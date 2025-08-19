// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Powers } from "../../../src/Powers.sol";
import { TestSetupElectoral } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";
import { LawUtilities } from "../../../src/LawUtilities.sol";
import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";
// import { VoteOnAccounts } from "../../../src/laws/state/VoteOnAccounts.sol";
import { Erc20VotesMock } from "../../mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../../mocks/Erc20TaxedMock.sol";

import { NominateMe } from "../../../src/laws/state/NominateMe.sol";
import { RenounceRole } from "../../../src/laws/electoral/RenounceRole.sol";
import { PeerSelect } from "../../../src/laws/electoral/PeerSelect.sol";
import { DirectSelect } from "../../../src/laws/electoral/DirectSelect.sol";
import { TaxSelect } from "../../../src/laws/electoral/TaxSelect.sol";
import { DirectDeselect } from "../../../src/laws/electoral/DirectDeselect.sol";
// import { Subscription } from "../../../src/laws/electoral/Subscription.sol";
import { StartElection } from "../../../src/laws/electoral/StartElection.sol";
import { EndElection } from "../../../src/laws/electoral/EndElection.sol";
import { NStrikesYourOut } from "../../../src/laws/electoral/NStrikesYourOut.sol";

contract DelegateSelectTest is TestSetupElectoral {
    using ShortStrings for *;
    
    function testAssignDelegateRolesWithFewNominees() public {
        Erc20VotesMock erc20VotesMock = Erc20VotesMock(mockAddresses[2]);
        
        // prep -- nominate charlotte
        
        uint16 delegateSelect = 2;
        lawCalldataNominate = abi.encode(true); // 1
        lawCalldataElect = abi.encode(); // empty calldata

        // First nominate charlotte
        vm.prank(charlotte);
        daoMock.request(
            1,
            lawCalldataNominate,
            nonce,
            "nominating charlotte!"
        );
        nonce++;

        // Mint and delegate votes to charlotte
        vm.prank(charlotte);
        erc20VotesMock.mintVotes(100);
        erc20VotesMock.delegate(charlotte);

        // Execute the delegate select law
        vm.prank(charlotte);
        daoMock.request(
            delegateSelect,
            lawCalldataElect,
            nonce,
            "electing delegate roles!"
        );

        // assert
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should have ROLE_THREE after execution");
    }

    function testAssignDelegateRolesWithManyNominees() public {
        Erc20VotesMock erc20VotesMock = Erc20VotesMock(mockAddresses[2]);

        // prep -- nominate all users
        
        uint16 delegateSelect = 2;
        lawCalldataNominate = abi.encode(true); // 1

        // Nominate users
        for (i = 4; i < users.length; i++) {
            vm.prank(users[i]);
            daoMock.request(
                1,
                lawCalldataNominate,
                nonce,
                "nominating user!"
            );
            nonce++;
        }

        // Mint and delegate votes to users
        for (i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            erc20VotesMock.mintVotes(100 + i * 2);
            erc20VotesMock.delegate(users[i]); // delegate votes to themselves
            vm.stopPrank();
        }

        // Execute the delegate select law
        vm.prank(charlotte);
        daoMock.request(
            delegateSelect,
            abi.encode(),
            nonce,
            "electing delegate roles!"
        );

        // assert
        for (i = 0; i < 2; i++) {
            assertNotEq(daoMock.hasRoleSince(users[i], ROLE_THREE), 0, "User should have ROLE_THREE after execution");
        }
    }

    function testDelegatesReelectionWorks() public {
        Erc20VotesMock erc20VotesMock = Erc20VotesMock(mockAddresses[2]);

        // prep -- nominate all users
        
        uint16 delegateSelect = 2;
        lawCalldataNominate = abi.encode(true); // 1

        // First election setup
        for (i = 0; i < users.length; i++) {
            // Nominate users
            vm.prank(users[i]);
            daoMock.request(
                1,
                lawCalldataNominate,
                nonce,
                "nominating user!"
            );
            nonce++;

            // Mint and delegate votes
            vm.startPrank(users[i]);
            erc20VotesMock.mintVotes(100 + i * 2);
            erc20VotesMock.delegate(users[i % 3]);
            vm.stopPrank();
        }

        // Execute first election
        vm.prank(charlotte);
        daoMock.request(
            delegateSelect,
            abi.encode(),
            nonce,
            "First election for delegate roles!"
        );
        nonce++;
        // Verify initial roles
        for (i = 0; i < 3; i++) {
            assertNotEq(daoMock.hasRoleSince(users[i], ROLE_THREE), 0, "User should have ROLE_THREE after first election");
        }

        // Move forward in time
        vm.roll(block.number + 100);

        // Second election setup
        // First election setup
        for (i = 0; i < users.length; i++) {
            // redelegate votes to different users
            vm.startPrank(users[i]);
            erc20VotesMock.delegate(users[i % 5 + 3]);
            vm.stopPrank();
        }

        // Execute second election
        vm.prank(charlotte);
        daoMock.request(
            delegateSelect,
            abi.encode(),
            nonce,
            "Second election for delegate roles!"
        );

        // Verify roles were revoked
        for (i = 0; i < 3; i++) {
            assertEq(daoMock.hasRoleSince(users[i], ROLE_THREE), 0, "Previous holders should not have ROLE_THREE after second election");
        }
    }
}

contract HolderSelectTest is TestSetupElectoral {
    using ShortStrings for *;
    
    function testAssignRoleWhenHoldingEnoughTokens() public {
        Erc20TaxedMock erc20TaxedMock = Erc20TaxedMock(mockAddresses[3]);
        
        // prep: mint tokens to charlotte
        uint16 holderSelect = 4;
        lawCalldata = abi.encode(charlotte);

        // Mint tokens to charlotte (more than minimum threshold of 1000)
        vm.prank(charlotte);
        erc20TaxedMock.faucet();

        // Execute the holder select law
        vm.prank(alice); // has role 1
        daoMock.request(
            holderSelect,
            lawCalldata,
            nonce,
            "assigning role based on token holdings!"
        );

        // assert
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_FOUR), 0, "Charlotte should have ROLE_FOUR after holding enough tokens");
    }

    function testRevokeRoleWhenNotHoldingEnoughTokens() public {
        Erc20TaxedMock erc20TaxedMock = Erc20TaxedMock(mockAddresses[3]);
        
        // prep: mint tokens to charlotte and assign role
        uint16 holderSelect = 4;
        lawCalldata = abi.encode(charlotte);

        // First assign role by minting enough tokens
        vm.prank(charlotte);
        erc20TaxedMock.faucet();

        vm.prank(alice);
        daoMock.request(
            holderSelect,
            lawCalldata,
            nonce,
            "assigning role based on token holdings!"
        );
        nonce++;

        // Now burn tokens to go below threshold
        vm.prank(charlotte);
        erc20TaxedMock.transfer(address(daoMock), 1 * 10 ** 18 - 500); // now has 500 tokens, below 1000 threshold

        // Execute holder select again
        vm.prank(alice);
        daoMock.request(
            holderSelect,
            lawCalldata,
            nonce,
            "revoking role due to insufficient token holdings!"
        );

        // assert
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_FOUR), 0, "Charlotte should not have ROLE_FOUR after falling below token threshold");
    }

    function testNoRoleChangeWhenHoldingEnoughTokens() public {
        Erc20TaxedMock erc20TaxedMock = Erc20TaxedMock(mockAddresses[3]);
        
        // prep: mint tokens to charlotte and assign role
        uint16 holderSelect = 4;
        lawCalldata = abi.encode(charlotte);

        // First assign role by minting enough tokens
        vm.prank(charlotte);
        erc20TaxedMock.faucet();

        vm.prank(alice);
        daoMock.request(
            holderSelect,
            lawCalldata,
            nonce,
            "assigning role based on token holdings!"
        );
        nonce++;

        // Execute holder select again while still holding enough tokens
        vm.prank(alice);
        daoMock.request(
            holderSelect,
            lawCalldata,
            nonce,
            "checking role with sufficient token holdings!"
        );

        // assert
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_FOUR), 0, "Charlotte should still have ROLE_FOUR while holding enough tokens");
    }

    function testRevertsWhenCallerHasNoAccess() public {
        Erc20TaxedMock erc20TaxedMock = Erc20TaxedMock(mockAddresses[3]);
        
        // prep: mint tokens to charlotte
        uint16 holderSelect = 4;
        address caller = makeAddr("caller");
        lawCalldata = abi.encode(caller);

        // Mint tokens to charlotte
        vm.prank(caller);
        erc20TaxedMock.faucet();

        // Try to execute with unauthorized caller
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(Powers__AccessDenied.selector));
        daoMock.request(
            holderSelect,
            lawCalldata,
            nonce,
            "unauthorized role assignment attempt!"
        );
    }
}


