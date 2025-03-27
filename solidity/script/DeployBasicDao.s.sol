// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";

// core protocol
import { Powers} from "../src/Powers.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { DeployLaws } from "./DeployLaws.s.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

// mocks
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

/// @notice core script to deploy a dao
/// Note the {run} function for deploying the dao can be used without changes.
/// Note  the {initiateConstitution} function for creating bespoke constitution for the DAO.
/// Note the {getFounders} function for setting founders' roles.
contract DeployBasicDao is Script {
    function run()
        external
        returns (
            address payable dao,
            HelperConfig.NetworkConfig memory config,
            address payable mock20votes_
            )
    {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfigByChainId(block.chainid);
        vm.startBroadcast();
        Powers powers = new Powers(
            "Powers 101",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiebpc5ynyisal3ee426jgpib2vawejibzfgmopjxtmucranjy26py"
        );
        Erc20VotesMock erc20VotesMock = new Erc20VotesMock();
        vm.stopBroadcast();

        dao = payable(address(powers));
        mock20votes_ = payable(address(erc20VotesMock));
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(dao, mock20votes_);

        // constitute dao.
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (dao, config, mock20votes_);
    }

    // function createConstitution(
    //     address payable dao_,
    //     address payable mock20votes_
    //     ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
    //     Law law;
    //     LawUtilities.Conditions memory Conditions;

    //     //////////////////////////////////////////////////////////////
    //     //              CHAPTER 1: EXECUTIVE ACTIONS                //
    //     //////////////////////////////////////////////////////////////

    //     // law[0]
    //     string[] memory inputParams = new string[](3);
    //     inputParams[0] = "address[] Targets"; // targets
    //     inputParams[1] = "uint256[] Values"; // values
    //     inputParams[2] = "bytes[] Calldatas"; // calldatas
    //     // setting conditions.
    //     Conditions.quorum = 66; // = Two thirds quorum needed to pass the proposal
    //     Conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
    //     Conditions.votingPeriod = 25; // = duration in number of blocks to vote, about half an hour.
    //     // initiating law
    //     vm.startBroadcast();
    //     law = new ProposalOnly(
    //         "Propose an action",
    //         "Seniors can propose new actions to be executed. They cannot implement them.",
    //         dao_,
    //         2, // access role
    //         Conditions,
    //         inputParams
    //     );
    //     vm.stopBroadcast();
    //     laws.push(address(law));
    //     delete Conditions;

    //     // law[1]
    //     Conditions.needCompleted = laws[0]; // needs the proposal by Delegates to be completed.
    //     vm.startBroadcast();
    //     law = new ProposalOnly(
    //         "Veto an action",
    //         "The admin can veto any proposed action. They can only veto after a proposed action has been formalised.",
    //         dao_,
    //         0, // access role
    //         Conditions,
    //         inputParams
    //     );
    //     vm.stopBroadcast();
    //     laws.push(address(law));
    //     delete Conditions;

    //     // law[2]
    //     // setting conditions.
    //     Conditions.quorum = 51; // = 51 majority of seniors need to vote.
    //     Conditions.succeedAt = 66; // =  two/thirds majority FOR vote needed to pass.
    //     Conditions.votingPeriod = 25; // = duration in number of blocks to vote, about half an hour.
    //     Conditions.needCompleted = laws[0]; // needs the proposal by Delegates to be completed.
    //     Conditions.needNotCompleted = laws[1]; // needs the admin NOT to have cast a veto.
    //     Conditions.delayExecution = 450; // = duration in number of blocks to vote, about half an hour.
    //     // initiate law
    //     vm.startBroadcast();
    //     law = new OpenAction(
    //         "Execute an action",
    //         "Members can execute actions that seniors proposed and passed the proposal vote. They can only be execute if the admin did not cast a veto.",
    //         dao_, // separated powers
    //         1, // access role
    //         Conditions
    //     );
    //     vm.stopBroadcast();
    //     laws.push(address(law));
    //     delete Conditions;

    //     //////////////////////////////////////////////////////////////
    //     //              CHAPTER 2: ELECT ROLES                      //
    //     //////////////////////////////////////////////////////////////

    //     // law[3]
    //     vm.startBroadcast();
    //     law = new NominateMe(
    //         "Nominate self for senior", // max 31 chars
    //         "Anyone can nominate themselves for a senior role.",
    //         dao_,
    //         type(uint32).max, // access role = public access
    //         Conditions
    //     );
    //     vm.stopBroadcast();
    //     laws.push(address(law));

    //     // law[4]
    //     vm.startBroadcast();
    //     Conditions.throttleExecution = 300; // once every hour
    //     Conditions.readStateFrom = laws[3]; // nominateMe
    //     law = new DelegateSelect(
    //         "Call senior election", // max 31 chars
    //         "Anyone can call (and pay for) an election to assign seniors. The nominated accounts with most delegated vote tokens will be assigned as seniors. The law can only be called once every 500 blocks.",
    //         dao_, // separated powers protocol.
    //         type(uint32).max, // public access
    //         Conditions, //  config file.
    //         mock20votes_, // the tokens that will be used as votes in the election.
    //         3, // maximum amount of delegates
    //         2 // role id to be assigned
    //     );
    //     vm.stopBroadcast();
    //     laws.push(address(law));
    //     delete Conditions;

    //     // law[5]
    //     vm.startBroadcast();
    //     law = new SelfSelect(
    //         "Select yourself as a member", // max 31 chars
    //         "Anyone can self select as member of the community.",
    //         dao_,
    //         type(uint32).max, // access role = public access
    //         Conditions,
    //         1
    //     );
    //     vm.stopBroadcast();
    //     laws.push(address(law));

    //     // laws[6]: SelfDestructAction: label roles in the DAO.
    //     address[] memory targets = new address[](2);
    //     uint256[] memory values = new uint256[](2);
    //     bytes[] memory calldatas = new bytes[](2);
    //     for (uint256 i = 0; i < targets.length; i++) {
    //         targets[i] = dao_;
    //     }
    //     calldatas[0] = abi.encodeWithSelector(Powers.labelRole.selector, 1, "member");
    //     calldatas[1] = abi.encodeWithSelector(Powers.labelRole.selector, 2, "senior");
    //     vm.startBroadcast();
    //     law = new SelfDestructAction(
    //         "Set label roles",
    //         "The admin can label roles. The law self destructs when executed.",
    //         dao_, // separated powers protocol.
    //         0, // admin.
    //         Conditions, //  config file.
    //         targets,
    //         values,
    //         calldatas
    //     );
    //     vm.stopBroadcast();
    //     laws.push(address(law));
    // }

    function createConstitution(
        address payable dao_,
        address payable mock20votes_
        ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](8);
        DeployLaws deployLaws = new DeployLaws();
        (, address[] memory lawAddresses) = deployLaws.run();

        // dummy call for preset actions
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        // directSelect
        conditions.allowedRole = type(uint32).max;
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[1],
            config: abi.encode(1), // role that can be assigned
            conditions: conditions,
            description: "A law to select an account to a specific role directly."
        });
        delete conditions;

        // nominateMe
        conditions.allowedRole = type(uint32).max;
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[10],
            config: abi.encode(), // empty config
            conditions: conditions,
            description: "A law for accounts to nominate themselves for a role."
        });
        delete conditions;

        // delegateSelect
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[0],
            config: abi.encode(
                mock20votes_,
                15, // max role holders
                2 // roleId to be elected
            ),
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
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[6],
            config: abi.encode(), // empty config
            conditions: conditions,
            description: "A law to execute an open action."
        });
        delete conditions;

        // PresetAction
        conditions.allowedRole = 1;
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needCompleted = 3;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targets, values, calldatas),
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;

        // PresetAction for roles
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
            _getRoles(dao_, 7);
        conditions.allowedRole = 0;
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;
    }

    function _getRoles(address payable dao_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");
        address gary = makeAddr("gary");
        address helen = makeAddr("helen");

        // call to set initial roles
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
        // revoke law after use
        if (lawId != 0) {
            calldatas[12] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        }

        return (targets, values, calldatas);
    }
}
