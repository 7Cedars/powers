// SPDX-License-Identifier: MIT

/// @notice An example implementation of a Mandate Package that adopts multiple mandates into the Powers protocol.
/// It is meant to be adopted through the AdoptMandates mandate, and then be executed to adopt multiple mandates in a single transaction.
/// The mandate self-destructs after execution.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../Mandate.sol";
import { MandateUtilities } from "../libraries/MandateUtilities.sol";
import { IPowers } from "../interfaces/IPowers.sol";
import { Powers } from "../Powers.sol";
import { PowersTypes } from "../interfaces/PowersTypes.sol";
import { ModuleManager } from "../../lib/safe-smart-account/contracts/base/ModuleManager.sol";
import { SafeL2 } from "lib/safe-smart-account/contracts/SafeL2.sol";

// This MandatePackage adopts the following governance paths:
// path 0 + 1: init Allowance Module.
// path 2: adopt new child.
// path 3: assign allowance to child.

// import { console2 } from "forge-std/console2.sol"; // only for testing purposes.

contract PowerLabsConfig is Mandate {
    struct Mem {
        uint16 mandateCount;
        address safeProxy;
        bytes signature;
    }
    address[] private mandateAddresses;
    address private allowanceModuleAddress;
    uint16 public constant NUMBER_OF_CALLS = 18; // total number of calls in handleRequest
    uint48 public immutable BLOCKS_PER_HOUR;

    // in this case mandateAddresses should be [statementOfIntent, SafeExecTransaction, PresetSingleAction, SafeAllowanceAction, RoleByTransaction]
    constructor(uint48 BLOCKS_PER_HOUR_, address[] memory mandateAddresses_, address allowanceModuleAddress_) {
        BLOCKS_PER_HOUR = BLOCKS_PER_HOUR_;
        mandateAddresses = mandateAddresses_;
        allowanceModuleAddress = allowanceModuleAddress_;

        emit Mandate__Deployed(abi.encode());
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        inputParams = abi.encode("address SafeProxy");
        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Build calls.
    /// intentionally this mandate packacge is kept very 'flat'. No loops or dynamic arrays to keep things understandable.
    /// @param mandateCalldata Unused for this mandate
    function handleRequest(
        address,
        /*caller*/
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
        Mem memory mem;

        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);
        mem.mandateCount = Powers(powers).mandateCounter();
        (mem.safeProxy) = abi.decode(mandateCalldata, (address));
        mem.signature = abi.encodePacked(
            uint256(uint160(powers)), // r = address of the signer (powers contract)
            uint256(0), // s = 0
            uint8(1) // v = 1 This is a type 1 call. See Safe.sol for details.
        );

        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(NUMBER_OF_CALLS);

        /////////////////////////////////////////////////////////////////////////////////////////////////////
        // DIRECT CALLS TO POWERS CONTRACT TO ADOPT THE ALLOWANCE MODULE AND SET THE SAFEPROXY AS TREASURY //
        /////////////////////////////////////////////////////////////////////////////////////////////////////

        // 1: adopt Allowance Module
        targets[0] = mem.safeProxy; // Safe contract
        calldatas[0] = abi.encodeWithSelector(
            SafeL2.execTransaction.selector,
            mem.safeProxy, // The internal transaction's destination
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
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

        for (uint256 i = 1; i < NUMBER_OF_CALLS; i++) {
            targets[i] = powers;
        }

        // 3: assign labels to roles.
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Funders");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Doc Contributors");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Frontend Contributors");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Protocol Contributors");
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Members");

        // 4: set final call to self-destruct the MandatePackage after adopting the mandates
        calldatas[NUMBER_OF_CALLS - 1] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateId);

        //////////////////////////////////////////////////////////////////////////
        //                  ELECTORAL LAWS (BUY FUNDER ROLE)                    //
        //////////////////////////////////////////////////////////////////////////
        PowersTypes.Conditions memory conditions;
        string[] memory inputParams;
        PowersTypes.MandateInitData memory mandateInitData;

        // RoleByTransaction
        conditions.allowedRole = type(uint256).max; // == PUBLIC_ROLE: anyone can call this mandate.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "Buy Funder Role: Make a contribution of more than 0.1 ether (written in its smallest denomination) in TAX token (0x93d94e8D5DC29C6610946C3226e5Be4e4FB503Ce) to be granted a funder role.",
            targetMandate: mandateAddresses[4], // RoleByTransaction
            config: abi.encode(
                0x93d94e8D5DC29C6610946C3226e5Be4e4FB503Ce, // token = TAX token
                1 ether / 10, // amount = 0.1 Ether minimum
                1, // newRoleId = Funder role
                mem.safeProxy // safeProxy == treasury
            ),
            conditions: conditions
        });

        calldatas[6] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        //////////////////////////////////////////////////////////////////////////
        //   GOVERNANCE FLOW FOR ADOPTING DELEGATE / CHILD POWERS DEPLOYMENTS   //
        //////////////////////////////////////////////////////////////////////////

        // statementOfIntent params
        inputParams = new string[](1);
        inputParams[0] = "address NewChildPowers";
        conditions.allowedRole = 5; // = Members can call this mandate.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); //
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "Propose to add a new Child Powers as a delegate to the Safe Treasury.",
            targetMandate: mandateAddresses[0], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });

        calldatas[7] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        conditions.allowedRole = 1; // = funders.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
        conditions.needFulfilled = mem.mandateCount - 1; // = mandate that must be completed before this one.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "Veto adding a new Child Powers as a delegate to the Safe Treasury.",
            targetMandate: mandateAddresses[0], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });

        calldatas[8] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        conditions.allowedRole = 2; // = doc contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
        conditions.needFulfilled = mem.mandateCount - 2; // = the proposal mandate.
        conditions.needNotFulfilled = mem.mandateCount - 1; // = the funders veto mandate.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "OK adding a new Child Powers as a delegate to the Safe Treasury.",
            targetMandate: mandateAddresses[0], // statementOfIntent.
            config: abi.encode(inputParams),
            conditions: conditions
        });

        calldatas[9] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        conditions.allowedRole = 3; // = frontend contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
        conditions.needFulfilled = mem.mandateCount - 1; // = the proposal mandate.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "OK adding a new Child Powers as a delegate to the Safe Treasury.",
            targetMandate: mandateAddresses[0], // statementOfIntent.
            config: abi.encode(inputParams),
            conditions: conditions
        });

        calldatas[10] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        conditions.allowedRole = 4; // = protocol contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(10); // = number of blocks
        conditions.needFulfilled = mem.mandateCount - 1; // = the proposal mandate.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "Execute and adopt new child Powers as a delegate to the Safe treasury.",
            targetMandate: mandateAddresses[3], // safeAllowanceAction
            config: abi.encode(
                inputParams,
                bytes4(0xe71bdf41), // == AllowanceModule.addDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                allowanceModuleAddress,
                mem.safeProxy
            ),
            conditions: conditions // everythign zero == Only admin can call directly
        });

        calldatas[11] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

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

        conditions.allowedRole = 5; // = Members can call this mandate.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "Propose to set allowance for a Powers Child at the Safe Treasury.",
            targetMandate: mandateAddresses[0], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });

        calldatas[12] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        conditions.allowedRole = 1; // = funders.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
        conditions.needFulfilled = mem.mandateCount - 1; // = mandate that must be completed before this one.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "Veto setting allowance for a Powers Child at the Safe Treasury.",
            targetMandate: mandateAddresses[0], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });

        calldatas[13] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        conditions.allowedRole = 2; // = doc contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
        conditions.needFulfilled = mem.mandateCount - 2; // = the proposal mandate.
        conditions.needNotFulfilled = mem.mandateCount - 1; // = the funders veto mandate.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "OK setting allowance for a Powers Child at the Safe Treasury.",
            targetMandate: mandateAddresses[0], // statementOfIntent.
            config: abi.encode(inputParams),
            conditions: conditions
        });

        calldatas[14] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        conditions.allowedRole = 3; // = frontend contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
        conditions.needFulfilled = mem.mandateCount - 1; // = the proposal mandate.
        delete conditions.needNotFulfilled; // = no veto mandate.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "OK setting allowance for a Powers Child at the Safe Treasury.",
            targetMandate: mandateAddresses[0], // statementOfIntent.
            config: abi.encode(inputParams),
            conditions: conditions
        });

        calldatas[15] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);
        delete conditions;
        mem.mandateCount++;

        conditions.allowedRole = 4; // = protocol contributors.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks
        conditions.needFulfilled = mem.mandateCount - 1; // = the proposal mandate.
        mandateInitData = PowersTypes.MandateInitData({
            nameDescription: "Execute and set allowance for a Powers Child at the Safe Treasury.",
            targetMandate: mandateAddresses[3], // safeAllowanceAction
            config: abi.encode(
                inputParams,
                bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                allowanceModuleAddress,
                mem.safeProxy
            ),
            conditions: conditions // everythign zero == Only admin can call directly
        });

        calldatas[16] = abi.encodeWithSelector(IPowers.adoptMandate.selector, mandateInitData);

        return (actionId, targets, values, calldatas);
    }

    function minutesToBlocks(uint48 mins) internal view returns (uint32) {
        return uint32((mins * BLOCKS_PER_HOUR) / 60);
    }
}
