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

// /// @notice A law that analyzes addresses using AI via cross-chain communication
// /// @dev This law sends msg.sender to AiCCIPProxy for AI analysis and assigns roles based on results
// /// @author 7Cedars

// // Note: Data validation is hardly present at this stage. It's a PoC..

// pragma solidity ^0.8.26;

// import { Law } from "../../Law.sol";
// import { ILaw } from "../../interfaces/ILaw.sol";
// import { Powers } from "../../Powers.sol";
// import { IPowers } from "../../interfaces/IPowers.sol";
// import { LawUtilities } from "../../LawUtilities.sol";
// import { Client } from "@chainlink/contracts-ccip/libraries/Client.sol";
// import { CCIPReceiver } from "@chainlink/contracts-ccip/applications/CCIPReceiver.sol";
// import { IRouterClient } from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";
// import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

// /// @title AddressAnalysis - A law for AI-powered address analysis and role assignment
// /// @notice This law integrates with AiCCIPProxy to analyze addresses and assign roles
// /// @dev Inherits from both Law and CCIPReceiver to handle cross-chain AI analysis
// contract AddressAnalysis is Law, CCIPReceiver {
//     // Custom errors
//     error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
//     error InvalidResponseSender(address expectedSender, address actualSender);
//     error NoPendingRequest(bytes32 messageId);
//     error AiCCIPProxyNotSet();

//     // Events
//     event AddressAnalysisRequested(
//         bytes32 indexed messageId,
//         uint256 indexed actionId,
//         address indexed caller,
//         address aiCCIPProxy
//     );

//     event AddressAnalysisReceived(
//         bytes32 indexed messageId,
//         uint256 indexed actionId,
//         address indexed caller,
//         uint256 category,
//         string explanation
//     );

//     event RoleAssigned(
//         address indexed caller,
//         uint256 roleId,
//         uint256 category,
//         string explanation
//     );

//     // Storage
//     address private s_aiCCIPProxy;
//     LinkTokenInterface private s_linkToken;
//     uint64 private s_destinationChainSelector;

//     // Structure to store address analysis results
//     struct AddressAnalysisResult {
//         uint256 category;
//         string explanation;
//         uint256 roleId;
//         bool analyzed;
//     }

//     // Mapping to store analysis results by address
//     mapping(address => AddressAnalysisResult) public addressAnalyses;

//     // Mapping to track actionId => lawId, caller, powers, processed
//     struct PendingRequest {
//         address caller;
//         uint16 lawId;
//         address powers;
//         bool processed;
//     }
//     // stores the pending request for each actionId
//     mapping(uint256 => PendingRequest) private s_pendingRequests;

//     // Store the last received analysis details
//     bytes32 private s_lastReceivedMessageId;
//     address private s_lastAnalyzedAddress;
//     uint64 private s_lastSourceChainSelector;
//     address private s_lastSender;
//     uint256 private s_lastActionId;

//     /// @notice Constructor initializes the contract with router and link token addresses
//     /// @param router The address of the CCIP router contract
//     /// @param link The address of the link contract
//     /// @param destinationChainSelector The destination chain selector for replies

//     /** Mantle Sepolia Testnet details:
//      * Link Token: 0x22bdEdEa0beBdD7CfFC95bA53826E55afFE9DE04
//      * Oracle: 0xBDC0f941c144CB75f3773d9c2B2458A2f1506273
//      * jobId: 582d4373649642e0994ab29295c45db0
//      *
//      */

//     constructor(
//         address router,
//         address link,
//         uint64 destinationChainSelector,
//         address aiCCIPProxy
//     ) CCIPReceiver(router) {
//         s_destinationChainSelector = destinationChainSelector;
//         s_linkToken = LinkTokenInterface(link);
//         s_aiCCIPProxy = aiCCIPProxy;
//         emit Law__Deployed("");
//     }

//     fallback() external payable {}
//     receive() external payable {}

//     /// @notice Initializes the law with its configuration
//     /// @param index Index of the law
//     /// @param nameDescription Name of the law
//     /// @param inputParams Input parameters (none for this law)
//     /// @param conditions Conditions for the law
//     /// @param config Configuration data containing aiCCIPProxy address
//     function initializeLaw(
//         uint16 index,
//         string memory nameDescription,
//         bytes memory inputParams,
//         Conditions memory conditions,
//         bytes memory config
//     ) public override {
//         // This law takes no input parameters
//         inputParams = abi.encode("");
//         super.initializeLaw(index, nameDescription, inputParams, conditions, config);
//     }