contract RenounceRoleTest is TestSetupElectoral {
    function testConstructorInitialization() public {
        // Get the RenounceRole contract from the test setup
        uint16 renounceRole = 6;
        (address renounceRoleAddress, , ) = daoMock.getActiveLaw(renounceRole);
        
        // Test that the contract was initialized correctly
        vm.startPrank(address(daoMock));
        assertEq(Law(renounceRoleAddress).getConditions(address(daoMock), renounceRole).allowedRole, ROLE_ONE, "Allowed role should be set to ROLE_ONE");

        assertEq(Law(renounceRoleAddress).getExecutions(address(daoMock), renounceRole).powers, address(daoMock), "Powers address should be set correctly");

        // Test that the allowed role IDs were set correctly
        assertEq(RenounceRole(renounceRoleAddress).getAllowedRoleIds(LawUtilities.hashLaw(address(daoMock), renounceRole))[0], ROLE_THREE, "First allowed role ID should be ROLE_THREE");
        vm.stopPrank();
    }

    function testSuccessfulRoleRenouncement() public {
        // prep
        uint16 renounceRole = 6;
        lawCalldata = abi.encode(ROLE_THREE);
        description = "Renouncing role";

        // Store initial state
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should have ROLE_THREE initially");

        // act
        vm.prank(alice);
        daoMock.request(renounceRole, lawCalldata, nonce, description);

        // assert
        assertEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should not have ROLE_THREE after renouncing");
    }

    function testCannotRenounceUnallowedRole() public {
        // prep
        uint16 renounceRole = 6;
        lawCalldata = abi.encode(ROLE_ONE); // ROLE_ONE is not in allowedRoleIds

        // act & assert
        vm.prank(alice);
        vm.expectRevert("Role not allowed to be renounced.");
        daoMock.request(renounceRole, lawCalldata, nonce, "Attempting to renounce unallowed role");
    }

    function testCannotRenounceRoleNotHeld() public {
        // prep
        uint16 renounceRole = 6;
        lawCalldata = abi.encode(ROLE_THREE);

        // Ensure helen doesn't have ROLE_THREE
        assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0, "Helen should not have ROLE_THREE initially");

        // act & assert
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, helen);

        vm.prank(helen);
        vm.expectRevert("Account does not have role.");
        daoMock.request(renounceRole, lawCalldata, nonce, "Attempting to renounce unheld role");
    }

    function testHandleRequestOutputRenounceRole() public {
        // prep
        uint16 renounceRole = 6;
        (address renounceRoleAddress, , ) = daoMock.getActiveLaw(renounceRole);
        lawCalldata = abi.encode(ROLE_THREE);
        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(renounceRoleAddress).handleRequest(alice, address(daoMock), renounceRole, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(
            calldatas[0],
            abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_THREE, alice),
            "Calldata should be for role revocation"
        );
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}


contract SelfSelectTest is TestSetupElectoral {
    function testConstructorInitialization() public {
        // Get the SelfSelect contract from the test setup
        uint16 selfSelect = 7;
        (address selfSelectAddress, , ) = daoMock.getActiveLaw(selfSelect);
        
        vm.startPrank(address(daoMock));
        // Test that the contract was initialized correctly
        assertEq(Law(selfSelectAddress).getConditions(address(daoMock), selfSelect).allowedRole, type(uint256).max, "Allowed role should be set to public access");
        assertEq(Law(selfSelectAddress).getExecutions(address(daoMock), selfSelect).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testSuccessfulSelfAssignment() public {
        // prep
        uint16 selfSelect = 7;
        lawCalldata = abi.encode();
        description = "Self selecting role";

        // Store initial state
        assertEq(daoMock.hasRoleSince(bob, ROLE_FOUR), 0, "Bob should not have role initially");

        // act
        vm.prank(bob);
        daoMock.request(selfSelect, lawCalldata, nonce, description);

        // assert
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_FOUR), 0, "Bob should have role after self-selection");
    }

    function testCannotAssignRoleTwice() public {
        // prep
        uint16 selfSelect = 7;
        lawCalldata = abi.encode();

        // First assignment
        vm.prank(bob);
        daoMock.request(selfSelect, lawCalldata, nonce, "Self selecting role once..");
        nonce++;

        // Try to assign again
        vm.prank(bob);
        vm.expectRevert("Account already has role.");
        daoMock.request(selfSelect, lawCalldata, nonce, "Self selecting role twice..");
    }

    function testMultipleAccountsSelfAssign() public {
        // prep
        uint16 selfSelect = 7;
        lawCalldata = abi.encode();

        // Have multiple users self-assign the role
        for (i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            daoMock.request(
                selfSelect,
                lawCalldata,
                nonce,
                string.concat("Self selecting role - user ", Strings.toString(i))
            );
            nonce++;
            assertNotEq(
                daoMock.hasRoleSince(users[i], ROLE_FOUR),
                0,
                string.concat("User ", Strings.toString(i), " should have role after self-selection")
            );
        }
    }

    function testHandleRequestOutputSelfSelect() public {
        // prep
        uint16 selfSelect = 7;
        (address selfSelectAddress, , ) = daoMock.getActiveLaw(selfSelect);
        lawCalldata = abi.encode();
        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,   
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(selfSelectAddress).handleRequest(bob, address(daoMock), selfSelect, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(
            calldatas[0],
            abi.encodeWithSelector(Powers.assignRole.selector, ROLE_FOUR, bob),
            "Calldata should be for role assignment"
        );
        assertEq(stateChange, "", "State change should be empty");
        assertTrue(actionId != 0, "Action ID should not be 0");
    }
}


contract PeerSelectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get 5 from laws array
         // Adjust index based on ConstitutionsMock setup
        (address peer_SelectAddress, , ) = daoMock.getActiveLaw(5);

        vm.startPrank(address(daoMock));
        assertEq(Law(peer_SelectAddress).getConditions(address(daoMock), 5).allowedRole, ROLE_ONE, "Allowed role should be ROLE_ONE");
        assertEq(Law(peer_SelectAddress).getExecutions(address(daoMock), 5).powers, address(daoMock), "Powers address should be set correctly");

        PeerSelect.Data memory data = PeerSelect(peer_SelectAddress).getData(LawUtilities.hashLaw(address(daoMock), 5));
        assertEq(data.roleId, ROLE_FOUR, "Role ID should be set correctly");
        assertEq(data.maxRoleHolders, 2, "Max role holders should be set correctly");
        vm.stopPrank();
    }

    function testNominationAndSelection() public {
         // Adjust index based on ConstitutionsMock setup
        (address peer_SelectAddress, , ) = daoMock.getActiveLaw(5);

        // First nominate alice
        vm.prank(alice);
        daoMock.request(1, abi.encode(true), nonce, string(abi.encodePacked("Nominate ", alice)));
        nonce++;

        // Give bob permission to select peers
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, bob);

        // Select alice as peer
        vm.prank(bob);
        daoMock.request(
            5,
            abi.encode(0, true), // index 0, assign=true
            nonce,
            "Select alice as peer"
        );

        // Verify selection
        vm.startPrank(address(daoMock));
        assertEq(PeerSelect(peer_SelectAddress).getData(LawUtilities.hashLaw(address(daoMock), 5)).electedSorted[0], alice, "Alice should be elected");
        assertTrue(daoMock.hasRoleSince(alice, ROLE_FOUR) > 0, "Alice should have role");
        vm.stopPrank();
    }

    function testMultipleNominationsAndSelections() public {
         // Adjust index based on ConstitutionsMock setup
         // Adjust index based on ConstitutionsMock setup
        (address peer_SelectAddress, , ) = daoMock.getActiveLaw(5);
        (address nominate_MeAddress, , ) = daoMock.getActiveLaw(1);

        // Give alice permission to select peers
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // Nominate multiple users
        nominees = new address[](2);
        nominees[0] = bob;
        nominees[1] = charlotte;

        for (i = 0; i < nominees.length; i++) {
            vm.prank(nominees[i]);
            daoMock.request(1, abi.encode(true), nonce, string(abi.encodePacked("Nominate ", nominees[i])));
            nonce++;
        }

        // Select all nominees
        for (i = 0; i < nominees.length; i++) {
            vm.prank(alice);
            daoMock.request(
                5,
                abi.encode(i, true),
                nonce,
                string(abi.encodePacked("Select nominee ", i))
            );
            nonce++;
        }

        // Verify selections
        for (i = 0; i < nominees.length; i++) {
            assertEq(PeerSelect(peer_SelectAddress).getData(LawUtilities.hashLaw(address(daoMock), 5)).electedSorted[i], nominees[i], "Nominee should be elected");
            assertTrue(
                daoMock.hasRoleSince(nominees[i], 4) > 0,
                "Nominee should have role"
            );
        }
    }

    function testMaxRoleHoldersLimit() public {
         // Adjust index based on ConstitutionsMock setup
         // Adjust index based on ConstitutionsMock setup
        (address peer_SelectAddress, , ) = daoMock.getActiveLaw(5);
        (address nominate_MeAddress, , ) = daoMock.getActiveLaw(1);

        // Give alice permission to select peers
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // Nominate more than max allowed
        nominees = new address[](3); // MAX_ROLE_HOLDERS is 2
        nominees[0] = bob;
        nominees[1] = charlotte;
        nominees[2] = david;

        for (i = 0; i < nominees.length; i++) {
            vm.prank(nominees[i]);
            daoMock.request(1, abi.encode(true), nonce, string(abi.encodePacked("Nominate ", nominees[i])));
            nonce++;
        }

        // Select up to max allowed
        for (i = 0; i < 2; i++) {
            vm.prank(alice);
            daoMock.request(
                5,
                abi.encode(i, true),
                nonce,
                string(abi.encodePacked("Select nominee ", i))
            );
            nonce++;
        }

        // Try to select one more - should fail
        vm.prank(alice);
        vm.expectRevert("Max role holders reached.");
        daoMock.request(
            5,
            abi.encode(2, true),
            nonce,
            "Should fail - max reached"
        );
    }

    function testRevokeAndReassign() public {
         // Adjust index based on ConstitutionsMock setup
         // Adjust index based on ConstitutionsMock setup
        (address peer_SelectAddress, , ) = daoMock.getActiveLaw(5);
        (address nominate_MeAddress, , ) = daoMock.getActiveLaw(1);

        // Give alice permission to select peers
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // Setup: Get bob and charlotte elected
        vm.prank(bob);
        daoMock.request(1, abi.encode(true), nonce, string(abi.encodePacked("Nominate ", bob)));
        nonce++;
        vm.prank(charlotte);
        daoMock.request(1, abi.encode(true), nonce, string(abi.encodePacked("Nominate ", charlotte)));
        nonce++;

        vm.startPrank(alice);
        daoMock.request(
            5,
            abi.encode(0, true),
            nonce,
            "Select bob"
        );
        nonce++;

        daoMock.request(
            5,
            abi.encode(1, true),
            nonce,
            "Select charlotte"
        );
        nonce++;
        vm.stopPrank();

        // Verify initial state
        vm.startPrank(address(daoMock));
        assertEq(PeerSelect(peer_SelectAddress).getData(LawUtilities.hashLaw(address(daoMock), 5)).electedSorted[0], bob, "Bob should be first");
        assertEq(PeerSelect(peer_SelectAddress).getData(LawUtilities.hashLaw(address(daoMock), 5)).electedSorted[1], charlotte, "Charlotte should be second");
        vm.stopPrank();

        // Revoke bob's role
        vm.prank(alice);
        daoMock.request(
            5,
            abi.encode(0, false),
            nonce,
            "Revoke bob"
        );
        nonce++;

        // Verify charlotte moved to first position
        vm.startPrank(address(daoMock));
        assertEq(PeerSelect(peer_SelectAddress).getData(LawUtilities.hashLaw(address(daoMock), 5)).electedSorted[0], charlotte, "Charlotte should be first after bob's removal");
        assertEq(daoMock.hasRoleSince(bob, 6), 0, "Bob should not have role anymore");
        vm.stopPrank();
    }

    function testUnauthorizedAccess() public {
         // Adjust index based on ConstitutionsMock setup
         // Adjust index based on ConstitutionsMock setup
        (address peer_SelectAddress, , ) = daoMock.getActiveLaw(5);
        (address nominate_MeAddress, , ) = daoMock.getActiveLaw(1);
    
        // Nominate bob
        vm.prank(bob);
        daoMock.request(1, abi.encode(true), nonce, string(abi.encodePacked("Nominate ", bob)));
        nonce++;

        // make sure that eve doesn't have ROLE_ONE
        assertEq(daoMock.hasRoleSince(helen, ROLE_ONE), 0, "Helen should not have ROLE_ONE");

        // Try to select with unauthorized account (eve doesn't have ROLE_ONE)
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(
            5,
            abi.encode(0, true),
            nonce,
            "Should fail - unauthorized"
        );
    }

    function testHandleRequestValidation() public {
         // Adjust index based on ConstitutionsMock setup
         // Adjust index based on ConstitutionsMock setup
        (address peer_SelectAddress, , ) = daoMock.getActiveLaw(5);
        (address nominate_MeAddress, , ) = daoMock.getActiveLaw(1);

        // Give alice permission to select peers
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);

        // Test with invalid index
        vm.prank(alice);
        vm.expectRevert(); // Should revert when accessing invalid nominee index
        daoMock.request(
            5,
            abi.encode(999, true),
            nonce,
            "Should fail - invalid index"
        );

        // Test with invalid calldata
        vm.prank(alice);
        vm.expectRevert(); // Should revert with invalid calldata
        daoMock.request(
            5,
            abi.encode(1), // Missing boolean parameter
            nonce,
            "Should fail - invalid calldata"
        );
    }
}

