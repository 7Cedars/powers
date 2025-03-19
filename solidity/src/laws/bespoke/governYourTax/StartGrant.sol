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
import { LawUtils } from "../../LawUtils.sol";
// open zeppelin contracts
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StartGrant is Law {
    LawChecks public configNewGrants; // config for new grants.

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint256 allowedRole_,
        LawChecks memory config_, // this is the configuration for creating new grants, not of the grants themselves.
        address proposals // the address where proposals to the grant are made.
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

        // note: the configuration of grants is set here inside the law itself...
        configNewGrants.quorum = 80;
        configNewGrants.succeedAt = 66;
        configNewGrants.votingPeriod = 25;
        configNewGrants.needCompleted = proposals;
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function handleRequest(address, /*caller*/ bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: create actionId & decode the calldata.
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
 
        // step 1: run additional checks
        // - if budget of grant does not exceed available funds.
        if ( budget > ERC20(tokenAddress).balanceOf(powers) ) {
            revert ("Request amount exceeds available funds."); 
        }
        if (proposals != configNewGrants.needCompleted) {
            revert ("Invalid proposal law.");
        }

        // step 2: calculate address at which grant will be created.
        address grantAddress =
            getGrantAddress(name, description, duration, budget, tokenAddress, grantCouncil, proposals);

        // step 3: if address is already in use, revert.
        uint256 codeSize = grantAddress.code.length;
        if (codeSize > 0) {
            revert ("Grant address already exists");
        }

        // step 4: create arrays
        (targets, values, calldatas) = LawUtils.createEmptyArrays(1);
        stateChange = abi.encode("");

        // step 5: fill out arrays with data
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.adoptLaw.selector, grantAddress);
        stateChange = lawCalldata;

        // step 6: return data
        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes memory stateChange) internal override {
        // step 0: decode data from stateChange
        (
            string memory name,
            string memory description,
            uint48 duration,
            uint256 budget,
            address tokenAddress,
            uint32 grantCouncil, 
            address proposals
        ) = abi.decode(stateChange, (string, string, uint48, uint256, address, uint32, address));

        // stp 1: deploy new grant
        _deployGrant(name, description, duration, budget, tokenAddress, grantCouncil, proposals);
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     * exact copy from SimpleAccountFactory.sol, except it takes loyaltyProgram as param
     */
    function getGrantAddress(
        string memory name,
        string memory description,
        uint48 duration,
        uint256 budget,
        address tokenAddress,
        uint32 grantCouncil, 
        address proposals
    ) public view returns (address) {
        address grantAddress = Create2.computeAddress(
            bytes32(keccak256(abi.encodePacked(name, description))),
            keccak256(
                abi.encodePacked(
                    type(Grant).creationCode,
                    abi.encode(
                        // standard params
                        name,
                        description,
                        powers,
                        grantCouncil,
                        configNewGrants,
                        // remaining params
                        duration,
                        budget,
                        tokenAddress,
                        proposals
                    )
                )
            )
        );

        return grantAddress;
    }

    function _deployGrant(
        string memory name,
        string memory description,
        uint48 duration,
        uint256 budget,
        address tokenAddress,
        uint32 grantCouncil,
        address proposals
    ) internal {
        new Grant{ salt: bytes32(keccak256(abi.encodePacked(name, description))) }(
            // standard params
            name,
            description,
            powers,
            grantCouncil,
            configNewGrants,
            // remaining params
            duration,
            budget,
            tokenAddress,
            proposals
        );
    }
}
