// // SPDX-License-Identifier: MIT

// ///////////////////////////////////////////////////////////////////////////////
// /// This program is free software: you can redistribute it and/or modify    ///
// /// it under the terms of the MIT Public License.                           ///
// ///                                                                         ///
// /// This is a Proof Of Concept and is not intended for production use.      ///
// /// Tests are incomplete and it contracts have not been audited.            ///
// ///                                                                         ///
// /// It is distributed in the hope that it will be useful and insightful,    ///
// /// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
// /// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
// ///////////////////////////////////////////////////////////////////////////////

// /// @notice This contract assigns accounts to roles based on buying access. 
// /// at setup a token is set, and amount per block is set.
// /// when an account buys access, it can assigned a role to an account of choice. A lapse block for the chosen account is set at the same time.
// /// when an account transfers 0, the contract checks if there is still access for the account. If it is, it is (re)assigned the role.
// /// There is no revoke functionality, this should be implemented through another law.

// /// @author 7Cedars
// pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import { Powers } from "../../Powers.sol";
// import { LawUtilities } from "../../LawUtilities.sol";

// // import "forge-std/Test.sol"; // only for testing

// contract BuyAccess is Law {
//     struct Data {
//         address erc20Token; // erc20 token address.
//         uint256 tokensPerBlock; // tokens per block.
//         uint16 roleIdToSet; // role id to set.
//     }

//     struct Mem {
//         bytes32 lawHash;
//         Data data;
//         address caller;
//         address account;
//         uint256 amountTokens;
//         uint48 currentBlock;    
//         uint48 amountBlocksBought;
//         uint48 lapseBlock;
//         uint48 newLapseBlock;
//     }

//     mapping(bytes32 lawHash => Data) internal data;
//     // lapse block is the block number when the access will lapse and it will not be possible to regain access to role if revoked.
//     mapping(bytes32 lawHash => mapping(address account => uint48 lapseBlock)) public lapseBlock;

//     constructor() {
//         bytes memory configParams = abi.encode("address Erc20Token", "uint256 TokensPerBlock", "uint16 RoleId");
//         emit Law__Deployed(configParams);
//     }

//     function initializeLaw(
//         uint16 index,
//         string memory nameDescription,
//         bytes memory inputParams,
//         bytes memory config
//     ) public override {
//         (address erc20Token_, uint256 tokensPerBlock_, uint16 roleIdToSet_) =
//             abi.decode(config, (address, uint256, uint16));
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
//         data[lawHash].erc20Token = erc20Token_;
//         data[lawHash].tokensPerBlock = tokensPerBlock_;
//         data[lawHash].roleIdToSet = roleIdToSet_;

//         inputParams = abi.encode("address Account", "uint256 AmountTokens"); // note: you can buy someone else access. 

//         super.initializeLaw(index, nameDescription, inputParams, config);
//     }

//     /// @notice Handles the request to assign or revoke a role based on buying access
//     /// @param caller The address of the caller
//     /// @param powers The address of the Powers contract
//     /// @param lawId The ID of the law
//     /// @param lawCalldata The calldata containing the account and amount
//     /// @param nonce The nonce for the action
//     /// @return actionId The ID of the action
//     /// @return targets The target addresses for the action
//     /// @return values The values for the action
//     /// @return calldatas The calldatas for the action
//     function handleRequest(
//         address caller,
//         address powers,
//         uint16 lawId,
//         bytes memory lawCalldata,
//         uint256 nonce
//     )
//         public
//         view
//         virtual
//         override
//         returns (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas
//         )
//     {
//         Mem memory mem;
//         mem.lawHash = LawUtilities.hashLaw(powers, lawId);
//         mem.data = data[mem.lawHash];
       
//         // step 0: create actionId & decode the calldata
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
//         (mem.account, mem.amountTokens) = abi.decode(lawCalldata, (address, uint256));
//         mem.lapseBlock = lapseBlock[mem.lawHash][mem.account];
//         mem.amountBlocksBought = uint48(mem.amountTokens / mem.data.tokensPerBlock); // note: I am dividing here. Change if possible.
//         mem.currentBlock = uint48(block.number);

//         if (mem.amountBlocksBought == 0 && mem.lapseBlock < mem.currentBlock) {
//             revert("No access bought or already expired.");
//         }

//         mem.newLapseBlock = mem.lapseBlock < mem.currentBlock ? 
//             mem.currentBlock + mem.amountBlocksBought 
//             : 
//             mem.lapseBlock + mem.amountBlocksBought;

//         // Create arrays for execution


//         // Update lapse block in state
//         lapseBlock[mem.lawHash][mem.account] = mem.newLapseBlock;

//         return (actionId, targets, values, calldatas);
//     }

//     function _externalCall(uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) internal override {
//         // call transferFrom from caller to Powers contract
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
//         targets[0] = mem.data.erc20Token;
//         values[0] = 0;
//         calldatas[0] = abi.encodeWithSelector(
//             ERC20.transferFrom.selector,
//             caller,
//             powers,
//             mem.amountTokens
//         );


//     }

//     function _replyPowers(uint16 lawId, uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) internal override {
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(2);
        
//         // First call: transfer tokens from caller to Powers contract
//         targets[0] = mem.data.erc20Token;
//         values[0] = 0;
//         calldatas[0] = abi.encodeWithSelector(
//             ERC20.transferFrom.selector,
//             caller,
//             powers,
//             mem.amountTokens
//         );
        
//         // Second call: assign role to account
//         targets[1] = powers;
//         values[1] = 0;
//         calldatas[1] = abi.encodeWithSelector(
//             Powers.assignRole.selector,
//             mem.data.roleIdToSet,
//             mem.account
//         );

//         super._replyPowers(lawId, actionId, targets, values, calldatas);
//     }

//     function getData(bytes32 lawHash) public view returns (Data memory) {
//         return data[lawHash];
//     }
// }
