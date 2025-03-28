// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/utils/ShortStrings.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import { Powers } from "../../../src/Powers.sol";
// import { TestSetupElectoral } from "../../TestSetup.t.sol";
// import { Law } from "../../../src/Law.sol";
// import { LawUtilities } from "../../../src/LawUtilities.sol";
// import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
// import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";
// import { VoteOnNominees } from "../../../src/laws/state/VoteOnNominees.sol";
// import { ElectionCall } from "../../../src/laws/electoral/ElectionCall.sol";
// import { ElectionTally } from "../../../src/laws/electoral/ElectionTally.sol";
// import { ILaw } from "../../../src/interfaces/ILaw.sol";
// import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
// import { NominateMe } from "../../../src/laws/state/NominateMe.sol";
// import { RenounceRole } from "../../../src/laws/electoral/RenounceRole.sol";
// import { PeerSelect } from "../../../src/laws/electoral/PeerSelect.sol";

// contract DirectSelectTest is TestSetupElectoral {
//     using ShortStrings for *;

//     function testAssignSucceeds() public {
//         // prep: check if charlotte does NOT have role 3
//         assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should not have ROLE_THREE initially");
//         address directSelect = laws[2];
//         bytes memory lawCalldata = abi.encode(true, charlotte); // assign

//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, charlotte);

//         vm.prank(charlotte);
//         Powers(payable(address(daoMock))).request(
//             directSelect,
//             lawCalldata,
//             nonce,
//             "selecting role for account!"
//         );

//         // assert
//         assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should have ROLE_THREE after executing the law");
//     }

//     function testAssignReverts() public {
//         // prep: check if alice does have role 3
//         assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should have ROLE_THREE initially");
//         address directSelect = laws[2];
//         bytes memory lawCalldata = abi.encode(true, alice); // assign

//         // act & assert
//         vm.prank(alice);
//         vm.expectRevert("Account already has role.");
//         Powers(payable(address(daoMock))).request(
//             directSelect,
//             lawCalldata,
//             nonce,
//             "selecting role for account!"
//         );
//     }

//     function testRevokeSucceeds() public {
//         // prep: check if alice does have role 3
//         assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should have ROLE_THREE initially");
//         address directSelect = laws[2];
//         bytes memory lawCalldata = abi.encode(false, alice); // assign
//         bytes memory expectedCalldata = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_THREE, alice);

//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(
//             directSelect,
//             lawCalldata,
//             nonce,
//             "selecting role for account!"
//         );

//         // assert
//         assertEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should not have ROLE_THREE after executing the law");
//     }

//     function testRevokeReverts() public {
//         // prep: check if charlotte does NOT have role 3
//         assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should not have ROLE_THREE initially");
//         address directSelect = laws[2];
//         bytes memory lawCalldata = abi.encode(false, charlotte); // assign

//         // act & assert
//         vm.prank(charlotte);
//         vm.expectRevert("Account does not have role.");
//         Powers(payable(address(daoMock))).request(
//             directSelect,
//             lawCalldata,
//             nonce,
//             "selecting role for account!"
//         );
//     }
// }

// contract DelegateSelectTest is TestSetupElectoral {
//     using ShortStrings for *;

//     function testAssignDelegateRolesWithFewNominees() public {
//         // prep -- nominate charlotte
//         address nominateMe = laws[0];
//         address delegateSelect = laws[3];
//         bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
//         bytes memory lawCalldataElect = abi.encode(); // empty calldata

//         // First nominate charlotte
//         vm.prank(address(daoMock));
//         Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, nonce);

//         // Mint and delegate votes to charlotte
//         vm.prank(charlotte);
//         erc20VotesMock.mintVotes(100);
//         erc20VotesMock.delegate(charlotte);

//         // Execute the delegate select law
//         vm.prank(charlotte);
//         Powers(payable(address(daoMock))).request(
//             delegateSelect,
//             lawCalldataElect,
//             nonce,
//             "electing delegate roles!"
//         );

//         // assert
//         assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should have ROLE_THREE after execution");
//     }

