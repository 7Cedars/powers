// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// import { console2 } from "forge-std/console2.sol"; // remove before deploying.

/// @title Grant - Standalone Grant Management Contract
/// @notice Comprehensive grant management system with budget control, token whitelisting, and proposal approval
/// @dev All functions are restricted to the Powers contract set at construction
contract Grant is Ownable {
    struct Proposal {
        address proposer;
        string uri; // KPI/description URI
        uint256[] milestoneBlocks; // Block numbers for milestones
        uint256[] milestoneAmounts; // Amounts for each milestone
        address[] tokens; // Token addresses for each milestone (address(0) for native)
        bool approved;
        bool rejected;
        uint256 submissionBlock;
    }

    struct Milestone {
        uint256 blockNumber;
        uint256 amount;
        address token;
        bool released;
    }

    struct Budget {
        uint256 nativeBudget; // Native currency budget
        mapping(address => uint256) tokenBudgets; // ERC20 token budgets
    }

    // State variables
    Budget public budget;
    mapping(address => bool) public whitelistedTokens;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(uint256 => Milestone)) public milestones; // proposalId => milestoneIndex => Milestone
    uint256 public proposalCounter;
    uint256 public totalSpentNative;
    mapping(address => uint256) public totalSpentToken;

    // Events
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string uri);
    event ProposalApproved(uint256 indexed proposalId);
    event ProposalRejected(uint256 indexed proposalId);
    event MilestoneReleased(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount, address token);
    event BudgetUpdated(uint256 nativeBudget);
    event TokenBudgetUpdated(address indexed token, uint256 budget);
    event TokenWhitelisted(address indexed token);
    event TokenDewhitelisted(address indexed token);

    constructor() Ownable(msg.sender) { }

    // --- Budget Management ---
    function updateNativeBudget(uint256 _budget) external onlyOwner {
        budget.nativeBudget = _budget;
        emit BudgetUpdated(_budget);
    }

    function updateTokenBudget(address token, uint256 _budget) external onlyOwner {
        if (token == address(0)) revert("Invalid token address");
        budget.tokenBudgets[token] = _budget;
        emit TokenBudgetUpdated(token, _budget);
    }

    function getNativeBudget() external view returns (uint256) {
        return budget.nativeBudget;
    }

    function getTokenBudget(address token) external view returns (uint256) {
        return budget.tokenBudgets[token];
    }

    function getRemainingNativeBudget() external view returns (uint256) {
        return budget.nativeBudget - totalSpentNative;
    }

    function getRemainingTokenBudget(address token) external view returns (uint256) {
        return budget.tokenBudgets[token] - totalSpentToken[token];
    }

    // --- Token Whitelisting ---

    function whitelistToken(address token) external onlyOwner {
        if (token == address(0)) revert("Invalid token address");
        whitelistedTokens[token] = true;
        emit TokenWhitelisted(token);
    }

    function dewhitelistToken(address token) external onlyOwner {
        whitelistedTokens[token] = false;
        emit TokenDewhitelisted(token);
    }

    function isTokenWhitelisted(address token) external view returns (bool) {
        return whitelistedTokens[token];
    }

    // --- Proposal Management ---

    function submitProposal(
        string memory uri,
        uint256[] memory milestoneBlocks,
        uint256[] memory milestoneAmounts,
        address[] memory tokens
    ) external onlyOwner returns (uint256 proposalId) {
        if (milestoneBlocks.length == 0) revert("Invalid proposal");
        if (milestoneBlocks.length != milestoneAmounts.length) revert("Invalid proposal");
        if (milestoneBlocks.length != tokens.length) revert("Invalid proposal");

        // Validate tokens are whitelisted (except native currency)
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] != address(0) && !whitelistedTokens[tokens[i]]) {
                revert("Token not whitelisted");
            }
        }

        proposalId = proposalCounter++;

        proposals[proposalId] = Proposal({
            proposer: tx.origin, // Use tx.origin to get the actual proposer
            uri: uri,
            milestoneBlocks: milestoneBlocks,
            milestoneAmounts: milestoneAmounts,
            tokens: tokens,
            approved: false,
            rejected: false,
            submissionBlock: block.number
        });

        // Store milestones
        for (uint256 i; i < milestoneBlocks.length; i++) {
            milestones[proposalId][i] = Milestone({
                blockNumber: milestoneBlocks[i],
                amount: milestoneAmounts[i],
                token: tokens[i],
                released: false
            });
        }

        emit ProposalSubmitted(proposalId, tx.origin, uri);
    }

    function approveProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.submissionBlock == 0) revert("Proposal not found");
        if (proposal.approved || proposal.rejected) revert("Proposal already processed");

        // Check if the total requested amounts fall within the remaining budget
        _checkProposalBudgetConstraints(proposalId);

        proposal.approved = true;
        emit ProposalApproved(proposalId);
    }

    function rejectProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.submissionBlock == 0) revert("Proposal not found");
        if (proposal.approved || proposal.rejected) revert("Proposal already processed");

        proposal.rejected = true;
        emit ProposalRejected(proposalId);
    }

    // --- Milestone Management ---

    function releaseMilestone(uint256 proposalId, uint256 milestoneIndex) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.submissionBlock == 0) revert("Proposal not found");
        if (!proposal.approved) revert("Proposal not approved");

        Milestone storage milestone = milestones[proposalId][milestoneIndex];

        if (milestone.amount == 0) revert("Milestone not found");
        if (milestone.released) revert("Milestone already released");
        if (block.number < milestone.blockNumber) revert("Milestone not reached");

        _checkBudgetConstraints(proposalId, milestoneIndex);

        milestone.released = true;
        emit MilestoneReleased(proposalId, milestoneIndex, milestone.amount, milestone.token);
    }

    // --- View Functions ---

    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }

    function getMilestone(uint256 proposalId, uint256 milestoneIndex) external view returns (Milestone memory) {
        return milestones[proposalId][milestoneIndex];
    }

    function getProposalMilestones(uint256 proposalId) external view returns (Milestone[] memory) {
        Proposal memory proposal = proposals[proposalId];
        if (proposal.submissionBlock == 0) revert("Proposal not found");

        Milestone[] memory milestoneList = new Milestone[](proposal.milestoneBlocks.length);
        for (uint256 i; i < proposal.milestoneBlocks.length; i++) {
            milestoneList[i] = milestones[proposalId][i];
        }
        return milestoneList;
    }

    function isProposalApproved(uint256 proposalId) external view returns (bool) {
        return proposals[proposalId].approved;
    }

    function isProposalRejected(uint256 proposalId) external view returns (bool) {
        return proposals[proposalId].rejected;
    }

    function getTotalSpentNative() external view returns (uint256) {
        return totalSpentNative;
    }

    function getTotalSpentToken(address token) external view returns (uint256) {
        return totalSpentToken[token];
    }

    function getProposalCount() external view returns (uint256) {
        return proposalCounter;
    }

    // --- Utility Functions ---

    function canReleaseMilestone(uint256 proposalId, uint256 milestoneIndex) external view returns (bool) {
        Proposal memory proposal = proposals[proposalId];
        if (proposal.submissionBlock == 0) return false;
        if (!proposal.approved) return false;

        Milestone memory milestone = milestones[proposalId][milestoneIndex];
        if (milestone.amount == 0) return false;
        if (milestone.released) return false;
        if (block.number < milestone.blockNumber) return false;

        // Check budget
        if (milestone.token == address(0)) {
            return (totalSpentNative + milestone.amount <= budget.nativeBudget);
        } else {
            return (totalSpentToken[milestone.token] + milestone.amount <= budget.tokenBudgets[milestone.token]);
        }
    }

    function getBudgetStatus()
        external
        view
        returns (
            uint256 nativeBudget,
            uint256 nativeSpent,
            uint256 nativeRemaining,
            address[] memory whitelistedTokenList,
            uint256[] memory tokenBudgets,
            uint256[] memory tokenSpent,
            uint256[] memory tokenRemaining
        )
    {
        nativeBudget = budget.nativeBudget;
        nativeSpent = totalSpentNative;
        nativeRemaining = budget.nativeBudget - totalSpentNative;

        // Note: This is a simplified version. In practice, you might want to limit the number of tokens returned
        // or implement pagination for better gas efficiency
        return (
            nativeBudget,
            nativeSpent,
            nativeRemaining,
            new address[](0),
            new uint256[](0),
            new uint256[](0),
            new uint256[](0)
        );
    }

    function _checkProposalBudgetConstraints(uint256 proposalId) internal view {
        Proposal memory proposal = proposals[proposalId];

        // Calculate total amounts needed for each token type
        uint256 totalNativeNeeded = 0;

        // First pass: sum up all milestone amounts by token type
        for (uint256 i = 0; i < proposal.milestoneBlocks.length; i++) {
            Milestone memory milestone = milestones[proposalId][i];

            if (milestone.token == address(0)) {
                // Native currency
                totalNativeNeeded += milestone.amount;
            }
        }

        // Check native budget constraints
        if (totalNativeNeeded > 0) {
            if (totalSpentNative + totalNativeNeeded > budget.nativeBudget) {
                revert("Insufficient native budget for proposal");
            }
        }

        // Second pass: check token budget constraints for each unique token
        for (uint256 i = 0; i < proposal.milestoneBlocks.length; i++) {
            Milestone memory milestone = milestones[proposalId][i];

            if (milestone.token != address(0)) {
                // Calculate total amount needed for this specific token across all milestones
                uint256 totalTokenNeeded = 0;
                for (uint256 j = 0; j < proposal.milestoneBlocks.length; j++) {
                    Milestone memory otherMilestone = milestones[proposalId][j];
                    if (otherMilestone.token == milestone.token) {
                        totalTokenNeeded += otherMilestone.amount;
                    }
                }

                // Check if this token's total requirement exceeds budget
                if (totalSpentToken[milestone.token] + totalTokenNeeded > budget.tokenBudgets[milestone.token]) {
                    revert("Insufficient token budget for proposal");
                }
            }
        }
    }

    function _checkBudgetConstraints(uint256 proposalId, uint256 milestoneIndex) internal {
        Milestone memory milestone = milestones[proposalId][milestoneIndex];
        // Check budget constraints
        if (milestone.token == address(0)) {
            // Native currency
            if (totalSpentNative + milestone.amount > budget.nativeBudget) {
                revert("Insufficient budget");
            }
            totalSpentNative += milestone.amount;
        } else {
            // ERC20 token
            if (totalSpentToken[milestone.token] + milestone.amount > budget.tokenBudgets[milestone.token]) {
                revert("Insufficient budget");
            }
            totalSpentToken[milestone.token] += milestone.amount;
        }
    }
}
