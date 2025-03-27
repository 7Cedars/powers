// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;

// // test setup
// import "forge-std/Test.sol";
// import { TestSetupGovernYourTax } from "../../../TestSetup.t.sol";

// // protocol
// import { Powers } from "../../../../src/Powers.sol";
// import { Law } from "../../../../src/Law.sol";
// import { Erc1155Mock } from "../../../mocks/Erc1155Mock.sol";
// import { Erc20VotesMock } from "../../../mocks/Erc20VotesMock.sol";
// import { Erc20TaxedMock } from "../../../mocks/Erc20TaxedMock.sol";

// // law contracts being tested
// import { Grant } from "../../../../src/laws/bespoke/governYourTax/Grant.sol";
// import { StartGrant } from "../../../../src/laws/bespoke/governYourTax/StartGrant.sol";
// import { StopGrant } from "../../../../src/laws/bespoke/governYourTax/StopGrant.sol";
// import { SelfDestructAction } from "../../../../src/laws/executive/SelfDestructAction.sol";
// import { Erc20VotesMock } from "../../../mocks/Erc20VotesMock.sol";
// import { RoleByTaxPaid } from "../../../../src/laws/bespoke/governYourTax/RoleByTaxPaid.sol";

// // openzeppelin contracts
// import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// contract AssignCouncilRoleTest is TestSetupGovernYourTax {

//   function testConstructorInitialization() public {
//     address assignCouncilRole = laws[6];

//     assertTrue(Powers(daoMock).getActiveLaw(assignCouncilRole), "Law should be active after initialization");
//     assertEq(Law(assignCouncilRole).powers(), address(daoMock), "Powers address should be set correctly");
//     assertEq(Law(assignCouncilRole).allowedRole(), 2, "Allowed role should be Governors");
//   }

//   function testAssignCouncillorSucceedsWithValidRole() public {
//     // prep
//     address nominateMe = laws[5];
//     address assignCouncilRole = laws[6];
//     bytes memory lawCalldata = abi.encode(
//       4, // roleId - Grant Council role
//       alice // account
//     );

//     // assign roles
//     vm.startPrank(address(daoMock));
//     daoMock.assignRole(2, alice); // assign alice to role 2 (Governors)
//     daoMock.assignRole(1, alice); // assign alice to role 1 (Member)
//     vm.stopPrank();

//     vm.prank(alice);
//     daoMock.request(
//       nominateMe,
//       abi.encode(true),
//       nonce,
//       "Alice nominates herself"
//     );

//     vm.roll(100);
//     vm.startPrank(alice);
//     daoMock.request(
//       assignCouncilRole,
//       lawCalldata,
//       nonce,
//       "Alice requests to be assigned council role"
//     );
//     vm.stopPrank();

//     // assert output
//     assertEq(daoMock.hasRoleSince(alice, 4), 100, "Alice should have council role");
//   }

//   function testAssignCouncilRoleRevertsIfRoleNotAllowed() public {
//     // prep
//     address nominateMe = laws[5];
//     address assignCouncilRole = laws[6];
//     bytes memory lawCalldata = abi.encode(
//       3, // roleId - Not in allowed council roles [4,5,6]
//       alice // account
//     );

//     // assign roles
//     vm.startPrank(address(daoMock));
//     daoMock.assignRole(2, alice); // assign alice to role 2 (Governors)
//     daoMock.assignRole(1, alice); // assign alice to role 2 (Governors)
//     vm.stopPrank();

//     vm.prank(alice);
//     daoMock.request(
//       nominateMe,
//       abi.encode(true),
//       nonce,
//       "Alice nominates herself"
//     );

//     vm.expectRevert("Role not allowed.");
//     vm.prank(address(daoMock));
//     Law(assignCouncilRole).executeLaw(
//       alice, // alice = caller
//       lawCalldata,
//       nonce
//     );
//   }

