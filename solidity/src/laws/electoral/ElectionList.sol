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

/// @notice This contract that lists the nominees for an election and allows voters to vote on them. 
/// - When the law is adopted the following config params are set:
///    - the ElectionVetting law address used to get nominees.

/// - the InputParams are the following: 
///    - the list of nominees taken from the ElectionVetting law. This is ReadStateFrom!

/// the logic of the law: 
/// - The inputParams are _Dynamic_. As many bool options will appear as there are nominees. 
/// - when a voter selects more than one nominee, the law will revert. 
/// - when a vote is cast, the law will register the vote + that the voter has voted. 
/// - only one vote per voter is allowed. 

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { ElectionStart } from "./ElectionStart.sol";
import { NominateMe } from "../state/NominateMe.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

contract ElectionList is Law {
    struct MemoryData {
        address caller;
        bytes32 lawHash;
        Conditions conditions;
        uint16 startElectionId;
        address startElectionAddress;
        bytes32 startElectionHash;
        bool active;
        // 
        uint48 startElection;
        uint48 endElection;
        uint16 roleId;
        address nominateMeAddress;
        bytes32 nominateMeHash;
        //
        address[] nominees;
        string[] nomineeList;
        // 
        bool[] vote;
        uint256 numVotes;
        uint256 i;
    }
    
    struct Data {
        mapping(address nominee => uint256 votes) votes;
        mapping(address voter => bool voted) voted;
        address[] nominees;
        uint48 startElection;
        uint48 endElection;
        uint16 roleId;
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
        (mem.startElectionAddress, mem.startElectionHash, mem.active) = Powers(payable(msg.sender)).getActiveLaw(conditions.readStateFrom);
        // checking if StartElection law is set correctly. 
        if (!mem.active) {
            revert ("No valid StartElection law provided.");
        }
        // loading data from StartElection law. 
        (
            mem.startElection, 
            mem.endElection, 
            mem.roleId, 
            , 
            mem.nominateMeAddress, 
            mem.nominateMeHash
            ) = ElectionStart(payable(mem.startElectionAddress)).getElectionData(mem.startElectionHash);
        if (block.number > mem.startElection) {
            revert ("Election start block has already passed.");
        }
        (mem.nominees) = NominateMe(payable(mem.nominateMeAddress)).getNominees(mem.nominateMeHash);

        // saving data to state. 
        mem.lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[mem.lawHash].nominees = mem.nominees;
        data[mem.lawHash].startElection = mem.startElection;
        data[mem.lawHash].endElection = mem.endElection;
        data[mem.lawHash].roleId = mem.roleId;

        // creating inputParams. 
        // string memory description = string.concat("request payment at block: ", Strings.toString(block.number));
        mem.nomineeList = new string[](mem.nominees.length);
        for (uint256 i = 0; i < mem.nominees.length; i++) {
            mem.nomineeList[i] = string.concat("bool ", Strings.toHexString(mem.nominees[i]));
        }
        inputParams = abi.encode(mem.nomineeList);

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);    
    }

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
        // step 1: decode the calldata & create hashes .
        MemoryData memory mem;

        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        // note that this 
        (mem.vote) = LawUtilities.arrayifyBools(data[mem.lawHash].nominees.length);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // step 2: check if the voter has already voted.
        if (data[mem.lawHash].voted[caller]) {
            revert ("Voter has already voted.");
        }
        if (block.number < data[mem.lawHash].startElection) {
            revert ("Election has not started yet.");
        }
        if (block.number > data[mem.lawHash].endElection) {
            revert ("Election has ended.");
        }

        // step 3: check if the voter has voted for more than one nominee.
        mem.numVotes = 0;
        for (mem.i = 0; mem.i < mem.vote.length; mem.i++) {
            if (mem.vote[mem.i]) {
                mem.numVotes++;
                if (mem.numVotes > 1) {
                    revert ("Voter has voted for more than one nominee.");
                }
            }
        }

        // step 4: set the state change.
        // the state change is the caller and the vote.
        stateChange = abi.encode(caller, mem.vote);
        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        MemoryData memory mem;
        (mem.caller, mem.vote) = abi.decode(stateChange, (address, bool[]));
        for (mem.i = 0; mem.i < mem.vote.length; mem.i++) {
            if (mem.vote[mem.i]) {
                data[lawHash].votes[data[lawHash].nominees[mem.i]]++;
                data[lawHash].voted[mem.caller] = true;
            }
        }
    }

    function getElectionData(bytes32 lawHash) public view returns (address[] memory nominees, uint48 startElection, uint48 endElection) {
        return (data[lawHash].nominees, data[lawHash].startElection, data[lawHash].endElection);
    }

    function getElectionTally(bytes32 lawHash) public view returns (address[] memory nominees, uint256[] memory votes) {
        MemoryData memory mem;

        nominees = new address[](data[lawHash].nominees.length);
        votes = new uint256[](data[lawHash].nominees.length);

        for (mem.i = 0; mem.i < data[lawHash].nominees.length; mem.i++) {
            nominees[mem.i] = data[lawHash].nominees[mem.i];
            votes[mem.i] = data[lawHash].votes[data[lawHash].nominees[mem.i]];
        }
    }
}
