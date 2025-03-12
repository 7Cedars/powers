// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import "lib/forge-std/src/Script.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// // core protocol
// import { Powers} from "../src/Powers.sol";
// import { Law } from "../src/Law.sol";
// import { ILaw } from "../src/interfaces/ILaw.sol";
// import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

// // config
// import { HelperConfig } from "./HelperConfig.s.sol";

// // laws
// import { NominateMe } from "../src/laws/state/NominateMe.sol"; 
// import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
// import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
// import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
// import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
// import { OpenAction } from "../src/laws/executive/OpenAction.sol";
// import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
// import { PresetAction } from "../src/laws/executive/PresetAction.sol";
// import { StringsArray } from "../src/laws/state/StringsArray.sol";
// import { RevokeMembership } from "../src/laws/bespoke/alignedDao/RevokeMembership.sol";
// import { ReinstateRole } from "../src/laws/bespoke/alignedDao/ReinstateRole.sol";
// import { RequestPayment } from "../src/laws/bespoke/alignedDao/RequestPayment.sol";
// import { NftSelfSelect } from "../src/laws/bespoke/alignedDao/NftSelfSelect.sol";

// import { SelfDestructPresetAction } from "../src/laws/executive/SelfDestructPresetAction.sol"; 

// // mocks 
// import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
// import { Erc20TaxedMock } from "../test/mocks/Erc20TaxedMock.sol";
// import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";

// contract DeployAlignedDao is Script {
//     address[] laws;

//     function run()
//         external
//         returns (
//             address payable dao,  
//             address[] memory constituentLaws, 
//             HelperConfig.NetworkConfig memory config, 
//             address payable mock20votes_, 
//             address payable mock20taxed_, 
//             address payable mock721_
//             )
//     {
//         HelperConfig helperConfig = new HelperConfig();
//         config = helperConfig.getConfigByChainId(block.chainid);

//         // deploying token contracts that will be managed by the Dao. 
//         vm.startBroadcast();
//         // initiating Dao
//         Powers powers = new Powers(
//             "Aligned Dao", 
//             "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreihwvloi4rmzeertaclrz4pom4a42fn6asbcxex2iw3kggmdmsexee"
//             );
//         // Deploying token contracts that will be controlled by the Dao
//         Erc20VotesMock erc20VotesMock = new Erc20VotesMock(); 
//         Erc20TaxedMock erc20TaxedMock = new Erc20TaxedMock(
//             5, // taxRate_, 
//             3, // DENOMINATOR_,
//             25 //uint48 epochDuration_
//             );
//         Erc721Mock erc721Mock = new Erc721Mock();
//         vm.stopBroadcast();

//         dao = payable(address(powers));
//         mock20votes_ = payable(address(erc20VotesMock)); 
//         mock20taxed_ = payable(address(erc20TaxedMock)); 
//         mock721_ = payable(address(erc721Mock));

//         // initiating constitution: creates the Daos laws. 
//         initiateConstitution(dao, mock20votes_, mock20taxed_, mock721_);

//         vm.startBroadcast();
//         // constitute dao.
//         powers.constitute(laws);
//         // & transferring ownership of tokens to the Dao. 
//         erc20TaxedMock.transferOwnership(address(powers));
//         erc721Mock.transferOwnership(address(powers));
//         vm.stopBroadcast();
 
//         return (dao, laws, config, mock20votes_,  mock20taxed_, mock721_);
//     }

//     function initiateConstitution(
//         address payable dao_,
//         address payable mock20votes_,
//         address payable mock20taxed_,
//         address payable mock721_
//     ) public {
//         Law law;
//         ILaw.LawConfig memory lawConfig;

//         //////////////////////////////////////////////////////////////
//         //              CHAPTER 1: EXECUTIVE ACTIONS                //
//         //////////////////////////////////////////////////////////////
//         // laws[0]
//         lawConfig.quorum = 60; // = 60% quorum needed
//         lawConfig.succeedAt = 50; // = Simple majority vote needed.
//         lawConfig.votingPeriod = 25; // = number of blocks, about half an hour.  
//         // setting up params
//         string[] memory inputParams = new string[](2);
//         inputParams[0] = "string Value";
//         inputParams[1] = "bool Add";
//         // initiating law.
//         vm.startBroadcast();
//         law = new ProposalOnly(
//             "Propose to add / remove value",
//             "Members can propose to add a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented.",
//             dao_,
//             1, // access role
//             lawConfig,
//             inputParams // input parameters
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete lawConfig;

