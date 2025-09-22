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

// /// @title GrantProgram - Law for managing a grant program in the Powers Protocol
// /// @notice This law allows the management of a grant program in the Powers protocol
// /// @dev Handles the dynamic configuration and management of a grant program
// ///
// /// @dev Note: if the grantprogram needs to be restricted by a budget, create an Erc20Budget law and set it as the readstate condition. 
// /// @author 7Cedars

// pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { LawUtilities } from "../../LawUtilities.sol";
// import { Powers } from "../../Powers.sol";
// import { ILaw } from "../../interfaces/ILaw.sol";
// import { PowersTypes } from "../../interfaces/PowersTypes.sol";
// import { Erc20Budget } from "../state/Erc20Budget.sol";

// // import "forge-std/console2.sol"; // for testing only

// contract GrantProgram is Law {
//     struct Memory {
//         string uriProposal;
//         address grantee;
//         address tokenAddress;
//         uint256[] milestoneDisbursements;
//         uint256 totalDisbursements;
//         bytes32 lawHash;
//         bytes32 grantHash;
//         uint16 lawCount;
//         bytes lawCalldata;
//         address grantLaw;
//         uint16 grantsId;
//         bytes grantConditions;
//         address budgetLaw;
//         bytes32 budgetLawHash;
//         bool budgetActive;
//     }

//     /// @notice Constructor for the GrantProgram contract
//     struct Data {
//         address grantLaw;
//         uint256 granteeRoleId;
//         bytes grantConditions;
//     }

//     mapping(bytes32 lawHash => Data) internal data;
//     mapping(bytes32 lawHash => mapping (address token => uint256)) internal spent; // spent per token per law. 
//     mapping(bytes32 lawHash => mapping(bytes32 grantHash => uint16)) internal grantIds;

//     constructor() {
//         bytes memory configParams = abi.encode(
//             "address grantLaw", // Address of the grant law: the law that will be adopted for each assigned grant. 
//             "uint256 granteeRoleId", // Role ID that grantee will be assigned. 
//             "bytes grantConditions" // NB: a bytes encoded ILaw.Conditions struct. Conditions for all subsequent grants are set when the grant program law is adopted.
//         );
//         emit Law__Deployed(configParams);
//     }

//     /// @notice Initializes the law with its configuration
//     /// @param index Index of the law
//     /// @param nameDescription Name of the law
//     /// @param conditions Conditions for the law
//     /// @param config Configuration data
//     function initializeLaw(
//         uint16 index,
//         string memory nameDescription,
//         bytes memory inputParams,
//         Conditions memory conditions,
//         bytes memory config
//     ) public override {
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
//         (
//             address grantLaw, 
//             uint256 granteeRoleId, 
//             bytes memory grantConditions
//             ) = abi.decode(config, (address, uint256, bytes));

//         data[lawHash] = Data({ 
//             grantLaw: grantLaw, 
//             granteeRoleId: granteeRoleId, 
//             grantConditions: grantConditions
//             });

//         inputParams = abi.encode(
//             "string UriProposal",
//             "address Grantee",
//             "address TokenAddress",
//             "uint256[] MilestoneDisbursements"
//         );

//         super.initializeLaw(index, nameDescription, inputParams, conditions, config);
//     }

//     /// @notice Handles the request to adopt a new law
//     /// @param caller Address initiating the request
//     /// @param lawId ID of this law
//     /// @param lawCalldata Encoded data containing the law to adopt and its configuration
//     /// @param nonce Nonce for the action
//     /// @return actionId ID of the created action
//     /// @return targets Array of target addresses
//     /// @return values Array of values to send
//     /// @return calldatas Array of calldata for the calls
//     /// @return stateChange State changes to apply
//     function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         override
//         returns (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         )
//     {
//         // Decode the law adoption data
//         Memory memory mem;
//         (mem.uriProposal, mem.grantee, mem.tokenAddress, mem.milestoneDisbursements) =
//             abi.decode(lawCalldata, (string, address, address, uint256[]));

//         mem.lawHash = LawUtilities.hashLaw(powers, lawId);
//         Data memory grantProgramData = getData(mem.lawHash);
//         Conditions memory conditions = laws[mem.lawHash].conditions;
//         ILaw.Conditions memory grantConditions = abi.decode(grantProgramData.grantConditions, (ILaw.Conditions));

//         // calculate the total disbursements requested 
//         for (uint256 i = 0; i < mem.milestoneDisbursements.length; i++) {
//             mem.totalDisbursements += mem.milestoneDisbursements[i];
//         }

//         // if a readState is set, check if the budget is sufficient. 
//         if (conditions.readStateFrom != 0) {
//             (mem.budgetLaw, mem.budgetLawHash, mem.budgetActive) = Powers(payable(powers)).getAdoptedLaw(conditions.readStateFrom);
//             Erc20Budget budget = Erc20Budget(mem.budgetLaw);
//             if (mem.budgetActive && budget.getBudget(mem.budgetLawHash, conditions.readStateFrom, mem.tokenAddress) < mem.totalDisbursements + spent[mem.lawHash][mem.tokenAddress]) {
//                 revert("Insufficient funds");
//             }
//         }

//         // Create arrays for the execution calldata 
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(2);

//         // Set up the call to adopt the grant law in Powers
//         targets[0] = powers; // Powers contract
//         targets[1] = powers; // Powers contract
//         calldatas[0] = abi.encodeWithSelector(
//             // adopt the grant as a law, with the relevant conditions
//             Powers.adoptLaw.selector,
//             PowersTypes.LawInitData({
//                 nameDescription: mem.uriProposal, // we use the uriProposal as the nameDescription.
//                 targetLaw: data[mem.lawHash].grantLaw,
//                 config: abi.encode(
//                     mem.uriProposal, mem.grantee, mem.tokenAddress, mem.milestoneDisbursements
//                 ),
//                 conditions: grantConditions
//             })
//         );
//         // assign the grantee role to the grantee
//         calldatas[1] = abi.encodeWithSelector(
//             Powers.assignRole.selector,
//             data[mem.lawHash].granteeRoleId, // grantee role
//             mem.grantee // grantee address
//         );

//         // Generate action ID
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
//         stateChange = abi.encode(Powers(payable(powers)).lawCount(), lawCalldata);

//         return (actionId, targets, values, calldatas, stateChange);
//     }

//     function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
//         Memory memory mem;
//         (mem.lawCount, mem.lawCalldata) = abi.decode(stateChange, (uint16, bytes));
//         (, , mem.tokenAddress, mem.milestoneDisbursements) = abi.decode(mem.lawCalldata, (string, address, address, uint256[]));

//         // update the spent budget per token
//         spent[lawHash][mem.tokenAddress] += mem.totalDisbursements;
//         // save the lawId of the grant law.  
//         mem.grantHash = keccak256(mem.lawCalldata);
//         grantIds[lawHash][mem.grantHash] = mem.lawCount;
//     }

//     function getGrantId(bytes32 lawHash, bytes memory lawCalldata) public view returns (uint16) {
//         return grantIds[lawHash][keccak256(lawCalldata)];
//     }

//     function getData(bytes32 lawHash) public view returns (Data memory) {
//         return data[lawHash];
//     }

//     function getSpent(bytes32 lawHash, address tokenAddress) public view returns (uint256) {
//         return spent[lawHash][tokenAddress];
//     }
// }
