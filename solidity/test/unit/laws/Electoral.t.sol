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
// import { VoteOnNominees } from "../../../src/laws/state/VoteOnNominees.sol";
import { Erc20VotesMock } from "../../mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../../mocks/Erc20TaxedMock.sol";

import { NominateMe } from "../../../src/laws/state/NominateMe.sol";
import { RenounceRole } from "../../../src/laws/electoral/RenounceRole.sol";
import { PeerSelect } from "../../../src/laws/electoral/PeerSelect.sol";
import { DirectSelect } from "../../../src/laws/electoral/DirectSelect.sol";


contract DirectSelectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testAssignSucceeds() public {
        // prep: check if charlotte does NOT have role 3
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should not have ROLE_THREE initially");
        uint16 directSelect = 3;
        lawCalldata = abi.encode(true, charlotte); // assign

        vm.prank(alice); // has role 1 
        daoMock.request(
            directSelect,
            lawCalldata,
            nonce,
            "giving role three to charlotte!"
        );

        // assert
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should have ROLE_THREE after executing the law");
    }

    function testAssignReverts() public {
        // prep: check if alice does have role 3
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should have ROLE_THREE initially");
        uint16 directSelect = 3;
        lawCalldata = abi.encode(true, alice); // assign

        // act & assert
        vm.prank(alice);
        vm.expectRevert("Account already has role.");
        daoMock.request(
            directSelect,
            lawCalldata,
            nonce,
            "giving role three to alice!"
        );
    }

    function testRevokeSucceeds() public {
        // prep: check if alice does have role four
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should have ROLE_THREE initially");
        uint16 directSelect = 3;
        lawCalldata = abi.encode(false, alice); // assign
        bytes memory expectedCalldata = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_THREE, alice);

        vm.prank(alice);
        daoMock.request(
            directSelect,
            lawCalldata,
            nonce,
            "selecting role for account!"
        );

        // assert
        assertEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0, "Alice should not have ROLE_THREE after executing the law");
    }

    function testRevokeReverts() public {
        // prep: check if charlotte does NOT have role 3
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should not have ROLE_THREE initially");
        uint16 directSelect = 3;
        lawCalldata = abi.encode(false, charlotte); // assign

        // act & assert
        vm.prank(charlotte);
        vm.expectRevert("Account does not have role.");
        daoMock.request(
            directSelect,
            lawCalldata,
            nonce,
            "revoking role three from charlotte!"
        );
    }
}

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
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should have ROLE_THREE after holding enough tokens");
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
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should not have ROLE_THREE after falling below token threshold");
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
        assertNotEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0, "Charlotte should still have ROLE_THREE while holding enough tokens");
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
