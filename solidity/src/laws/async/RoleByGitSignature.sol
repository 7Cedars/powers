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
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
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
        address powers;
        uint16 lawId;
        uint256 actionId;
        string signatureHex;
        bytes signatureBytes;
        address caller;
        uint256 roleId;
        string commitHash;
        uint256 indexPath;
        string[] args;
        bytes callData;
        bytes32 requestId;
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
    bytes32 private s_messageHash;
    address private s_signer;
    // note that the repo is hard coded in the source code of this law. This is to avoid having to pass it as a parameter to the law.
    string internal constant source = "const branch = args[0];\nconst commitHash = args[1];\nconst folderName = args[2]; \n\nif (!branch || !commitHash || !folderName) {\n    throw Error(\"Missing required args\");\n}\n\nconst url = `https://powers-protocol.vercel.app/api/check-commit`; \n\nconst githubRequest = Functions.makeHttpRequest({\n    url: url,\n    method: \"GET\",\n    timeout: 9000, \n    params: {\n        repo: \"7cedars/powers\",\n        branch: branch,\n        commitHash: commitHash,\n        maxAgeCommitInDays: 90,\n        folderName: folderName\n    }\n});\n\n \nconst githubResponse = await githubRequest;\nif (githubResponse.error || !githubResponse.data || !githubResponse.data.data || !githubResponse.data.data.signature) {\n    throw Error(`Request Failed: ${githubResponse.error.message}`);\n}\n\nreturn Functions.encodeString(githubResponse.data.data.signature);";

    mapping(bytes32 lawHash => Data) internal data;
    mapping(bytes32 requestId => Request) public requests;

    // --- Constructor ---

    constructor(address router) FunctionsClient(router) {
        // Define the parameters required to configure this law
        bytes memory configParams = abi.encode(
            "string branch",
            "string[] paths",
            "uint256[] roleIds",
            "string signatureString",
            "uint64 subscriptionId",
            "uint32 gasLimit",
            "bytes32 donID"
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
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        
        // Decode all configuration parameters once
        (
            string memory branch,
            string[] memory paths,
            uint256[] memory roleIds,
            string memory signatureString,
            uint64 subscriptionId,
            uint32 gasLimit,
            bytes32 donID
        ) = abi.decode(
            config,
            (string, string[], uint256[], string, uint64, uint32, bytes32)
        );
        
        // Store in separate scopes to avoid stack too deep
        {
            data[lawHash].branch = branch;
            data[lawHash].paths = paths;
            data[lawHash].roleIds = roleIds;
        }
        
        {
            data[lawHash].signatureString = signatureString;
            data[lawHash].subscriptionId = subscriptionId;
            data[lawHash].gasLimit = gasLimit;
            data[lawHash].donID = donID;
        }

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
        Data memory data_ = data[mem.lawHash];

        // Hash the action
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Decode input parameters: roleId and the commitHash
        (mem.roleId, mem.commitHash) = abi.decode(lawCalldata, (uint256, string));

        // Find the folder path associated with the requested roleId
        mem.indexPath = findIndex(data_.roleIds, mem.roleId);

        // Prepare arguments for Chainlink Functions (githubSigs.js)
        mem.args = new string[](3);
        mem.args[0] = data_.branch;
        mem.args[1] = mem.commitHash;
        mem.args[2] = data_.paths[mem.indexPath];

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
        Mem memory mem;
        mem.lawId = lawId;
        mem.actionId = actionId;
        mem.callData = calldatas[0];
        (mem.roleId, mem.caller, mem.powers, mem.args) =
            abi.decode(mem.callData, (uint256, address, address, string[]));

        // Get law hash
        mem.lawHash = LawUtilities.hashLaw(mem.powers, mem.lawId);

        // Call Chainlink Functions oracle
        mem.requestId = sendRequest(mem.args, mem.lawHash);

        // Store the request details for fulfillment
        requests[mem.requestId] = Request({
            caller: mem.caller, // Store the original caller
            roleId: mem.roleId,
            powers: mem.powers,
            lawId: mem.lawId,
            actionId: mem.actionId
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
        /// memory helper 
        Mem memory mem;

        // Get the law's config data
        mem.lawHash = LawUtilities.hashLaw(request.powers, request.lawId);
        Data memory data_ = data[mem.lawHash];

        // --- Signature Verification ---

        // 1. Decode the signature (returned as a hex string "0x...")
        mem.signatureHex = abi.decode(abi.encode(response), (string));
        mem.signatureBytes = LawUtilities.hexStringToBytes(mem.signatureHex);

        // 2. Hash the pre-defined message (EIP-191)
        s_messageHash = MessageHashUtils.toEthSignedMessageHash(
            bytes(data_.signatureString)
        );

        // 3. Recover the signer's address
        s_signer = s_messageHash.recover(mem.signatureBytes);

        if (s_signer == address(0)) {
            revert InvalidSignature();
        }

        // 4. Check if the signer matches the original caller
        if (s_signer == request.caller) {
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



}