//   function testAssignCouncilRoleRevertsIfAccountNotNominated() public {
//     // prep
//     address assignCouncilRole = laws[6];
//     bytes memory lawCalldata = abi.encode(
//       4, // allowed roleId - Grant Council role
//       alice // account
//     );

//     // assign roles
//     vm.prank(address(daoMock));
//     daoMock.assignRole(2, alice); // assign alice to role 2 (Governors)

//     // note: no nomination.

//     vm.expectRevert("Account not nominated.");
//     vm.prank(address(daoMock));
//     Law(assignCouncilRole).executeLaw(
//       alice, // alice = caller
//       lawCalldata,
//       nonce
//     );
//   }

//   function testHandleRequestOutput() public {
//     // prep
//     address nominateMe = laws[5];
//     address assignCouncilRole = laws[6];
//     bytes memory lawCalldata = abi.encode(4, alice); // roleId 4, alice

//     vm.prank(address(daoMock));
//     daoMock.assignRole(1, alice); // assign alice to role 1 (Member)

//     vm.startPrank(alice);
//     daoMock.request(
//       nominateMe,
//       abi.encode(true),
//       nonce,
//       "Alice nominates herself"
//     );
//     vm.stopPrank();

//     // Call handleRequest directly to verify output format
//     (
//       uint256 actionId,
//       address[] memory targets,
//       uint256[] memory values,
//       bytes[] memory calldatas,
//       bytes memory stateChange
//     ) = Law(assignCouncilRole).handleRequest(alice, lawCalldata, nonce);

//     // Verify outputs
//     assertEq(targets.length, 1, "Should have one target");
//     assertEq(values.length, 1, "Should have one value");
//     assertEq(calldatas.length, 1, "Should have one calldata");

//     // Role assignment action
//     assertEq(targets[0], address(daoMock), "Target should be the DAO");
//     assertEq(values[0], 0, "Value should be 0");
//     assertEq(
//       calldatas[0],
//       abi.encodeWithSelector(Powers.assignRole.selector, 4, alice),
//       "Calldata should be role assignment"
//     );

//     assertEq(stateChange, "", "State change should be empty");
//     assertTrue(actionId != 0, "Action ID should not be 0");
//   }
// }

// contract GrantTest is TestSetupGovernYourTax {
//     function testConstructorInitialization() public {
//         address grant = laws[1];

//         assertTrue(Powers(daoMock).getActiveLaw(grant), "Law should be active after initialization");
//         assertEq(Law(grant).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(Law(grant).allowedRole(), type(uint32).max, "Allowed role should be Public Role");
//         assertEq(Grant(grant).tokenAddress(), address(erc20VotesMock), "Token address should be set correctly");
//         assertEq(Grant(grant).budget(), 5000, "Budget should be set correctly");
//         assertEq(Grant(grant).spent(), 0, "Initial spent amount should be 0");
//         assertEq(Grant(grant).expiryBlock(), 2711, "Expiry block should be set correctly");
//     }

//     function testGrantRequestSucceedsWithValidParameters() public {
//         // prep
//         address grantProposal = laws[0];
//         address grant = laws[1];
//         uint256 amountRequested = 100;
//         bytes memory lawCalldata = abi.encode(
//             alice, // grantee
//             grant, // grant address
//             amountRequested
//         );

//         vm.prank(address(daoMock));
//         erc20VotesMock.mintVotes(5000);

//         // Store initial state
//         uint256 initialBalance = erc20VotesMock.balanceOf(alice);
//         uint256 initialSpent = Grant(grant).spent();
//         vm.prank(address(daoMock));
//         daoMock.assignRole(1, alice); // assign alice to role 1 (Member)

//         vm.prank(alice);
//         Powers(daoMock).request(
//             grantProposal,
//             lawCalldata,
//             nonce,
//             "Alice requests grant payment"
//         );

//         uint256 actionId = _hashAction(grantProposal, lawCalldata, nonce);
//         ActionState state = Powers(payable(address(daoMock))).state(
//             actionId
//         );
//         console.log("state", uint8(state));
//         // assertEq(state, ActionState.Succeeded, "Grant proposal should be succeeded");

