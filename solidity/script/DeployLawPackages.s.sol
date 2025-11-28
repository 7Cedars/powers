// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
// core protocol
import { Powers } from "../src/Powers.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

import { InitialisePowers } from "./InitialisePowers.s.sol";
import { LawPackage } from "../src/laws/reform/LawPackage.sol";
import { PowerBaseSafeSetup } from "../src/laws/reform/PowerBaseSafeSetup.sol";

// @dev this script deploys custom law packages to the chain.
contract DeployLawPackages is Script {
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.
    bytes32 salt = bytes32(abi.encodePacked("LawPackageDeploymentSaltV1"));
    InitialisePowers initialisePowers;

    Powers powers;

    // PowerBaseSafeSetup 
    function run() external returns (address lawPackage) {
        initialisePowers = new InitialisePowers();

        (, address[] memory lawAddresses) = initialisePowers.run();
        // select the laws used in the package.
        address[] memory selectedAddresses = new address[](3);
        selectedAddresses[0] = lawAddresses[4]; // statementOfIntent
        selectedAddresses[1] = lawAddresses[8]; // SafeExecTransaction
        selectedAddresses[2] = lawAddresses[1]; // PresetSingleAction
 
        console2.log("Preparing deployment data with the following addresses:");
        console2.logAddress(selectedAddresses[0]);
        console2.logAddress(selectedAddresses[1]);
        console2.logAddress(selectedAddresses[2]);

        bytes memory deploymentData = abi.encodePacked(type(PowerBaseSafeSetup).creationCode, abi.encode(selectedAddresses));
        address computedAddress = Create2.computeAddress(salt, keccak256(deploymentData), create2Factory); 

        if (computedAddress.code.length == 0) { 
            vm.startBroadcast(); 
            address deployedAddress = Create2.deploy(0, salt, deploymentData); 
            vm.stopBroadcast(); 
            return deployedAddress;
        }
        return computedAddress; 
    }

    // LawPackage
    // function run() external returns (address lawPackage) {
    //     initialisePowers = new InitialisePowers();

    //     (, address[] memory lawAddresses) = initialisePowers.run();
    //     // select the laws used in the package.
    //     address[] memory selectedAddresses = new address[](2);
    //     selectedAddresses[0] = lawAddresses[3]; // openAction
    //     selectedAddresses[1] = lawAddresses[4]; // statementOfIntent
 
    //     console2.log("Preparing deployment data...");
    //     bytes memory deploymentData = abi.encodePacked(type(LawPackage).creationCode, abi.encode(selectedAddresses));
    //     address computedAddress = Create2.computeAddress(salt, keccak256(deploymentData), create2Factory); 

    //     if (computedAddress.code.length == 0) { 
    //         vm.startBroadcast(); 
    //         address deployedAddress = Create2.deploy(0, salt, deploymentData); 
    //         vm.stopBroadcast(); 
    //         return deployedAddress;
    //     }
    //     return computedAddress; 
    // }
}
