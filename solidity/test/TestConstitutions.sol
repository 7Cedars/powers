// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";
import { IPowers } from "@src/interfaces/IPowers.sol";
import { PowersTypes } from "@src/interfaces/PowersTypes.sol";
import { Configurations } from "@script/Configurations.s.sol";

import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";
import { IPowersFactory } from "@src/helpers/PowersFactory.sol";
import { ISoulbound1155} from "@src/helpers/Soulbound1155.sol";


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
    PowersTypes.MandateInitData[] constitution;
    PowersTypes.MandateInitData[] parentConstitution;
    PowersTypes.MandateInitData[] childConstitution;

    string[] mandateNames; 
    address[] mandateAddresses;

    string[] descriptions;
    string[] params;

    Configurations helperConfig = new Configurations();
    Configurations.NetworkConfig config = helperConfig.getConfig();

    constructor(string[] memory _mandateNames, address[] memory _mandateAddresses) {
        mandateNames = _mandateNames;
        mandateAddresses = _mandateAddresses; 
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                    CORE PROTOCOL TESTS                                          //
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////
    //                 POWERS CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    /// @notice initiate the powers constitution. Follows the Powers101 governance structure.
    function powersTestConstitution(address daoMock) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.
        
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
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Self select as community member: Self select as a community member. Anyone can call this mandate.",
            targetMandate: getMandateAddress("SelfSelect"), // selfSelct
            config: abi.encode(
                1 // community member role ID
            ),
            conditions: conditions
        }));
        delete conditions;

        // self Select as delegate
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Self select as delegate: Self select as a delegate. Only community members can call this mandate.",
            targetMandate: getMandateAddress("SelfSelect"), // selfSelct
            config: abi.encode(
                2 // delegeate member role ID
            ),
            conditions: conditions
        }));
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
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: Propose any kind of action.",
            targetMandate: getMandateAddress("StatementOfIntent"), // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        conditions.allowedRole = 0; // = admin.
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetMandate: getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        conditions.allowedRole = 2; // = role that can call this mandate.
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        conditions.needNotFulfilled = 4; // = mandate that must not be completed before this one.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Execute an action: Execute an action that has been proposed by the community and should not have been vetoed by an admin.",
            targetMandate: getMandateAddress("OpenAction"), // openAction.
            config: abi.encode(), // empty config.
            conditions: conditions
        }));
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
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    //////////////////////////////////////////////////////////////
    //                  LAW CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function mandateTestConstitution( address daoMock, address simpleErc1155 ) public returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution;

        // dummy call: mint coins at mock1155 contract.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = simpleErc1155;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(SimpleErc1155.mintCoins.selector, 123);

        // setting up config file
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.allowedRole = 1;
        // initiating mandate.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: Needs Proposal Vote to pass",
            targetMandate: getMandateAddress("StatementOfIntent"), // statementOfIntent
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        // setting up config file
        conditions.needFulfilled = 1;
        conditions.allowedRole = 1;
        // initiating mandate.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "PresetSingleActions: Needs Parent Completed to pass",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        // setting up config file
        conditions.needNotFulfilled = 1;
        conditions.allowedRole = 1;
        // initiating mandate.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "PresetSingleActions: Parent can block a mandate, making it impossible to pass",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        // setting up config file
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.timelock = 5000;
        conditions.allowedRole = 1;
        // initiating mandate.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "PresetSingleActions: Delay execution of a mandate, by a preset number of blocks",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        // setting up config file
        conditions.allowedRole = 1;
        conditions.throttleExecution = 5000;
        // initiating mandate.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "PresetSingleActions: Throttle the number of executions of a mandate.",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
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
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          UNIT TESTS                                             //
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////
    //                    ASYNC CONSTITUTION                    //
    //////////////////////////////////////////////////////////////
    function asyncTestConstitution( ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // todo
        // need to include the get role by git commit.
        // need to use dummy return calls. 

        return constitution;
    }

    ////////////////////////////////////////////////////////////
    //                ELECTORAL CONSTITUTION                  //
    ////////////////////////////////////////////////////////////
    function electoralTestConstitution( 
        address daoMock, 
        address nominees, 
        address openElection, 
        address erc20DelegateElection, 
        address erc20Taxed, 
        address flagActions 
        ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // PeerSelect - for peer voting
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "PeerSelect: A mandate to select roles by peer votes from nominees.",
            targetMandate: getMandateAddress("PeerSelect"), // PeerSelect (electoral mandate)
            config: abi.encode(
                2, // max role holders
                4, // roleId to be assigned
                1, // max votes per voter
                nominees // Nominees contract
            ),
            conditions: conditions
        }));
        delete conditions;

        // OpenElectionVote - for voting in open elections
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "OpenElectionVote: A mandate to vote in open elections.",
            targetMandate: getMandateAddress("OpenElectionVote"), // OpenElectionVote (electoral mandate)
            config: abi.encode(openElection, 1), // OpenElection contract, max votes per voter
            conditions: conditions
        }));
        delete conditions;

        // OpenElectionEnd - for delegate elections
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "OpenElectionEnd: A mandate to run delegate elections and assign roles based on results.",
            targetMandate: getMandateAddress("OpenElectionEnd"), // OpenElectionEnd (electoral mandate)
            config: abi.encode(
                erc20DelegateElection, // Erc20DelegateElection contract
                3, // roleId to be elected
                3 // max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        // TaxSelect - for tax-based role assignment
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "TaxSelect: A mandate to assign roles based on tax payments.",
            targetMandate: getMandateAddress("TaxSelect"), // TaxSelect (electoral mandate)
            config: abi.encode(
                erc20Taxed, // Erc20Taxed mock
                1000, // threshold tax paid
                4 // roleId to be assigned
            ),
            conditions: conditions
        }));
        delete conditions;

        // SelfSelect - for self-assignment
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "SelfSelect: A mandate to self-assign a role.",
            targetMandate: getMandateAddress("SelfSelect"), // SelfSelect (electoral mandate)
            config: abi.encode(4), // roleId to be assigned
            conditions: conditions
        }));
        delete conditions;

        // RenounceRole - for renouncing roles
        roles = new uint256[](2);
        roles[0] = 1;
        roles[1] = 2;
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "RenounceRole: A mandate to renounce specific roles.",
            targetMandate: getMandateAddress("RenounceRole"), // RenounceRole (electoral mandate)
            config: abi.encode(roles), // roles that can be renounced
            conditions: conditions
        }));
        delete conditions;

        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "NStrikesRevokesRoles: A mandate to revoke roles after N strikes.",
            targetMandate: getMandateAddress("NStrikesRevokesRoles"), // NStrikesRevokesRoles (electoral mandate)
            config: abi.encode(
                3, // roleId to be revoked.
                2, // number of strikes needed to be revoked.
                flagActions // FlagActions contract
            ),
            conditions: conditions
        }));
        delete conditions;

        // RoleByRoles - for role-based role assignment
        roleIdsNeeded = new uint256[](2);
        roleIdsNeeded[0] = 1;
        roleIdsNeeded[1] = 2;
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "RoleByRoles: A mandate to assign roles based on existing role holders.",
            targetMandate: getMandateAddress("RoleByRoles"), // RoleByRoles (electoral mandate)
            config: abi.encode(
                4, // target role (what gets assigned)
                roleIdsNeeded // roles that are needed to be assigned
            ),
            conditions: conditions
        }));
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
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    //////////////////////////////////////////////////////////////
    //                  EXECUTIVE CONSTITUTION                  //
    //////////////////////////////////////////////////////////////
    function executiveTestConstitution( address daoMock, address simpleErc1155 ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // StatementOfIntent - for proposing actions
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: A mandate to propose actions without execution.",
            targetMandate: getMandateAddress("StatementOfIntent"), // StatementOfIntent (multi mandate)
            config: abi.encode(), // empty config
            conditions: conditions
        }));
        delete conditions;

        // OpenAction - allows any action to be executed
        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "OpenAction: A mandate to execute any action with full power.",
            targetMandate: getMandateAddress("OpenAction"), // OpenAction (multi mandate)
            config: abi.encode(), // empty config
            conditions: conditions
        }));
        delete conditions;

        // BespokeActionSimple - for simple function calls
        params = new string[](1);
        params[0] = "uint256 Quantity";
        conditions.allowedRole = 1;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "BespokeActionSimple: A mandate to execute a simple function call.",
            targetMandate: getMandateAddress("BespokeActionSimple"), // BespokeActionSimple (multi mandate)
            config: abi.encode(
                simpleErc1155, // SimpleErc1155 mock
                SimpleErc1155.mintCoins.selector,
                params
            ),
            conditions: conditions
        }));
        delete conditions;

        // BespokeActionAdvanced - for complex function calls with mixed parameters
        staticParams = new bytes[](1);
        staticParams[0] = abi.encode(1); // roleId = 1
        dynamicParams = new string[](1);
        dynamicParams[0] = "address Account";
        indexDynamicParams = new uint8[](1);
        indexDynamicParams[0] = 1; // insert at position 1

        conditions.allowedRole = 1;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "BespokeActionAdvanced: A mandate to execute complex function calls with mixed parameters.",
            targetMandate: getMandateAddress("BespokeActionAdvanced"), // BespokeActionAdvanced (multi mandate)
            config: abi.encode(
                daoMock, // Powers contract
                IPowers.assignRole.selector,
                staticParams,
                dynamicParams,
                indexDynamicParams
            ),
            conditions: conditions
        }));
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
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "PresetSingleAction: A mandate to execute preset actions.",
            targetMandate: getMandateAddress("PresetSingleAction"), // PresetSingleAction (multi mandate)
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        // PresetMultipleActions - for executing multiple preset actions
        descriptions = new string[](2);
        descriptions[0] = "Assign Member Role";
        descriptions[1] = "Assign Delegate Role";

        conditions.allowedRole = 1;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "PresetMultipleActions: A mandate to execute multiple preset actions.",
            targetMandate: getMandateAddress("PresetMultipleActions"), // PresetMultipleActions (multi mandate)
            config: abi.encode(descriptions, targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;
 
        // CheckExternalActionState
        inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = type(uint256).max;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "CheckExternalActionState: Checks if an action is fulfilled on a parent contract.",
            targetMandate: getMandateAddress("CheckExternalActionState"), // CheckExternalActionState
            config: abi.encode(
                daoMock, // parentPowers (self for test)
                1, // mandateId on parent (OpenAction)
                inputParams
            ),
            conditions: conditions
        }));
        delete conditions;

        // AdoptMandates - for adopting new mandates
        mandatesToAdopt = new address[](1);
        mandateInitDatas = new bytes[](1);

        // Create a simple mandate init data for adoption
        PowersTypes.MandateInitData({
            nameDescription: "Test Adopted Mandate",
            targetMandate: getMandateAddress("PresetSingleAction"), // PresetSingleAction
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
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "AdoptMandates: A mandate to adopt new mandates into the DAO.",
            targetMandate: getMandateAddress("AdoptMandates"), // AdoptMandates (executive mandate)
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    //////////////////////////////////////////////////////////////
    //               INTEGRATIONS CONSTITUTION                  //
    //////////////////////////////////////////////////////////////
    function integrationsTestConstitution( address simpleGovernor, address powersFactory, address soulbound1155 ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array 

        // Governor Integration // 
        // GovernorCreateProposal - for creating governance proposals
        conditions.allowedRole = 1; // role 1 can create proposals
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "GovernorCreateProposal: A mandate to create governance proposals on a Governor contract.",
            targetMandate: getMandateAddress("GovernorCreateProposal"), // GovernorCreateProposal (executive mandate)
            config: abi.encode(simpleGovernor), // SimpleGovernor mock address
            conditions: conditions
        }));
        delete conditions;

        // GovernorExecuteProposal - for executing governance proposals
        conditions.allowedRole = 1; // role 1 can execute proposals
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "GovernorExecuteProposal: A mandate to execute governance proposals on a Governor contract.",
            targetMandate: getMandateAddress("GovernorExecuteProposal"), // GovernorExecuteProposal (executive mandate)
            config: abi.encode(simpleGovernor), // SimpleGovernor mock address
            conditions: conditions
        }));
        delete conditions;

        // Safe Allowance Integration //
        // SafeSetup
        conditions.allowedRole = type(uint256).max; // Public
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Setup Safe: Create a SafeProxy and register it as treasury.",
            targetMandate: getMandateAddress("SafeSetup"),
            config: abi.encode(
                config.safeProxyFactory,
                config.safeL2Canonical,
                config.safeAllowanceModule
            ),
            conditions: conditions
        }));
        delete conditions;
 
        // execute action from safe. 
        inputParams = new string[](3);
        inputParams[0] = "calldata SafeFunctionTarget";
        inputParams[1] = "bytes4 SafeFunctionSelector";
        inputParams[2] = "calldata SafeFunctionCalldata";

        conditions.allowedRole = 1;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Execute an action from the Safe treasury.",
            targetMandate: getMandateAddress("SafeExecTransaction"),
            config: abi.encode(
                inputParams,
                config.safeL2Canonical
            ),
            conditions: conditions 
        }));
        delete conditions;

        // Powers Factory Integration //
        // create new org 
        inputParams = new string[](3);
        inputParams[0] = "string OrgName";
        inputParams[1] = "string OrgUri";
        inputParams[2] = "uint256 Allowance";

        uint256 roleIdnewOrg = 9; // roleId for the new organisation.  

        conditions.allowedRole = 1; //
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create new Powers: call Powers Factory to spawn new powers.",
            targetMandate: getMandateAddress("BespokeActionSimple"),
            config: abi.encode(
                powersFactory,
                IPowersFactory.createPowers.selector,
                inputParams
            ),
            conditions: conditions 
        }));
        delete conditions;

 
        conditions.allowedRole = 1; //
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Execute and set allowance for a Powers Child at the Safe Treasury.",
            targetMandate: getMandateAddress("PowersFactoryAssignRole"),
            config: abi.encode(
                6, // mandateId of the createPowers action above.
                roleIdnewOrg,
                inputParams // the input params from above are passed to extract the new org address.
            ),
            conditions: conditions 
        }));
        delete conditions;

        // Soulbound1155 integration //
        // minting mandate // 
        inputParams = new string[](1);
        inputParams[0] = "address to";
        conditions.allowedRole = 1; //
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint soulbound token: mint a soulbound ERC1155 token and send it to an address of choice.",
            targetMandate: getMandateAddress("BespokeActionSimple"),
            config: abi.encode(
                soulbound1155,
                ISoulbound1155.mint.selector,
                inputParams
            ),
            conditions: conditions 
        }));
        delete conditions;

        // access mandate // 
        conditions.allowedRole = 1; //
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Soulbound1155 Access: Get roleId through soulbound ERC1155 token.",
            targetMandate: getMandateAddress("Soulbound1155GatedAccess"),
            config: abi.encode(
                soulbound1155,
                9, // roleId to be assigned upon holding the soulbound token.
                100, // epoch of blocks within which the tokens must have been held.
                3 // number of tokens that need to be held.
            ),
            conditions: conditions 
        }));
        delete conditions;

        return constitution;
    }

    function integrationsTestConstitution2( address daoMock, address allowedTokens ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array
        
        // Safe Allowance Integration //
        // Mandate: Execute Allowance Transaction
        conditions.allowedRole = 0; 
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Execute Allowance Transaction: Execute a transaction from the Safe Treasury within the allowance set.",
            targetMandate: getMandateAddress("SafeAllowanceTransfer"),
            config: abi.encode(
                config.safeAllowanceModule,
                IPowers(daoMock).getTreasury() // This is the SafeProxyTreasury! 
            ),
            conditions: conditions
        }));
        delete conditions;

        // Allowed Tokens Integration //
        conditions.allowedRole = 0; 
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer allowed tokens from child to parent Powers Organisation.",
            targetMandate: getMandateAddress("AllowedTokensPresetTransfer"),
            config: abi.encode(
                daoMock,
                allowedTokens  
            ),
            conditions: conditions
        }));
        delete conditions;    

        return constitution;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                      INTEGRATION TESTS                                          //
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Note: test constitutions created per governance flow to be tested.
    // NB2: leaving async tests out for now. Due to use of oracles, they are better tested directly on actual test nets. 

    //////////////////////////////////////////////////////////////
    //               INTEGRATION TEST: ELECTORAL                //
    //////////////////////////////////////////////////////////////
    // Delegate Token election flow
    function delegateToken_IntegrationTestConstitution( address nominees, address openElection, address simpleErc20Votes ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // Mandate 1: Nominate for Delegates
        conditions.allowedRole = 1; // = Voters
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for Delegates: Members can nominate themselves for the Token Delegate role.",
            targetMandate: getMandateAddress("Nominate"),
            config: abi.encode(
                nominees
            ),
            conditions: conditions
        }));
        delete conditions;

        // Mandate 2: Elect Delegates
        conditions.allowedRole = type(uint256).max; // = Public Role
        conditions.throttleExecution = 600;
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Elect Delegates: Run the election for delegates. In this demo, the top 3 nominees by token delegation of token VOTES_TOKEN become Delegates.",
            targetMandate: getMandateAddress("DelegateTokenSelect"),
            config: abi.encode(
                simpleErc20Votes,
                nominees,
                2, // RoleId
                3 // MaxRoleHolders
            ),
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    // Open Election flow
    function openElection_IntegrationTestConstitution( address openElection ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // Mandate 1: Nominate for Delegates
        conditions.allowedRole = 1; // = Voters
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for Delegates: Members can nominate themselves for the Token Delegate role.",
            targetMandate: getMandateAddress("Nominate"),
            config: abi.encode(
                openElection
            ),
            conditions: conditions
        }));
        delete conditions;

        // Mandate 2: Start an election
        conditions.allowedRole = 1; // = Voters
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Start an election: an election can be initiated be voters once every 2 hours. The election will last 10 minutes.",
            targetMandate: getMandateAddress("OpenElectionStart"),
            config: abi.encode(
                openElection,
                600, // 10 minutes in blocks (approx)
                1 // Voter role id
            ),
            conditions: conditions
        }));
        delete conditions;

        // Mandate 3: End and Tally elections
        conditions.allowedRole = 1; // = Voters
        conditions.needFulfilled = 2; // = Mandate 2 (Start election)
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "End and Tally elections: After an election has finished, assign the Delegate role to the winners.",
            targetMandate: getMandateAddress("OpenElectionEnd"),
            config: abi.encode(
                openElection,
                2, // RoleId for Delegates
                5 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    // Role By Transaction flow
    function roleByTransaction_IntegrationTestConstitution( address /*daoMock*/ ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // RoleByTransaction
        // conditions.allowedRole = type(uint256).max; // == PUBLIC_ROLE: anyone can call this mandate.
        // mandateInitData = PowersTypes.MandateInitData({
        //     nameDescription: "Buy Funder Role: Make a contribution of more than 0.1 ether (written in its smallest denomination) in TAX token (0x93d94e8D5DC29C6610946C3226e5Be4e4FB503Ce) to be granted a funder role.",
        //     targetMandate: mandateAddresses[4], // RoleByTransaction
        //     config: abi.encode(
        //         0x93d94e8D5DC29C6610946C3226e5Be4e4FB503Ce, // token = TAX token
        //         1 ether / 10, // amount = 0.1 Ether minimum
        //         1, // newRoleId = Funder role
        //         mem.safeProxy // safeProxy == treasury
        //     ),
        //     conditions: conditions
        // });

        return constitution;
    }

    // Assign external role flow (= 2 constitutions, parent & child) 
    function assignExternalRole_parent_IntegrationTestConstitution( address daoMock ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // Mandate: Admin assigns role
        dynamicParams = new string[](2);
        dynamicParams[0] = "uint256 roleId";
        dynamicParams[1] = "address account";

        conditions.allowedRole = 0; // = Admin
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Admin can assign any role: For this demo, the admin can assign any role to an account.",
            targetMandate: getMandateAddress("BespokeActionSimple"),
            config: abi.encode(
                daoMock,
                IPowers.assignRole.selector,
                dynamicParams
            ),
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }
 
    function assignExternalRole_child_IntegrationTestConstitution( address /*daoMock*/, address parent ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete childConstitution; // restart childConstitution array.

        conditions.allowedRole = type(uint256).max; // Public
        childConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt Role 1: Anyone that has role 1 at the parent organization can adopt the same role here.",
            targetMandate: getMandateAddress("AssignExternalRole"),
            config: abi.encode(
                parent,
                1 // RoleId (Funders) placeholder
            ),
            conditions: conditions
        }));
        delete conditions;

        return childConstitution;
    }

    //////////////////////////////////////////////////////////////
    //             INTEGRATION TEST: EXECUTIVE                  //
    //////////////////////////////////////////////////////////////
    // Open Action flow: The most classic governance flows of all. This is the base to test if needFulfilled and needNotFulfilled actually work. 
    function openAction_IntegrationTestConstitution() external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // proposalOnly
        inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = 1; // = role that can call this mandate.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 300; // = number of blocks
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: Propose any kind of action.",
            targetMandate: getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        conditions.allowedRole = 0; // = admin.
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetMandate: getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        conditions.allowedRole = 2; // = role that can call this mandate.
        conditions.votingPeriod = 300; // = number of blocks
        conditions.succeedAt = 66; // = 51% simple majority needed for executing an action.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        conditions.needNotFulfilled = 4; // = mandate that must not be completed before this one.
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Execute an action: Execute an action that has been proposed by the community and should not have been vetoed by an admin.",
            targetMandate: getMandateAddress("OpenAction"), // openAction.
            config: abi.encode(), // empty config.
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    // Check External Action State flow (= 2 constitutions, parent & child)
    function checkExternalActionState_Parent_IntegrationTestConstitution( address /*daoMock*/ ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete parentConstitution; // restart parentConstitution array.

        // Mandate: Adopt a Child Mandate
        conditions.allowedRole = 0; // Admin
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt a Child Mandate: Admin adopts the new mandate for a Powers' child",
            targetMandate: getMandateAddress("StatementOfIntent"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return parentConstitution;
    }

    function checkExternalActionState_Child_IntegrationTestConstitution( address /*daoMock*/, address parent ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete childConstitution; // restart childConstitution array.

        // Mandate: Adopt a Child Mandate
        // conditions.allowedRole = 0; // Admin
        // childConstitution.push(PowersTypes.MandateInitData({
        //     nameDescription: "Adopt a Child Mandate: Admin adopts the new mandate for a Powers' child",
        //     targetMandate: getMandateAddress("StatementOfIntent"),
        //     config: abi.encode(),
        //     conditions: conditions
        // }));
        // delete conditions;

        return childConstitution;
    }

    //////////////////////////////////////////////////////////////
    //               INTEGRATION TEST: INTEGRATIONS              //
    //////////////////////////////////////////////////////////////
    // Governor protocol flow 
    function governorProtocol_IntegrationTestConstitution( address simpleGovernor ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

        // GovernorCreateProposal - for creating governance proposals
        conditions.allowedRole = 1; // role 1 can create proposals
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "GovernorCreateProposal: A mandate to create governance proposals on a Governor contract.",
            targetMandate: getMandateAddress("GovernorCreateProposal"), // GovernorCreateProposal (executive mandate)
            config: abi.encode(simpleGovernor), // SimpleGovernor mock address
            conditions: conditions
        }));
        delete conditions;

        // GovernorExecuteProposal - for executing governance proposals
        conditions.allowedRole = 1; // role 1 can execute proposals
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "GovernorExecuteProposal: A mandate to execute governance proposals on a Governor contract.",
            targetMandate: getMandateAddress("GovernorExecuteProposal"), // GovernorExecuteProposal (executive mandate)
            config: abi.encode(simpleGovernor), // SimpleGovernor mock address
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    // Safe protocol flow 
    function safeProtocol_Parent_IntegrationTestConstitution( address /*daoMock*/ ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete parentConstitution; // restart parentConstitution array.

        // SafeSetup
        conditions.allowedRole = type(uint256).max; // Public
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Setup Safe: Create a SafeProxy and register it as treasury.",
            targetMandate: getMandateAddress("SafeSetup"),
            config: abi.encode(
                config.safeProxyFactory,
                config.safeL2Canonical
            ),
            conditions: conditions
        }));
        delete conditions;

        // Allow for child to be set as delegate and receive allowance 
        inputParams = new string[](1);
        inputParams[0] = "address NewChildPowers";

        return parentConstitution;
    }

    function safeProtocol_Child_IntegrationTestConstitution( address /*daoMock*/, address parent ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete childConstitution; // restart childConstitution array.

        // Mandate: Execute Allowance Transaction
        conditions.allowedRole = 1; // Assuming RoleId 1 (Funders) as placeholder for formData["RoleId"] 
        conditions.votingPeriod = 300; 
        conditions.succeedAt = 67;
        conditions.quorum = 50;
        conditions.timelock = 150; 
        childConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Execute Allowance Transaction: Execute a transaction from the Safe Treasury within the allowance set.",
            targetMandate: getMandateAddress("SafeAllowanceTransfer"),
            config: abi.encode(
                config.safeAllowanceModule,
                IPowers(parent).getTreasury() // This is the SafeProxyTreasury! 
            ),
            conditions: conditions
        }));
        delete conditions;

        return childConstitution;
    }
 
    //////////////////////////////////////////////////////////////
    //                 HELPERS CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function helpersTestConstitution( ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete constitution; // restart constitution array.

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
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Open Action: Execute any action.",
            targetMandate: getMandateAddress("OpenAction"), // openAction
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return constitution;
    }

    //////////////////////////////////////////////////////////////
    //                         HELPERS                          //
    //////////////////////////////////////////////////////////////
    function getMandateAddress(string memory name) public view returns (address mandateAddress) {
        for (uint256 i = 0; i < mandateNames.length; i++) {
            if (keccak256(abi.encodePacked(mandateNames[i])) == keccak256(abi.encodePacked(name))) {
                return mandateAddresses[i];
            }
        }
        revert("Mandate not found");
    } 
}
