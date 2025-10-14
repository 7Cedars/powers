// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

// import { console2 } from "forge-std/console2.sol"; // only for testing purposes.

// helper Config
import { HelperConfig } from "./HelperConfig.s.sol";

// laws to be deployed
// Multi laws
import { PresetSingleAction } from "../src/laws/multi/PresetSingleAction.sol";
import { PresetMultipleActions } from "../src/laws/multi/PresetMultipleActions.sol";
import { OpenAction } from "../src/laws/multi/OpenAction.sol";
import { StatementOfIntent } from "../src/laws/multi/StatementOfIntent.sol";
import { BespokeActionAdvanced } from "../src/laws/multi/BespokeActionAdvanced.sol";
import { BespokeActionSimple } from "../src/laws/multi/BespokeActionSimple.sol";

// Executive laws
import { AdoptLaws } from "../src/laws/executive/AdoptLaws.sol";
import { GovernorCreateProposal } from "../src/laws/executive/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../src/laws/executive/GovernorExecuteProposal.sol";

// Electoral laws
import { ElectionSelect } from "../src/laws/electoral/ElectionSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { VoteInOpenElection } from "../src/laws/electoral/VoteInOpenElection.sol";
import { NStrikesRevokesRoles } from "../src/laws/electoral/NStrikesRevokesRoles.sol";
import { TaxSelect } from "../src/laws/electoral/TaxSelect.sol";
import { BuyAccess } from "../src/laws/electoral/BuyAccess.sol";
import { RoleByRoles } from "../src/laws/electoral/RoleByRoles.sol"; 
import { SelfSelect } from "../src/laws/electoral/SelfSelect.sol";
import { RenounceRole } from "../src/laws/electoral/RenounceRole.sol";

contract DeployLaws is Script {
    HelperConfig public helperConfig;
    address public router;

    function run() external returns (string[] memory names, address[] memory addresses) {
        helperConfig = new HelperConfig();
        router = helperConfig.getConfig().chainlinkFunctionsRouter;
        // console2.log("router1", router);

        names = new string[](19);
        addresses = new address[](19);
        bytes[] memory creationCodes = new bytes[](19);
        bytes[] memory constructorArgs = new bytes[](19);

        // dummy law to get index of aray to be the same as lawId. 
        names[0] = "PresetSingleAction";
        creationCodes[0] = type(PresetSingleAction).creationCode;
        constructorArgs[0] = abi.encode();

        // Multi laws (0-5)
        names[1] = "PresetSingleAction";
        creationCodes[1] = type(PresetSingleAction).creationCode;
        constructorArgs[1] = abi.encode("PresetSingleAction");

        names[2] = "PresetMultipleActions";
        creationCodes[2] = type(PresetMultipleActions).creationCode;
        constructorArgs[2] = abi.encode("PresetMultipleActions");

        names[3] = "OpenAction";
        creationCodes[3] = type(OpenAction).creationCode;
        constructorArgs[3] = abi.encode("OpenAction");

        names[4] = "StatementOfIntent";
        creationCodes[4] = type(StatementOfIntent).creationCode;
        constructorArgs[4] = abi.encode("StatementOfIntent");

        names[5] = "BespokeActionAdvanced";
        creationCodes[5] = type(BespokeActionAdvanced).creationCode;
        constructorArgs[5] = abi.encode("BespokeActionAdvanced");

        names[6] = "BespokeActionSimple";
        creationCodes[6] = type(BespokeActionSimple).creationCode;
        constructorArgs[6] = abi.encode("BespokeActionSimple");

        // Executive laws (6-8)
        names[7] = "AdoptLaws";
        creationCodes[7] = type(AdoptLaws).creationCode;
        constructorArgs[7] = abi.encode("AdoptLaws");

        names[8] = "GovernorCreateProposal";
        creationCodes[8] = type(GovernorCreateProposal).creationCode;
        constructorArgs[8] = abi.encode("GovernorCreateProposal");

        names[9] = "GovernorExecuteProposal";
        creationCodes[9] = type(GovernorExecuteProposal).creationCode;
        constructorArgs[9] = abi.encode("GovernorExecuteProposal");

        // Electoral laws (9-18)
        names[10] = "ElectionSelect";
        creationCodes[10] = type(ElectionSelect).creationCode;
        constructorArgs[10] = abi.encode("ElectionSelect");

        names[11] = "PeerSelect";
        creationCodes[11] = type(PeerSelect).creationCode;
        constructorArgs[11] = abi.encode("PeerSelect");

        names[12] = "VoteInOpenElection";
        creationCodes[12] = type(VoteInOpenElection).creationCode;
        constructorArgs[12] = abi.encode("VoteInOpenElection");

        names[13] = "NStrikesRevokesRoles";
        creationCodes[13] = type(NStrikesRevokesRoles).creationCode;
        constructorArgs[13] = abi.encode("NStrikesRevokesRoles");

        names[14] = "TaxSelect";
        creationCodes[14] = type(TaxSelect).creationCode;
        constructorArgs[14] = abi.encode("TaxSelect");

        names[15] = "BuyAccess";
        creationCodes[15] = type(BuyAccess).creationCode;
        constructorArgs[15] = abi.encode("BuyAccess");

        names[16] = "RoleByRoles";
        creationCodes[16] = type(RoleByRoles).creationCode;
        constructorArgs[16] = abi.encode("RoleByRoles");

        names[17] = "SelfSelect";
        creationCodes[17] = type(SelfSelect).creationCode;
        constructorArgs[17] = abi.encode("SelfSelect");

        names[18] = "RenounceRole";
        creationCodes[18] = type(RenounceRole).creationCode;
        constructorArgs[18] = abi.encode("RenounceRole");

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
