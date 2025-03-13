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

/// @title LawUtils - Utility Functions for Powers Protocol Laws
/// @notice A library of helper functions used across Law contracts
/// @dev Provides common functionality for law implementation and validation
/// @author 7Cedars
pragma solidity 0.8.26;

import { ERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { Powers } from "../Powers.sol";
 
library LawUtils {
    /// @notice Structure to track transactions by account address
    /// @dev Uses a mapping to store arrays of block numbers for each account
    struct TransactionsByAccount {
        mapping(address account => uint48[] blockNumber) transactions;
    }

    function checkConstructorInputs(address powers, string memory name)
        internal
        pure
    {
        if (powers == address(0)) {
            revert ("Invalid Powers Contract Address");
        }
        if (bytes(name).length < 1) {
            revert ("Empty name not allowed.");
        }
    }

    /// @notice Creates a unique identifier for an action
    /// @dev Hashes the combination of law address, calldata, and description
    /// @param targetLaw Address of the law contract being called
    /// @param lawCalldata Encoded function call data
    /// @param descriptionHash Hash of the action description
    /// @return actionId Unique identifier for the action
    function hashActionId(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        pure
        returns (uint256 actionId)
    {
        actionId = uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }

    /// @notice Creates empty arrays for storing transaction data
    /// @dev Initializes three arrays of the same length for targets, values, and calldata
    /// @param length The desired length of the arrays
    /// @return targets Array of target addresses
    /// @return values Array of ETH values
    /// @return calldatas Array of encoded function calls
    function createEmptyArrays(uint256 length) 
        internal
        pure
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](length);
        values = new uint256[](length);
        calldatas = new bytes[](length);
    }

    /// @notice Adds a self-destruct call to existing transaction arrays
    /// @dev Appends a revokeLaw call to the end of the transaction arrays
    /// @param targets Existing array of target addresses
    /// @param values Existing array of ETH values
    /// @param calldatas Existing array of encoded function calls
    /// @param powers Address of the Powers protocol contract
    /// @return targetsNew Updated array of target addresses including the self-destruct call
    /// @return valuesNew Updated array of ETH values including the self-destruct call
    /// @return calldatasNew Updated array of encoded function calls including the self-destruct call
    function addSelfDestruct(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, address powers)
        internal
        view
        returns (address[] memory targetsNew, uint256[] memory valuesNew, bytes[] memory calldatasNew)
    {
        // create new arrays
        targetsNew = new address[](targets.length + 1);
        valuesNew = new uint256[](values.length + 1);
        calldatasNew = new bytes[](calldatas.length + 1);

        // pasting in old arrays. This method is super inefficient. Is there no other way of doing this?
        for (uint256 i; i < targets.length; i++) {
            targetsNew[i] = targets[i];
            valuesNew[i] = values[i];
            calldatasNew[i] = calldatas[i];
        }

        // adding self destruct data to array
        targetsNew[targets.length] = powers;
        valuesNew[values.length] = 0;
        calldatasNew[calldatas.length] = abi.encodeWithSelector(Powers.revokeLaw.selector, address(this));

        // return new arrays
        return (targetsNew, valuesNew, calldatasNew);
    }

    /// @notice Verifies if an address owns any tokens from a specific NFT contract
    /// @dev Checks the balance of the given address in the specified ERC721 contract
    /// @param initiator Address to check token ownership for
    /// @param nftCheckAddress Address of the ERC721 contract
    /// @return hasToken True if the initiator owns at least one token
    function nftCheck(address initiator, address nftCheckAddress)
        internal
        view
        returns (bool hasToken)
    {
        hasToken = ERC721(nftCheckAddress).balanceOf(initiator) > 0;
        if (!hasToken) {
            revert ("Does not own token.");
        }
    }

    /// @notice Checks if an address is blacklisted
    /// @dev Queries a mapping contract to check if the address is blacklisted
    /// @param initiator Address to check blacklist status for
    /// @param blacklistAddress Address of the blacklist contract
    /// @return isBlacklisted True if the address is blacklisted
    // function blacklistCheck(address initiator, address blacklistAddress)
    //     internal
    //     pure
    //     returns (bool isBlacklisted)
    // {
    //     isBlacklisted = AddressesMapping(blacklistAddress).addresses(initiator);
        
    //     if (isBlacklisted) {
    //         revert ("Is blacklisted.");
    //     }
    // }

    /// @notice Verifies if an address has all specified roles
    /// @dev Checks each role against the Powers contract's role system
    /// @param initiator Address to check roles for
    /// @param roles Array of role IDs to check
    function hasRoleCheck(address initiator, uint32[] memory roles, address powers)
        internal
        view
    {
        for (uint32 i = 0; i < roles.length; i++) {
            uint48 since = Powers(payable(powers)).hasRoleSince(initiator, roles[i]);
            if (since == 0) {
                revert ("Does not have role.");
            }
        }
    }

    /// @notice Verifies if an address does not have any of the specified roles
    /// @dev Checks each role against the Powers contract's role system
    /// @param initiator Address to check roles for
    /// @param roles Array of role IDs to check
    function hasNotRoleCheck(address initiator, uint32[] memory roles, address powers)
        internal
        view
    {
        for (uint32 i = 0; i < roles.length; i++) {
            uint48 since = Powers(payable(powers)).hasRoleSince(initiator, roles[i]);
            if (since != 0) {
                revert ("Has role.");
            }
        }
    }

    /// @notice Logs a transaction for an account at a specific block
    /// @dev Adds a block number to the account's transaction history
    /// @param self The TransactionsByAccount storage structure
    /// @param account The address of the account
    /// @param blockNumber The block number to log
    /// @return True if the transaction was successfully logged
    /// see for explanation: https://docs.soliditylang.org/en/v0.8.29/contracts.html#libraries
    function logTransaction(TransactionsByAccount storage self, address account, uint48 blockNumber)
        public  
        returns (bool)
    {
        self.transactions[account].push(blockNumber);
        return true;
    }

    /// @notice Checks if enough time has passed since the last transaction
    /// @dev Verifies if the delay between transactions meets the minimum requirement
    /// @param self The TransactionsByAccount storage structure
    /// @param account The address of the account
    /// @param delay The minimum number of blocks required between transactions
    /// @return True if the delay requirement is met
    function checkThrottle(TransactionsByAccount storage self, address account, uint48 delay)
        public
        view
        returns (bool)
    {
        uint48 lastTransaction = self.transactions[account][self.transactions[account].length - 1];
        if (uint48(block.number) - lastTransaction < delay) {
            revert ("Delay not passed");
        }
        return true;
    }

    /// @notice Counts the number of transactions within a block range
    /// @dev Iterates through transaction history to count transactions in the specified range
    /// @param self The TransactionsByAccount storage structure
    /// @param account The address of the account
    /// @param start The starting block number
    /// @param end The ending block number
    /// @return numberOfTransactions The count of transactions within the range
    function checkNumberOfTransactions(TransactionsByAccount storage self, address account, uint48 start, uint48 end)
        public  
        view
        returns (uint256 numberOfTransactions)
    {   
        for (uint256 i = 0; i < self.transactions[account].length; i++) {
            if (self.transactions[account][i] >= start && self.transactions[account][i] <= end) {
                numberOfTransactions++;
            }
        }
        return numberOfTransactions;
    }
}