//     function testAssignDelegateRolesWithManyNominees() public {
//         // prep -- nominate all users
//         address nominateMe = laws[0];
//         address delegateSelect = laws[3];
//         bytes memory lawCalldataNominate = abi.encode(true); // nominateMe

//         // Nominate users
//         for (uint256 i = 4; i < users.length; i++) {
//             vm.prank(address(daoMock));
//             Law(nominateMe).executeLaw(users[i], lawCalldataNominate, 54321);
//         }

//         // Mint and delegate votes to users
//         for (uint256 i = 0; i < users.length; i++) {
//             vm.startPrank(users[i]);
//             erc20VotesMock.mintVotes(100 + i * 2);
//             erc20VotesMock.delegate(users[i]); // delegate votes to themselves
//             vm.stopPrank();
//         }

//         // Execute the delegate select law
//         vm.prank(charlotte);
//         Powers(payable(address(daoMock))).request(
//             delegateSelect,
//             abi.encode(),
//             nonce,
//             "electing delegate roles!"
//         );

//         // assert
//         for (uint256 i = 0; i < 2; i++) {
//             assertNotEq(daoMock.hasRoleSince(users[i], ROLE_THREE), 0, "User should have ROLE_THREE after execution");
//         }
//     }

//     function testDelegatesReelectionWorks() public {
//         // prep -- nominate all users
//         address nominateMe = laws[0];
//         address delegateSelect = laws[3];
//         bytes memory lawCalldataNominate = abi.encode(true); // nominateMe

//         // First election setup
//         for (uint256 i = 0; i < users.length; i++) {
//             // Nominate users
//             vm.prank(address(daoMock));
//             Law(nominateMe).executeLaw(users[i], lawCalldataNominate, nonce);
//             nonce++;

//             // Mint and delegate votes
//             vm.startPrank(users[i]);
//             erc20VotesMock.mintVotes(100 + i * 2);
//             erc20VotesMock.delegate(users[i % 3]);
//             vm.stopPrank();
//         }

//         // Execute first election
//         vm.prank(charlotte);
//         Powers(payable(address(daoMock))).request(
//             delegateSelect,
//             abi.encode(),
//             nonce,
//             "First election for delegate roles!"
//         );
//         nonce++;
//         // Verify initial roles
//         for (uint256 i = 0; i < 3; i++) {
//             assertNotEq(daoMock.hasRoleSince(users[i], ROLE_THREE), 0, "User should have ROLE_THREE after first election");
//         }

//         // Move forward in time
//         vm.roll(block.number + 100);

//         // Second election setup
//         // First election setup
//         for (uint256 i = 0; i < users.length; i++) {
//             // redelegate votes to different users
//             vm.startPrank(users[i]);
//             erc20VotesMock.delegate(users[i % 5 + 3]);
//             vm.stopPrank();
//         }

//         // Execute second election
//         vm.prank(charlotte);
//         Powers(payable(address(daoMock))).request(
//             delegateSelect,
//             abi.encode(),
//             nonce,
//             "Second election for delegate roles!"
//         );

//         // Verify roles were revoked
//         for (uint256 i = 0; i < 3; i++) {
//             assertEq(daoMock.hasRoleSince(users[i], ROLE_THREE), 0, "Previous holders should not have ROLE_THREE after second election");
//         }
//     }
// }

// contract ElectionCallTest is TestSetupElectoral {
//     using ShortStrings for *;

//     function testConstructorInitialization() public {
//         assertTrue(Powers(daoMock).getActiveLaw(laws[4]), "Law should be active after initialization");
//         assertEq(Law(laws[4]).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(ElectionCall(laws[4]).VOTER_ROLE_ID(), 2, "Voter role ID should be set correctly");
//         assertEq(ElectionCall(laws[4]).ELECTED_ROLE_ID(), 3, "Elected role ID should be set correctly");
//         assertEq(ElectionCall(laws[4]).MAX_ROLE_HOLDERS(), 2, "Max role holders should be set correctly");
//     }

//     function testDeployVoteOnNominees() public {
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         vm.prank(alice);
//         Powers(daoMock).request(
//             laws[4],
//             abi.encode("Test Election", uint48(block.number), uint48(block.number + 100)),
//             nonce,
//             "Test Election"
//         );

