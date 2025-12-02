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
import { SafeL2 } from "lib/safe-smart-account/contracts/SafeL2.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";
import { MessageHashUtils } from "../../../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

// This LawPackage adopts the following governance paths: 
// path 0 + 1: init Allowance Module. 
// path 2: adopt new child. 
// path 3: assign allowance to child. 

// import { console2 } from "forge-std/console2.sol"; // only for testing purposes. 

contract PowerBaseSafeSetup is Law {
    struct Mem {
        uint16 lawCount;
        address safeProxy;
        address allowanceModuleAddress;
        uint256 length;
        bytes signature;
    }
    address[] private s_lawAddresses;

    
    // in this case lawAddresses should be [statementOfIntent, SafeExecTransaction, PresetSingleAction, SafeAllowanceAction]
    constructor() {
        emit Law__Deployed(abi.encode("address[] lawDependencies")
        );
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address[] memory lawAddresses) = abi.decode(config, (address[])); 
        s_lawAddresses = lawAddresses;
        
        inputParams = abi.encode("address SafeProxy", "address AllowanceModule");
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
        // Placing action between brackets to avoid stack too deep errors.
        
            Mem memory mem; 

            actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce); 
            mem.lawCount = Powers(powers).lawCounter();
            (mem.safeProxy, mem.allowanceModuleAddress) = abi.decode(lawCalldata, (address, address));
            mem.signature = abi.encodePacked(
                uint256(uint160(powers)), // r = address of the signer (powers contract)
                uint256(0),                // s = 0
                uint8(1)                  // v = 1 This is a type 1 call. See Safe.sol for details.
            );
            // mem.delegateInitLaws = getDelegateLaws(s_lawAddresses, powers, mem.lawCount, mem.safeProxy, mem.allowanceModuleAddress);
            // mem.allowanceInitLaws = getAllowanceLaws(s_lawAddresses, powers, mem.lawCount + uint16(mem.delegateInitLaws.length), mem.safeProxy, mem.allowanceModuleAddress);

            // Create arrays for the calls to adoptLaw
            // mem.length = mem.delegateInitLaws.length + mem.allowanceInitLaws.length + 3; // +3 for adopt allowance module, set treasury, and self-destruct calls.
            (targets, values, calldatas) = LawUtilities.createEmptyArrays(3);

            // 1: adopt Allowance Module
            targets[0] = mem.safeProxy; // Safe contract
            calldatas[0] = abi.encodeWithSelector(
                SafeL2.execTransaction.selector, 
                mem.safeProxy, // The internal transaction's destination
                0, // The internal transaction's value in this law is always 0. To transfer Eth use a different law.
                abi.encodeWithSelector( // the call to be executed by the Safe: enabling the module. 
                    ModuleManager.enableModule.selector,
                    mem.allowanceModuleAddress
                    ),
                0, // operation = Call
                0, // safeTxGas
                0, // baseGas
                0, // gasPrice
                address(0), // gasToken
                address(0), // refundReceiver
                mem.signature // the signature constructed above
            );
        
            // 2: set treasury to safe address
            targets[1] = powers; // Powers contract
            calldatas[1] = abi.encodeWithSelector(Powers.setTreasury.selector, mem.safeProxy); 

            // Encoding calls 3..n: adopting law calls
            // for (uint256 i = 2; i < mem.delegateInitLaws.length + 2; i++) {
            //     targets[i] = powers;
            //     calldatas[i] = abi.encodeWithSelector(IPowers.adoptLaw.selector, mem.delegateInitLaws[i - 2]);
            // }
            // for (uint256 i = mem.delegateInitLaws.length + 2; i < mem.length - 1; i++) {
            //     targets[i] = powers;
            //     calldatas[i] = abi.encodeWithSelector(IPowers.adoptLaw.selector, mem.allowanceInitLaws[i - mem.delegateInitLaws.length - 2]);
            // }

            // Final call to self-destruct the LawPackage after adopting the laws
            targets[mem.length] = powers;
            calldatas[mem.length] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId); 
            return (actionId, targets, values, calldatas);
        
    }

    // /// @notice Generates the governance flow related to the Safe treasury. 
    // /// @param lawAddresses The addresses of the laws to be adopted.
    // /// @param powers The address of the Powers contract.
    // /// @return lawInitData An array of LawInitData structs for the new laws.
    // /// @dev the function follows the same pattern as TestConstitutions.sol 
    // /// this function can be overwritten to create different law packages.
    // function getDelegateLaws(
    //     address[] memory lawAddresses,
    //     address powers,
    //     uint16 lawCount,
    //     address safeProxy,
    //     address allowanceModuleAddress
    // ) private view returns (PowersTypes.LawInitData[] memory lawInitData) {
    //     lawInitData = new PowersTypes.LawInitData[](5);
    //     PowersTypes.Conditions memory conditions; 
    //     string[] memory inputParams; 
 
    //     //////////////////////////////////////////////////////////////////////////  
    //     // register new delegate = roleId with its own child Powers deployment. //
    //     //////////////////////////////////////////////////////////////////////////

    //     // statementOfIntent params
    //     inputParams = new string[](1);
    //     inputParams[0] = "address NewChildPowers"; 

    //     conditions.allowedRole = 5; // = Members can call this law.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     lawInitData[0] = PowersTypes.LawInitData({
    //         nameDescription: "Propose to add a new Child Powers as a delegate to the Safe Treasury.",
    //         targetLaw: lawAddresses[0], // statementOfIntent
    //         config: abi.encode(inputParams),
    //         conditions: conditions
    //     });
    //     delete conditions;
    //     lawCount++;

    //     conditions.allowedRole = 1; // = funders.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     conditions.needFulfilled = lawCount - 1; // = law that must be completed before this one.
    //     lawInitData[1] = PowersTypes.LawInitData({
    //         nameDescription: "Veto adding a new Child Powers as a delegate to the Safe Treasury.",
    //         targetLaw: lawAddresses[0], // statementOfIntent
    //         config: abi.encode(inputParams),
    //         conditions: conditions
    //     });
    //     delete conditions;
    //     lawCount++;
        
    //     conditions.allowedRole = 2; // = doc contributors.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     conditions.needFulfilled = lawCount - 2; // = the proposal law.
    //     conditions.needNotFulfilled = lawCount - 1; // = the funders veto law.
    //     lawInitData[2] = PowersTypes.LawInitData({
    //         nameDescription: "OK adding a new Child Powers as a delegate to the Safe Treasury.",
    //         targetLaw: lawAddresses[0], // statementOfIntent.
    //         config: abi.encode(inputParams),
    //         conditions: conditions
    //     });
    //     delete conditions;
    //     lawCount++;

    //     conditions.allowedRole = 3; // = frontend contributors.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     conditions.needFulfilled = lawCount - 1; // = the proposal law.
    //     lawInitData[3] = PowersTypes.LawInitData({
    //         nameDescription: "OK adding a new Child Powers as a delegate to the Safe Treasury.",
    //         targetLaw: lawAddresses[0], // statementOfIntent.
    //         config: abi.encode(inputParams),
    //         conditions: conditions
    //     });
    //     delete conditions;
    //     lawCount++;

    //     conditions.allowedRole = 4; // = frontend contributors.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     conditions.needFulfilled = lawCount - 1; // = the proposal law.
    //     lawInitData[4] = PowersTypes.LawInitData({
    //         nameDescription: "Execute and adopt new child Powers as a delegate to the Safe treasury.",
    //         targetLaw: lawAddresses[3], // safeAllowanceAction
    //         config: abi.encode(
    //             inputParams,
    //             bytes4(0xe71bdf41), // == AllowanceModule.addDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
    //             safeProxy
    //         ),
    //         conditions: conditions // everythign zero == Only admin can call directly 
    //     });
    //     delete conditions;
        
    //     return lawInitData;
    // }
    
    // function getAllowanceLaws(
    //     address[] memory lawAddresses,
    //     address powers,
    //     uint16 lawCount,
    //     address safeProxy,
    //     address allowanceModuleAddress
    // ) private view returns (PowersTypes.LawInitData[] memory lawInitData) {
    //     lawInitData = new PowersTypes.LawInitData[](5);
    //     PowersTypes.Conditions memory conditions; 
    //     string[] memory inputParams; 

    //     //////////////////////////////////////////////////////////////////////////  
    //     //          Set new allowance for delegated child powers contract       //
    //     //////////////////////////////////////////////////////////////////////////

    //     // statementOfIntent params
    //     inputParams = new string[](5);
    //     inputParams[0] = "address ChildPowers"; 
    //     inputParams[1] = "address Token";
    //     inputParams[2] = "uint96 allowanceAmount";
    //     inputParams[3] = "uint16 resetTimeMin";
    //     inputParams[4] = "uint32 resetBaseMin";

    //     conditions.allowedRole = 5; // = Members can call this law.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     lawInitData[0] = PowersTypes.LawInitData({
    //         nameDescription: "Propose to set allowance for a Powers Child at the Safe Treasury.",
    //         targetLaw: lawAddresses[0], // statementOfIntent
    //         config: abi.encode(inputParams),
    //         conditions: conditions
    //     });
    //     delete conditions;
    //     lawCount++;

    //     conditions.allowedRole = 1; // = funders.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     conditions.needFulfilled = lawCount - 1; // = law that must be completed before this one.
    //     lawInitData[1] = PowersTypes.LawInitData({
    //         nameDescription: "Veto setting allowance for a Powers Child at the Safe Treasury.",
    //         targetLaw: lawAddresses[0], // statementOfIntent
    //         config: abi.encode(inputParams),
    //         conditions: conditions
    //     });
    //     delete conditions;
    //     lawCount++;
        
    //     conditions.allowedRole = 2; // = doc contributors.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     conditions.needFulfilled = lawCount - 2; // = the proposal law.
    //     conditions.needNotFulfilled = lawCount - 1; // = the funders veto law.
    //     lawInitData[2] = PowersTypes.LawInitData({
    //         nameDescription: "OK setting allowance for a Powers Child at the Safe Treasury.",
    //         targetLaw: lawAddresses[0], // statementOfIntent.
    //         config: abi.encode(inputParams),
    //         conditions: conditions
    //     });
    //     delete conditions;
    //     lawCount++;

    //     conditions.allowedRole = 3; // = frontend contributors.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     conditions.needFulfilled = lawCount - 1; // = the proposal law. 
    //     delete conditions.needNotFulfilled; // = no veto law.
    //     lawInitData[3] = PowersTypes.LawInitData({
    //         nameDescription: "OK setting allowance for a Powers Child at the Safe Treasury.",
    //         targetLaw: lawAddresses[0], // statementOfIntent.
    //         config: abi.encode(inputParams),
    //         conditions: conditions
    //     });
    //     delete conditions;
    //     lawCount++;
        
    //     conditions.allowedRole = 4; // = protocol contributors.
    //     conditions.quorum = 20; // = 30% quorum needed
    //     conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
    //     conditions.votingPeriod = 1200; // = number of blocks
    //     conditions.needFulfilled = lawCount - 1; // = the proposal law. 
    //     lawInitData[4] = PowersTypes.LawInitData({
    //         nameDescription: "Execute and set allowance for a Powers Child at the Safe Treasury.",
    //         targetLaw: lawAddresses[3], // safeAllowanceAction
    //         config: abi.encode(
    //             inputParams, 
    //             bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
    //             allowanceModuleAddress,
    //             safeProxy
    //         ),
    //         conditions: conditions // everythign zero == Only admin can call directly 
    //     });

    //     return lawInitData;
    // }

}
 