//         // laws[1]
//         lawConfig.quorum = 30; // = 30% quorum needed
//         lawConfig.succeedAt = 66; // =  two/thirds majority needed for
//         lawConfig.votingPeriod = 25; // = number of blocks, about half an hour.
//         lawConfig.needCompleted = laws[0];
//         // initiating law.
//         vm.startBroadcast();
//         law = new StringsArray(
//             "Add and Remove values",
//             "Governors accept & implement a proposed decision to add or remove a value from the Dao.",
//             dao_, // separated powers
//             2, // access role
//             lawConfig // bespoke configs for this law
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete lawConfig;

//         // laws[2]
//         lawConfig.quorum = 80; // = 80% quorum needed
//         lawConfig.succeedAt = 66; // =  two/thirds majority needed for
//         lawConfig.votingPeriod = 25; // = number of blocks, about half an hour.
//         // initiating law
//         vm.startBroadcast();
//         law = new RevokeMembership(
//             "Revoke membership", // max 31 chars
//             "Seniors can, subject to a vote, revoke a member's role and have their access token burned.",
//             dao_, // separated powers
//             3, // access role
//             lawConfig, // bespoke configs for this law.
//             mock721_ // the Erc721 token address.
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete lawConfig;

//         // laws[3]
//         lawConfig.quorum = 1; // = 1% quorum needed
//         lawConfig.succeedAt = 80; // = 80 percent of the quorum needs to vote fore reinstatement.
//         lawConfig.votingPeriod = 25; // = number of blocks, about half an hour.
//         lawConfig.needCompleted = laws[2];
//         // input params
//         inputParams = new string[](2);
//         inputParams[0] = "uint256 TokenId";
//         inputParams[1] = "address Account";
//         // initiating law
//         vm.startBroadcast();
//         law = new ProposalOnly(
//             "Challenge a member revoke",
//             "Members can challenge revoking of another members role.",
//             dao_, // separated powers
//             1, // access role
//             lawConfig, // bespoke configs for this law.
//             inputParams // input parameters
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete lawConfig;

//         // laws[4]
//         lawConfig.quorum = 20; // = 20% quorum needed
//         lawConfig.succeedAt = 67; // =  two/thirds majority needed for
//         lawConfig.votingPeriod = 25; // = number of blocks, about half an hour.
//         lawConfig.needCompleted = laws[3]; // NB! £todo all the law references need to be changed!
//         //initiating law
//         vm.startBroadcast();
//         law = new ReinstateRole(
//             "Reinstate member",
//             "Governors can reinstate a member after members formalised a challenge.",
//             dao_,
//             2, // access role
//             lawConfig,
//             mock721_
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete lawConfig;

//         // laws[5]
//         vm.startBroadcast();
//         law = new RequestPayment(
//             "Members can request payment",
//             "Members can request a payment of 5_000 tokens every 300 blocks.",
//             dao_,
//             1,
//             lawConfig, //  config
//             // bespoke configs for this law:
//             mock20taxed_, // token address.
//             0,
//             5000, // number of tokens
//             300 // = number of blocks, about an hour.
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         //////////////////////////////////////////////////////////////
//         //              CHAPTER 2: ELECT ROLES                      //
//         //////////////////////////////////////////////////////////////
//         // laws[6]
//         vm.startBroadcast();
//         law = new NftSelfSelect(
//             "Elect self for member role", // max 31 chars
//             string.concat("Anyone who knows how to mint an NFT at ", Strings.toHexString(uint256(addressToInt(mock721_)), 20), " can (de)select themselves for a member role. Mint an NFT and claim the role!"),
//             dao_,
//             type(uint32).max, // access role = public access
//             lawConfig,
//             1, // role id
//             mock721_
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // laws[7]
//         vm.startBroadcast();
//         law = new NominateMe(
//             "Nominate self for governor", // max 31 chars
//             "Anyone can nominate themselves for a governor role.",
//             dao_,
//             type(uint32).max, // access role = public access
//             lawConfig
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // laws[8]
//         lawConfig.readStateFrom = laws[7];
//         vm.startBroadcast();
//         law = new DelegateSelect(
//             "Call governor election", // max 31 chars
//             "Governor elections are called by an oracle, as set by the admin. The five nominated accounts with most delegated vote tokens are then assigned as governor.",
//             dao_, // separated powers protocol.
//             4, // oracle role id designation.
//             lawConfig, //  config file.
//             mock20votes_, // the tokens that will be used as votes in the election.
//             5, // maximum amount of governors
//             2 // role id to be assigned
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete lawConfig;

