// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// --- Forge/OpenZeppelin Imports ---
import { Script } from "forge-std/Script.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { console2 } from "forge-std/console2.sol";

// --- Library Imports ---
import { Checks } from "../src/libraries/Checks.sol";
import { LawUtilities } from "../src/libraries/LawUtilities.sol";
import { InitialisePowers } from "./InitialisePowers.s.sol";

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
import { RevokeLaws } from "../src/laws/executive/RevokeLaws.sol";
import { AdoptLawsPackage } from "../src/laws/executive/AdoptLawsPackage.sol";
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
// async laws
import { RoleByGitSignature } from "../src/laws/async/RoleByGitSignature.sol";
// Integration Laws 
import { AlloCreateRPGFPool } from "../src/laws/integrations/AlloCreateRPGFPool.sol";
import { AlloDistribute } from "../src/laws/integrations/AlloDistribute.sol";
import { AlloRPFGGovernance } from "../src/laws/integrations/AlloRPFGGovernance.sol";
 
/// @title DeployLaws
/// @notice A wrapper function that runs the deployment of law contracts deterministically using CREATE2, using the deployAndRecordLaws function from InitialisePowers.s.sol
/// In contrast to InitialisePowers, it does NOT save anything to file. It just returns the names and addresses of the deployed laws.
contract DeployLaws is Script { 
    string outputFile;
      InitialisePowers initialisePowers;

    function run() external returns (string[] memory names, address[] memory addresses) {
        initialisePowers = new InitialisePowers();
        (names, addresses, ) = initialisePowers.deployAndRecordLaws("Random string to avoid error.");
    }
}