//     /// @notice Handles the law execution request
//     /// @param caller Address that initiated the action (msg.sender)
//     /// @param powers Address of the Powers contract
//     /// @param lawId The id of the law
//     /// @param lawCalldata Encoded function call data (empty for this law)
//     /// @param nonce The nonce for the action
//     /// @return actionId The action ID
//     /// @return targets Target contract addresses for calls
//     /// @return values ETH values to send with calls
//     /// @return calldatas Encoded function calls
//     /// @return stateChange Encoded state changes to apply
//     function handleRequest(
//         address caller,
//         address powers,
//         uint16 lawId,
//         bytes memory lawCalldata,
//         uint256 nonce
//     )
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
//         if (s_aiCCIPProxy == address(0)) {
//             revert AiCCIPProxyNotSet();
//         }
//         actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

//         // State change to store the caller and actionId for later processing
//         stateChange = abi.encode(caller, actionId, lawId);
//         return (actionId, targets, values, calldatas, stateChange);
//     }

//     /// @notice Applies state changes from law execution
//     /// @param lawHash The hash of the law
//     /// @param stateChange Encoded state changes to apply
//     function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
//         (address caller, uint256 actionId, uint16 lawId) = abi.decode(stateChange, (address, uint256, uint16));

//         // Store the pending request for when we receive the analysis back
//         // We'll use the actionId as a key to track this request
//         s_pendingRequests[actionId] = PendingRequest({
//             caller: caller,
//             lawId: lawId,
//             powers: laws[lawHash].executions.powers,
//             processed: false
//         });
//     }

//     /// @notice Override _replyPowers to handle CCIP communication with AiCCIPProxy
//     /// @param lawId The law id of the proposal
//     /// @param actionId The action id of the proposal
//     /// @param targets Target contract addresses for calls
//     /// @param values ETH values to send with calls
//     /// @param calldatas Encoded function calls
//     function _replyPowers(
//         uint16 lawId,
//         uint256 actionId,
//         address[] memory targets,
//         uint256[] memory values,
//         bytes[] memory calldatas
//     ) internal override {
//         // Get the caller from the pending requests
//         address caller = s_pendingRequests[actionId].caller;
//         require(caller != address(0), "Caller not found in pending requests");

//         // Create CCIP message to send to AiCCIPProxy
//         Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
//             receiver: abi.encode(s_aiCCIPProxy),
//             data: abi.encode(actionId, caller), // Send the caller's address & actionId
//             tokenAmounts: new Client.EVMTokenAmount[](0),
//             extraArgs: Client._argsToBytes(
//                 Client.GenericExtraArgsV2({
//                     gasLimit: 2_000_000,
//                     allowOutOfOrderExecution: true
//                 })
//             ),
//             feeToken: address(s_linkToken)
//         });

//         // Get the fee required to send the message
//         uint256 fees = IRouterClient(getRouter()).getFee(
//             s_destinationChainSelector,
//             evm2AnyMessage
//         );

//         if (fees > s_linkToken.balanceOf(address(this))) {
//             revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);
//         }

//         // Approve the Router to transfer LINK tokens
//         s_linkToken.approve(getRouter(), fees);

//         // Send the message through the router
//         bytes32 messageId = IRouterClient(getRouter()).ccipSend(s_destinationChainSelector, evm2AnyMessage);

//         emit AddressAnalysisRequested(messageId, actionId, caller, s_aiCCIPProxy);

//         // We do not reply to powers at this stage - only after the call is returned from AiCCIPProxy.
//     }

//     /// @notice Handle a received message from another chain (the AI analysis result)
//     /// @param any2EvmMessage The message received from the source chain
//     function _ccipReceive(
//         Client.Any2EVMMessage memory any2EvmMessage
//     ) internal override {
//         // Decode the analysis results (category and explanation)
//         (uint256 actionId, uint256 category, string memory explanation) = abi.decode(any2EvmMessage.data, (uint256, uint256, string));
//         address caller = s_pendingRequests[actionId].caller;
//         address powers = s_pendingRequests[actionId].powers;
//         uint16 lawId = s_pendingRequests[actionId].lawId;