contract TaxSelectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the TaxSelect contract from the test setup
        uint16 taxSelect = 8;
        (address taxSelectAddress, , ) = daoMock.getActiveLaw(taxSelect);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(taxSelectAddress).getConditions(address(daoMock), taxSelect).allowedRole, 1, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(taxSelectAddress).getExecutions(address(daoMock), taxSelect).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testAssignRoleBasedOnTax() public {
        // prep
        uint16 taxSelect = 8;
        (address taxSelectAddress, , ) = daoMock.getActiveLaw(taxSelect);
        lawHash = LawUtilities.hashLaw(address(daoMock), taxSelect);
        
        // Get the configured threshold from the law
        TaxSelect.Data memory data = TaxSelect(taxSelectAddress).getData(lawHash);
        uint256 threshold = data.thresholdTaxPaid;
        
        // Setup: Make alice pay enough tax to meet threshold
        vm.startPrank(alice);
        Erc20TaxedMock(mockAddresses[3]).faucet(); // Get some tokens
        Erc20TaxedMock(mockAddresses[3]).transfer(bob, 1_000_000_000); // Transfer to generate tax
        vm.stopPrank();

        // Advance to next epoch
        vm.roll(block.number + 900);

        // Request role assignment
        lawCalldata = abi.encode(alice);
        vm.prank(alice);
        daoMock.request(taxSelect, lawCalldata, nonce, "Requesting role based on tax payment");

        // assert
        assertTrue(daoMock.hasRoleSince(alice, data.roleIdToSet) > 0, "Alice should have the role");
    }

    function testRevokeRoleBasedOnTax() public {
        // prep
        uint16 taxSelect = 8;
        (address taxSelectAddress, , ) = daoMock.getActiveLaw(taxSelect);
        lawHash = LawUtilities.hashLaw(address(daoMock), taxSelect);
        
        // Get the configured threshold from the law
        TaxSelect.Data memory data = TaxSelect(taxSelectAddress).getData(lawHash);
        uint256 threshold = data.thresholdTaxPaid;
        
        // Setup: Make alice pay enough tax to meet threshold
        vm.startPrank(alice);
        Erc20TaxedMock(mockAddresses[3]).faucet(); // Get some tokens
        Erc20TaxedMock(mockAddresses[3]).transfer(bob, 10000); // Transfer to generate tax
        vm.stopPrank();

        // Advance to next epoch
        vm.roll(block.number + 900);

        // Request role assignment
        lawCalldata = abi.encode(alice);
        vm.prank(alice);
        daoMock.request(taxSelect, lawCalldata, nonce, "Requesting role based on tax payment");
        nonce++;

        // Setup: Make alice pay less tax in next epoch
        vm.startPrank(alice);
        Erc20TaxedMock(mockAddresses[3]).faucet(); // Get some tokens
        Erc20TaxedMock(mockAddresses[3]).transfer(bob, 100); // Transfer to generate less tax
        vm.stopPrank();

        // Advance to next epoch
        vm.roll(block.number + 900);

        // Request role revocation
        lawCalldata = abi.encode(alice);
        vm.prank(alice);
        daoMock.request(taxSelect, lawCalldata, nonce, "Requesting role revocation based on tax payment");

        // assert
        assertEq(daoMock.hasRoleSince(alice, data.roleIdToSet), 0, "Alice should not have the role");
    }

    function testCannotAssignRoleInFirstEpoch() public {
        // prep
        uint16 taxSelect = 8;
        
        // Try to request role assignment in first epoch

        vm.roll(1); // set blocknumber to 1. 
        lawCalldata = abi.encode(alice);
        vm.prank(alice);
        vm.expectRevert("No finished epoch yet.");
        daoMock.request(taxSelect, lawCalldata, nonce, "Requesting role in first epoch");
    }

    function testMultipleAccountsTaxBasedRoles() public {
        // prep
        uint16 taxSelect = 8;
        (address taxSelectAddress, , ) = daoMock.getActiveLaw(taxSelect);
        lawHash = LawUtilities.hashLaw(address(daoMock), taxSelect);
        
        // Get the configured threshold from the law
        TaxSelect.Data memory data = TaxSelect(taxSelectAddress).getData(lawHash);
        uint256 threshold = data.thresholdTaxPaid;
        
        // Setup: Make alice and bob pay enough tax to meet threshold
        vm.startPrank(alice);
        Erc20TaxedMock(mockAddresses[3]).faucet();
        Erc20TaxedMock(mockAddresses[3]).transfer(bob, 1_000_000_000);
        vm.stopPrank();

        vm.startPrank(bob);
        Erc20TaxedMock(mockAddresses[3]).faucet();
        Erc20TaxedMock(mockAddresses[3]).transfer(alice, 1_000_000_000);
        vm.stopPrank();

        // Advance to next epoch
        vm.roll(block.number + 900);

        // Request role assignment for alice
        lawCalldata = abi.encode(alice);
        vm.prank(alice);
        daoMock.request(taxSelect, lawCalldata, nonce, "Alice requesting role");
        nonce++;

        // Request role assignment for bob
        lawCalldata = abi.encode(bob);
        vm.prank(bob);
        daoMock.request(taxSelect, lawCalldata, nonce, "Bob requesting role");

        // assert
        assertTrue(daoMock.hasRoleSince(alice, data.roleIdToSet) > 0, "Alice should have the role");
        assertTrue(daoMock.hasRoleSince(bob, data.roleIdToSet) > 0, "Bob should have the role");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 taxSelect = 8;
        (address taxSelectAddress, , ) = daoMock.getActiveLaw(taxSelect);
        
        // Setup: Make alice pay enough tax to meet threshold
        vm.startPrank(alice);
        Erc20TaxedMock(mockAddresses[3]).faucet();
        Erc20TaxedMock(mockAddresses[3]).transfer(bob, 100000);
        vm.stopPrank();

        // Advance to next epoch
        vm.roll(block.number + 900);
        assertTrue(daoMock.hasRoleSince(alice, ROLE_FOUR) == 0, "Alice should have NOT have role four.");

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(taxSelectAddress).handleRequest(alice, address(daoMock), taxSelect, abi.encode(alice), nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(calldatas[0], "", "Calldata should not be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testVerifyStoredData() public {
        // prep
        uint16 taxSelect = 8;
        (address taxSelectAddress, , ) = daoMock.getActiveLaw(taxSelect);
        lawHash = LawUtilities.hashLaw(address(daoMock), taxSelect);

        // assert
        TaxSelect.Data memory data = TaxSelect(taxSelectAddress).getData(lawHash);
        assertEq(data.erc20TaxedMock, mockAddresses[3], "ERC20 taxed mock address should be set correctly");
        assertEq(data.thresholdTaxPaid, 1000, "Threshold tax paid should be set correctly");
        assertEq(data.roleIdToSet, 4, "Role ID to set should be set correctly");
    }
}

contract DirectSelectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the DirectSelect contract from the test setup
        uint16 directSelect = 3;
        (address directSelectAddress, , ) = daoMock.getActiveLaw(directSelect);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(directSelectAddress).getConditions(address(daoMock), directSelect).allowedRole, ROLE_ONE, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(directSelectAddress).getExecutions(address(daoMock), directSelect).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testAssignRoleToMultipleAccounts() public {
        // prep
        uint16 directSelect = 3;
        address[] memory accounts = new address[](2);
        accounts[0] = bob;
        accounts[1] = charlotte;
        lawCalldata = abi.encode(accounts);
        description = "Assigning role to multiple accounts";

        // act
        vm.prank(alice);
        daoMock.request(directSelect, lawCalldata, nonce, description);

        // assert
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_FOUR), 0, "Bob should have ROLE_FOUR");
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_FOUR), 0, "Charlotte should have ROLE_FOUR");
    }

    function testSkipAccountsWithExistingRole() public {
        // prep
        uint16 directSelect = 3;
        address[] memory accounts = new address[](2);
        accounts[0] = bob;
        accounts[1] = charlotte;
        lawCalldata = abi.encode(accounts);
        description = "Assigning role to accounts";

        // First assign role to bob
        vm.prank(alice);
        daoMock.request(directSelect, lawCalldata, nonce, "First assignment");
        nonce++;

        // Try to assign again to both accounts
        vm.prank(alice);
        daoMock.request(directSelect, lawCalldata, nonce, "Second assignment");

        // assert
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_FOUR), 0, "Bob should still have ROLE_FOUR");
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_FOUR), 0, "Charlotte should still have ROLE_FOUR");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 directSelect = 3;
        (address directSelectAddress, , ) = daoMock.getActiveLaw(directSelect);
        address[] memory accounts = new address[](2);
        accounts[0] = bob;
        accounts[1] = charlotte;
        lawCalldata = abi.encode(accounts);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(directSelectAddress).handleRequest(alice, address(daoMock), directSelect, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 2, "Should have two targets");
        assertEq(values.length, 2, "Should have two values");
        assertEq(calldatas.length, 2, "Should have two calldatas");
        assertEq(targets[0], address(daoMock), "First target should be the DAO");
        assertEq(targets[1], address(daoMock), "Second target should be the DAO");
        assertEq(values[0], 0, "First value should be 0");
        assertEq(values[1], 0, "Second value should be 0");
        assertEq(
            calldatas[0],
            abi.encodeWithSelector(Powers.assignRole.selector, ROLE_FOUR, bob),
            "First calldata should be for role assignment to bob"
        );
        assertEq(
            calldatas[1],
            abi.encodeWithSelector(Powers.assignRole.selector, ROLE_FOUR, charlotte),
            "Second calldata should be for role assignment to charlotte"
        );
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 directSelect = 3;
        address[] memory accounts = new address[](1);
        accounts[0] = bob;
        lawCalldata = abi.encode(accounts);

        // Try to execute with unauthorized caller
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(directSelect, lawCalldata, nonce, "Unauthorized role assignment");
    }

    function testVerifyStoredRoleId() public {
        // prep
        uint16 directSelect = 3;
        (address directSelectAddress, , ) = daoMock.getActiveLaw(directSelect);
        lawHash = LawUtilities.hashLaw(address(daoMock), directSelect);

        // assert
        assertEq(DirectSelect(directSelectAddress).roleId(lawHash), ROLE_FOUR, "Role ID should be set correctly");
    }
} 


