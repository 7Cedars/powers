// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/utils/ShortStrings.sol";
// import { Powers} from "../../src/Powers.sol";
// import { TestSetupLaw } from "../TestSetup.t.sol";
// import { OpenAction } from "../../src/laws/executive/OpenAction.sol";
// import { PresetAction } from "../../src/laws/executive/PresetAction.sol";
// import { Law } from "../../src/Law.sol";
// import { LawUtilities } from "../../src/LawUtilities.sol";
// import { ILaw } from "../../src/interfaces/ILaw.sol";
// import { Erc1155Mock } from "../mocks/Erc1155Mock.sol";
// //////////////////////////////////////////////////
// //                  DEPLOY                      //
// //////////////////////////////////////////////////
// contract DeployTest is TestSetupLaw {
//     using ShortStrings for *;

//     function testDeploy() public {
//         Law lawMock = new OpenAction("Mock Law", "This is a mock law contract", payable(address(123)), ROLE_ONE, Conditions);

//         string memory lawMockName = lawMock.name().toString();

//         assertEq(lawMockName, "Mock Law"); 
//         assertEq(lawMock.powers(), address(123));
//     }

//     function testDeployEmitsEvent() public {
//         bytes memory params = abi.encode(
//             "address[] Targets", 
//             "uint256[] Values", 
//             "bytes[] CallDatas"
//             );
//         vm.expectEmit(false, false, false, false);
//         emit Law__Initialized(
//             payable(address(0)), "Mock Law", "This is a mock law contract", address(123), ROLE_ONE, Conditions, params
//         );
//         new OpenAction("Mock Law", "This is a mock law contract", payable(address(123)), ROLE_ONE, Conditions);
//     }

//     function testLawRevertsIfNotCalledFromPowers() public {
//         lawCalldata = abi.encode([address(123)], [0], ["0x0"]);
//         description = "Executing a proposal vote";
//         address powersTemp = address(123);

//         Law lawMock = new OpenAction("Mock Law", "This is a mock law contract", payable(powersTemp), ROLE_ONE, Conditions);

//         vm.prank(address(1)); // =! powers
//         vm.expectRevert(Law__OnlyPowers.selector);
//         lawMock.executeLaw(address(333), lawCalldata, nonce);
//     }
// }

// //////////////////////////////////////////////////
// //                   CONFIG                     //
// //////////////////////////////////////////////////
// contract NeedsProposalVoteTest is TestSetupLaw {
//     function testExecuteLawSucceedsWithSuccessfulVote() public {
//         // prep: create a proposal
//         uint32 lawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);

//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time

//         // act
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // assert
//         uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balance, 123);
//     }

//     function testLawRevertsWithUnsuccessfulVote() public {
//         // prep: create a proposal
//         uint32 lawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote against the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, AGAINST);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time

//         // act & assert
//         vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testLawRevertsIfVoteStillActive() public {
//         // prep: create a proposal
//         uint32 lawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // act & assert
//         vm.expectRevert(LawUtilities.LawUtilities__ProposalNotSucceeded.selector);
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }
// }

// contract NeedsParentCompletedTest is TestSetupLaw {
//     function testLawSucceedsIfParentCompleted() public {
//         // prep: create a parent proposal, vote & execute.
//         uint32 lawNumber = 1;
//         uint32 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);
        
//         // First execute parent law
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time
        
//         // Execute parent law
//         vm.prank(alice);
//         daoMock.request(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Verify parent law state
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Fulfilled));

//         // Record balance before executing dependent law
//         uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);

//         // Now execute the dependent law
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // Verify the execution succeeded by checking balance change
//         uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balanceBefore + 123, balanceAfter);
//     }

//     function testLawRevertsIfParentNotCompleted() public {
//         // prep: create a parent proposal and have it be defeated
//         uint32 lawNumber = 1;
//         uint32 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);
        
//         // Create and vote against parent proposal
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote against the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, AGAINST);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time
        
//         // Verify parent proposal was defeated
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Defeated));

//         // Attempt to execute dependent law - should revert
//         vm.expectRevert(LawUtilities.LawUtilities__ParentNotCompleted.selector);    
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testLawRevertsIfParentNotFulfilled() public {
//         // prep: create a parent proposal that succeeds vote but isn't executed
//         uint32 lawNumber = 1;
//         uint32 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);
        
//         // Create and vote for parent proposal
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time
        
//         // Verify parent proposal succeeded but not executed
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Succeeded));

//         // Attempt to execute dependent law - should revert
//         vm.expectRevert(LawUtilities.LawUtilities__ParentNotCompleted.selector);
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }
// }

