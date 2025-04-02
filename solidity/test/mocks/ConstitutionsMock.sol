// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { IPowers } from "../../src/interfaces/IPowers.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";

import { Erc1155Mock } from "./Erc1155Mock.sol";
import { DaoMock } from "./DaoMock.sol";
import { BaseSetup } from "../TestSetup.t.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract ConstitutionsMock is Test {
    //////////////////////////////////////////////////////////////
    //                  FIRST CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    function initiatePowersConstitution(
        address[] memory lawAddresses,
        address payable dao_,
        address payable mock20Votes_
    ) external returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](8);

        // dummy call.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        // Note: I leave the first slot empty, so that numbering is equal to how laws are registered in Powers.sol.
        // Counting starts at 1, so the first law is lawId = 1.

        // directSelect
        conditions.allowedRole = type(uint32).max;
        lawInitData[1] = PowersTypes.LawInitData({
            // = directSelect
            targetLaw: lawAddresses[1],
            config: abi.encode(1), // role that can be assigned.
            conditions: conditions,
            description: "A law to select an account to a specific role directly."
        });
        delete conditions;

        // nominateMe
        conditions.allowedRole = type(uint32).max;
        lawInitData[2] = PowersTypes.LawInitData({
            // = nominateMe
            targetLaw: lawAddresses[10],
            config: abi.encode(), // empty config.
            conditions: conditions,
            description: "A law for accounts to nominate themselves for a role."
        });
        delete conditions;

        // delegateSelect
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[0],
            config: abi.encode(
                mock20Votes_,
                15, // max role holders
                2 // roleId to be elected
            ), // role that can call the law.
            conditions: conditions,
            description: "A law to select a role by delegated votes."
        });
        delete conditions;

        // proposalOnly
        string[] memory inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = 3;
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[8],
            config: abi.encode(inputParams),
            conditions: conditions,
            description: "A law to propose a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented."
        });
        delete conditions;

        // OpenAction
        conditions.allowedRole = 2;
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[6],
            config: abi.encode(), // empty config.
            conditions: conditions,
            description: "A law to execute an open action."
        });
        delete conditions;

        // PresetAction
        conditions.allowedRole = 1;
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needCompleted = 3;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targets, values, calldatas), // empty config.
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;

        // PresetAction
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
            _getRoles(dao_, 7);
        conditions.allowedRole = 0;
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles), // empty config.
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  THIRD CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateLawTestConstitution(address[] memory lawAddresses, address payable dao_, address payable mock1155_)
        external
        returns (PowersTypes.LawInitData[] memory lawInitData)
    {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](7);

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        // setting up config file
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.allowedRole = 1;
        // initiating law.
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[8],
            config: abi.encode(),
            conditions: conditions,
            description: "Needs Proposal Vote to pass"
        });
        delete conditions;

        // setting up config file
        conditions.needCompleted = 1;
        conditions.allowedRole = 1;
        // initiating law.
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targets, values, calldatas),
            conditions: conditions,
            description: "Needs Parent Completed to pass"
        });
        delete conditions;

        // setting up config file
        conditions.needNotCompleted = 1;
        conditions.allowedRole = 1;
        // initiating law.
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targets, values, calldatas),
            conditions: conditions,
            description: "Parent can block a law, making it impossible to pass"
        });
        delete conditions;

        // setting up config file
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.delayExecution = 5000;
        conditions.allowedRole = 1;
        // initiating law.
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targets, values, calldatas),
            conditions: conditions,
            description: "Delay execution of a law, by a preset number of blocks"
        });
        delete conditions;

        // setting up config file
        conditions.allowedRole = 1;
        conditions.throttleExecution = 5000;
        // initiating law.
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targets, values, calldatas),
            conditions: conditions,
            description: "Throttle the number of executions of a by setting minimum time that should have passed since last execution"
        });
        delete conditions;

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
            _getRoles(dao_, 6);
        conditions.allowedRole = 0;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles), // empty config.
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL HELPER FUNCTION                //
    //////////////////////////////////////////////////////////////
    function _getRoles(address payable dao_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses.
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");
        address gary = makeAddr("gary");
        address helen = makeAddr("helen");

        // call to set initial roles. Also used as dummy call data.
        targets = new address[](13);
        values = new uint256[](13);
        calldatas = new bytes[](13);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }

        calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, alice);
        calldatas[1] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, bob);
        calldatas[2] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, charlotte);
        calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, david);
        calldatas[4] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, eve);
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, frank);
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, gary);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, alice);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, bob);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, charlotte);
        calldatas[10] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, alice);
        calldatas[11] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, bob);
        // revoke law after use.
        if (lawId != 0) {
            calldatas[12] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        }

        return (targets, values, calldatas);
    }
}
