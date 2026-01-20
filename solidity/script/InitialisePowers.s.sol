// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// --- Forge/OpenZeppelin Imports ---
import { Script } from "forge-std/Script.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@script/Configurations.s.sol"; 

// --- Library Imports ---
import { Checks } from "@src/libraries/Checks.sol";
import { MandateUtilities } from "@src/libraries/MandateUtilities.sol";

// --- Mandate Contract Imports ---
// async mandates
import { Github_ClaimRoleWithSig } from "@src/mandates/async/Github_ClaimRoleWithSig.sol";
import { Github_AssignRoleWithSig } from "@src/mandates/async/Github_AssignRoleWithSig.sol";

// Electoral mandates
import { OpenElection_Start } from "@src/mandates/electoral/OpenElection_Start.sol";
import { OpenElection_End } from "@src/mandates/electoral/OpenElection_End.sol";
import { OpenElection_Vote } from "@src/mandates/electoral/OpenElection_Vote.sol";
import { PeerSelect } from "@src/mandates/electoral/PeerSelect.sol";
import { NStrikesRevokesRoles } from "@src/mandates/electoral/NStrikesRevokesRoles.sol";
import { TaxSelect } from "@src/mandates/electoral/TaxSelect.sol";
import { RoleByRoles } from "@src/mandates/electoral/RoleByRoles.sol";
import { SelfSelect } from "@src/mandates/electoral/SelfSelect.sol";
import { RenounceRole } from "@src/mandates/electoral/RenounceRole.sol";
import { AssignExternalRole } from "@src/mandates/electoral/AssignExternalRole.sol";
import { RoleByTransaction } from "@src/mandates/electoral/RoleByTransaction.sol";
import { DelegateTokenSelect } from "@src/mandates/electoral/DelegateTokenSelect.sol";
import { Nominate } from "@src/mandates/electoral/Nominate.sol";

// Executive mandates
import { PresetActions_Single } from "@src/mandates/executive/PresetActions_Single.sol";
import { PresetActions_Multiple } from "@src/mandates/executive/PresetActions_Multiple.sol";
import { OpenAction } from "@src/mandates/executive/OpenAction.sol";
import { StatementOfIntent } from "@src/mandates/executive/StatementOfIntent.sol";
import { Mandates_Adopt } from "@src/mandates/executive/Mandates_Adopt.sol";
import { Mandates_Revoke } from "@src/mandates/executive/Mandates_Revoke.sol";
import { CheckExternalActionState } from "@src/mandates/executive/CheckExternalActionState.sol";
import { BespokeAction_OnReturnValue } from "@src/mandates/executive/BespokeAction_OnReturnValue.sol";
import { BespokeAction_OnOwnPowers } from "@src/mandates/executive/BespokeAction_OnOwnPowers.sol";
import { BespokeAction_Advanced } from "@src/mandates/executive/BespokeAction_Advanced.sol";
import { BespokeAction_Simple } from "@src/mandates/executive/BespokeAction_Simple.sol";
import { PowersAction_Simple } from "@src/mandates/executive/PowersAction_Simple.sol";

// Integration Mandates
import { Governor_CreateProposal } from "@src/mandates/integrations/Governor_CreateProposal.sol";
import { Governor_ExecuteProposal } from "@src/mandates/integrations/Governor_ExecuteProposal.sol";
import { Safe_Setup } from "@src/mandates/integrations/Safe_Setup.sol";
import { Safe_ExecTransaction } from "@src/mandates/integrations/Safe_ExecTransaction.sol";
import { Safe_RecoverTokens } from "@src/mandates/integrations/Safe_RecoverTokens.sol";
import { SafeAllowance_Transfer } from "@src/mandates/integrations/SafeAllowance_Transfer.sol";
import { SafeAllowance_Action } from "@src/mandates/integrations/SafeAllowance_Action.sol"; 
import { PowersFactory_AssignRole } from "@src/mandates/integrations/PowersFactory_AssignRole.sol";
import { PowersFactory_AddSafeDelegate } from "@src/mandates/integrations/PowersFactory_AddSafeDelegate.sol";
import { Soulbound1155_GatedAccess } from "@src/mandates/integrations/Soulbound1155_GatedAccess.sol";
import { Soulbound1155_MintEncodedToken } from "@src/mandates/integrations/Soulbound1155_MintEncodedToken.sol";
import { Safe_ExecTransaction_OnReturnValue } from "@src/mandates/integrations/Safe_ExecTransaction_OnReturnValue.sol";