contract DirectDeselectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the DirectDeselect contract from the test setup
        uint16 directDeselect = 9;
        (address directDeselectAddress, , ) = daoMock.getActiveLaw(directDeselect);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(directDeselectAddress).getConditions(address(daoMock), directDeselect).allowedRole, ROLE_ONE, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(directDeselectAddress).getExecutions(address(daoMock), directDeselect).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testRevokeRoleFromMultipleAccounts() public {
        // prep
        uint16 directDeselect = 9;
        address[] memory accounts = new address[](2);
        accounts[0] = bob;
        accounts[1] = charlotte;
        lawCalldata = abi.encode(accounts);
        description = "Revoking role from multiple accounts";

        // First assign roles to both accounts
        vm.startPrank(address(daoMock));
        daoMock.assignRole(ROLE_FOUR, bob);
        daoMock.assignRole(ROLE_FOUR, charlotte);
        vm.stopPrank();

        // Verify initial state
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_FOUR), 0, "Bob should have ROLE_FOUR initially");
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_FOUR), 0, "Charlotte should have ROLE_FOUR initially");

        // act
        vm.prank(alice);
        daoMock.request(directDeselect, lawCalldata, nonce, description);

        // assert
        assertEq(daoMock.hasRoleSince(bob, ROLE_FOUR), 0, "Bob should not have ROLE_FOUR after revocation");
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_FOUR), 0, "Charlotte should not have ROLE_FOUR after revocation");
    }

    function testSkipAccountsWithoutRole() public {
        // prep
        uint16 directDeselect = 9;
        address[] memory accounts = new address[](2);
        accounts[0] = bob;
        accounts[1] = charlotte;
        lawCalldata = abi.encode(accounts);
        description = "Revoking role from accounts";

        // First assign role only to bob
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_FOUR, bob);

        // First revocation
        vm.prank(alice);
        daoMock.request(directDeselect, lawCalldata, nonce, "First revocation");
        nonce++;

        // Try to revoke again from both accounts
        vm.prank(alice);
        daoMock.request(directDeselect, lawCalldata, nonce, "Second revocation");

        // assert
        assertEq(daoMock.hasRoleSince(bob, ROLE_FOUR), 0, "Bob should not have ROLE_FOUR");
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_FOUR), 0, "Charlotte should not have ROLE_FOUR");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 directDeselect = 9;
        (address directDeselectAddress, , ) = daoMock.getActiveLaw(directDeselect);
        address[] memory accounts = new address[](2);
        accounts[0] = bob;
        accounts[1] = charlotte;
        lawCalldata = abi.encode(accounts);

        // First assign roles to both accounts
        vm.startPrank(address(daoMock));
        daoMock.assignRole(ROLE_FOUR, bob);
        daoMock.assignRole(ROLE_FOUR, charlotte);

        // act: call handleRequest directly to check its output
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(directDeselectAddress).handleRequest(alice, address(daoMock), directDeselect, lawCalldata, nonce);
        vm.stopPrank();

        // assert
        assertEq(targets.length, 2, "Should have two targets");
        assertEq(values.length, 2, "Should have two values");
        assertEq(calldatas.length, 2, "Should have two calldatas");
        assertEq(targets[0], address(daoMock), "First target should be the DAO");
        assertEq(targets[1], address(daoMock), "Second target should be the DAO");
        assertEq(values[0], 0, "First value should be 0");
        assertEq(values[1], 0, "Second value should be 0");
        assertEq(
            calldatas[0],
            abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_FOUR, bob),
            "First calldata should be for role revocation from bob"
        );
        assertEq(
            calldatas[1],
            abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_FOUR, charlotte),
            "Second calldata should be for role revocation from charlotte"
        );
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 directDeselect = 9;
        address[] memory accounts = new address[](1);
        accounts[0] = bob;
        lawCalldata = abi.encode(accounts);

        // Try to execute with unauthorized caller
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(directDeselect, lawCalldata, nonce, "Unauthorized role revocation");
    }

    function testVerifyStoredRoleId() public {
        // prep
        uint16 directDeselect = 9;
        (address directDeselectAddress, , ) = daoMock.getActiveLaw(directDeselect);
        lawHash = LawUtilities.hashLaw(address(daoMock), directDeselect);

        // assert
        assertEq(DirectDeselect(directDeselectAddress).roleId(lawHash), ROLE_FOUR, "Role ID should be set correctly");
    }
} 

