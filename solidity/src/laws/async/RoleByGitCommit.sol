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

// /// @notice A law that uses Chainlink Functions to execute external API calls and assign roles based on results.
// ///
// /// The logic:
// /// - Takes a roleId and author string as input
// /// - Calls Chainlink Functions to check GitHub commit count for the author
// /// - If commits > 0, assigns the role to the author's linked address
// /// - Uses StringToAddress law to resolve author string to address
// ///
// /// @author 7Cedars,

// pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { LawUtilities } from "../../LawUtilities.sol";
// import { Powers } from "../../Powers.sol";
// import { IPowers } from "../../interfaces/IPowers.sol";
// import { StringToAddress } from "../state/StringToAddress.sol";
// // Chainlink Functions Oracle
// import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
// import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
// import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

// contract RoleByGitCommit is Law, FunctionsClient, ConfirmedOwner {
//     error UnexpectedRequestID(bytes32 requestId);

//     using FunctionsRequest for FunctionsRequest.Request;

//     struct Data {
//         string repo;
//         string[] paths;
//         uint256[] roleIds;
//         uint64 subscriptionId;
//         uint32 gasLimit;
//         bytes32 donID;
//     }

//     struct Request {
//         string author;
//         uint256 roleId;
//         address powers;
//         uint16 lawId;
//         uint256 actionId;
//         uint256 reply;
//         address addressLinkedToAuthor;
//     }

//     bytes32 public s_lastRequestId;
//     bytes32 public s_lastRequestHash;
//     bytes public s_lastResponse;
//     bytes public s_lastError;
//     mapping(bytes32 lawHash => Data) internal data;
//     mapping(bytes32 requestId => Request) public requests;

//     // Chainlink Functions source code for GitHub API call
//     string internal constant source =
//         "const repo = args[0]\nconst path = args[1]\nconst author = args[2]\n\nif (!repo || !path || !author) {\n    throw Error(\"Missing required arguments: repo, path or author\")\n}\n\nconst url = `https://powers-protocol.vercel.app/api/github-commits?repo=${repo}&path=${path}&author=${author}` \n\nconst resp = await Functions.makeHttpRequest({url}) \nif (resp.error) {\n  throw Error(\"Request failed\")\n}\n\nreturn Functions.encodeUint256(resp.data.data.commitCount)";

//     /// @notice Constructor of the law
//     constructor(address router) FunctionsClient(router) ConfirmedOwner(msg.sender) {
//         bytes memory configParams = abi.encode(
//             "string repo", 
//             "string[] paths", 
//             "uint256[] roleIds", 
//             "uint64 subscriptionId", 
//             "uint32 gasLimit", 
//             "bytes32 donID"
//         );
//         emit Law__Deployed(configParams);
//     }

//     function initializeLaw(
//         uint16 index,
//         string memory nameDescription,
//         bytes memory inputParams,
//         bytes memory config
//     ) public override {
//         bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

//         (
//             string memory repo, 
//             string[] memory paths, 
//             uint256[] memory roleIds, 
//             uint64 subscriptionId, 
//             uint32 gasLimit, 
//             bytes32 donID 
//         ) = abi.decode(config, (string, string[], uint256[], uint64, uint32, bytes32));
        
//         data[lawHash] = Data({ 
//             repo: repo, 
//             paths: paths, 
//             roleIds: roleIds, 
//             subscriptionId: subscriptionId, 
//             gasLimit: gasLimit, 
//             donID: donID
//         });

//         // Set input parameters for UI
//         inputParams = abi.encode("uint256 roleId", "string author");
//         super.initializeLaw(index, nameDescription, inputParams, config);
//     }

//     /// @notice Execute the law - initiates async Chainlink Functions call
//     function handleRequest(address /*caller*/, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
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
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
//         (uint256 roleId, string memory author) = abi.decode(lawCalldata, (uint256, string));

//         // Create empty arrays - actual execution happens in fulfillRequest
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
//         calldatas[0] = abi.encode(roleId, author, powers);