// mocks used
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";

/// @title InitialisePowers
/// @notice Deploys all library and mandate contracts deterministically using CREATE2
/// and saves their names and addresses to a obj1 file.
contract InitialisePowers is Script {
    string outputFile;
    Configurations helperConfig;
    Configurations.NetworkConfig public config;
    string[] names;
    address[] addresses;
    bytes[] creationCodes;
    bytes[] constructorArgs;

    function run() external {
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
        helperConfig = new Configurations();
        config = helperConfig.getConfig();

        // vm.startBroadcast();
        outputJson = deployAndRecordMandates(config);
        // vm.stopBroadcast();

        string memory finalJson = vm.serializeString(obj1, "mandates", outputJson);

        outputFile = string.concat("../frontend/public/powered/", vm.toString(block.chainid), ".json");
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
    function deployAndRecordMandates(Configurations.NetworkConfig memory config_)
        internal
        returns (string memory outputJson)
    {
        names.push("DUMMY LAW");
        creationCodes.push(type(PresetActions_Single).creationCode);
        constructorArgs.push(abi.encode());

        //////////////////////////////////////////////////////////////////////////
        //                         Async Mandates                               //
        //////////////////////////////////////////////////////////////////////////
        names.push("Github_ClaimRoleWithSig");
        creationCodes.push(type(Github_ClaimRoleWithSig).creationCode);
        constructorArgs.push(abi.encode(config_.chainlinkFunctionsRouter));

        names.push("Github_AssignRoleWithSig");
        creationCodes.push(type(Github_AssignRoleWithSig).creationCode);
        constructorArgs.push(abi.encode());

        //////////////////////////////////////////////////////////////////////////
        //                      Electoral Mandates                              //
        //////////////////////////////////////////////////////////////////////////
        names.push("OpenElection_End");
        creationCodes.push(type(OpenElection_End).creationCode);
        constructorArgs.push(abi.encode("OpenElection_End"));

         names.push("PeerSelect");
        creationCodes.push(type(PeerSelect).creationCode);
        constructorArgs.push(abi.encode("PeerSelect"));

        names.push("OpenElection_Vote");
        creationCodes.push(type(OpenElection_Vote).creationCode);
        constructorArgs.push(abi.encode("OpenElection_Vote"));

        names.push("NStrikesRevokesRoles");
        creationCodes.push(type(NStrikesRevokesRoles).creationCode);
        constructorArgs.push(abi.encode("NStrikesRevokesRoles"));

        names.push("TaxSelect");
        creationCodes.push(type(TaxSelect).creationCode);
        constructorArgs.push(abi.encode("TaxSelect"));

        names.push("RoleByRoles");
        creationCodes.push(type(RoleByRoles).creationCode);
        constructorArgs.push(abi.encode("RoleByRoles"));

        names.push("SelfSelect");
        creationCodes.push(type(SelfSelect).creationCode);
        constructorArgs.push(abi.encode("SelfSelect"));

        names.push("RenounceRole");
        creationCodes.push(type(RenounceRole).creationCode);
        constructorArgs.push(abi.encode("RenounceRole"));

        names.push("RoleByTransaction");
        creationCodes.push(type(RoleByTransaction).creationCode);
        constructorArgs.push(abi.encode("RoleByTransaction"));

        names.push("AssignExternalRole");
        creationCodes.push(type(AssignExternalRole).creationCode);
        constructorArgs.push(abi.encode("AssignExternalRole"));

        names.push("DelegateTokenSelect");
        creationCodes.push(type(DelegateTokenSelect).creationCode);
        constructorArgs.push(abi.encode("DelegateTokenSelect"));

        names.push("Nominate");
        creationCodes.push(type(Nominate).creationCode);
        constructorArgs.push(abi.encode("Nominate"));

        names.push("OpenElection_Start");
        creationCodes.push(type(OpenElection_Start).creationCode);
        constructorArgs.push(abi.encode("OpenElection_Start"));

        //////////////////////////////////////////////////////////////////////////
        //                       Executive Mandates                             //
        //////////////////////////////////////////////////////////////////////////
        names.push("PresetActions_Single");
        creationCodes.push(type(PresetActions_Single).creationCode);
        constructorArgs.push(abi.encode("PresetActions_Single"));

        names.push("PresetActions_Multiple");
        creationCodes.push(type(PresetActions_Multiple).creationCode);
        constructorArgs.push(abi.encode("PresetActions_Multiple"));

        names.push("OpenAction");
        creationCodes.push(type(OpenAction).creationCode);
        constructorArgs.push(abi.encode("OpenAction"));

        names.push("StatementOfIntent");
        creationCodes.push(type(StatementOfIntent).creationCode);
        constructorArgs.push(abi.encode("StatementOfIntent"));

        names.push("BespokeAction_Advanced");
        creationCodes.push(type(BespokeAction_Advanced).creationCode);
        constructorArgs.push(abi.encode("BespokeAction_Advanced"));

        names.push("PowersAction_Simple");
        creationCodes.push(type(PowersAction_Simple).creationCode);
        constructorArgs.push(abi.encode("PowersAction_Simple"));

        names.push("BespokeAction_Simple");
        creationCodes.push(type(BespokeAction_Simple).creationCode);
        constructorArgs.push(abi.encode("BespokeAction_Simple"));

        names.push("Mandates_Adopt");
        creationCodes.push(type(Mandates_Adopt).creationCode);
        constructorArgs.push(abi.encode("Mandates_Adopt"));

        names.push("Mandates_Revoke");
        creationCodes.push(type(Mandates_Revoke).creationCode);
        constructorArgs.push(abi.encode("Mandates_Revoke"));

        names.push("CheckExternalActionState");
        creationCodes.push(type(CheckExternalActionState).creationCode);
        constructorArgs.push(abi.encode("CheckExternalActionState"));

        names.push("BespokeAction_OnReturnValue");
        creationCodes.push(type(BespokeAction_OnReturnValue).creationCode);
        constructorArgs.push(abi.encode("BespokeAction_OnReturnValue"));

        names.push("BespokeAction_OnOwnPowers");
        creationCodes.push(type(BespokeAction_OnOwnPowers).creationCode);
        constructorArgs.push(abi.encode("BespokeAction_OnOwnPowers"));


        //////////////////////////////////////////////////////////////////////////
        //                      Integrations Mandates                           //
        //////////////////////////////////////////////////////////////////////////
        names.push("Governor_CreateProposal");
        creationCodes.push(type(Governor_CreateProposal).creationCode);
        constructorArgs.push(abi.encode("Governor_CreateProposal"));

        names.push("Governor_ExecuteProposal");
        creationCodes.push(type(Governor_ExecuteProposal).creationCode);
        constructorArgs.push(abi.encode("Governor_ExecuteProposal"));

        names.push("Safe_Setup");
        creationCodes.push(type(Safe_Setup).creationCode);
        constructorArgs.push(abi.encode("Safe_Setup"));

        names.push("Safe_ExecTransaction");
        creationCodes.push(type(Safe_ExecTransaction).creationCode);
        constructorArgs.push(abi.encode("Safe_ExecTransaction"));

        names.push("Safe_ExecTransaction_OnReturnValue");
        creationCodes.push(type(Safe_ExecTransaction_OnReturnValue).creationCode);
        constructorArgs.push(abi.encode("Safe_ExecTransaction_OnReturnValue"));

        names.push("Safe_RecoverTokens");
        creationCodes.push(type(Safe_RecoverTokens).creationCode);
        constructorArgs.push(abi.encode("Safe_RecoverTokens"));

        names.push("SafeAllowance_Transfer");
        creationCodes.push(type(SafeAllowance_Transfer).creationCode);
        constructorArgs.push(abi.encode("SafeAllowance_Transfer"));

        names.push("SafeAllowance_Action");
        creationCodes.push(type(SafeAllowance_Action).creationCode);
        constructorArgs.push(abi.encode("SafeAllowance_Action"));

        names.push("PowersFactory_AssignRole");
        creationCodes.push(type(PowersFactory_AssignRole).creationCode);
        constructorArgs.push(abi.encode("PowersFactory_AssignRole"));

        names.push("PowersFactory_AddSafeDelegate");
        creationCodes.push(type(PowersFactory_AddSafeDelegate).creationCode);
        constructorArgs.push(abi.encode("PowersFactory_AddSafeDelegate"));

        names.push("Soulbound1155_GatedAccess");
        creationCodes.push(type(Soulbound1155_GatedAccess).creationCode);
        constructorArgs.push(abi.encode("Soulbound1155_GatedAccess"));

        names.push("Soulbound1155_MintEncodedToken");
        creationCodes.push(type(Soulbound1155_MintEncodedToken).creationCode);  
        constructorArgs.push(abi.encode("Soulbound1155_MintEncodedToken"));


        //////////////////////////////////////////////////////////////////////////
        //                   Helper Contracts (remove?)                         //
        //////////////////////////////////////////////////////////////////////////
        names.push("Erc20Taxed");
        creationCodes.push(type(Erc20Taxed).creationCode);
        constructorArgs.push(abi.encode());



        string memory obj2 = "second key"; 

        for (uint256 i = 0; i < names.length; i++) {
            address mandateAddr = deployMandate(creationCodes[i], constructorArgs[i]);
            addresses.push(mandateAddr);
            vm.serializeAddress(obj2, names[i], mandateAddr);
        }

        outputJson = vm.serializeUint(obj2, "chainId", uint256(block.chainid));
    }

    /// @dev Deploys a mandate using CREATE2. Salt is derived from constructor arguments.
    function deployMandate(bytes memory creationCode, bytes memory constructorArg) internal returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(constructorArg));
        bytes memory deploymentData = abi.encodePacked(creationCode, constructorArg);
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
    function deployLibrary(bytes memory creationCodeLib, string memory nameLib) internal returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(nameLib));
        address computedAddress = Create2.computeAddress(salt, keccak256(creationCodeLib), CREATE2_FACTORY);

        if (computedAddress.code.length == 0) {
            address deployedAddress = Create2.deploy(0, salt, creationCodeLib);
            // require(deployedAddress == computedAddress, "Error: Deployed address mismatch.");
            return deployedAddress;
        }
        return computedAddress;
    }

    // @dev wrapper function to expose deployAndRecordMandates externally and only return addresses and names of mandates.
    function getDeployedMandates() external returns (string[] memory mandateNames, address[] memory mandateAddresses) {
        helperConfig = new Configurations();
        config = helperConfig.getConfig();
        deployAndRecordMandates(config);
        return (names, addresses);
    }

    function getMandateAddress(string memory mandateName) external view returns (address) {
        bytes32 mandateHash = keccak256(abi.encodePacked(mandateName));
        for (uint256 i = 0; i < names.length; i++) {
            bytes32 nameHash = keccak256(abi.encodePacked(names[i]));
            if (nameHash == mandateHash) {
                return addresses[i];
            }
        }
        revert("Mandate not found");
    }
}
