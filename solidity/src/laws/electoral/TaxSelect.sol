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

/// @notice This contract assigns accounts to roles based on their tax payments in a specified ERC20 token.
/// - At construction time, the following is set:
///    - the ERC20 taxed token address to be assessed
///    - the threshold amount of tax that needs to be paid
///    - the roleId to be assigned
///
/// - The logic:
///    - The calldata holds the account that needs to be assessed.
///    - If the account has paid more tax than the threshold in the previous epoch, it is assigned the role.
///    - If the account has paid less tax than the threshold in the previous epoch, its role is revoked.
///    - If there is no previous epoch, the operation reverts.
///
/// @dev The contract is an example of a law that:
/// - does not need a proposal to be voted through; it can be called directly
/// - has a simple tax-based role assignment mechanism
/// - does not have to be role-restricted
/// - translates tax payments to role assignments
/// - can be extended to include more complex tax-based role assignment mechanisms

/// @author 7Cedars
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";

// import "forge-std/Test.sol"; // only for testing

contract TaxSelect is Law {
    struct Data {
        address erc20Taxed;
        uint256 thresholdTaxPaid;
        uint256 roleIdToSet;
    }

    struct Mem {
        bytes32 lawHash;
        uint48 epochDuration;
        uint48 currentEpoch;
        bool hasRole;
        uint256 taxPaid;
    }

    mapping(bytes32 lawHash => Data) internal data;

    /// @notice Constructor for TaxSelect law
    constructor() {
        bytes memory configParams =
            abi.encode("address erc20TaxedMock", "uint256 thresholdTaxPaid", "uint256 roleIdToSet");
        emit Law__Deployed(configParams);
    }

    /// @notice Initializes the law with its configuration parameters
    /// @param index The index of the law in the DAO
    /// @param nameDescription The description of the law
    /// @param config The configuration parameters (erc20Taxed, thresholdTaxPaid, roleIdToSet)
    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address erc20Taxed_, uint256 thresholdTaxPaid_, uint256 roleIdToSet_) =
            abi.decode(config, (address, uint256, uint256));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].erc20Taxed = erc20Taxed_;
        data[lawHash].thresholdTaxPaid = thresholdTaxPaid_;
        data[lawHash].roleIdToSet = roleIdToSet_;

        inputParams = abi.encode("address Account");

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Handles the request to assign or revoke a role based on tax payments
    //
    /// @param powers The address of the Powers contract
    /// @param lawId The ID of the law
    /// @param lawCalldata The calldata containing the account to assess
    /// @param nonce The nonce for the action
    /// @return actionId The ID of the action
    /// @return targets The target addresses for the action
    /// @return values The values for the action
    /// @return calldatas The calldatas for the action
    function handleRequest(address, /* caller */ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        // step 0: create actionId & decode the calldata
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        (address account) = abi.decode(lawCalldata, (address));

        // step 1: retrieve data
        mem.epochDuration = Erc20Taxed(data[mem.lawHash].erc20Taxed).EPOCH_DURATION();
        mem.currentEpoch = uint48(block.number) / mem.epochDuration;

        if (mem.currentEpoch == 0) {
            revert("No finished epoch yet.");
        }

        // step 2: retrieve data on tax paid and role
        mem.hasRole = Powers(payable(powers)).hasRoleSince(account, data[mem.lawHash].roleIdToSet) > 0;
        // console.log("mem.hasRole", mem.hasRole);
        mem.taxPaid =
            Erc20Taxed(data[mem.lawHash].erc20Taxed).getTaxLogs(uint48(block.number) - mem.epochDuration, account);
        // console.log("mem.taxPaid", mem.taxPaid);

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = powers;

        // step 3: create arrays
        if (mem.hasRole && mem.taxPaid < data[mem.lawHash].thresholdTaxPaid) {
            // console.log("revoking role");
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, data[mem.lawHash].roleIdToSet, account);
        } else if (!mem.hasRole && mem.taxPaid >= data[mem.lawHash].thresholdTaxPaid) {
            // console.log("assigning role");
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleIdToSet, account);
        }

        // step 4: return data
        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
