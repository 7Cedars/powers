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

/// @notice This contract manages grants funded through ERC20 tokens.
/// - At construction time, the following is set:
///    - the ERC20 token address to be used for grants
///    - the total budget available for grants
///    - the duration of the grant program
///    - the address from where proposals can be made
///
/// - The logic:
///    - The calldata holds the grantee address, grant address, and quantity to transfer.
///    - If the grant address matches this contract and the quantity is within budget, the transfer is executed.
///    - The spent amount is tracked and updated after each successful transfer.
///
/// @dev The contract is an example of a law that
/// - requires proposals to be made from a specific address
/// - manages a budget of ERC20 tokens
/// - tracks spending over time
/// - Note: no checks on the ERC20 token type are performed, this is just an example.

/// @author 7Cedars
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "forge-std/console.sol"; // for testing only 

contract Grant is Law {
    struct Data {
        uint48 expiryBlock;
        uint256 budget;
        uint256 spent;
        address tokenAddress;
    }

    mapping(bytes32 lawHash => Data) internal data;

    constructor() {
        bytes memory configParams = abi.encode(
            "uint48 Duration",
            "uint256 Budget",
            "address TokenAddress"
        );
        emit Law__Deployed(configParams);
    }

    /// @notice Initializes the law with its configuration parameters
    /// @param index The index of the law in the DAO
    /// @param conditions The conditions for the law
    /// @param config The configuration parameters (duration, budget, tokenAddress, proposals)
    /// @param nameDescription The description of the law
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (uint48 duration, uint256 budget, address tokenAddress) =
            abi.decode(config, (uint48, uint256, address));
        
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].expiryBlock = duration + uint48(block.number);
        data[lawHash].budget = budget;
        data[lawHash].tokenAddress = tokenAddress;

        inputParams = abi.encode("address Grantee", "address Grant", "uint256 Quantity");

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    /// @notice Handles the request to transfer grant funds
    /// @param caller The address of the caller
    /// @param lawId The ID of the law
    /// @param lawCalldata The calldata containing grant details
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
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        // step 0: create actionId & decode law calldata
        (, bytes32 lawHash,) = Powers(payable(powers)).getActiveLaw(lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        (address grantee, address grantAddress, uint256 quantity) = abi.decode(lawCalldata, (address, address, uint256));

        // step 1: run additional checks
        if (grantAddress != address(this)) {
            revert("Incorrect grant address.");
        }
        if (quantity > data[lawHash].budget - data[lawHash].spent) {
            revert("Request amount exceeds available funds.");
        }
        if (block.number > data[lawHash].expiryBlock) {
            revert("Grant program has expired.");
        }

        // step 2: create arrays
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = data[lawHash].tokenAddress;
        calldatas[0] = abi.encodeWithSelector(ERC20.transfer.selector, grantee, quantity);
        stateChange = abi.encode(quantity);

        // step 3: return data
        return (actionId, targets, values, calldatas, stateChange);
    }

    /// @notice Changes the state of the law
    /// @param lawHash The hash of the law
    /// @param stateChange The state change data
    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (uint256 quantity) = abi.decode(stateChange, (uint256));
        data[lawHash].spent += quantity;
    }

    function getTokensLeft(bytes32 lawHash) external view returns (uint256) {
        return data[lawHash].budget - data[lawHash].spent;
    }

    function getDurationLeft(bytes32 lawHash) external view returns (uint48) {
        if (block.number > data[lawHash].expiryBlock) {
            return 0;
        }
        return data[lawHash].expiryBlock - uint48(block.number);
    }

    function getData(bytes32 lawHash) external view returns (Data memory) {
        return data[lawHash];
    }
}
