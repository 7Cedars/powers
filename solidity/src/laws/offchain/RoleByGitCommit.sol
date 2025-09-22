// // SPDX-License-Identifier: MIT

// //////////////////////////////////////////////////////////////////////////////
// // This program is free software: you can redistribute it and/or modify    ///
// // it under the terms of the MIT Public License.                           ///
// //                                                                         ///
// // This is a Proof Of Concept and is not intended for production use.      ///
// // Tests are incomplete and it contracts have not been audited.            ///
// //                                                                         ///
// // It is distributed in the hope that it will be useful and insightful,    ///
// // but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
// //  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                   ///
// //////////////////////////////////////////////////////////////////////////////

// // @notice A base contract that executes a bespoke action.
// // TBI: Basic logic sho
// //
// // @author 7Cedars,

// pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { LawUtilities } from "../../LawUtilities.sol";
// import { Powers } from "../../Powers.sol";
// import { IPowers } from "../../interfaces/IPowers.sol";
// import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
// import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
// // Chainlink Functions Oracle
// import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
// import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
// import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
// import { StringToAddress } from "../state/StringToAddress.sol";

// // @notice A contract that checks if a snapshot proposal passed.
// // It uses the Chainlink Functions Oracle to call snapshots API to check if a snapshot proposal passed.
// // @author 7Cedars

// // see the example here: https://github.com/smartcontractkit/smart-contract-examples/blob/main/functions-examples/examples/4-post-data/source.js
// // see the script in chainlinkFunctionScript.js. It can be tried at https://functions.chain.link/playground. It works at time of writing.
// // I used this website https://www.espruino.com/File%20Converter to convert the source code to a string. 
// contract RoleByGitCommit is Law, FunctionsClient, ConfirmedOwner {
//     error UnexpectedRequestID(bytes32 requestId);

//     using FunctionsRequest for FunctionsRequest.Request;

//     struct Memory {
//         string repo;
//         uint256 roleId;
//         string author;
//         address powers;
//         bytes32 lawHash;
//         uint256 indexPath;
//         string[] paths;
//         uint256[] roleIds;
//         uint64 subscriptionId;
//         uint32 gasLimit;
//         uint16 stringToAddress;
//         address lawSta;
//         bytes32 lawHashSta;
//         bytes callData;
//         address addressLinkedToAuthor;
//         uint256 reply;
//     }

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
//     mapping(bytes32 lawHash => Data) public data;
//     mapping(bytes32 requestId => Request) public requests;

//     // see the example here: https://github.com/smartcontractkit/smart-contract-examples/blob/main/functions-examples/examples/4-post-data/source.js
//     // see the script in chainlinkFunctionScript.js. It can be tried at https://functions.chain.link/playground. It works at time of writing.
//     // I used this website https://www.espruino.com/File%20Converter to convert the source code to a string.
//     string internal constant source =
//         "const repo = args[0]\nconst path = args[1]\nconst author = args[2]\n\nif (!repo || !path || !author) {\n    throw Error(\"Missing required arguments: repo, path or author\")\n}\n\nconst url = `https://powers-protocol.vercel.app/api/github-commits?repo=${repo}&path=${path}&author=${author}` \n\nconst resp = await Functions.makeHttpRequest({url}) \nif (resp.error) {\n  throw Error(\"Request failed\")\n}\n\nreturn Functions.encodeUint256(resp.data.data.commitCount)";

//     /// @notice constructor of the law.
//     constructor(address router) FunctionsClient(router) ConfirmedOwner(msg.sender) {
//         // if I can take owner out - do so. checks are handled through the Powers protocol.
//         bytes memory configParams =
//             abi.encode("string repo", "string[] paths", "uint256[] roleIds", "uint64 subscriptionId", "uint32 gasLimit", "bytes32 donID");
//         emit Law__Deployed(configParams);
//     }

//     function initializeLaw(
//         uint16 index,
//         string memory nameDescription,
//         bytes memory inputParams,
//         Conditions memory conditions,
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
//             ) = abi.decode(config, (string, string[], uint256[], uint64, uint32, bytes32));
//         data[lawHash] = Data({ 
//             repo: repo, paths: paths, roleIds: roleIds, subscriptionId: subscriptionId, gasLimit: gasLimit, donID: donID
//         });
        

//         inputParams = abi.encode(
//             "uint256 RoleId",
//             "string Author"
//         );
//         super.initializeLaw(index, nameDescription, inputParams, conditions, config);
//     }

//     // @notice execute the law.
//     // @param lawCalldata the calldata _without function signature_ to send to the function.
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
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
//         Memory memory mem;
//         (mem.roleId, mem.author) = abi.decode(lawCalldata, (uint256, string));

