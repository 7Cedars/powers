// todo.
// link to NominateMe
// save cast vote on address.
// log if address has voted.
// disallow repeated votes.

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

/// @notice Natspecs are tbi. 
///
/// @author 7Cedars

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { NominateMe } from "./NominateMe.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract ElectionVotes is Law { 
    // the state vars that this law manages: community strings.
    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public votes;
    uint48 public immutable startVote;
    uint48 public immutable endVote;

    event ElectionVotes__VoteCast(address voter);

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint256 allowedRole_,
        LawUtilities.Conditions memory config_,
        // bespoke params
        uint48 startVote_,
        uint48 endVote_
    ) Law(name_, powers_, allowedRole_, config_) {
        startVote = startVote_;
        endVote = endVote_;

        bytes memory params = abi.encode(
            "address VoteFor"
        );

        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    function handleRequest(address caller, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: run additional checks
        if (block.number < startVote || block.number > endVote) {
            revert ("Election not open.");
        }
        if (hasVoted[caller]) {
            revert ("Already voted.");
        }

        // step 1: decode law calldata
        (address vote) = abi.decode(lawCalldata, (address));
        // step 2: create & data arrays 
        stateChange = abi.encode(vote, caller);
        actionId = LawUtilities.hashActionId(address(this), lawCalldata, nonce);
        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes memory stateChange) internal override {
        (address nominee, address caller) = abi.decode(stateChange, (address, address));
        uint48 since = NominateMe(conditions.readStateFrom).nominees(nominee);

        // step 3: save vote
        if (since == 0) {
            revert ("Not a nominee.");
        }

        hasVoted[caller] = true;
        votes[nominee]++;
        emit ElectionVotes__VoteCast(caller);
    }

    
}
