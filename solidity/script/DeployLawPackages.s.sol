// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// core protocol
import { Powers } from "../src/Powers.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

import { InitialisePowers } from "./InitialisePowers.s.sol";
import { LawPackage } from "../src/law-packages/LawPackage.sol";
import { PowerLabsConfig } from "../src/law-packages/PowerLabsConfig.sol";
import { PowerLabs_Documentation } from "../src/law-packages/PowersLabs_Documentation.sol";
import { PowerLabs_Frontend } from "../src/law-packages/PowersLabs_Frontend.sol";
import { PowerLabs_Protocol } from "../src/law-packages/PowersLabs_Protocol.sol"; 

// @dev this script deploys custom law packages to the chain.
contract DeployLawPackages is Script {
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.
    bytes32 salt = bytes32(abi.encodePacked("LawPackageDeploymentSaltV1"));
    InitialisePowers initialisePowers;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig public config;
    Powers powers;
    string[] public lawNames;
    address[] public lawAddresses;

    // PowerLabsConfig 
    function run() external returns (string[] memory packageNames, address[] memory packageAddresses) {
        initialisePowers = new InitialisePowers();
        (lawNames, lawAddresses) = initialisePowers.run();
        helperConfig = new HelperConfig();
        config = helperConfig.getConfig();
        
        (packageNames, packageAddresses) = deployPackages();
    }

    /// @notice Deploys all law contracts and uses 'serialize' to record their addresses.
    function deployPackages() internal returns (string[] memory names, address[] memory addresses) { 
        names = new string[](4);   
        addresses = new address[](4);
        bytes[] memory creationCodes = new bytes[](4);
        bytes[] memory constructorArgs = new bytes[](4);
        
        // PowerLabsConfig
        address[] memory lawDependencies = new address[](5);
        lawDependencies[0] = findLawAddress("StatementOfIntent");
        lawDependencies[1] = findLawAddress("SafeExecTransaction");
        lawDependencies[2] = findLawAddress("PresetSingleAction");
        lawDependencies[3] = findLawAddress("SafeAllowanceAction");
        lawDependencies[4] = findLawAddress("RoleByTransaction");
        
        names[0] = "PowerLabs_Config";
        creationCodes[0] = type(PowerLabsConfig).creationCode;
        constructorArgs[0] = abi.encode(
            config.blocksPerHour, 
            lawDependencies, // empty array for now, will be set through a reform later.
            config.SafeAllowanceModule // zero address for allowance module, will be set through a reform later.
        );
        
        // PowerLabs_Documentation // no dependencies for now
        lawDependencies = new address[](1);
        lawDependencies[0] = findLawAddress("StatementOfIntent");
        names[1] = "PowerLabs_Documentation";
        creationCodes[1] = type(PowerLabs_Documentation).creationCode;  
        constructorArgs[1] = abi.encode(
            config.blocksPerHour, 
            lawDependencies, // empty array for now, will be set through a reform later.
            config.SafeAllowanceModule // zero address for allowance module, will be set through a reform later.
        );


        // PowerLabs_Frontend 
        names[2] = "PowerLabs_Frontend";
        creationCodes[2] = type(PowerLabs_Frontend).creationCode; 
        constructorArgs[2] = abi.encode(
            config.blocksPerHour, 
            lawDependencies, // empty array for now, will be set through a reform later.
            config.SafeAllowanceModule // zero address for allowance module, will be set through a reform later.
        );
        
        // PowerLabs_Protocol 
        names[3] = "PowerLabs_Protocol";
        creationCodes[3] = type(PowerLabs_Protocol).creationCode; 
        constructorArgs[3] = abi.encode(
            config.blocksPerHour, 
            lawDependencies, // empty array for now, will be set through a reform later.
            config.SafeAllowanceModule // zero address for allowance module, will be set through a reform later.
        );

        for (uint256 i = 0; i < names.length; i++) {
            address lawAddr = deployLawPackage(creationCodes[i], constructorArgs[i]);
            addresses[i] = lawAddr; 
        } 

        return (names, addresses);
    }

    /// @dev Deploys a law using CREATE2. Salt is derived from constructor arguments.
    function deployLawPackage(bytes memory creationCode, bytes memory constructorArgs) internal returns (address) {
        bytes memory deploymentData = abi.encodePacked(creationCode, constructorArgs);
        address computedAddress = Create2.computeAddress(salt, keccak256(deploymentData), CREATE2_FACTORY); 

        if (computedAddress.code.length == 0) { 
            vm.startBroadcast(); 
            address deployedAddress = Create2.deploy(0, salt, deploymentData); 
            vm.stopBroadcast();
            // require(deployedAddress == computedAddress, "Error: Deployed address mismatch.");
            return deployedAddress;
        }
        return computedAddress; 
    }

    function findLawAddress(string memory name) internal view returns (address) {
        for (uint i = 0; i < lawNames.length; i++) {
            if (Strings.equal(lawNames[i], name)) {
                return lawAddresses[i];
            }
        }
        return address(0);
    }
}
