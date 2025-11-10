// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// --- Forge/OpenZeppelin Imports ---
import { Script } from "forge-std/Script.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { console2 } from "forge-std/console2.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";

// --- Library Imports ---
import { Checks } from "../src/libraries/Checks.sol";
import { LawUtilities } from "../src/libraries/LawUtilities.sol";

// --- Law Contract Imports ---
// Executive laws
import { PresetSingleAction } from "../src/laws/executive/PresetSingleAction.sol";
import { PresetMultipleActions } from "../src/laws/executive/PresetMultipleActions.sol";
import { OpenAction } from "../src/laws/executive/OpenAction.sol";
import { StatementOfIntent } from "../src/laws/executive/StatementOfIntent.sol";
import { BespokeActionAdvanced } from "../src/laws/executive/BespokeActionAdvanced.sol";
import { BespokeActionSimple } from "../src/laws/executive/BespokeActionSimple.sol";
import { AdoptLaws } from "../src/laws/executive/AdoptLaws.sol";
import { RevokeLaws } from "../src/laws/executive/RevokeLaws.sol";
import { AdoptLawsPackage } from "../src/laws/executive/AdoptLawsPackage.sol";

// Electoral laws
import { ElectionSelect } from "../src/laws/electoral/ElectionSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { VoteInOpenElection } from "../src/laws/electoral/VoteInOpenElection.sol";
import { NStrikesRevokesRoles } from "../src/laws/electoral/NStrikesRevokesRoles.sol";
import { TaxSelect } from "../src/laws/electoral/TaxSelect.sol";
import { RoleByRoles } from "../src/laws/electoral/RoleByRoles.sol";
import { SelfSelect } from "../src/laws/electoral/SelfSelect.sol";
import { RenounceRole } from "../src/laws/electoral/RenounceRole.sol";

// async laws
import { ClaimRoleWithGitSig } from "../src/laws/async/ClaimRoleWithGitSig.sol";
import { AssignRoleWithGitSig } from "../src/laws/async/AssignRoleWithGitSig.sol";

// Integration Laws 
import { AlloCreateRPGFPool } from "../src/laws/integrations/AlloCreateRPGFPool.sol";
import { AlloDistribute } from "../src/laws/integrations/AlloDistribute.sol";
import { AlloRPFGGovernance } from "../src/laws/integrations/AlloRPFGGovernance.sol";
import { TreasuryPoolGovernance } from "../src/laws/integrations/TreasuryPoolGovernance.sol";
import { TreasuryRoleWithTransfer } from "../src/laws/integrations/TreasuryRoleWithTransfer.sol";
import { TreasuryPoolTransfer } from "../src/laws/integrations/TreasuryPoolTransfer.sol";
import { GovernorCreateProposal } from "../src/laws/integrations/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../src/laws/integrations/GovernorExecuteProposal.sol";

// mocks used 
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";

