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

/// @notice A law that manages budget of laws. It works by linking lawId to a budget.  This contract only supports Erc20 tokens on the same chain as the law. 
/// How to use: have a 'spend' storage var in the law, set this law as readstate; and check if spend + new spend is less than budget in this contract. .
///
/// Note: ths contract doubles as a whitelister for ERC20 tokens. Only addresses that have a budget of > 0 can be used. 
/// it does NOT check the signature of the token, with ERC20 it does not always work. It is up to governance to make sure the token is not malicious.
///
/// @author 7Cedars

///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract Erc20Budget is Law {
    // we need a triple mapping to store the budget per Powers protocol, per lawId and per token address. 
    mapping(bytes32 lawHash => mapping(uint16 lawId => mapping(address tokenAddress => uint256 budget))) public budget; 

    event Erc20Budget__BudgetSet(address indexed tokenAddress, uint256 budget); // emitted when budget is set + budget > 0 equals whitelisted. 

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
        inputParams = abi.encode("uint16 lawId", "address TokenAddress", "uint256 Budget");

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
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
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        return (actionId, targets, values, calldatas, lawCalldata);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        // step 1: decode
        (uint16 lawId, address tokenAddress_, uint256 budget_) = abi.decode(stateChange, (uint16, address, uint256));

        // step 2: change state
        // note: address is not type checked. We trust the caller
        budget[lawHash][lawId][tokenAddress_] = budget_;
        emit Erc20Budget__BudgetSet(tokenAddress_, budget_);
    }

    function getBudget(bytes32 lawHash, uint16 lawId, address tokenAddress) public view returns (uint256) {
        return budget[lawHash][lawId][tokenAddress];
    }
}
