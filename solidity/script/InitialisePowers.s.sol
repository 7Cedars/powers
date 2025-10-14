// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// --- Forge/OpenZeppelin Imports ---
import { Script } from "forge-std/Script.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { console2 } from "forge-std/console2.sol";
import { stdJson } from "forge-std/StdJson.sol"; // Your file is correct

// --- Library Imports ---
import { Checks } from "../src/libraries/Checks.sol";
import { LawUtilities } from "../src/libraries/LawUtilities.sol";

// --- Core Protocol Import ---
import { Powers } from "../src/Powers.sol";

// --- Law Contract Imports ---
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

/// @title InitialisePowers
/// @notice Deploys all library and law contracts deterministically using CREATE2
/// and saves their names and addresses to a obj1 file.
contract InitialisePowers is Script { 
    string outputFile;

    function run() external {
        string memory obj1 = "some key"; 

        vm.startBroadcast();
        deployAndRecordLaws(obj1);
        vm.stopBroadcast();
 
        vm.startBroadcast();
        address checksAddr = deployLibrary(type(Checks).creationCode, "Checks");
        vm.serializeAddress(obj1, "Checks", checksAddr);

        address lawUtilsAddr = deployLibrary(type(LawUtilities).creationCode, "LawUtilities");
        vm.serializeAddress(obj1, "LawUtilities", lawUtilsAddr);
        vm.stopBroadcast();
        
        vm.serializeUint(obj1, "chainId", uint256(block.chainid));
        
        string memory output = generateAndRecordPowersBytecode(checksAddr);
        string memory finalJson = vm.serializeString(obj1, "powers", output);        

        outputFile = string.concat("powered/", vm.toString(block.chainid), ".json");
        vm.writeJson(finalJson, outputFile);
        console2.log("Success! All deployment data saved to:", outputFile);

    }

    /// @notice Uses vm.ffi() and the 'serialize' function to add bytecode to the obj1 string.
    function generateAndRecordPowersBytecode(
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

        // Serialize the bytecode into the obj1 object
        string memory obj2 = "second key";
        string memory modifiedJson = vm.serializeString(obj2, "bytecode", deploymentBytecode);
        console2.log("Linked bytecode for Powers contract added to obj1 output.");
        
        return modifiedJson; // Return the new obj1 string
    }


    /// @notice Deploys all law contracts and uses 'serialize' to record their addresses.
    function deployAndRecordLaws(string memory obj1) internal { 
        string[] memory names = new string[](19);
        bytes[] memory creationCodes = new bytes[](19);
        bytes[] memory constructorArgs = new bytes[](19);
        
        names[0] = "PresetSingleAction";
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

        names[8] = "GovernorCreateProposal";
        creationCodes[8] = type(GovernorCreateProposal).creationCode; 
        constructorArgs[8] = abi.encode("GovernorCreateProposal");

        names[9] = "GovernorExecuteProposal";
        creationCodes[9] = type(GovernorExecuteProposal).creationCode; 
        constructorArgs[9] = abi.encode("GovernorExecuteProposal");

        // Electoral laws
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

      
        for (uint256 i = 0; i < names.length; i++) {
            address lawAddr = deployLaw(creationCodes[i], constructorArgs[i]);
            vm.serializeAddress(obj1, names[i], lawAddr);
        }
    }

    /// @dev Deploys a law using CREATE2. Salt is derived from constructor arguments.
    function deployLaw(bytes memory creationCode, bytes memory constructorArgs) internal returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(constructorArgs));
        bytes memory deploymentData = abi.encodePacked(creationCode, constructorArgs);
        address computedAddress = Create2.computeAddress(salt, keccak256(deploymentData), CREATE2_FACTORY); 

        if (computedAddress.code.length == 0) { 
            address deployedAddress = Create2.deploy(0, salt, deploymentData); 
            require(deployedAddress == computedAddress, "Error: Deployed address mismatch.");
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
            require(deployedAddress == computedAddress, "Error: Deployed address mismatch.");
            return deployedAddress;
        }
        return computedAddress; 
    }
}