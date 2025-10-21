// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// Base contracts
import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { IPowers } from "../../interfaces/IPowers.sol";

// Chainlink Functions
import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

// OpenZeppelin for signature verification
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title RoleByGitSignature
 * @notice A law that assigns a role to a user if they can prove ownership
 * of a specific GitHub commit via a signed message.
 *
 * The logic:
 * - Takes a roleId and commitHash as input.
 * - Calls Chainlink Functions (executing the `githubSigs.js` script) to:
 * 1. Verify the commit exists on the repo/branch.
 * 2. Verify the commit modified the correct folder (`paths[roleId]`).
 * 3. Verify the commit is recent (e.g., < 90 days).
 * 4. Extract an ETH signature ("0x...") from the commit message.
 * - The `fulfillRequest` callback receives this signature.
 * - It recovers the signer's address from the signature using a pre-defined `signatureString`.
 * - If the recovered address matches the original `caller`, the law grants them the role.
 */
contract RoleByGitSignature is Law, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;
    using ECDSA for bytes32;

    error UnexpectedRequestID(bytes32 requestId);
    error InvalidSignature();
    error InvalidHexCharacter();

    // @notice Configuration data for each instance of the law
    struct Data {
        string repo;
        string branch;
        string[] paths; // Folder paths, indexed by roleId
        uint256[] roleIds;
        string signatureString; // The message that must be signed
        uint64 subscriptionId;
        uint32 gasLimit;
        bytes32 donID;
        string source; // The Chainlink Functions source code
    }

    // --- Mem struct for handleRequest ---
    // (This is just to avoid "stack too deep" errors)
    struct Mem {
        bytes32 lawHash;
        Data data;
        uint256 roleId;
        string commitHash;
        uint256 indexPath;
        string[] args;
    }

    // @notice Stores data about an in-flight request
    struct Request {
        address caller; // The address that initiated the request
        uint256 roleId;
        address powers;
        uint16 lawId;
        uint256 actionId;
    }

    // --- State Variables ---

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 requestId => Request) public requests;

    // --- Constructor ---

    constructor(address router) FunctionsClient(router) {
        // Define the parameters required to configure this law
        bytes memory configParams = abi.encode(
            "string repo",
            "string branch",
            "string[] paths",
            "uint256[] roleIds",
            "string signatureString",
            "uint64 subscriptionId",
            "uint32 gasLimit",
            "bytes32 donID",
            "string source" // The JS source code is now part of config
        );
        emit Law__Deployed(configParams);
    }

    // --- Law Initialization ---

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config
    ) public override {
        // Decode all configuration parameters
        (
            string memory repo,
            string memory branch,
            string[] memory paths,
            uint256[] memory roleIds,
            string memory signatureString,
            uint64 subscriptionId,
            uint32 gasLimit,
            bytes32 donID,
            string memory source
        ) = abi.decode(
            config,
            (string, string, string[], uint256[], string, uint64, uint32, bytes32, string)
        );

        // Store configuration
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash] = Data({
            repo: repo,
            branch: branch,
            paths: paths,
            roleIds: roleIds,
            signatureString: signatureString,
            subscriptionId: subscriptionId,
            gasLimit: gasLimit,
            donID: donID,
            source: source
        });

        // Set input parameters for UI
        inputParams = abi.encode("uint256 roleId", "string commitHash");
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    // --- Law Execution (Request) ---

    function handleRequest(
        address caller, // The user requesting the role
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    ) public view override returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) {
        Mem memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        mem.data = data[mem.lawHash];

        // Hash the action
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Decode input parameters: roleId and the commitHash
        (mem.roleId, mem.commitHash) = abi.decode(lawCalldata, (uint256, string));

        // Find the folder path associated with the requested roleId
        mem.indexPath = findIndex(mem.data.roleIds, mem.roleId);

        // Prepare arguments for Chainlink Functions (githubSigs.js)
        // args[0]: repo
        // args[1]: branch
        // args[2]: commitHash
        // args[3]: folderName (path)
        mem.args = new string[](4);
        mem.args[0] = mem.data.repo;
        mem.args[1] = mem.data.branch;
        mem.args[2] = mem.commitHash;
        mem.args[3] = mem.data.paths[mem.indexPath];

        // Create empty arrays for the execution plan
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);

        // Pack data needed for the _externalCall and fulfillRequest
        calldatas[0] = abi.encode(
            mem.roleId,
            caller, // Pass the original caller
            powers,
            mem.args
        );

        return (actionId, targets, values, calldatas);
    }

    // --- Law Execution (Callback) ---

    function _externalCall(
        uint16 lawId,
        uint256 actionId,
        address[] memory /*targets*/,
        uint256[] memory /*values*/,
        bytes[] memory calldatas
    ) internal override {
        // Decode data from handleRequest
        bytes memory callData = calldatas[0];
        (uint256 roleId, address caller, address powers, string[] memory args) =
            abi.decode(callData, (uint256, address, address, string[]));

        // Get law hash
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);

        // Call Chainlink Functions oracle
        bytes32 requestId = sendRequest(args, lawHash);

        // Store the request details for fulfillment
        requests[requestId] = Request({
            caller: caller, // Store the original caller
            roleId: roleId,
            powers: powers,
            lawId: lawId,
            actionId: actionId
        });
    }

    // --- Chainlink Functions ---

    /**
     * @notice Send a request to Chainlink Functions
     * @dev Uses the `source` code stored in this law's `Data`
     */
    function sendRequest(string[] memory args, bytes32 lawHash) internal returns (bytes32 requestId) {
        Data memory data_ = data[lawHash];

        FunctionsRequest.Request memory req;
        // Initialize request with the source code from config
        req.initializeRequestForInlineJavaScript(data_.source);
        if (args.length > 0) req.setArgs(args);

        // Send the request
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            data_.subscriptionId,
            data_.gasLimit,
            data_.donID
        );
        return s_lastRequestId;
    }

    /**
     * @notice Handle Chainlink Functions response
     * @dev This is where the signature verification happens
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        s_lastResponse = response;
        s_lastError = err;

        if (err.length > 0) {
            revert(string(err));
        }
        if (response.length == 0) {
            revert("No response from the API");
        }

        // Get the pending request
        Request memory request = requests[requestId];

        // Get the law's config data
        bytes32 lawHash = LawUtilities.hashLaw(request.powers, request.lawId);
        Data memory data_ = data[lawHash];

        // --- Signature Verification ---

        // 1. Decode the signature (returned as a hex string "0x...")
        string memory signatureHex = abi.decode(abi.encode(response), (string));
        bytes memory signatureBytes = hexStringToBytes(signatureHex);

        // 2. Hash the pre-defined message (EIP-191)
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(
            bytes(data_.signatureString)
        );

        // 3. Recover the signer's address
        address signer = messageHash.recover(signatureBytes);

        if (signer == address(0)) {
            revert InvalidSignature();
        }

        // 4. Check if the signer matches the original caller
        if (signer == request.caller) {
            // Success! Prepare the call to assign the role.
            address[] memory targets = new address[](1);
            uint256[] memory values = new uint256[](1);
            bytes[] memory calldatas = new bytes[](1);

            targets[0] = request.powers;
            calldatas[0] = abi.encodeWithSelector(
                Powers.assignRole.selector,
                request.roleId,
                request.caller // Grant role to the original caller
            );

            // Fulfill the action
            IPowers(payable(request.powers)).fulfill(
                request.lawId,
                request.actionId,
                targets,
                values,
                calldatas
            );
        }
        // If signer != caller, we simply do nothing. The request times out.
        // An event could be emitted here for off-chain monitoring.
    }

    // --- View Functions ---

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }

    function getRouter() public view returns (address) {
        return address(i_router);
    }

    function findIndex(uint256[] memory roleIds, uint256 roleId) public pure returns (uint256) {
        for (uint256 i = 0; i < roleIds.length; i++) {
            if (roleIds[i] == roleId) {
                return i;
            }
        }
        revert("RoleId not found");
    }

    // --- Utility Functions ---

    /**
     * @notice Converts a hex string (e.g., "0x1a2b...") to bytes.
     * @dev From https://ethereum.stackexchange.com/a/8171
     */
    function hexStringToBytes(string memory hex) internal pure returns (bytes memory) {
        bytes memory bts = new bytes(bytes(hex).length / 2 - 1);
        for (uint i = 0; i < bts.length; i++) {
            bts[i] = bytes1(
                (hexToByte(bytes(hex)[i * 2 + 2]) << 4) |
                hexToByte(bytes(hex)[i * 2 + 3])
            );
        }
        return bts;
    }

    function hexToByte(bytes1 b) internal pure returns (uint8) {
        if (b >= bytes1(uint8(48)) && b <= bytes1(uint8(57))) { // 0-9
            return uint8(b) - 48;
        }
        if (b >= bytes1(uint8(97)) && b <= bytes1(uint8(102))) { // a-f
            return uint8(b) - 87;
        }
        if (b >= bytes1(uint8(65)) && b <= bytes1(uint8(70))) { // A-F
            return uint8(b) - 55;
        }
        revert InvalidHexCharacter();
    }


}