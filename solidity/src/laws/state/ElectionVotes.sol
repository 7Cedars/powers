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
import { Powers } from "../../Powers.sol";
import { NominateMe } from "./NominateMe.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract ElectionVotes is Law { 
    // the state vars that this law manages: community strings.
    mapping(bytes32 lawHash => mapping(address caller => bool hasVoted)) public hasVoted;
    mapping(bytes32 lawHash => mapping(address nominee => uint256 votes)) public votes;
    mapping(bytes32 lawHash => uint48 startVote) public startVote;
    mapping(bytes32 lawHash => uint48 endVote) public endVote;

    event ElectionVotes__VoteCast(address voter);

    constructor(
        string memory name_,
        string memory description_
    ) Law(name_) {
        bytes memory configParams = abi.encode(
            "uint48 startVote",
            "uint48 endVote"
        );
        emit Law__Deployed(name_, description_, configParams);
    }

    function initializeLaw(uint16 index, Conditions memory conditions, bytes memory config, bytes memory inputParams) public override {
        (uint48 startVote_, uint48 endVote_) = abi.decode(config, (uint48, uint48));
        startVote[hashLaw(msg.sender, index)] = startVote_;
        endVote[hashLaw(msg.sender, index)] = endVote_;
        
        inputParams = abi.encode(
            "address VoteFor"
        );
        super.initializeLaw(index, conditions, config, inputParams);
    }
    function handleRequest(address caller, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        bytes32 lawHash = LawUtilities.hashLaw(caller, lawId);
        uint16 nomineesId = conditionsLaws[lawHash].readStateFrom; 
        (address nomineesContract, , ) = Powers(payable(msg.sender)).getActiveLaw(nomineesId);

        // step 0: run additional checks
        if (block.number < startVote[lawHash] || block.number > endVote[lawHash]) {
            revert ("Election not open.");
        }
        if (hasVoted[lawHash][caller]) {
            revert ("Already voted.");
        }

        // step 1: decode law calldata
        (address vote) = abi.decode(lawCalldata, (address));
        // step 2: create & data arrays 
        stateChange = abi.encode(vote, caller, nomineesContract);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address nominee, address caller, address nomineesContract) = abi.decode(stateChange, (address, address, address));
        bool isNominee = NominateMe(nomineesContract).isNominee(lawHash, nominee);

        // step 3: save vote
        if (!isNominee) {
            revert ("Not a nominee.");
        }

        hasVoted[lawHash][caller] = true;
        votes[lawHash][nominee]++;
        emit ElectionVotes__VoteCast(caller);
    }

    
}