//         // act
//         vm.roll(block.number + 100);
//         vm.prank(alice);
//         Powers(daoMock).request(
//             grant,
//             lawCalldata,
//             nonce,
//             "Alice requests grant payment"
//         );

//         // assert
//         assertEq(
//             erc20VotesMock.balanceOf(alice),
//             initialBalance + amountRequested,
//             "Grantee should receive requested amount"
//         );
//         assertEq(
//             Grant(grant).spent(),
//             initialSpent + amountRequested,
//             "Spent amount should be updated"
//         );
//     }

//     function testGrantRequestRevertsWithInsufficientFunds() public {
//         // prep
//         address grantProposal = laws[0];
//         address grant = laws[1];
//         uint256 amountRequested = 6000;    // More than budget
//         bytes memory lawCalldata = abi.encode(
//             alice, // grante
//             grant, // grant address
//             amountRequested
//         );

//         vm.prank(address(daoMock));
//         erc20VotesMock.mintVotes(5000);

//         vm.prank(address(daoMock));
//         daoMock.assignRole(1, alice); // assign alice to role 1 (Member)

//         vm.prank(alice);
//         Powers(daoMock).request(
//             grantProposal,
//             lawCalldata,
//             nonce,
//             "Alice requests grant payment"
//         );

//         // act
//         vm.startPrank(address(daoMock));
//         vm.expectRevert("Request amount exceeds available funds.");
//         // vm.prank(alice);
//         // Powers(daoMock).request(
//         //     grant,
//         //     lawCalldata,
//         //     "Alice requests grant payment"
//         // );
//         Law(grant).executeLaw(
//             alice,
//             lawCalldata,
//             nonce
//         );
//         vm.stopPrank();
//     }

//     function testGrantRevertsAfterFundsSpent() public {
//         // prep
//         address grantProposal = laws[0];
//         address grant = laws[1];
//         uint256 budget = Grant(grant).budget();
//         uint256 amountRequested = 55;
//         uint256 totalRequested;
//         bytes memory lawCalldata = abi.encode(
//             alice, // grantee
//             grant, // grant address
//             amountRequested
//         );

//         vm.prank(address(daoMock));
//         erc20VotesMock.mintVotes(5000);

//         vm.prank(address(daoMock));
//         daoMock.assignRole(1, alice); // assign alice to role 1 (Member)

//         // act
//         while (totalRequested + amountRequested < budget) {
//             string memory description = string.concat("Alice requests grant payment at block: ", Strings.toString(block.number));
//             vm.prank(alice);
//             Powers(daoMock).request(
//                 grantProposal,
//                 lawCalldata,
//                 nonce,
//                 description
//             );
//             console.log("request grant, should pass");

//             vm.roll(block.number + 100);
//             vm.prank(alice);
//             Powers(daoMock).request(
//                 grant,
//                 lawCalldata,
//                 nonce,
//                 description
//             );
//             nonce++;
//             totalRequested += amountRequested;
//         }

//         // Try to request more after budget is spent
//         console.log("request grant, should revert");
//         string memory description = string.concat("Alice requests grant payment at block that should revert: ", Strings.toString(block.number));
//         vm.prank(alice);
//         Powers(daoMock).request(
//             grantProposal,
//             lawCalldata,
//             nonce,
//             description
//         );

//         vm.startPrank(alice);
//         vm.expectRevert("Request amount exceeds available funds.");
//         Powers(daoMock).request(
//             grant,
//             lawCalldata,
//             nonce,
//             description
//         );
//         vm.stopPrank();
//     }

//     function testHandleRequestOutput() public {
//         // prep
//         address grant = laws[1];
//         uint256 amountRequested = 100;
//         bytes memory lawCalldata = abi.encode(
//             alice, // grantee
//             grant, // grant address
//             amountRequested
//         );

//         // Call handleRequest directly to verify output format
//         (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         ) = Law(grant).handleRequest(alice, lawCalldata, nonce);

