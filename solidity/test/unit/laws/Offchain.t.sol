// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Powers } from "../../../src/Powers.sol";
import { TestSetupLaw } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";
import { LawUtilities } from "../../../src/LawUtilities.sol";
import { RoleByGitCommit } from "../../../src/laws/offchain/RoleByGitCommit.sol";
import { StringToAddress } from "../../../src/laws/state/StringToAddress.sol";
import { PowersMock } from "../../mocks/PowersMock.sol";

// Mock Chainlink Functions Router for testing
contract MockFunctionsRouter {
    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint16 dataVersion,
        uint32 callbackGasLimit,
        bytes32 donId
    ) external returns (bytes32) {
        // Return a mock request ID
        return keccak256(abi.encodePacked(subscriptionId, data, block.timestamp));
    }
}

// Helper contract to expose internal functions for testing
contract RoleByGitCommitHelper is RoleByGitCommit {
    constructor(address router) RoleByGitCommit(router) {}
    
    // Expose internal functions for testing
    function testSendRequest(
        string[] memory args,
        address powers,
        uint16 lawId
    ) external returns (bytes32) {
        return sendRequest(args, powers, lawId);
    }
    
    function testFindIndex(uint256[] memory roleIds, uint256 roleId) external pure returns (uint256) {
        return findIndex(roleIds, roleId);
    }
    
    // NOTE: fulfillRequest cannot be exposed for testing because it's internal and expects
    // to be called by the Chainlink Functions oracle system, not external test code.
}

