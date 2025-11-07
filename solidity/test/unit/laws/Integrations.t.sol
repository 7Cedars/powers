// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { TestSetupExecutive } from "../../TestSetup.t.sol";
import { GovernorCreateProposal } from "../../../src/laws/integrations/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../../../src/laws/integrations/GovernorExecuteProposal.sol";
import { SimpleGovernor } from "@mocks/SimpleGovernor.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol"; 
import { PresetSingleAction } from "../../../src/laws/executive/PresetSingleAction.sol";

/// @notice Comprehensive unit tests for all executive laws
/// @dev Tests all functionality of executive laws including initialization, execution, and edge cases

//////////////////////////////////////////////////
//          GOVERNOR CREATE PROPOSAL TESTS     //
//////////////////////////////////////////////////
contract GovernorCreateProposalTest is TestSetupExecutive {
    GovernorCreateProposal governorCreateProposal;
    SimpleGovernor simpleGovernor;
    SimpleErc20Votes votingToken;

    function setUp() public override {
        super.setUp();
        governorCreateProposal = GovernorCreateProposal(lawAddresses[8]); // GovernorCreateProposal from executive constitution
        votingToken = SimpleErc20Votes(mockAddresses[0]);
        simpleGovernor = SimpleGovernor(payable(mockAddresses[4]));
        lawId = 2; // GovernorCreateProposal law ID in executive constitution
    }

    function testGovernorCreateProposalWithValidProposal() public {
        // Setup proposal parameters
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = "Test proposal description";

        // Execute proposal creation
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas, description), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testGovernorCreateProposalRevertsWithNoTargets() public {
        // Setup proposal parameters with no targets
        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);
        description = "Test proposal description";

        // Execute proposal creation
        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: No targets provided");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");
    }

    function testGovernorCreateProposalRevertsWithLengthMismatch() public {
        // Setup proposal parameters with length mismatch
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](2); // Different length
        values[0] = 0;
        values[1] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = "Test proposal description";

        // Execute proposal creation
        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: Targets and values length mismatch");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");
    }

    function testGovernorCreateProposalRevertsWithEmptyDescription() public {
        // Setup proposal parameters with empty description
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = ""; // Empty description

        // Execute proposal creation
        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: Description cannot be empty");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");
    }
}

//////////////////////////////////////////////////
//         GOVERNOR EXECUTE PROPOSAL TESTS     //
//////////////////////////////////////////////////
contract GovernorExecuteProposalTest is TestSetupExecutive {
    GovernorCreateProposal governorCreateProposal;
    GovernorExecuteProposal governorExecuteProposal;
    PresetSingleAction presetSingleAction;
    SimpleGovernor simpleGovernor;
    SimpleErc20Votes votingToken;

    function setUp() public override {
        super.setUp();
        governorCreateProposal = GovernorCreateProposal(lawAddresses[8]); // GovernorCreateProposal from executive constitution
        governorExecuteProposal = GovernorExecuteProposal(lawAddresses[9]); // GovernorExecuteProposal from executive constitution
        votingToken = SimpleErc20Votes(mockAddresses[0]);
        simpleGovernor = SimpleGovernor(payable(mockAddresses[4]));
        lawIds = new uint16[](1);
        lawIds[0] = 2;
        lawId = 3; // GovernorExecuteProposal law ID in executive constitution
    }

    // function testGovernorExecuteProposalWithValidProposal() public {
    //     // Setup proposal parameters
    //     targets = new address[](1);
    //     targets[0] = address(daoMock);
    //     values = new uint256[](1);
    //     values[0] = 0;
    //     calldatas = new bytes[](1);
    //     calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
    //     description = "Test proposal description";

    //     // first create a proposal in the Governor contract.
    //     vm.startPrank(alice);
    //     votingToken.mintVotes(100);
    //     votingToken.delegate(address(alice));
    //     daoMock.request(lawIds[0], abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");
    //     vm.stopPrank();

    //     uint256 proposalId = simpleGovernor.getProposalId(targets, values, calldatas, keccak256(bytes(description)));
    //     assertTrue(proposalId != 0);

    //     vm.roll(block.number + 30);

    //     // vote for the proposal
    //     vm.prank(alice);
    //     simpleGovernor.castVote(proposalId, FOR);

    //     nonce++;
    //     vm.roll(block.number + 100);

    //     // Execute proposal execution
    //     vm.prank(alice);
    //     daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");

    //     // Should succeed
    //     actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas, description), nonce)));
    //     assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    // }

    function testGovernorExecuteProposalRevertsWithNoTargets() public {
        // Setup proposal parameters with no targets
        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);
        description = "Test proposal description";

        // Execute proposal execution
        vm.prank(alice);
        vm.expectRevert("GovernorExecuteProposal: No targets provided");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");
    }

    function testGovernorExecuteProposalRevertsWithLengthMismatch() public {
        // Setup proposal parameters with length mismatch
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](2); // Different length
        values[0] = 0;
        values[1] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = "Test proposal description";

        // Execute proposal execution
        vm.prank(alice);
        vm.expectRevert("GovernorExecuteProposal: Targets and values length mismatch");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");
    }

    function testGovernorExecuteProposalRevertsWithEmptyDescription() public {
        // Setup proposal parameters with empty description
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = ""; // Empty description

        // Execute proposal execution
        vm.prank(alice);
        vm.expectRevert("GovernorExecuteProposal: Description cannot be empty");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");
    }

    function testGovernorExecuteProposalRevertsWithNonExistentProposal() public {
        // Setup proposal parameters for non-existent proposal
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = "Non-existent proposal";

        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas, description), nonce)));

        // Execute proposal execution
        vm.prank(alice);
        vm.expectRevert();
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");
    }
}