//         // Verify outputs
//         assertEq(targets.length, 1, "Should have one target");
//         assertEq(values.length, 1, "Should have one value");
//         assertEq(calldatas.length, 1, "Should have one calldata");

//         // Grant transfer action
//         assertEq(targets[0], address(erc20VotesMock), "Target should be the token contract");
//         assertEq(values[0], 0, "Value should be 0");
//         assertEq(
//             calldatas[0],
//             abi.encodeWithSelector(ERC20.transfer.selector, alice, amountRequested),
//             "Calldata should be token transfer"
//         );

//         // State change should contain amount for spent tracking
//         assertEq(
//             abi.decode(stateChange, (uint256)),
//             amountRequested,
//             "State change should contain transfer amount"
//         );
//         assertTrue(actionId != 0, "Action ID should not be 0");
//     }

//     function _hashAction(address targetLaw, bytes memory lawCalldata, uint256 nonce) internal view virtual returns (uint256) {
//         return uint256(keccak256(abi.encode(targetLaw, lawCalldata, nonce)));
//     }
// }

// contract StartGrantTest is TestSetupGovernYourTax {
//     function testConstructorInitialization() public {
//         address startGrant = laws[3];
//         assertTrue(Powers(daoMock).getActiveLaw(startGrant), "Law should be active after initialization");
//         assertEq(Law(startGrant).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(Law(startGrant).allowedRole(), 2, "Allowed role should be Governors");
//     }

//     function testStartGrantSucceedsWithValidParameters() public {
//         // prep
//         address startGrant = laws[2];
//         uint256 initialLawCount = laws.length;

//         // Give alice permission to start grants (Governors role)
//         vm.startPrank(address(daoMock));
//         erc20VotesMock.mintVotes(2500);
//         Powers(daoMock).assignRole(2, alice);
//         vm.stopPrank();

//         // Prepare grant parameters
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant", // name
//             "This is a test grant", // description
//             3000, // duration
//             1000, // budget
//             address(erc20VotesMock), // token address
//             2, // access role
//             laws[0] // proposal law
//         );

//         // act
//         vm.prank(alice);
//         Powers(daoMock).request(startGrant, lawCalldata, nonce, "Starting new grant");

//     }

//     function testStartGrantFailsWithoutProperPermissions() public {
//         // prep
//         address startGrant = laws[2];
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant",
//             "This is a test grant",
//             3000,
//             1000,
//             address(erc20VotesMock),
//             2,
//             laws[0]
//         );

//         // Attempt to start grant without proper role
//         vm.prank(bob);
//         vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
//         Powers(daoMock).request(startGrant, lawCalldata, nonce, "Attempting to start grant without permission");
//     }

//     function testStartGrantFailsWithInvalidProposalLaw() public {
//         // prep
//         address startGrant = laws[2];
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant",
//             "This is a test grant",
//             3000,
//             1000,
//             address(erc20VotesMock),
//             2,
//             address(0) // Invalid proposal law
//         );

//         // Give alice permission to start grants
//         vm.startPrank(address(daoMock));
//         erc20VotesMock.mintVotes(2500);
//         Powers(daoMock).assignRole(2, alice);
//         vm.stopPrank();

//         // Attempt to start grant with invalid proposal law
//         vm.prank(alice);
//         vm.expectRevert("Invalid proposal law.");
//         Powers(daoMock).request(startGrant, lawCalldata, nonce, "Attempting to start grant with invalid proposal law");
//     }

//     function testHandleRequestOutput() public {
//         // prep
//         address startGrant = laws[2];
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant",
//             "This is a test grant",
//             3000,
//             1000,
//             address(erc20VotesMock),
//             2,
//             laws[0]
//         );

//         vm.prank(address(daoMock));
//         erc20VotesMock.mintVotes(2500);

//         // Call handleRequest directly to verify output format
//         (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         ) = Law(startGrant).handleRequest(alice, lawCalldata, nonce);

