// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";
import { Nominees } from "../src/helpers/Nominees.sol";

import { HelperConfig } from "../script/HelperConfig.s.sol";

contract TestConstitutions is Test {
    uint256[] milestoneDisbursements;

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
    address[] mandatesToAdopt;
    bytes[] mandateInitDatas;
    string[] descriptions;
    string[] params;

    HelperConfig helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig config = helperConfig.getConfig();

    //////////////////////////////////////////////////////////////
    //                 POWERS CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    /// @notice initiate the powers constitution. Follows the Powers101 governance structure.
    function powersTestConstitution(
        string[] memory, /*mandateNames*/
        address[] memory mandateAddresses,
        string[] memory, /*mockNames*/
        address[] memory,
        address payable daoMock
    ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        mandateInitData = new PowersTypes.MandateInitData[](7);

        // dummy call.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        // Note: I leave the first slot empty, so that numbering is equal to how mandates are registered in IPowers.sol.
        // Counting starts at 1, so the first mandate is mandateId = 1.

        // slef select as communtiy member
        conditions.allowedRole = type(uint256).max;
        mandateInitData[1] = PowersTypes.MandateInitData({
            nameDescription: "Self select as community member: Self select as a community member. Anyone can call this mandate.",
            targetMandate: mandateAddresses[18], // selfSelct
            config: abi.encode(
                1 // community member role ID
            ),
            conditions: conditions
        });
        delete conditions;

        // self Select as delegate
        conditions.allowedRole = type(uint256).max;
        mandateInitData[2] = PowersTypes.MandateInitData({
            nameDescription: "Self select as delegate: Self select as a delegate. Only community members can call this mandate.",
            targetMandate: mandateAddresses[18], // selfSelct
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

        conditions.allowedRole = 1; // = role that can call this mandate.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.throttleExecution = 5000;
        conditions.timelock = 250; // = 250 blocks to wait after proposal success before execution
        mandateInitData[3] = PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: Propose any kind of action.",
            targetMandate: mandateAddresses[4], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 0; // = admin.
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        mandateInitData[4] = PowersTypes.MandateInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetMandate: mandateAddresses[4], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 2; // = role that can call this mandate.
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        conditions.needNotFulfilled = 4; // = mandate that must not be completed before this one.
        mandateInitData[5] = PowersTypes.MandateInitData({
            nameDescription: "Execute an action: Execute an action that has been proposed by the community and should not have been vetoed by an admin.",
            targetMandate: mandateAddresses[3], // openAction.
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
        calldatas[3] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 6); // revoke mandate after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        mandateInitData[6] = PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: mandateAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  LAW CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function mandateTestConstitution(
        string[] memory, /*mandateNames*/
        address[] memory mandateAddresses,
        string[] memory, /*mockNames*/
        address[] memory mockAddresses,
        address payable daoMock
    ) public returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        mandateInitData = new PowersTypes.MandateInitData[](7);

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
        // initiating mandate.
        mandateInitData[1] = PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: Needs Proposal Vote to pass",
            targetMandate: mandateAddresses[4], // statementOfIntent
            config: abi.encode(),
            conditions: conditions
        });
        delete conditions;

        // setting up config file
        conditions.needFulfilled = 1;
        conditions.allowedRole = 1;
        // initiating mandate.
        mandateInitData[2] = PowersTypes.MandateInitData({
            nameDescription: "PresetSingleActions: Needs Parent Completed to pass",
            targetMandate: mandateAddresses[1], // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // setting up config file
        conditions.needNotFulfilled = 1;
        conditions.allowedRole = 1;
        // initiating mandate.
        mandateInitData[3] = PowersTypes.MandateInitData({
            nameDescription: "PresetSingleActions: Parent can block a mandate, making it impossible to pass",
            targetMandate: mandateAddresses[1], // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // setting up config file
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.timelock = 5000;
        conditions.allowedRole = 1;
        // initiating mandate.
        mandateInitData[4] = PowersTypes.MandateInitData({
            nameDescription: "PresetSingleActions: Delay execution of a mandate, by a preset number of blocks",
            targetMandate: mandateAddresses[1], // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // setting up config file
        conditions.allowedRole = 1;
        conditions.throttleExecution = 5000;
        // initiating mandate.
        mandateInitData[5] = PowersTypes.MandateInitData({
            nameDescription: "PresetSingleActions: Throttle the number of executions of a mandate.",
            targetMandate: mandateAddresses[1], // presetAction
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
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 7); // revoke mandate after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        mandateInitData[6] = PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: mandateAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;
    }

    ////////////////////////////////////////////////////////////
    //                ELECTORAL CONSTITUTION                  //
    ////////////////////////////////////////////////////////////
    function electoralTestConstitution(
        string[] memory, /* mandateNames */
        address[] memory mandateAddresses,
        string[] memory, /* mockNames */
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        mandateInitData = new PowersTypes.MandateInitData[](12);

        // OpenElectionEnd - for delegate elections
        conditions.allowedRole = type(uint256).max;
        mandateInitData[1] = PowersTypes.MandateInitData({
            nameDescription: "OpenElectionEnd: A mandate to run delegate elections and assign roles based on results.",
            targetMandate: mandateAddresses[11], // OpenElectionEnd (electoral mandate)
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
        mandateInitData[2] = PowersTypes.MandateInitData({
            nameDescription: "PeerSelect: A mandate to select roles by peer votes from nominees.",
            targetMandate: mandateAddresses[12], // PeerSelect (electoral mandate)
            config: abi.encode(
                2, // max role holders
                4, // roleId to be assigned
                1, // max votes per voter
                mockAddresses[8] // Nominees contract
            ),
            conditions: conditions
        });
        delete conditions;

        // OpenElectionVote - for voting in open elections
        conditions.allowedRole = type(uint256).max;
        mandateInitData[3] = PowersTypes.MandateInitData({
            nameDescription: "OpenElectionVote: A mandate to vote in open elections.",
            targetMandate: mandateAddresses[13], // OpenElectionVote (electoral mandate)
            config: abi.encode(mockAddresses[9], 1), // OpenElection contract, max votes per voter
            conditions: conditions
        });
        delete conditions;

        // TaxSelect - for tax-based role assignment
        conditions.allowedRole = type(uint256).max;
        mandateInitData[4] = PowersTypes.MandateInitData({
            nameDescription: "TaxSelect: A mandate to assign roles based on tax payments.",
            targetMandate: mandateAddresses[15], // TaxSelect (electoral mandate)
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
        mandateInitData[5] = PowersTypes.MandateInitData({
            nameDescription: "BuyAccess: A mandate to buy role access with ERC20 tokens.",
            targetMandate: mandateAddresses[16], // BuyAccess (electoral mandate)
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
        mandateInitData[6] = PowersTypes.MandateInitData({
            nameDescription: "SelfSelect: A mandate to self-assign a role.",
            targetMandate: mandateAddresses[18], // SelfSelect (electoral mandate)
            config: abi.encode(4), // roleId to be assigned
            conditions: conditions
        });
        delete conditions;

        // RenounceRole - for renouncing roles
        roles = new uint256[](2);
        roles[0] = 1;
        roles[1] = 2;
        conditions.allowedRole = type(uint256).max;
        mandateInitData[7] = PowersTypes.MandateInitData({
            nameDescription: "RenounceRole: A mandate to renounce specific roles.",
            targetMandate: mandateAddresses[19], // RenounceRole (electoral mandate)
            config: abi.encode(roles), // roles that can be renounced
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = type(uint256).max;
        mandateInitData[8] = PowersTypes.MandateInitData({
            nameDescription: "NStrikesRevokesRoles: A mandate to revoke roles after N strikes.",
            targetMandate: mandateAddresses[14], // NStrikesRevokesRoles (electoral mandate)
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
        mandateInitData[9] = PowersTypes.MandateInitData({
            nameDescription: "RoleByRoles: A mandate to assign roles based on existing role holders.",
            targetMandate: mandateAddresses[17], // RoleByRoles (electoral mandate)
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
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 7); // revoke mandate after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        mandateInitData[10] = PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: mandateAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // AssignExternalRole
        conditions.allowedRole = type(uint256).max;
        mandateInitData[11] = PowersTypes.MandateInitData({
            nameDescription: "AssignExternalRole: A mandate to assign a role if the account has a role on an external contract.",
            targetMandate: mandateAddresses[29], // AssignExternalRole (electoral mandate)
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
        string[] memory, /* mandateNames */
        address[] memory mandateAddresses,
        string[] memory, /* mockNames */
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        mandateInitData = new PowersTypes.MandateInitData[](7);

        // StatementOfIntent - for proposing actions
        conditions.allowedRole = type(uint256).max;
        mandateInitData[1] = PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: A mandate to propose actions without execution.",
            targetMandate: mandateAddresses[4], // StatementOfIntent (multi mandate)
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // GovernorCreateProposal - for creating governance proposals
        conditions.allowedRole = 1; // role 1 can create proposals
        mandateInitData[2] = PowersTypes.MandateInitData({
            nameDescription: "GovernorCreateProposal: A mandate to create governance proposals on a Governor contract.",
            targetMandate: mandateAddresses[9], // GovernorCreateProposal (executive mandate)
            config: abi.encode(mockAddresses[4]), // SimpleGovernor mock address
            conditions: conditions
        });
        delete conditions;

        // GovernorExecuteProposal - for executing governance proposals
        conditions.allowedRole = 1; // role 1 can execute proposals
        mandateInitData[3] = PowersTypes.MandateInitData({
            nameDescription: "GovernorExecuteProposal: A mandate to execute governance proposals on a Governor contract.",
            targetMandate: mandateAddresses[10], // GovernorExecuteProposal (executive mandate)
            config: abi.encode(mockAddresses[4]), // SimpleGovernor mock address
            conditions: conditions
        });
        delete conditions;

        // AdoptMandates - for adopting new mandates
        mandatesToAdopt = new address[](1);
        mandateInitDatas = new bytes[](1);

        // Create a simple mandate init data for adoption
        PowersTypes.MandateInitData({
            nameDescription: "Test Adopted Mandate",
            targetMandate: mandateAddresses[1], // PresetSingleAction
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
                timelock: 0,
                throttleExecution: 0,
                needFulfilled: 0,
                needNotFulfilled: 0
            })
        });

        conditions.allowedRole = type(uint256).max; // public role can adopt mandates
        mandateInitData[4] = PowersTypes.MandateInitData({
            nameDescription: "AdoptMandatePackage: A mandate to adopt new mandates into the DAO.",
            targetMandate: mandateAddresses[7], // AdoptMandates (executive mandate)
            config: abi.encode(),
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
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 5); // revoke mandate after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        mandateInitData[5] = PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: mandateAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // OpenAction - for executing any action
        conditions.allowedRole = type(uint256).max;
        mandateInitData[6] = PowersTypes.MandateInitData({
            nameDescription: "OpenAction: A mandate to execute any action with full power.",
            targetMandate: mandateAddresses[3], // OpenAction (multi mandate)
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                    MULTI CONSTITUTION                    //
    //////////////////////////////////////////////////////////////
    function multiTestConstitution(
        string[] memory, /* mandateNames */
        address[] memory mandateAddresses,
        string[] memory, /* mockNames */
        address[] memory mockAddresses,
        address payable daoMock
    ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        mandateInitData = new PowersTypes.MandateInitData[](9);

        // OpenAction - allows any action to be executed
        conditions.allowedRole = type(uint256).max;
        mandateInitData[1] = PowersTypes.MandateInitData({
            nameDescription: "OpenAction: A mandate to execute any action with full power.",
            targetMandate: mandateAddresses[3], // OpenAction (multi mandate)
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // StatementOfIntent - for proposing actions without execution
        conditions.allowedRole = type(uint256).max;
        mandateInitData[2] = PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: A mandate to propose actions without execution.",
            targetMandate: mandateAddresses[4], // StatementOfIntent (multi mandate)
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // BespokeActionSimple - for simple function calls
        params = new string[](1);
        params[0] = "uint256 Quantity";
        conditions.allowedRole = 1;
        mandateInitData[3] = PowersTypes.MandateInitData({
            nameDescription: "BespokeActionSimple: A mandate to execute a simple function call.",
            targetMandate: mandateAddresses[6], // BespokeActionSimple (multi mandate)
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
        mandateInitData[4] = PowersTypes.MandateInitData({
            nameDescription: "BespokeActionAdvanced: A mandate to execute complex function calls with mixed parameters.",
            targetMandate: mandateAddresses[5], // BespokeActionAdvanced (multi mandate)
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
        mandateInitData[5] = PowersTypes.MandateInitData({
            nameDescription: "PresetSingleAction: A mandate to execute preset actions.",
            targetMandate: mandateAddresses[1], // PresetSingleAction (multi mandate)
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // PresetMultipleActions - for executing multiple preset actions
        descriptions = new string[](2);
        descriptions[0] = "Assign Member Role";
        descriptions[1] = "Assign Delegate Role";

        conditions.allowedRole = 1;
        mandateInitData[6] = PowersTypes.MandateInitData({
            nameDescription: "PresetMultipleActions: A mandate to execute multiple preset actions.",
            targetMandate: mandateAddresses[2], // PresetMultipleActions (multi mandate)
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
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 7); // revoke mandate after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        mandateInitData[7] = PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: mandateAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;

        // CheckExternalActionState
        inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = type(uint256).max;
        mandateInitData[8] = PowersTypes.MandateInitData({
            nameDescription: "CheckExternalActionState: Checks if an action is fulfilled on a parent contract.",
            targetMandate: mandateAddresses[31], // CheckExternalActionState
            config: abi.encode(
                daoMock, // parentPowers (self for test)
                1, // mandateId on parent (OpenAction)
                inputParams
            ),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                 POWERS101 CONSTITUTION                   //
    //////////////////////////////////////////////////////////////
    // very similar to the PowersConstitution. Only difference is the use of SelfSelect.
    function powers101Constitution(
        string[] memory, /*mandateNames*/
        address[] memory mandateAddresses,
        string[] memory, /*mockNames*/
        address[] memory mockAddresses,
        address payable
    ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        mandateInitData = new PowersTypes.MandateInitData[](8);

        dynamicParamsSimple = new string[](1);
        dynamicParamsSimple[0] = "bool NominateMe";

        conditions.allowedRole = type(uint256).max;
        mandateInitData[1] = PowersTypes.MandateInitData({
            nameDescription: "Nominate Me: Nominate yourself for a delegate election. (Set nominateMe to false to revoke nomination)",
            targetMandate: mandateAddresses[6], // bespokeActionSimple
            config: abi.encode(
                mockAddresses[10], // = Erc20DelegateElection
                Nominees.nominate.selector,
                dynamicParamsSimple
            ),
            conditions: conditions
        });
        delete conditions;

        // delegateSelect
        conditions.allowedRole = type(uint256).max; // = role that can call this mandate.
        mandateInitData[2] = PowersTypes.MandateInitData({
            nameDescription: "Delegate Nominees: Call a delegate election. This can be done at any time. Nominations are elected on the amount of delegated tokens they have received. For",
            targetMandate: mandateAddresses[10], // OpenElectionEnd
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

        conditions.allowedRole = 1; // = role that can call this mandate.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        mandateInitData[3] = PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: Propose any kind of action.",
            targetMandate: mandateAddresses[4], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 0; // = admin.
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        mandateInitData[4] = PowersTypes.MandateInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetMandate: mandateAddresses[4], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 2; // = role that can call this mandate.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.succeedAt = 66; // = 51% simple majority needed for executing an action.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        conditions.needNotFulfilled = 4; // = mandate that must not be completed before this one.
        mandateInitData[5] = PowersTypes.MandateInitData({
            nameDescription: "Execute an action: Execute an action that has been proposed by the community and should not have been vetoed by an admin.",
            targetMandate: mandateAddresses[3], // openAction.
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
            targets[i] = address(this); // = Powers contract.
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 6); // revoke mandate after use.

        // set conditions
        conditions.allowedRole = type(uint256).max; // = public role. .
        mandateInitData[6] = PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: mandateAddresses[1], // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  POWER BASE CONSTITUTION                 //
    //////////////////////////////////////////////////////////////
    function powerLabsSafesConstitution(
        string[] memory, /*mandateNames*/
        address[] memory mandateAddresses,
        string[] memory, /*mockNames*/
        address[] memory, /*mockAddresses*/
        address payable
    ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        mandateInitData = new PowersTypes.MandateInitData[](3); // Index 0 is empty

        // Mandate 1: Create a SafeProxy and register as treasury for Powers
        conditions.allowedRole = type(uint256).max; // Public
        mandateInitData[1] = PowersTypes.MandateInitData({
            nameDescription: "Create SafeProxy: Creates the safe and registers it as the organization treasury.",
            targetMandate: mandateAddresses[22], // PowerLabsConfig mandate
            config: abi.encode(config.SafeProxyFactory, config.SafeL2Canonical),
            conditions: conditions
        });
        delete conditions;

        // Mandate 2: Setup Power Base Safe
        address[] memory configParams = new address[](4);
        configParams[0] = mandateAddresses[4]; // StatementOfIntent
        configParams[1] = mandateAddresses[8]; // SafeExecTransaction
        configParams[2] = mandateAddresses[1]; // PresetSingleAction
        configParams[3] = mandateAddresses[20]; // SafeAllowanceAction

        conditions.allowedRole = type(uint256).max; // Public
        mandateInitData[2] = PowersTypes.MandateInitData({
            nameDescription: "Setup Safe: Setup the allowance module and governance paths.",
            targetMandate: mandateAddresses[21], // PowerLabsConfig mandate
            config: abi.encode(configParams, config.SafeAllowanceModule),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //              POWER BASE CHILD CONSTITUTION               //
    //////////////////////////////////////////////////////////////
    // function powerLabsChildConstitution(
    //     string[] memory, /*mandateNames*/
    //     address[] memory mandateAddresses,
    //     string[] memory, /*mockNames*/
    //     address[] memory, /*mockAddresses*/
    //     address daoMock,
    // ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
    //     mandateInitData = new PowersTypes.MandateInitData[](5); // Index 0 is empty

    //     // Mandate 1: Execute transaction from allowance
    //     conditions.allowedRole = 3; // Doc Contributor
    //     conditions.votingPeriod = 50; // 10 mins approx (assuming 12s blocks)
    //     conditions.succeedAt = 67;
    //     conditions.quorum = 50;
    //     conditions.timelock = 15; // 3 mins approx.

    //     mandateInitData[1] = PowersTypes.MandateInitData({
    //         nameDescription: "Execute transaction from allowance: This is still a work in progress.",
    //         targetMandate: mandateAddresses[30], // "SafeAllowanceTransfer";
    //         config: abi.encode(
    //             config.SafeAllowanceModule, // allowanceModule
    //             // safeProxy
    //         ),
    //         conditions: conditions
    //     });
    //     delete conditions;

    //     // Mandate 2: Adopt Doc Contrib Role
    //     conditions.allowedRole = type(uint256).max; // PUBLIC_ROLE

    //     mandateInitData[2] = PowersTypes.MandateInitData({
    //         nameDescription: "Adopt Doc Contrib Role: Anyone that has a documentation contributor role at the parent organization can adopt the same role here.",
    //         targetMandate: mandateAddresses[29], // AssignExternalRole
    //         config: abi.encode(daoMock, 3), // powersAddress, roleId
    //         conditions: conditions
    //     });
    //     delete conditions;

    //     // Mandate 3: Adopt Mandates
    //     string[] memory paramsLocal = new string[](3);
    //     paramsLocal[0] = "uint256 PoolId";
    //     paramsLocal[1] = "address payableTo";
    //     paramsLocal[2] = "uint256 Amount";

    //     conditions.allowedRole = type(uint256).max; // PUBLIC_ROLE

    //     // Note: CheckExternalActionState is not in InitialisePowers, using mandateAddresses[0] as placeholder
    //     mandateInitData[3] = PowersTypes.MandateInitData({
    //         nameDescription: "Adopt Mandates: Anyone can adopt new mandates ok-ed by the parent organization",
    //         targetMandate: mandateAddresses[0], // CheckExternalActionState
    //         config: abi.encode(uint16(123), daoMock, paramsLocal), // mandateId (dummy), powersAddress, inputParams
    //         conditions: conditions
    //     });
    //     delete conditions;

    //     // Mandate 4: Revoke Mandates
    //     conditions.allowedRole = 3;
    //     conditions.votingPeriod = 50;
    //     conditions.succeedAt = 67;
    //     conditions.quorum = 50;
    //     conditions.timelock = 15;

    //     mandateInitData[4] = PowersTypes.MandateInitData({
    //         nameDescription: "Revoke Mandates: Admin can revoke mandates from the organization",
    //         targetMandate: mandateAddresses[25], // RevokeMandates
    //         config: abi.encode(""), // 0x00
    //         conditions: conditions
    //     });
    //     delete conditions;
    // }

    //////////////////////////////////////////////////////////////
    //                 HELPERS CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function helpersTestConstitution(
        string[] memory, /*mandateNames*/
        address[] memory mandateAddresses,
        string[] memory, /*mockNames*/
        address[] memory, /*mockAddresses*/
        address payable
    ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        mandateInitData = new PowersTypes.MandateInitData[](2);

        // dummy call.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        // Note: I leave the first slot empty, so that numbering is equal to how mandates are registered in IPowers.sol.
        // Counting starts at 1, so the first mandate is mandateId = 1.

        // openAction
        conditions.allowedRole = type(uint256).max;
        mandateInitData[1] = PowersTypes.MandateInitData({
            nameDescription: "Open Action: Execute any action.",
            targetMandate: mandateAddresses[3], // openAction
            config: abi.encode(),
            conditions: conditions
        });
        delete conditions;
    }
}