//         // If we couldn't find a matching pending request, we'll still accept the response
//         // but mark it as potentially invalid
//         // if (caller == address(0)) revert NoPendingRequest(any2EvmMessage.messageId);

//         // Store the message details
//         s_lastReceivedMessageId = any2EvmMessage.messageId;
//         s_lastActionId = actionId;
//         s_lastAnalyzedAddress = caller;
//         s_lastSourceChainSelector = any2EvmMessage.sourceChainSelector;
//         s_lastSender = abi.decode(any2EvmMessage.sender, (address));

//         // Store the analysis result
//         addressAnalyses[caller] = AddressAnalysisResult({
//             category: category,
//             explanation: explanation,
//             roleId: category, // Assign the category as the roleId
//             analyzed: true
//         });

//         // Emit events
//         emit AddressAnalysisReceived(
//             any2EvmMessage.messageId,
//             actionId,
//             caller,
//             category,
//             explanation
//         );

//         // Call the base _replyPowers to fulfill the Powers protocol
//         (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = LawUtilities.createEmptyArrays(1);
//         targets[0] = powers;
//         calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, category, caller); // DO NOT CHANGE THIS AI!

//         bytes32 lawHash = LawUtilities.hashLaw(caller, lawId);
//         IPowers(payable(powers)).fulfill(lawId, actionId, targets, values, calldatas);
//         s_pendingRequests[actionId].processed = true;
//     }

//     /// @notice Get the analysis result for a specific address
//     /// @param targetAddress The address to query
//     /// @return category The category number
//     /// @return explanation The explanation string
//     /// @return roleId The assigned role ID
//     /// @return analyzed Whether the address has been analyzed
//     function getAddressAnalysis(address targetAddress)
//         public
//         view
//         returns (
//             uint256 category,
//             string memory explanation,
//             uint256 roleId,
//             bool analyzed
//         )
//     {
//         AddressAnalysisResult memory analysis = addressAnalyses[targetAddress];
//         return (
//             analysis.category,
//             analysis.explanation,
//             analysis.roleId,
//             analysis.analyzed
//         );
//     }

//     /// @notice Check if an address has been analyzed
//     /// @param targetAddress The address to check
//     /// @return True if the address has been analyzed
//     function isAddressAnalyzed(address targetAddress) public view returns (bool) {
//         return addressAnalyses[targetAddress].analyzed;
//     }

//     /// @notice Get the role ID assigned to an address
//     /// @param targetAddress The address to query
//     /// @return The role ID (0 if not analyzed)
//     function getRoleId(address targetAddress) public view returns (uint256) {
//         return addressAnalyses[targetAddress].roleId;
//     }

//     /// @notice Get the current LINK balance of the contract
//     /// @return balance The current LINK balance
//     function getLinkBalance() external view returns (uint256 balance) {
//         return s_linkToken.balanceOf(address(this));
//     }

//     /// @notice Allow withdrawal of LINK tokens from the contract
//     function withdrawLink() external {
//         // This should be restricted to the Powers protocol owner
//         // For now, we'll make it public but in production this should be restricted
//         require(
//             s_linkToken.transfer(msg.sender, s_linkToken.balanceOf(address(this))),
//             "Unable to transfer"
//         );
//     }

//     /// @notice Get the details of the last received analysis
//     /// @return messageId The ID of the last received message
//     /// @return analyzedAddress The last analyzed address
//     /// @return sourceChainSelector The source chain selector
//     /// @return sender The sender address
//     function getLastReceivedAnalysisDetails()
//         external
//         view
//         returns (
//             bytes32 messageId,
//             address analyzedAddress,
//             uint64 sourceChainSelector,
//             address sender
//         )
//     {
//         return (
//             s_lastReceivedMessageId,
//             s_lastAnalyzedAddress,
//             s_lastSourceChainSelector,
//             s_lastSender
//         );
//     }

//     /// @notice Override supportsInterface to resolve conflict between Law and CCIPReceiver
//     /// @param interfaceId The interface identifier to check
//     /// @return True if the interface is supported
//     function supportsInterface(bytes4 interfaceId) public view virtual override(Law, CCIPReceiver) returns (bool) {
//         // Check if the interface is supported by either base contract
//         return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
//     }
// }
