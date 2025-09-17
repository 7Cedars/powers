// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
// import { console2 } from "forge-std/console2.sol";

// core protocol
import { Powers } from "../src/Powers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { LawUtilities } from "../src/LawUtilities.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

// laws
import { NominateMe } from "../src/laws/state/NominateMe.sol";
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { StatementOfIntent } from "../src/laws/executive/StatementOfIntent.sol";
import { OpenAction } from "../src/laws/executive/OpenAction.sol";
import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";
import { StringsArray } from "../src/laws/state/StringsArray.sol";
import { TokensArray } from "../src/laws/state/TokensArray.sol";
import { SelfSelect } from "../src/laws/electoral/SelfSelect.sol";
import { RenounceRole } from "../src/laws/electoral/RenounceRole.sol";
import { AddressesMapping } from "../src/laws/state/AddressesMapping.sol";
import { TaxSelect } from "../src/laws/electoral/TaxSelect.sol";
import { HolderSelect } from "../src/laws/electoral/HolderSelect.sol";
import { Grant } from "../src/laws/state/Grant.sol";
import { GrantProgram } from "../src/laws/executive/GrantProgram.sol";
import { AdoptLaw } from "../src/laws/executive/AdoptLaw.sol";
import { NStrikesYourOut } from "../src/laws/electoral/NStrikesYourOut.sol";
import { FlagActions } from "../src/laws/state/FlagActions.sol";
import { DirectDeselect } from "../src/laws/electoral/DirectDeselect.sol";
import { EndGrant } from "../src/laws/executive/EndGrant.sol";
// import { Subscription } from "../src/laws/electoral/Subscription.sol";
import { VoteOnAccounts } from "../src/laws/state/VoteOnAccounts.sol";
import { StartElection } from "../src/laws/electoral/StartElection.sol";
import { EndElection } from "../src/laws/electoral/EndElection.sol";
import { GovernorCreateProposal } from "../src/laws/integrations/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../src/laws/integrations/GovernorExecuteProposal.sol";
import { SnapToGov_CheckSnapExists } from "../src/laws/integrations/SnapToGov_CheckSnapExists.sol";
import { SnapToGov_CheckSnapPassed } from "../src/laws/integrations/SnapToGov_CheckSnapPassed.sol";
import { SnapToGov_CreateGov } from "../src/laws/integrations/SnapToGov_CreateGov.sol";
import { SnapToGov_CancelGov } from "../src/laws/integrations/SnapToGov_CancelGov.sol";
import { SnapToGov_ExecuteGov } from "../src/laws/integrations/SnapToGov_ExecuteGov.sol";
import { ElectionList } from "../src/laws/electoral/ElectionList.sol";
import { ElectionStart } from "../src/laws/electoral/ElectionStart.sol";
import { ElectionTally } from "../src/laws/electoral/ElectionTally.sol";
import { RoleByGitCommit } from "../src/laws/offchain/RoleByGitCommit.sol";
import { StringToAddress } from "../src/laws/state/StringToAddress.sol";
import { Erc20Budget } from "../src/laws/state/Erc20Budget.sol";
import { AdoptLawPackage } from "../src/laws/executive/AdoptLawPackage.sol";
import { RoleByRoles } from "../src/laws/electoral/RoleByRoles.sol";
import { BuyAccess } from "../src/laws/electoral/BuyAccess.sol";

