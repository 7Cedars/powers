// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Powers } from "../../../src/Powers.sol";
import { TestSetupIntegrations } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";
import { LawUtilities } from "../../../src/LawUtilities.sol";
import { GovernorCreateProposal } from "../../../src/laws/integrations/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../../../src/laws/integrations/GovernorExecuteProposal.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { GovernorMock } from "../../mocks/GovernorMock.sol";
import { Erc20VotesMock } from "../../mocks/Erc20VotesMock.sol";

contract GovernorCreateProposalTest is TestSetupIntegrations {
    using ShortStrings for *;

    GovernorMock public governor;
    Erc20VotesMock public votingToken;
    uint256 public constant VOTING_DELAY = 25;
    uint256 public constant VOTING_PERIOD = 50;
    uint256 public constant QUORUM_FRACTION = 4;

    function setUp() public virtual override {
        super.setUp();
        governor = GovernorMock(payable(mockAddresses[1]));
        votingToken = Erc20VotesMock(mockAddresses[2]);
    }

    function testConstructorInitialization() public {
        // Get the GovernorCreateProposal contract from the test setup
        uint16 governorCreateProposal = 1;
        (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(governorCreateProposalAddress).getConditions(address(daoMock), governorCreateProposal).allowedRole, ROLE_ONE, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(governorCreateProposalAddress).getExecutions(address(daoMock), governorCreateProposal).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testCreateProposalBasic() public {
        // prep
        uint16 governorCreateProposal = 1;
        (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
        // Create proposal data
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        description = "Create proposal to mint 5000 tokens";
        targetsIn[0] = mockAddresses[2]; // ERC20VotesMock
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);
        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // act
        vm.prank(alice);
        daoMock.request(governorCreateProposal, lawCalldata, nonce, description);

        // assert
        lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
        assertEq(
            GovernorCreateProposal(governorCreateProposalAddress).governorContracts(lawHash),
            address(governor),
            "Governor contract should be set correctly"
        );
    }

    function testCreateAndVoteOnProposal() public {
        // prep
        uint16 governorCreateProposal = 1;
        (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
        // Create proposal data
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        description = "Create proposal to mint 5000 tokens";
        targetsIn[0] = mockAddresses[2];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // Create proposal
        vm.prank(alice);
        daoMock.request(governorCreateProposal, lawCalldata, nonce, description);

        // Get proposal ID
        lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
        uint256 proposalId = governor.hashProposal(
            targetsIn,
            valuesIn,
            calldatasIn,
            keccak256(bytes(description))
        );

        // Mint voting tokens to alice
        vm.prank(alice);
        votingToken.mintVotes(5 * 10 ** 18);
        vm.prank(alice);
        votingToken.delegate(alice);

        // Fast forward past voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        // Cast vote
        vm.prank(alice);
        governor.castVote(proposalId, 1); // 1 = For

        // Fast forward past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Check vote results
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        assertEq(forVotes, 5 * 10 ** 18, "Votes should be counted correctly");
        assertEq(againstVotes, 0, "No against votes");
        assertEq(abstainVotes, 0, "No abstain votes");
    }

    function testCreateMultipleProposals() public {
        // prep
        uint16 governorCreateProposal = 1;
        (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // First proposal
        address[] memory targets1 = new address[](1);
        uint256[] memory values1 = new uint256[](1);
        bytes[] memory calldatas1 = new bytes[](1);
        targets1[0] = mockAddresses[2];
        values1[0] = 0;
        calldatas1[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        description = "First proposal";

        lawCalldata = abi.encode(targets1, values1, calldatas1, description);
        vm.prank(alice);
        daoMock.request(governorCreateProposal, lawCalldata, nonce, description);
        nonce++;

        // Second proposal
        address[] memory targets2 = new address[](1);
        uint256[] memory values2 = new uint256[](1);
        bytes[] memory calldatas2 = new bytes[](1);
        targets2[0] = mockAddresses[2];
        values2[0] = 0;
        calldatas2[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        description = "Second proposal";

        lawCalldata = abi.encode(targets2, values2, calldatas2, description);
        vm.prank(alice);
        daoMock.request(governorCreateProposal, lawCalldata, nonce, description);

        // assert
        lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
        assertEq(
            GovernorCreateProposal(governorCreateProposalAddress).governorContracts(lawHash),
            address(governor),
            "Governor contract should be set correctly for both proposals"
        );
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 governorCreateProposal = 1;
        (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
        // Create proposal data
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = mockAddresses[2];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        description = "Create proposal to mint 5000 tokens";

        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(governorCreateProposalAddress).handleRequest(alice, address(daoMock), governorCreateProposal, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(governor), "Target should be the GovernorMock");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(calldatas[0], "", "Calldata should not be empty");
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 governorCreateProposal = 1;
        
        // Create proposal data
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = mockAddresses[2];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        description = "Create proposal to mint 5000 tokens";

        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        // Try to create proposal without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(governorCreateProposal, lawCalldata, nonce, "Unauthorized proposal creation");
    }

    function testProposalDescriptionFormat() public {
        // prep
        uint16 governorCreateProposal = 1;
        (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
        // Create proposal data
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = mockAddresses[2];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        description = "Create proposal to mint 5000 tokens";

        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(governorCreateProposalAddress).handleRequest(alice, address(daoMock), governorCreateProposal, lawCalldata, nonce);

        // assert
        // Need to deconstruct abi.encodeWITHSELECTOR. -- I have a solution for this. Somewhere.. 
        // bytes memory expectedDescription = abi.encodePacked(
        //     "This is a proposal created in the Powers protocol.\n",
        //     "To see the proposal, please visit: https://powers-protocol.vercel.app/",
        //     Strings.toHexString(uint256(uint160(address(daoMock)))),
        //     "/proposals/",
        //     Strings.toString(governorCreateProposal)
        // );

        // // Extract the description from the calldata
        // bytes memory proposeCalldata = calldatas[0];
        // bytes32 descriptionHash = abi.decode(proposeCalldata[proposeCalldata.length - 32:], (bytes32));
        // assertEq(
        //     keccak256(abi.encodePacked(expectedDescription)),
        //     descriptionHash,
        //     "Proposal description should be formatted correctly"
        // );
    }
}

contract GovernorExecuteProposalTest is TestSetupIntegrations {
    using ShortStrings for *;

    GovernorMock public governor;
    Erc20VotesMock public votingToken;
    uint256 public constant VOTING_DELAY = 25;
    uint256 public constant VOTING_PERIOD = 50;

    function setUp() public virtual override {
        super.setUp();
        governor = GovernorMock(payable(mockAddresses[1]));
        votingToken = Erc20VotesMock(mockAddresses[2]);
    }

    function testConstructorInitialization() public {
        // Get the GovernorExecuteProposal contract from the test setup
        uint16 governorExecuteProposal = 2;
        (address governorExecuteProposalAddress, , ) = daoMock.getActiveLaw(governorExecuteProposal);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(governorExecuteProposalAddress).getConditions(address(daoMock), governorExecuteProposal).allowedRole, type(uint256).max, "Allowed role should be set to PUBLIC_ROLE");
        // assertEq(Law(governorExecuteProposalAddress).getConditions(address(daoMock), governorExecuteProposal).needCompleted, 1, "Need completed should be set to 1");
        assertEq(Law(governorExecuteProposalAddress).getExecutions(address(daoMock), governorExecuteProposal).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testCheckVoteBasic() public {
        // prep
        uint16 governorExecuteProposal = 2;
        (address governorExecuteProposalAddress, , ) = daoMock.getActiveLaw(governorExecuteProposal);
        
        // Create proposal data
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        description = "Check proposal to mint 5000 tokens";
        targetsIn[0] = mockAddresses[2]; // ERC20VotesMock
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        // Create a proposal first
        uint16 governorCreateProposal = 1;
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);
        vm.prank(alice);
        daoMock.request(governorCreateProposal, lawCalldata, nonce, description);

        // Get proposal ID
        lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
        uint256 proposalId = governor.hashProposal(
            targetsIn,
            valuesIn,
            calldatasIn,
            keccak256(bytes(description))
        );

        // Mint voting tokens to alice
        for (i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            votingToken.mintVotes(5 * 10 ** 18);
            vm.prank(users[i]);
            votingToken.delegate(users[i]);
        }

        // Fast forward past voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        // Cast vote
        for (i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            governor.castVote(proposalId, 1); // 1 = For
        }

        // Fast forward past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Now check the vote
        vm.prank(alice);
        daoMock.request(governorExecuteProposal, lawCalldata, nonce, description);

        // assert
        lawHash = LawUtilities.hashLaw(address(daoMock), governorExecuteProposal);
        assertEq(
            GovernorExecuteProposal(governorExecuteProposalAddress).governorContracts(lawHash),
            address(governor),
            "Governor contract should be set correctly"
        );
    }

    function testCheckVoteProposalNotFound() public {
        // prep
        uint16 governorExecuteProposal = 2;
        (address governorExecuteProposalAddress, , ) = daoMock.getActiveLaw(governorExecuteProposal);
        
        // Create proposal data with non-existent proposal
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        description = "Check non-existent proposal";
        targetsIn[0] = mockAddresses[2];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        // proposal Id 
        uint256 proposalId = governor.hashProposal(
            targetsIn,
            valuesIn,
            calldatasIn,
            keccak256(bytes(description))
        );

        // Try to check non-existent proposal
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorNonexistentProposal.selector, proposalId));
        daoMock.request(governorExecuteProposal, lawCalldata, nonce, description);
    }

    function testCheckVoteProposalNotSucceeded() public {
        // prep
        uint16 governorExecuteProposal = 2;
        (address governorExecuteProposalAddress, , ) = daoMock.getActiveLaw(governorExecuteProposal);
        
        // Create proposal data
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        description = "Check proposal that hasn't succeeded";
        targetsIn[0] = mockAddresses[2];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        // Create a proposal first
        uint16 governorCreateProposal = 1;
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);
        vm.prank(alice);
        daoMock.request(governorCreateProposal, lawCalldata, nonce, description);

        // Get proposal ID
        lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
        uint256 proposalId = governor.hashProposal(
            targetsIn,
            valuesIn,
            calldatasIn,
            keccak256(bytes(description))
        );

        // Try to check proposal before it has succeeded
        vm.prank(alice);
        vm.expectRevert("Proposal not succeeded");
        daoMock.request(governorExecuteProposal, lawCalldata, nonce, description);
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 governorExecuteProposal = 2;
        (address governorExecuteProposalAddress, , ) = daoMock.getActiveLaw(governorExecuteProposal);
        
        // Create proposal data
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = mockAddresses[2];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5 * 10 ** 18);
        description = "Check proposal to mint 5000 tokens";

        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn, description);

        // Create a proposal first
        uint16 governorCreateProposal = 1;
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);
        vm.prank(alice);
        daoMock.request(governorCreateProposal, lawCalldata, nonce, description);

        // Get proposal ID
        lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
        uint256 proposalId = governor.hashProposal(
            targetsIn,
            valuesIn,
            calldatasIn,
            keccak256(bytes(description))
        );

        // Mint voting tokens to alice
        vm.prank(alice);
        votingToken.mintVotes(5 * 10 ** 18);
        vm.prank(alice);
        votingToken.delegate(alice);

        // Fast forward past voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        // Cast vote
        vm.prank(alice);
        governor.castVote(proposalId, 1); // 1 = For

        // Fast forward past voting period
        vm.roll(block.number + VOTING_PERIOD + 1);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            
        ) = Law(governorExecuteProposalAddress).handleRequest(alice, address(daoMock), governorExecuteProposal, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], mockAddresses[2], "Target should be daoMock");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(calldatas[0], calldatasIn[0], "Calldata should be the same");
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