// contract ParentCanBlockTest is TestSetupLaw {
//     function testLawRevertsIfParentHasCompleted() public {
//         // prep: create a parent proposal and execute it
//         uint32 lawNumber = 2;
//         uint32 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);
        
//         // Create and vote for parent proposal
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time
        
//         // Execute parent law
//         vm.prank(alice);
//         daoMock.request(laws[parentLawNumber], lawCalldata, nonce, description);
        
//         // Verify parent law is fulfilled
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Fulfilled));

//         // Attempt to execute blocked law - should revert
//         vm.expectRevert(LawUtilities.LawUtilities__ParentBlocksCompletion.selector);
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }

//     function testLawSucceedsIfParentHasNotCompleted() public {
//         // prep: create a parent proposal and have it be defeated
//         uint32 lawNumber = 2;
//         uint32 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);
        
//         // Create and vote against parent proposal
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote against the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, AGAINST);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time
        
//         // Verify parent proposal was defeated
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Defeated));

//         // Record balance before executing blocked law
//         uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);

//         // Execute blocked law - should succeed since parent is not fulfilled
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // Verify the execution succeeded by checking balance change
//         uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balanceBefore + 123, balanceAfter);
//     }

//     function testLawSucceedsIfParentNotExecuted() public {
//         // prep: create a parent proposal that succeeds vote but isn't executed
//         uint32 lawNumber = 2;
//         uint32 parentLawNumber = 0;
//         description = "Executing a proposal vote";
//         lawCalldata = abi.encode(true);
        
//         // Create and vote for parent proposal
//         vm.prank(alice);
//         uint256 parentActionId = daoMock.propose(laws[parentLawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(parentActionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time
        
//         // Verify parent proposal succeeded but wasn't executed
//         ActionState parentState = daoMock.state(parentActionId);
//         assertEq(uint8(parentState), uint8(ActionState.Succeeded));

//         // Record balance before executing blocked law
//         uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);

//         // Execute blocked law - should succeed since parent is not fulfilled
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // Verify the execution succeeded by checking balance change
//         uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balanceBefore + 123, balanceAfter);
//     }
// }

// contract DelayProposalExecutionTest is TestSetupLaw {
//     function testExecuteLawSucceedsAfterDelay() public {
//         // prep: create a proposal
//         uint32 lawNumber = 3;
//         description = "Executing a delayed proposal vote";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, FOR);
//             }
//         }
//         vm.roll(block.number + 10_000); // forward in time, past the delay.
//         // act
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);

//         // assert
//         uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balance, 123);
//     }

//     function testExecuteLawRevertsBeforeDelay() public {
//         // prep: create a proposal
//         uint32 lawNumber = 3;
//         description = "Executing a delayed proposal vote";
//         lawCalldata = abi.encode(true);
//         vm.prank(alice);
//         actionId = daoMock.propose(laws[lawNumber], lawCalldata, nonce, description);

//         // Loop through users, they vote for the proposal
//         for (i = 0; i < users.length; i++) {
//             if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
//                 vm.prank(users[i]);
//                 daoMock.castVote(actionId, FOR);
//             }
//         }
//         vm.roll(block.number + 4000); // forward in time, but NOT past the delay.
//         // act & assert
//         vm.expectRevert(LawUtilities.LawUtilities__DeadlineNotPassed.selector);
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, description);
//     }
// }

// contract LimitExecutionsTest is TestSetupLaw {
//     function testExecuteSucceedsWithinLimits() public {
//         // prep: create a proposal
//         uint32 lawNumber = 4;
//         uint256 numberOfExecutions = 5;
//         uint256 numberOfBlockBetweenExecutions = 15;
//         lawCalldata = abi.encode(true);

//         // act
//         for (i = 0; i < numberOfExecutions; i++) {
//             vm.roll(block.number + block.number + numberOfBlockBetweenExecutions);
//             vm.prank(alice);
//             daoMock.request(laws[lawNumber], lawCalldata, nonce, string(abi.encode(i)));
//             nonce++;
//         }

//         // assert
//         uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
//         assertEq(balance, 123 * numberOfExecutions);
//     }

//     function testExecuteRevertsIfGapTooSmall() public {
//         // prep: execute 10 times
//         uint32 lawNumber = 4;
//         lawCalldata = abi.encode(true);
//         // prep: execute once...
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, "first execute");

//         // act & assert: execute twice, very soon after.
//         vm.roll(block.number + 5);
//         nonce++;
//         vm.expectRevert(LawUtilities.LawUtilities__ExecutionGapTooSmall.selector);
//         vm.prank(alice);
//         daoMock.request(laws[lawNumber], lawCalldata, nonce, "second execute");
//     }
// }