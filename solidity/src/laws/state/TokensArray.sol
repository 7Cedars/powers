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

    Token[] public tokens;
    uint256 public numberOfTokens; 

    event TokensArray__TokenAdded(address indexed tokenAddress, TokenType tokenType);
    event TokensArray__TokenRemoved(address indexed tokenAddress, TokenType tokenType);

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        inputParams = abi.encode(
            "address TokenAddress", 
            "uint256 TokenType", 
            "bool Add"
            );
        stateVars = inputParams;
    }

    function simulateLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal, bytes memory stateChange)
    {
        // step 1: return data
        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);
        tar[0] = address(1); // signals that powers should not execute anything else.

        return (tar, val, cal, lawCalldata);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        // step 1: decode
        (address tokenAddress, TokenType tokenType, bool add) = abi.decode(stateChange, (address, TokenType, bool)); // don't know if this is going to work...

        // step 2: change state
        // note: address is not type checked. We trust the caller
        if (add) {
            tokens.push(Token({ tokenAddress: tokenAddress, tokenType: tokenType }));
            numberOfTokens++;
            emit TokensArray__TokenAdded(tokenAddress, tokenType);
        } else if (numberOfTokens == 0) {
            revert ("Token not found.");
        } else {
            for (uint256 index; index < numberOfTokens; index++) {
                if (tokens[index].tokenAddress == tokenAddress) {
                    tokens[index] = tokens[numberOfTokens - 1];
                    tokens.pop();
                    numberOfTokens--;
                    break;
                }

                if (index == numberOfTokens - 1) {
                    revert ("Token not found.");
                }
            }
            emit TokensArray__TokenRemoved(tokenAddress, tokenType);
        }
    }
}
