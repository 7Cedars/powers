// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// --- Forge/OpenZeppelin Imports ---
import { Script } from "forge-std/Script.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { console2 } from "forge-std/console2.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";

// --- Library Imports ---
import { Checks } from "../src/libraries/Checks.sol";
import { MandateUtilities } from "../src/libraries/MandateUtilities.sol";

// --- Mandate Contract Imports ---
// Executive mandates
import { PresetSingleAction } from "../src/mandates/executive/PresetSingleAction.sol";
import { PresetMultipleActions } from "../src/mandates/executive/PresetMultipleActions.sol";
import { OpenAction } from "../src/mandates/executive/OpenAction.sol";
import { StatementOfIntent } from "../src/mandates/executive/StatementOfIntent.sol";
import { BespokeActionAdvanced } from "../src/mandates/executive/BespokeActionAdvanced.sol";
import { BespokeActionSimple } from "../src/mandates/executive/BespokeActionSimple.sol";
import { AdoptMandates } from "../src/mandates/executive/AdoptMandates.sol";
import { RevokeMandates } from "../src/mandates/executive/RevokeMandates.sol";
import { CheckExternalActionState } from "../src/mandates/executive/CheckExternalActionState.sol";

// Electoral mandates
import { OpenElectionStart } from "../src/mandates/electoral/OpenElectionStart.sol";
import { OpenElectionEnd } from "../src/mandates/electoral/OpenElectionEnd.sol";
import { OpenElectionVote } from "../src/mandates/electoral/OpenElectionVote.sol";
import { PeerSelect } from "../src/mandates/electoral/PeerSelect.sol";
import { NStrikesRevokesRoles } from "../src/mandates/electoral/NStrikesRevokesRoles.sol";
import { TaxSelect } from "../src/mandates/electoral/TaxSelect.sol";
import { RoleByRoles } from "../src/mandates/electoral/RoleByRoles.sol";
import { SelfSelect } from "../src/mandates/electoral/SelfSelect.sol";
import { RenounceRole } from "../src/mandates/electoral/RenounceRole.sol";
import { AssignExternalRole } from "../src/mandates/electoral/AssignExternalRole.sol";
import { RoleByTransaction } from "../src/mandates/electoral/RoleByTransaction.sol";
import { DelegateTokenSelect } from "../src/mandates/electoral/DelegateTokenSelect.sol";
import { Nominate } from "../src/mandates/electoral/Nominate.sol";


// async mandates
import { ClaimRoleWithGitSig } from "../src/mandates/async/ClaimRoleWithGitSig.sol";
import { AssignRoleWithGitSig } from "../src/mandates/async/AssignRoleWithGitSig.sol";

// Integration Mandates
import { TreasuryPoolGovernance } from "../src/mandates/integrations/TreasuryPoolGovernance.sol";
import { TreasuryRoleWithTransfer } from "../src/mandates/integrations/TreasuryRoleWithTransfer.sol";
import { TreasuryPoolTransfer } from "../src/mandates/integrations/TreasuryPoolTransfer.sol";
import { GovernorCreateProposal } from "../src/mandates/integrations/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../src/mandates/integrations/GovernorExecuteProposal.sol";
import { SafeExecTransaction } from "../src/mandates/integrations/SafeExecTransaction.sol";
import { SafeAllowanceAction } from "../src/mandates/integrations/SafeAllowanceAction.sol";
import { SafeSetup } from "../src/mandates/integrations/SafeSetup.sol";
import { SafeAllowanceTransfer } from "../src/mandates/integrations/SafeAllowanceTransfer.sol";

// mocks used
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";

