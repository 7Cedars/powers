// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";

import { console2 } from "forge-std/console2.sol"; // only for testing/debugging

contract SafeAllowanceAction is Law {
    /// @dev Configuration for this law adoption.
    struct ConfigData {
        bytes4 functionSelector;
        address safeProxy;
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
            "address safeProxy"
        );
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (string[] memory inputParamsArray, bytes4 functionSelector, address allowanceModule, address safeProxy) = 
            abi.decode(config, (string[], bytes4, address, address));
            
        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);
        lawConfig[lawHash_] = ConfigData({
            functionSelector: functionSelector,
            safeProxy: safeProxy,
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

        console2.log("CONFIG: selector, safe, module");
        console2.logBytes4(config.functionSelector);
        console2.logAddress(config.safeProxy);
        console2.logAddress(config.allowanceModule);

        (address delegateAddress) = abi.decode(lawCalldata, (address));
        console2.log("delegate address:");
        console2.logAddress(delegateAddress); 

        // Construct the `v=1` signature.
        // This indicatesa) = abi.decode(lawCalldata) = abi.decode(lawCalldat that the `msg.sender` of this transaction (the `powers` contract)
        // is the delegate providing the approval by executing the transaction.
        // r = address of the signer (powers contract)
        // s = 0
        // v = 1
        bytes memory powersSignature = abi.encodePacked(uint256(uint160(powers)), uint256(0), uint8(1));
        console2.log("powersSignature:");
        console2.logBytes(powersSignature); 

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

        // NB: We call the execTransaction function in our SafeL2 proxy to make the call to the Allowance Module.
        targets[0] = config.safeProxy;
        calldatas[0] = abi.encodeWithSelector(
            Safe.execTransaction.selector, 
            config.safeProxy, // The internal transaction's destination
            0, // The internal transaction's value in this law is always 0. To transfer Eth use a different law.
            abi.encodeWithSelector( // the call to be executed by the Safe. The function selector is dynamic.
                config.functionSelector,
                delegateAddress
                ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            powersSignature // the signature constructed above
        );

        return (actionId, targets, values, calldatas);
    }
}
