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

// // protocol
// import { Law } from "../../../Law.sol";

// // @title AiAgents
// contract AiAgents is Law {
//     struct AiAgent {
//         string name;
//         address account;
//         string uri;
//     }

//     AiAgent[] public aiAgentsList;
//     uint256 public aiAgentsCount;

//     event AiAgents__AgentAdded(address indexed account, string name, string uri);
//     event AiAgents__AgentRemoved(address indexed account);

//     constructor(
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint32 allowedRole_,
//         LawChecks memory config_
//     )  {
//         inputParams = abi.encode(
//             "string Name", // name
//             "address Account", // account
//             "string Uri", // uri
//             "bool Add" // add
//         );
//     }

//     /// @notice execute the law.
//     /// @param lawCalldata the calldata _without function signature_ to send to the function.
//     function handleRequest(address, /*initiator*/ bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         virtual
//         override
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {
//         // step 0: decode law calldata
//         (string memory name, address account,, bool add) = abi.decode(lawCalldata, (string, address, string, bool));

//         // step 1: run additional checks
//         if (add) {
//             for (uint256 i = 0; i < aiAgentsCount; i++) {
//                 if (aiAgentsList[i].account == account) {
//                     revert ("Agent already exist");
//                 }
//             }
//         }

//         if (!add) {
//             bool agentFound;
//             for (uint256 i = 0; i < aiAgentsCount; i++) {
//                 if (aiAgentsList[i].account == account) {
//                     agentFound = true;
//                     break;
//                 }
//             }
//             if (!agentFound) {
//                 revert ("Agent does not exist");
//             }
//         }

//         // step 2: create arrays
//         targets = new address[](1);
//         values = new uint256[](1);
//         calldatas = new bytes[](1);
//         stateChange = abi.encode("");

//         // step 3: fill out arrays with data - no action should be taken by protocol.
//         targets[0] = address(1);
//         stateChange = lawCalldata;

//         // step 4: return data
//         return (targets, values, calldatas, stateChange);
//     }

//     // add or remove member from state mapping in law.
//     function _changeState(bytes memory stateChange) internal override {
//         (string memory name, address account, string memory uri, bool add) =
//             abi.decode(stateChange, (string, address, string, bool));

//         if (add) {
//             aiAgentsList.push(AiAgent(name, account, uri));
//             aiAgentsCount++;
//             emit AiAgents__AgentAdded(account, name, uri);
//         }

//         if (!add) {
//             for (uint256 i = 0; i < aiAgentsCount; i++) {
//                 if (aiAgentsList[i].account == account) {
//                     aiAgentsList[i] = aiAgentsList[aiAgentsCount - 1];
//                     aiAgentsList.pop();
//                     aiAgentsCount--;
//                     break;
//                 }
//             }
//             emit AiAgents__AgentRemoved(account);
//         }
//     }
// }