//         // laws[9]
//         vm.startBroadcast();
//         law = new NominateMe(
//             "Nominate self for senior", // max 31 chars
//             "Anyone can nominate themselves as a senior.",
//             dao_,
//             type(uint32).max, // access role = public access
//             lawConfig
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // laws[10]
//         lawConfig.quorum = 66; // = Two thirds quorum needed to pass the proposal
//         lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
//         lawConfig.votingPeriod = 25; // = duration in number of blocks to vote, about half an hour.
//         lawConfig.readStateFrom = laws[9]; // NominateMe
//         vm.startBroadcast();
//         law = new PeerSelect(
//             "Assign senior role", // max 31 chars
//             "Senior roles are assigned by their peers through a majority vote.",
//             dao_, // separated powers protocol.
//             3, // role 3 id designation.
//             lawConfig, //  config file.
//             3, // maximum elected to role, 
//             3 // role id to be assigned
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete lawConfig;

//         // laws[11]
//         // input params
//         inputParams = new string[](2);
//         inputParams[0] = "bool revoke"; 
//         inputParams[1] = "address Account";
//         vm.startBroadcast();
//         law = new ProposalOnly(
//             "Propose oracle", // max 31 chars
//             "The admin proposes an account as oracle.",
//             dao_, // separated powers protocol.
//             0, // admin.
//             lawConfig, //  config file.
//             inputParams
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // laws[12]
//         lawConfig.quorum = 30; // = Two thirds quorum needed to pass the proposal
//         lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
//         lawConfig.votingPeriod = 25; // = duration in number of blocks to vote, about half an hour.
//         lawConfig.needCompleted = laws[11]; // ProposalOnly 
//         vm.startBroadcast();
//         law = new DirectSelect(
//             "Accept oracle", // max 31 chars
//             "Seniors accept the proposed account as oracle.",
//             dao_, // separated powers protocol.
//             3, // role 1.
//             lawConfig, //  config file.
//             4 // role id to be assigned
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete lawConfig;

//         // // laws[13]
//         // // input params
//         // inputParams = new string[](2);
//         // inputParams[0] = "uint32 RoleId"; 
//         // inputParams[1] = "address Account";
//         // vm.startBroadcast();
//         // law = new BespokeAction(
//         //     "Assign role for testing", // max 31 chars
//         //     "The admin can assign any role to any account. For testing purposes only.",
//         //     dao_, // separated powers protocol.
//         //     0, // admin.
//         //     lawConfig, //  config file.
//         //     dao_, // target contract
//         //     Powers.assignRole.selector, // target function
//         //     inputParams
//         // );
//         // vm.stopBroadcast();
//         // laws.push(address(law));

//         // // laws[14]
//         // lawConfig.needCompleted = laws[13];  
//         // vm.startBroadcast();
//         // law = new BespokeAction(
//         //     "Revoke role for testing", // max 31 chars
//         //     "The admin can revoke roles that they assigned. For testing purposes only.",
//         //     dao_, // separated powers protocol.
//         //     0, // admin.
//         //     lawConfig, //  config file.
//         //     dao_, // target contract
//         //     Powers.revokeRole.selector, // target function
//         //     inputParams // same input params as at laws[13]
//         // );
//         // vm.stopBroadcast();
//         // laws.push(address(law));
//         // delete lawConfig;

//         // laws[13]: selfDestructPresetAction: assign initial accounts to role 3.
//         address[] memory targets = new address[](5);
//         uint256[] memory values = new uint256[](5);
//         bytes[] memory calldatas = new bytes[](5);
//         for (uint256 i = 0; i < targets.length; i++) {
//             targets[i] = dao_;
//         }
//         calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, 3, 0x328735d26e5Ada93610F0006c32abE2278c46211);
//         calldatas[1] = abi.encodeWithSelector(Powers.labelRole.selector, 1, "Member");
//         calldatas[2] = abi.encodeWithSelector(Powers.labelRole.selector, 2, "Governor");
//         calldatas[3] = abi.encodeWithSelector(Powers.labelRole.selector, 3, "Senior");
//         calldatas[4] = abi.encodeWithSelector(Powers.labelRole.selector, 4, "Oracle");
        
//         vm.startBroadcast();
//         law = new SelfDestructPresetAction(
//             "Set initial labels & role", // max 31 chars
//             "The admin assigns an initial account to the senior role and gives role ids their labels. The law self destructs when executed.",
//             dao_, // separated powers protocol.
//             0, // admin.
//             lawConfig, //  config file.
//             targets,
//             values,
//             calldatas
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//     }

//     ///////////////////////////////////////////////////////
//     //                  Helper functions                //
//     //////////////////////////////////////////////////////
//     function addressToInt(address a) internal pure returns (uint256) {
//         return uint256(uint160(a));
//     }
// }
