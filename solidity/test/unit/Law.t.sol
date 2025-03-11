// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Powers} from "../../src/Powers.sol";
import { TestSetupLaw } from "../TestSetup.t.sol";
import { OpenAction } from "../../src/laws/executive/OpenAction.sol";
import { PresetAction } from "../../src/laws/executive/PresetAction.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";

//////////////////////////////////////////////////
//                  DEPLOY                      //
//////////////////////////////////////////////////

contract TempBuildTest is TestSetupLaw {
    function testTempInputParams() public {
        bytes4[] memory inputParams = new bytes4[](3);

        // inputParams[0] = _dataType("address");
        // inputParams[1] = _dataType("address");
        // inputParams[2] = _dataType("uint256");

        bytes memory test = abi.encode("address[]", "uint256[]", "bytes[]");
        console.logBytes(test);
        // (string memory one, string memory two, string memory three, string memory four) = abi.decode(test, (string, string, string, string));

        // console.log(one, two, three);
    }
}

contract DeployTest is TestSetupLaw {
    using ShortStrings for *;

    ILaw.LawConfig lawConfig;

    function testDeploy() public {
        Law lawMock = new Law("Mock Law", "This is a mock law contract", payable(address(123)), ROLE_ONE, lawConfig);

        string memory lawMockName = lawMock.name().toString();
        string memory lawMockDescription = lawMock.description();

        assertEq(lawMockName, "Mock Law");
        assertEq(lawMockDescription, "This is a mock law contract");
        assertEq(lawMock.powers(), address(123));
    }

    function testDeployEmitsEvent() public {
        vm.expectEmit(false, false, false, false);
        emit Law__Initialized(
            address(0), payable(address(123)), "Mock Law", "This is a mock law contract", ROLE_ONE, lawConfig
        );
        new Law("Mock Law", "This is a mock law contract", payable(address(123)), ROLE_ONE, lawConfig);
    }

    function testLawReturnsEmptyValue() public {
        bytes memory lawCalldata = abi.encode(123); // the amount of coins to mint.
        string memory description = "Executing a proposal vote";

        Law lawMock = new Law("Mock Law", "This is a mock law contract", payable(address(123)), ROLE_ONE, lawConfig);

        vm.prank(address(123));
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            lawMock.executeLaw(address(333), lawCalldata, keccak256(bytes(description)));

        assertEq(targets.length, 0);
        assertEq(values.length, 0);
        assertEq(calldatas.length, 0);
    }

    function testLawRevertsIfNotCalledFromPowers() public {
        bytes memory lawCalldata = abi.encode(123); // the amount of coins to mint.
        string memory description = "Executing a proposal vote";
        address powers = address(123);

        Law lawMock = new Law("Mock Law", "This is a mock law contract", payable(powers), ROLE_ONE, lawConfig);

        vm.prank(address(1)); // =! powers
        vm.expectRevert(Law__OnlyPowers.selector);
        lawMock.executeLaw(address(333), lawCalldata, keccak256(bytes(description)));
    }
}