// contract SubscriptionTest is TestSetupElectoral {
//     using ShortStrings for *;

//     function testConstructorInitialization() public {
//         // Get the Subscription contract from the test setup
//         uint16 subscription = 10;
//         (address subscriptionAddress, , ) = daoMock.getActiveLaw(subscription);
        
//         vm.startPrank(address(daoMock));
//         assertEq(Law(subscriptionAddress).getConditions(address(daoMock), subscription).allowedRole, ROLE_ONE, "Allowed role should be set to ROLE_ONE");
//         assertEq(Law(subscriptionAddress).getExecutions(address(daoMock), subscription).powers, address(daoMock), "Powers address should be set correctly");
//         vm.stopPrank();
//     }

//     function testAssignRoleBasedOnSubscription() public {
//         // prep
//         uint16 subscription = 10;
//         (address subscriptionAddress, , ) = daoMock.getActiveLaw(subscription);
//         lawHash = LawUtilities.hashLaw(address(daoMock), subscription);
        
//         // Get the configured subscription amount from the law
//         Subscription.Data memory data = Subscription(subscriptionAddress).getData(lawHash);
//         uint256 subscriptionAmount = data.subscriptionAmount;
        
//         // Setup: Make alice pay enough tax to meet subscription amount
//         vm.deal(alice, 1 * 10 ** 18); // = 1 ether 
//         vm.prank(alice);
//         address(daoMock).call{value: subscriptionAmount}(""); 

//         // Advance to next epoch
//         vm.roll(block.number + data.epochDuration);

//         // Request role assignment
//         lawCalldata = abi.encode(alice);
//         vm.prank(alice);
//         daoMock.request(subscription, lawCalldata, nonce, "Requesting role based on subscription payment");

//         // assert
//         assertTrue(daoMock.hasRoleSince(alice, data.roleIdToSet) > 0, "Alice should have the role");
//     }

//     function testRevokeRoleBasedOnInsufficientSubscription() public {
//         // prep
//         uint16 subscription = 10;
//         (address subscriptionAddress, , ) = daoMock.getActiveLaw(subscription);
//         lawHash = LawUtilities.hashLaw(address(daoMock), subscription);
        
//         // Get the configured subscription amount from the law
//         Subscription.Data memory data = Subscription(subscriptionAddress).getData(lawHash);
//         uint256 subscriptionAmount = data.subscriptionAmount;
        
//         // Setup: Make alice pay enough tax to meet subscription amount
//         vm.deal(alice, 1 * 10 ** 18); // = 1 ether 
//         vm.prank(alice);
//         address(daoMock).call{value: subscriptionAmount + 1}(""); 

//         // Advance to next epoch
//         vm.roll(block.number + data.epochDuration);

//         // Request role assignment
//         lawCalldata = abi.encode(alice);
//         vm.prank(alice);
//         daoMock.request(subscription, lawCalldata, nonce, "Requesting role based on subscription payment");
//         nonce++;

//         // Advance to next epoch
//         vm.roll(block.number + data.epochDuration);

//         // Setup: Make alice pay not enough tax to meet subscription amount
//         vm.prank(alice);
//         address(daoMock).call{value: subscriptionAmount -1}(""); 

//         // Request role revocation
//         lawCalldata = abi.encode(alice);
//         vm.prank(alice);
//         daoMock.request(subscription, lawCalldata, nonce, "Requesting role revocation based on insufficient subscription");

//         // assert
//         assertEq(daoMock.hasRoleSince(alice, data.roleIdToSet), 0, "Alice should not have the role");
//     }

//     function testCannotAssignRoleInFirstEpoch() public {
//         // prep
//         uint16 subscription = 10;
        
//         // Try to request role assignment in first epoch
//         vm.roll(1); // set blocknumber to 1
//         lawCalldata = abi.encode(alice);
//         vm.prank(alice);
//         vm.expectRevert("No finished epoch yet.");
//         daoMock.request(subscription, lawCalldata, nonce, "Requesting role in first epoch");
//     }

//     function testMultipleAccountsSubscriptionBasedRoles() public {
//         // prep
//         uint16 subscription = 10;
//         (address subscriptionAddress, , ) = daoMock.getActiveLaw(subscription);
//         lawHash = LawUtilities.hashLaw(address(daoMock), subscription);
        
//         // Get the configured subscription amount from the law
//         Subscription.Data memory data = Subscription(subscriptionAddress).getData(lawHash);
//         uint256 subscriptionAmount = data.subscriptionAmount;
        
//         // Setup: Make alice and bob pay enough tax to meet subscription amount
//         vm.deal(alice, 1 * 10 ** 18); // = 1 ether 
//         vm.prank(alice);
//         address(daoMock).call{value: subscriptionAmount + 1}(""); 

//         // Setup: Make bob pay enough tax to meet subscription amount
//         vm.deal(bob, 1 * 10 ** 18); // = 1 ether 
//         vm.prank(bob);
//         address(daoMock).call{value: subscriptionAmount + 1}(""); 

//         // Advance to next epoch
//         vm.roll(block.number + data.epochDuration);

//         // Request role assignment for alice
//         lawCalldata = abi.encode(alice);
//         vm.prank(alice);
//         daoMock.request(subscription, lawCalldata, nonce, "Alice requesting role");
//         nonce++;

//         // Request role assignment for bob
//         lawCalldata = abi.encode(bob);
//         vm.prank(bob);
//         daoMock.request(subscription, lawCalldata, nonce, "Bob requesting role");

//         // assert
//         assertTrue(daoMock.hasRoleSince(alice, data.roleIdToSet) > 0, "Alice should have the role");
//         assertTrue(daoMock.hasRoleSince(bob, data.roleIdToSet) > 0, "Bob should have the role");
//     }

//     function testHandleRequestOutput() public {
//         // prep
//         uint16 subscription = 10;
//         (address subscriptionAddress, , ) = daoMock.getActiveLaw(subscription);
//         lawHash = LawUtilities.hashLaw(address(daoMock), subscription);
        
//         // Get the configured subscription amount from the law
//         Subscription.Data memory data = Subscription(subscriptionAddress).getData(lawHash);
//         uint256 subscriptionAmount = data.subscriptionAmount;

//         // Setup: Make alice pay enough tax to meet subscription amount
//         vm.deal(alice, 1 * 10 ** 18); // = 1 ether 
//         vm.prank(alice);
//         address(daoMock).call{value: subscriptionAmount + 1}(""); 

//         // Advance to next epoch
//         vm.roll(block.number + data.epochDuration);

//         lawCalldata = abi.encode(alice);

//         // act: call handleRequest directly to check its output
//         vm.prank(address(daoMock));
//         (
//             actionId,
//             targets,
//             values,
//             calldatas,
//             stateChange
//         ) = Law(subscriptionAddress).handleRequest(alice, address(daoMock), subscription, lawCalldata, nonce);