// @dev this script is used to deploy the laws to the chain.
// Note: we do not return addresses of the deployed laws.
// addresses should be computed on basis of deployment data using create2.
contract DeployLaws is Script {
    HelperConfig public helperConfig;
    address public router;

    function run() external returns (string[] memory names, address[] memory addresses) {
        helperConfig = new HelperConfig();
        router = helperConfig.getConfig().chainlinkFunctionsRouter;
        // console2.log("router1", router);

        names = new string[](42);
        addresses = new address[](42);
        bytes[] memory creationCodes = new bytes[](42);
        bytes[] memory constructorArgs = new bytes[](42);

        names[0] = "DelegateSelect";
        creationCodes[0] = type(DelegateSelect).creationCode;
        constructorArgs[0] = abi.encode("DelegateSelect");

        names[1] = "DirectSelect";
        creationCodes[1] = type(DirectSelect).creationCode;
        constructorArgs[1] = abi.encode("DirectSelect");

        names[2] = "PeerSelect";
        creationCodes[2] = type(PeerSelect).creationCode;
        constructorArgs[2] = abi.encode("PeerSelect");

        names[3] = "RenounceRole";
        creationCodes[3] = type(RenounceRole).creationCode;
        constructorArgs[3] = abi.encode("RenounceRole");

        names[4] = "SelfSelect";
        creationCodes[4] = type(SelfSelect).creationCode;
        constructorArgs[4] = abi.encode("SelfSelect");

        names[5] = "BespokeAction";
        creationCodes[5] = type(BespokeAction).creationCode;
        constructorArgs[5] = abi.encode("BespokeAction");

        names[6] = "OpenAction";
        creationCodes[6] = type(OpenAction).creationCode;
        constructorArgs[6] = abi.encode("OpenAction");

        names[7] = "PresetAction";
        creationCodes[7] = type(PresetAction).creationCode;
        constructorArgs[7] = abi.encode("PresetAction");

        names[8] = "StatementOfIntent";
        creationCodes[8] = type(StatementOfIntent).creationCode;
        constructorArgs[8] = abi.encode("StatementOfIntent");

        names[9] = "AddressesMapping";
        creationCodes[9] = type(AddressesMapping).creationCode;
        constructorArgs[9] = abi.encode("AddressesMapping");

        names[10] = "NominateMe";
        creationCodes[10] = type(NominateMe).creationCode;
        constructorArgs[10] = abi.encode("NominateMe");

        names[11] = "StringsArray";
        creationCodes[11] = type(StringsArray).creationCode;
        constructorArgs[11] = abi.encode("StringsArray");

        names[12] = "TokensArray";
        creationCodes[12] = type(TokensArray).creationCode;
        constructorArgs[12] = abi.encode("TokensArray");

        names[13] = "TaxSelect";
        creationCodes[13] = type(TaxSelect).creationCode;
        constructorArgs[13] = abi.encode("TaxSelect");

        names[14] = "HolderSelect";
        creationCodes[14] = type(HolderSelect).creationCode;
        constructorArgs[14] = abi.encode("HolderSelect");

        names[15] = "Grant";
        creationCodes[15] = type(Grant).creationCode;
        constructorArgs[15] = abi.encode("Grant");

        names[16] = "AdoptLaw";
        creationCodes[16] = type(AdoptLaw).creationCode;
        constructorArgs[16] = abi.encode("AdoptLaw");

        names[17] = "VoteOnAccounts";
        creationCodes[17] = type(VoteOnAccounts).creationCode;
        constructorArgs[17] = abi.encode("VoteOnAccounts");

        names[18] = "DirectDeselect";
        creationCodes[18] = type(DirectDeselect).creationCode;
        constructorArgs[18] = abi.encode("DirectDeselect");

        // names[21] = "Subscription";
        // creationCodes[21] = type(Subscription).creationCode;
        // constructorArgs[21] = abi.encode("Subscription");

        names[19] = "DirectDeselect";
        creationCodes[19] = type(DirectDeselect).creationCode;
        constructorArgs[19] = abi.encode("DirectDeselect");

        names[20] = "StartElection";
        creationCodes[20] = type(StartElection).creationCode;
        constructorArgs[20] = abi.encode("StartElection");

        names[21] = "EndElection";
        creationCodes[21] = type(EndElection).creationCode;
        constructorArgs[21] = abi.encode("EndElection");

        names[22] = "GovernorCreateProposal";
        creationCodes[22] = type(GovernorCreateProposal).creationCode;
        constructorArgs[22] = abi.encode("GovernorCreateProposal");

        names[23] = "GovernorExecuteProposal";
        creationCodes[23] = type(GovernorExecuteProposal).creationCode;
        constructorArgs[23] = abi.encode("GovernorExecuteProposal");

        names[24] = "SnapToGov_CheckSnapExists";
        creationCodes[24] = type(SnapToGov_CheckSnapExists).creationCode;
        constructorArgs[24] = abi.encode(router);

        names[25] = "SnapToGov_CheckSnapPassed";
        creationCodes[25] = type(SnapToGov_CheckSnapPassed).creationCode;
        constructorArgs[25] = abi.encode(router);

        names[26] = "SnapToGov_CreateGov";
        creationCodes[26] = type(SnapToGov_CreateGov).creationCode;
        constructorArgs[26] = abi.encode("SnapToGov_CreateGov");

        names[27] = "SnapToGov_CancelGov";
        creationCodes[27] = type(SnapToGov_CancelGov).creationCode;
        constructorArgs[27] = abi.encode("SnapToGov_CancelGov");

        names[28] = "SnapToGov_ExecuteGov";
        creationCodes[28] = type(SnapToGov_ExecuteGov).creationCode;
        constructorArgs[28] = abi.encode("SnapToGov_ExecuteGov");

        names[29] = "ElectionList";
        creationCodes[29] = type(ElectionList).creationCode;
        constructorArgs[29] = abi.encode("ElectionList");

        names[30] = "ElectionStart";
        creationCodes[30] = type(ElectionStart).creationCode;
        constructorArgs[30] = abi.encode("ElectionStart");

        names[31] = "ElectionTally";
        creationCodes[31] = type(ElectionTally).creationCode;
        constructorArgs[31] = abi.encode("ElectionTally");

        names[32] = "NStrikesYourOut";
        creationCodes[32] = type(NStrikesYourOut).creationCode;
        constructorArgs[32] = abi.encode("NStrikesYourOut");

        names[33] = "FlagActions";
        creationCodes[33] = type(FlagActions).creationCode;
        constructorArgs[33] = abi.encode("FlagActions");

        names[34] = "GrantProgram";
        creationCodes[34] = type(GrantProgram).creationCode;
        constructorArgs[34] = abi.encode("GrantProgram");

        names[35] = "EndGrant";
        creationCodes[35] = type(EndGrant).creationCode;
        constructorArgs[35] = abi.encode("EndGrant");

        names[36] = "RoleByGitCommit";
        creationCodes[36] = type(RoleByGitCommit).creationCode;
        constructorArgs[36] = abi.encode(router);

        names[37] = "StringToAddress";
        creationCodes[37] = type(StringToAddress).creationCode;
        constructorArgs[37] = abi.encode("StringToAddress");

        names[38] = "Erc20Budget";
        creationCodes[38] = type(Erc20Budget).creationCode;
        constructorArgs[38] = abi.encode("Erc20Budget");

        names[39] = "AdoptLawPackage";
        creationCodes[39] = type(AdoptLawPackage).creationCode;
        constructorArgs[39] = abi.encode("AdoptLawPackage");

        names[40] = "RoleByRoles";
        creationCodes[40] = type(RoleByRoles).creationCode;
        constructorArgs[40] = abi.encode("RoleByRoles");

        names[41] = "BuyAccess";
        creationCodes[41] = type(BuyAccess).creationCode;
        constructorArgs[41] = abi.encode("BuyAccess");

        // console2.log("router2", router);

        for (uint256 i = 0; i < creationCodes.length; i++) {
            //    console2.log("router", router);
            addresses[i] = deployLaw(creationCodes[i], constructorArgs[i]);
        }
    }

    //////////////////////////////////////////////////////////////
    //                   LAW DEPLOYMENT                         //
    //////////////////////////////////////////////////////////////
    function deployLaw(bytes memory creationCode, bytes memory constructorArgs) public returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(constructorArgs));
        address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.

        address computedAddress = Create2.computeAddress(
            salt,
            keccak256(abi.encodePacked(creationCode, constructorArgs)),
            create2Factory // create2 factory address. NEED TO INCLUDE THIS!
        );

        if (computedAddress.code.length == 0) {
            vm.startBroadcast();
            address lawAddress = Create2.deploy(0, salt, abi.encodePacked(creationCode, constructorArgs));
            vm.stopBroadcast();
            // console2.log(string.concat(name, " deployed at (new deployment): "), lawAddress);
            return lawAddress;
        } else {
            // console2.log(string.concat(name, " deployed at: "), computedAddress);
            return computedAddress;
        }
    }
}
