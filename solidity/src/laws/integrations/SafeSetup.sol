// SPDX-License-Identifier: MIT
/// @notice A law to execute that creates a SafeProxy, setting Powers as owner and registring it as its treasury. 
/// @dev This law uses the v=1 signature type, where the transaction executor (`msg.sender` to the Safe)
///      is an owner, thus providing its own approval by making the call.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";
import { SafeProxyFactory } from "lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";

// import { console2 } from "lib/forge-std/src/console2.sol"; // REMOVE AFTER TESTING

contract SafeSetup is Law {
    /// @dev Configuration for this law adoption.
    struct ConfigData {
        address safeProxyFactory; // The SafeProxyFactory address to create the SafeProxy.
        address safeL2Singleton;  // The SafeL2 singleton address used by the SafeProxy.
    }

    /// @dev Mapping from law hash to its configuration.
    mapping(bytes32 => ConfigData) public lawConfig;

    /// @notice Exposes the expected input parameters for UIs during deployment.
    constructor() {
        bytes memory configParams =
            abi.encode("address safeProxyFactory", "address safeL2Singleton");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config
    ) public override {
        (address safeProxyFactory_, address safeL2Singleton_) = abi.decode(config, (address, address));
        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);
        lawConfig[lawHash_] = ConfigData({ 
            safeProxyFactory: safeProxyFactory_,
            safeL2Singleton: safeL2Singleton_
        });
        super.initializeLaw(index, nameDescription, abi.encode(""), config);
    }

    /// @notice Prepares a transaction to be executed by the configured Gnosis Safe.
    /// @dev This function decodes the internal transaction parameters from `lawCalldata` and
    ///      constructs a `v=1` signature where `powers` is the designated signer.
    ///      This is valid only if the `powers` contract is an owner of the target Safe.
    /// @param lawCalldata The ABI-encoded parameters for the internal Safe transaction:
    ///                    (address to, uint256 value, bytes data, Enum.Operation operation).
    /// @return actionId The unique action identifier.
    /// @return targets An array containing the Safe contract address.
    /// @return values An array containing 0, as no ETH is sent to the Safe directly.
    /// @return calldatas An array with the encoded `execTransaction` call for the Safe.
    function handleRequest(
        address, /*caller*/
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    ) public view override returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // NB! No transaction is sent to Powers here, so the action remains unfulfilled. 
        calldatas = new bytes[](1);
        calldatas[0] = abi.encode(powers); 

        return (actionId, targets, values, calldatas);
    }

    function _externalCall(
        uint16 lawId,
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal override virtual {

        // step 1: creating a SafeProxy with Powers as owner 
        address powers = abi.decode(calldatas[0], (address));
        ConfigData memory config = lawConfig[LawUtilities.hashLaw(powers, lawId)];

        address[] memory owners = new address[](1);
        owners[0] = powers; 

        address safeProxyAddress = address(SafeProxyFactory(config.safeProxyFactory).createProxyWithNonce(
            config.safeL2Singleton,
            abi.encodeWithSelector(
                Safe.setup.selector,
                owners,
                1, // threshold
                address(0), // to
                "", // data
                address(0), // fallbackHandler
                address(0), // paymentToken
                0, // payment
                address(0) // paymentReceiver
                ),
            1 // = nonce 
        )); 

        // step 2: register the SafeProxy as treasury in Powers ./
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(2);
        targets[0] = msg.sender;
        calldatas[0] = abi.encodeWithSelector(
            IPowers.setTreasury.selector,
            safeProxyAddress
        ); 
        targets[1] = msg.sender;
        calldatas[1] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId); 

        IPowers(msg.sender).fulfill(lawId, actionId, targets, values, calldatas);
    }
}
