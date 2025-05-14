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

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract TokensArray is Law {
    enum TokenType {
        Erc20,
        Erc721,
        Erc1155
    }

    struct Token {
        address tokenAddress;
        TokenType tokenType;
    }

    mapping(bytes32 lawHash => Token[] tokens) public tokens;
    mapping(bytes32 lawHash => uint256 numberOfTokens) public numberOfTokens;

    event TokensArray__TokenAdded(address indexed tokenAddress, TokenType tokenType);
    event TokensArray__TokenRemoved(address indexed tokenAddress, TokenType tokenType);

    constructor() { emit Law__Deployed(""); }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        inputParams = abi.encode("address TokenAddress", "uint256 TokenType", "bool Add");

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
        (address tokenAddress, TokenType tokenType, bool add) = abi.decode(stateChange, (address, TokenType, bool)); // don't know if this is going to work...

        // step 2: change state
        // note: address is not type checked. We trust the caller
        if (add) {
            tokens[lawHash].push(Token({ tokenAddress: tokenAddress, tokenType: tokenType }));
            numberOfTokens[lawHash]++;
            emit TokensArray__TokenAdded(tokenAddress, tokenType);
        } else if (numberOfTokens[lawHash] == 0) {
            revert("Token not found.");
        } else {
            for (uint256 index; index < numberOfTokens[lawHash]; index++) {
                if (tokens[lawHash][index].tokenAddress == tokenAddress) {
                    tokens[lawHash][index] = tokens[lawHash][numberOfTokens[lawHash] - 1];
                    tokens[lawHash].pop();
                    numberOfTokens[lawHash]--;
                    break;
                }

                if (index == numberOfTokens[lawHash] - 1) {
                    revert("Token not found.");
                }
            }
            emit TokensArray__TokenRemoved(tokenAddress, tokenType);
        }
    }
}
