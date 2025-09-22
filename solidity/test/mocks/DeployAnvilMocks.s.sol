// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import { Script } from "forge-std/Script.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
// import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
// // import { console2 } from "forge-std/console2.sol";
// // core protocol
// import { Powers } from "../../src/Powers.sol";
// import { Law } from "../../src/Law.sol";
// import { ILaw } from "../../src/interfaces/ILaw.sol";
// import { LawUtilities } from "../../src/LawUtilities.sol";
// import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";

// // laws
// import { DelegateSelect } from "../../src/laws/electoral/DelegateSelect.sol";
// import { DirectSelect } from "../../src/laws/electoral/DirectSelect.sol";
// import { PeerSelect } from "../../src/laws/electoral/PeerSelect.sol";
// import { StatementOfIntent } from "../../src/laws/executive/StatementOfIntent.sol";
// import { OpenAction } from "../../src/laws/executive/OpenAction.sol";
// import { PresetAction } from "../../src/laws/executive/PresetAction.sol";
// import { BespokeAction } from "../../src/laws/executive/BespokeAction.sol";
// import { SelfSelect } from "../../src/laws/electoral/SelfSelect.sol";
// import { RenounceRole } from "../../src/laws/electoral/RenounceRole.sol";
// import { AddressesMapping } from "../../src/laws/state/AddressesMapping.sol";
// import { NominateMe } from "../../src/laws/state/NominateMe.sol";
// import { StringsArray } from "../../src/laws/state/StringsArray.sol";
// import { TokensArray } from "../../src/laws/state/TokensArray.sol";
// import { TaxSelect } from "../../src/laws/electoral/TaxSelect.sol";
// import { HolderSelect } from "../../src/laws/electoral/HolderSelect.sol";
// import { Grant } from "../../src/laws/state/Grant.sol";
// import { GrantProgram } from "../../src/laws/executive/GrantProgram.sol";
// import { AdoptLaw } from "../../src/laws/executive/AdoptLaw.sol";
// import { VoteOnAccounts } from "../../src/laws/state/VoteOnAccounts.sol";
// import { DirectDeselect } from "../../src/laws/electoral/DirectDeselect.sol";
// // import { Subscription } from "../../src/laws/electoral/Subscription.sol";
// import { StartElection } from "../../src/laws/electoral/StartElection.sol";
// import { EndElection } from "../../src/laws/electoral/EndElection.sol";
// import { GovernorCreateProposal } from "../../src/laws/integrations/GovernorCreateProposal.sol";
// import { GovernorExecuteProposal } from "../../src/laws/integrations/GovernorExecuteProposal.sol";
// import { SnapToGov_CheckSnapExists } from "../../src/laws/integrations/SnapToGov_CheckSnapExists.sol";
// import { ElectionStart } from "../../src/laws/electoral/ElectionStart.sol";
// import { ElectionList } from "../../src/laws/electoral/ElectionList.sol";
// import { ElectionTally } from "../../src/laws/electoral/ElectionTally.sol";
// import { NStrikesYourOut } from "../../src/laws/electoral/NStrikesYourOut.sol";
// import { FlagActions } from "../../src/laws/state/FlagActions.sol";
// import { EndGrant } from "../../src/laws/executive/EndGrant.sol";
// import { RoleByGitCommit } from "../../src/laws/offchain/RoleByGitCommit.sol";
// import { StringToAddress } from "../../src/laws/state/StringToAddress.sol";
// import { Erc20Budget } from "../../src/laws/state/Erc20Budget.sol";
// import { AdoptLawPackage } from "../../src/laws/executive/AdoptLawPackage.sol";
// import { RoleByRoles } from "../../src/laws/electoral/RoleByRoles.sol";
// import { BuyAccess } from "../../src/laws/electoral/BuyAccess.sol";

// // Mocks
// import { Erc1155Mock } from "./Erc1155Mock.sol";
// import { Erc20VotesMock } from "./Erc20VotesMock.sol";
// import { Erc20TaxedMock } from "./Erc20TaxedMock.sol";
// import { Erc721Mock } from "./Erc721Mock.sol";
// import { PowersMock } from "./PowersMock.sol";
// import { GovernorMock } from "./GovernorMock.sol";
// import { FunctionsRouterMock } from "./FunctionsRouterMock.sol";

// // @dev this script is used to deploy the laws to the chain.
// // Note: we do not return addresses of the deployed laws.
// // addresses should be computed on basis of deployment data using create2.
// contract DeployAnvilMocks is Script {
//     function run(address daoMock)
//         external
//         returns (
//             string[] memory lawNames,
//             address[] memory lawAddresses,
//             string[] memory mockNames,
//             address[] memory mockAddresses
//         )
//     {
//         lawNames = new string[](37);
//         lawAddresses = new address[](37);
//         mockNames = new string[](7);
//         mockAddresses = new address[](7);

