// // // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import "lib/forge-std/src/Script.sol";

// // core protocol
// import { Powers} from "../src/Powers.sol";
// import { Law } from "../src/Law.sol";
// import { ILaw } from "../src/interfaces/ILaw.sol";
// import { LawUtilities } from "../src/LawUtilities.sol";
// import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

// // laws
// import { NominateMe } from "../src/laws/state/NominateMe.sol";
// import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
// import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
// import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
// import { SelfSelect } from "../src/laws/electoral/SelfSelect.sol";
// import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
// import { OpenAction } from "../src/laws/executive/OpenAction.sol";
// import { PresetAction } from "../src/laws/executive/PresetAction.sol";

// import { SelfDestructAction } from "../src/laws/executive/SelfDestructAction.sol";

// // config
// import { HelperConfig } from "./HelperConfig.s.sol";

// // mocks
// import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
// import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

// /// @notice core script to deploy a dao
// /// Note the {run} function for deploying the dao can be used without changes.
// /// Note  the {initiateConstitution} function for creating bespoke constitution for the DAO.
// /// Note the {getFounders} function for setting founders' roles.
// contract DeployBasicDao is Script {
//     address[] laws;

//     function run()
//         external
//         returns (
//             address payable dao,
//             address[] memory constituentLaws,
//             HelperConfig.NetworkConfig memory config,
//             address payable mock20votes_
//             )
//     {
//         HelperConfig helperConfig = new HelperConfig();
//         config = helperConfig.getConfigByChainId(block.chainid);

//         vm.startBroadcast();
//         Powers powers = new Powers(
//             "Powers 101",
//             "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiebpc5ynyisal3ee426jgpib2vawejibzfgmopjxtmucranjy26py"
//         );
//         Erc20VotesMock erc20VotesMock = new Erc20VotesMock();
//         vm.stopBroadcast();

//         dao = payable(address(powers));
//         mock20votes_ = payable(address(erc20VotesMock));
//         initiateConstitution(dao, mock20votes_);

//         // constitute dao.
//         vm.startBroadcast();
//         powers.constitute(laws);
//         vm.stopBroadcast();

//         return (dao, laws, config, mock20votes_);
//     }

//     function initiateConstitution(
//         address payable dao_,
//         address payable mock20votes_
//         ) public {
//         Law law;
//          LawUtilities.Conditions memory Conditions;

//         //////////////////////////////////////////////////////////////
//         //              CHAPTER 1: EXECUTIVE ACTIONS                //
//         //////////////////////////////////////////////////////////////

//         // law[0]
//         string[] memory inputParams = new string[](3);
//         inputParams[0] = "address[] Targets"; // targets
//         inputParams[1] = "uint256[] Values"; // values
//         inputParams[2] = "bytes[] Calldatas"; // calldatas
//         // setting conditions.
//         Conditions.quorum = 66; // = Two thirds quorum needed to pass the proposal
//         Conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
//         Conditions.votingPeriod = 25; // = duration in number of blocks to vote, about half an hour.
//         // initiating law
//         vm.startBroadcast();
//         law = new ProposalOnly(
//             "Propose an action",
//             "Seniors can propose new actions to be executed. They cannot implement them.",
//             dao_,
//             2, // access role
//             Conditions,
//             inputParams
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete Conditions;

//         // law[1]
//         Conditions.needCompleted = laws[0]; // needs the proposal by Delegates to be completed.
//         vm.startBroadcast();
//         law = new ProposalOnly(
//             "Veto an action",
//             "The admin can veto any proposed action. They can only veto after a proposed action has been formalised.",
//             dao_,
//             0, // access role
//             Conditions,
//             inputParams
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete Conditions;

//         // law[2]
//         // setting conditions.
//         Conditions.quorum = 51; // = 51 majority of seniors need to vote.
//         Conditions.succeedAt = 66; // =  two/thirds majority FOR vote needed to pass.
//         Conditions.votingPeriod = 25; // = duration in number of blocks to vote, about half an hour.
//         Conditions.needCompleted = laws[0]; // needs the proposal by Delegates to be completed.
//         Conditions.needNotCompleted = laws[1]; // needs the admin NOT to have cast a veto.
//         Conditions.delayExecution = 450; // = duration in number of blocks to vote, about half an hour.
//         // initiate law
//         vm.startBroadcast();
//         law = new OpenAction(
//             "Execute an action",
//             "Members can execute actions that seniors proposed and passed the proposal vote. They can only be execute if the admin did not cast a veto.",
//             dao_, // separated powers
//             1, // access role
//             Conditions
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete Conditions;

//         //////////////////////////////////////////////////////////////
//         //              CHAPTER 2: ELECT ROLES                      //
//         //////////////////////////////////////////////////////////////

//         // law[3]
//         vm.startBroadcast();
//         law = new NominateMe(
//             "Nominate self for senior", // max 31 chars
//             "Anyone can nominate themselves for a senior role.",
//             dao_,
//             type(uint32).max, // access role = public access
//             Conditions
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // law[4]
//         vm.startBroadcast();
//         Conditions.throttleExecution = 300; // once every hour
//         Conditions.readStateFrom = laws[3]; // nominateMe
//         law = new DelegateSelect(
//             "Call senior election", // max 31 chars
//             "Anyone can call (and pay for) an election to assign seniors. The nominated accounts with most delegated vote tokens will be assigned as seniors. The law can only be called once every 500 blocks.",
//             dao_, // separated powers protocol.
//             type(uint32).max, // public access
//             Conditions, //  config file.
//             mock20votes_, // the tokens that will be used as votes in the election.
//             3, // maximum amount of delegates
//             2 // role id to be assigned
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete Conditions;

//         // law[5]
//         vm.startBroadcast();
//         law = new SelfSelect(
//             "Select yourself as a member", // max 31 chars
//             "Anyone can self select as member of the community.",
//             dao_,
//             type(uint32).max, // access role = public access
//             Conditions,
//             1
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // laws[6]: SelfDestructAction: label roles in the DAO.
//         address[] memory targets = new address[](2);
//         uint256[] memory values = new uint256[](2);
//         bytes[] memory calldatas = new bytes[](2);
//         for (uint256 i = 0; i < targets.length; i++) {
//             targets[i] = dao_;
//         }
//         calldatas[0] = abi.encodeWithSelector(Powers.labelRole.selector, 1, "member");
//         calldatas[1] = abi.encodeWithSelector(Powers.labelRole.selector, 2, "senior");
//         vm.startBroadcast();
//         law = new SelfDestructAction(
//             "Set label roles",
//             "The admin can label roles. The law self destructs when executed.",
//             dao_, // separated powers protocol.
//             0, // admin.
//             Conditions, //  config file.
//             targets,
//             values,
//             calldatas
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//     }
// }
