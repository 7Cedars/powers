// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

// import { console2 } from "forge-std/console2.sol"; // only for testing purposes. 

// helper Config
import { HelperConfig } from "./HelperConfig.s.sol";

// laws to be deployed 
import { PresetSingleAction } from "../src/laws/multi/PresetSingleAction.sol";
import { PresetMultipleActions } from "../src/laws/multi/PresetMultipleActions.sol";
import { OpenAction } from "../src/laws/multi/OpenAction.sol";
import { StatementOfIntent } from "../src/laws/multi/StatementOfIntent.sol";
import { BespokeActionAdvanced } from "../src/laws/multi/BespokeActionAdvanced.sol";
import { BespokeActionSimple } from "../src/laws/multi/BespokeActionSimple.sol";
import { AdoptLaws } from "../src/laws/executive/AdoptLaws.sol";
import { ElectionSelect } from "../src/laws/electoral/ElectionSelect.sol";

contract DeployLaws is Script {
    HelperConfig public helperConfig;
    address public router;

    function run() external returns (string[] memory names, address[] memory addresses) {
        helperConfig = new HelperConfig();
        router = helperConfig.getConfig().chainlinkFunctionsRouter;
        // console2.log("router1", router);

        names = new string[](8);
        addresses = new address[](8);
        bytes[] memory creationCodes = new bytes[](8);
        bytes[] memory constructorArgs = new bytes[](8);

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

        names[6] = "AdoptLaws";
        creationCodes[6] = type(AdoptLaws).creationCode;
        constructorArgs[6] = abi.encode("AdoptLaws");

        names[7] = "ElectionSelect";
        creationCodes[7] = type(ElectionSelect).creationCode;
        constructorArgs[7] = abi.encode("ElectionSelect");

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
