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

/// @title LawUtilities - Utility Functions for Powers Protocol Laws
/// @notice A library of helper functions used across Law contracts
/// @dev Provides common functionality for Law implementation and validation
/// @author 7Cedars

pragma solidity 0.8.26;

import { ERC721 } from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { Powers } from "./Powers.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { PowersTypes } from "./interfaces/PowersTypes.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

library LawUtilities {
    //////////////////////////////////////////////////////////////
    //                  STORAGE POINTERS                        //
    //////////////////////////////////////////////////////////////

    /// @notice Structure to track transactions by account address
    /// @dev Uses a mapping to store arrays of block numbers for each account
    struct TransactionsByAccount {
        mapping(address account => uint48[] blockNumber) transactions;
    }

    /////////////////////////////////////////////////////////////
    //                  CHECKS                                 //
    /////////////////////////////////////////////////////////////
    function checkStringLength(string memory name_, uint256 minLength, uint256 maxLength) external pure {
        if (bytes(name_).length < minLength) {
            revert ("String too short");
        }
        if (bytes(name_).length > maxLength) {
            revert ("String too long");
        }
    }


    /////////////////////////////////////////////////////////////
    //                  FUNCTIONS                              //
    /////////////////////////////////////////////////////////////
    /// @notice Verifies if an address owns any tokens from a specific NFT contract
    /// @dev Checks the balance of the given address in the specified ERC721 contract
    /// @param caller Address to check token ownership for
    /// @param nftCheckAddress Address of the ERC721 contract
    /// @return hasToken True if the caller owns at least one token
    function nftCheck(address caller, address nftCheckAddress) external view returns (bool hasToken) {
        hasToken = ERC721(nftCheckAddress).balanceOf(caller) > 0;
        if (!hasToken) {
            revert("Does not own token.");
        }
    }

    /// @notice Checks if an address is blacklisted
    /// @dev Queries a mapping contract to check if the address is blacklisted
    /// @param caller Address to check blacklist status for
    /// @param blacklistAddress Address of the blacklist contract
    /// @return isBlacklisted True if the address is blacklisted
    // function blacklistCheck(address caller, address blacklistAddress)
    //     internal
    //     pure
    //     returns (bool isBlacklisted)
    // {
    //     isBlacklisted = AddressesMapping(blacklistAddress).addresses(caller);

    //     if (isBlacklisted) {
    //         revert ("Is blacklisted.");
    //     }
    // }

    /// @notice Verifies if an address has all specified roles
    /// @dev Checks each role against the Powers contract's role system
    /// @param caller Address to check roles for
    /// @param roles Array of role IDs to check
    function hasRoleCheck(address caller, uint32[] memory roles, address powers) external view {
        for (uint32 i = 0; i < roles.length; i++) {
            uint48 since = Powers(payable(powers)).hasRoleSince(caller, roles[i]);
            if (since == 0) {
                revert("Does not have role.");
            }
        }
    }

    /// @notice Verifies if an address does not have any of the specified roles
    /// @dev Checks each role against the Powers contract's role system
    /// @param caller Address to check roles for
    /// @param roles Array of role IDs to check
    function hasNotRoleCheck(address caller, uint32[] memory roles, address powers) external view {
        for (uint32 i = 0; i < roles.length; i++) {
            uint48 since = Powers(payable(powers)).hasRoleSince(caller, roles[i]);
            if (since != 0) {
                revert("Has role.");
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
        external
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
        external
        view
        returns (bool)
    {
        if (self.transactions[account].length == 0) {
            return true;
        }
        uint48 lastTransaction = self.transactions[account][self.transactions[account].length - 1];
        if (uint48(block.number) - lastTransaction < delay) {
            revert("Delay not passed");
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
        external
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

    //////////////////////////////////////////////////////////////
    //                      HELPER FUNCTIONS                    //
    //////////////////////////////////////////////////////////////
    /// @notice Creates a unique identifier for an action
    /// @dev Hashes the combination of law address, calldata, and nonce
    /// @param lawId Address of the law contract being called
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return actionId Unique identifier for the action
    function hashActionId(uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        pure
        returns (uint256 actionId)
    {
        actionId = uint256(keccak256(abi.encode(lawId, lawCalldata, nonce)));
    }

    /// @notice Creates a unique identifier for a law, used for sandboxing executions of laws.
    /// @dev Hashes the combination of law address and index
    /// @param powers Address of the Powers contract
    /// @param index Index of the law
    /// @return lawHash Unique identifier for the law
    function hashLaw(address powers, uint16 index) public pure returns (bytes32 lawHash) {
        lawHash = keccak256(abi.encode(powers, index));
    }

    /// @notice Creates empty arrays for storing transaction data
    /// @dev Initializes three arrays of the same length for targets, values, and calldata
    /// @param length The desired length of the arrays
    /// @return targets Array of target addresses
    /// @return values Array of ETH values
    /// @return calldatas Array of encoded function calls
    function createEmptyArrays(uint256 length)
        public
        pure
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](length);
        values = new uint256[](length);
        calldatas = new bytes[](length);
    }

    /// @notice Converts a boolean array from calldata to a memory array
    /// @dev Uses assembly to efficiently decode the boolean array from calldata
    /// @param numBools The number of booleans to decode
    /// @return boolArray The decoded boolean array
    /// Note: written by Cursor AI.
    function arrayifyBools(uint256 numBools) public pure returns (bool[] memory boolArray) {
        assembly {
            // Allocate memory for the array
            boolArray := mload(0x40)
            mstore(boolArray, numBools) // set array length
            let dataOffset := 0x24 // skip 4 bytes selector, start at 0x04, but arrays start at 0x20
            for { let i := 0 } lt(i, numBools) { i := add(i, 1) } {
                // Each bool is 32 bytes
                let value := calldataload(add(4, mul(i, 32)))
                mstore(add(add(boolArray, 0x20), mul(i, 0x20)), iszero(iszero(value)))
            }
            // Update free memory pointer
            mstore(0x40, add(add(boolArray, 0x20), mul(numBools, 0x20)))
        }
    }
}
