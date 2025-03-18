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
pragma solidity 0.8.26;

// protocol
import { Law } from "../../../Law.sol";
import { Powers} from "../../../Powers.sol";

import { Grant } from "./Grant.sol";
import { StartGrant } from "./StartGrant.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { LawUtils } from "../../LawUtils.sol";

contract StopGrant is Law {
    LawChecks public configNewGrants; // config for new grants.
    
    constructor(
        string memory name_,    
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawChecks memory config_ // this is the configuration for creating new grants, not of the grants themselves.
    ) Law(name_, powers_, allowedRole_, config_) {

        bytes memory params = abi.encode(
            "string Name", // name
            "string Description", // description
            "uint48 Duration", // duration
            "uint256 Budget", // budget
            "address Erc20Token", // tokenAddress
            "uint32 GrantCouncilId", // allowedRole
            "address Proposals" // proposals
        );
        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);

        (
            configNewGrants.needCompleted,
            , 
            , 
            ,
            configNewGrants.votingPeriod,
            configNewGrants.quorum,
            configNewGrants.succeedAt,
            ) = StartGrant(config.needCompleted).configNewGrants(); 
    }

    function handleRequest(address, /*initiator*/ bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: create actionId & decode data from stateChange
        actionId = LawUtils.hashActionId(address(this), lawCalldata, nonce);
        (
            string memory name,
            string memory description,
            uint48 duration,
            uint256 budget,
            address tokenAddress,
            uint32 grantCouncil, 
            address proposals 
        ) = abi.decode(lawCalldata, (string, string, uint48, uint256, address, uint32, address));

        // step 1: calculate address at which grant will be created.
        address grantAddress = StartGrant(config.needCompleted).getGrantAddress(
            name, description, duration, budget, tokenAddress, grantCouncil, proposals
            );

        // step 2: run additional checks
        if (
            budget != Grant(grantAddress).spent() && 
            Grant(grantAddress).expiryBlock() > uint48(block.number)
        ) {
            revert ("Grant not expired."); 
        }

        // step 3: create arrays
        (targets, values, calldatas) = LawUtils.createEmptyArrays(1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.revokeLaw.selector, grantAddress);

        // step 5: return data
        return (actionId, targets, values, calldatas, stateChange);
    }
}