//         ( , , , address readStateFromAddress, , , , ) = ElectionCall(laws[4]).conditions();
//         assertTrue(
//             Powers(daoMock).getActiveLaw(
//                 ElectionCall(laws[4]).getVoteOnNomineesAddress(
//                     ElectionCall(laws[4]).VOTER_ROLE_ID(),
//                     readStateFromAddress,
//                     uint48(block.number),
//                     uint48(block.number + 100),
//                     "Test Election"
//                 )
//             ),
//             "VoteOnNominees should be active"
//         );
//     }

//     function testCannotDeployDuplicateElection() public {
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         bytes memory callData = abi.encode("Test Election", uint48(block.number), uint48(block.number + 100));

//         vm.prank(alice);
//         Powers(daoMock).request(laws[4], callData, nonce, "Test Election");

//         vm.prank(alice);
//         vm.expectRevert(abi.encodeWithSignature("Powers__ActionAlreadyInitiated()"));
//         Powers(daoMock).request(laws[4], callData, nonce, "Test Election");
//     }

//     function testUnauthorizedDeployment() public {
//         vm.prank(helen);
//         vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
//         Powers(daoMock).request(
//             laws[4],
//             abi.encode("Test Election", uint48(block.number), uint48(block.number + 100)),
//             nonce,
//             "Test Election"
//         );
//     }

//     function testDeployWithoutNomineesContract() public {
//         LawUtilities.Conditions memory config;
//         ElectionCall newElectionCall = new ElectionCall(
//             "Election without nominees",
//             "Test election call without nominees contract",
//             payable(address(daoMock)),
//             0,
//             config,
//             1,
//             2,
//             5
//         );

//         vm.prank(address(daoMock));
//         vm.expectRevert("Nominees contract not set at `conditions.readStateFrom`.");
//         newElectionCall.handleRequest(
//             address(0),
//             abi.encode("Test Election", uint48(block.number), uint48(block.number + 100)),
//             nonce
//         );
//     }

//     function testVoteOnNomineesInitialization() public {
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         uint48 startBlock = uint48(block.number);
//         uint48 endBlock = startBlock + 100;

//         vm.prank(alice);
//         Powers(daoMock).request(
//             laws[4],
//             abi.encode("Test Election", startBlock, endBlock),
//             nonce,
//             "Test Election"
//         );

//         VoteOnNominees electionVotes = VoteOnNominees(ElectionCall(laws[4]).electionVotes());
//         assertEq(electionVotes.startVote(), startBlock);
//         assertEq(electionVotes.endVote(), endBlock);
//         assertEq(electionVotes.allowedRole(), ElectionCall(laws[4]).VOTER_ROLE_ID());
//         assertEq(electionVotes.powers(), address(daoMock));
//     }

//     function testHandleRequestOutput() public {
//         uint48 startBlock = uint48(block.number);
//         uint48 endBlock = startBlock + 100;
//         (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         ) = Law(laws[4]).handleRequest(
//             address(0),
//             abi.encode("Test Election", startBlock, endBlock),
//             nonce
//         );

//         ( , , , address readStateFromAddress, , , , ) = ElectionCall(laws[4]).conditions();
//         address expectedAddr = ElectionCall(laws[4]).getVoteOnNomineesAddress(
//             ElectionCall(laws[4]).VOTER_ROLE_ID(),
//             readStateFromAddress,
//             startBlock,
//             endBlock,
//             "Test Election"
//         );

//         assertEq(targets.length, 1);
//         assertEq(targets[0], address(daoMock));
//         assertEq(values[0], 0);
//         assertEq(calldatas[0], abi.encodeWithSelector(Powers.adoptLaw.selector, expectedAddr));
//         assertTrue(actionId != 0);

//         (
//             string memory desc,
//             uint48 start,
//             uint48 end,
//             address addr
//         ) = abi.decode(stateChange, (string, uint48, uint48, address));

//         assertEq(desc, "Test Election");
//         assertEq(start, startBlock);
//         assertEq(end, endBlock);
//         assertEq(addr, expectedAddr);
//     }
// }