/// @title InitialisePowers
/// @notice Deploys all library and law contracts deterministically using CREATE2
/// and saves their names and addresses to a obj1 file.
contract InitialisePowers is Script { 
    string outputFile;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig public config;

    function run() external returns (string[] memory names, address[] memory addresses) {
        string memory obj1 = "some key"; 
        string memory outputJson;

        vm.startBroadcast();
        address checksAddr = deployLibrary(type(Checks).creationCode, "Checks");
        vm.serializeAddress(obj1, "Checks", checksAddr);

        address lawUtilsAddr = deployLibrary(type(LawUtilities).creationCode, "LawUtilities");
        vm.serializeAddress(obj1, "LawUtilities", lawUtilsAddr);
        vm.stopBroadcast();
        
        string memory powersBytecode = generatePowersBytecode(checksAddr);
        vm.serializeString(obj1, "powers", powersBytecode);

        // vm.serializeUint(obj1, "chainId", uint256(block.chainid));
        helperConfig = new HelperConfig();
        config = helperConfig.getConfig();

        // vm.startBroadcast();
        (names, addresses, outputJson) = deployAndRecordLaws(config);
        // vm.stopBroadcast();

        string memory finalJson = vm.serializeString(obj1, "laws", outputJson);        

        outputFile = string.concat("powered/", vm.toString(block.chainid), ".json");
        vm.writeJson(finalJson, outputFile);
        console2.log("Success! All deployment data saved to:", outputFile);
 
    }

    /// @notice Uses vm.ffi() and the 'serialize' function to add bytecode to the obj1 string.
    function generatePowersBytecode(
        address _checks
    ) internal returns (string memory) { // Must return the modified string
        string[] memory inputs = new string[](5);
        inputs[0] = "forge";
        inputs[1] = "build";
        inputs[2] = "--libraries";
        inputs[3] = string.concat("src/libraries/Checks.sol:Checks:", vm.toString(_checks));
        inputs[4] = "--force";

        vm.ffi(inputs);

        string memory artifactJson = vm.readFile("out/Powers.sol/Powers.json");
        string memory deploymentBytecode = vm.parseJsonString(artifactJson, ".bytecode.object");

        return deploymentBytecode; // Return the new obj1 string
    }


    /// @notice Deploys all law contracts and uses 'serialize' to record their addresses.
    function deployAndRecordLaws(HelperConfig.NetworkConfig memory config_) internal returns (string[] memory names, address[] memory addresses, string memory outputJson) { 
        names = new string[](29);   
        addresses = new address[](29);
        bytes[] memory creationCodes = new bytes[](29);
        bytes[] memory constructorArgs = new bytes[](29);
        
        names[0] = "DUMMY LAW";
        creationCodes[0] = type(PresetSingleAction).creationCode;
        constructorArgs[0] = abi.encode();
        
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

        // Executive laws
        names[7] = "AdoptLaws";
        creationCodes[7] = type(AdoptLaws).creationCode;
        constructorArgs[7] = abi.encode("AdoptLaws");

        names[8] = "AdoptLawsPackage";
        creationCodes[8] = type(AdoptLawsPackage).creationCode;
        constructorArgs[8] = abi.encode("AdoptLawsPackage");

        names[9] = "GovernorCreateProposal";
        creationCodes[9] = type(GovernorCreateProposal).creationCode; 
        constructorArgs[9] = abi.encode("GovernorCreateProposal");

        names[10] = "GovernorExecuteProposal";
        creationCodes[10] = type(GovernorExecuteProposal).creationCode; 
        constructorArgs[10] = abi.encode("GovernorExecuteProposal");

        // Electoral laws
        names[11] = "ElectionSelect";
        creationCodes[11] = type(ElectionSelect).creationCode; 
        constructorArgs[11] = abi.encode("ElectionSelect");

        names[12] = "PeerSelect";
        creationCodes[12] = type(PeerSelect).creationCode; 
        constructorArgs[12] = abi.encode("PeerSelect");

        names[13] = "VoteInOpenElection";
        creationCodes[13] = type(VoteInOpenElection).creationCode; 
        constructorArgs[13] = abi.encode("VoteInOpenElection");

        names[14] = "NStrikesRevokesRoles";
        creationCodes[14] = type(NStrikesRevokesRoles).creationCode; 
        constructorArgs[14] = abi.encode("NStrikesRevokesRoles");

        names[15] = "TaxSelect";
        creationCodes[15] = type(TaxSelect).creationCode; 
        constructorArgs[15] = abi.encode("TaxSelect");

        names[16] = "TreasuryRoleWithTransfer";
        creationCodes[16] = type(TreasuryRoleWithTransfer).creationCode; 
        constructorArgs[16] = abi.encode("TreasuryRoleWithTransfer");

        names[17] = "RoleByRoles";
        creationCodes[17] = type(RoleByRoles).creationCode;
        constructorArgs[17] = abi.encode("RoleByRoles");

        names[18] = "SelfSelect";
        creationCodes[18] = type(SelfSelect).creationCode; 
        constructorArgs[18] = abi.encode("SelfSelect");

        names[19] = "RenounceRole";
        creationCodes[19] = type(RenounceRole).creationCode;
        constructorArgs[19] = abi.encode("RenounceRole");

        // Integration laws
        names[20] = "AlloCreateRPGFPool";
        creationCodes[20] = type(AlloCreateRPGFPool).creationCode;
        constructorArgs[20] = abi.encode("AlloCreateRPGFPool");

        names[21] = "AlloDistribute";
        creationCodes[21] = type(AlloDistribute).creationCode;
        constructorArgs[21] = abi.encode("AlloDistribute");
        
        names[22] = "AlloRPFGGovernance";
        creationCodes[22] = type(AlloRPFGGovernance).creationCode;
        constructorArgs[22] = abi.encode("AlloRPFGGovernance");

        // Async laws
        names[23] = "ClaimRoleWithGitSig";
        creationCodes[23] = type(ClaimRoleWithGitSig).creationCode;
        constructorArgs[23] = abi.encode(config_.chainlinkFunctionsRouter);

        names[24] = "Erc20Taxed";
        creationCodes[24] = type(Erc20Taxed).creationCode;
        constructorArgs[24] = abi.encode();

        names[25] = "RevokeLaws";
        creationCodes[25] = type(RevokeLaws).creationCode;
        constructorArgs[25] = abi.encode("RevokeLaws");

        names[26] = "AssignRoleWithGitSig";
        creationCodes[26] = type(AssignRoleWithGitSig).creationCode;
        constructorArgs[26] = abi.encode();

        names[27] = "TreasuryPoolTransfer";
        creationCodes[27] = type(TreasuryPoolTransfer).creationCode;
        constructorArgs[27] = abi.encode();

        names[28] = "TreasuryPoolGovernance";
        creationCodes[28] = type(TreasuryPoolGovernance).creationCode;
        constructorArgs[28] = abi.encode();

        string memory obj2 = "second key";

        for (uint256 i = 0; i < names.length; i++) {
            address lawAddr = deployLaw(creationCodes[i], constructorArgs[i]);
            addresses[i] = lawAddr;
            vm.serializeAddress(obj2, names[i], lawAddr);
        }

        outputJson = vm.serializeUint(obj2, "chainId", uint256(block.chainid));

        return (names, addresses, outputJson);
    }

    /// @dev Deploys a law using CREATE2. Salt is derived from constructor arguments.
    function deployLaw(bytes memory creationCode, bytes memory constructorArgs) internal returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(constructorArgs));
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

    /// @dev Deploys a library using CREATE2. Salt is derived from the library name.
    function deployLibrary(bytes memory creationCode, string memory name) internal returns (address) { 
        bytes32 salt = bytes32(abi.encodePacked(name));
        address computedAddress = Create2.computeAddress(salt, keccak256(creationCode), CREATE2_FACTORY);

        if (computedAddress.code.length == 0) { 
            address deployedAddress = Create2.deploy(0, salt, creationCode); 
            // require(deployedAddress == computedAddress, "Error: Deployed address mismatch.");
            return deployedAddress;
        }
        return computedAddress; 
    }

    // @dev wrapper function to expose deployAndRecordLaws externally and only return addresses and names of laws. 
    function getDeployedLaws() external returns (string[] memory names, address[] memory addresses) {
        helperConfig = new HelperConfig();
        config = helperConfig.getConfig();
        (names, addresses, ) = deployAndRecordLaws(config);
    }
}