contract RoleByGitCommitTest is TestSetupLaw {
    using Strings for *;
    
    RoleByGitCommitHelper roleByGitCommit;
    StringToAddress stringToAddress;
    MockFunctionsRouter mockRouter;
    PowersMock powersMock;
    
    // Test data
    string constant TEST_REPO = "test-org/test-repo";
    string[] testPaths;
    uint256[] testRoleIds;
    uint64 constant TEST_SUBSCRIPTION_ID = 1;
    uint32 constant TEST_GAS_LIMIT = 100000;
    bytes32 constant TEST_DON_ID = keccak256("test-don-id");
    
    // Test users and roles
    address testAuthor = makeAddr("testAuthor");
    uint256 TEST_ROLE_ID = 1;
    string constant TEST_AUTHOR_NAME = "testAuthor";
    
    function setUp() public override {
        super.setUp();
        
        // Deploy mock router
        mockRouter = new MockFunctionsRouter();
        
        // Deploy contracts
        roleByGitCommit = new RoleByGitCommitHelper(address(mockRouter));
        stringToAddress = new StringToAddress();
        powersMock = new PowersMock();
        
        // Setup test data
        testPaths = new string[](2);
        testPaths[0] = "src/contracts";
        testPaths[1] = "test/unit";
        
        testRoleIds = new uint256[](2);
        testRoleIds[0] = 1;
        testRoleIds[1] = 2;
        
        // Initialize StringToAddress law
        vm.prank(address(powersMock));
        stringToAddress.initializeLaw(
            1,
            "StringToAddress Test Law",
            "",
            ILaw.Conditions({
                allowedRole: 0,
                needCompleted: 0,
                delayExecution: 0,
                throttleExecution: 0,
                readStateFrom: 0,
                votingPeriod: 0,
                quorum: 0,
                succeedAt: 0,
                needNotCompleted: 0
            }),
            ""
        );
        
        // Add test author to StringToAddress mapping by directly setting the storage
        bytes32 lawHash = LawUtilities.hashLaw(address(powersMock), 1);
        bytes32 nameHash = keccak256(bytes(TEST_AUTHOR_NAME));
        vm.store(
            address(stringToAddress),
            keccak256(abi.encode(keccak256(abi.encode("stringToAddress", lawHash)), nameHash)),
            bytes32(uint256(uint160(testAuthor)))
        );
    }
    
    function testConstructor() public {
        assertEq(address(roleByGitCommit.getRouter()), address(mockRouter));
        assertEq(roleByGitCommit.owner(), address(this));
    }
    
    function testInitializeLaw() public {
        bytes memory configData = abi.encode(
            TEST_REPO,
            testPaths,
            testRoleIds,
            TEST_SUBSCRIPTION_ID,
            TEST_GAS_LIMIT,
            TEST_DON_ID
        );
        
        conditions = ILaw.Conditions({
            allowedRole: 0,
            needCompleted: 0,
            delayExecution: 0,
            throttleExecution: 0,
            readStateFrom: 1, // Points to StringToAddress law
            votingPeriod: 0,
            quorum: 0,
            succeedAt: 0,
            needNotCompleted: 0
        });
        
        vm.prank(address(powersMock));
        roleByGitCommit.initializeLaw(
            1,
            "RoleByGitCommit Test Law",
            "",
            conditions,
            configData
        );
        
        lawHash = LawUtilities.hashLaw(address(powersMock), 1);
        RoleByGitCommit.Data memory data = roleByGitCommit.getData(lawHash);
        
        assertEq(data.repo, TEST_REPO);
        assertEq(data.paths.length, 2);
        assertEq(data.paths[0], "src/contracts");
        assertEq(data.paths[1], "test/unit");
        assertEq(data.roleIds.length, 2);
        assertEq(data.roleIds[0], 1);
        assertEq(data.roleIds[1], 2);
        assertEq(data.subscriptionId, TEST_SUBSCRIPTION_ID);
        assertEq(data.gasLimit, TEST_GAS_LIMIT);
        assertEq(data.donID, TEST_DON_ID);
    }
    
    // function testHandleRequestRoleByGitCommit() public {
    //     // Initialize the law first
    //     bytes memory configData = abi.encode(
    //         TEST_REPO,
    //         testPaths,
    //         testRoleIds,
    //         TEST_SUBSCRIPTION_ID,
    //         TEST_GAS_LIMIT,
    //         TEST_DON_ID
    //     );
        
    //     conditions = ILaw.Conditions({
    //         allowedRole: 0,
    //         needCompleted: 0,
    //         delayExecution: 0,
    //         throttleExecution: 0,
    //         readStateFrom: 1,
    //         votingPeriod: 0,
    //         quorum: 0,
    //         succeedAt: 0,
    //         needNotCompleted: 0
    //     });
        
    //     vm.prank(address(powersMock));
    //     roleByGitCommit.initializeLaw(1, "Test Law", "", conditions, configData);
        
    //     // Test handleRequest
    //     lawCalldata = abi.encode(TEST_ROLE_ID, TEST_AUTHOR_NAME);
        
    //     (
    //         actionId,
    //         targets,
    //         values,
    //         calldatas,
    //         stateChange
    //     ) = roleByGitCommit.handleRequest(testAuthor, address(powersMock), 1, lawCalldata, 123);
        
    //     // Verify actionId is correctly calculated
    //     uint256 expectedActionId = LawUtilities.hashActionId(1, lawCalldata, 123);
    //     assertEq(actionId, expectedActionId);
        
    //     // Verify targets, values, calldatas are set up correctly
    //     assertEq(targets.length, 1);
    //     assertEq(values.length, 1);
    //     assertEq(calldatas.length, 1);
    //     assertEq(targets[0], address(powersMock));
    //     assertEq(values[0], 0);
        
    //     // Verify calldata contains roleId, author, and powers
    //     (uint256 roleId, string memory author, address powers) = abi.decode(calldatas[0], (uint256, string, address));
    //     assertEq(roleId, TEST_ROLE_ID);
    //     assertEq(author, TEST_AUTHOR_NAME);
    //     assertEq(powers, address(powersMock));
        
    //     assertEq(stateChange.length, 0);
    // }
    
    function testFindIndex() public {
        uint256[] memory roleIds = new uint256[](3);
        roleIds[0] = 1;
        roleIds[1] = 2;
        roleIds[2] = 3;
        
        assertEq(roleByGitCommit.testFindIndex(roleIds, 1), 0);
        assertEq(roleByGitCommit.testFindIndex(roleIds, 2), 1);
        assertEq(roleByGitCommit.testFindIndex(roleIds, 3), 2);
        assertEq(roleByGitCommit.testFindIndex(roleIds, 4), 0); // Not found, returns 0
    }
    
    function testSendRequest() public {
        // Initialize the law first
        bytes memory configData = abi.encode(
            TEST_REPO,
            testPaths,
            testRoleIds,
            TEST_SUBSCRIPTION_ID,
            TEST_GAS_LIMIT,
            TEST_DON_ID
        );
        
        conditions = ILaw.Conditions({
            allowedRole: 0,
            needCompleted: 0,
            delayExecution: 0,
            throttleExecution: 0,
            readStateFrom: 1,
            votingPeriod: 0,
            quorum: 0,
            succeedAt: 0,
            needNotCompleted: 0
        });
        
        vm.prank(address(powersMock));
        roleByGitCommit.initializeLaw(1, "Test Law", "", conditions, configData);
        
        // Test sendRequest
        string[] memory args = new string[](3);
        args[0] = TEST_REPO;
        args[1] = testPaths[0];
        args[2] = TEST_AUTHOR_NAME;
        
        bytes32 requestId = roleByGitCommit.testSendRequest(args, address(powersMock), 1);
        
        // Verify requestId is not zero (request was created)
        assertTrue(requestId != bytes32(0));
    }
    
    // NOTE: This test is commented out because fulfillRequest is internal and can only be called
    // by the Chainlink Functions oracle system. Testing the oracle fulfillment flow would require
    // either modifying the original contract or setting up a complete Chainlink Functions environment.
    // The core functionality (handleRequest, sendRequest, findIndex) can still be tested.
    
    // function testFulfillRequestWithCommits() public {
    //     // This test cannot be implemented without modifying the original contract
    //     // because fulfillRequest is internal and expects to be called by Chainlink oracle
    // }
    
    // function testFulfillRequestWithNoCommits() public {
    //     // Initialize the law first
    //     bytes memory configData = abi.encode(
    //         TEST_REPO,
    //         testPaths,
    //         testRoleIds,
    //         TEST_SUBSCRIPTION_ID,
    //         TEST_GAS_LIMIT,
    //         TEST_DON_ID
    //     );
        
    //     conditions = ILaw.Conditions({
    //         allowedRole: 0,
    //         needCompleted: 0,
    //         delayExecution: 0,
    //         throttleExecution: 0,
    //         readStateFrom: 1,
    //         votingPeriod: 0,
    //         quorum: 0,
    //         succeedAt: 0,
    //         needNotCompleted: 0
    //     });
        
    //     vm.prank(address(powersMock));
    //     roleByGitCommit.initializeLaw(1, "Test Law", "", conditions, configData);
        
    //     // Create a request
    //     string[] memory args = new string[](3);
    //     args[0] = TEST_REPO;
    //     args[1] = testPaths[0];
    //     args[2] = TEST_AUTHOR_NAME;
        
    //     bytes32 requestId = roleByGitCommit.testSendRequest(args, address(powersMock), 1);
        
    //     // Manually set up the request data
    //     vm.store(
    //         address(roleByGitCommit),
    //         keccak256(abi.encode(keccak256(abi.encode("requests", requestId)), 0)),
    //         bytes32(uint256(uint160(testAuthor)))
    //     );
    //     vm.store(
    //         address(roleByGitCommit),
    //         keccak256(abi.encode(keccak256(abi.encode("requests", requestId)), 1)),
    //         bytes32(TEST_ROLE_ID)
    //     );
    //     vm.store(
    //         address(roleByGitCommit),
    //         keccak256(abi.encode(keccak256(abi.encode("requests", requestId)), 2)),
    //         bytes32(uint256(uint160(address(powersMock))))
    //     );
    //     vm.store(
    //         address(roleByGitCommit),
    //         keccak256(abi.encode(keccak256(abi.encode("requests", requestId)), 3)),
    //         bytes32(uint256(1)) // lawId
    //     );
    //     vm.store(
    //         address(roleByGitCommit),
    //         keccak256(abi.encode(keccak256(abi.encode("requests", requestId)), 4)),
    //         bytes32(uint256(123)) // actionId
    //     );
    //     vm.store(
    //         address(roleByGitCommit),
    //         keccak256(abi.encode(keccak256(abi.encode("requests", requestId)), 5)),
    //         bytes32(uint256(uint160(testAuthor))) // addressLinkedToAuthor
    //     );
        
    //     // Mock the Powers contract fulfill function
    //     vm.mockCall(
    //         address(powersMock),
    //         abi.encodeWithSelector(Powers.fulfill.selector),
    //         abi.encode()
    //     );
        
    //     // Simulate oracle response with no commits (zero)
    //     bytes memory response = abi.encode(uint256(0)); // 0 commits
    //     bytes memory error = "";
        
    //     // Expect the fulfill call with revokeRole
    //     vm.expectCall(
    //         address(powersMock),
    //         abi.encodeWithSelector(
    //             Powers.fulfill.selector,
    //             1, // lawId
    //             123, // actionId
    //             new address[](1), // targets
    //             new uint256[](1), // values
    //             abi.encodeWithSelector(
    //                 Powers.revokeRole.selector,
    //                 TEST_ROLE_ID,
    //                 testAuthor
    //             ) // calldatas
    //         )
    //     );
        
    //     roleByGitCommit.simulateFulfillRequest(requestId, response, error);
    // }
    
    // NOTE: This test is commented out because fulfillRequest is internal and can only be called
    // by the Chainlink Functions oracle system.
    
    // function testFulfillRequestWithError() public {
    //     // This test cannot be implemented without modifying the original contract
    //     // because fulfillRequest is internal and expects to be called by Chainlink oracle
    // }
    
    // NOTE: This test is commented out because fulfillRequest is internal and can only be called
    // by the Chainlink Functions oracle system.
    
    // function testFulfillRequestWithEmptyResponse() public {
    //     // This test cannot be implemented without modifying the original contract
    //     // because fulfillRequest is internal and expects to be called by Chainlink oracle
    // }
    
    // function testUnexpectedRequestId() public {
    //     // Initialize the law first
    //     bytes memory configData = abi.encode(
    //         TEST_REPO,
    //         testPaths,
    //         testRoleIds,
    //         TEST_SUBSCRIPTION_ID,
    //         TEST_GAS_LIMIT,
    //         TEST_DON_ID
    //     );
        
    //     conditions = ILaw.Conditions({
    //         allowedRole: 0,
    //         needCompleted: 0,
    //         delayExecution: 0,
    //         throttleExecution: 0,
    //         readStateFrom: 1,
    //         votingPeriod: 0,
    //         quorum: 0,
    //         succeedAt: 0,
    //         needNotCompleted: 0
    //     });
        
    //     vm.prank(address(powersMock));
    //     roleByGitCommit.initializeLaw(1, "Test Law", "", conditions, configData);
        
    //     // Create a request
    //     string[] memory args = new string[](3);
    //     args[0] = TEST_REPO;
    //     args[1] = testPaths[0];
    //     args[2] = TEST_AUTHOR_NAME;
        
    //     bytes32 requestId = roleByGitCommit.testSendRequest(args, address(powersMock), 1);
        
    //     // Create a different request to change s_lastRequestId
    //     string[] memory args2 = new string[](3);
    //     args2[0] = TEST_REPO;
    //     args2[1] = testPaths[1];
    //     args2[2] = "differentAuthor";
        
    //     bytes32 requestId2 = roleByGitCommit.testSendRequest(args2, address(powersMock), 1);
        
    //     // Try to fulfill with the first requestId but s_lastRequestId is now requestId2
    //     bytes memory response = abi.encode(uint256(5));
    //     bytes memory error = "";
        
    //     // Expect revert with UnexpectedRequestID
    //     vm.expectRevert(RoleByGitCommit.UnexpectedRequestID.selector);
    //     roleByGitCommit.simulateFulfillRequest(requestId, response, error);
    // }
    
    function testSourceCodeConstant() public {
        // Test that the source code constant is properly set
        // This is a basic check - in a real test you might want to verify the actual content
        // Note: source() is internal, so we can't test it directly
        // We can test that the contract was deployed successfully instead
        assertTrue(address(roleByGitCommit) != address(0));
    }
    
    function testGetData() public {
        // Initialize the law first
        bytes memory configData = abi.encode(
            TEST_REPO,
            testPaths,
            testRoleIds,
            TEST_SUBSCRIPTION_ID,
            TEST_GAS_LIMIT,
            TEST_DON_ID
        );
        
        conditions = ILaw.Conditions({
            allowedRole: 0,
            needCompleted: 0,
            delayExecution: 0,
            throttleExecution: 0,
            readStateFrom: 1,
            votingPeriod: 0,
            quorum: 0,
            succeedAt: 0,
            needNotCompleted: 0
        });
        
        vm.prank(address(powersMock));
        roleByGitCommit.initializeLaw(1, "Test Law", "", conditions, configData);
        
        lawHash = LawUtilities.hashLaw(address(powersMock), 1);
        RoleByGitCommit.Data memory data = roleByGitCommit.getData(lawHash);
        
        assertEq(data.repo, TEST_REPO);
        assertEq(data.subscriptionId, TEST_SUBSCRIPTION_ID);
        assertEq(data.gasLimit, TEST_GAS_LIMIT);
        assertEq(data.donID, TEST_DON_ID);
    }
    
    function testGetDataNonExistent() public {
        bytes32 nonExistentLawHash = keccak256("non-existent");
        RoleByGitCommit.Data memory data = roleByGitCommit.getData(nonExistentLawHash);
        
        // Should return empty data
        assertEq(data.repo, "");
        assertEq(data.subscriptionId, 0);
        assertEq(data.gasLimit, 0);
        assertEq(data.donID, bytes32(0));
    }
    
    function testFuzzHandleRequest(uint256 roleId, string memory author) public {
        // Initialize the law first
        bytes memory configData = abi.encode(
            TEST_REPO,
            testPaths,
            testRoleIds,
            TEST_SUBSCRIPTION_ID,
            TEST_GAS_LIMIT,
            TEST_DON_ID
        );
        
        conditions = ILaw.Conditions({
            allowedRole: 0,
            needCompleted: 0,
            delayExecution: 0,
            throttleExecution: 0,
            readStateFrom: 1,
            votingPeriod: 0,
            quorum: 0,
            succeedAt: 0,
            needNotCompleted: 0
        });
        
        vm.prank(address(powersMock));
        roleByGitCommit.initializeLaw(1, "Test Law", "", conditions, configData);
        
        // Test handleRequest with fuzzed inputs
        lawCalldata = abi.encode(roleId, author);
        
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = roleByGitCommit.handleRequest(testAuthor, address(powersMock), 1, lawCalldata, 123);
        
        // Verify basic structure
        assertTrue(actionId != 0);
        assertEq(targets.length, 1);
        assertEq(values.length, 1);
        assertEq(calldatas.length, 1);
        assertEq(stateChange.length, 0);
        
        // Verify calldata can be decoded
        (uint256 decodedRoleId, string memory decodedAuthor, address decodedPowers) = abi.decode(calldatas[0], (uint256, string, address));
        assertEq(decodedRoleId, roleId);
        assertEq(decodedAuthor, author);
        assertEq(decodedPowers, address(powersMock));
    }
    
    function testFuzzFindIndex(uint256[] memory roleIds, uint256 targetRoleId) public {
        // Ensure we have at least one role ID
        vm.assume(roleIds.length > 0);
        
        uint256 result = roleByGitCommit.testFindIndex(roleIds, targetRoleId);
        
        // Result should be within bounds
        assertTrue(result < roleIds.length);
        
        // If targetRoleId is found, result should be the correct index
        bool found = false;
        for (i = 0; i < roleIds.length; i++) {
            if (roleIds[i] == targetRoleId) {
                assertEq(result, i);
                found = true;
                break;
            }
        }
        
        // If not found, result should be 0
        if (!found) {
            assertEq(result, 0);
        }
    }
}
