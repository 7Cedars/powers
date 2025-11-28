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
import { ModuleManager } from "../../../lib/safe-smart-account/contracts/base/ModuleManager.sol";

// This LawPackage adopts the following governance paths: 
// path 0 + 1: init Allowance Module. 
// path 2: adopt new child. 
// path 3: assign allowance to child. 

contract PowerBaseSafeSetup is Law {
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
        inputParams = abi.encode("address Safe");
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
        address safeAddress = abi.decode(lawCalldata, (address));
        string[] memory inputParams;
        
        // Enable Allowance Module & register treasury. 
        inputParams = new string[](0);
        lawInitData[0] = PowersTypes.LawInitData({
            nameDescription: "Adopt Allowance Module: In safe",
            targetLaw: lawAddresses[1], // safeExecTransaction
            config: abi.encode(
                inputParams,
                ModuleManager.enableModule.selector,
                0xAA46724893dedD72658219405185Fb0Fc91e091C // the canonic address of the Allowance Module (v.1.4.1)
            ),
            conditions: conditions // everythign zero == Only admin can call directly 
        });
        delete conditions;
        lawCount++;

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = LawUtilities.createEmptyArrays(2);
        targets[0] = powers; // Powers contract
        calldatas[0] = abi.encodeWithSelector(Powers.setTreasury.selector, safeAddress);
        targets[1] = powers; 
        calldatas[1] = abi.encodeWithSelector(Powers.revokeLaw.selector, lawCount); // revoke this law after execution
        
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Set Treasury to Safe address and delete this law.",
            targetLaw: lawAddresses[2], // PresetSingleAction
            config: abi.encode(
                targets,
                values,
                calldatas
            ),
            conditions: conditions // everythign zero == Only admin can call directly 
        });
        delete conditions;
        lawCount++;

        //////////////////////////////////////////////////////////////////////////  
        // register new delegate = roleId with its own child Powers deployment. //
        //////////////////////////////////////////////////////////////////////////

        // statementOfIntent params
        inputParams = new string[](1);
        inputParams[0] = "address NewChildPowers"; 

        conditions.allowedRole = 5; // = Members can call this law.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Propose to add a new Child Powers as a delegate to the Safe Treasury.",
            targetLaw: lawAddresses[0], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;
        lawCount++;

        conditions.allowedRole = 1; // = funders.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needFulfilled = lawCount - 1; // = law that must be completed before this one.
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "Veto adding a new Child Powers as a delegate to the Safe Treasury.",
            targetLaw: lawAddresses[0], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;
        lawCount++;
        
        conditions.allowedRole = 2; // = doc contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needFulfilled = lawCount - 2; // = the proposal law.
        conditions.needNotFulfilled = lawCount - 1; // = the funders veto law.
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "OK adding a new Child Powers as a delegate to the Safe Treasury.",
            targetLaw: lawAddresses[0], // statementOfIntent.
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;
        lawCount++;

        conditions.allowedRole = 3; // = frontend contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needFulfilled = lawCount - 1; // = the proposal law.
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "OK adding a new Child Powers as a delegate to the Safe Treasury.",
            targetLaw: lawAddresses[0], // statementOfIntent.
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;
        lawCount++;

        conditions.allowedRole = 4; // = frontend contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        // conditions.needFulfilled = lawCount - 1; // = the proposal law.
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "Execute and adopt new child Powers as a delegate to the Safe treasury.",
            targetLaw: lawAddresses[1], // safeExecTransaction
            config: abi.encode(
                inputParams,
                bytes4(0xe71bdf41), // == AllowanceModule.addDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                safeAddress
            ),
            conditions: conditions // everythign zero == Only admin can call directly 
        });
        delete conditions;
        lawCount++;
    

        //////////////////////////////////////////////////////////////////////////  
        //          Set new allowance for delegated child powers contract       //
        //////////////////////////////////////////////////////////////////////////

        // statementOfIntent params
        inputParams = new string[](5);
        inputParams[0] = "address ChildPowers"; 
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";

        conditions.allowedRole = 5; // = Members can call this law.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[7] = PowersTypes.LawInitData({
            nameDescription: "Propose to set allowance for a Powers Child at the Safe Treasury.",
            targetLaw: lawAddresses[0], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;
        lawCount++;

        conditions.allowedRole = 1; // = funders.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needFulfilled = lawCount - 1; // = law that must be completed before this one.
        lawInitData[8] = PowersTypes.LawInitData({
            nameDescription: "Veto setting allowance for a Powers Child at the Safe Treasury.",
            targetLaw: lawAddresses[0], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;
        lawCount++;
        
        conditions.allowedRole = 2; // = doc contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needFulfilled = lawCount - 2; // = the proposal law.
        conditions.needNotFulfilled = lawCount - 1; // = the funders veto law.
        lawInitData[9] = PowersTypes.LawInitData({
            nameDescription: "OK setting allowance for a Powers Child at the Safe Treasury.",
            targetLaw: lawAddresses[0], // statementOfIntent.
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;
        lawCount++;

        conditions.allowedRole = 3; // = frontend contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needFulfilled = lawCount - 1; // = the proposal law. 
        delete conditions.needNotFulfilled; // = no veto law.
        lawInitData[10] = PowersTypes.LawInitData({
            nameDescription: "OK setting allowance for a Powers Child at the Safe Treasury.",
            targetLaw: lawAddresses[0], // statementOfIntent.
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;
        lawCount++;
        
        conditions.allowedRole = 4; // = protocol contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        // conditions.needFulfilled = lawCount - 1; // = the proposal law. 
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

        return lawInitData;
    }

}
 