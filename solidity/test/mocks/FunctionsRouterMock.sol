// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { IFunctionsRouter } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";
import { FunctionsResponse } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsResponse.sol";

contract FunctionsRouterMock is IFunctionsRouter {
    mapping(bytes32 => address) public requestToClient;
    mapping(bytes32 => bool) public requestFulfilled;
    
    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint16 dataVersion,
        uint32 callbackGasLimit,
        bytes32 donId
    ) external override returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, subscriptionId, data));
        requestToClient[requestId] = msg.sender;
        requestFulfilled[requestId] = false;
        return requestId;
    }
    
    // Simulate a callback (no actual call to client)
    function fulfillRequest(
        bytes32 requestId,
        bytes calldata response,
        bytes calldata err
    ) external {
        require(requestToClient[requestId] != address(0), "Request not found");
        require(!requestFulfilled[requestId], "Request already fulfilled");
        // In a real router, this would call the client contract. Here, it's a stub.
    }
    
    // Required by interface, returns dummy values
    function getRequestConfig() external pure returns (uint16, uint32, bytes32[] memory) {
        bytes32[] memory donIds = new bytes32[](1);
        donIds[0] = bytes32(uint256(1));
        return (1, 300000, donIds);
    }
    function getContractById(bytes32) external pure override returns (address) { return address(0); }
    function getProposedContractSet() external pure override returns (bytes32[] memory, address[] memory) {
        bytes32[] memory ids = new bytes32[](0);
        address[] memory addresses = new address[](0);
        return (ids, addresses);
    }
    function proposeContractsUpdate(bytes32[] calldata, address[] calldata) external override {}
    function updateContracts() external override {}
    function pause() external override {}
    function unpause() external override {}
    function getAllowListId() external pure override returns (bytes32) { return bytes32(0); }
    function setAllowListId(bytes32) external override {}
    function getAdminFee() external pure override returns (uint72) { return 0; }
    function sendRequestToProposed(
        uint64 subscriptionId,
        bytes calldata data,
        uint16 dataVersion,
        uint32 callbackGasLimit,
        bytes32 donId
    ) external override returns (bytes32 requestId) {
        return this.sendRequest(subscriptionId, data, dataVersion, callbackGasLimit, donId);
    }
    function getProposedContractById(bytes32) external pure override returns (address) { return address(0); }
    function isValidCallbackGasLimit(uint64, uint32) external pure override {}
        // Required stub for interface compliance
    function fulfill(
        bytes memory response,
        bytes memory err,
        uint96 juelsPerGas,
        uint96 costWithoutFulfillment,
        address transmitter,
        FunctionsResponse.Commitment memory commitment
    ) external returns (FunctionsResponse.FulfillResult, uint96) {
        return (FunctionsResponse.FulfillResult.FULFILLED, 0);
    }
} 