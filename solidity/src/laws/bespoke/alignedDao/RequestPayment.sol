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

import { Law } from "../../../Law.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { LawUtilities } from "../../../LawUtilities.sol";
    
contract RequestPayment is Law {
    address public erc1155;
    uint256 public tokenId;
    uint256 public amount;
    uint48 public delay;
    LawUtilities.TransactionsByAccount private transactions;

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint256 allowedRole_,
        LawUtilities.Conditions memory config_,
        address erc1155_,
        uint256 tokenId_,
        uint256 amount_,
        uint48 delay_
    ) Law(name_, powers_, allowedRole_, config_) {
        erc1155 = erc1155_;
        tokenId = tokenId_;
        amount = amount_;
        delay = delay_;

        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, "");
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function handleRequest(address caller, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        actionId = LawUtilities.hashActionId(address(this), lawCalldata, nonce);
        LawUtilities.checkThrottle(transactions, caller, delay);

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        stateChange = abi.encode(caller); // needed to log the transaction

        targets[0] = erc1155;
        calldatas[0] = abi.encodeWithSelector(
            ERC20.transfer.selector, 
            caller, 
            amount
            );

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes memory stateChange) internal override {
        address caller = abi.decode(stateChange, (address));
        LawUtilities.logTransaction(transactions, caller, uint48(block.number));
    }
}
