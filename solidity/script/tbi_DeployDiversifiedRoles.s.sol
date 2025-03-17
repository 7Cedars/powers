// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// import "lib/forge-std/src/Script.sol";

// // core protocol
// import { Powers} from "../src/Powers.sol";
// import { Law } from "../src/Law.sol";
// import { ILaw } from "../src/interfaces/ILaw.sol";
// import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

// // laws
// import { NominateMe } from "../src/laws/state/NominateMe.sol"; 
// import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
// import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
// import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
// import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
// import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
// import { PresetAction } from "../src/laws/executive/PresetAction.sol";
// import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";

// import { Members } from "../src/laws/bespoke/diversifiedRoles/Members.sol";
// import { RoleByKyc } from "../src/laws/bespoke/diversifiedRoles/RoleByKyc.sol";
// import { RoleByKycFactory } from "../src/laws/bespoke/diversifiedRoles/RoleByKycFactory.sol";
// import { AiAgents } from "../src/laws/bespoke/diversifiedRoles/AiAgents.sol";
// import { BespokeActionFactory } from "../src/laws/bespoke/diversifiedRoles/BespokeActionFactory.sol";

// // config
// import { HelperConfig } from "./HelperConfig.s.sol";

// // mocks 
// import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
// import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";
// import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

// contract DeployDiversifiedRoles is Script {
//     address[] laws;

//     function run()
//         external
//         returns (
//             address payable dao, 
//             address[] memory constituentLaws, 
//             HelperConfig.NetworkConfig memory config, 
//             address payable mock20_, 
//             address payable mock721_, 
//             address payable mock1155_
//             )
//     {
//         HelperConfig helperConfig = new HelperConfig();
//         config = helperConfig.getConfigByChainId(block.chainid);

//         vm.startBroadcast();
//         // Initiating Dao.
//         Powers powers = new Powers(
//             "Diversified Roles", 
//             "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibszieidbocucrpnwwsljfxktoq46zj45hb7iak6upphl4jow5blm"
//             );
//         // deploying token contracts that will be managed by the Dao.
//         Erc20VotesMock erc20VotesMock = new Erc20VotesMock(); 
//         Erc721Mock erc721Mock = new Erc721Mock();
//         Erc1155Mock erc1155Mock = new Erc1155Mock(); 
//         vm.stopBroadcast();

//         dao = payable(address(powers));
//         mock20_ = payable(address(erc20VotesMock)); 
//         mock721_ = payable(address(erc721Mock));
//         mock1155_ = payable(address(erc1155Mock));
//         initiateConstitution(dao, mock20_, mock721_, mock1155_);

//         // constitute dao.
//         vm.startBroadcast();
//         powers.constitute(laws);
//         // transferring ownership erc721 token contract.
//         erc721Mock.transferOwnership(address(powers));
//         vm.stopBroadcast();

//         return (dao, laws, config, mock20_, mock721_, mock1155_);
//     }

//     function initiateConstitution(
//         address payable dao_,
//         address payable mock20_,
//         address payable mock721_,
//         address payable mock1155_
//     ) public {
//         Law law;
//         ILaw.LawChecks memory LawChecks;

//         //////////////////////////////////////////////////////////////
//         //              CHAPTER 1: EXECUTIVE ACTIONS                //
//         //////////////////////////////////////////////////////////////
//         // laws[0]
//         // add or remove KYC data to address. (public in this case, just for testing purposes.
//         // initiating law.
//         vm.startBroadcast();
//         law = new Members(
//             "Add KYC data to an account.",
//             "Add Know Your Customer (KYC) data to an account. This law is accessible for any one, for testing purposes only.",
//             dao_,
//             type(uint32).max, // access role = public.
//             LawChecks
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // laws[1]
//         // propose new role filter. (Role 2)
//         LawChecks.quorum = 70; // = 60% quorum needed
//         LawChecks.succeedAt = 60; // = Simple majority vote needed.
//         LawChecks.votingPeriod = 1200; // = number of blocks
//         // setting up params
//         string[] memory inputParams = new string[](6); // same as DeployRoleByKyc inputParams
//         inputParams[0] = "string Name"; // name
//         inputParams[1] = "string Description"; // description
//         inputParams[2] = "uint16[] Nationalities"; // nationalities
//         inputParams[3] = "uint16[] residentCountries"; // countries of residence
//         inputParams[4] = "int64 olderThan"; // olderThan
//         inputParams[5] = "int64 youngerThan"; // youngerThan
//         // initiating law.
//         vm.startBroadcast();
//         law = new ProposalOnly(
//             "Propose to create role filter.",
//             "Make a proposal to create a role filter based on Know Your Customer (KYC) data to assign a specific role to a subsection of community members. Input [0] = grantee address to transfer to. Inputs: 0 = name; 1: description; 2: nationalities to select (IBAN code); 3: Country of Residence to select (IBAN code); 4: older than (in seconds); 5: younger than (in seconds);     ",
//             dao_,
//             2, // access role
//             LawChecks,
//             inputParams // input parameters
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete LawChecks;

