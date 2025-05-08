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

/// @notice This contract assigns accounts to roles based on payment to the powers protocol during an epoch. 


/// @author 7Cedars
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Erc20TaxedMock } from "../../../test/mocks/Erc20TaxedMock.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

// import "forge-std/Test.sol"; // only for testing

contract Subscription is Law {
    struct Data {
        uint48 epochDuration;
        uint256 subscriptionAmount; // in chain native currency
        uint256 roleIdToSet;
    }

    struct Mem {
        bytes32 lawHash;
        uint48 epochDuration;
        uint48 currentEpoch;
        bool hasRole;
        PowersTypes.Deposit[] deposits; 
        uint256 amountPaidLastEpoch;
    }

    mapping(bytes32 lawHash => Data) internal data;

    constructor(string memory name_) {
        LawUtilities.checkStringLength(name_);
        name = name_;
        bytes memory configParams = abi.encode("uint48 EpochDuration", "uint256 SubscriptionAmount", "uint256 RoleId");
        emit Law__Deployed(name_, configParams);
    }   

    /// @notice Initializes the law with its configuration parameters
    /// @param index The index of the law in the DAO
    /// @param conditions The conditions for the law
    /// @param config The configuration parameters (erc20TaxedMock, thresholdTaxPaid, roleIdToSet)
    /// @param inputParams The input parameters for the law
    /// @param description The description of the law
    function initializeLaw(
        uint16 index,
        Conditions memory conditions, 
        bytes memory config,
        bytes memory inputParams,
        string memory description
    ) public override {
        (uint48 epochDuration_, uint256 subscriptionAmount_, uint256 roleIdToSet_) =
            abi.decode(config, (uint48, uint256, uint256));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].epochDuration = epochDuration_;
        data[lawHash].subscriptionAmount = subscriptionAmount_;
        data[lawHash].roleIdToSet = roleIdToSet_;

        super.initializeLaw(index, conditions, config, abi.encode("address Account"), description);
    }

    /// @notice Handles the request to assign or revoke a role based on tax payments
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
        Mem memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        // step 0: create actionId & decode the calldata
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        (address account) = abi.decode(lawCalldata, (address));

        // step 1: retrieve data 
        mem.epochDuration = data[mem.lawHash].epochDuration;
        mem.currentEpoch = uint48(block.number) / mem.epochDuration;

        if (mem.currentEpoch == 0) {
            revert("No finished epoch yet.");
        }

        // step 2: retrieve data on tax paid and role
        mem.hasRole = Powers(payable(powers)).hasRoleSince(caller, data[mem.lawHash].roleIdToSet) > 0;
        mem.deposits = Powers(payable(powers)).getDeposits(account);
        mem.amountPaidLastEpoch = 0;

        for (uint256 i = 0; i < mem.deposits.length; i++) {
            if (mem.deposits[i].atBlock + mem.epochDuration > mem.currentEpoch * mem.epochDuration) {
                mem.amountPaidLastEpoch += mem.deposits[i].amount;
            }
        }

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        // step 3: create arrays
        
        if (mem.hasRole && mem.amountPaidLastEpoch < data[mem.lawHash].subscriptionAmount) {
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(
                Powers.revokeRole.selector,
                data[mem.lawHash].roleIdToSet,
                account
            );
        } else if (!mem.hasRole && mem.amountPaidLastEpoch >= data[mem.lawHash].subscriptionAmount) {
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(
                Powers.assignRole.selector,
                data[mem.lawHash].roleIdToSet,
                account
            );
        }

        // step 4: return data
        return (actionId, targets, values, calldatas, "");
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}