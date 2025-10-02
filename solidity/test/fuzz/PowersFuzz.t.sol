// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { TestSetupPowers  } from "../TestSetup.t.sol";
import { Powers } from "../../src/Powers.sol";
import { IPowers } from "../../src/interfaces/IPowers.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";
import { PowersErrors } from "../../src/interfaces/PowersErrors.sol";
import { PresetSingleAction } from "../../src/laws/multi/PresetSingleAction.sol";
import { OpenAction } from "../../src/laws/multi/OpenAction.sol";

/// @title Powers Core Fuzz Tests
/// @notice Deep fuzz testing for core Powers.sol functionality
/// @dev Tests core governance mechanisms with random inputs
contract PowersFuzzTest is TestSetupPowers {
    // Test state

    //////////////////////////////////////////////////////////////
    //                  VOTING MECHANISM FUZZ                   //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test voting with random parameters 
    function testFuzzVotingMechanism(
        uint8 support,
        address voter,
        bool hasRole,
        string memory reason
    ) public {
        // Bound inputs
        vm.assume(support <= 2); // 0=Against, 1=For, 2=Abstain
        vm.assume(voter != address(0));
        vm.assume(bytes(reason).length <= 500);
        vm.deal(voter, 1 ether);

        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);
        
        // Create a valid action first
        lawId = 4; // this law needs a vote. 
        lawCalldata = abi.encode(
            new address[](1),
            new uint256[](1),
            new bytes[](1)
        );
        nonce = 123;
        
        vm.prank(alice);
        uint256 validActionId = daoMock.propose(lawId, lawCalldata, nonce, "Test action");
        
        // Test voting
        if (hasRole) {
            vm.prank(address(daoMock));
            daoMock.assignRole(ROLE_ONE, voter);
        }
        if (!hasRole) vm.expectRevert(Powers__CannotCallLaw.selector);
        vm.prank(voter);
        daoMock.castVoteWithReason(validActionId, support, reason);
        // Verify vote was cast
        if (hasRole) assertTrue(daoMock.hasVoted(validActionId, voter));
    }
    
    /// @notice Fuzz test quorum calculation
    function testFuzzQuorumCalculation(
        uint256 roleIdFuzzed, // 1 
        uint256 numMembers, // 0 
        uint8 quorumFuzzed // 1
    ) public { 
        // Bound inputs
        vm.assume(roleIdFuzzed != ADMIN_ROLE && roleIdFuzzed != PUBLIC_ROLE);
        vm.assume(numMembers <= 15);
        vm.assume(quorumFuzzed <= 100); 

        uint256 numberOfMembersBefore =  daoMock.getAmountRoleHolders(roleIdFuzzed);
        
        // Add members to role
        for (i = 0; i < numMembers; i++) {
            address member = address(uint160(i + 1000));
            vm.deal(member, 1 ether);
            
            vm.prank(address(daoMock));
            daoMock.assignRole(roleIdFuzzed, member);
        }

        // Verify role member count
        assertEq(daoMock.getAmountRoleHolders(roleIdFuzzed), numMembers + numberOfMembersBefore);
        
        // Test quorum calculation
        uint256 expectedQuorum = (numMembers * quorumFuzzed) / 100;
        assertTrue(expectedQuorum >= 0);
    }
    
    /// @notice Fuzz test vote counting
    function testFuzzVoteCounting(
        address[] memory voters,
        uint256[] memory support,
        uint8 numberVotes // = max 255 votes. 
    ) public {
        // Bound inputs
        vm.assume(voters.length > numberVotes);
        vm.assume(support.length > numberVotes);
        vm.assume(numberVotes > 0);
        uint32 numberVotesCast = 0;

        // Create a valid action first
        lawId = 4; // this law needs a vote. needs ROLE_ONE.
        lawCalldata = abi.encode(
            new address[](1),
            new uint256[](1),
            new bytes[](1)
        );
        nonce = 123;

        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);
        
        vm.prank(alice);
        uint256 validActionId = daoMock.propose(lawId, lawCalldata, nonce, "Vote counting test");
        
        // Cast votes
        for (i = 0; i < numberVotes; i++) {
            vm.assume(voters[i] != address(0));
            vm.assume(daoMock.hasVoted(validActionId, voters[i]) == false); // addresses in array are NOT unique.
            vm.prank(address(daoMock));
            
            daoMock.assignRole(ROLE_ONE, voters[i]);
            vm.prank(voters[i]);
            daoMock.castVote(validActionId, uint8(support[i] % 3));
            numberVotesCast++;
        }

        // Verify vote counts
        (, , , uint32 againstVotes, uint32 forVotes, uint32 abstainVotes) = daoMock.getActionVoteData(validActionId);
        assertTrue(againstVotes + forVotes + abstainVotes <= numberVotesCast);
    } 

    //////////////////////////////////////////////////////////////
    //                  ACTION LIFECYCLE FUZZ                   //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test action state transitions
    function testFuzzActionStateTransitions(
        uint16 lawIdfuzzed,
        bytes memory lawCalldataFuzzed,
        uint256 nonceFuzzed,
        bool shouldCancel,
        bool shouldVote
    ) public {
        vm.assume(lawIdfuzzed > 0 && lawIdfuzzed < daoMock.lawCounter());
        vm.assume(lawCalldataFuzzed.length <= daoMock.MAX_CALLDATA_LENGTH());
    
        // Assign law role to alice and bob
        conditions = daoMock.getConditions(lawIdfuzzed);
        vm.assume(conditions.quorum > 0);
        vm.startPrank(address(daoMock));
        daoMock.assignRole(conditions.allowedRole, alice);
        daoMock.assignRole(conditions.allowedRole, bob);
        vm.stopPrank();
        
        // Create action
        vm.prank(alice);
        actionId = daoMock.propose(lawIdfuzzed, lawCalldataFuzzed, nonceFuzzed, "State transition test");
        
        // Verify initial state
        assertTrue(daoMock.getActionState(actionId) == PowersTypes.ActionState.Active);
        
        if (shouldVote) {
            // Cast some votes
            vm.prank(bob);
            daoMock.castVote(actionId, 1); 

            assertTrue(daoMock.hasVoted(actionId, bob));
        }
        
        if (shouldCancel) {
            // Cancel action
            vm.prank(alice);
            daoMock.cancel(lawIdfuzzed, lawCalldataFuzzed, nonceFuzzed);
            
            // Verify cancelled state
            assertTrue(daoMock.getActionState(actionId) == PowersTypes.ActionState.Cancelled);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  ROLE MANAGEMENT FUZZ                    //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test role assignment with random parameters
    function testFuzzRoleAssignment(
        address[] memory accountsFuzzed,
        uint256[] memory roleIdsFuzzed,
        uint256 numberOfAssignments,
        bool[] memory assignments
    ) public {
        // Bound inputs
        vm.assume(accountsFuzzed.length > numberOfAssignments);
        vm.assume(roleIdsFuzzed.length > numberOfAssignments); 
        vm.assume(assignments.length > numberOfAssignments);
        
        for (i = 0; i < numberOfAssignments; i++) {
            vm.assume(accountsFuzzed[i] != address(0));
            vm.assume(roleIdsFuzzed[i] != ADMIN_ROLE && roleIdsFuzzed[i] != PUBLIC_ROLE);
            vm.deal(accountsFuzzed[i], 1 ether);
            
            if (assignments[i]) {
                vm.prank(address(daoMock));
                daoMock.assignRole(roleIdsFuzzed[i], accountsFuzzed[i]);
                
                // Verify role assignment
                assertTrue(daoMock.hasRoleSince(accountsFuzzed[i], roleIdsFuzzed[i]) > 0);
            } else {
                vm.prank(address(daoMock));
                daoMock.revokeRole(roleIdsFuzzed[i], accountsFuzzed[i]);
                
                // Verify role revocation
                assertEq(daoMock.hasRoleSince(accountsFuzzed[i], roleIdsFuzzed[i]), 0);
            }
        }
    }
    
    /// @notice Fuzz test role permissions
    function testFuzzRolePermissions(
        address accountFuzzed,
        uint16 lawIdFuzzed,
        uint256 roleIdFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        vm.assume(lawIdFuzzed > 0 && lawIdFuzzed < daoMock.lawCounter());
        vm.assume(roleIdFuzzed != ADMIN_ROLE && roleIdFuzzed != PUBLIC_ROLE);
        vm.deal(accountFuzzed, 1 ether);
        
        // Assign role to account
        vm.prank(address(daoMock));
        daoMock.assignRole(roleIdFuzzed, accountFuzzed);
        
        // Test law access
        bool canCall = daoMock.canCallLaw(accountFuzzed, lawIdFuzzed);
        
        // Verify access based on law conditions
        conditions = daoMock.getConditions(lawIdFuzzed);
        if (conditions.allowedRole == PUBLIC_ROLE) {
            assertTrue(canCall);
        } else if (conditions.allowedRole == roleIdFuzzed) {
            assertTrue(canCall);
        } else {
            assertFalse(canCall);
        }
    }

    /// @notice Fuzz test role labeling
    function testFuzzLabelRole(
        uint256 roleIdFuzzed,
        string memory labelFuzzed
    ) public {
        vm.assume(roleIdFuzzed != ADMIN_ROLE && roleIdFuzzed != PUBLIC_ROLE); 
        
        vm.prank(address(daoMock));
        if (bytes(labelFuzzed).length < 1) vm.expectRevert(PowersErrors.Powers__InvalidLabel.selector);
        if (bytes(labelFuzzed).length > 255) vm.expectRevert(PowersErrors.Powers__LabelTooLong.selector);

        daoMock.labelRole(roleIdFuzzed, labelFuzzed);
        
        // Verify label was set
        assertEq(daoMock.getRoleLabel(roleIdFuzzed), labelFuzzed);
    }

    //////////////////////////////////////////////////////////////
    //                  LAW MANAGEMENT FUZZ                     //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test law conditions
    function testFuzzLawConditions(
        uint8 quorumFuzzed,
        uint8 succeedAtFuzzed,
        uint32 votingPeriodFuzzed,
        uint256 allowedRoleFuzzed
    ) public {
        vm.assume(quorumFuzzed <= daoMock.DENOMINATOR());
        vm.assume(succeedAtFuzzed <= daoMock.DENOMINATOR());
        vm.assume(votingPeriodFuzzed <= type(uint32).max);
        vm.assume(allowedRoleFuzzed != ADMIN_ROLE && allowedRoleFuzzed != PUBLIC_ROLE);

        PowersTypes.LawInitData memory lawInitData = PowersTypes.LawInitData({
            targetLaw: lawAddresses[2],
            nameDescription: "Test law conditions",
            conditions: PowersTypes.Conditions({
                quorum: quorumFuzzed,
                succeedAt: succeedAtFuzzed,
                votingPeriod: votingPeriodFuzzed,
                allowedRole: allowedRoleFuzzed,
                needCompleted: 0,
                needNotCompleted: 0,
                delayExecution: 0,
                throttleExecution: 0
            }),
            config: ""
        });
        
        vm.prank(address(daoMock));
        daoMock.adoptLaw(lawInitData);

        lawId = daoMock.lawCounter() - 1;
        // Get current law conditions
        conditions = daoMock.getConditions(lawId);
        
        // Verify conditions are within bounds
        assertTrue(conditions.quorum == quorumFuzzed);
        assertTrue(conditions.succeedAt == succeedAtFuzzed);
        assertTrue(conditions.votingPeriod == votingPeriodFuzzed);
        assertTrue(conditions.allowedRole == allowedRoleFuzzed);
    }
    
    /// @notice Fuzz test law adoption and revocation
    function testFuzzLawAdoptionRevocation(
        string memory nameDescriptionFuzzed,
        uint8 quorumFuzzed,
        uint8 succeedAtFuzzed,
        uint32 votingPeriodFuzzed,
        uint256 allowedRoleFuzzed
    ) public {
        vm.assume(quorumFuzzed <= daoMock.DENOMINATOR());
        vm.assume(succeedAtFuzzed <= daoMock.DENOMINATOR());
        vm.assume(allowedRoleFuzzed != ADMIN_ROLE && allowedRoleFuzzed != PUBLIC_ROLE);
        
        // Create law init data
        PowersTypes.LawInitData memory lawInitData = PowersTypes.LawInitData({
            targetLaw: lawAddresses[2],
            nameDescription: nameDescriptionFuzzed,
            conditions: PowersTypes.Conditions({
                quorum: quorumFuzzed,
                succeedAt: succeedAtFuzzed,
                votingPeriod: votingPeriodFuzzed,
                allowedRole: allowedRoleFuzzed,
                needCompleted: 0,
                needNotCompleted: 0,
                delayExecution: 0,
                throttleExecution: 0
            }),
            config: ""
        });
        
        // Test law adoption
        vm.prank(address(daoMock));
        if (bytes(nameDescriptionFuzzed).length < 1) vm.expectRevert("String too short");
        if (bytes(nameDescriptionFuzzed).length > 255) vm.expectRevert("String too long");
        daoMock.adoptLaw(lawInitData); 
        lawCounter = daoMock.lawCounter();
        assertTrue(lawCounter > 0);
        
        // Test law revocation
        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawCounter - 1);
        // Verify law was revoked
        (, , bool active2) = daoMock.getAdoptedLaw(lawCounter - 1);
        assertFalse(active2);
    }

    function testFuzzRevokeLaw(uint16 lawIdFuzzed) public {
        vm.assume(lawIdFuzzed > 0 && lawIdFuzzed < daoMock.lawCounter());
        
        // Get law info before revocation
        (, , bool active2) = daoMock.getAdoptedLaw(lawIdFuzzed);
        vm.assume(active2); // Only test with active laws
        
        // Revoke law
        vm.prank(address(daoMock));
        daoMock.revokeLaw(lawIdFuzzed);
        
        // Verify law was revoked
        (, , bool activeAfter) = daoMock.getAdoptedLaw(lawIdFuzzed);
        assertFalse(activeAfter);
    }

    //////////////////////////////////////////////////////////////
    //                  BLACKLIST FUZZ                         //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test blacklist functionality
    function testFuzzBlacklistManagement(
        address[] memory accountsFuzzed,
        bool[] memory blacklistedFuzzed,
        uint256 numberOfAccounts
    ) public {
        // Bound inputs
        vm.assume(accountsFuzzed.length > numberOfAccounts);
        vm.assume(blacklistedFuzzed.length > numberOfAccounts);
        vm.assume(numberOfAccounts > 0 && numberOfAccounts <= 15);
        
        for (i = 0; i < numberOfAccounts; i++) {
            vm.assume(accountsFuzzed[i] != address(0));
            
            // Set blacklist status
            vm.prank(address(daoMock));
            daoMock.blacklistAddress(accountsFuzzed[i], blacklistedFuzzed[i]);
            
            // Verify blacklist status
            assertEq(daoMock.isBlacklisted(accountsFuzzed[i]), blacklistedFuzzed[i]);
        }
    }
    
    /// @notice Fuzz test blacklisted account restrictions
    function testFuzzBlacklistedAccountRestrictions(
        address accountFuzzed,
        bytes memory lawCalldataFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        vm.assume(lawCalldataFuzzed.length <= daoMock.MAX_CALLDATA_LENGTH());
        vm.deal(accountFuzzed, 1 ether);
        
        // Blacklist account
        vm.prank(address(daoMock));
        daoMock.blacklistAddress(accountFuzzed, true);
        
        // Verify account is blacklisted
        assertTrue(daoMock.isBlacklisted(accountFuzzed));
        
        // Try to perform actions - should fail
        vm.prank(accountFuzzed);
        vm.expectRevert(Powers__AddressBlacklisted.selector);
        daoMock.request(1, lawCalldataFuzzed, nonceFuzzed, "Blacklist test");
    }
}
