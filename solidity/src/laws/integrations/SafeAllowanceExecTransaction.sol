// needs to have the same layout as Statement of Intent.  But signing and executing action to SafeL2 (v1.4.1) instance. 

// SPDX-License-Identifier: MIT
/// @notice A base contract that takes an input but does not execute any logic.
///
/// The logic:
/// - the lawCalldata includes targets[], values[], calldatas[] - that are sent straight to the Powers protocol without any checks.
/// - the lawCalldata is not executed.
///
/// @author 7Cedars,

pragma solidity 0.8.26; 

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { MessageHashUtils } from "../../../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import { SafeL2 } from "lib/safe-smart-account/contracts/SafeL2.sol";
import { ModuleManager } from "lib/safe-smart-account/contracts/base/ModuleManager.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";

// NB! TODO

contract SafeAllowanceExecTransaction is Law {
    /// @dev Configuration for this law adoption law. Includes addresses of base laws to adopt.
    struct ConfigData {
        address safe; // The Safe address to execute the transaction on
        bytes4 functionSig; // The function signature to call on the Safe
    }

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address payable refundReceiver;
        bytes signatures;
    }

    /// @dev Mapping law hash => configuration.
    mapping(bytes32 lawHash => ConfigData data) public lawConfig;
    
    /// @notice Constructor function for StatementOfIntent law
    constructor() {
        // This law does not require config; it forwards user-provided calls.
        // Expose expected input parameters for UIs.
        bytes memory configParams = abi.encode("string[] inputParams", "bytes4 functionSig", "address Safe");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {   

        (string[] memory inputParamsRaw, bytes4 functionSig, address safe) = abi.decode(config, (string[], bytes4, address));
        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);
        lawConfig[lawHash_] = ConfigData({
            safe: safe,
            functionSig: functionSig
        });
        inputParams = abi.encode(inputParamsRaw);

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Return calls provided by the user without modification
    /// @param lawCalldata The calldata containing targets, values, and calldatas arrays
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
        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, lawId);
        address safeAddress = lawConfig[lawHash_].safe;
        bytes4 functionSig = lawConfig[lawHash_].functionSig;
        uint256 safeNonce = SafeL2(payable(safeAddress)).nonce(); // Placeholder to avoid unused variable warning

        // Transaction memory txData = Transaction({
        //     to: safeAddress,
        //     value: 0,
        //     data: lawCalldata,
        //     operation: Enum.Operation.Call,
        //     safeTxGas: 0,
        //     baseGas: 0,
        //     gasPrice: 0,
        //     gasToken: address(0),
        //     refundReceiver: payable(address(0)),
        //     signatures: ""
        // });

        // creating the signature for the safe transaction
        bytes32 signature = MessageHashUtils.toEthSignedMessageHash(
            SafeL2(payable(safeAddress)).getTransactionHash(
                safeAddress,
                0,
                lawCalldata,
                Enum.Operation.Call,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                safeNonce // Here there is a nonce.... 
            )
        );

        // creating call to safe account for execTransaction
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = safeAddress; // The target is the Safe contract
        calldatas[0] = abi.encodeWithSelector(
            functionSig,
            safeAddress,
            0,
            lawCalldata,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            abi.encodePacked(signature) // ... and here you have signature, but no nonce. hmm. 
        );

        return (actionId, targets, values, calldatas);
    }
}
