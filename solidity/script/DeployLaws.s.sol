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
import { StartGrant } from "../src/laws/executive/StartGrant.sol";
import { EndGrant } from "../src/laws/executive/EndGrant.sol";
import { AdoptLaw } from "../src/laws/executive/AdoptLaw.sol";
import { DirectDeselect } from "../src/laws/electoral/DirectDeselect.sol";
import { Subscription } from "../src/laws/electoral/Subscription.sol";
import { VoteOnAccounts } from "../src/laws/state/VoteOnAccounts.sol";
import { StartElection } from "../src/laws/electoral/StartElection.sol";
import { EndElection } from "../src/laws/electoral/EndElection.sol";
import { GovernorCreateProposal } from "../src/laws/integrations/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../src/laws/integrations/GovernorExecuteProposal.sol";
import { SnapToGov_CheckSnapExists } from "../src/laws/integrations/SnapToGov_CheckSnapExists.sol";

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
        
        names = new string[](27);
        addresses = new address[](27);
        bytes[] memory creationCodes = new bytes[](27);
        bytes[] memory constructorArgs = new bytes[](27);

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

        names[16] = "StartGrant";
        creationCodes[16] = type(StartGrant).creationCode;
        constructorArgs[16] = abi.encode("StartGrant");

        names[17] = "EndGrant";
        creationCodes[17] = type(EndGrant).creationCode;
        constructorArgs[17] = abi.encode("EndGrant");

        names[18] = "AdoptLaw";
        creationCodes[18] = type(AdoptLaw).creationCode;
        constructorArgs[18] = abi.encode("AdoptLaw");

        names[19] = "VoteOnAccounts";
        creationCodes[19] = type(VoteOnAccounts).creationCode;
        constructorArgs[19] = abi.encode("VoteOnAccounts");

        names[20] = "DirectDeselect";
        creationCodes[20] = type(DirectDeselect).creationCode;
        constructorArgs[20] = abi.encode("DirectDeselect");

        names[21] = "Subscription";
        creationCodes[21] = type(Subscription).creationCode;
        constructorArgs[21] = abi.encode("Subscription");

        names[22] = "StartElection";
        creationCodes[22] = type(StartElection).creationCode;
        constructorArgs[22] = abi.encode("StartElection");

        names[23] = "EndElection";
        creationCodes[23] = type(EndElection).creationCode;
        constructorArgs[23] = abi.encode("EndElection");

        names[24] = "GovernorCreateProposal";
        creationCodes[24] = type(GovernorCreateProposal).creationCode;
        constructorArgs[24] = abi.encode("GovernorCreateProposal");

        names[25] = "GovernorExecuteProposal";
        creationCodes[25] = type(GovernorExecuteProposal).creationCode;
        constructorArgs[25] = abi.encode("GovernorExecuteProposal");

        names[26] = "SnapToGov_CheckSnapExists";
        creationCodes[26] = type(SnapToGov_CheckSnapExists).creationCode;
        constructorArgs[26] = abi.encode(router);

        // console2.log("router2", router);

        for (uint256 i = 0; i < creationCodes.length; i++) {
        //    console2.log("router", router);
           addresses[i] = deployLaw(creationCodes[i], constructorArgs[i], names[i]);
        }
    }


    //////////////////////////////////////////////////////////////
    //                   LAW DEPLOYMENT                         //
    //////////////////////////////////////////////////////////////
    function deployLaw(bytes memory creationCode, bytes memory constructorArgs, string memory name) public returns (address) {
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
