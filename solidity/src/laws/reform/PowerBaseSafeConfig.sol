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

contract PowerBaseSafeConfig is Law {
    struct Mem {
        uint16 lawCount;
        address safeProxy;
        bytes signature; 
    }
    address[] private lawAddresses;
    address private allowanceModuleAddress;
    uint16 constant public NUMBER_OF_CALLS = 17; // total number of calls in handleRequest
    uint48 immutable public blocksPerHour;
    
    // in this case lawAddresses should be [statementOfIntent, SafeExecTransaction, PresetSingleAction, SafeAllowanceAction]
    constructor(uint48 blocksPerHour_) {
        blocksPerHour = blocksPerHour_;

        emit Law__Deployed(abi.encode("address[] lawDependencies", "address AllowanceModule")
        );
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address[] memory lawAddresses_, address allowanceModuleAddress_) = abi.decode(config, (address[], address)); 
        lawAddresses = lawAddresses_;
        allowanceModuleAddress = allowanceModuleAddress_;
        
        inputParams = abi.encode("address SafeProxy");
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
            (mem.safeProxy) = abi.decode(lawCalldata, (address));
            mem.signature = abi.encodePacked(
                uint256(uint160(powers)), // r = address of the signer (powers contract)
                uint256(0),                // s = 0
                uint8(1)                  // v = 1 This is a type 1 call. See Safe.sol for details.
            );

            (targets, values, calldatas) = LawUtilities.createEmptyArrays(NUMBER_OF_CALLS);

            /////////////////////////////////////////////////////////////////////////////////////////////////////
            // DIRECT CALLS TO POWERS CONTRACT TO ADOPT THE ALLOWANCE MODULE AND SET THE SAFEPROXY AS TREASURY //
            /////////////////////////////////////////////////////////////////////////////////////////////////////

            // 1: adopt Allowance Module
            targets[0] = mem.safeProxy; // Safe contract
            calldatas[0] = abi.encodeWithSelector(
                SafeL2.execTransaction.selector, 
                mem.safeProxy, // The internal transaction's destination
                0, // The internal transaction's value in this law is always 0. To transfer Eth use a different law.
                abi.encodeWithSelector( // the call to be executed by the Safe: enabling the module. 
                    ModuleManager.enableModule.selector,
                    allowanceModuleAddress
                    ),
                0, // operation = Call
                0, // safeTxGas
                0, // baseGas
                0, // gasPrice
                address(0), // gasToken
                address(0), // refundReceiver
                mem.signature // the signature constructed above
            );

            for (uint i = 1; i < NUMBER_OF_CALLS; i++) {
                targets[i] = powers;
            }

            // 3: assign labels to roles. 
            calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Funders");
            calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Doc Contributors");
            calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Frontend Contributors");
            calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Protocol Contributors");
            calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Members");


            // 4: set final call to self-destruct the LawPackage after adopting the laws
            calldatas[NUMBER_OF_CALLS - 1] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId); 

            //////////////////////////////////////////////////////////////////////////  
            //              GOVERNANCE FLOW FOR ADOPTING DELEGATES                  //
            //////////////////////////////////////////////////////////////////////////

            PowersTypes.Conditions memory conditions;
            string[] memory inputParams;
            PowersTypes.LawInitData memory lawInitData;

            // statementOfIntent params
            inputParams = new string[](1);
            inputParams[0] = "address NewChildPowers"; 
            conditions.allowedRole = 5; // = Members can call this law.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(5); // 
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "Propose to add a new Child Powers as a delegate to the Safe Treasury.",
                targetLaw: lawAddresses[0], // statementOfIntent
                config: abi.encode(inputParams),
                conditions: conditions
            });

            calldatas[6] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;

            conditions.allowedRole = 1; // = funders.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
            conditions.needFulfilled = mem.lawCount - 1; // = law that must be completed before this one.
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "Veto adding a new Child Powers as a delegate to the Safe Treasury.",
                targetLaw: lawAddresses[0], // statementOfIntent
                config: abi.encode(inputParams),
                conditions: conditions
            });

            calldatas[7] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;
            
            conditions.allowedRole = 2; // = doc contributors.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
            conditions.needFulfilled = mem.lawCount - 2; // = the proposal law.
            conditions.needNotFulfilled = mem.lawCount - 1; // = the funders veto law.
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "OK adding a new Child Powers as a delegate to the Safe Treasury.",
                targetLaw: lawAddresses[0], // statementOfIntent.
                config: abi.encode(inputParams),
                conditions: conditions
            });

            calldatas[8] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;

            conditions.allowedRole = 3; // = frontend contributors.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
            conditions.needFulfilled = mem.lawCount - 1;   // = the proposal law.
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "OK adding a new Child Powers as a delegate to the Safe Treasury.",
                targetLaw: lawAddresses[0], // statementOfIntent.
                config: abi.encode(inputParams),
                conditions: conditions
            });

            calldatas[9] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;

            conditions.allowedRole = 4; // = protocol contributors.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(10); // = number of blocks
            conditions.needFulfilled = mem.lawCount - 1; // = the proposal law.
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "Execute and adopt new child Powers as a delegate to the Safe treasury.",
                targetLaw: lawAddresses[3], // safeAllowanceAction
                config: abi.encode(
                    inputParams,
                    bytes4(0xe71bdf41), // == AllowanceModule.addDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    allowanceModuleAddress, 
                    mem.safeProxy
                ),
                conditions: conditions // everythign zero == Only admin can call directly 
            });

            calldatas[10] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;

            //////////////////////////////////////////////////////////////////////////  
            //               GOVERNANCE FLOW FOR SETTING ALLOWANCE                  //
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
            conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "Propose to set allowance for a Powers Child at the Safe Treasury.",
                targetLaw: lawAddresses[0], // statementOfIntent
                config: abi.encode(inputParams),
                conditions: conditions
            });

            calldatas[11] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;

            conditions.allowedRole = 1; // = funders.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
            conditions.needFulfilled = mem.lawCount - 1; // = law that must be completed before this one.
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "Veto setting allowance for a Powers Child at the Safe Treasury.",
                targetLaw: lawAddresses[0], // statementOfIntent
                config: abi.encode(inputParams),
                conditions: conditions
            });

            calldatas[12] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;
            
            conditions.allowedRole = 2; // = doc contributors.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
            conditions.needFulfilled = mem.lawCount - 2; // = the proposal law.
            conditions.needNotFulfilled = mem.lawCount - 1; // = the funders veto law.
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "OK setting allowance for a Powers Child at the Safe Treasury.",
                targetLaw: lawAddresses[0], // statementOfIntent.
                config: abi.encode(inputParams),
                conditions: conditions
            });

            calldatas[13] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;

            conditions.allowedRole = 3; // = frontend contributors.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
            conditions.needFulfilled = mem.lawCount - 1; // = the proposal law. 
            delete conditions.needNotFulfilled; // = no veto law.
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "OK setting allowance for a Powers Child at the Safe Treasury.",
                targetLaw: lawAddresses[0], // statementOfIntent.
                config: abi.encode(inputParams),
                conditions: conditions
            });

            calldatas[14] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
            delete conditions;
            mem.lawCount++;
            
            conditions.allowedRole = 4; // = protocol contributors.
            conditions.quorum = 20; // = 30% quorum needed
            conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
            conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
            conditions.needFulfilled = mem.lawCount - 1; // = the proposal law. 
            lawInitData = PowersTypes.LawInitData({
                nameDescription: "Execute and set allowance for a Powers Child at the Safe Treasury.",
                targetLaw: lawAddresses[3], // safeAllowanceAction
                config: abi.encode(
                    inputParams, 
                    bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    allowanceModuleAddress,
                    mem.safeProxy
                ),
                conditions: conditions // everythign zero == Only admin can call directly 
            });

            calldatas[15] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);

            
        return (actionId, targets, values, calldatas);
    }

    function minutesToBlocks(uint48 mins) internal view returns (uint32) {
        return uint32((mins * blocksPerHour) / 60);
    }
}
 