/// @title InitialisePowers
/// @notice Deploys all library and mandate contracts deterministically using CREATE2
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

        address mandateUtilsAddr = deployLibrary(type(MandateUtilities).creationCode, "MandateUtilities");
        vm.serializeAddress(obj1, "MandateUtilities", mandateUtilsAddr);
        vm.stopBroadcast();

        string memory powersBytecode = generatePowersBytecode(checksAddr);
        vm.serializeString(obj1, "powers", powersBytecode);

        // vm.serializeUint(obj1, "chainId", uint256(block.chainid));
        helperConfig = new HelperConfig();
        config = helperConfig.getConfig();

        // vm.startBroadcast();
        (names, addresses, outputJson) = deployAndRecordMandates(config);
        // vm.stopBroadcast();

        string memory finalJson = vm.serializeString(obj1, "mandates", outputJson);

        outputFile = string.concat("powered/", vm.toString(block.chainid), ".json");
        vm.writeJson(finalJson, outputFile);
        console2.log("Success! All deployment data saved to:", outputFile);
    }

    /// @notice Uses vm.ffi() and the 'serialize' function to add bytecode to the obj1 string.
    function generatePowersBytecode(address _checks) internal returns (string memory) {
        // Must return the modified string
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

    /// @notice Deploys all mandate contracts and uses 'serialize' to record their addresses.
    function deployAndRecordMandates(HelperConfig.NetworkConfig memory config_)
        internal
        returns (string[] memory names, address[] memory addresses, string memory outputJson)
    {
        names = new string[](35);
        addresses = new address[](35);
        bytes[] memory creationCodes = new bytes[](35);
        bytes[] memory constructorArgs = new bytes[](35);

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

        names[7] = "AdoptMandates";
        creationCodes[7] = type(AdoptMandates).creationCode;
        constructorArgs[7] = abi.encode("AdoptMandates");

        names[8] = "SafeExecTransaction";
        creationCodes[8] = type(SafeExecTransaction).creationCode;
        constructorArgs[8] = abi.encode("SafeExecTransaction");

        names[9] = "GovernorCreateProposal";
        creationCodes[9] = type(GovernorCreateProposal).creationCode;
        constructorArgs[9] = abi.encode("GovernorCreateProposal");

        names[10] = "GovernorExecuteProposal";
        creationCodes[10] = type(GovernorExecuteProposal).creationCode;
        constructorArgs[10] = abi.encode("GovernorExecuteProposal");

        // Electoral mandates
        names[11] = "OpenElectionEnd";
        creationCodes[11] = type(OpenElectionEnd).creationCode;
        constructorArgs[11] = abi.encode("OpenElectionEnd");

        names[12] = "PeerSelect";
        creationCodes[12] = type(PeerSelect).creationCode;
        constructorArgs[12] = abi.encode("PeerSelect");

        names[13] = "OpenElectionVote";
        creationCodes[13] = type(OpenElectionVote).creationCode;
        constructorArgs[13] = abi.encode("OpenElectionVote");

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

        names[20] = "SafeAllowanceAction";
        creationCodes[20] = type(SafeAllowanceAction).creationCode;
        constructorArgs[20] = abi.encode("SafeAllowanceAction");

        names[21] = "RoleByTransaction";
        creationCodes[21] = type(RoleByTransaction).creationCode;
        constructorArgs[21] = abi.encode("RoleByTransaction");

        names[22] = "SafeSetup";
        creationCodes[22] = type(SafeSetup).creationCode;
        constructorArgs[22] = abi.encode("SafeSetup");

        names[23] = "ClaimRoleWithGitSig";
        creationCodes[23] = type(ClaimRoleWithGitSig).creationCode;
        constructorArgs[23] = abi.encode(config_.chainlinkFunctionsRouter);

        names[24] = "Erc20Taxed";
        creationCodes[24] = type(Erc20Taxed).creationCode;
        constructorArgs[24] = abi.encode();

        names[25] = "RevokeMandates";
        creationCodes[25] = type(RevokeMandates).creationCode;
        constructorArgs[25] = abi.encode("RevokeMandates");

        names[26] = "AssignRoleWithGitSig";
        creationCodes[26] = type(AssignRoleWithGitSig).creationCode;
        constructorArgs[26] = abi.encode();

        names[27] = "TreasuryPoolTransfer";
        creationCodes[27] = type(TreasuryPoolTransfer).creationCode;
        constructorArgs[27] = abi.encode();

        names[28] = "TreasuryPoolGovernance";
        creationCodes[28] = type(TreasuryPoolGovernance).creationCode;
        constructorArgs[28] = abi.encode();

        names[29] = "AssignExternalRole";
        creationCodes[29] = type(AssignExternalRole).creationCode;
        constructorArgs[29] = abi.encode("AssignExternalRole");

        names[30] = "SafeAllowanceTransfer";
        creationCodes[30] = type(SafeAllowanceTransfer).creationCode;
        constructorArgs[30] = abi.encode("SafeAllowanceTransfer");

        names[31] = "CheckExternalActionState";
        creationCodes[31] = type(CheckExternalActionState).creationCode;
        constructorArgs[31] = abi.encode("CheckExternalActionState");

        names[32] = "DelegateTokenSelect";
        creationCodes[32] = type(DelegateTokenSelect).creationCode;
        constructorArgs[32] = abi.encode("DelegateTokenSelect");

        names[33] = "Nominate";
        creationCodes[33] = type(Nominate).creationCode;
        constructorArgs[33] = abi.encode("Nominate");

        names[34] = "OpenElectionStart";
        creationCodes[34] = type(OpenElectionStart).creationCode;
        constructorArgs[34] = abi.encode("OpenElectionStart");

        string memory obj2 = "second key";

        for (uint256 i = 0; i < names.length; i++) {
            address mandateAddr = deployMandate(creationCodes[i], constructorArgs[i]);
            addresses[i] = mandateAddr;
            vm.serializeAddress(obj2, names[i], mandateAddr);
        }

        outputJson = vm.serializeUint(obj2, "chainId", uint256(block.chainid));

        return (names, addresses, outputJson);
    }

    /// @dev Deploys a mandate using CREATE2. Salt is derived from constructor arguments.
    function deployMandate(bytes memory creationCode, bytes memory constructorArgs) internal returns (address) {
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

    // @dev wrapper function to expose deployAndRecordMandates externally and only return addresses and names of mandates.
    function getDeployedMandates() external returns (string[] memory names, address[] memory addresses) {
        helperConfig = new HelperConfig();
        config = helperConfig.getConfig();
        (names, addresses,) = deployAndRecordMandates(config);
    }
}
