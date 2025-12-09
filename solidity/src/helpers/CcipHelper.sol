// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { Client } from "@chainlink/contracts-ccip/libraries/Client.sol";
import { CCIPReceiver } from "@chainlink/contracts-ccip/applications/CCIPReceiver.sol";
import { IRouterClient } from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import { PowersTypes } from "../interfaces/PowersTypes.sol";
import { IPowers } from "../interfaces/IPowers.sol";

contract CcipHelper is CCIPReceiver, ConfirmedOwner {
    // Custom errors
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);

    // Events
    event StateReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        uint256 actionId,
        address powersAddress
    );

    event StateSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        uint256 actionId,
        PowersTypes.ActionState state,
        address feeToken,
        uint256 fees
    );

    /**
     * @notice Constructor initializes the contract with the router address
     * @param router The address of the CCIP router contract
     */
    constructor(address router, address owner_) CCIPReceiver(router) ConfirmedOwner(owner_) { }

    /**
     * @notice Handle a received message from another chain
     * @param any2EvmMessage The message received from the source chain
     */
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        // Decode the received data
        (uint256 actionId, address powersAddress) = abi.decode(any2EvmMessage.data, (uint256, address));

        address originalSender = abi.decode(any2EvmMessage.sender, (address));

        emit StateReceived(
            any2EvmMessage.messageId, any2EvmMessage.sourceChainSelector, originalSender, actionId, powersAddress
        );

        // Get the action state
        PowersTypes.ActionState state = IPowers(powersAddress).getActionState(actionId);

        // Send the state back to the original sender
        _sendStateBack(originalSender, actionId, state, any2EvmMessage.sourceChainSelector);
    }

    /**
     * @notice Internal function to send the action state back to the original sender
     * @param receiver The address to send back to (original sender)
     * @param actionId The action ID
     * @param state The action state
     * @param destinationChainSelector The destination chain selector
     * @return messageId The ID of the message that was sent
     */
    function _sendStateBack(
        address receiver,
        uint256 actionId,
        PowersTypes.ActionState state,
        uint64 destinationChainSelector
    ) internal returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct in memory
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(actionId, state), // Encode actionId and state
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: 200_000, // 200k gas limit, adjust as needed
                    allowOutOfOrderExecution: true
                })
            ),
            feeToken: address(0) // Use native currency
        });

        // Get the fee required to send the message
        uint256 fees = IRouterClient(getRouter()).getFee(destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance) {
            revert NotEnoughBalance(address(this).balance, fees);
        }

        // Send the message through the router, paying with native currency
        messageId = IRouterClient(getRouter()).ccipSend{ value: fees }(destinationChainSelector, evm2AnyMessage);

        // Emit event for the reply message
        emit StateSent(messageId, destinationChainSelector, receiver, actionId, state, address(0), fees);

        return messageId;
    }

    /**
     * @notice Allow owner to withdraw native currency from the contract
     */
    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Unable to withdraw");
    }

    /**
     * @notice Get the current native currency balance of the contract
     * @return balance The current balance
     */
    function getBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }
}