//         // laws[2]
//         // ok & implement new role self Select filter (Role 1)
//         LawChecks.quorum = 5; // = 5% quorum needed
//         LawChecks.succeedAt = 51; // = Simple majority vote needed.
//         LawChecks.votingPeriod = 1200; // = number of blocks
//         vm.startBroadcast();
//         law = new RoleByKycFactory(
//             "Accept role filter.",
//             "Accept and implement a role filter based on Know Your Customer (KYC) data to assign a specific role to a subsection of community members. Input [0] = grantee address to transfer to. Inputs: 0 = name; 1: description; 2: nationalities to select (IBAN code); 3: Country of Residence to select (IBAN code); 4: older than (in seconds); 5: younger than (in seconds);     ",
//             dao_,
//             1, // access role
//             LawChecks,
//             laws[0]
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete LawChecks;

//         // laws[3]
//         // propose new AiAgent (Role 2)
//         LawChecks.quorum = 60; // = 60% quorum needed
//         LawChecks.succeedAt = 51; // = Simple majority vote needed.
//         LawChecks.votingPeriod = 1200; // = number of blocks
//         // setting up params
//         inputParams = new string[](4); // same as AiAgents inputParams
//         inputParams[0] = "string Name"; // name
//         inputParams[1] = "address Account"; // account
//         inputParams[2] = "string Uri"; // uri
//         inputParams[3] = "bool Add"; // add
//         // initiating law.
//         vm.startBroadcast();
//         law = new ProposalOnly(
//             "Propose to add AI Agent.",
//             "Make a proposal to add an AI agent to the DAO. Inputs: 0 = name agent; 1: account of AI agent; 2: uri; 3: add? (false = remove entry)",
//             dao_,
//             2, // access role
//             LawChecks,
//             inputParams // input parameters
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete LawChecks;

//         // laws[4]
//         // ok & implement new AiAgent (Role 1)
//         LawChecks.quorum = 5; // = 5% quorum needed
//         LawChecks.succeedAt = 51; // = Simple majority vote needed.
//         LawChecks.votingPeriod = 1200; // = number of blocks
//         vm.startBroadcast();
//         law = new AiAgents(
//             "Accept and add AI Agent.",
//             "Accept and add an AI agent to the DAO.",
//             dao_,
//             1, // access role
//             LawChecks
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete LawChecks;

//         // laws[5]
//         // propose new bespoke action (Role 2)
//         LawChecks.quorum = 60; // = 60% quorum needed
//         LawChecks.succeedAt = 51; // = Simple majority vote needed.
//         LawChecks.votingPeriod = 1200; // = number of blocks
//         // setting up params
//         inputParams = new string[](6); // same as AiAgents inputParams
//         inputParams[0] = "string"; // name
//         inputParams[1] = "string"; // description
//         inputParams[2] = "uint32"; // allowedRole
//         inputParams[3] = "address"; // target contract
//         inputParams[4] = "bytes4"; // target function
//         inputParams[5] = "string[]"; // params
//         // initiating law.
//         vm.startBroadcast();
//         law = new ProposalOnly(
//             "Propose new Bespoke Action.",
//             "Propose to deploy a new, role restricted, bespoke action. Inputs: 0 = name; 1: description; 2: allowed Role; 3: target contract; 4: target function; 5: input parameters.",
//             dao_,
//             2, // access role
//             LawChecks,
//             inputParams // input parameters
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));
//         delete LawChecks;

//         // laws [6]
//         // ok & implement new role restricted bespoke action (Admin)
//         vm.startBroadcast();
//         law = new BespokeActionFactory(
//             "Deploy bespoke action.",
//             "Accept and deploy bespoke action.",
//             dao_,
//             0, // access role = Admin.
//             LawChecks
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         //////////////////////////////////////////////////////////////
//         //              CHAPTER 2: ELECT ROLES                      //
//         //////////////////////////////////////////////////////////////

//         // laws[7]
//         // self select Role 1 (checks if age has been filled out, but accepts everyone.)
//         vm.startBroadcast();
//         law = new RoleByKyc(
//             "Claim community role.",
//             "Claim community role.",
//             dao_,
//             type(uint32).max, // access role = public.
//             LawChecks,
//             //// self select
//             1, // uint32 roleId_
//             //// filter
//             new uint16[](0), // memory nationalities,
//             new uint16[](0), // uint16[] memory countryOfResidences,
//             1, // int64 olderThan, // in seconds, set to minimum
//             type(int64).max, // int64 youngerThan // in seconds, set to maximum.
//             laws[0] // address members
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // laws[8]
//         // NominateMe for Role 2 (allowedRole = Role 1)
//         vm.startBroadcast();
//         law = new NominateMe(
//             "Nominate self for role 2", // max 31 chars
//             "Community members can nominate themselves for role 2.",
//             dao_,
//             type(uint32).max, // access role = public access
//             LawChecks
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // laws[9]
//         // peer select Role 2 (allowedRole = Role 1)
//         LawChecks.readStateFrom = laws[8]; // = nominateMe
//         vm.startBroadcast();
//         law = new PeerSelect(
//             "Claim community role.",
//             "Claim community role.",
//             dao_,
//             type(uint32).max, // access role = public.
//             LawChecks,
//             //
//             15,
//             2 // uint32 roleId_
//         );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // ... all other roles through dynamic self select.
//     }
// }