//         return (actionId, targets, values, calldatas, "");
//     }

//     function _replyPowers(
//         uint16 lawId,
//         uint256 actionId,
//         address[] memory targets,
//         uint256[] memory values,
//         bytes[] memory calldatas
//     ) internal override {
//         // Initiate Chainlink Functions request
//         bytes memory callData = calldatas[0];
//         (uint256 roleId, string memory author, address powers) = abi.decode(callData, (uint256, string, address));
//         bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
//         uint256 indexPath = findIndex(data[lawHash].roleIds, roleId);

//         // Get address linked to author from StringToAddress law
//         uint16 stringToAddressLawId = laws[lawHash].conditions.readStateFrom;
//         (address lawSta, bytes32 lawHashSta, ) = IPowers(powers).getAdoptedLaw(stringToAddressLawId); 
//         address addressLinkedToAuthor = StringToAddress(lawSta).getAddressByString(lawHashSta, author); 

//         string[] memory args = new string[](3);
//         args[0] = data[lawHash].repo;
//         args[1] = data[lawHash].paths[indexPath]; 
//         args[2] = author;

//         // Call Chainlink Functions oracle
//         bytes32 requestId = sendRequest(args, powers, lawId);
//         requests[requestId] = Request({
//             author: author,
//             roleId: roleId,
//             powers: powers,
//             lawId: lawId,
//             actionId: actionId,
//             reply: 0,
//             addressLinkedToAuthor: addressLinkedToAuthor
//         });
//     }

//     ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//     //      Chainlink Functions Oracle: https://docs.chain.link/chainlink-functions/tutorials/api-query-parameters       //
//     ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
//     /// @notice Send a request to Chainlink Functions
//     function sendRequest(
//         string[] memory args,
//         address powers,
//         uint16 lawId
//     ) internal returns (bytes32 requestId) {
//         bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
//         Data memory data_ = data[lawHash];

//         FunctionsRequest.Request memory req;
//         req.initializeRequestForInlineJavaScript(source);

//         if (args.length > 0) req.setArgs(args);
//         s_lastRequestId = _sendRequest(req.encodeCBOR(), data_.subscriptionId, data_.gasLimit, data_.donID);
//         return s_lastRequestId;
//     }

//     /// @notice Handle Chainlink Functions response
//     function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {        
//         if (s_lastRequestId != requestId) {
//             revert UnexpectedRequestID(requestId);
//         }
        
//         s_lastResponse = response;
//         s_lastError = err;
//         if (err.length > 0) {
//             revert(string(err));
//         }
//         if (s_lastResponse.length == 0) {
//             revert("No response from the API");
//         }
        
//         Request memory request = requests[requestId];
//         request.reply = abi.decode(abi.encode(response), (uint256));

//         // If commits > 0, assign role to the author's linked address
//         if (request.reply > 0) {
//             address[] memory targets = new address[](1);
//             uint256[] memory values = new uint256[](1);
//             bytes[] memory calldatas = new bytes[](1);
//             targets[0] = request.powers;
//             calldatas[0] = abi.encodeWithSelector(
//                 Powers.assignRole.selector, 
//                 request.roleId, 
//                 request.addressLinkedToAuthor
//             ); 
//             IPowers(payable(request.powers)).fulfill(request.lawId, request.actionId, targets, values, calldatas);
//         }
//     }

//     /////////////////////////////////
//     //      View Functions         //
//     /////////////////////////////////
    
//     function getData(bytes32 lawHash) public view returns (Data memory) {
//         return data[lawHash];
//     }

//     function getRouter() public view returns (address) {
//         return address(i_router);
//     }

//     function findIndex(uint256[] memory roleIds, uint256 roleId) public pure returns (uint256) {
//         for (uint256 i = 0; i < roleIds.length; i++) {
//             if (roleIds[i] == roleId) {
//                 return i;
//             }
//         }
//         revert("RoleId not found");
//     }
// }
