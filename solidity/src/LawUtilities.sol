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
/// @dev Provides common functionality for law implementation and validation
/// @author 7Cedars
pragma solidity 0.8.26;

import { ERC721 } from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { Powers } from "./Powers.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { PowersTypes } from "./interfaces/PowersTypes.sol";    


library LawUtilities {
    //////////////////////////////////////////////////////////////
    //                        ERRORS                            //
    //////////////////////////////////////////////////////////////
    error LawUtilities__ParentNotCompleted();
    error LawUtilities__ParentBlocksCompletion();
    error LawUtilities__ExecutionGapTooSmall();
    error LawUtilities__ProposalNotSucceeded();
    error LawUtilities__DeadlineNotPassed();
    
    //////////////////////////////////////////////////////////////
    //                  STORAGE POINTERS                        //
    //////////////////////////////////////////////////////////////

    /// @notice Structure to track transactions by account address
    /// @dev Uses a mapping to store arrays of block numbers for each account
    struct TransactionsByAccount {
        mapping(address account => uint48[] blockNumber) transactions;
    }

    /// @notice Structure to track conditions for a law
    /// @dev Uses a mapping to store arrays of block numbers for each account
    struct Conditions {
        // Slot 1
        address needCompleted;      // 20 bytes - Address of law that must be completed before this one
        uint48 delayExecution;      // 6 bytes  - Blocks to wait after proposal success before execution
        uint48 throttleExecution;   // 6 bytes  - Minimum blocks between executions
        // Slot 2  
        address readStateFrom;      // 20 bytes - Address to read state from (for law dependencies)
        uint32 votingPeriod;       // 4 bytes  - Number of blocks for voting period
        uint8 quorum;              // 1 byte   - Required participation percentage
        uint8 succeedAt;           // 1 byte   - Required success percentage
        // Slot 3
        address needNotCompleted;   // 20 bytes - Address of law that must NOT be completed
    }

    /////////////////////////////////////////////////////////////
    //                  CHECKS                                 //
    /////////////////////////////////////////////////////////////

    /// @notice Checks if a parent law has been completed
    /// @dev Checks if a parent law has been completed
    /// @param conditions The conditionsuration parameters for the law
    /// @param lawCalldata The calldata of the law
    /// @param nonce The nonce of the law
    function baseChecksAtPropose(Conditions memory conditions, bytes memory lawCalldata, uint256 nonce, address powers)
        external
        view
      {
        // Check if parent law completion is required
        if (conditions.needCompleted != address(0)) {
            uint256 parentActionId = hashActionId(conditions.needCompleted, lawCalldata, nonce);

            if (Powers(payable(powers)).state(parentActionId) != PowersTypes.ActionState.Fulfilled) {
                revert LawUtilities__ParentNotCompleted();
            }
        }

        // Check if parent law must not be completed
        if (conditions.needNotCompleted != address(0)) {
            uint256 parentActionId = hashActionId(conditions.needNotCompleted, lawCalldata, nonce);

            if (Powers(payable(powers)).state(parentActionId) == PowersTypes.ActionState.Fulfilled) {
                revert LawUtilities__ParentBlocksCompletion();
            }
        }
    }

    /// @notice Checks if a parent law has been completed
    /// @dev Checks if a parent law has been completed
    /// @param conditions The conditionsuration parameters for the law
    /// @param lawCalldata The calldata of the law
    /// @param nonce The nonce of the law
    function baseChecksAtExecute(Conditions memory conditions, bytes memory lawCalldata, uint256 nonce, address powers, uint48[] memory executions)
        external
        view
    {
        // Check execution throttling
        if (conditions.throttleExecution != 0) {
            uint256 numberOfExecutions = executions.length - 1;
            if (executions[numberOfExecutions] != 0 && 
                block.number - executions[numberOfExecutions] < conditions.throttleExecution) {
                revert LawUtilities__ExecutionGapTooSmall();
            }
        }

        // Check if proposal vote succeeded
        if (conditions.quorum != 0) {
            uint256 actionId = hashActionId(address(this), lawCalldata, nonce);
            if (Powers(payable(powers)).state(actionId) != PowersTypes.ActionState.Succeeded) {
                revert LawUtilities__ProposalNotSucceeded();
            }
        }

        // Check execution delay after proposal
        if (conditions.delayExecution != 0) {
            uint256 actionId = hashActionId(address(this), lawCalldata, nonce);
            uint256 deadline = Powers(payable(powers)).getProposedActionDeadline(actionId);
            if (deadline + conditions.delayExecution > block.number) {
                revert LawUtilities__DeadlineNotPassed();
            }
        }
    }


    /////////////////////////////////////////////////////////////
    //                  FUNCTIONS                              //
    /////////////////////////////////////////////////////////////

    /// @notice Creates a unique identifier for an action
    /// @dev Hashes the combination of law address, calldata, and nonce
    /// @param targetLaw Address of the law contract being called
    /// @param lawCalldata Encoded function call data
    /// @param nonce The nonce for the action
    /// @return actionId Unique identifier for the action
    function hashActionId(address targetLaw, bytes memory lawCalldata, uint256 nonce)
        public
        pure
        returns (uint256 actionId)
    {
        actionId = uint256(keccak256(abi.encode(targetLaw, lawCalldata, nonce)));
    }

    /// @notice Creates empty arrays for storing transaction data
    /// @dev Initializes three arrays of the same length for targets, values, and calldata
    /// @param length The desired length of the arrays
    /// @return targets Array of target addresses
    /// @return values Array of ETH values
    /// @return calldatas Array of encoded function calls
    function createEmptyArrays(uint256 length) 
        external
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
        external
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
    /// @param caller Address to check token ownership for
    /// @param nftCheckAddress Address of the ERC721 contract
    /// @return hasToken True if the caller owns at least one token
    function nftCheck(address caller, address nftCheckAddress)
        external
        view
        returns (bool hasToken)
    {
        hasToken = ERC721(nftCheckAddress).balanceOf(caller) > 0;
        if (!hasToken) {
            revert ("Does not own token.");
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
    function hasRoleCheck(address caller, uint32[] memory roles, address powers)
        external
        view
    {
        for (uint32 i = 0; i < roles.length; i++) {
            uint48 since = Powers(payable(powers)).hasRoleSince(caller, roles[i]);
            if (since == 0) {
                revert ("Does not have role.");
            }
        }
    }

    /// @notice Verifies if an address does not have any of the specified roles
    /// @dev Checks each role against the Powers contract's role system
    /// @param caller Address to check roles for
    /// @param roles Array of role IDs to check
    function hasNotRoleCheck(address caller, uint32[] memory roles, address powers)
        external
        view
    {
        for (uint32 i = 0; i < roles.length; i++) {
            uint48 since = Powers(payable(powers)).hasRoleSince(caller, roles[i]);
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
}
