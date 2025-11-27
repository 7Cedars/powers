// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";
import { Nominees } from "../src/helpers/Nominees.sol";

contract TestConstitutions is Test {
    uint256[] milestoneDisbursements;
    uint256 PrevActionId;

    bytes[] staticParams;
    string[] dynamicParams;
    uint8[] indexDynamicParams;
    string[] dynamicParamsSimple;

    // State variables to avoid stack too deep errors
    PowersTypes.Conditions conditions;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string[] inputParams;
    address[] tokens;
    uint256[] tokensPerBlock;
    uint256[] roles;
    uint256[] roleIds;
    uint256[] roleIdsNeeded;
    address[] lawsToAdopt;
    bytes[] lawInitDatas;
    string[] descriptions;
    string[] params;

    //////////////////////////////////////////////////////////////
    //                 POWERS CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    /// @notice initiate the powers constitution. Follows the Powers101 governance structure.
    function powersTestConstitution(
        string[] memory, /*lawNames*/
        address[] memory lawAddresses,
        string[] memory, /*mockNames*/
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData) {
        lawInitData = new PowersTypes.LawInitData[](7);

        // dummy call.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        // Note: I leave the first slot empty, so that numbering is equal to how laws are registered in IPowers.sol.
        // Counting starts at 1, so the first law is lawId = 1.

        // slef select as communtiy member
        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Self select as community member: Self select as a community member. Anyone can call this law.",
            targetLaw: lawAddresses[18], // selfSelct
            config: abi.encode( 
                1 // community member role ID
            ), 
            conditions: conditions
        });
        delete conditions;

        // self Select as delegate 
        conditions.allowedRole = type(uint256).max;
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Self select as delegate: Self select as a delegate. Only community members can call this law.",
            targetLaw: lawAddresses[18], // selfSelct
            config: abi.encode( 
                2 // delegeate member role ID
            ),
            conditions: conditions
        });
        delete conditions;

        // proposalOnly
        inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = 1; // = role that can call this law.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.throttleExecution = 5000;
        conditions.delayExecution = 250; // = 250 blocks to wait after proposal success before execution
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "StatementOfIntent: Propose any kind of action.",
            targetLaw: lawAddresses[4], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 0; // = admin.
        conditions.needFulfilled = 3; // = law that must be completed before this one.
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetLaw: lawAddresses[4], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 2; // = role that can call this law.
        conditions.needFulfilled = 3; // = law that must be completed before this one.
        conditions.needNotFulfilled = 4; // = law that must not be completed before this one.
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "Execute an action: Execute an action that has been proposed by the community and should not have been vetoed by an admin.",
            targetLaw: lawAddresses[3], // openAction.
            config: abi.encode(), // empty config.
            conditions: conditions
        });
        delete conditions;

        // PresetSingleAction
        // Set config
        targets = new address[](4);
        values = new uint256[](4);
        calldatas = new bytes[](4);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = daoMock; // = Powers contract.
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(IPowers.assignRole.selector, 5, makeAddr("alice"));
        calldatas[3] = abi.encodeWithSelector(IPowers.revokeLaw.selector, 6); // revoke law after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetLaw: lawAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  LAW CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function lawTestConstitution(
        string[] memory, /*lawNames*/
        address[] memory lawAddresses,
        string[] memory, /*mockNames*/
        address[] memory mockAddresses,
        address payable daoMock
    ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        lawInitData = new PowersTypes.LawInitData[](7);

        // dummy call: mint coins at mock1155 contract.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = mockAddresses[3]; // erc1155Mock
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(SimpleErc1155.mintCoins.selector, 123);

        // setting up config file
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.allowedRole = 1;
        // initiating law.
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "StatementOfIntent: Needs Proposal Vote to pass",
            targetLaw: lawAddresses[4], // statementOfIntent
            config: abi.encode(),
            conditions: conditions
        });
        delete conditions;

        // setting up config file
        conditions.needFulfilled = 1;
        conditions.allowedRole = 1;
        // initiating law.
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "PresetSingleActions: Needs Parent Completed to pass",
            targetLaw: lawAddresses[1], // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // setting up config file
        conditions.needNotFulfilled = 1;
        conditions.allowedRole = 1;
        // initiating law.
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "PresetSingleActions: Parent can block a law, making it impossible to pass",
            targetLaw: lawAddresses[1], // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
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
            nameDescription: "PresetSingleActions: Delay execution of a law, by a preset number of blocks",
            targetLaw: lawAddresses[1], // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // setting up config file
        conditions.allowedRole = 1;
        conditions.throttleExecution = 5000;
        // initiating law.
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "PresetSingleActions: Throttle the number of executions of a law.",
            targetLaw: lawAddresses[1], // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // PresetSingleAction
        // Set config
        targets = new address[](3);
        values = new uint256[](3);
        calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = daoMock; // = Powers contract.
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeLaw.selector, 7); // revoke law after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetLaw: lawAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;
    }

    ////////////////////////////////////////////////////////////
    //                ELECTORAL CONSTITUTION                  //
    ////////////////////////////////////////////////////////////
    function electoralTestConstitution(
        string[] memory, /* lawNames */
        address[] memory lawAddresses,
        string[] memory, /* mockNames */
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData) {
        lawInitData = new PowersTypes.LawInitData[](12);

        // ElectionSelect - for delegate elections
        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "ElectionSelect: A law to run delegate elections and assign roles based on results.",
            targetLaw: lawAddresses[11], // ElectionSelect (electoral law)
            config: abi.encode(
                mockAddresses[10], // Erc20DelegateElection contract
                3, // roleId to be elected
                3 // max role holders
            ),
            conditions: conditions
        });
        delete conditions;

        // PeerSelect - for peer voting
        conditions.allowedRole = type(uint256).max;
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "PeerSelect: A law to select roles by peer votes from nominees.",
            targetLaw: lawAddresses[12], // PeerSelect (electoral law)
            config: abi.encode(
                2, // max role holders
                4, // roleId to be assigned
                1, // max votes per voter
                mockAddresses[8] // Nominees contract
            ),
            conditions: conditions
        });
        delete conditions;

        // VoteInOpenElection - for voting in open elections
        conditions.allowedRole = type(uint256).max;
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "VoteInOpenElection: A law to vote in open elections.",
            targetLaw: lawAddresses[13], // VoteInOpenElection (electoral law)
            config: abi.encode(mockAddresses[9], 1), // OpenElection contract, max votes per voter
            conditions: conditions
        });
        delete conditions;

        // TaxSelect - for tax-based role assignment
        conditions.allowedRole = type(uint256).max;
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "TaxSelect: A law to assign roles based on tax payments.",
            targetLaw: lawAddresses[15], // TaxSelect (electoral law)
            config: abi.encode(
                mockAddresses[1], // Erc20Taxed mock
                1000, // threshold tax paid
                4 // roleId to be assigned
            ),
            conditions: conditions
        });
        delete conditions;

        // BuyAccess - for buying role access with tokens
        tokens = new address[](2);
        tokensPerBlock = new uint256[](2);
        tokens[0] = mockAddresses[1]; // Erc20Taxed mock
        tokens[1] = address(0); // native currency.
        tokensPerBlock[0] = 1000; // tokens per block for access
        tokensPerBlock[1] = 100;

        conditions.allowedRole = type(uint256).max;
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "BuyAccess: A law to buy role access with ERC20 tokens.",
            targetLaw: lawAddresses[16], // BuyAccess (electoral law)
            config: abi.encode(
                mockAddresses[11], // Treasury simple
                tokens,
                tokensPerBlock,
                4 // roleId to be assigned
            ),
            conditions: conditions
        });
        delete conditions;

        // SelfSelect - for self-assignment
        conditions.allowedRole = type(uint256).max;
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "SelfSelect: A law to self-assign a role.",
            targetLaw: lawAddresses[18], // SelfSelect (electoral law)
            config: abi.encode(4), // roleId to be assigned
            conditions: conditions
        });
        delete conditions;

        // RenounceRole - for renouncing roles
        roles = new uint256[](2);
        roles[0] = 1;
        roles[1] = 2;
        conditions.allowedRole = type(uint256).max;
        lawInitData[7] = PowersTypes.LawInitData({
            nameDescription: "RenounceRole: A law to renounce specific roles.",
            targetLaw: lawAddresses[19], // RenounceRole (electoral law)
            config: abi.encode(roles), // roles that can be renounced
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = type(uint256).max;
        lawInitData[8] = PowersTypes.LawInitData({
            nameDescription: "NStrikesRevokesRoles: A law to revoke roles after N strikes.",
            targetLaw: lawAddresses[14], // NStrikesRevokesRoles (electoral law)
            config: abi.encode(
                3, // roleId to be revoked.
                2, // number of strikes needed to be revoked.
                mockAddresses[6] // FlagActions contract
            ),
            conditions: conditions
        });
        delete conditions;

        // RoleByRoles - for role-based role assignment
        roleIdsNeeded = new uint256[](2);
        roleIdsNeeded[0] = 1;
        roleIdsNeeded[1] = 2;
        conditions.allowedRole = type(uint256).max;
        lawInitData[9] = PowersTypes.LawInitData({
            nameDescription: "RoleByRoles: A law to assign roles based on existing role holders.",
            targetLaw: lawAddresses[17], // RoleByRoles (electoral law)
            config: abi.encode(
                4, // target role (what gets assigned)
                roleIdsNeeded // roles that are needed to be assigned
            ),
            conditions: conditions
        });
        delete conditions;

        // PresetSingleAction
        // Set config
        targets = new address[](3);
        values = new uint256[](3);
        calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = daoMock; // = Powers contract.
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeLaw.selector, 7); // revoke law after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        lawInitData[10] = PowersTypes.LawInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetLaw: lawAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // AssignExternalRole
        conditions.allowedRole = type(uint256).max;
        lawInitData[11] = PowersTypes.LawInitData({
            nameDescription: "AssignExternalRole: A law to assign a role if the account has a role on an external contract.",
            targetLaw: lawAddresses[29], // AssignExternalRole (electoral law)
            config: abi.encode(
                daoMock, // external Powers contract (using self for test)
                1 // roleId to be checked
            ),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  EXECUTIVE CONSTITUTION                  //
    //////////////////////////////////////////////////////////////
    function executiveTestConstitution(
        string[] memory, /* lawNames */
        address[] memory lawAddresses,
        string[] memory, /* mockNames */
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData) {
        lawInitData = new PowersTypes.LawInitData[](7);

        // StatementOfIntent - for proposing actions
        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "StatementOfIntent: A law to propose actions without execution.",
            targetLaw: lawAddresses[4], // StatementOfIntent (multi law)
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // GovernorCreateProposal - for creating governance proposals
        conditions.allowedRole = 1; // role 1 can create proposals
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "GovernorCreateProposal: A law to create governance proposals on a Governor contract.",
            targetLaw: lawAddresses[9], // GovernorCreateProposal (executive law)
            config: abi.encode(mockAddresses[4]), // SimpleGovernor mock address
            conditions: conditions
        });
        delete conditions;

        // GovernorExecuteProposal - for executing governance proposals
        conditions.allowedRole = 1; // role 1 can execute proposals
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "GovernorExecuteProposal: A law to execute governance proposals on a Governor contract.",
            targetLaw: lawAddresses[10], // GovernorExecuteProposal (executive law)
            config: abi.encode(mockAddresses[4]), // SimpleGovernor mock address
            conditions: conditions
        });
        delete conditions;

        // AdoptLaws - for adopting new laws
        lawsToAdopt = new address[](1);
        lawInitDatas = new bytes[](1);

        // Create a simple law init data for adoption
        PowersTypes.LawInitData memory adoptLawData = PowersTypes.LawInitData({
            nameDescription: "Test Adopted Law",
            targetLaw: lawAddresses[1], // PresetSingleAction
            config: abi.encode(
                new address[](1), // empty targets
                new uint256[](1), // empty values
                new bytes[](1) // empty calldatas
            ),
            conditions: PowersTypes.Conditions({
                allowedRole: type(uint256).max,
                quorum: 0,
                succeedAt: 0,
                votingPeriod: 0,
                delayExecution: 0,
                throttleExecution: 0,
                needFulfilled: 0,
                needNotFulfilled: 0
            })
        });

        lawsToAdopt[0] = lawAddresses[1];
        lawInitDatas[0] = abi.encode(adoptLawData);

        conditions.allowedRole = type(uint256).max; // public role can adopt laws
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "AdoptLawPackage: A law to adopt new laws into the DAO.",
            targetLaw: lawAddresses[8], // AdoptLaws (executive law)
            config: abi.encode(lawsToAdopt, lawInitDatas),
            conditions: conditions
        });
        delete conditions;

        // PresetSingleAction
        // Set config
        targets = new address[](3);
        values = new uint256[](3);
        calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = daoMock; // = Powers contract.
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeLaw.selector, 5); // revoke law after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetLaw: lawAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // OpenAction - for executing any action
        conditions.allowedRole = type(uint256).max;
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "OpenAction: A law to execute any action with full power.",
            targetLaw: lawAddresses[3], // OpenAction (multi law)
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                    MULTI CONSTITUTION                    //
    //////////////////////////////////////////////////////////////
    function multiTestConstitution(
        string[] memory, /* lawNames */
        address[] memory lawAddresses,
        string[] memory, /* mockNames */
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData) {
        lawInitData = new PowersTypes.LawInitData[](8);

        // OpenAction - allows any action to be executed
        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "OpenAction: A law to execute any action with full power.",
            targetLaw: lawAddresses[3], // OpenAction (multi law)
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // StatementOfIntent - for proposing actions without execution
        conditions.allowedRole = type(uint256).max;
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "StatementOfIntent: A law to propose actions without execution.",
            targetLaw: lawAddresses[4], // StatementOfIntent (multi law)
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // BespokeActionSimple - for simple function calls
        params = new string[](1);
        params[0] = "uint256 Quantity";
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "BespokeActionSimple: A law to execute a simple function call.",
            targetLaw: lawAddresses[6], // BespokeActionSimple (multi law)
            config: abi.encode(
                mockAddresses[3], // SimpleErc1155 mock
                SimpleErc1155.mintCoins.selector,
                params
            ),
            conditions: conditions
        });
        delete conditions;

        // BespokeActionAdvanced - for complex function calls with mixed parameters
        staticParams = new bytes[](1);
        staticParams[0] = abi.encode(1); // roleId = 1
        dynamicParams = new string[](1);
        dynamicParams[0] = "address Account";
        indexDynamicParams = new uint8[](1);
        indexDynamicParams[0] = 1; // insert at position 1

        conditions.allowedRole = 1;
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "BespokeActionAdvanced: A law to execute complex function calls with mixed parameters.",
            targetLaw: lawAddresses[5], // BespokeActionAdvanced (multi law)
            config: abi.encode(
                daoMock, // Powers contract
                IPowers.assignRole.selector,
                staticParams,
                dynamicParams,
                indexDynamicParams
            ),
            conditions: conditions
        });
        delete conditions;

        // PresetSingleAction - for executing preset actions
        targets = new address[](2);
        values = new uint256[](2);
        calldatas = new bytes[](2);

        targets[0] = daoMock;
        targets[1] = daoMock;
        values[0] = 0;
        values[1] = 0;
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");

        conditions.allowedRole = 1;
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "PresetSingleAction: A law to execute preset actions.",
            targetLaw: lawAddresses[1], // PresetSingleAction (multi law)
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // PresetMultipleActions - for executing multiple preset actions
        descriptions = new string[](2);
        descriptions[0] = "Assign Member Role";
        descriptions[1] = "Assign Delegate Role";

        conditions.allowedRole = 1;
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "PresetMultipleActions: A law to execute multiple preset actions.",
            targetLaw: lawAddresses[2], // PresetMultipleActions (multi law)
            config: abi.encode(descriptions, targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // PresetSingleAction
        // Set config
        targets = new address[](3);
        values = new uint256[](3);
        calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = daoMock; // = Powers contract.
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeLaw.selector, 7); // revoke law after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        lawInitData[7] = PowersTypes.LawInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetLaw: lawAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                 POWERS101 CONSTITUTION                   //
    //////////////////////////////////////////////////////////////
    // very similar to the PowersConstitution. Only difference is the use of SelfSelect.
    function powers101Constitution(
        string[] memory, /*lawNames*/
        address[] memory lawAddresses,
        string[] memory, /*mockNames*/
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData) {
        lawInitData = new PowersTypes.LawInitData[](8);

        dynamicParamsSimple = new string[](1);
        dynamicParamsSimple[0] = "bool NominateMe";

        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Nominate Me: Nominate yourself for a delegate election. (Set nominateMe to false to revoke nomination)",
            targetLaw: lawAddresses[6], // bespokeActionSimple
            config: abi.encode(
                mockAddresses[10], // = Erc20DelegateElection
                Nominees.nominate.selector,
                dynamicParamsSimple
            ),
            conditions: conditions
        });
        delete conditions;

        // delegateSelect
        conditions.allowedRole = type(uint256).max; // = role that can call this law.
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Delegate Nominees: Call a delegate election. This can be done at any time. Nominations are elected on the amount of delegated tokens they have received. For",
            targetLaw: lawAddresses[10], // ElectionSelect
            config: abi.encode(
                mockAddresses[10], // = Erc20DelegateElection
                2, // role to be elected.
                3 // max number role holders
            ),
            conditions: conditions
        });
        delete conditions;

        // proposalOnly
        inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = 1; // = role that can call this law.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "StatementOfIntent: Propose any kind of action.",
            targetLaw: lawAddresses[4], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 0; // = admin.
        conditions.needFulfilled = 3; // = law that must be completed before this one.
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetLaw: lawAddresses[4], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 2; // = role that can call this law.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.succeedAt = 66; // = 51% simple majority needed for executing an action.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.needFulfilled = 3; // = law that must be completed before this one.
        conditions.needNotFulfilled = 4; // = law that must not be completed before this one.
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "Execute an action: Execute an action that has been proposed by the community and should not have been vetoed by an admin.",
            targetLaw: lawAddresses[3], // openAction.
            config: abi.encode(), // empty config.
            conditions: conditions
        });
        delete conditions;

        // PresetSingleAction
        // Set config
        targets = new address[](3);
        values = new uint256[](3);
        calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = daoMock; // = Powers contract.
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeLaw.selector, 6); // revoke law after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetLaw: lawAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //             SPLIT GOVERNANCE CONSTITUTION                //
    //////////////////////////////////////////////////////////////

    // Will be implemented later.

    // law 1: CREATE PROPOSAL

    // law 2: ASSIGN TO PATH A (SELECTORS)
    // needFulfilled: law 1
    // needNotFulfilled: law 5

    // law 3: ASSIGN TO PATH B (SELECTORS)
    // needFulfilled: law 1
    // needNotFulfilled: law 5

    // law 4: ASSIGN TO PATH C (SELECTORS)
    // needFulfilled: law 1
    // needNotFulfilled: law 5

    // law 5: ALLOCATION CLOSED (SELECTORS)
    // needFulfilled: law 1

    // law 6: (PATH A) EXECUTE PROPOSAL (EXECUTIVES)
    // needFulfilled: law 2

    // law 7: (PATH B) VETO PROPOSAL (SECURITY COUNCIL)
    // needFulfilled: law 3

    // law 8: (PATH B) EXECUTE PROPOSAL (EXECUTIVES)
    // needFulfilled: law 3
    // needNotFulfilled: law 7

    // law 9: (PATH C) PASS PROPOSAL (SECURITY COUNCIL)
    // needFulfilled: law 4

    // law 10: (PATH C) EXECUTE PROPOSAL (SECURITY COUNCIL)
    // needFulfilled: law 9

    //////////////////////////////////////////////////////////////
    //               MANAGED GRANTS CONSTITUTION                //
    //////////////////////////////////////////////////////////////

    // Will be implemented later.

    // law 1: CREATE GRANT PROPOSAL (PUBLIC)

    // law 2: SCOPE ASSESSMENT (SCOPE ASSESSOR)
    // assigns applicant role
    // needFulfilled: law 1

    // Law 3: TECHNICAL ASSESSMENT (TECHNICAL ASSESSOR)
    // needFulfilled: law 2

    // Law 4: FINANCIAL ASSESSMENT (FINANCIAL ASSESSOR)
    // needFulfilled: law 3

    // Law 5: ASSIGN GRANT (GRANT IMBURSER)
    // assigns grantee role
    // needFulfilled: law 4

    // Law 6: END GRANT (GRANT IMBURSER)
    // needFulfilled: law 5

    // Law 7: LOG COMPLAINT (APPLICANT)
    // needFulfilled: law 1

    // Law 8: JUDGE COMPLAINT (JUDGE)
    // flags action
    // needFulfilled: law 7

    // Law 9: N STRIKES YOUR OUT (PUBLIC)
    // removes ALL role holders from role.

    // Law 10: ASSIGN ANY ACCOUNT TO ANY ROLE (PARENT DAO)

    // Law 11: REQUEST PAYOUT (GRANTEE)

    // Law 12: ASSESS PAYOUT (GRANT IMBURSER)
    // sends payout to grantee
    // needFulfilled: law 11

    //////////////////////////////////////////////////////////////
    //                      MORE ORGS TBI                       //
    //////////////////////////////////////////////////////////////
    // ...

    //////////////////////////////////////////////////////////////
    //                 HELPERS CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function helpersTestConstitution(
        string[] memory, /*lawNames*/
        address[] memory lawAddresses,
        string[] memory, /*mockNames*/
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.LawInitData[] memory lawInitData) {
        lawInitData = new PowersTypes.LawInitData[](2);

        // dummy call.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        // Note: I leave the first slot empty, so that numbering is equal to how laws are registered in IPowers.sol.
        // Counting starts at 1, so the first law is lawId = 1.

        // openAction
        conditions.allowedRole = type(uint256).max;
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Open Action: Execute any action.",
            targetLaw: lawAddresses[3], // openAction
            config: abi.encode(), 
            conditions: conditions
        });
        delete conditions;
    }
}