//         // Verify outputs
//         assertEq(targets.length, 1, "Should have one target");
//         assertEq(values.length, 1, "Should have one value");
//         assertEq(calldatas.length, 1, "Should have one calldata");

//         // Grant creation action
//         assertEq(targets[0], address(daoMock), "Target should be the DAO");
//         assertEq(values[0], 0, "Value should be 0");

//         // State change should contain new grant parameters
//         (
//             string memory name,
//             string memory description,
//             uint48 duration_,
//             uint256 budget_,
//             address token,
//             uint32 role,
//             address proposalLaw
//         ) = abi.decode(stateChange, (string, string, uint48, uint256, address, uint32, address));

//         assertEq(name, "Test Grant", "Name should match");
//         assertEq(description, "This is a test grant", "Description should match");
//         assertEq(duration_, 3000, "Duration should match");
//         assertEq(budget_, 1000, "Budget should match");
//         assertEq(token, address(erc20VotesMock), "Token address should match");
//         assertEq(role, 2, "Access role should match");
//         assertEq(proposalLaw, laws[0], "Proposal law should match");
//         assertTrue(actionId != 0, "Action ID should not be 0");
//     }

//     function testMultipleGrantsCanBeStarted() public {
//         // prep
//         address startGrant = laws[2];

//         vm.startPrank(address(daoMock));
//         erc20VotesMock.mintVotes(2500);
//         Powers(daoMock).assignRole(2, alice);
//         vm.stopPrank();

//         // Start multiple grants
//         for (uint i = 0; i < 3; i++) {
//             bytes memory lawCalldata = abi.encode(
//                 "Test Grant",
//                 string(abi.encodePacked("Starting grant ", i)),
//                 3000,
//                 1000,
//                 address(erc20VotesMock),
//                 2,
//                 laws[0]
//             );

//             vm.prank(alice);
//             Powers(daoMock).request(
//                 startGrant,
//                 lawCalldata,
//                 nonce,
//                 string(abi.encodePacked("Starting grant ", i))
//             );
//         }
//     }
// }

// contract StopGrantTest is TestSetupGovernYourTax {
//     function testConstructorInitialization() public {
//         address stopGrant = laws[3];

//         assertTrue(Powers(daoMock).getActiveLaw(stopGrant), "Law should be active after initialization");
//         assertEq(Law(stopGrant).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(Law(stopGrant).allowedRole(), 2, "Allowed role should be ROLE_TWO");
//     }

//     function testStopExpiredGrant() public {
//         // Get the grant contracts
//         address proposalLaw = laws[0];
//         address startGrant = laws[2];
//         address stopGrant = laws[3];

//         // Create grant parameters
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant",
//             "requesting grant",
//             uint48(100), // duration
//             uint256(1000 ), // budget
//             address(erc20TaxedMock), // token
//             2, // grant council role
//             laws[0] // proposals
//         );

//         // Get grant address
//         address grantAddress = StartGrant(startGrant).getGrantAddress(
//             "Test Grant",
//             "requesting grant",
//             100,
//             1000,
//             address(erc20TaxedMock),
//             2,
//             laws[0]
//         );

//         // Give alice permission to start grant
//         vm.startPrank(address(daoMock));
//         erc20VotesMock.mintVotes(2500);
//         daoMock.assignRole(1, alice);
//         daoMock.assignRole(2, alice);
//         vm.stopPrank();

//         // Start the grant

//         vm.startPrank(alice);
//         // Start the grant
//         daoMock.request(startGrant, lawCalldata, nonce, "requesting grant");
//         daoMock.request(proposalLaw, lawCalldata, nonce, "requesting grant");
//         vm.stopPrank();

//         // Fast forward past grant expiry
//         vm.roll(block.number + 101);

//         // Try to stop the grant
//         vm.prank(alice);
//         daoMock.request(stopGrant, lawCalldata, nonce, "requesting grant");

//         // Verify the grant is being revoked
//         assertFalse(Powers(daoMock).getActiveLaw(grantAddress), "Grant should be revoked");
//     }