//         // assert
//         assertEq(targets.length, 1, "Should have one target");
//         assertEq(values.length, 1, "Should have one value");
//         assertEq(calldatas.length, 1, "Should have one calldata");
//         assertEq(targets[0], address(daoMock), "Target should be the DAO");
//         assertEq(values[0], 0, "Value should be 0");
//         assertNotEq(calldatas[0], "", "Calldata should not be empty");
//         assertNotEq(actionId, 0, "Action ID should not be 0");
//     }

//     function testVerifyStoredData() public {
//         // prep
//         uint16 subscription = 10;
//         (address subscriptionAddress, , ) = daoMock.getActiveLaw(subscription);
//         lawHash = LawUtilities.hashLaw(address(daoMock), subscription);

//         // assert
//         Subscription.Data memory data = Subscription(subscriptionAddress).getData(lawHash);
//         assertEq(data.epochDuration, 120, "Epoch duration should be set correctly");
//         assertEq(data.subscriptionAmount, 1000, "Subscription amount should be set correctly");
//         assertEq(data.roleIdToSet, ROLE_FOUR, "Role ID to set should be set correctly");
//     }
// } 

contract StartElectionTest is TestSetupElectoral {
    using ShortStrings for *;

    function testConstructorInitializationStartElection() public {
        // Get the StartElection contract from the test setup
        uint16 startElection = 10;
        (address startElectionAddress, , ) = daoMock.getActiveLaw(startElection);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(startElectionAddress).getConditions(address(daoMock), startElection).allowedRole, 0, "Allowed role should be set to ADMIN_ROLE");
        assertEq(Law(startElectionAddress).getExecutions(address(daoMock), startElection).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testStartElection() public {
        // prep
        uint16 startElection = 10;
        (address startElectionAddress, , ) = daoMock.getActiveLaw(startElection);
        lawHash = LawUtilities.hashLaw(address(daoMock), startElection);
        
        // Get the configured election law and conditions
        StartElection.Data memory data = StartElection(startElectionAddress).getData(lawHash);
        
        // Setup election parameters
        uint48 startVote = uint48(block.number + 100);
        uint48 endVote = uint48(block.number + 200);
        string memory electionDescription = "Test Election";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        // Start the election
        vm.startPrank(address(daoMock));
        daoMock.assignRole(ADMIN_ROLE, address(daoMock)); 
        daoMock.request(startElection, lawCalldata, nonce, electionDescription);
        vm.stopPrank(); 

        // Get the election ID
        uint16 electionId = StartElection(startElectionAddress).getElectionId(lawHash, lawCalldata);
        
        // Verify the election was created
        assertTrue(electionId > 0, "Election ID should be greater than 0");
        
        // Verify the election law was adopted with correct parameters
        (address adoptedLaw, , ) = daoMock.getActiveLaw(electionId);
        assertEq(adoptedLaw, data.electionLaw, "Adopted law should match configured election law");
    }

    function testStartElectionWithInvalidTiming() public {
        // prep
        uint16 startElection = 10;
        
        // Setup election parameters with invalid timing (end before start)
        uint48 startVote = uint48(block.number + 200);
        uint48 endVote = uint48(block.number + 100);
        string memory electionDescription = "Invalid Election";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        // Try to start the election
        vm.prank(address(daoMock));
        vm.expectRevert(); // Should revert due to invalid timing
        daoMock.request(startElection, lawCalldata, nonce, electionDescription);
    }

    function testStartElectionWithEmptyDescription() public {
        // prep
        uint16 startElection = 11;
        
        // Setup election parameters with empty description
        uint48 startVote = uint48(block.number + 100);
        uint48 endVote = uint48(block.number + 200);
        string memory electionDescription = "";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        // Try to start the election
        vm.prank(address(daoMock));
        vm.expectRevert(); // Should revert due to empty description
        daoMock.request(startElection, lawCalldata, nonce, electionDescription);
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 startElection = 10;
        (address startElectionAddress, , ) = daoMock.getActiveLaw(startElection);
        
        // Setup election parameters
        uint48 startVote = uint48(block.number + 100);
        uint48 endVote = uint48(block.number + 200);
        string memory electionDescription = "Test Election";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(startElectionAddress).handleRequest(address(daoMock), address(daoMock), startElection, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(calldatas[0], "", "Calldata should not be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testVerifyStoredData() public {
        // prep
        uint16 startElection = 10;
        (address startElectionAddress, , ) = daoMock.getActiveLaw(startElection);
        lawHash = LawUtilities.hashLaw(address(daoMock), startElection);

        // assert
        StartElection.Data memory data = StartElection(startElectionAddress).getData(lawHash);
        assertNotEq(data.electionLaw, address(0), "Election law address should be set");
        assertNotEq(data.electionConditions.length, 0, "Election conditions should be set");
    }
} 

contract EndElectionTest is TestSetupElectoral {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the EndElection contract from the test setup
        uint16 EndElection = 11;
        (address EndElectionAddress, , ) = daoMock.getActiveLaw(EndElection);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(EndElectionAddress).getConditions(address(daoMock), EndElection).allowedRole, 0, "Allowed role should be set to ADMIN_ROLE");
        assertEq(Law(EndElectionAddress).getConditions(address(daoMock), EndElection).needCompleted, 10, "NeedCompleted should be set to StartElection law ID");
        assertEq(Law(EndElectionAddress).getConditions(address(daoMock), EndElection).readStateFrom, 1, "ReadStateFrom should be set to NominateMe law ID");
        assertEq(Law(EndElectionAddress).getExecutions(address(daoMock), EndElection).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testEndElectionCheck() public {
        // prep
        uint16 nominateMe = 1;
        uint16 startElection = 10;
        uint16 EndElection = 11;
        (address startElectionAddress, , ) = daoMock.getActiveLaw(startElection);
        (address EndElectionAddress, , ) = daoMock.getActiveLaw(EndElection);
        
        // First nominate some users
        vm.startPrank(bob);
        daoMock.request(nominateMe, abi.encode(true), nonce, "Bob nominating");
        nonce++;
        vm.stopPrank();

        vm.startPrank(charlotte);
        daoMock.request(nominateMe, abi.encode(true), nonce, "Charlotte nominating");
        nonce++;
        vm.stopPrank();

        // Start an election
        uint48 startVote = uint48(block.number + 100);
        uint48 endVote = uint48(block.number + 200);
        string memory electionDescription = "Test Election";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ADMIN_ROLE, address(daoMock));
        daoMock.request(startElection, lawCalldata, nonce, electionDescription);
        vm.stopPrank();

        // Get the election ID]
        vm.roll(block.number + 125); 
        bytes32 startElectionLawHash = LawUtilities.hashLaw(address(daoMock), startElection);
        uint16 electionId = StartElection(startElectionAddress).getElectionId(startElectionLawHash, lawCalldata);
        
        // Move forward in time to when election is not active anymore
        vm.roll(block.number + 125);

        // Now stop the election
        // Note: same calldata as startElection. 
        vm.startPrank(address(daoMock));
        daoMock.request(EndElection, lawCalldata, nonce, electionDescription);
        vm.stopPrank();

        // Verify the election law was revoked
        (, , active ) = daoMock.getActiveLaw(electionId); 
        assertTrue(!active, "Election law should be revoked");
    }

    function testEndElectionBeforeStart() public {
        // prep
        uint16 nominateMe = 1;
        uint16 startElection = 10;
        uint16 EndElection = 11;
        
        // First nominate some users
        vm.startPrank(bob);
        daoMock.request(nominateMe, abi.encode(true), nonce, "Bob nominating");
        nonce++;
        vm.stopPrank();

        // Start an election
        uint48 startVote = uint48(block.number + 100);
        uint48 endVote = uint48(block.number + 200);
        string memory electionDescription = "Test Election";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ADMIN_ROLE, address(daoMock));
        daoMock.request(startElection, lawCalldata, nonce, electionDescription);
        vm.stopPrank();

        // Try to stop election before it starts. Note: same calldat as start election
        vm.startPrank(address(daoMock));
        vm.expectRevert("Election not open.");
        daoMock.request(EndElection, lawCalldata, nonce, "Stopping election too early");
        vm.stopPrank();
    }

    function testEndElectionAfterEnd() public {
        // prep
        uint16 nominateMe = 1;
        uint16 startElection = 10;
        uint16 EndElection = 11;
        
        // First nominate some users
        vm.startPrank(bob);
        daoMock.request(nominateMe, abi.encode(true), nonce, "Bob nominating");
        nonce++;
        vm.stopPrank();

        // Start an election
        uint48 startVote = uint48(block.number + 100);
        uint48 endVote = uint48(block.number + 200);
        string memory electionDescription = "Test Election";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ADMIN_ROLE, address(daoMock));
        daoMock.request(startElection, lawCalldata, nonce, electionDescription);
        vm.stopPrank();

        // Move forward to while the election is still active
        vm.roll(block.number + 150);

        // Try to stop election after it ends. Note same calldata as start election! 
        vm.startPrank(address(daoMock));
        vm.expectRevert("Election has not ended.");
        daoMock.request(EndElection, lawCalldata, nonce, "Stopping election too late");
        vm.stopPrank();
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 nominateMe = 1;
        uint16 startElection = 10;
        uint16 EndElection = 11;
        (address startElectionAddress, , ) = daoMock.getActiveLaw(startElection);
        (address EndElectionAddress, , ) = daoMock.getActiveLaw(EndElection);
        
        // First nominate some users
        vm.startPrank(bob);
        daoMock.request(nominateMe, abi.encode(true), nonce, "Bob nominating");
        nonce++;
        vm.stopPrank();

        // Start an election
        uint48 startVote = uint48(block.number + 100);
        uint48 endVote = uint48(block.number + 200);
        string memory electionDescription = "Test Election";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ADMIN_ROLE, address(daoMock));
        daoMock.request(startElection, lawCalldata, nonce, electionDescription);
        vm.stopPrank();

        // Move forward in time to when election is not active anymore. 
        vm.roll(block.number + 250);

        // act: call handleRequest directly to check its output
        // note: same calldata as at start Election. 
        vm.startPrank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(EndElectionAddress).handleRequest(address(daoMock), address(daoMock), EndElection, lawCalldata, nonce);
        vm.stopPrank();

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(calldatas[0], "", "Calldata should not be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testEndElectionWithoutNominees() public {
        // prep
        uint16 startElection = 10;
        uint16 EndElection = 11;
        (address EndElectionAddress, , ) = daoMock.getActiveLaw(EndElection);
        
        // Start an election without any nominees
        uint48 startVote = uint48(block.number + 100);
        uint48 endVote = uint48(block.number + 200);
        string memory electionDescription = "Test Election";
        lawCalldata = abi.encode(startVote, endVote, electionDescription);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ADMIN_ROLE, address(daoMock));
        daoMock.request(startElection, lawCalldata, nonce, electionDescription);
        vm.stopPrank();

        // Move forward in time to when election is not active anymore
        vm.roll(block.number + 250);

        // Try to stop election
        vm.startPrank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(EndElectionAddress).handleRequest(address(daoMock), address(daoMock), EndElection, lawCalldata, nonce);
        vm.stopPrank();

        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

contract NStrikesYourOutTest is TestSetupElectoral {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the NStrikesYourOut contract from the test setup
        uint16 nStrikesYourOut = 14;
        (address nStrikesYourOutAddress, , ) = daoMock.getActiveLaw(nStrikesYourOut);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(nStrikesYourOutAddress).getConditions(address(daoMock), nStrikesYourOut).allowedRole, ROLE_ONE, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(nStrikesYourOutAddress).getConditions(address(daoMock), nStrikesYourOut).readStateFrom, 13, "ReadStateFrom should be set to FlagActions law");
        assertEq(Law(nStrikesYourOutAddress).getExecutions(address(daoMock), nStrikesYourOut).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testRevokeRoleAfterEnoughStrikes() public {
        // prep
        uint16 nStrikesYourOut = 14;
        uint16 flagActions = 13;
        uint16 statementOfIntent = 15; // New StatementOfIntent law
        (address nStrikesYourOutAddress, , ) = daoMock.getActiveLaw(nStrikesYourOut);
        (address flagActionsAddress, , ) = daoMock.getActiveLaw(flagActions);
        
        // Assign multiple roles to bob first
        vm.startPrank(address(daoMock));
        daoMock.assignRole(4, bob); // roleId 4 as configured in constitution
        daoMock.assignRole(5, bob); // roleId 5 as configured in constitution
        vm.stopPrank();

        // Create actual actions by bob using StatementOfIntent law
        // These will be the actions that bob "executed" and then got flagged
        uint256[] memory actionIdsToFlag = new uint256[](3);
        
        // Bob creates 3 actions using StatementOfIntent law (these are the "bad" actions)
        vm.startPrank(bob);
        for (i = 0; i < 3; i++) {
            // Create empty proposal (StatementOfIntent doesn't execute anything)
            targets = new address[](0);
            values = new uint256[](0);
            calldatas = new bytes[](0);
            bytes memory proposalCalldata = abi.encode(targets, values, calldatas);
            
            daoMock.request(statementOfIntent, proposalCalldata, nonce + i, "Bob's action that gets flagged");
            // Store the action ID that was just created
            actionIdsToFlag[i] = LawUtilities.hashActionId(statementOfIntent, proposalCalldata, nonce + i);
        }
        vm.stopPrank();
        
        // Now alice flags these specific actions as problematic
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice); // roleId 1 as configured in constitution

        vm.startPrank(alice);
        for (i = 0; i < 3; i++) {
            bytes memory flagCalldata = abi.encode(actionIdsToFlag[i], true); // flag the specific actionIds
            daoMock.request(flagActions, flagCalldata, nonce + i + 3, "Flag bob's problematic actions");
        }
        vm.stopPrank();
        
        // Now try to revoke bob's roles with enough strikes (3 strikes, need 3)
        // roleId parameter is now required in the calldata
        lawCalldata = abi.encode(bob, actionIdsToFlag);
        
        vm.prank(alice);
        daoMock.request(nStrikesYourOut, lawCalldata, nonce, "Revoke role after strikes");
        
        // assert
        assertFalse(daoMock.hasRoleSince(bob, 4) != 0, "Role should be revoked");
    }

    function testCannotRevokeWithInsufficientStrikes() public {
        // prep
        uint16 nStrikesYourOut = 14;
        uint16 flagActions = 13;
        uint16 statementOfIntent = 15;
        
        // Assign role to bob first
        vm.prank(address(daoMock));
        daoMock.assignRole(4, bob);
        
        // Create actual actions by bob using StatementOfIntent law
        uint256[] memory actionIdsToFlag = new uint256[](2);
        
        // Bob creates 2 actions using StatementOfIntent law (only 2 strikes, need 3)
        vm.startPrank(bob);
        for (i = 0; i < 2; i++) {
            targets = new address[](0);
            values = new uint256[](0);
            calldatas = new bytes[](0);
            bytes memory proposalCalldata = abi.encode(targets, values, calldatas);
            
            daoMock.request(statementOfIntent, proposalCalldata, nonce + i, "Bob's action that gets flagged");
            actionIdsToFlag[i] = LawUtilities.hashActionId(statementOfIntent, proposalCalldata, nonce + i);
        }
        vm.stopPrank();
        
        // Now alice flags these specific actions
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);
        
        vm.startPrank(alice);
        for (i = 0; i < 2; i++) {
            bytes memory flagCalldata = abi.encode(actionIdsToFlag[i], true);
            daoMock.request(flagActions, flagCalldata, nonce + i + 10, "Flag bob's action");
        }
        vm.stopPrank();
        
        // Now try to revoke bob's role with only 2 strikes (need 3)
        // roleId parameter is now required in the calldata
        lawCalldata = abi.encode(bob, actionIdsToFlag);
        
        vm.prank(alice);
        vm.expectRevert("Not enough strikes to revoke role.");
        daoMock.request(nStrikesYourOut, lawCalldata, nonce + 20, "Revoke with insufficient strikes");
    }

    function testCannotRevokeAccountWithoutRole() public {
        // prep
        uint16 nStrikesYourOut = 14;
        uint16 flagActions = 13;
        uint16 statementOfIntent = 15;
        
        // Create actual actions by bob using StatementOfIntent law
        uint256[] memory actionIdsToFlag = new uint256[](3);
        
        // Bob creates 3 actions using StatementOfIntent law
        vm.startPrank(bob);
        for (i = 0; i < 3; i++) {
            targets = new address[](0);
            values = new uint256[](0);
            calldatas = new bytes[](0);
            bytes memory proposalCalldata = abi.encode(targets, values, calldatas);
            
            daoMock.request(statementOfIntent, proposalCalldata, nonce + i, "Bob's action that gets flagged");
            actionIdsToFlag[i] = LawUtilities.hashActionId(statementOfIntent, proposalCalldata, nonce + i);
        }
        vm.stopPrank();
        
        // Now alice flags these specific actions
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);
        
        // vm.startPrank(alice);
        // for (i = 0; i < 3; i++) {
        //     bytes memory flagCalldata = abi.encode(helen, actionIdsToFlag[i]);
        //     daoMock.request(flagActions, flagCalldata, nonce + i + 10, "Flag bob's action");
        // }
        // vm.stopPrank();
        
        // Try to revoke helen's role (helen doesn't have role 4)
        // roleId parameter is now required in the calldata
        lawCalldata = abi.encode(helen, actionIdsToFlag);
        
        vm.prank(alice);
        vm.expectRevert("Action is not from account being revoked.");
        daoMock.request(nStrikesYourOut, lawCalldata, nonce + 20, "Revoke account without role");
    }

    function testHandleRequestOutputNStrikesYourOut() public {
        // prep
        uint16 nStrikesYourOut = 14;
        (address nStrikesYourOutAddress, , ) = daoMock.getActiveLaw(nStrikesYourOut);
        uint16 flagActions = 13;
        uint16 statementOfIntent = 15;
        
        // Create actual actions by bob using StatementOfIntent law
        uint256[] memory actionIdsToFlag = new uint256[](3);
        
        // Bob creates 3 actions using StatementOfIntent law
        vm.startPrank(bob);
        for (i = 0; i < 3; i++) {
            targets = new address[](0);
            values = new uint256[](0);
            calldatas = new bytes[](0);
            bytes memory proposalCalldata = abi.encode(targets, values, calldatas);
            
            daoMock.request(statementOfIntent, proposalCalldata, nonce + i, "Bob's action that gets flagged");
            actionIdsToFlag[i] = LawUtilities.hashActionId(statementOfIntent, proposalCalldata, nonce + i);
        }
        vm.stopPrank();
        
        // Now alice flags these specific actions
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);
        
        vm.startPrank(alice);
        for (i = 0; i < 3; i++) {
            bytes memory flagCalldata = abi.encode(actionIdsToFlag[i], true);
            daoMock.request(flagActions, flagCalldata, nonce + i + 10, "Flag bob's action");
        }
        vm.stopPrank();
        
        // Assign role to bob
        vm.prank(address(daoMock));
        daoMock.assignRole(4, bob);
        
        // roleId parameter is now required in the calldata
        lawCalldata = abi.encode(bob, actionIdsToFlag);
        
        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(nStrikesYourOutAddress).handleRequest(alice, address(daoMock), nStrikesYourOut, lawCalldata, nonce + 20);
        
        // assert
        assertEq(targets.length, 4, "Should have four targets");
        assertEq(values.length, 4, "Should have four value");
        assertEq(calldatas.length, 4, "Should have four calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(calldatas[0], "", "Calldata should not be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testStoredData() public {
        // prep
        uint16 nStrikesYourOut = 14;
        (address nStrikesYourOutAddress, , ) = daoMock.getActiveLaw(nStrikesYourOut);
        
        lawHash = LawUtilities.hashLaw(address(daoMock), nStrikesYourOut);
        NStrikesYourOut.Data memory data = NStrikesYourOut(nStrikesYourOutAddress).getData(lawHash);
        
        // assert - Data structure changed to roleIds array and numberStrikes
        assertEq(data.roleIds.length, 4, "Should have four role ID configured");
        assertEq(data.roleIds[0], 3, "First role ID should be set to 3");
        assertEq(data.numberStrikes, 3, "Number of strikes should be set to 3");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 nStrikesYourOut = 14;
        uint16 flagActions = 13;
        uint16 statementOfIntent = 15;
        
        // Create actual actions by bob using StatementOfIntent law
        uint256[] memory actionIdsToFlag = new uint256[](3);
        
        // Bob creates 3 actions using StatementOfIntent law
        vm.startPrank(bob);
        for (i = 0; i < 3; i++) {
            targets = new address[](0);
            values = new uint256[](0);
            calldatas = new bytes[](0);
            bytes memory proposalCalldata = abi.encode(targets, values, calldatas);
            
            daoMock.request(statementOfIntent, proposalCalldata, nonce + i, "Bob's action that gets flagged");
            actionIdsToFlag[i] = LawUtilities.hashActionId(statementOfIntent, proposalCalldata, nonce + i);
        }
        vm.stopPrank();
        
        // Now alice flags these specific actions
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);
        
        vm.startPrank(alice);
        for (i = 0; i < 3; i++) {
            bytes memory flagCalldata = abi.encode(actionIdsToFlag[i], true);
            daoMock.request(flagActions, flagCalldata, nonce + i + 10, "Flag bob's action");
        }
        vm.stopPrank();
        
        // Assign role to bob
        vm.prank(address(daoMock));
        daoMock.assignRole(4, bob);
        
        // roleId parameter is now required in the calldata
        lawCalldata = abi.encode(bob, actionIdsToFlag);
        
        // Try to revoke role without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(nStrikesYourOut, lawCalldata, nonce + 20, "Unauthorized role revocation");
    }

    function testRevokeMultipleRolesAfterEnoughStrikes() public {
        // prep
        uint16 nStrikesYourOut = 14;
        uint16 flagActions = 13;
        uint16 statementOfIntent = 15;
        (address nStrikesYourOutAddress, , ) = daoMock.getActiveLaw(nStrikesYourOut);
        
        // Assign multiple roles to bob first
        vm.startPrank(address(daoMock));
        daoMock.assignRole(4, bob); // roleId 4 as configured in constitution
        daoMock.assignRole(5, bob); // roleId 5 as configured in constitution
        daoMock.assignRole(6, bob); // roleId 6 as configured in constitution
        vm.stopPrank(); 

        // Create actual actions by bob using StatementOfIntent law
        uint256[] memory actionIdsToFlag = new uint256[](3);
        
        // Bob creates 3 actions using StatementOfIntent law (these are the "bad" actions)
        vm.startPrank(bob);
        for (i = 0; i < 3; i++) {
            targets = new address[](0);
            values = new uint256[](0);
            calldatas = new bytes[](0);
            bytes memory proposalCalldata = abi.encode(targets, values, calldatas);
            
            daoMock.request(statementOfIntent, proposalCalldata, nonce + i, "Bob's action that gets flagged");
            actionIdsToFlag[i] = LawUtilities.hashActionId(statementOfIntent, proposalCalldata, nonce + i);
        }
        vm.stopPrank();
        
        // Now alice flags these specific actions as problematic
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice); // roleId 1 as configured in constitution

        vm.startPrank(alice);
        for (i = 0; i < 3; i++) {
            bytes memory flagCalldata = abi.encode(actionIdsToFlag[i], true); // flag the specific actionIds
            daoMock.request(flagActions, flagCalldata, nonce + i + 3, "Flag bob's problematic actions");
        }
        vm.stopPrank();
        
        // Now try to revoke bob's roles with enough strikes (3 strikes, need 3)
        // roleId parameter is now required in the calldata
        lawCalldata = abi.encode(bob, actionIdsToFlag);
        
        vm.prank(alice);
        daoMock.request(nStrikesYourOut, lawCalldata, nonce, "Revoke role after strikes");
        
        // assert - should revoke all roles that bob has from the configured roleIds array
        assertFalse(daoMock.hasRoleSince(bob, 4) != 0, "Role 4 should be revoked");
        assertFalse(daoMock.hasRoleSince(bob, 5) != 0, "Role 5 should be revoked");
        assertFalse(daoMock.hasRoleSince(bob, 6) != 0, "Role 6 should be revoked");
    }

    function testCallerMismatchRevert() public {
        // prep
        uint16 nStrikesYourOut = 14;
        uint16 flagActions = 13;
        uint16 statementOfIntent = 15;
        
        // Assign role to bob first
        vm.prank(address(daoMock));
        daoMock.assignRole(4, bob);
        
        // Create actual actions by charlotte using StatementOfIntent law
        uint256[] memory actionIdsToFlag = new uint256[](3);
        
        // Charlotte creates 3 actions using StatementOfIntent law
        vm.startPrank(charlotte);
        for (i = 0; i < 3; i++) {
            targets = new address[](0);
            values = new uint256[](0);
            calldatas = new bytes[](0);
            bytes memory proposalCalldata = abi.encode(targets, values, calldatas);
            
            daoMock.request(statementOfIntent, proposalCalldata, nonce + i, "Charlotte's action that gets flagged");
            actionIdsToFlag[i] = LawUtilities.hashActionId(statementOfIntent, proposalCalldata, nonce + i);
        }
        vm.stopPrank();
        
        // Now alice flags these specific actions
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);
        
        vm.startPrank(alice);
        for (i = 0; i < 3; i++) {
            bytes memory flagCalldata = abi.encode(actionIdsToFlag[i], true);
            daoMock.request(flagActions, flagCalldata, nonce + i + 10, "Flag charlotte's action");
        }
        vm.stopPrank();
        
        // Try to revoke bob's role using charlotte's flagged actions (caller mismatch)
        lawCalldata = abi.encode(bob, actionIdsToFlag);
        
        vm.prank(alice);
        vm.expectRevert("Action is not from account being revoked.");
        daoMock.request(nStrikesYourOut, lawCalldata, nonce + 20, "Revoke with caller mismatch");
    }
} 



