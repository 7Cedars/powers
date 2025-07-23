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

/// @notice This law is a work in progress. 
///
/// @author 7Cedars

/// @notice This contract that tallies the votes for an election. 
/// - When the law is adopted the following config params are set:
///    - the ElectionList law address used to get the list of nominees.
///    - the roleId to be assigned. 
///    - the max number of nominees to be assigned. 

/// - the InputParams are the following: 
///    - none. 

/// the logic of the law: 
/// - If the election has not ended yet, the law will revert. 
/// - the law counts the votes, and assigns the top N nominees to the roleId. 

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { ElectionList } from "./ElectionList.sol";
import { ElectionStart } from "./ElectionStart.sol";
import { NominateMe } from "../state/NominateMe.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

contract ElectionTally is Law {
    struct Data {
        uint256 roleId;
        uint32 maxToElect;
        address[] nominees;
        address[] electedAccounts;
        uint48 endElection;
    }

    struct MemoryData {
        bytes32 lawHash;
        Conditions conditions;
        // 
        uint16 electionListId;
        address electionListAddress;
        bytes32 electionListHash;
        bool electionListActive;
        // 
        uint16 electionStartId;
        address electionStartAddress;
        bytes32 electionStartHash;
        bool electionStartActive;
        // 
        address nominateMeAddress;
        bytes32 nominateMeHash;
        // 
        uint256 roleId;
        uint32 maxToElect;
        address[] nominees;
        uint256[] votes;
        uint48 startElection;
        uint48 endElection;
        // 
        uint256 arrayLength;
        uint256 numberRevokees;
        address[] electedAccounts;
    }

    mapping(bytes32 lawHash => Data) public data;

    constructor() {
        emit Law__Deployed("");
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        MemoryData memory mem;
        mem.lawHash = LawUtilities.hashLaw(msg.sender, index);
        mem.conditions = conditions;
        // get the election list address.
        mem.electionListId = mem.conditions.readStateFrom;
        (mem.electionListAddress, mem.electionListHash, mem.electionListActive) = Powers(payable(msg.sender)).getActiveLaw(mem.electionListId);
         
        // get the election start address.
        mem.electionStartId = ElectionList(mem.electionListAddress).getConditions(msg.sender, mem.electionListId).readStateFrom;
        (mem.electionStartAddress, mem.electionStartHash, mem.electionStartActive) = Powers(payable(msg.sender)).getActiveLaw(mem.electionStartId);
        if (!mem.electionStartActive) {
            revert ("No valid ElectionStart law provided.");
        }
        // retrieve the election data.
        (
            mem.startElection, 
            mem.endElection, 
            mem.roleId, 
            mem.maxToElect, 
            mem.nominateMeAddress, 
            mem.nominateMeHash
            ) = ElectionStart(mem.electionStartAddress).getElectionData(mem.electionStartHash);
        mem.nominees = NominateMe(mem.nominateMeAddress).getNominees(mem.nominateMeHash);
        mem.electedAccounts = new address[](0);
        
        data[mem.lawHash] = Data({
            roleId: mem.roleId,
            maxToElect: mem.maxToElect,
            nominees: mem.nominees,
            electedAccounts: mem.electedAccounts,
            endElection: mem.endElection
        }); 
        super.initializeLaw(index, nameDescription, abi.encode(), conditions, config);    }

    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        MemoryData memory mem;

        // step 1: decode the calldata & create hashes .
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        mem.conditions = laws[mem.lawHash].conditions;        
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        
        // step 2: check if the election has ended.
        mem.electionListId = mem.conditions.readStateFrom;
        if (block.number < data[mem.lawHash].endElection) {
            revert ("Election has not ended.");
        }

        // step 3: get the nominees and votes tally.
        (mem.electionListAddress, mem.electionListHash, ) = Powers(payable(powers)).getActiveLaw(mem.electionListId);
        (mem.nominees, mem.votes) = ElectionList(payable(mem.electionListAddress)).getElectionTally(mem.electionListHash);

        ///////////////////////////////////////////////
        //              ELECT ACCOUNTS               //   
        /////////////////////////////////////////////// 
        // step 1: setting up array for revoking & assigning roles.
        mem.numberRevokees = data[mem.lawHash].electedAccounts.length;
        mem.arrayLength = mem.nominees.length < data[mem.lawHash].maxToElect
            ? mem.numberRevokees + mem.nominees.length + 2 // have to add calls to remove election tally and list laws. 
            : mem.numberRevokees + data[mem.lawHash].maxToElect + 2; // have to add calls to remove election tally and list laws. 

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(mem.arrayLength);
        for (uint256 i; i < mem.arrayLength; i++) {
            targets[i] = powers;
        }
        // step 2: calls to revoke roles of previously elected accounts
        for (uint256 i; i < mem.numberRevokees; i++) {
            calldatas[i] = abi.encodeWithSelector(
                Powers.revokeRole.selector, data[mem.lawHash].roleId, data[mem.lawHash].electedAccounts[i]
            );
        }

        // step 3a: calls to add nominees if fewer than MAX_ROLE_HOLDERS
        if (mem.nominees.length < data[mem.lawHash].maxToElect) {
            mem.electedAccounts = new address[](mem.nominees.length); 
            for (uint256 i; i < mem.nominees.length; i++) {
                address accountElect = mem.nominees[i];
                calldatas[i + mem.numberRevokees] =
                    abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleId, accountElect);
                mem.electedAccounts[i] = accountElect;
            }

         // step 3b: calls to add nominees if more than MAX_ROLE_HOLDERS
        } else {
            // retrieve balances of delegated votes of nominees.
            mem.electedAccounts = new address[](data[mem.lawHash].maxToElect); 

            // note how the following mechanism works:
            // a. we add 1 to each nominee's position, if we found a account that holds more tokens.
            // b. if the position is greater than MAX_ROLE_HOLDERS, we break. (it means there are more accounts that have more tokens than MAX_ROLE_HOLDERS)
            // c. if the position is less than MAX_ROLE_HOLDERS, we assign the roles.
            uint256 index;
            for (uint256 i; i < mem.nominees.length; i++) {
                uint256 rank;
                // a: loop to assess ranking.
                for (uint256 j; j < mem.nominees.length; j++) {
                    if (j != i && mem.votes[j] >= mem.votes[i]) {
                        rank++;
                        if (rank > data[mem.lawHash].maxToElect) break; // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold.
                    }
                }
                // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
                if (rank < data[mem.lawHash].maxToElect && index < mem.arrayLength - mem.numberRevokees) {
                    calldatas[index + mem.numberRevokees] =
                        abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleId, mem.nominees[i]);
                    mem.electedAccounts[index] = mem.nominees[i];
                    index++;
                }
            }
        }
        // step 4: calls to remove election tally and list laws.
        calldatas[mem.arrayLength - 2] = abi.encodeWithSelector(Powers.revokeLaw.selector, mem.electionListId);
        calldatas[mem.arrayLength - 1] = abi.encodeWithSelector(Powers.revokeLaw.selector, lawId);

        stateChange = abi.encode(mem.electedAccounts);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address[] memory electedAccounts) = abi.decode(stateChange, (address[]));
        // delete the previous elected accounts.
        for (uint256 i; i < data[lawHash].electedAccounts.length; i++) {
            data[lawHash].electedAccounts.pop();
        }
        // update the elected accounts.
        data[lawHash].electedAccounts = electedAccounts;
    }

    function getElectedAccounts(bytes32 lawHash) public view returns (address[] memory) {
        return data[lawHash].electedAccounts;
    }
}