//     function testStopGrantFailsWithoutProperPermissions() public {
//         address stopGrant = laws[3];

//         vm.startPrank(address(daoMock));
//         erc20VotesMock.mintVotes(2500);
//         vm.stopPrank();

//         // Create grant parameters
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant",
//             "Test Description",
//             uint48(100),
//             uint256(1000),
//             address(erc20TaxedMock),
//             2,
//             laws[0]
//         );

//         // Try to stop grant without proper role
//         vm.prank(bob);
//         vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
//         daoMock.request(stopGrant, lawCalldata, nonce, "Attempting to stop grant without permission");
//     }

//     function testStopGrantFailsWhenGrantNotExpired() public {
//         address startGrant = laws[2];
//         address stopGrant = laws[3];

//         vm.startPrank(address(daoMock));
//         erc20VotesMock.mintVotes(2500);
//         vm.stopPrank();

//         // Create grant parameters
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant",
//             "Test Description",
//             uint48(100),
//             uint256(1000),
//             address(erc20TaxedMock),
//             2,
//             laws[0]
//         );

//         // Get grant address
//         address grantAddress = StartGrant(startGrant).getGrantAddress(
//             "Test Grant",
//             "Test Description",
//             100,
//             1000 ,
//             address(erc20TaxedMock),
//             2,
//             laws[0]
//         );

//         // Give alice permission to start grant
//         vm.prank(address(daoMock));
//         daoMock.assignRole(2, alice);

//         // Start the grant
//         vm.prank(alice);
//         daoMock.request(startGrant, lawCalldata, nonce, "Test Description");

//         // Try to stop grant before expiry
//         vm.prank(alice);
//         vm.expectRevert("Grant not expired.");
//         daoMock.request(stopGrant, lawCalldata, nonce, "Test Description");

//         // Verify grant is still active
//         assertTrue(Powers(daoMock).getActiveLaw(grantAddress), "Test Description");
//     }

//     function testStopGrantFailsWhenGrantNotSpent() public {
//         address startGrant = laws[2];
//         address stopGrant = laws[3];

//         // Create grant parameters
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant",
//             "Test Description",
//             uint48(100),
//             uint256(1000 ),
//             address(erc20TaxedMock),
//             2,
//             laws[0]
//         );

//         // Get grant address
//         address grantAddress = StartGrant(startGrant).getGrantAddress(
//             "Test Grant",
//             "Test Description",
//             100,
//             1000 ,
//             address(erc20TaxedMock),
//             2,
//             laws[0]
//         );

//         // Give alice permission to start grant
//         vm.prank(address(daoMock));
//         daoMock.assignRole(2, alice);

//         // Start the grant
//         vm.prank(alice);
//         daoMock.request(startGrant, lawCalldata, nonce, "Test Description");

//         // Fast forward past grant expiry

//         // Try to stop grant before it's spent
//         vm.prank(alice);
//         vm.expectRevert("Grant not expired.");
//         daoMock.request(stopGrant, lawCalldata, nonce, "Test Description");

//         // Verify grant is still active
//         assertTrue(Powers(daoMock).getActiveLaw(grantAddress), "Grant should still be active");
//     }

//     function testHandleRequestOutput() public {
//         address proposalLaw = laws[0];
//         address startGrant = laws[2];
//         address stopGrant = laws[3];
//         bytes memory lawCalldata = abi.encode(
//             "Test Grant",
//             "Test Description",
//             uint48(100),
//             uint256(1000),
//             address(erc20TaxedMock),
//             2,
//             proposalLaw
//         );

//         vm.startPrank(address(daoMock));
//         erc20VotesMock.mintVotes(2500);
//         daoMock.assignRole(2, alice);
//         vm.stopPrank();

//         vm.prank(alice);
//         daoMock.request(startGrant, lawCalldata, nonce, "Test description");

//         vm.roll(block.number + 101);
//         vm.prank(alice);
//         daoMock.request(stopGrant, lawCalldata, nonce, "Test description");

