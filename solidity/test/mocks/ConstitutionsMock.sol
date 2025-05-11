// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { IPowers } from "../../src/interfaces/IPowers.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";

import { Erc1155Mock } from "./Erc1155Mock.sol";
import { PowersMock } from "./PowersMock.sol";
import { BaseSetup } from "../TestSetup.t.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { DeployMocks } from "../../script/DeployMocks.s.sol";
import { DeployLaws } from "../../script/DeployLaws.s.sol";

contract ConstitutionsMock is Test  {
 
    //////////////////////////////////////////////////////////////
    //                 POWERS CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    function initiatePowersConstitution( 
        string[] memory lawNames,
        address[] memory lawAddresses,
        string[] memory mockNames,
        address[] memory mockAddresses,
        address payable daoMock 
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

        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            // = nominateMe
            targetLaw: lawAddresses[1], // directSelect
            config: abi.encode(1), 
            conditions: conditions,
            description: "A law to select an account to a specific role directly."
        });
        delete conditions;

        // nominateMe
        conditions.allowedRole = type(uint256).max;
        lawInitData[2] = PowersTypes.LawInitData({
            // = nominateMe
            targetLaw: lawAddresses[10], // nominateMe
            config: abi.encode(), // empty config.
            conditions: conditions,
            description: "A law for accounts to nominate themselves for a role."
        });
        delete conditions;

        // delegateSelect
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[0], // directSelect
            config: abi.encode(
                daoMock,
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
            targetLaw: lawAddresses[8], // proposalOnly
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
            _getActions(daoMock, 7);
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
    //                  LAW CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateLawTestConstitution(
        string[] memory lawNames,   
        address[] memory lawAddresses,
        string[] memory mockNames,
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData)
    {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](7);

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mockAddresses[5]; // erc1155Mock
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        // setting up config file
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.allowedRole = 1;
        // initiating law.
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[8], // proposalOnly
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
            targetLaw: lawAddresses[7], // presetAction
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
            targetLaw: lawAddresses[7], // presetAction
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
            targetLaw: lawAddresses[7], // presetAction
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
            targetLaw: lawAddresses[7], // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions,
            description: "Throttle the number of executions of a by setting minimum time that should have passed since last execution"
        });
        delete conditions;

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
            _getActions(daoMock, 6); // powersMock
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
    //                  ELECTORAL CONSTITUTION                  //
    //////////////////////////////////////////////////////////////
    function initiateElectoralTestConstitution(
        string[] memory lawNames,
        address[] memory lawAddresses,
        string[] memory mockNames,
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData)
    {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](14);

        // CONTINUE HERE. 
        // NB: NEED TO ADD  NOMINATE ME LAW.
        // nominateMe
        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[10], // nominateMe
            config: abi.encode(),
            conditions: conditions,
            description: "A law to nominate a role."
        });
        delete conditions;

        // delegateSelect
        conditions.allowedRole = 1;
        conditions.readStateFrom = 1;
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[0], // delegateSelect
            config: abi.encode(
                mockAddresses[2], // erc20TaxedMock
                3, // max role holders
                3 // roleId to be elected
            ),
            conditions: conditions,
            description: "A law to select a role by delegated votes."
        });
        delete conditions;

        // directSelect
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[1], // directSelect
            config: abi.encode(
                4 // role to be assigned. 
            ),
            conditions: conditions,
            description: "A law to select a role by direct votes."
        });
        delete conditions;

        // holderSelect
        conditions.allowedRole = 1;
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[14], // holderSelect
            config: abi.encode(
                mockAddresses[3], // erc20TaxedMock
                1000, //minimum tokens
                3 // roleId to be assigned
            ),
            conditions: conditions,
            description: "A law to select a role by token holdings."
        });
        delete conditions;

        // peerSelect
        conditions.allowedRole = 1;
        conditions.readStateFrom = 1;
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[2], // peerSelect
            config: abi.encode(
                2, // max role holders
                4 // roleId to be assigned
            ),
            conditions: conditions,
            description: "A law to select a role by peer votes."
        });
        delete conditions;

        // renounceRole
        uint256[] memory roles = new uint256[](1);
        roles[0] = 3;
        conditions.allowedRole = 1;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[3], // renounceRole
            config: abi.encode(
                roles // roles allowed to renounced
            ),
            conditions: conditions,
            description: "A law to renounce a role."
        });
        delete conditions;

        // selfSelect
        conditions.allowedRole = type(uint256).max;
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[4], // selfSelect
            config: abi.encode(
                4 // roleId to be assigned
            ),
            conditions: conditions,
            description: "A law to select a role by self."
        });
        delete conditions;

        // TaxSelect
        conditions.allowedRole = 1;
        lawInitData[8] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[13], // taxSelect
            config: abi.encode(
                mockAddresses[3], // erc20TaxedMock
                1000, //threshold of tax paid tokens
                3 // roleId to be assigned
            ),
            conditions: conditions,
            description: "A law to select a role by tax."
        });
        delete conditions;

        // DirectDeselect
        conditions.allowedRole = 1;
        lawInitData[9] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[20], // directDeselect
            config: abi.encode(
                4 // roleId to be revoked
            ),
            conditions: conditions,
            description: "A law to revoke a role."
        });
        delete conditions;

        // Subscription
        conditions.allowedRole = 1;
        lawInitData[10] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[21], // subscription
            config: abi.encode(
                120, // epoch duration
                1000, // subscription amount
                4 // roleId to be assigned or revoked
            ),
            conditions: conditions,
            description: "A law to subscribe to a role."
        });
        delete conditions;

        // startElection
        conditions.allowedRole = 0;
        ILaw.Conditions memory electionConditions;
        electionConditions.allowedRole = 1;
        lawInitData[11] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[22], // startElection
            config: abi.encode(
                lawAddresses[19], // VoteOnAccounts
                abi.encode(electionConditions)
            ),
            conditions: conditions,
            description: "A law to start an election."
        });
        delete conditions;

        // EndElection
        conditions.allowedRole = 0;
        conditions.needCompleted = 11; 
        conditions.readStateFrom = 1;
        lawInitData[12] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[23], // EndElection
            config: abi.encode(),
            conditions: conditions,
            description: "A law to stop an election."
        });
        delete conditions;

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
            _getActions(daoMock, 13); // powersMock
        conditions.allowedRole = 0;
        lawInitData[13] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles), // empty config.
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;
    }

        
    //////////////////////////////////////////////////////////////
    //                  EXECUTIVE CONSTITUTION                  //
    //////////////////////////////////////////////////////////////
    function initiateExecutiveTestConstitution(
        string[] memory lawNames,
        address[] memory lawAddresses,
        string[] memory mockNames,
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData)
    {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](10);

        // proposalOnly
        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[8], // proposalOnly
            config: abi.encode(abi.encode("address[] Targets")),
            conditions: conditions,
            description: "A law to propose a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented."
        });
        delete conditions;

        // openAction
        conditions.allowedRole = type(uint256).max;
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[6], // openAction
            config: abi.encode(),
            conditions: conditions,
            description: "A law to execute an open action."
        });
        delete conditions;

        // Bespoke Action 
        string[] memory params = new string[](1);
        params[0] = "uint256 Quantity";
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[5], // Bespoke Action 
            config: abi.encode(
                mockAddresses[5],
                Erc1155Mock.mintCoins.selector, // bespokeActionMock
                params
            ),
            conditions: conditions,
            description: "A law to execute a bespoke action."
        });
        delete conditions;

        // presetAction
        address[] memory targets = new address[](1);
        targets[0] = mockAddresses[5];
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        conditions.allowedRole = 1;
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7], // presetAction
            config: abi.encode(
                targets,
                values,
                calldatas
            ),
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;

        // grant law 
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[15], // grantLaw
            config: abi.encode(
                1000,
                1 * 10 ** 18,
                mockAddresses[3]
            ),
            conditions: conditions,
            description: "A grant law."
        });
        delete conditions;

        // startGrant 
        conditions.allowedRole = 1;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[16], // startGrant
            config: abi.encode(
                lawInitData[5].targetLaw,
                abi.encode(conditions)
            ),
            conditions: conditions,
            description: "A law to start a grant."
        });
        delete conditions;

        // EndGrant
        conditions.allowedRole = 1;
        conditions.needCompleted = 6;
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[17], // EndGrant
            config: abi.encode(
                1000,
                true
            ),
            conditions: conditions,
            description: "A law to stop a grant."
        });
        delete conditions;

        // adoptLaw
        conditions.allowedRole = 1;
        lawInitData[8] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[18], // adoptLaw
            config: abi.encode(),
            conditions: conditions,
            description: "A law to adopt a law."
        });
        delete conditions;

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
            _getActions(daoMock, 9); // powersMock
        conditions.allowedRole = 0;
        lawInitData[9] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles), 
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  STATE LAW CONSTITUTION                  //
    //////////////////////////////////////////////////////////////
    function initiateStateTestConstitution(
        string[] memory lawNames,
        address[] memory lawAddresses,
        string[] memory mockNames,
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData)
    {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](8);

        // Grant
        conditions.allowedRole = 1;
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[15], // Grant
            config: abi.encode(
                10_000, // duration
                1 * 10 ** 18, // budget = 1 ERC 20 token
                mockAddresses[3] // tokenAddress
            ),
            conditions: conditions,
            description: "A law to manage grants."
        });
        delete conditions;

        // NominateMe
        conditions.allowedRole = type(uint256).max;
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[10], // NominateMe
            config: abi.encode(),
            conditions: conditions,
            description: "A law for accounts to nominate themselves for a role."
        });
        delete conditions;

        // StringsArray
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[11], // StringsArray
            config: abi.encode(),
            conditions: conditions,
            description: "A law to manage arrays of strings."
        });
        delete conditions;

        // TokensArray
        conditions.allowedRole = 1;
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[12], // TokensArray
            config: abi.encode(),
            conditions: conditions,
            description: "A law to manage arrays of tokens."
        });
        delete conditions;

        // VoteOnAccounts
        conditions.allowedRole = 1;
        conditions.readStateFrom = 2;
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[19], // VoteOnAccounts
            config: abi.encode(
                5000, // startvote 
                6000 // endvote
            ),
            conditions: conditions,
            description: "A law to vote on nominated candidates."
        });
        delete conditions;

        // AddressesMapping
        conditions.allowedRole = 1;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[9], // AddressesMapping
            config: abi.encode(),
            conditions: conditions,
            description: "A law to manage mappings of addresses."
        });
        delete conditions;

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
            _getActions(daoMock, 7); // powersMock
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
    //                  INTERNAL HELPER FUNCTION                //
    //////////////////////////////////////////////////////////////
    function _getActions(address powers_, uint16 lawId)
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
            targets[i] = powers_;
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