// contract ElectionTallyTest is TestSetupElectoral {
//     function testNomineesCorrectlyElectedWithManyNominees() public {
//         // prep: data
//         address nominateMe = laws[0];
//         address electionCall = laws[4];
//         console.log("electionCall", electionCall);
//         address electionTally = laws[5];
//         uint48 startVote = uint48(block.number + 50);
//         uint48 endVote = uint48(block.number + 150);
//         uint256 electionNonce = 123456;

//         bytes memory lawCalldataNominate = abi.encode(true);
//         bytes memory lawCalldataElection = abi.encode(
//             "This is a test election",
//             startVote,
//             endVote
//         );
//         // make sure no one has role 3 at start of election
//         for (uint256 i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], ROLE_THREE) != 0) {
//                 vm.prank(address(daoMock));
//                 daoMock.revokeRole(ROLE_THREE, users[i]);
//             }
//         }

//         // create an election
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);
//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(
//             electionCall,
//             lawCalldataElection,
//             electionNonce,
//             "This is a test election"
//         );
//         address electionVotesAddress = ElectionCall(electionCall).electionVotes();

//         // prep: nominate accounts
//         for (uint256 i = 0; i < users.length; i++) {
//             vm.prank(address(daoMock));
//             Law(nominateMe).executeLaw(users[i], lawCalldataNominate, nonce);
//             nonce++;
//         }

//         // prep: vote on accounts
//         vm.roll(startVote + 1);

//         for (uint256 i = 0; i < users.length; i++) {
//             vm.prank(address(daoMock));
//             daoMock.assignRole(ROLE_TWO, users[i]); // Give  voting rights

//             if (i <= 4) {
//                 vm.prank(users[i]);
//                 Powers(payable(address(daoMock))).request(
//                     electionVotesAddress,
//                     abi.encode(users[0]), // vote for first user
//                     nonce,
//                     string.concat("Voting for first user", Strings.toString(i))
//                 );
//                 nonce++;
//             }
//             if (i > 4 && i <= 9) {
//                 vm.prank(users[i]);
//                 Powers(payable(address(daoMock))).request(
//                     electionVotesAddress,
//                     abi.encode(users[1]), // vote for second user
//                     nonce,
//                     string.concat("Voting for second user", Strings.toString(i))
//                 );
//                 nonce++;
//             }
//             if (i > 9) {
//                 vm.prank(users[i]);
//                 Powers(payable(address(daoMock))).request(
//                     electionVotesAddress,
//                     abi.encode(users[2]), // vote for third user
//                     nonce,
//                     string.concat("Voting for third user", Strings.toString(i))
//                 );
//                 nonce++;
//             }
//         }

//         // act: tally votes
//         (address needCompleted , , , , , , ,) = Law(electionTally).conditions();
//         assertEq(needCompleted, electionCall);

//         vm.roll(endVote + 1);
//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(
//             electionTally,
//             lawCalldataElection,
//             electionNonce,
//             "This is a test election"
//         );

//         // assert: check role assignments
//         assertNotEq(daoMock.hasRoleSince(users[0], ROLE_THREE), 0, "First user should have role");
//         assertNotEq(daoMock.hasRoleSince(users[1], ROLE_THREE), 0, "Second user should have role");
//         assertEq(daoMock.hasRoleSince(users[2], ROLE_THREE), 0, "Third user should not have role");

//         // assert: check elected accounts array
//         assertEq(ElectionTally(electionTally).electedAccounts(0), users[0]);
//         assertEq(ElectionTally(electionTally).electedAccounts(1), users[1]);
//     }

//     function testNomineesCorrectlyElectedWithFewNominees() public {
//         // prep: data
//         address nominateMe = laws[0];
//         address electionCall = laws[4];
//         address electionTally = laws[5];
//         uint48 startVote = uint48(block.number + 50);
//         uint48 endVote = uint48(block.number + 150);

//         bytes memory lawCalldataNominate = abi.encode(true);
//         bytes memory lawCalldataElection = abi.encode(
//             "This is a test election",
//             startVote,
//             endVote
//         );

//         // create an election
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);
//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(
//             electionCall,
//             lawCalldataElection,
//             nonce,
//             "This is a test election"
//         );
//         address electionVotesAddress = ElectionCall(electionCall).electionVotes();

