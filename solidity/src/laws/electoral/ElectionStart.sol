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

/// @notice This contract that vetting a nominees for an election.
/// - When the law is adopted the following config params are set:
///    - the NominateMe law that is used to nominate candidates. -- = readStateFrom!  

/// - the InputParams are the following: 
///    - the list of nominees to select for the election.
///    - the start of the election (in block.number)
///    - the end of the election (in block.number)
///    - the description of the election. 

/// the logic of the law: 
/// - When the law is called, it checks if all listed nominees have indeed nomintaed themselves. If not, the law will revert.
/// - If this check passes, it will set the list of nominees, start and end time of the election in storage. 
/// - a subsequent law, ElectionList.sol reads this data to create a law where people can vote on nominees.  

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { ElectionList } from "./ElectionList.sol";
import { ElectionTally } from "./ElectionTally.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

contract ElectionStart is Law {

    struct Data {
        address electionListAddress;
        address electionTallyAddress;
        uint48 startElection;
        uint48 endElection;
        uint16 roleId;
        uint32 maxToElect;
        address nominateMeAddress;
        bytes32 nominateMeHash;
    }

    struct MemoryData {
        uint16 roleId;
        uint32 maxToElect;
        uint48 startElection;
        uint48 endElection;
        bool active;
        bytes32 lawHash;
        Conditions conditions;
        uint16 nominateMeId;
        address nominateMeAddress;
        bytes32 nominateMeHash;
        uint16 lawCount;
    }

    mapping(bytes32 lawHash => Data) public data;

    constructor() {
        emit Law__Deployed(abi.encode("address ElectionList", "address ElectionTally", "uint16 RoleId", "uint32 MaxToElect"));
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
        (address electionListAddress, address electionTallyAddress, uint16 roleId, uint32 maxToElect) = abi.decode(config, (address, address, uint16, uint32));
        data[mem.lawHash].electionListAddress = electionListAddress;
        data[mem.lawHash].electionTallyAddress = electionTallyAddress;
        data[mem.lawHash].roleId = roleId;
        data[mem.lawHash].maxToElect = maxToElect;

        inputParams = abi.encode("uint48 StartElection", "uint48 EndElection");
        
        super.initializeLaw(index, nameDescription, inputParams, conditions, config);    }

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

        // step 1: decode the calldata & create hashes.
        (mem.startElection, mem.endElection) = abi.decode(lawCalldata, (uint48, uint48));
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        mem.conditions = laws[mem.lawHash].conditions;
        mem.nominateMeId = mem.conditions.readStateFrom;
        (mem.nominateMeAddress, mem.nominateMeHash, mem.active) = Powers(payable(powers)).getActiveLaw(mem.nominateMeId);
        mem.lawCount = Powers(payable(powers)).lawCount();

        // step 2: checks 
        if (mem.startElection == 0 || mem.endElection == 0) {
            revert ("No valid start or end election provided.");
        }
        if (mem.startElection > mem.endElection) {  
            revert ("Start election is after end election.");
        }
        if (!mem.active) {
            revert ("No valid nominees contract provided"); 
        }

        // step 3: create election laws.
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(2);
        for (uint256 i; i < 2; i++) {
            targets[i] = powers;
            values[i] = 0;
        }

        calldatas[0] = abi.encodeWithSelector(
            Powers.adoptLaw.selector, 
            PowersTypes.LawInitData({
                nameDescription: "Election: Vote on nominated candidates.",
                targetLaw: data[mem.lawHash].electionListAddress,
                config: abi.encode(),
                conditions: Conditions({
                    allowedRole: type(uint256).max,
                    needCompleted: 0,
                    delayExecution: 0,
                    throttleExecution: 0,
                    readStateFrom: lawId,
                    votingPeriod: 0,
                    quorum: 0,
                    succeedAt: 0,
                    needNotCompleted: 0
                })
            })
        );

        calldatas[1] = abi.encodeWithSelector(
            Powers.adoptLaw.selector, 
            PowersTypes.LawInitData({
                nameDescription: "ElectionTally: Tally the votes of the election.",
                targetLaw: data[mem.lawHash].electionTallyAddress,
                config: abi.encode(),
                conditions: Conditions({
                    allowedRole: type(uint256).max,
                    needCompleted: 0,
                    delayExecution: 0,
                    throttleExecution: 0,
                    readStateFrom: mem.lawCount,
                    votingPeriod: 0,
                    quorum: 0,
                    succeedAt: 0,
                    needNotCompleted: 0
                })
            })
        );

        // step 4: set the state change. 
        stateChange = abi.encode(mem.startElection, mem.endElection, mem.nominateMeAddress, mem.nominateMeHash);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        MemoryData memory mem;
        (mem.startElection, mem.endElection, mem.nominateMeAddress, mem.nominateMeHash) = abi.decode(stateChange, (uint48, uint48, address, bytes32));

        data[lawHash].startElection = mem.startElection; // block.number
        data[lawHash].endElection = mem.endElection; // block.number
        data[lawHash].nominateMeAddress = mem.nominateMeAddress; // address
        data[lawHash].nominateMeHash = mem.nominateMeHash; // bytes32
    }

    function getElectionData(bytes32 lawHash) public view returns (
        uint48 startElection, 
        uint48 endElection, 
        uint16 roleId, 
        uint32 maxToElect, 
        address nominateMeAddress, 
        bytes32 nominateMeHash
        ) {
        // console2.log("getElectionData");
        // console2.log(data[lawHash].startElection);
        // console2.log(data[lawHash].endElection);
        // console2.log(data[lawHash].roleId);
        // console2.log(data[lawHash].maxToElect);
        // console2.log(data[lawHash].nominateMeAddress);
        // console2.logBytes32(data[lawHash].nominateMeHash);

        startElection = data[lawHash].startElection;
        endElection = data[lawHash].endElection;
        roleId = data[lawHash].roleId;
        maxToElect = data[lawHash].maxToElect;
        nominateMeAddress = data[lawHash].nominateMeAddress;
        nominateMeHash = data[lawHash].nominateMeHash;
    }
}