//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
//         calldatas[0] = abi.encode(mem.roleId, mem.author, powers);

//         return (actionId, targets, values, calldatas, "");
//     }

//     function _replyPowers(
//         uint16 lawId,
//         uint256 actionId,
//         address[] memory targets,
//         uint256[] memory values,
//         bytes[] memory calldatas
//     ) internal override {
//         // NB! Naming is confusing here, because we are NOT replying to the Powers contract: we are sending a request to an oracle.
//         Memory memory mem;
//         mem.callData = calldatas[0];
//         (mem.roleId, mem.author, mem.powers) = abi.decode(mem.callData, (uint256, string, address));
//         mem.lawHash = LawUtilities.hashLaw(mem.powers, lawId);
//         mem.indexPath = findIndex(data[mem.lawHash].roleIds, mem.roleId);

//         // call readStateFrom contract to retrieve address linked to the author.
//         mem.stringToAddress = laws[mem.lawHash].conditions.readStateFrom;
//         (mem.lawSta, mem.lawHashSta, ) = IPowers(mem.powers).getAdoptedLaw(mem.stringToAddress); 
//         mem.addressLinkedToAuthor = StringToAddress(mem.lawSta).getAddressByString(mem.lawHashSta, mem.author); 

//         string[] memory args = new string[](3);
//         args[0] = data[mem.lawHash].repo;
//         args[1] = data[mem.lawHash].paths[mem.indexPath]; 
//         args[2] = mem.author;

//         // call to the oracle.
//         bytes32 requestId = sendRequest(args, mem.powers, lawId);
//         requests[requestId] = Request({
//             author: mem.author,
//             roleId: mem.roleId,
//             powers: mem.powers,
//             lawId: lawId,
//             actionId: actionId,
//             reply: 0,
//             addressLinkedToAuthor: mem.addressLinkedToAuthor
//         });
//     }

//     ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//     //      Chainlink Functions Oracle: https://docs.chain.link/chainlink-functions/tutorials/api-query-parameters       //
//     ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//     /**
//      * @notice Send a simple request
//      * @param args List of arguments accessible from within the source code
//      * @param powers The address of the Powers contract
//      * @param lawId The id of the law
//      */
//     function sendRequest(
//         string[] memory args, // = List of arguments accessible from within the source code
//         address powers,
//         uint16 lawId
//     ) internal returns (bytes32 requestId) {
//         Memory memory mem;
//         mem.lawHash = LawUtilities.hashLaw(powers, lawId);
//         Data memory data_ = data[mem.lawHash];

//         FunctionsRequest.Request memory req;
//         req.initializeRequestForInlineJavaScript(source);

//         if (args.length > 0) req.setArgs(args);
//         s_lastRequestId = _sendRequest(req.encodeCBOR(), data_.subscriptionId, data_.gasLimit, data_.donID);
//         return s_lastRequestId;
//     }

//     // TODO: The callback function needs to be far more gas efficient. 
//     // It seems that execution reverts on this. (when mem is not used, the call actually executes.)
//     // First line of attack is to simplify the mem struct. Make it much smaller and more efficient. 

//     /**
//      * @notice When oracle replies, we send data to Powers contract.
//      * @param requestId The request ID, returned by sendRequest()
//      * @param response Aggregated response from the user code
//      * @param err Aggregated error from the user code or from the execution pipeline
//      * Either response or error parameter will be set, but never both
//      */
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

//         if (request.reply > 0) {
//             address[] memory targets = new address[](1);
//             uint256[] memory values = new uint256[](1);
//             bytes[] memory calldatas = new bytes[](1);
//             targets[0] = request.powers;
//             calldatas[0] = abi.encodeWithSelector(
//                 Powers.assignRole.selector, 
//                 request.roleId, 
//                 request.addressLinkedToAuthor
//                 ); 
//             IPowers(payable(request.powers)).fulfill(request.lawId, request.actionId, targets, values, calldatas);
//         }
//     }

//     /////////////////////////////////
//     //      Helper Functions       //
//     /////////////////////////////////
//     function getData(bytes32 lawHash) public view returns (Data memory data_) {
//         data_ = data[lawHash];
//     }

//     function getRouter() public view returns (address) {
//         return address(i_router);
//     }

//     function findIndex(uint256[] memory roleIds, uint256 roleId) public pure returns (uint256 indexPath) {
//         for (uint256 i = 0; i < roleIds.length; i++) {
//             if (roleIds[i] == roleId) {
//                 indexPath = uint256(i);
//                 break;
//             }
//         }
//         return indexPath;
//     }

// }
