// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { Nominees } from "./Nominees.sol";

// import { console2 } from "forge-std/console2.sol"; // remove before deploying.

/// @title Erc20DelegateElection (standalone)
/// @notice Simple, standalone contract combining self-nomination and delegate-based selection.
/// - Accounts can nominate or revoke themselves as candidates.
/// - An election selects up to `maxRoleHolders` nominees with highest delegated votes (`ERC20Votes.getVotes`).
/// - No Powers/Law integration. Pure storage and helper utilities.
contract Erc20DelegateElection is Nominees {
    struct Config {
        ERC20Votes token; // token used for delegated voting power lookups
    }

    Config public config;

    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) revert("token required");
        config = Config({ token: ERC20Votes(tokenAddress) });
    }

    // --- Erc20DelegateElection specific ranking ---
    function getNomineeRanking() external view returns (address[] memory nominees, uint256[] memory votes) {
        uint256 numNominees = nomineesSorted.length;
        if (numNominees == 0) return (new address[](0), new uint256[](0));

        nominees = new address[](numNominees);
        votes = new uint256[](numNominees);

        // Copy nominees and their votes
        for (uint256 i; i < numNominees; i++) {
            nominees[i] = nomineesSorted[i];
            votes[i] = config.token.getVotes(nomineesSorted[i]);
        }

        // Simple bubble sort by vote count (descending)
        for (uint256 i; i < numNominees - 1; i++) {
            for (uint256 j; j < numNominees - i - 1; j++) {
                if (votes[j] < votes[j + 1]) {
                    // Swap votes
                    uint256 tempVotes = votes[j];
                    votes[j] = votes[j + 1];
                    votes[j + 1] = tempVotes;
                    // Swap nominees
                    address tempNominee = nominees[j];
                    nominees[j] = nominees[j + 1];
                    nominees[j + 1] = tempNominee;
                }
            }
        }

        return (nominees, votes);
    }
}
