// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @notice Assign roles based on the latest donation an account made to a Treasury contract.
/// @dev At setup, a role ID is set, the treasury contract address, and multiple tokens with their respective
/// amounts per block. When an account claims a role, it checks the most recent donation and assigns/revokes the role
/// based on whether access is still valid past the current block. Donations do not add up—only the most recent donation
/// determines access duration. Different tokens can have different rates for the access duration calculation.

/// @author 7Cedars
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { TreasurySimple } from "../../helpers/TreasurySimple.sol";

// import "forge-std/Test.sol"; // only for testing

contract BuyAccess is Law {
    struct TokenConfig {
        address token; // token address (address(0) for native currency)
        uint256 tokensPerBlock; // tokens per block for access duration
    }

    struct Data {
        address treasuryContract; // TreasurySimple contract address
        TokenConfig[] tokenConfigs; // token configurations for supported tokens
        uint16 roleIdToSet; // role id to assign/revoke
    }

    struct Mem {
        bytes32 lawHash;
        Data data;
        address caller;
        address account;
        uint256 totalDonated;
        uint48 currentBlock;
        uint48 amountBlocksBought;
        uint48 accessUntilBlock;
        bool shouldAssignRole;
    }

    mapping(bytes32 lawHash => Data) internal data;

    constructor() {
        bytes memory configParams =
            abi.encode("address TreasuryContract", "address[] Tokens", "uint256[] TokensPerBlock", "uint16 RoleId");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address treasuryContract_, address[] memory tokens_, uint256[] memory tokensPerBlock_, uint16 roleIdToSet_) =
            abi.decode(config, (address, address[], uint256[], uint16));

        // Validate that arrays have the same length
        if (tokens_.length != tokensPerBlock_.length) {
            revert("Tokens and TokensPerBlock arrays must have the same length");
        }
        if (tokens_.length == 0) {
            revert("At least one token configuration is required");
        }

        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].treasuryContract = treasuryContract_;
        data[lawHash].roleIdToSet = roleIdToSet_;

        // Store token configurations
        for (uint256 i = 0; i < tokens_.length; i++) {
            data[lawHash].tokenConfigs.push(TokenConfig({ token: tokens_[i], tokensPerBlock: tokensPerBlock_[i] }));
        }

        inputParams = abi.encode("address Account"); // account to claim role for

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Handles the request to claim a role based on donations
    /// @param powers The address of the Powers contract
    /// @param lawId The ID of the law
    /// @param lawCalldata The calldata containing the account to claim role for
    /// @param nonce The nonce for the action
    /// @return actionId The ID of the action
    /// @return targets The target addresses for the action
    /// @return values The values for the action
    /// @return calldatas The calldatas for the action
    function handleRequest(address, /* caller */ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        mem.data = data[mem.lawHash];

        // Decode the calldata to get the account to claim role for
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        mem.account = abi.decode(lawCalldata, (address));
        mem.currentBlock = uint48(block.number);

        // Check donations and determine if role should be assigned or revoked
        mem.shouldAssignRole =
            _checkDonationAccess(mem.account, mem.data.treasuryContract, mem.data.tokenConfigs, mem.currentBlock);

        // Create arrays for execution
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

        if (mem.shouldAssignRole) {
            // Assign role
            targets[0] = powers;
            values[0] = 0;
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, mem.data.roleIdToSet, mem.account);
        } else {
            // Revoke role
            targets[0] = powers;
            values[0] = 0;
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, mem.data.roleIdToSet, mem.account);
        }

        return (actionId, targets, values, calldatas);
    }

    /// @notice Check if an account has sufficient donations to maintain role access
    /// @param account The account to check donations for
    /// @param treasuryContract The address of the TreasurySimple contract
    /// @param tokenConfigs Array of token configurations with their respective rates
    /// @param currentBlock The current block number
    /// @return shouldAssign True if the account should have the role assigned
    function _checkDonationAccess(
        address account,
        address treasuryContract,
        TokenConfig[] memory tokenConfigs,
        uint48 currentBlock
    ) internal view returns (bool shouldAssign) {
        // Get the transfer count for the account from the treasury contract
        uint256 transferCount = TreasurySimple(payable(treasuryContract)).transferCount();
        if (transferCount == 0) {
            return false; // No transfers, no access
        }

        // Find the most recent transfer from the account
        TreasurySimple.TransferLog memory mostRecentTransfer;
        bool foundTransfer = false;
        for (uint256 i = transferCount; i > 0; i--) {
            TreasurySimple.TransferLog memory transferLog = TreasurySimple(payable(treasuryContract)).getTransfer(i - 1);
            if (transferLog.from == account) {
                mostRecentTransfer = transferLog;
                foundTransfer = true;
                break;
            }
        }

        if (!foundTransfer) {
            return false; // No transfers from this account
        }

        // Find the token configuration for the most recent transfer
        TokenConfig memory tokenConfig = _findTokenConfig(mostRecentTransfer.token, tokenConfigs);

        // If token is not configured, no access
        if (tokenConfig.token == address(0) && mostRecentTransfer.token != address(0)) {
            return false; // Token not configured
        }

        // Calculate how many blocks of access this transfer provides
        uint48 blocksOfAccess = uint48(mostRecentTransfer.amount / tokenConfig.tokensPerBlock);

        if (blocksOfAccess == 0) {
            return false; // Transfer too small for any access
        }

        // Calculate when access expires
        uint48 accessUntilBlock = uint48(mostRecentTransfer.blockNumber) + blocksOfAccess;

        // Check if access is still valid
        return currentBlock < accessUntilBlock;
    }

    /// @notice Find the token configuration for a given token address
    /// @param token The token address to find configuration for
    /// @param tokenConfigs Array of token configurations
    /// @return config The token configuration, or empty config if not found
    function _findTokenConfig(address token, TokenConfig[] memory tokenConfigs)
        internal
        pure
        returns (TokenConfig memory config)
    {
        for (uint256 i = 0; i < tokenConfigs.length; i++) {
            if (tokenConfigs[i].token == token) {
                return tokenConfigs[i];
            }
        }
        // Return empty config if token not found
        return TokenConfig({ token: address(0), tokensPerBlock: 0 });
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
