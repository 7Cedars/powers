// SPDX-License-Identifier: MIT

/// @notice Allows voters to vote on nominees from a standalone OpenElection contract.
///
/// The logic:
/// - The inputParams are dynamic - as many bool options will appear as there are nominees.
/// - When a voter selects more than one nominee, the mandate will revert.
/// - When a vote is cast, the mandate calls the vote function in OpenElection contract.
/// - Only one vote per voter is allowed per election.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { OpenElection } from "../../helpers/OpenElection.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract OpenElectionVote is Mandate {
    struct Mem {
        address caller;
        bytes32 mandateHash;
        address[] nominees;
        string[] nomineeList;
        bool[] vote;
        uint256 numVotes;
        uint256 i;
        address openElectionContract;
        uint256 maxVotes;
        uint256 electionId;
    }

    /// @notice Constructor for OpenElectionVote mandate
    constructor() {
        bytes memory configParams = abi.encode("address OpenElectionContract", "uint256 maxVotes");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        Mem memory mem;
        (mem.openElectionContract,  ) = abi.decode(config, (address, uint256));

        // Check if election is open - otherwise revert. 
        if (
                !OpenElection(mem.openElectionContract).isElectionOpen()
            ) {
                revert("Election is not open.");
        }

        // Get nominees from the OpenElection contract
        mem.nominees = OpenElection(mem.openElectionContract).getNominees();
        mem.electionId = OpenElection(mem.openElectionContract).currentElectionId();

        // Create dynamic inputParams based on nominees
        mem.nomineeList = new string[](mem.nominees.length);
        for (uint256 i = 0; i < mem.nominees.length; i++) {
            mem.nomineeList[i] = string.concat("bool ", Strings.toHexString(mem.nominees[i]));
        }
        inputParams = abi.encode(mem.nomineeList);
        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Build a call to cast a vote in the OpenElection contract
    /// @param caller The voter address
    /// @param powers The Powers contract address (unused here, forwarded in action context)
    /// @param mandateId The mandate identifier
    /// @param mandateCalldata Encoded bool[] where each index corresponds to a nominee
    /// @param nonce Unique nonce to build the action id
    function handleRequest(address caller, address powers, uint16 mandateId, bytes memory mandateCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem; 

        // Decode the vote data
        (mem.vote) = abi.decode(mandateCalldata, (bool[]));
        actionId = MandateUtilities.computeActionId(mandateId, mandateCalldata, nonce);
        (mem.openElectionContract, mem.maxVotes) = abi.decode(getConfig(powers, mandateId), (address, uint256));
        mem.nominees = OpenElection(mem.openElectionContract).getNominees();
    
        // Check if election is open
        if (!OpenElection(mem.openElectionContract).isElectionOpen()) {
            revert("Election is not open.");
        }

        // Validate vote length matches nominees length
        if (mem.vote.length != mem.nominees.length) {
            revert("Invalid vote length.");
        }

        // Check if the voter has voted for more than one nominee
        mem.numVotes = 0;
        for (mem.i = 0; mem.i < mem.vote.length; mem.i++) {
            if (mem.vote[mem.i]) {
                mem.numVotes++;
                if (mem.numVotes > mem.maxVotes) {
                    revert("Voter tries to vote for more than maxVotes nominees.");
                }
            }
        }

        // create call for
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
        targets[0] = mem.openElectionContract;
        calldatas[0] = abi.encodeWithSelector(OpenElection.vote.selector, caller, mem.vote);

        return (actionId, targets, values, calldatas);
    }
}
