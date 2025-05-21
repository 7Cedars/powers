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

/// @notice This contract assigns accounts to roles based on their token holdings in a specified ERC20 token.
/// - At construction time, the following is set:
///    - the ERC20 token address to be assessed
///    - the minimum amount of tokens that needs to be held
///    - the roleId to be assigned
///
/// - The logic:
///    - The calldata holds the account that needs to be assessed.
///    - If the account holds more tokens than the threshold, it is assigned the role.
///    - If the account holds less tokens than the threshold, its role is revoked.
///
/// @dev The contract is an example of a law that
/// - has does not need a proposal to be voted through. It can be called directly.
/// - has a simple token-based role assignment mechanism.
/// - doess not have to role restricted.
/// - translates token holdings to role assignments.
/// - Note this logic can be extended to include more complex token-based role assignment mechanisms.

/// @author 7Cedars
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "forge-std/Test.sol"; // for testing

contract HolderSelect is Law {
    struct Data {
        address erc20Token;
        uint256 minimumTokens;
        uint256 roleIdToSet;
    }

    mapping(bytes32 lawHash => Data) internal data;

    constructor() {
        bytes memory configParams = abi.encode("address erc20Token", "uint256 minimumTokens", "uint256 roleIdToSet");
        emit Law__Deployed(configParams);
    }

    /// @notice Initializes the law with its configuration parameters
    /// @param index The index of the law in the DAO
    /// @param nameDescription The description of the law
    /// @param conditions The conditions for the law
    /// @param config The configuration parameters (erc20Token, minimumTokens, roleIdToSet)
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (address erc20Token_, uint256 minimumTokens_, uint256 roleIdToSet_) =
            abi.decode(config, (address, uint256, uint256));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].erc20Token = erc20Token_;
        data[lawHash].minimumTokens = minimumTokens_;
        data[lawHash].roleIdToSet = roleIdToSet_;

        super.initializeLaw(index, nameDescription, abi.encode("address Account"), conditions, config);
    }

    /// @notice Handles the request to assign or revoke a role based on token holdings
    /// @param caller The address of the caller
    /// @param lawId The ID of the law
    /// @param lawCalldata The calldata containing the account to assess
    /// @param nonce The nonce for the action
    /// @return actionId The ID of the action
    /// @return targets The target addresses for the action
    /// @return values The values for the action
    /// @return calldatas The calldatas for the action
    /// @return stateChange The state change data
    function handleRequest(
        address caller,
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
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
        // step 0: create actionId & decode the calldata
        (, bytes32 lawHash,) = Powers(payable(powers)).getActiveLaw(lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        (address account) = abi.decode(lawCalldata, (address));

        // step 1: retrieve token balance
        uint256 tokenBalance = ERC20(data[lawHash].erc20Token).balanceOf(account);

        // step 2: check if account has the role
        bool hasRole = Powers(payable(powers)).hasRoleSince(account, data[lawHash].roleIdToSet) != 0;

        // step 3: create arrays
        if (hasRole && tokenBalance < data[lawHash].minimumTokens) {
            (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(
                Powers.revokeRole.selector,
                data[lawHash].roleIdToSet,
                account
            );
        } else if (!hasRole && tokenBalance >= data[lawHash].minimumTokens) {
            (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(
                Powers.assignRole.selector,
                data[lawHash].roleIdToSet,
                account
            );
        }

        // step 4: return data
        return (actionId, targets, values, calldatas, "");
    }

    /// @notice Changes the state of the law
    /// @param lawHash The hash of the law
    /// @param stateChange The state change data
    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        // No state changes needed for this law
    }
}


