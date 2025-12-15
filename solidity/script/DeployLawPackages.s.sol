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
import { MandatePackage } from "../src/mandate-packages/MandatePackage.sol";
import { PowerLabsConfig } from "../src/mandate-packages/PowerLabsConfig.sol";
import { PowerLabs_Documentation } from "../src/mandate-packages/PowersLabs_Documentation.sol";
import { PowerLabs_Frontend } from "../src/mandate-packages/PowersLabs_Frontend.sol";
import { PowerLabs_Protocol } from "../src/mandate-packages/PowersLabs_Protocol.sol";

// @dev this script deploys custom mandate packages to the chain.
contract DeployMandatePackages is Script {
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.
    bytes32 salt = bytes32(abi.encodePacked("MandatePackageDeploymentSaltV1"));
    InitialisePowers initialisePowers;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig public config;
    Powers powers;
    string[] public mandateNames;
    address[] public mandateAddresses;

    // PowerLabsConfig
    function run() external returns (string[] memory packageNames, address[] memory packageAddresses) {
        initialisePowers = new InitialisePowers();
        (mandateNames, mandateAddresses) = initialisePowers.run();
        helperConfig = new HelperConfig();
        config = helperConfig.getConfig();

        (packageNames, packageAddresses) = deployPackages();
    }

    /// @notice Deploys all mandate contracts and uses 'serialize' to record their addresses.
    function deployPackages() internal returns (string[] memory names, address[] memory addresses) {
        names = new string[](4);
        addresses = new address[](4);
        bytes[] memory creationCodes = new bytes[](4);
        bytes[] memory constructorArgs = new bytes[](4);

        // PowerLabsConfig
        address[] memory mandateDependencies = new address[](5);
        mandateDependencies[0] = findMandateAddress("StatementOfIntent");
        mandateDependencies[1] = findMandateAddress("SafeExecTransaction");
        mandateDependencies[2] = findMandateAddress("PresetSingleAction");
        mandateDependencies[3] = findMandateAddress("SafeAllowanceAction");
        mandateDependencies[4] = findMandateAddress("RoleByTransaction");

        names[0] = "PowerLabs_Config";
        creationCodes[0] = type(PowerLabsConfig).creationCode;
        constructorArgs[0] = abi.encode(
            config.BLOCKS_PER_HOUR,
            mandateDependencies, // empty array for now, will be set through a reform later.
            config.SafeAllowanceModule // zero address for allowance module, will be set through a reform later.
        );

        // PowerLabs_Documentation // no dependencies for now
        mandateDependencies = new address[](1);
        mandateDependencies[0] = findMandateAddress("StatementOfIntent");
        names[1] = "PowerLabs_Documentation";
        creationCodes[1] = type(PowerLabs_Documentation).creationCode;
        constructorArgs[1] = abi.encode(
            config.BLOCKS_PER_HOUR,
            mandateDependencies, // empty array for now, will be set through a reform later.
            config.SafeAllowanceModule // zero address for allowance module, will be set through a reform later.
        );

        // PowerLabs_Frontend
        names[2] = "PowerLabs_Frontend";
        creationCodes[2] = type(PowerLabs_Frontend).creationCode;
        constructorArgs[2] = abi.encode(
            config.BLOCKS_PER_HOUR,
            mandateDependencies, // empty array for now, will be set through a reform later.
            config.SafeAllowanceModule // zero address for allowance module, will be set through a reform later.
        );

        // PowerLabs_Protocol
        names[3] = "PowerLabs_Protocol";
        creationCodes[3] = type(PowerLabs_Protocol).creationCode;
        constructorArgs[3] = abi.encode(
            config.BLOCKS_PER_HOUR,
            mandateDependencies, // empty array for now, will be set through a reform later.
            config.SafeAllowanceModule // zero address for allowance module, will be set through a reform later.
        );

        for (uint256 i = 0; i < names.length; i++) {
            address mandateAddr = deployMandatePackage(creationCodes[i], constructorArgs[i]);
            addresses[i] = mandateAddr;
        }

        return (names, addresses);
    }

    /// @dev Deploys a mandate using CREATE2. Salt is derived from constructor arguments.
    function deployMandatePackage(bytes memory creationCode, bytes memory constructorArgs) internal returns (address) {
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

    function findMandateAddress(string memory name) internal view returns (address) {
        for (uint256 i = 0; i < mandateNames.length; i++) {
            if (Strings.equal(mandateNames[i], name)) {
                return mandateAddresses[i];
            }
        }
        return address(0);
    }
}