//         // Call handleRequest directly to verify output format
//         (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         ) = Law(stopGrant).handleRequest(alice, lawCalldata, nonce);

//         // Verify outputs
//         assertEq(targets.length, 1, "Should have one target");
//         assertEq(values.length, 1, "Should have one value");
//         assertEq(calldatas.length, 1, "Should have one calldata");

//         // Verify revocation action
//         assertEq(targets[0], address(daoMock), "Target should be the DAO");
//         assertEq(values[0], 0, "Value should be 0");
//         assertEq(
//             keccak256(calldatas[0]),
//             keccak256(abi.encodeWithSelector(Powers.revokeLaw.selector, StartGrant(laws[2]).getGrantAddress(
//                 "Test Grant",
//                 "Test Description",
//                 100,
//                 1000 ,
//                 address(erc20TaxedMock),
//                 2,
//                 laws[0]
//             ))),
//             "Calldata should be for grant revocation"
//         );
//         assertTrue(actionId != 0, "Action ID should not be 0");
//     }
// }

// contract RoleByTaxPaidTest is TestSetupGovernYourTax {
//     function testConstructorInitialization() public {
//         address roleByTax = laws[4];

//         assertTrue(Powers(daoMock).getActiveLaw(roleByTax), "Law should be active after initialization");
//         assertEq(Law(roleByTax).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(Law(roleByTax).allowedRole(), 2, "Allowed role should be 2");
//         assertEq(RoleByTaxPaid(roleByTax).erc20TaxedMock(), address(erc20TaxedMock), "ERC20TaxedMock address should be set correctly");
//         assertEq(RoleByTaxPaid(roleByTax).thresholdTaxPaid(), 100, "Threshold tax paid should be set correctly");
//         assertEq(RoleByTaxPaid(roleByTax).roleIdToSet(), 3, "Role ID should be set correctly");
//     }

//     function testAssignRoleWhenTaxThresholdMet() public {
//         // prep
//         address roleByTax = laws[4];
//         bytes memory lawCalldata = abi.encode(alice);

//         // Give alice some tokens and make her pay tax
//         vm.startPrank(address(daoMock));
//         erc20TaxedMock.mint(10000);
//         erc20TaxedMock.transfer(alice, 10000);
//         Powers(daoMock).assignRole(2, alice);
//         vm.stopPrank();

//         // Make alice transfer tokens to generate tax
//         vm.prank(alice);
//         erc20TaxedMock.transfer(bob, 5000);

//         // Fast forward past epoch duration
//         vm.roll(block.number + 101);

//         // Request role assignment
//         vm.prank(alice);
//         daoMock.request(roleByTax, lawCalldata, nonce, "Alice requests role based on tax paid");

//         // Verify role was assigned
//         assertNotEq(daoMock.hasRoleSince(alice, 3), 0, "Alice should have role 3");
//     }

//     function testRevokeRoleWhenTaxThresholdNotMet() public {
//         // prep
//         address roleByTax = laws[4];
//         bytes memory lawCalldata = abi.encode(alice);

//         // Give alice some tokens and make her pay tax
//         vm.startPrank(address(daoMock));
//         erc20TaxedMock.mint(1000);
//         erc20TaxedMock.transfer(alice, 10000);
//         Powers(daoMock).assignRole(2, alice);
//         vm.stopPrank();

//         // Make alice transfer tokens to generate tax
//         vm.prank(alice);
//         erc20TaxedMock.transfer(bob, 5000);

//         // Fast forward past epoch duration
//         vm.roll(block.number + 101);

//         // Request role assignment
//         vm.prank(alice);
//         daoMock.request(roleByTax, lawCalldata, nonce, "Alice requests role based on tax paid");
//         nonce++;

//         // Verify role was assigned
//         assertEq(daoMock.hasRoleSince(alice, 3), block.number, "Alice should have role 3");

//         // Fast forward to next epoch
//         vm.roll(block.number + 101);