//         // prep: nominate single account
//         vm.prank(address(daoMock));
//         Law(nominateMe).executeLaw(users[0], lawCalldataNominate, 54321);

//         // prep: vote for the nominee
//         vm.roll(startVote + 1);
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_TWO, alice); // Give alice voting rights
//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(
//             electionVotesAddress,
//             abi.encode(users[0]),
//             nonce,
//             "Voting for nominee"
//         );

//         // act: tally votes
//         vm.roll(endVote + 1);
//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(
//             electionTally,
//             lawCalldataElection,
//             nonce,
//             "This is a test election"
//         );

//         // assert: check role assignment
//         assertNotEq(daoMock.hasRoleSince(users[0], ROLE_THREE), 0, "Nominee should have role");

//         // assert: check elected accounts array
//         assertEq(ElectionTally(electionTally).electedAccounts(0), users[0]);
//     }

//     function testTallyRevertsIfVoteOnNomineesNotFinishedYet() public {
//         // prep: data
//         address nominateMe = laws[0];
//         address electionCall = laws[4];
//         address electionTally = laws[5];
//         uint48 startVote = uint48(block.number + 50);
//         uint48 endVote = uint48(block.number + 150);

//         bytes memory lawCalldataNominate = abi.encode(true);
//         bytes memory lawCalldataElection = abi.encode(
//             "This is a test election",
//             startVote,
//             endVote
//         );

//         // create an election
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);
//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(
//             electionCall,
//             lawCalldataElection,
//             nonce,
//             "This is a test election"
//         );

//         // prep: nominate an account
//         vm.prank(address(daoMock));
//         Law(nominateMe).executeLaw(users[0], lawCalldataNominate, 54321);

//         // act & assert: attempt to tally before election ends
//         vm.roll(endVote - 10);
//         vm.prank(alice);
//         vm.expectRevert("Election still active.");
//         Powers(payable(address(daoMock))).request(
//             electionTally,
//             lawCalldataElection,
//             nonce,
//             "This is a test election"
//         );
//     }

//     function testTallyRevertsIfNoNominees() public {
//         // prep: data
//         address electionCall = laws[4];
//         address electionTally = laws[5];
//         uint48 startVote = uint48(block.number + 50);
//         uint48 endVote = uint48(block.number + 150);

//         bytes memory lawCalldataElection = abi.encode(
//             "This is a test election",
//             startVote,
//             endVote
//         );

//         // create an election
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);
//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(
//             electionCall,
//             lawCalldataElection,
//             nonce,
//             "This is a test election"
//         );

//         // act & assert: attempt to tally with no nominees
//         vm.roll(endVote + 1);
//         vm.prank(alice);
//         vm.expectRevert("No nominees.");
//         Powers(payable(address(daoMock))).request(
//             electionTally,
//             lawCalldataElection,
//             nonce,
//             "This is a test election"
//         );
//     }
// }

// contract SelfSelectTest is TestSetupElectoral {
//     function testConstructorInitialization() public {
//         // Get the SelfSelect contract from the test setup
//         address selfSelect = laws[6];

//         // Test that the contract was initialized correctly
//         assertTrue(Powers(daoMock).getActiveLaw(selfSelect), "Law should be active after initialization");
//         assertEq(Law(selfSelect).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(Law(selfSelect).allowedRole(), type(uint32).max, "Allowed role should be set to public access");
//     }

//     function testSuccessfulSelfAssignment() public {
//         // prep
//         address selfSelect = laws[6];
//         bytes memory lawCalldata = abi.encode();
//         string memory description = "Self selecting role";

//         // Store initial state
//         assertEq(daoMock.hasRoleSince(bob, 6), 0, "Bob should not have role initially");

//         // act
//         vm.prank(bob);
//         Powers(daoMock).request(selfSelect, lawCalldata, nonce, description);

//         // assert
//         assertNotEq(daoMock.hasRoleSince(bob, 6), 0, "Bob should have role after self-selection");
//     }

//     function testCannotAssignRoleTwice() public {
//         // prep
//         address selfSelect = laws[6];
//         bytes memory lawCalldata = abi.encode();

