// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Powers } from "../../../src/Powers.sol";
import { TestSetupState } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";
import { LawUtilities } from "../../../src/LawUtilities.sol";
import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";
import { Erc20VotesMock } from "../../mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../../mocks/Erc20TaxedMock.sol";
import { Grant } from "../../../src/laws/state/Grant.sol";
import { VoteOnAccounts } from "../../../src/laws/state/VoteOnAccounts.sol";
import { AddressesMapping } from "../../../src/laws/state/AddressesMapping.sol";
import { StringsArray } from "../../../src/laws/state/StringsArray.sol";
import { NominateMe } from "../../../src/laws/state/NominateMe.sol";
import { TokensArray } from "../../../src/laws/state/TokensArray.sol";

contract AddressesMappingTest is TestSetupState {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the AddressesMapping contract from the test setup
        uint16 addressesMapping = 6;
        (address addressesMappingAddress, , ) = daoMock.getActiveLaw(addressesMapping);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(addressesMappingAddress).getConditions(address(daoMock),addressesMapping).allowedRole, 1, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(addressesMappingAddress).getExecutions(address(daoMock), addressesMapping).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testAddAddress() public {
        // prep
        uint16 addressesMapping = 6;
        lawCalldata = abi.encode(
            alice,
            true
        );
        description = "Adding an address to the mapping";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // act
        vm.prank(bob);
        daoMock.request(addressesMapping, lawCalldata, nonce, description);

        // assert
        (address addressesMappingAddress, , ) = daoMock.getActiveLaw(addressesMapping);
        lawHash = LawUtilities.hashLaw(address(daoMock), addressesMapping);
        assertTrue(AddressesMapping(addressesMappingAddress).addresses(lawHash, alice), "Address should be mapped correctly");
    }

    function testUpdateAddress() public {
        // prep
        uint16 addressesMapping = 6;
        
        // First add an address
        lawCalldata = abi.encode(
            alice,
            true
        );

        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        vm.prank(bob);
        daoMock.request(addressesMapping, lawCalldata, nonce, "Adding initial address");
        nonce++;

        // Then update it
        lawCalldata = abi.encode(
            charlotte, 
            true 
        );

        vm.prank(bob);
        daoMock.request(addressesMapping, lawCalldata, nonce, "Updating address");

        // assert
        (address addressesMappingAddress, , ) = daoMock.getActiveLaw(addressesMapping); 
        lawHash = LawUtilities.hashLaw(address(daoMock), addressesMapping);
        assertTrue(AddressesMapping(addressesMappingAddress).addresses(lawHash, charlotte), "Address should be updated correctly");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 addressesMapping = 6;
        lawCalldata = abi.encode(
            alice,
            true
        );

        // Try to add address without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(addressesMapping, lawCalldata, nonce, "Unauthorized address addition");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 addressesMapping = 6;
        (address addressesMappingAddress, , ) = daoMock.getActiveLaw(addressesMapping);
        
        lawCalldata = abi.encode(
            alice,
            true
        );

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(addressesMappingAddress).handleRequest(bob, address(daoMock), addressesMapping, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 0, "Should not have a target");
        assertEq(values.length, 0, "Should not have a value");
        assertEq(calldatas.length, 0, "Should not have a calldata");
        assertEq(stateChange, abi.encode(alice, true), "State change should be alice, true");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

contract GrantTest is TestSetupState {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the Grant contract from the test setup
        uint16 grant = 1;
        (address grantAddress, , ) = daoMock.getActiveLaw(grant);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(grantAddress).getConditions(address(daoMock), grant).allowedRole, 1, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(grantAddress).getExecutions(address(daoMock), grant).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testRequestGrant() public {
        // prep
        uint16 grant = 1;
        (address grantAddress, , ) = daoMock.getActiveLaw(grant);
        lawCalldata = abi.encode(
            alice,
            grantAddress,
            1000
        );
        description = "Requesting grant money";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        daoMock.request(grant, lawCalldata, nonce, description);

        // assert
        lawHash = LawUtilities.hashLaw(address(daoMock), grant);
        Grant.Data memory data = Grant(grantAddress).getData(lawHash);
        assertEq(data.budget, 1 * 10 ** 18, "Grant amount should match");
        assertEq(data.tokenAddress, mockAddresses[3], "Grant token address should match");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 grant = 1;
        lawCalldata = abi.encode(
            1000,
            1 * 10 ** 18,
            mockAddresses[3]
        );

        // Try to create grant without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(grant, lawCalldata, nonce, "Unauthorized grant creation");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 grant = 1;
        (address grantAddress, , ) = daoMock.getActiveLaw(grant);
        
        lawCalldata = abi.encode(
            alice,
            grantAddress,
            5 * 10 ** 17 // .5 tokens
        );

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(grantAddress).handleRequest(alice, address(daoMock), grant, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], mockAddresses[3], "Target should be the token address");
        assertEq(values[0], 0, "Value should be zero");
        assertEq(stateChange, abi.encode(5 * 10 ** 17), "State change should be .5 tokens");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

contract VoteOnAccountsTest is TestSetupState {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the VoteOnAccounts contract from the test setup
        uint16 voteOnAccounts = 5;
        (address VoteOnAccountsAddress, , ) = daoMock.getActiveLaw(voteOnAccounts);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(VoteOnAccountsAddress).getConditions(address(daoMock), voteOnAccounts).allowedRole, 1, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(VoteOnAccountsAddress).getConditions(address(daoMock), voteOnAccounts).readStateFrom, 2, "Read state from should be set to 2");
        assertEq(Law(VoteOnAccountsAddress).getExecutions(address(daoMock), voteOnAccounts).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testVoteOnNominee() public {
        // prep
        uint16 voteOnAccounts = 5;
        uint16 nominateMe = 2;

        // nominate alice
        vm.prank(alice);
        daoMock.request(nominateMe, abi.encode(true), nonce, "Nominating alice");
        nonce++;

        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // act
        vm.prank(bob);
        vm.roll(5001); // set block number to after startvote
        daoMock.request(voteOnAccounts, abi.encode(alice), nonce, "Voting on a nominee");

        // assert
        (address VoteOnAccountsAddress, , ) = daoMock.getActiveLaw(voteOnAccounts);
        lawHash = LawUtilities.hashLaw(address(daoMock), voteOnAccounts);
        VoteOnAccounts.Data memory data = VoteOnAccounts(VoteOnAccountsAddress).getData(lawHash);
        uint256 votes = VoteOnAccounts(VoteOnAccountsAddress).getVotes(lawHash, alice);
        assertEq(votes, 1, "Nominee should have one vote");
    }

    function testMultipleVotes() public {
        // prep
        uint16 voteOnAccounts = 5;
        uint16 nominateMe = 2;

        // nominate alice
        vm.prank(alice);
        daoMock.request(nominateMe, abi.encode(true), nonce, "Nominating alice");
        nonce++;

        vm.roll(block.number + 10);
        // check if alice is nominated
        (address nominateMeAddress, , ) = daoMock.getActiveLaw(nominateMe);
        lawHash = LawUtilities.hashLaw(address(daoMock), nominateMe);
        assertTrue(NominateMe(nominateMeAddress).isNominee(lawHash, alice), "Alice should be nominated");


        vm.startPrank(address(daoMock));
        daoMock.assignRole(1, bob);
        daoMock.assignRole(1, charlotte);
        vm.stopPrank();

        // First vote
        vm.roll(5001); // set block number to after startvote
        vm.prank(bob);
        daoMock.request(voteOnAccounts, abi.encode(alice), nonce, "First vote");
        nonce++;

        // Second vote
        vm.roll(5002); // set block number to after startvote
        vm.prank(charlotte);
        daoMock.request(voteOnAccounts, abi.encode(alice), nonce, "Second vote");

        // assert
        (address VoteOnAccountsAddress, , ) = daoMock.getActiveLaw(voteOnAccounts);
        uint256 votes = VoteOnAccounts(VoteOnAccountsAddress).getVotes(LawUtilities.hashLaw(address(daoMock), voteOnAccounts), alice);
        assertEq(votes, 2, "Nominee should have two votes");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 voteOnAccounts = 5;
        lawCalldata = abi.encode(
            alice,
            true
        );

        // Try to vote without proper role
        vm.roll(5001); // set block number to after startvote
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(voteOnAccounts, lawCalldata, nonce, "Unauthorized vote");
    }

    function testHandleRequestOutputVoteOnAccounts() public {
        // prep
        uint16 voteOnAccounts = 5;
        (address VoteOnAccountsAddress, , ) = daoMock.getActiveLaw(voteOnAccounts);
        
        lawCalldata = abi.encode(alice);

        // act: call handleRequest directly to check its output
        vm.roll(5001); // set block number to after startvote
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(VoteOnAccountsAddress).handleRequest(bob, address(daoMock), voteOnAccounts, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 0, "Should have no target");
        assertEq(values.length, 0, "Should have no value");
        assertEq(calldatas.length, 0, "Should have no calldata");
        assertNotEq(stateChange, abi.encode(), "State change should not be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

contract NominateMeTest is TestSetupState {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the NominateMe contract from the test setup
        uint16 nominateMe = 2;
        (address nominateMeAddress, , ) = daoMock.getActiveLaw(nominateMe);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(nominateMeAddress).getConditions(address(daoMock), nominateMe).allowedRole, type(uint256).max, "Allowed role should be set to public access");
        assertEq(Law(nominateMeAddress).getExecutions(address(daoMock), nominateMe).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testNominateSelf() public {
        // prep
        uint16 nominateMe = 2;
        lawCalldata = abi.encode(true);
        description = "Nominating self";

        // act
        vm.prank(alice);
        daoMock.request(nominateMe, lawCalldata, nonce, description);

        // assert
        (address nominateMeAddress, , ) = daoMock.getActiveLaw(nominateMe);
        lawHash = LawUtilities.hashLaw(address(daoMock), nominateMe);
        assertTrue(NominateMe(nominateMeAddress).isNominee(lawHash, alice), "Alice should be nominated");
        assertEq(NominateMe(nominateMeAddress).getNomineesCount(lawHash), 1, "Should have one nominee");
        nominees = NominateMe(nominateMeAddress).getNominees(lawHash);
        assertEq(nominees[0], alice, "Alice should be in nominees array");
    }

    function testRevokeNomination() public {
        // prep
        uint16 nominateMe = 2;
        
        // First nominate self
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        daoMock.request(nominateMe, lawCalldata, nonce, "Nominating self");
        nonce++;

        // Then revoke nomination
        lawCalldata = abi.encode(false);
        vm.prank(alice);
        daoMock.request(nominateMe, lawCalldata, nonce, "Revoking nomination");

        // assert
        (address nominateMeAddress, , ) = daoMock.getActiveLaw(nominateMe);
        lawHash = LawUtilities.hashLaw(address(daoMock), nominateMe);
        assertFalse(NominateMe(nominateMeAddress).isNominee(lawHash, alice), "Alice should not be nominated");
        assertEq(NominateMe(nominateMeAddress).getNomineesCount(lawHash), 0, "Should have no nominees");
    }

    function testMultipleNominations() public {
        // prep
        uint16 nominateMe = 2;
        
        // Nominate alice
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        daoMock.request(nominateMe, lawCalldata, nonce, "Alice nominating self");
        nonce++;

        // Nominate bob
        vm.prank(bob);
        daoMock.request(nominateMe, lawCalldata, nonce, "Bob nominating self");

        // assert
        (address nominateMeAddress, , ) = daoMock.getActiveLaw(nominateMe);
        lawHash = LawUtilities.hashLaw(address(daoMock), nominateMe);
        assertTrue(NominateMe(nominateMeAddress).isNominee(lawHash, alice), "Alice should be nominated");
        assertTrue(NominateMe(nominateMeAddress).isNominee(lawHash, bob), "Bob should be nominated");
        assertEq(NominateMe(nominateMeAddress).getNomineesCount(lawHash), 2, "Should have two nominees");
        nominees = NominateMe(nominateMeAddress).getNominees(lawHash);
        assertEq(nominees.length, 2, "Should have two nominees in array");
    }

    function testCannotNominateTwice() public {
        // prep
        uint16 nominateMe = 2;
        
        // First nomination
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        daoMock.request(nominateMe, lawCalldata, nonce, "First nomination");
        nonce++;

        // Second nomination attempt
        vm.prank(alice);
        vm.expectRevert("Nominee already nominated.");
        daoMock.request(nominateMe, lawCalldata, nonce, "Second nomination");
    }

    function testCannotRevokeIfNotNominated() public {
        // prep
        uint16 nominateMe = 2;
        lawCalldata = abi.encode(false);

        // Try to revoke without being nominated
        vm.prank(alice);
        vm.expectRevert("Nominee not nominated.");
        daoMock.request(nominateMe, lawCalldata, nonce, "Revoking without nomination");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 nominateMe = 2;
        (address nominateMeAddress, , ) = daoMock.getActiveLaw(nominateMe);
        
        lawCalldata = abi.encode(true);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(nominateMeAddress).handleRequest(alice, address(daoMock), nominateMe, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 0, "Should have no targets");
        assertEq(values.length, 0, "Should have no values");
        assertEq(calldatas.length, 0, "Should have no calldatas");
        assertEq(stateChange, abi.encode(alice, true), "State change should be alice, true");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

contract StringsArrayTest is TestSetupState {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the StringsArray contract from the test setup
        uint16 stringsArray = 3;
        (address stringsArrayAddress, , ) = daoMock.getActiveLaw(stringsArray);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(stringsArrayAddress).getConditions(address(daoMock), stringsArray).allowedRole, 1, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(stringsArrayAddress).getExecutions(address(daoMock), stringsArray).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testAddString() public {
        // prep
        uint16 stringsArray = 3;
        lawCalldata = abi.encode(
            "test string",
            true
        );
        description = "Adding a string to the array";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // act
        vm.prank(bob);
        daoMock.request(stringsArray, lawCalldata, nonce, description);

        // assert
        (address stringsArrayAddress, , ) = daoMock.getActiveLaw(stringsArray);
        lawHash = LawUtilities.hashLaw(address(daoMock), stringsArray);
        assertEq(StringsArray(stringsArrayAddress).strings(lawHash, 0), "test string", "String should be added correctly");
        assertEq(StringsArray(stringsArrayAddress).numberOfStrings(lawHash), 1, "Number of strings should be 1");
    }

    function testRemoveString() public {
        // prep
        uint16 stringsArray = 3;
        
        // First add a string
        lawCalldata = abi.encode(
            "test string",
            true
        );

        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        vm.prank(bob);
        daoMock.request(stringsArray, lawCalldata, nonce, "Adding initial string");
        nonce++;

        // Then remove it
        lawCalldata = abi.encode(
            "test string",
            false
        );

        vm.prank(bob);
        daoMock.request(stringsArray, lawCalldata, nonce, "Removing string");

        // assert
        (address stringsArrayAddress, , ) = daoMock.getActiveLaw(stringsArray);
        lawHash = LawUtilities.hashLaw(address(daoMock), stringsArray);
        assertEq(StringsArray(stringsArrayAddress).numberOfStrings(lawHash), 0, "Number of strings should be 0");
    }

    function testMultipleStrings() public {
        // prep
        uint16 stringsArray = 3;
        
        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // Add first string
        lawCalldata = abi.encode(
            "first string",
            true
        );
        vm.prank(bob);
        daoMock.request(stringsArray, lawCalldata, nonce, "Adding first string");
        nonce++;

        // Add second string
        lawCalldata = abi.encode(
            "second string",
            true
        );
        vm.prank(bob);
        daoMock.request(stringsArray, lawCalldata, nonce, "Adding second string");

        // assert
        (address stringsArrayAddress, , ) = daoMock.getActiveLaw(stringsArray);
        lawHash = LawUtilities.hashLaw(address(daoMock), stringsArray);
        assertEq(StringsArray(stringsArrayAddress).strings(lawHash, 0), "first string", "First string should be correct");
        assertEq(StringsArray(stringsArrayAddress).strings(lawHash, 1), "second string", "Second string should be correct");
        assertEq(StringsArray(stringsArrayAddress).numberOfStrings(lawHash), 2, "Number of strings should be 2");
    }

    function testRemoveMiddleString() public {
        // prep
        uint16 stringsArray = 3;
        
        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // Add three strings
        string[3] memory testStrings = ["first", "second", "third"];
        for(i = 0; i < 3; i++) {
            lawCalldata = abi.encode(
                testStrings[i],
                true
            );
            vm.prank(bob);
            daoMock.request(stringsArray, lawCalldata, nonce, string.concat("Adding string ", testStrings[i]));
            nonce++;
        }

        // Remove middle string
        lawCalldata = abi.encode(
            "second",
            false
        );
        vm.prank(bob);
        daoMock.request(stringsArray, lawCalldata, nonce, "Removing middle string");

        // assert
        (address stringsArrayAddress, , ) = daoMock.getActiveLaw(stringsArray);
        lawHash = LawUtilities.hashLaw(address(daoMock), stringsArray);
        assertEq(StringsArray(stringsArrayAddress).strings(lawHash, 0), "first", "First string should remain");
        assertEq(StringsArray(stringsArrayAddress).strings(lawHash, 1), "third", "Last string should move to second position");
        assertEq(StringsArray(stringsArrayAddress).numberOfStrings(lawHash), 2, "Number of strings should be 2");
    }

    function testCannotRemoveNonExistentString() public {
        // prep
        uint16 stringsArray = 3;
        lawCalldata = abi.encode(
            "non existent string",
            false
        );

        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // Try to remove string that doesn't exist
        vm.prank(bob);
        vm.expectRevert("String not found.");
        daoMock.request(stringsArray, lawCalldata, nonce, "Removing non-existent string");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 stringsArray = 3;
        lawCalldata = abi.encode(
            "test string",
            true
        );

        // Try to add string without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(stringsArray, lawCalldata, nonce, "Unauthorized string addition");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 stringsArray = 3;
        (address stringsArrayAddress, , ) = daoMock.getActiveLaw(stringsArray);
        
        lawCalldata = abi.encode(
            "test string",
            true
        );

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(stringsArrayAddress).handleRequest(bob, address(daoMock), stringsArray, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 0, "Should have no targets");
        assertEq(values.length, 0, "Should have no values");
        assertEq(calldatas.length, 0, "Should have no calldatas");
        assertEq(stateChange, lawCalldata, "State change should match input calldata");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

contract TokensArrayTest is TestSetupState {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the TokensArray contract from the test setup
        uint16 tokensArray = 4;
        (address tokensArrayAddress, , ) = daoMock.getActiveLaw(tokensArray);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(tokensArrayAddress).getConditions(address(daoMock), tokensArray).allowedRole, 1, "Allowed role should be set to ROLE_ONE");
        assertEq(Law(tokensArrayAddress).getExecutions(address(daoMock), tokensArray).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testAddErc20Token() public {
        // prep
        uint16 tokensArray = 4;
        lawCalldata = abi.encode(
            mockAddresses[2], // erc20VotesMock address
            uint256(0), // TokenType.Erc20
            true // add
        );
        description = "Adding an ERC20 token to the array";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // act
        vm.prank(bob);
        daoMock.request(tokensArray, lawCalldata, nonce, description);

        // assert
        (address tokensArrayAddress, , ) = daoMock.getActiveLaw(tokensArray);
        lawHash = LawUtilities.hashLaw(address(daoMock), tokensArray);
        (address tokenAddress, TokensArray.TokenType tokenType) = TokensArray(tokensArrayAddress).tokens(lawHash, 0);
        assertEq(tokenAddress, mockAddresses[2], "Token address should be added correctly");
        assertEq(uint256(tokenType), 0, "Token type should be ERC20");
        assertEq(TokensArray(tokensArrayAddress).numberOfTokens(lawHash), 1, "Number of tokens should be 1");
    }

    function testAddMultipleTokenTypes() public {
        // prep
        uint16 tokensArray = 4;
        
        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // Add ERC20 token
        lawCalldata = abi.encode(
            mockAddresses[2], // erc20VotesMock
            uint256(0), // TokenType.Erc20
            true
        );
        vm.prank(bob);
        daoMock.request(tokensArray, lawCalldata, nonce, "Adding ERC20 token");
        nonce++;

        // Add ERC721 token
        lawCalldata = abi.encode(
            mockAddresses[4], // erc721Mock
            uint256(1), // TokenType.Erc721
            true
        );
        vm.prank(bob);
        daoMock.request(tokensArray, lawCalldata, nonce, "Adding ERC721 token");
        nonce++;

        // Add ERC1155 token
        lawCalldata = abi.encode(
            mockAddresses[5], // erc1155Mock
            uint256(2), // TokenType.Erc1155
            true
        );
        vm.prank(bob);
        daoMock.request(tokensArray, lawCalldata, nonce, "Adding ERC1155 token");

        // assert
        (address tokensArrayAddress, , ) = daoMock.getActiveLaw(tokensArray);
        lawHash = LawUtilities.hashLaw(address(daoMock), tokensArray);
        
        // Check first token (ERC20)
        (address token0Address, TokensArray.TokenType token0Type) = TokensArray(tokensArrayAddress).tokens(lawHash, 0);
        assertEq(token0Address, mockAddresses[2], "First token address should be ERC20");
        assertEq(uint256(token0Type), 0, "First token type should be ERC20");
        
        // Check second token (ERC721)
        (address token1Address, TokensArray.TokenType token1Type) = TokensArray(tokensArrayAddress).tokens(lawHash, 1);
        assertEq(token1Address, mockAddresses[4], "Second token address should be ERC721");
        assertEq(uint256(token1Type), 1, "Second token type should be ERC721");
        
        // Check third token (ERC1155)
        (address token2Address, TokensArray.TokenType token2Type) = TokensArray(tokensArrayAddress).tokens(lawHash, 2);
        assertEq(token2Address, mockAddresses[5], "Third token address should be ERC1155");
        assertEq(uint256(token2Type), 2, "Third token type should be ERC1155");
        
        assertEq(TokensArray(tokensArrayAddress).numberOfTokens(lawHash), 3, "Number of tokens should be 3");
    }

    function testRemoveToken() public {
        // prep
        uint16 tokensArray = 4;
        
        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // First add a token
        lawCalldata = abi.encode(
            mockAddresses[2], // erc20VotesMock
            uint256(0), // TokenType.Erc20
            true
        );
        vm.prank(bob);
        daoMock.request(tokensArray, lawCalldata, nonce, "Adding token");
        nonce++;

        // Then remove it
        lawCalldata = abi.encode(
            mockAddresses[2], // erc20VotesMock
            uint256(0), // TokenType.Erc20
            false
        );
        vm.prank(bob);
        daoMock.request(tokensArray, lawCalldata, nonce, "Removing token");

        // assert
        (address tokensArrayAddress, , ) = daoMock.getActiveLaw(tokensArray);
        lawHash = LawUtilities.hashLaw(address(daoMock), tokensArray);
        assertEq(TokensArray(tokensArrayAddress).numberOfTokens(lawHash), 0, "Number of tokens should be 0");
    }

    function testRemoveMiddleToken() public {
        // prep
        uint16 tokensArray = 4;
        
        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // Add three tokens
        address[3] memory tokenAddresses = [mockAddresses[2], mockAddresses[4], mockAddresses[5]];
        uint256[3] memory tokenTypes = [uint256(0), uint256(1), uint256(2)];
        
        for(i = 0; i < 3; i++) {
            lawCalldata = abi.encode(
                tokenAddresses[i],
                tokenTypes[i],
                true
            );
            vm.prank(bob);
            daoMock.request(tokensArray, lawCalldata, nonce, string.concat("Adding token ", vm.toString(i)));
            nonce++;
        }

        // Remove middle token (ERC721)
        lawCalldata = abi.encode(
            mockAddresses[4], // erc721Mock
            uint256(1), // TokenType.Erc721
            false
        );
        vm.prank(bob);
        daoMock.request(tokensArray, lawCalldata, nonce, "Removing middle token");

        // assert
        (address tokensArrayAddress, , ) = daoMock.getActiveLaw(tokensArray);
        lawHash = LawUtilities.hashLaw(address(daoMock), tokensArray);
        
        // Check first token remains (ERC20)
        (address token0Address, TokensArray.TokenType token0Type) = TokensArray(tokensArrayAddress).tokens(lawHash, 0);
        assertEq(token0Address, mockAddresses[2], "First token should remain ERC20");
        assertEq(uint256(token0Type), 0, "First token type should remain ERC20");
        
        // Check second token is now ERC1155 (was moved from end)
        (address token1Address, TokensArray.TokenType token1Type) = TokensArray(tokensArrayAddress).tokens(lawHash, 1);
        assertEq(token1Address, mockAddresses[5], "Second token should now be ERC1155");
        assertEq(uint256(token1Type), 2, "Second token type should now be ERC1155");
        
        assertEq(TokensArray(tokensArrayAddress).numberOfTokens(lawHash), 2, "Number of tokens should be 2");
    }

    function testCannotRemoveNonExistentToken() public {
        // prep
        uint16 tokensArray = 4;
        lawCalldata = abi.encode(
            mockAddresses[2], // non-existent token
            uint256(0), // TokenType.Erc20
            false
        );

        vm.prank(address(daoMock));
        daoMock.assignRole(1, bob);

        // Try to remove token that doesn't exist
        vm.prank(bob);
        vm.expectRevert("Token not found.");
        daoMock.request(tokensArray, lawCalldata, nonce, "Removing non-existent token");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 tokensArray = 4;
        lawCalldata = abi.encode(
            mockAddresses[2], // erc20VotesMock
            uint256(0), // TokenType.Erc20
            true
        );

        // Try to add token without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(tokensArray, lawCalldata, nonce, "Unauthorized token addition");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 tokensArray = 4;
        (address tokensArrayAddress, , ) = daoMock.getActiveLaw(tokensArray);
        
        lawCalldata = abi.encode(
            mockAddresses[2], // erc20VotesMock
            uint256(0), // TokenType.Erc20
            true
        );

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(tokensArrayAddress).handleRequest(bob, address(daoMock), tokensArray, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 0, "Should have no targets");
        assertEq(values.length, 0, "Should have no values");
        assertEq(calldatas.length, 0, "Should have no calldatas");
        assertEq(stateChange, lawCalldata, "State change should match input calldata");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}




