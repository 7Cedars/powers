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

// import "forge-std/console.sol"; // remove before deploying

contract VoteOnAccounts is Law {
    struct Data {
        uint48 startVote;
        uint48 endVote;
    }
    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 lawHash => mapping(address nominee => uint256 votes)) internal votes;
    mapping(bytes32 lawHash => mapping(address caller => bool hasVoted)) internal hasVoted;

    event VoteOnAccounts__VoteCast(address voter);

    constructor() {
        bytes memory configParams = abi.encode("uint48 startVote", "uint48 endVote");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (uint48 startVote_, uint48 endVote_) = abi.decode(config, (uint48, uint48));
        data[LawUtilities.hashLaw(msg.sender, index)] = Data({startVote: startVote_, endVote: endVote_});

        inputParams = abi.encode("address VoteFor");
        super.initializeLaw(index, nameDescription, inputParams, conditions, config);    }

    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        uint16 nominateMeId = laws[lawHash].conditions.readStateFrom;
        (address nomineesContract,,) = Powers(payable(powers)).getActiveLaw(nominateMeId);
        bytes32 nominateMeHash = LawUtilities.hashLaw(powers, nominateMeId);
        // step 0: run additional checks
        if (block.number < data[lawHash].startVote || block.number > data[lawHash].endVote) {
            revert("Election not open.");
        }
        if (hasVoted[lawHash][caller]) {
            revert("Already voted.");
        }

        // step 1: decode law calldata
        (address vote) = abi.decode(lawCalldata, (address));

        // step 2: create & data arrays
        stateChange = abi.encode(vote, caller, nomineesContract, nominateMeHash);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address vote, address caller, address nomineesContract, bytes32 nominateMeHash) =
            abi.decode(stateChange, (address, address, address, bytes32));

        bool isNominee = NominateMe(nomineesContract).isNominee(nominateMeHash, vote);

        // step 3: save vote
        if (!isNominee) {
            revert("Not a nominee.");
        }

        hasVoted[lawHash][caller] = true;
        votes[lawHash][vote]++;
        emit VoteOnAccounts__VoteCast(caller);
    }

    function getData(bytes32 lawHash) external view returns (Data memory) {
        return data[lawHash];
    }

    function getVotes(bytes32 lawHash, address nominee) external view returns (uint256) {   
        return votes[lawHash][nominee];
    }

    function getHasVoted(bytes32 lawHash, address caller) external view returns (bool) {
        return hasVoted[lawHash][caller];
    }
}