//////////////////////////////////////////////////
//                   CONFIG                     //
//////////////////////////////////////////////////
contract NeedsProposalVoteTest is TestSetupLaw {
    function testExecuteLawSucceedsWithSuccessfulVote() public {
        // prep: create a proposal
        uint32 lawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(block.number + 4000); // forward in time

        // act
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // assert
        uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balance, 123);
    }

    function testLawRevertsWithUnsuccessfulVote() public {
        // prep: create a proposal
        uint32 lawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users, they vote against the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        vm.roll(block.number + 4000); // forward in time

        // act & assert
        vm.expectRevert(Law__ProposalNotSucceeded.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testLawRevertsIfVoteStillActive() public {
        // prep: create a proposal
        uint32 lawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        daoMock.propose(laws[lawNumber], lawCalldata, description);

        // act & assert
        vm.expectRevert(Law__ProposalNotSucceeded.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }
}

contract NeedsParentCompletedTest is TestSetupLaw {
    function testLawSucceedsIfParentCompleted() public {
        // prep: create a parent proposal, vote & execute.
        uint32 lawNumber = 1;
        uint32 parentLawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[parentLawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(block.number + 4000); // forward in time
        vm.prank(alice);
        daoMock.execute(laws[parentLawNumber], lawCalldata, description);
        // check if law has been set as completed.

        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Completed));

        uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);

        // act
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // assert
        uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balanceBefore, balanceAfter - 123);
    }

    function testLawRevertsIfParentNotCompleted() public {
        // prep: create a parent proposal and have it be defeated.
        uint32 lawNumber = 1;
        uint32 parentLawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[parentLawNumber], lawCalldata, description);

        // Loop through users, they vote against the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        vm.roll(block.number + 4000); // forward in time
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Defeated));

        // act & assert
        vm.expectRevert(Law__ParentNotCompleted.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }
}

contract ParentCanBlockTest is TestSetupLaw {
    function testLawRevertsIfParentHasCompleted() public {
        // prep: create a parent proposal and have it be defeated.
        uint32 lawNumber = 2;
        uint32 parentLawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[parentLawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(block.number + 4000); // forward in time
        vm.prank(alice);
        daoMock.execute(laws[parentLawNumber], lawCalldata, description);
        // check if law has been set as completed.
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Completed));

        // act & assert
        vm.prank(alice);
        vm.expectRevert(Law__ParentBlocksCompletion.selector);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }

    function testLawSucceedsIfParentHasNotCompleted() public {
        // prep: create a parent proposal and have it be defeated.
        uint32 lawNumber = 2;
        uint32 parentLawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[parentLawNumber], lawCalldata, description);

        // Loop through users, they vote against the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        vm.roll(block.number + 4000); // forward in time
        vm.prank(alice);
        // check if law has been set as defeated.
        ProposalState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ProposalState.Defeated));

        // act
        uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // assert
        uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balanceBefore, balanceAfter - 123);
    }
}

contract DelayProposalExecutionTest is TestSetupLaw {
    function testExecuteLawSucceedsAfterDelay() public {
        // prep: create a proposal
        uint32 lawNumber = 3;
        string memory description = "Executing a delayed proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(block.number + 10_000); // forward in time, past the delay.
        // act
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);

        // assert
        uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balance, 123);
    }

    function testExecuteLawRevertsBeforeDelay() public {
        // prep: create a proposal
        uint32 lawNumber = 3;
        string memory description = "Executing a delayed proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(block.number + 4000); // forward in time, but NOT past the delay.
        // act & assert
        vm.expectRevert(Law__DeadlineNotPassed.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, description);
    }
}

contract LimitExecutionsTest is TestSetupLaw {
    function testExecuteSucceedsWithinLimits() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        uint256 numberOfExecutions = 5;
        uint256 numberOfBlockBetweenExecutions = 15;
        bytes memory lawCalldata = abi.encode(true);

        // act
        for (uint256 i = 0; i < numberOfExecutions; i++) {
            vm.roll(block.number + block.number + numberOfBlockBetweenExecutions);
            vm.prank(alice);
            daoMock.execute(laws[lawNumber], lawCalldata, string(abi.encode(i)));
        }

        // assert
        uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balance, 123 * numberOfExecutions);
    }

    function testExecuteRevertsIfGapTooSmall() public {
        // prep: execute 10 times
        uint32 lawNumber = 4;
        bytes memory lawCalldata = abi.encode(true);
        // prep: execute once...
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, "first execute");

        // act & assert: execute twice, very soon after.
        vm.roll(block.number + 5);
        vm.expectRevert(Law__ExecutionGapTooSmall.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, "second execute");
    }
}

//////////////////////////////////////////////////
//                 FUNCTIONS                    //
//////////////////////////////////////////////////
