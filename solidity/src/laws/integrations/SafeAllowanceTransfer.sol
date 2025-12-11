// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";

// import { console2 } from "forge-std/console2.sol"; // only for testing/debugging

// The ISafe interface is declared in AllowanceModule.sol, but cannot be directly imported due to version conflicts.
interface ISafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
}

contract SafeAllowanceTransfer is Law {
    /// @dev Configuration for this law adoption.
    struct ConfigData {
        address safeProxy;
        address allowanceModule;
    }

    struct Mem {
        bytes32 lawHash;
        address token;
        address payableTo;
        uint256 amount;
        bytes delegateSignature;
    }

    /// @dev Mapping law hash => configuration.
    mapping(bytes32 lawHash => ConfigData data) public lawConfig;

    /// @notice Constructor function
    constructor() {
        // Expose expected input parameters for UIs.
        bytes memory configParams = abi.encode("address allowanceModule", "address safeProxy");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address allowanceModule, address safeProxy) = abi.decode(config, (address, address));

        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);
        lawConfig[lawHash_] = ConfigData({ safeProxy: safeProxy, allowanceModule: allowanceModule });

        // Overwrite inputParams with the specific structure expected by handleRequest
        inputParams = abi.encode("address Token", "address PayableTo", "uint256 Amount");

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Prepares the call to the Allowance Module
    /// @param lawCalldata The calldata containing token, to, amount, delegate
    /// @return actionId The unique action identifier
    /// @return targets Array of target contract addresses
    /// @return values Array of ETH values to send
    /// @return calldatas Array of calldata for each call
    function handleRequest(
        address, /*caller*/
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        ConfigData memory config = lawConfig[LawUtilities.hashLaw(powers, lawId)];

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        // NB: We call the allowance module directly to make the transfer. The allowance module then calls the Safe proxy.
        targets[0] = config.allowanceModule;
        calldatas[0] = _createCalldata(powers, lawId, lawCalldata);

        return (actionId, targets, values, calldatas);
    }

    function _createCalldata(address powers, uint16 lawId, bytes memory lawCalldata)
        internal
        view
        returns (bytes memory)
    {
        Mem memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        ConfigData memory config = lawConfig[mem.lawHash];
        (mem.token, mem.payableTo, mem.amount) = abi.decode(lawCalldata, (address, address, uint256));

        // Construct the `v=1` signature.
        // r = address of the signer (powers contract)
        // s = 0
        // v = 1
        mem.delegateSignature = abi.encodePacked(uint256(uint160(powers)), uint256(0), uint8(1));

        return (abi.encodeWithSelector(
                bytes4(0x4515641a), // executeAllowanceTransfer(address,address,address,uint96,address,uint96,address,bytes),
                ISafe(config.safeProxy), // The Safe proxy address
                mem.token, // The token to transfer
                mem.payableTo, // The recipient of the tokens
                uint96(mem.amount), // The amount to transfer
                address(0), // paymentToken = address(0) for ETH refund
                uint96(0), // paymentAmount = 0 for no ETH refund
                powers, // The delegate address executing the transfer
                mem.delegateSignature // the signature constructed above
            ));
    }
}
