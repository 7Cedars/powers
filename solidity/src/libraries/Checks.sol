// SPDX-License-Identifier: MIT



/// @title Checks - Checks for Powers Protocol
/// @notice A library of helper functions used across Powers contracts
/// @dev Provides common functionality for Powers implementation and validation
/// @author 7Cedars

pragma solidity 0.8.26;

import { Powers } from "../Powers.sol";
import { PowersTypes } from "../interfaces/PowersTypes.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

library Checks {
    //////////////////////////////////////////////////////////// 
    //                 ERRORS                                 //
    ////////////////////////////////////////////////////////////
    error Checks__ParentLawNotCompleted();
    error Checks__ParentLawBlocksCompletion();
    error Checks__ExecutionGapTooSmall();
    error Checks__ProposalNotSucceeded();
    error Checks__DeadlineNotPassed();
    
    /////////////////////////////////////////////////////////////
    //                  CHECKS                                 //
    /////////////////////////////////////////////////////////////
    /// @notice Runs checks before executing a law
    /// @param lawId The id of the law
    /// @param lawCalldata The calldata of the law
    /// @param powers The address of the Powers contract
    /// @param nonce The nonce of the law
    /// @param latestFulfillment The latest fulfillment of the law
    function check(
        uint16 lawId,
        bytes memory lawCalldata,
        address powers,
        uint256 nonce,
        uint48 latestFulfillment
    ) external view {
        PowersTypes.Conditions memory conditions = getConditions(powers, lawId);
        // Check if parent law completion is required
        if (conditions.needFulfilled != 0) {
            PowersTypes.ActionState stateLog =
                Powers(payable(powers)).getActionState(hashActionId(conditions.needFulfilled, lawCalldata, nonce));
            if (stateLog != PowersTypes.ActionState.Fulfilled) {
                revert Checks__ParentLawNotCompleted();
            }
        }

        // Check if parent law must not be completed
        if (conditions.needNotFulfilled != 0) {
            PowersTypes.ActionState stateLog =
                Powers(payable(powers)).getActionState(hashActionId(conditions.needNotFulfilled, lawCalldata, nonce));
            if (stateLog == PowersTypes.ActionState.Fulfilled) {
                revert Checks__ParentLawBlocksCompletion();
            }
        }

        // Check execution throttling
        if (conditions.throttleExecution != 0) {
            if (
                latestFulfillment > 0 && block.number - latestFulfillment < conditions.throttleExecution
            ) {
                revert Checks__ExecutionGapTooSmall();
            }
        }

        // Check if proposal vote succeeded
        if (conditions.quorum != 0) {
            if (
                Powers(payable(powers)).getActionState(hashActionId(lawId, lawCalldata, nonce))
                    != PowersTypes.ActionState.Succeeded
            ) {
                revert Checks__ProposalNotSucceeded();
            }
        }

        // Check execution delay after proposal
        if (conditions.delayExecution != 0) {

            (, , uint256 deadline, , , ) = Powers(payable(powers)).getActionVoteData(hashActionId(lawId, lawCalldata, nonce));
            if (deadline + conditions.delayExecution > block.number) {
                revert Checks__DeadlineNotPassed();
            }
        }
    }

    ///////////////////////////////////////////////////////////// 
    //                  SIGNATURE VALIDATION                   //
    /////////////////////////////////////////////////////////////
    

    /////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        //
    /////////////////////////////////////////////////////////////
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

    function getConditions(address powers, uint16 lawId)
        public
        view
        returns (PowersTypes.Conditions memory conditions)
    {
        return Powers(payable(powers)).getConditions(lawId);
    }
}
