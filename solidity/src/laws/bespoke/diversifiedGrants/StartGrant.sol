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

// open zeppelin contracts
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StartGrant is Law {
    LawConfig public configNewGrants; // config for new grants.

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_, // this is the configuration for creating new grants, not of the grants themselves.
        address proposals // the address where proposals to the grant are made.
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        inputParams = abi.encode(
            "string Name", // name
            "string Description", // description
            "uint48 Duration", // duration
            "uint256 Budget", // budget
            "address Erc20Token", // tokenAddress
            "uint32 GrantCouncilId", // allowedRole
            "address Proposals" // proposals
        );
        stateVars = inputParams; // Note: stateVars == inputParams.

        // note: the configuration of grants is set here inside the law itself...
        configNewGrants.quorum = 80;
        configNewGrants.succeedAt = 66;
        configNewGrants.votingPeriod = 25;
        configNewGrants.needCompleted = proposals;
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        (
            string memory name,
            string memory description,
            uint48 duration,
            uint256 budget,
            address tokenAddress,
            uint32 grantCouncil, 
            address proposals
        ) = abi.decode(lawCalldata, (string, string, uint48, uint256, address, uint32, address));
 
        // step 0: run additional checks
        // - if budget of grant does not exceed available funds.
        if ( budget > ERC20(tokenAddress).balanceOf(powers) ) {
            revert ("Request amount exceeds available funds."); 
        }

        // step 1: calculate address at which grant will be created.
        address grantAddress =
            getGrantAddress(name, description, duration, budget, tokenAddress, grantCouncil, proposals);

        // step 2: if address is already in use, revert.
        uint256 codeSize = grantAddress.code.length;
        if (codeSize > 0) {
            revert ("Grant address already exists");
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.adoptLaw.selector, grantAddress);
        stateChange = lawCalldata;

        // step 5: return data
        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
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
        Grant newGrant = new Grant{ salt: bytes32(keccak256(abi.encodePacked(name, description))) }(
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
