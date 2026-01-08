// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";
import { IPowers } from "@src/interfaces/IPowers.sol";
import { PowersTypes } from "@src/interfaces/PowersTypes.sol";
import { Nominees } from "@src/helpers/Nominees.sol";

import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";

import { Configurations } from "@script/Configurations.s.sol"; 

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
    PowersTypes.MandateInitData[] orgInitData;

    string[] mandateNames; 
    address[] mandateAddresses;
    string[] helperNames;
    address[] helperAddresses;

    string[] descriptions;
    string[] params;

    Configurations helperConfig = new Configurations();
    Configurations.NetworkConfig config = helperConfig.getConfig();

    constructor(string[] memory _mandateNames, address[] memory _mandateAddresses, string[] memory _helperNames, address[] memory _helperAddresses) {
        mandateNames = _mandateNames;
        mandateAddresses = _mandateAddresses;
        helperNames = _helperNames;
        helperAddresses = _helperAddresses;
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
    function powersTestConstitution(address payable daoMock) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete orgInitData; // restart orgInitData array.
        
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: Propose any kind of action.",
            targetMandate: getMandateAddress("StatementOfIntent"), // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        conditions.allowedRole = 0; // = admin.
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetMandate: getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        conditions.allowedRole = 2; // = role that can call this mandate.
        conditions.needFulfilled = 3; // = mandate that must be completed before this one.
        conditions.needNotFulfilled = 4; // = mandate that must not be completed before this one.
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        return orgInitData;
    }

    //////////////////////////////////////////////////////////////
    //                  LAW CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function mandateTestConstitution( address payable daoMock ) public returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete orgInitData;

        // dummy call: mint coins at mock1155 contract.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = getHelperAddress("SimpleErc1155");
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(SimpleErc1155.mintCoins.selector, 123);

        // setting up config file
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.allowedRole = 1;
        // initiating mandate.
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        return orgInitData;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          UNIT TESTS                                             //
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////
    //                    ASYNC CONSTITUTION                    //
    //////////////////////////////////////////////////////////////
    function asyncTestConstitution( address payable /*daoMock*/ ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete orgInitData; // restart orgInitData array.

        // todo
        // need to include the get role by git commit.
        // need to use dummy return calls. 

        return orgInitData;
    }

    ////////////////////////////////////////////////////////////
    //                ELECTORAL CONSTITUTION                  //
    ////////////////////////////////////////////////////////////
    function electoralTestConstitution( address payable daoMock ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete orgInitData; // restart orgInitData array.

        // PeerSelect - for peer voting
        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "PeerSelect: A mandate to select roles by peer votes from nominees.",
            targetMandate: getMandateAddress("PeerSelect"), // PeerSelect (electoral mandate)
            config: abi.encode(
                2, // max role holders
                4, // roleId to be assigned
                1, // max votes per voter
                getHelperAddress("Nominees") // Nominees contract
            ),
            conditions: conditions
        }));
        delete conditions;

        // OpenElectionVote - for voting in open elections
        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "OpenElectionVote: A mandate to vote in open elections.",
            targetMandate: getMandateAddress("OpenElectionVote"), // OpenElectionVote (electoral mandate)
            config: abi.encode(getHelperAddress("OpenElection"), 1), // OpenElection contract, max votes per voter
            conditions: conditions
        }));
        delete conditions;

        // OpenElectionEnd - for delegate elections
        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "OpenElectionEnd: A mandate to run delegate elections and assign roles based on results.",
            targetMandate: getMandateAddress("OpenElectionEnd"), // OpenElectionEnd (electoral mandate)
            config: abi.encode(
                getHelperAddress("Erc20DelegateElection"), // Erc20DelegateElection contract
                3, // roleId to be elected
                3 // max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        // TaxSelect - for tax-based role assignment
        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "TaxSelect: A mandate to assign roles based on tax payments.",
            targetMandate: getMandateAddress("TaxSelect"), // TaxSelect (electoral mandate)
            config: abi.encode(
                getHelperAddress("Erc20Taxed"), // Erc20Taxed mock
                1000, // threshold tax paid
                4 // roleId to be assigned
            ),
            conditions: conditions
        }));
        delete conditions;

        // SelfSelect - for self-assignment
        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "RenounceRole: A mandate to renounce specific roles.",
            targetMandate: getMandateAddress("RenounceRole"), // RenounceRole (electoral mandate)
            config: abi.encode(roles), // roles that can be renounced
            conditions: conditions
        }));
        delete conditions;

        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "NStrikesRevokesRoles: A mandate to revoke roles after N strikes.",
            targetMandate: getMandateAddress("NStrikesRevokesRoles"), // NStrikesRevokesRoles (electoral mandate)
            config: abi.encode(
                3, // roleId to be revoked.
                2, // number of strikes needed to be revoked.
                getHelperAddress("FlagActions") // FlagActions contract
            ),
            conditions: conditions
        }));
        delete conditions;

        // RoleByRoles - for role-based role assignment
        roleIdsNeeded = new uint256[](2);
        roleIdsNeeded[0] = 1;
        roleIdsNeeded[1] = 2;
        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "A Single Action: to assign labels to roles. It self-destructs after execution.",
            targetMandate: getMandateAddress("PresetSingleAction"), // presetSingleAction
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        return orgInitData;
    }

    //////////////////////////////////////////////////////////////
    //                  EXECUTIVE CONSTITUTION                  //
    //////////////////////////////////////////////////////////////
    function executiveTestConstitution( address payable daoMock ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete orgInitData; // restart orgInitData array.

        // StatementOfIntent - for proposing actions
        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "StatementOfIntent: A mandate to propose actions without execution.",
            targetMandate: getMandateAddress("StatementOfIntent"), // StatementOfIntent (multi mandate)
            config: abi.encode(), // empty config
            conditions: conditions
        }));
        delete conditions;

        // OpenAction - allows any action to be executed
        conditions.allowedRole = type(uint256).max;
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "BespokeActionSimple: A mandate to execute a simple function call.",
            targetMandate: getMandateAddress("BespokeActionSimple"), // BespokeActionSimple (multi mandate)
            config: abi.encode(
                getHelperAddress("SimpleErc1155"), // SimpleErc1155 mock
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
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
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "AdoptMandates: A mandate to adopt new mandates into the DAO.",
            targetMandate: getMandateAddress("AdoptMandates"), // AdoptMandates (executive mandate)
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return orgInitData;
    }

    //////////////////////////////////////////////////////////////
    //                INTEGRATIONS CONSTITUTION                 //
    //////////////////////////////////////////////////////////////
    function integrationsTestConstitution( address payable /*daoMock*/ ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete orgInitData; // restart orgInitData array.
    
    // GovernorCreateProposal - for creating governance proposals
        conditions.allowedRole = 1; // role 1 can create proposals
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "GovernorCreateProposal: A mandate to create governance proposals on a Governor contract.",
            targetMandate: getMandateAddress("GovernorCreateProposal"), // GovernorCreateProposal (executive mandate)
            config: abi.encode(getHelperAddress("SimpleGovernor")), // SimpleGovernor mock address
            conditions: conditions
        }));
        delete conditions;

        // GovernorExecuteProposal - for executing governance proposals
        conditions.allowedRole = 1; // role 1 can execute proposals
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "GovernorExecuteProposal: A mandate to execute governance proposals on a Governor contract.",
            targetMandate: getMandateAddress("GovernorExecuteProposal"), // GovernorExecuteProposal (executive mandate)
            config: abi.encode(getHelperAddress("SimpleGovernor")), // SimpleGovernor mock address
            conditions: conditions
        }));
        delete conditions;

        return orgInitData;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                      INTEGRATION TESTS                                          //
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////
    //                          ASYNC                           //
    //////////////////////////////////////////////////////////////
    // to do 


    //////////////////////////////////////////////////////////////
    //                          ELECTORAL                       //
    //////////////////////////////////////////////////////////////
    // to do 


    //////////////////////////////////////////////////////////////
    //                         EXECUTIVE                        //
    //////////////////////////////////////////////////////////////
    // to do 


    //////////////////////////////////////////////////////////////
    //                       INTEGRATIONS                       //
    //////////////////////////////////////////////////////////////
    // to do 


    //////////////////////////////////////////////////////////////
    //                 HELPERS CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function helpersTestConstitution( address payable /*daoMock*/ ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
        delete orgInitData; // restart orgInitData array.

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
        orgInitData.push(PowersTypes.MandateInitData({
            nameDescription: "Open Action: Execute any action.",
            targetMandate: getMandateAddress("OpenAction"), // openAction
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return orgInitData;
    }

    function getMandateAddress(string memory name) internal view returns (address mandateAddress) {
        for (uint256 i = 0; i < mandateNames.length; i++) {
            if (keccak256(abi.encodePacked(mandateNames[i])) == keccak256(abi.encodePacked(name))) {
                return mandateAddresses[i];
            }
        }
        revert("Mandate not found");
    }

    function getHelperAddress(string memory name) internal view returns (address helperAddress) {
        for (uint256 i = 0; i < helperNames.length; i++) {
            if (keccak256(abi.encodePacked(helperNames[i])) == keccak256(abi.encodePacked(name))) {
                return helperAddresses[i];
            }
        }
        revert("Helper not found");
    }
}