//         vm.startBroadcast();
//         lawAddresses[0] = address(new DelegateSelect());
//         lawAddresses[1] = address(new DirectSelect());
//         lawAddresses[2] = address(new PeerSelect());
//         lawAddresses[3] = address(new RenounceRole());
//         lawAddresses[4] = address(new SelfSelect());
//         lawAddresses[5] = address(new BespokeAction());
//         lawAddresses[6] = address(new OpenAction());
//         lawAddresses[7] = address(new PresetAction());
//         lawAddresses[8] = address(new StatementOfIntent());
//         lawAddresses[9] = address(new AddressesMapping());
//         lawAddresses[10] = address(new NominateMe());
//         lawAddresses[11] = address(new StringsArray());
//         lawAddresses[12] = address(new TokensArray());
//         lawAddresses[13] = address(new TaxSelect());
//         lawAddresses[14] = address(new HolderSelect());
//         lawAddresses[15] = address(new Grant());
//         lawAddresses[16] = address(new GrantProgram());
//         lawAddresses[17] = address(new AdoptLaw());
//         lawAddresses[18] = address(new VoteOnAccounts());
//         lawAddresses[19] = address(new DirectDeselect());
//         lawAddresses[20] = address(new StartElection());
//         lawAddresses[21] = address(new EndElection());
//         lawAddresses[22] = address(new GovernorCreateProposal());
//         lawAddresses[23] = address(new GovernorExecuteProposal());

//         mockAddresses[0] = address(new PowersMock());
//         mockAddresses[6] = address(new FunctionsRouterMock());

//         lawAddresses[24] = address(new SnapToGov_CheckSnapExists(mockAddresses[6]));
//         lawAddresses[25] = address(new ElectionStart());
//         lawAddresses[26] = address(new ElectionList());
//         lawAddresses[27] = address(new ElectionTally());
//         lawAddresses[28] = address(new NStrikesYourOut());
//         lawAddresses[29] = address(new FlagActions());
//         lawAddresses[30] = address(new EndGrant());
//         lawAddresses[31] = address(new RoleByGitCommit(address(mockAddresses[6])));
//         lawAddresses[32] = address(new StringToAddress());
//         lawAddresses[33] = address(new Erc20Budget());
//         lawAddresses[34] = address(new AdoptLawPackage());
//         lawAddresses[35] = address(new RoleByRoles());
//         lawAddresses[36] = address(new BuyAccess());

//         vm.stopBroadcast();

//         vm.startBroadcast(daoMock);
//         mockAddresses[2] = address(new Erc20VotesMock());
//         mockAddresses[3] = address(new Erc20TaxedMock());
//         mockAddresses[4] = address(new Erc721Mock());
//         mockAddresses[5] = address(new Erc1155Mock());
//         mockAddresses[1] = address(new GovernorMock(mockAddresses[2]));

//         // Deploy SnapToGov_CheckSnapExists with the FunctionsRouterMock

//         vm.stopBroadcast();

//         lawNames[0] = "DelegateSelect";
//         lawNames[1] = "DirectSelect";
//         lawNames[2] = "PeerSelect";
//         lawNames[3] = "RenounceRole";
//         lawNames[4] = "SelfSelect";
//         lawNames[5] = "BespokeAction";
//         lawNames[6] = "OpenAction";
//         lawNames[7] = "PresetAction";
//         lawNames[8] = "StatementOfIntent";
//         lawNames[9] = "AddressesMapping";
//         lawNames[10] = "NominateMe";
//         lawNames[11] = "StringsArray";
//         lawNames[12] = "TokensArray";
//         lawNames[13] = "TaxSelect";
//         lawNames[14] = "HolderSelect";
//         lawNames[15] = "Grant";
//         lawNames[16] = "GrantProgram";
//         lawNames[17] = "AdoptLaw";
//         lawNames[18] = "VoteOnAccounts";
//         lawNames[19] = "DirectDeselect";
//         // lawNames[21] = "Subscription";
//         lawNames[20] = "StartElection"; 
//         lawNames[21] = "EndElection";
//         lawNames[22] = "GovernorCreateProposal";
//         lawNames[23] = "GovernorExecuteProposal";
//         lawNames[24] = "SnapToGov_CheckSnapExists";
//         lawNames[25] = "ElectionStart";
//         lawNames[26] = "ElectionList";
//         lawNames[27] = "ElectionTally";
//         lawNames[28] = "NStrikesYourOut";
//         lawNames[29] = "FlagActions";
//         lawNames[30] = "EndGrant";
//         lawNames[31] = "RoleByGitCommit";
//         lawNames[32] = "StringToAddress";
//         lawNames[33] = "Erc20Budget";
//         lawNames[34] = "AdoptLawPackage";
//         lawNames[35] = "RoleByRoles";
//         lawNames[36] = "BuyAccess";
        
//         mockNames[0] = "PowersMock";
//         mockNames[1] = "GovernorMock";
//         mockNames[2] = "Erc20VotesMock";
//         mockNames[3] = "Erc20TaxedMock";
//         mockNames[4] = "Erc721Mock";
//         mockNames[5] = "Erc1155Mock";
//         mockNames[6] = "FunctionsRouterMock";
//     }
// }
