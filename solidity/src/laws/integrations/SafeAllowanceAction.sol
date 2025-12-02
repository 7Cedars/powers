// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";


interface ISafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);
}

contract SafeAllowanceAction is Law {
    /// @dev Configuration for this law adoption.
    struct ConfigData {
        bytes4 functionSelector;
        address safe;
        address allowanceModule;
    }

    /// @dev Mapping law hash => configuration.
    mapping(bytes32 lawHash => ConfigData data) public lawConfig;

    /// @notice Constructor function
    constructor() {
        // Expose expected input parameters for UIs.
        bytes memory configParams = abi.encode(
            "string[] inputParams",
            "bytes4 functionSelector", 
            "address allowanceModule",
            "address safe"
        );
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (string[] memory inputParamsArray, bytes4 functionSelector, address safe, address allowanceModule) = 
            abi.decode(config, (string[], bytes4, address, address));
            
        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);
        lawConfig[lawHash_] = ConfigData({
            functionSelector: functionSelector,
            safe: safe,
            allowanceModule: allowanceModule
        });
        
        // Overwrite inputParams with the specific structure expected by handleRequest
        inputParams = abi.encode(inputParamsArray);

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
        bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
        ConfigData memory config = lawConfig[lawHash_];

        (bytes[] memory bytesParams) = abi.decode(lawCalldata, (bytes[]));

        // Construct the `v=1` signature.
        // This indicates that the `msg.sender` of this transaction (the `powers` contract)
        // is the delegate providing the approval by executing the transaction.
        // r = address of the signer (powers contract)
        // s = 0
        // v = 1
        bytes memory powersSignature = abi.encodePacked(uint256(uint160(powers)), uint256(0), uint8(1));

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = config.allowanceModule;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(
            config.functionSelector,
            Safe(payable(config.safe)),
            bytesParams
        );

        return (actionId, targets, values, calldatas);
    }
}
