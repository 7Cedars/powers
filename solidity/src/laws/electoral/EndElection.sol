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

/// @title EndElection - Law for Stopping Elections in the Powers Protocol
/// @notice This law allows the stopping of elections in the Powers protocol
/// @dev Handles the dynamic configuration and stopping of elections
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { ILaw } from "../../interfaces/ILaw.sol";
import { StartElection } from "./StartElection.sol";
import { VoteOnAccounts } from "../state/VoteOnAccounts.sol";
import { NominateMe } from "../state/NominateMe.sol";

contract EndElection is Law {
    /// @notice Constructor for the EndElection contract
    /// @param name_ Name of the law
    struct Data {
        uint256 maxRoleHolders;
        uint256 roleId;
        address[] electedAccounts;
    }
    mapping(bytes32 lawHash => Data) internal data;


    struct Mem {
        bytes32 lawHash;
        uint16 needCompleted;
        uint48 startElection;
        uint48 endElection;
        string electionDescription;
        uint16 startElectionId;
        address startElectionLaw;
        bytes32 startElectionLawHash;
        uint16 nominateMeId;
        address nominateMeLaw;
        bytes32 nominateMeHash;
        uint16 VoteOnAccountsId;
        address VoteOnAccountsLaw;
        bytes32 VoteOnAccountsHash;
        address[] nominees;
        uint256 numberRevokees;
        uint256 arrayLength;
        address[] accountElects;
        uint48 startVoteLeft;
        uint48 endVoteLeft;
    }

    constructor() {
        bytes memory configParams = abi.encode("uint256 MaxRoleHolders", "uint256 RoleId");
        emit Law__Deployed(configParams);
    }

    /// @notice Initializes the law with its configuration
    /// @param index Index of the law
    /// @param nameDescription Name of the law
    /// @param conditions Conditions for the law. NOTE: in this case the 'NeedCompleted' condition needs to be the 'StartElection' law.
    /// @param config Configuration data
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        inputParams = abi.encode("uint48 startVote", "uint48 endVote", "string Description");

        super.initializeLaw(
            index, 
            nameDescription,
            inputParams,
            conditions,
            config
        );
    }

    /// @notice Handles the request to adopt a new law
    /// @param caller Address initiating the request
    /// @param lawId ID of this law
    /// @param lawCalldata Encoded data containing the law to adopt and its configuration
    /// @param nonce Nonce for the action
    /// @return actionId ID of the created action
    /// @return targets Array of target addresses
    /// @return values Array of values to send
    /// @return calldatas Array of calldata for the calls
    /// @return stateChange State changes to apply
    function handleRequest(
        address caller,
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
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
        Mem memory mem;

        // load data to memory & do checks 
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        mem.startElectionId = laws[mem.lawHash].conditions.needCompleted; // needCompleted is the startElection law.
        mem.nominateMeId = laws[mem.lawHash].conditions.readStateFrom; // readStateFrom is the nominateMe law.
        if (mem.startElectionId == 0) {
            revert("NeedCompleted condition not set.");
        }
        if (mem.nominateMeId == 0) {
            revert("readStateFrom condition not set.");
        }

        (mem.startElection, mem.endElection, mem.electionDescription) = abi.decode(lawCalldata, (uint48, uint48, string));
        // check if election has started
        if (block.number < mem.startElection) {
            revert("Election not open.");
        }
        // check if election has ended
        if (block.number < mem.endElection) {
            revert("Election has not ended.");
        }

        // Retrieving & calculating law id, addresses and hashes.  
        (mem.startElectionLaw, , ) = Powers(payable(powers)).getActiveLaw(mem.startElectionId);
        (mem.nominateMeLaw, , ) = Powers(payable(powers)).getActiveLaw(mem.nominateMeId);

        mem.startElectionLawHash = LawUtilities.hashLaw(powers, mem.startElectionId);
        mem.nominateMeHash = LawUtilities.hashLaw(powers, mem.nominateMeId);

        mem.VoteOnAccountsId = StartElection(mem.startElectionLaw).getElectionId(mem.startElectionLawHash, lawCalldata);
        (mem.VoteOnAccountsLaw, , ) = Powers(payable(powers)).getActiveLaw(mem.VoteOnAccountsId);
        mem.VoteOnAccountsHash = LawUtilities.hashLaw(powers, mem.VoteOnAccountsId);

        // Executing electoral Tally: calculating number of calls to make. 
        mem.nominees = NominateMe(mem.nominateMeLaw).getNominees(mem.nominateMeHash);
        mem.numberRevokees = data[mem.lawHash].electedAccounts.length;
        mem.arrayLength = mem.nominees.length < data[mem.lawHash].maxRoleHolders
            ? mem.numberRevokees + mem.nominees.length + 1
            : mem.numberRevokees + data[mem.lawHash].maxRoleHolders + 1;

        // Setting up the empty arrays to be filled out for call back to powers. 
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(mem.arrayLength);
        for (uint256 i; i < mem.arrayLength; i++) {
            targets[i] = powers;
        }

        // step 2: calls to revoke roles of previously elected accounts & delete array that stores elected accounts.
        for (uint256 i; i < mem.numberRevokees; i++) {
            calldatas[i] = abi.encodeWithSelector(
                Powers.revokeRole.selector, data[mem.lawHash].roleId, data[mem.lawHash].electedAccounts[i]
            );
        }

        // step 3: calls to add nominees if fewer than MAX_ROLE_HOLDERS
        if (mem.nominees.length < data[mem.lawHash].maxRoleHolders) {
            mem.accountElects = new address[](mem.nominees.length);
            for (uint256 i; i < mem.nominees.length; i++) {
                address accountElect = mem.nominees[i];
                calldatas[i + mem.numberRevokees] =
                    abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleId, accountElect);
                mem.accountElects[i] = accountElect;
            }
        } else {
            // retrieve votes from VoteOnAccounts
            mem.accountElects = new address[](data[mem.lawHash].maxRoleHolders);
            uint256[] memory _votes = new uint256[](mem.nominees.length);
            address[] memory _nominees = mem.nominees;

            for (uint256 i; i < mem.nominees.length; i++) {
                _votes[i] = VoteOnAccounts(mem.VoteOnAccountsLaw).getVotes(mem.VoteOnAccountsHash, _nominees[i]);
            }

            // note how the following mechanism works:
            // a. we add 1 to each nominee's position, if we found a account that holds more tokens.
            // b. if the position is greater than MAX_ROLE_HOLDERS, we break. (it means there are more accounts that have more tokens than MAX_ROLE_HOLDERS)
            // c. if the position is less than MAX_ROLE_HOLDERS, we assign the roles.
            uint256 index;
            for (uint256 i; i < mem.nominees.length; i++) {
                uint256 rank;
                // a: loop to assess ranking.
                for (uint256 j; j < mem.nominees.length; j++) {
                    if (j != i && _votes[j] >= _votes[i]) {
                        rank++;
                        if (rank > data[mem.lawHash].maxRoleHolders) break; // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold.
                    }
                }
                // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
                if (rank < data[mem.lawHash].maxRoleHolders && index < mem.arrayLength - mem.numberRevokees) {
                    calldatas[index + mem.numberRevokees] =
                        abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleId, _nominees[i]);
                    mem.accountElects[index] = _nominees[i];
                    index++;
                }
            }
        }

        // Set the state change to the accountElects array
        stateChange = abi.encode(mem.accountElects);

        // Set up the call to revoke the election law in Powers contract
        calldatas[mem.arrayLength - 1] = abi.encodeWithSelector(
            Powers.revokeLaw.selector,
            mem.VoteOnAccountsId
        );

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address[] memory accountElects) = abi.decode(stateChange, (address[]));
        for (uint256 i; i < data[lawHash].electedAccounts.length; i++) {
            data[lawHash].electedAccounts.pop();
        }
        data[lawHash].electedAccounts = accountElects;
    }
}
