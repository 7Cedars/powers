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

        names = new string[](18);
        addresses = new address[](18);
        bytes[] memory creationCodes = new bytes[](18);
        bytes[] memory constructorArgs = new bytes[](18);

        // Multi laws (0-5)
        names[0] = "PresetSingleAction";
        creationCodes[0] = type(PresetSingleAction).creationCode;
        constructorArgs[0] = abi.encode("PresetSingleAction");

        names[1] = "PresetMultipleActions";
        creationCodes[1] = type(PresetMultipleActions).creationCode;
        constructorArgs[1] = abi.encode("PresetMultipleActions");

        names[2] = "OpenAction";
        creationCodes[2] = type(OpenAction).creationCode;
        constructorArgs[2] = abi.encode("OpenAction");

        names[3] = "StatementOfIntent";
        creationCodes[3] = type(StatementOfIntent).creationCode;
        constructorArgs[3] = abi.encode("StatementOfIntent");

        names[4] = "BespokeActionAdvanced";
        creationCodes[4] = type(BespokeActionAdvanced).creationCode;
        constructorArgs[4] = abi.encode("BespokeActionAdvanced");

        names[5] = "BespokeActionSimple";
        creationCodes[5] = type(BespokeActionSimple).creationCode;
        constructorArgs[5] = abi.encode("BespokeActionSimple");

        // Executive laws (6-8)
        names[6] = "AdoptLaws";
        creationCodes[6] = type(AdoptLaws).creationCode;
        constructorArgs[6] = abi.encode("AdoptLaws");

        names[7] = "GovernorCreateProposal";
        creationCodes[7] = type(GovernorCreateProposal).creationCode;
        constructorArgs[7] = abi.encode("GovernorCreateProposal");

        names[8] = "GovernorExecuteProposal";
        creationCodes[8] = type(GovernorExecuteProposal).creationCode;
        constructorArgs[8] = abi.encode("GovernorExecuteProposal");

        // Electoral laws (9-18)
        names[9] = "ElectionSelect";
        creationCodes[9] = type(ElectionSelect).creationCode;
        constructorArgs[9] = abi.encode("ElectionSelect");

        names[10] = "PeerSelect";
        creationCodes[10] = type(PeerSelect).creationCode;
        constructorArgs[10] = abi.encode("PeerSelect");

        names[11] = "VoteInOpenElection";
        creationCodes[11] = type(VoteInOpenElection).creationCode;
        constructorArgs[11] = abi.encode("VoteInOpenElection");

        names[12] = "NStrikesRevokesRoles";
        creationCodes[12] = type(NStrikesRevokesRoles).creationCode;
        constructorArgs[12] = abi.encode("NStrikesRevokesRoles");

        names[13] = "TaxSelect";
        creationCodes[13] = type(TaxSelect).creationCode;
        constructorArgs[13] = abi.encode("TaxSelect");

        names[14] = "BuyAccess";
        creationCodes[14] = type(BuyAccess).creationCode;
        constructorArgs[14] = abi.encode("BuyAccess");

        names[15] = "RoleByRoles";
        creationCodes[15] = type(RoleByRoles).creationCode;
        constructorArgs[15] = abi.encode("RoleByRoles");

        names[16] = "SelfSelect";
        creationCodes[16] = type(SelfSelect).creationCode;
        constructorArgs[16] = abi.encode("SelfSelect");

        names[17] = "RenounceRole";
        creationCodes[17] = type(RenounceRole).creationCode;
        constructorArgs[17] = abi.encode("RenounceRole");

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