//         // Make alice transfer small amount to generate low tax
//         vm.prank(alice);
//         erc20TaxedMock.transfer(bob, 10);

//         // Fast forward past epoch duration
//         vm.roll(block.number + 101);

//         // Request role check
//         vm.prank(alice);
//         daoMock.request(roleByTax, lawCalldata, nonce, "Alice requests role check with low tax");

//         // Verify role was revoked
//         assertEq(daoMock.hasRoleSince(alice, 3), 0, "Alice should not have role 3");
//     }

//     function testRevertWhenNoFinishedEpoch() public {
//         // prep
//         address roleByTax = laws[4];
//         bytes memory lawCalldata = abi.encode(alice);
//         vm.startPrank(address(daoMock));
//         Powers(daoMock).assignRole(2, alice);
//         vm.stopPrank();

//         // Try to request role before any epoch has finished
//         vm.prank(alice);
//         vm.expectRevert("No finished epoch yet.");
//         daoMock.request(roleByTax, lawCalldata, nonce, "Alice requests role before epoch finished");
//     }

//     function testHandleRequestOutput() public {
//         // prep
//         address roleByTax = laws[4];
//         bytes memory lawCalldata = abi.encode(alice);

//         // Give alice some tokens and make her pay tax
//         vm.startPrank(address(daoMock));
//         erc20TaxedMock.mint(1000);
//         erc20TaxedMock.transfer(alice, 10000);
//         Powers(daoMock).assignRole(2, alice);
//         vm.stopPrank();

//         // Make alice transfer tokens to generate tax
//         vm.prank(alice);
//         erc20TaxedMock.transfer(bob, 5000);

//         // Fast forward past epoch duration
//         vm.roll(block.number + 101);

//         // Call handleRequest directly to verify output format
//         (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         ) = Law(roleByTax).handleRequest(alice, lawCalldata, nonce);

//         // Verify outputs
//         assertEq(targets.length, 1, "Should have one target");
//         assertEq(values.length, 1, "Should have one value");
//         assertEq(calldatas.length, 1, "Should have one calldata");

//         // Role assignment action
//         assertEq(targets[0], address(daoMock), "Target should be the DAO");
//         assertEq(values[0], 0, "Value should be 0");
//         assertEq(
//             calldatas[0],
//             abi.encodeWithSelector(Powers.assignRole.selector, 3, alice),
//             "Calldata should be role assignment"
//         );

//         assertEq(stateChange, "", "State change should be empty");
//         assertTrue(actionId != 0, "Action ID should not be 0");
//     }

//     function testMultipleUsersWithDifferentTaxPayments() public {
//         // prep
//         address roleByTax = laws[4];
//         bytes memory aliceCalldata = abi.encode(alice);
//         bytes memory bobCalldata = abi.encode(bob);

//         // Give users tokens
//         vm.startPrank(address(daoMock));
//         erc20TaxedMock.mint(2000);
//         erc20TaxedMock.transfer(alice, 10000);
//         erc20TaxedMock.transfer(bob, 10000);
//         Powers(daoMock).assignRole(2, alice);
//         Powers(daoMock).assignRole(2, bob);
//         vm.stopPrank();

//         // Make alice transfer large amount to generate high tax
//         vm.prank(alice);
//         erc20TaxedMock.transfer(charlotte, 8000);

//         // Make bob transfer small amount to generate low tax
//         vm.prank(bob);
//         erc20TaxedMock.transfer(charlotte, 100);

//         // Fast forward past epoch duration
//         vm.roll(block.number + 101);

//         // Request role assignments
//         vm.prank(alice);
//         daoMock.request(roleByTax, aliceCalldata, nonce, "Alice requests role");

//         vm.prank(bob);
//         daoMock.request(roleByTax, bobCalldata, nonce, "Bob requests role");

//         // Verify roles
//         assertEq(daoMock.hasRoleSince(alice, 3), block.number, "Alice should have role 3");
//         assertEq(daoMock.hasRoleSince(bob, 3), 0, "Bob should not have role 3");
//     }
// }
