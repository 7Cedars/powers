// SPDX-License-Identifier: MIT

/// @notice An example implementation of a Law Package that adopts multiple laws into the Powers protocol.
/// @dev It is meant to be adopted through the AdoptLaws law, and then be executed to adopt multiple laws in a single transaction.
/// @dev The law self-destructs after execution.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { Powers } from "../../Powers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";
import { ILaw } from "../../interfaces/ILaw.sol";
import { IERC165 } from "../../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { SafeExecTransaction } from "../integrations/SafeExecTransaction.sol";

// This LawPackage adopts the following governance paths: 
// path 0 + 1: init Allowance Module. 
// path 2: adopt new child. 
// path 3: assign allowance to child. 

contract PowerChildSafeSetup is Law {
    address[] private s_lawAddresses;
    
    // in this case lawAddresses should be [statementOfIntent, SafeExecTransaction, PresetSingleAction]
    constructor(address[] memory lawAddresses) {
        s_lawAddresses = lawAddresses;
        emit Law__Deployed(abi.encode());
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        inputParams = abi.encode("address Safe, uint256 roleId");
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Build calls to adopt the configured laws
    /// @param lawCalldata Unused for this law
    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce); 
        uint16 lawCount = Powers(powers).lawCounter();
        PowersTypes.LawInitData[] memory s_lawInitData = getNewLaws(s_lawAddresses, powers, lawCount, lawCalldata);

        // Create arrays for the calls to adoptLaw
        uint256 length = s_lawInitData.length;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length + 1);
        for (uint256 i; i < length; i++) {
            targets[i] = powers;
            calldatas[i] = abi.encodeWithSelector(IPowers.adoptLaw.selector, s_lawInitData[i]);
        }
        // Final call to self-destruct the LawPackage after adopting the laws
        targets[length] = powers;
        calldatas[length] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId); 
        return (actionId, targets, values, calldatas);
    }

    /// @notice Generates LawInitData for a set of new laws to be adopted.
    /// @param lawAddresses The addresses of the laws to be adopted.
    /// @param powers The address of the Powers contract.
    /// @return lawInitData An array of LawInitData structs for the new laws.
    /// @dev the function follows the same pattern as TestConstitutions.sol 
    /// this function can be overwritten to create different law packages.
    function getNewLaws(
        address[] memory lawAddresses,
        address powers,
        uint16 lawCount,
        bytes memory lawCalldata
    ) public view virtual returns (PowersTypes.LawInitData[] memory lawInitData) {
        lawInitData = new PowersTypes.LawInitData[](12);
        PowersTypes.Conditions memory conditions;
        (address safeAddress, uint256 roleId) = abi.decode(lawCalldata, (address, uint256));
        string[] memory inputParams;
        
        // 
        conditions.allowedRole = 4; // = protocol contributors.
        conditions.needFulfilled = lawCount - 1; // = the proposal law. 
        lawInitData[11] = PowersTypes.LawInitData({
            nameDescription: "Execute and set allowance for a Powers Child at the Safe Treasury.",
            targetLaw: lawAddresses[1], // safeExecTransaction
            config: abi.encode(
                inputParams,
                bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                safeAddress
            ),
            conditions: conditions // everythign zero == Only admin can call directly 
        });
        delete conditions;
    }
}
 