//         // First assignment
//         vm.prank(bob);
//         Powers(daoMock).request(selfSelect, lawCalldata, nonce, "Self selecting role once..");
//         nonce++;

//         // Try to assign again
//         vm.prank(bob);
//         vm.expectRevert("Account already has role.");
//         Powers(daoMock).request(selfSelect, lawCalldata, nonce, "Self selecting role twice..");
//     }

//     function testMultipleAccountsSelfAssign() public {
//         // prep
//         address selfSelect = laws[6];
//         bytes memory lawCalldata = abi.encode();

//         // Have multiple users self-assign the role
//         for (uint256 i = 0; i < users.length; i++) {
//             vm.prank(users[i]);
//             Powers(daoMock).request(
//                 selfSelect,
//                 lawCalldata,
//                 nonce,
//                 string.concat("Self selecting role - user ", Strings.toString(i))
//             );
//             nonce++;
//             assertNotEq(
//                 daoMock.hasRoleSince(users[i], 6),
//                 0,
//                 string.concat("User ", Strings.toString(i), " should have role after self-selection")
//             );
//         }
//     }

//     function testHandleRequestOutput() public {
//         // prep
//         address selfSelect = laws[6];
//         bytes memory lawCalldata = abi.encode();
//         // act: call handleRequest directly to check its output
//         vm.prank(bob);
//         (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         ) = Law(selfSelect).handleRequest(bob, lawCalldata, nonce);

//         // assert
//         assertEq(targets.length, 1, "Should have one target");
//         assertEq(values.length, 1, "Should have one value");
//         assertEq(calldatas.length, 1, "Should have one calldata");
//         assertEq(targets[0], address(daoMock), "Target should be the DAO");
//         assertEq(values[0], 0, "Value should be 0");
//         assertEq(
//             calldatas[0],
//             abi.encodeWithSelector(Powers.assignRole.selector, 6, bob),
//             "Calldata should be for role assignment"
//         );
//         assertEq(stateChange, "", "State change should be empty");
//         assertTrue(actionId != 0, "Action ID should not be 0");
//     }
// }

// contract RenounceRoleTest is TestSetupElectoral {
//     function testConstructorInitialization() public {
//         // Get the RenounceRole contract from the test setup
//         address renounceRole = laws[7];

//         // Test that the contract was initialized correctly
//         assertTrue(Powers(daoMock).getActiveLaw(renounceRole), "Law should be active after initialization");
//         assertEq(Law(renounceRole).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(Law(renounceRole).allowedRole(), ROLE_ONE, "Allowed role should be set to ROLE_ONE");

//         // Test that the allowed role IDs were set correctly
//         assertEq(RenounceRole(renounceRole).allowedRoleIds(0), ROLE_THREE, "First allowed role ID should be ROLE_THREE");
//     }

//     function testSuccessfulRoleRenouncement() public {
//         // prep
//         address renounceRole = laws[7];
//         bytes memory lawCalldata = abi.encode(ROLE_THREE);
//         string memory description = "Renouncing role";

//         // Store initial state
//         assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should have ROLE_THREE initially");

//         // act
//         vm.prank(alice);
//         Powers(daoMock).request(renounceRole, lawCalldata, nonce, description);

//         // assert
//         assertEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should not have ROLE_THREE after renouncing");
//     }

//     function testCannotRenounceUnallowedRole() public {
//         // prep
//         address renounceRole = laws[7];
//         bytes memory lawCalldata = abi.encode(ROLE_ONE); // ROLE_ONE is not in allowedRoleIds

//         // act & assert
//         vm.prank(alice);
//         vm.expectRevert("Role not allowed to be renounced.");
//         Powers(daoMock).request(renounceRole, lawCalldata, nonce, "Attempting to renounce unallowed role");
//     }

//     function testCannotRenounceRoleNotHeld() public {
//         // prep
//         address renounceRole = laws[7];
//         bytes memory lawCalldata = abi.encode(ROLE_THREE);

//         // Ensure helen doesn't have ROLE_THREE
//         assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0, "Helen should not have ROLE_THREE initially");

//         // act & assert
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, helen);

//         vm.prank(helen);
//         vm.expectRevert("Account does not have role.");
//         Powers(daoMock).request(renounceRole, lawCalldata, nonce, "Attempting to renounce unheld role");
//     }

