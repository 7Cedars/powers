// SPDX-License-Identifier: MIT
/// @notice A mandate to execute that creates a SafeProxy, setting Powers as owner and registring it as its treasury.
/// @dev This mandate uses the v=1 signature type, where the transaction executor (`msg.sender` to the Safe)
///      is an owner, thus providing its own approval by making the call.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";
import { SafeProxyFactory } from "lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { IPowers } from "../../interfaces/IPowers.sol";

// import { console2 } from "lib/forge-std/src/console2.sol"; // REMOVE AFTER TESTING

contract SafeSetup is Mandate {
    /// @dev Configuration for this mandate adoption.
    struct ConfigData {
        address safeProxyFactory; // The SafeProxyFactory address to create the SafeProxy.
        address safeL2Singleton; // The SafeL2 singleton address used by the SafeProxy.
    }

    /// @dev Mapping from mandate hash to its configuration.
    mapping(bytes32 => ConfigData) public mandateConfig;

    /// @notice Exposes the expected input parameters for UIs during deployment.
    constructor() {
        bytes memory configParams = abi.encode("address safeProxyFactory", "address safeL2Singleton");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory, bytes memory config)
        public
        override
    {
        (address safeProxyFactory_, address safeL2Singleton_) = abi.decode(config, (address, address));
        bytes32 mandateHash_ = MandateUtilities.hashMandate(msg.sender, index);
        mandateConfig[mandateHash_] = ConfigData({ safeProxyFactory: safeProxyFactory_, safeL2Singleton: safeL2Singleton_ });
        super.initializeMandate(index, nameDescription, abi.encode(""), config);
    }

    /// @notice Prepares a transaction to be executed by the configured Gnosis Safe.
    /// @dev This function decodes the internal transaction parameters from `mandateCalldata` and
    ///      constructs a `v=1` signature where `powers` is the designated signer.
    ///      This is valid only if the `powers` contract is an owner of the target Safe.
    /// @param mandateCalldata The ABI-encoded parameters for the internal Safe transaction:
    ///                    (address to, uint256 value, bytes data, Enum.Operation operation).
    /// @return actionId The unique action identifier.
    /// @return targets An array containing the Safe contract address.
    /// @return values An array containing 0, as no ETH is sent to the Safe directly.
    /// @return calldatas An array with the encoded `execTransaction` call for the Safe.
    function handleRequest(
        address, /*caller*/
        address powers,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // NB! No transaction is sent to Powers here, so the action remains unfulfilled.
        calldatas = new bytes[](1);
        calldatas[0] = abi.encode(powers);

        return (actionId, targets, values, calldatas);
    }

    function _externalCall(
        uint16 mandateId,
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal virtual override {
        // step 1: creating a SafeProxy with Powers as owner
        address powers = abi.decode(calldatas[0], (address));
        ConfigData memory config = mandateConfig[MandateUtilities.hashMandate(powers, mandateId)];

        address[] memory owners = new address[](1);
        owners[0] = powers;

        address safeProxyAddress = address(
            SafeProxyFactory(config.safeProxyFactory)
                .createProxyWithNonce(
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
                )
        );

        // step 2: register the SafeProxy as treasury in Powers ./
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(2);
        targets[0] = msg.sender;
        calldatas[0] = abi.encodeWithSelector(IPowers.setTreasury.selector, safeProxyAddress);
        targets[1] = msg.sender;
        calldatas[1] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateId);

        IPowers(msg.sender).fulfill(mandateId, actionId, targets, values, calldatas);
    }
}
