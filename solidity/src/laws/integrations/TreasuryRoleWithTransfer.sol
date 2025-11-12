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

/// @notice Assign roles based on a selected donation an account made to a Treasury contract.
/// @author 7Cedars
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { TreasurySimple } from "../../helpers/TreasurySimple.sol";

// import "forge-std/Test.sol"; // only for testing

contract TreasuryRoleWithTransfer is Law {
    struct TokenConfig { 
        uint256 tokensPerBlock; // tokens per block for access duration
        // can (and probably will add more configf here later on)
    }

    struct Data {
        address treasuryContract; // TreasurySimple contract address
        uint16 roleIdToSet; // role id to assign/revoke
    }

    struct Mem {
        bytes32 lawHash;
        Data data;
        address caller;
        uint256 receiptId;
        address account;
        TreasurySimple.TransferLog selectedTransfer;
        uint48 currentBlock; 
        uint256 tokensPerBlock;
        uint256 blocksBought;
        uint48 accessUntilBlock; 
    }

    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 lawHash => mapping(address => TokenConfig)) internal tokenConfigs;

    constructor() {
        bytes memory configParams =
            abi.encode("address TreasuryContract", "address[] Tokens", "uint256[] TokensPerBlock", "uint16 RoleId");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address treasuryContract_, address[] memory tokens_, uint256[] memory tokensPerBlock_, uint16 roleIdToSet_) =
            abi.decode(config, (address, address[], uint256[], uint16));

        // Validate that arrays have the same length
        if (tokens_.length != tokensPerBlock_.length) {
            revert("Tokens and TokensPerBlock arrays must have the same length");
        }
        if (tokens_.length == 0) {
            revert("At least one token configuration is required");
        }

        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].treasuryContract = treasuryContract_;
        data[lawHash].roleIdToSet = roleIdToSet_;

        // Store token configurations
        for (uint256 i = 0; i < tokens_.length; i++) {
             tokenConfigs[lawHash][tokens_[i]] = TokenConfig({ tokensPerBlock: tokensPerBlock_[i] });
        }

        inputParams = abi.encode("uint256 receiptId"); // receipt of transfer to check on account sending request. 

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Handles the request to claim a role based on donations
    /// @param powers The address of the Powers contract
    /// @param lawId The ID of the law
    /// @param lawCalldata The calldata containing the account to claim role for
    /// @param nonce The nonce for the action
    /// @return actionId The ID of the action
    /// @return targets The target addresses for the action
    /// @return values The values for the action
    /// @return calldatas The calldatas for the action
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        mem.data = data[mem.lawHash];

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        mem.caller = msg.sender;
        (mem.receiptId) = abi.decode(lawCalldata, (uint256));
        mem.selectedTransfer = TreasurySimple(payable(mem.data.treasuryContract)).getTransfer(mem.receiptId);

        // check if transfer exists
        if (mem.selectedTransfer.amount == 0) {
            revert("Transfer does not exist");
        }
        // check if transfer is from the caller
        if (mem.selectedTransfer.from != caller) {
            revert("Transfer not from caller");
        }
        // check if number of blocks bought bring it across current block.number. 
        mem.currentBlock = uint48(block.number);
        mem.tokensPerBlock = tokenConfigs[mem.lawHash][mem.selectedTransfer.token].tokensPerBlock;
        if (mem.tokensPerBlock == 0) {
            revert("Token not configured");
        }
        mem.blocksBought = mem.selectedTransfer.amount / mem.tokensPerBlock;
        if (mem.blocksBought == 0) {
            // Not enough tokens transferred for any access
            revert("Insufficient transfer amount");
        }
        if (mem.currentBlock > uint48(mem.selectedTransfer.blockNumber) + uint48(mem.blocksBought)) {
            revert("Access expired");
        }  

        // If all checks passed: Create arrays for execution and assign role
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, mem.data.roleIdToSet, caller);
        
        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }

    function getTokenConfig(bytes32 lawHash, address token) public view returns (TokenConfig memory) {
        return tokenConfigs[lawHash][token];
    }
}