//     function testHandleRequestOutput() public {
//         // prep
//         address renounceRole = laws[7];
//         bytes memory lawCalldata = abi.encode(ROLE_THREE);
//         // act: call handleRequest directly to check its output
//         vm.prank(alice);
//         (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         ) = Law(renounceRole).handleRequest(alice, lawCalldata, nonce);

//         // assert
//         assertEq(targets.length, 1, "Should have one target");
//         assertEq(values.length, 1, "Should have one value");
//         assertEq(calldatas.length, 1, "Should have one calldata");
//         assertEq(targets[0], address(daoMock), "Target should be the DAO");
//         assertEq(values[0], 0, "Value should be 0");
//         assertEq(
//             calldatas[0],
//             abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_THREE, alice),
//             "Calldata should be for role revocation"
//         );
//         assertEq(stateChange, "", "State change should be empty");
//         assertTrue(actionId != 0, "Action ID should not be 0");
//     }
// }

// contract PeerSelectTest is TestSetupElectoral {
//     using ShortStrings for *;

//     function testConstructorInitialization() public {
//         // Get PeerSelect from laws array
//         address peerSelect = laws[8]; // Adjust index based on ConstitutionsMock setup

//         assertTrue(Powers(daoMock).getActiveLaw(peerSelect), "Law should be active after initialization");
//         assertEq(Law(peerSelect).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(Law(peerSelect).allowedRole(), ROLE_ONE, "Allowed role should be ROLE_ONE");
//         assertEq(PeerSelect(peerSelect).MAX_ROLE_HOLDERS(), 2, "Max role holders should be set correctly");
//         assertEq(PeerSelect(peerSelect).ROLE_ID(), 6, "Role ID should be set correctly");
//     }

//     function testNominationAndSelection() public {
//         address nominateMe = laws[0];
//         address peerSelect = laws[8]; // Adjust index based on ConstitutionsMock setup

//         // First nominate alice
//         vm.prank(address(daoMock));
//         Law(nominateMe).executeLaw(alice, abi.encode(true), 54321);

//         // Give bob permission to select peers
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, bob);

//         // Select alice as peer
//         vm.prank(bob);
//         Powers(daoMock).request(
//             peerSelect,
//             abi.encode(0, true), // index 0, assign=true
//             nonce,
//             "Select alice as peer"
//         );

//         // Verify selection
//         assertEq(PeerSelect(peerSelect)._electedSorted(0), alice, "Alice should be elected");
//         assertTrue(Powers(daoMock).hasRoleSince(alice, 6) > 0, "Alice should have role");
//     }

//     function testMultipleNominationsAndSelections() public {
//         address nominateMe = laws[0];
//         address peerSelect = laws[8]; // Adjust index based on ConstitutionsMock setup

//         // Give alice permission to select peers
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         // Nominate multiple users
//         address[] memory nominees = new address[](2);
//         nominees[0] = bob;
//         nominees[1] = charlotte;

//         for (uint i = 0; i < nominees.length; i++) {
//             vm.prank(address(daoMock));
//             Law(nominateMe).executeLaw(nominees[i], abi.encode(true), 54321);
//         }

//         // Select all nominees
//         for (uint i = 0; i < nominees.length; i++) {
//             vm.prank(alice);
//             Powers(daoMock).request(
//                 peerSelect,
//                 abi.encode(i, true),
//                 nonce,
//                 string(abi.encodePacked("Select nominee ", i))
//             );
//         }

//         // Verify selections
//         for (uint i = 0; i < nominees.length; i++) {
//             assertEq(PeerSelect(peerSelect)._electedSorted(i), nominees[i], "Nominee should be elected");
//             assertTrue(
//                 Powers(daoMock).hasRoleSince(nominees[i], 6) > 0,
//                 "Nominee should have role"
//             );
//         }
//     }

//     function testMaxRoleHoldersLimit() public {
//         address nominateMe = laws[0];
//         address peerSelect = laws[8]; // Adjust index based on ConstitutionsMock setup

//         // Give alice permission to select peers
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         // Nominate more than max allowed
//         address[] memory nominees = new address[](3); // MAX_ROLE_HOLDERS is 2
//         nominees[0] = bob;
//         nominees[1] = charlotte;
//         nominees[2] = david;

//         for (uint i = 0; i < nominees.length; i++) {
//             vm.prank(address(daoMock));
//             Law(nominateMe).executeLaw(nominees[i], abi.encode(true), 54321);
//         }

//         // Select up to max allowed
//         for (uint i = 0; i < 2; i++) {
//             vm.prank(alice);
//             Powers(daoMock).request(
//                 peerSelect,
//                 abi.encode(i, true),
//                 nonce,
//                 string(abi.encodePacked("Select nominee ", i))
//             );
//         }

//         // Try to select one more - should fail
//         vm.prank(alice);
//         vm.expectRevert("Max role holders reached.");
//         Powers(daoMock).request(
//             peerSelect,
//             abi.encode(2, true),
//             nonce,
//             "Should fail - max reached"
//         );
//     }

//     function testRevokeAndReassign() public {
//         address nominateMe = laws[0];
//         address peerSelect = laws[8]; // Adjust index based on ConstitutionsMock setup

//         // Give alice permission to select peers
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         // Setup: Get bob and charlotte elected
//         vm.startPrank(address(daoMock));
//         Law(nominateMe).executeLaw(bob, abi.encode(true), 54321);
//         Law(nominateMe).executeLaw(charlotte, abi.encode(true), 54321);
//         vm.stopPrank();

//         vm.startPrank(alice);
//         Powers(daoMock).request(
//             peerSelect,
//             abi.encode(0, true),
//             nonce,
//             "Select bob"
//         );
//         Powers(daoMock).request(
//             peerSelect,
//             abi.encode(1, true),
//             nonce,
//             "Select charlotte"
//         );
//         vm.stopPrank();

//         // Verify initial state
//         assertEq(PeerSelect(peerSelect)._electedSorted(0), bob, "Bob should be first");
//         assertEq(PeerSelect(peerSelect)._electedSorted(1), charlotte, "Charlotte should be second");

//         // Revoke bob's role
//         vm.prank(alice);
//         Powers(daoMock).request(
//             peerSelect,
//             abi.encode(0, false),
//             nonce,
//             "Revoke bob"
//         );

//         // Verify charlotte moved to first position
//         assertEq(PeerSelect(peerSelect)._electedSorted(0), charlotte, "Charlotte should be first after bob's removal");
//         assertEq(Powers(daoMock).hasRoleSince(bob, 6), 0, "Bob should not have role anymore");
//     }

//     function testUnauthorizedAccess() public {
//         address nominateMe = laws[0];
//         address peerSelect = laws[8]; // Adjust index based on ConstitutionsMock setup

//         // Nominate bob
//         vm.prank(address(daoMock));
//         Law(nominateMe).executeLaw(bob, abi.encode(true), 54321);

//         // make sure that eve doesn't have ROLE_ONE
//         assertEq(daoMock.hasRoleSince(helen, ROLE_ONE), 0, "Helen should not have ROLE_ONE");

//         // Try to select with unauthorized account (eve doesn't have ROLE_ONE)
//         vm.prank(helen);
//         vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
//         Powers(daoMock).request(
//             peerSelect,
//             abi.encode(0, true),
//             nonce,
//             "Should fail - unauthorized"
//         );
//     }

//     function testHandleRequestValidation() public {
//         address nominateMe = laws[0];
//         address peerSelect = laws[8]; // Adjust index based on ConstitutionsMock setup

//         // Give alice permission to select peers
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         // Test with invalid index
//         vm.prank(alice);
//         vm.expectRevert(); // Should revert when accessing invalid nominee index
//         Powers(daoMock).request(
//             peerSelect,
//             abi.encode(999, true),
//             nonce,
//             "Should fail - invalid index"
//         );

//         // Test with invalid calldata
//         vm.prank(alice);
//         vm.expectRevert(); // Should revert with invalid calldata
//         Powers(daoMock).request(
//             peerSelect,
//             abi.encode(1), // Missing boolean parameter
//             nonce,
//             "Should fail - invalid calldata"
//         );
//     }
// }
