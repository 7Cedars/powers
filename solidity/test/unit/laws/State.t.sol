// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// test setup
import "forge-std/Test.sol";
import { TestSetupState } from "../../TestSetup.t.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// protocol 
import { Powers } from "../../../src/Powers.sol";
import { Law } from "../../../src/Law.sol";

// law contracts being tested
import { AddressesMapping } from "../../../src/laws/state/AddressesMapping.sol";
import { StringsArray } from "../../../src/laws/state/StringsArray.sol";
import { TokensArray } from "../../../src/laws/state/TokensArray.sol";
import { NominateMe } from "../../../src/laws/state/NominateMe.sol";
import { ElectionVotes } from "../../../src/laws/state/ElectionVotes.sol";

contract AddressMappingTest is TestSetupState {
    event AddressesMapping__Added(address account);
    event AddressesMapping__Removed(address account);

    // take this out later 
    function testParsingAddress() public {
        address mock721_ = makeAddr("mock721");
        string memory description = string.concat(
            "Anyone who knows how to mint an NFT at ", 
            Strings.toHexString(uint256(addressToInt(mock721_)), 20), 
            " can (de)select themselves for role 1."
            ); 
        console.log(mock721_); 
        console.log(description); 

        assertNotEq(description, "");
    }

    function addressToInt(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }

    function testSuccessfulAddingAddress() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            true // add
        );

        // act + assert emit
        vm.expectEmit(true, false, false, false);
        emit AddressesMapping__Added(address(123));
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(addressesMapping).executeLaw(address(0), lawCalldata, keccak256("Adding an address"));

        // assert state
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), true);

        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testAddingAddressRevertsIfAlreadyAdded() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            true // add
        );
        vm.startPrank(address(daoMock));
        Law(addressesMapping).executeLaw(address(0), lawCalldata, keccak256("Adding an address first time"));

        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert("Already true.");
        Law(addressesMapping).executeLaw(address(0), lawCalldata, keccak256("Adding an address a second time"));

        // assert state
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), true);
    }

    function testSuccessfulRemovingAddress() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldataAdd = abi.encode(
            address(123), // address
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // address
            false // add
        );

        vm.startPrank(address(daoMock));
        Law(addressesMapping).executeLaw(address(0), lawCalldataAdd, keccak256("Adding an address to be removed"));

        // act + emit
        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit AddressesMapping__Removed(address(123));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut) = Law(addressesMapping).executeLaw(address(0), lawCalldataRemove, keccak256("Removing an address"));

        // assert state
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), false);
        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testRemovingAddressRevertsIfNotAdded() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            false // add
        );

        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert("Already false.");
        Law(addressesMapping).executeLaw(address(0), lawCalldata, keccak256("Removing an address not added"));

        // assert state
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), false);
    }
}

contract StringsArrayTest is TestSetupState {
    event StringsArray__StringAdded(string str);
    event StringsArray__StringRemoved(string str);

    function testSuccessfulAddingString() public {
        address stringsArray = laws[1];
        // prep
        bytes memory lawCalldata = abi.encode("hello world", true);

        // act + assert emit
        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit StringsArray__StringAdded("hello world");
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut) = Law(stringsArray).executeLaw(address(0), lawCalldata, keccak256("Adding a string"));

        // assert state
        assertEq(StringsArray(stringsArray).strings(0), "hello world");
        assertEq(StringsArray(stringsArray).numberOfStrings(), 1);
        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testSuccessfulRemovingString() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldataAdd = abi.encode("hello world", true);
        bytes memory lawCalldataRemove = abi.encode("hello world", false);

        vm.startPrank(address(daoMock));
        Law(stringsArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a string to be removed"));

        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit StringsArray__StringRemoved("hello world");
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(stringsArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a string"));

        // assert state
        assertEq(StringsArray(stringsArray).numberOfStrings(), 0);
        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testRemovingStringRevertsIfNoneAdded() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldata = abi.encode("hello world", false);

        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert("String not found.");
        Law(stringsArray).executeLaw(address(0), lawCalldata, keccak256("Removing a string not added"));
    }

    function testRemovingStringRevertsIfStringNotFound() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldataAdd = abi.encode("hello world", true);
        bytes memory lawCalldataRemove = abi.encode("another string", false);

        vm.startPrank(address(daoMock));
        Law(stringsArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a string not to be removed"));

        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert("String not found.");
        Law(stringsArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a string that does not exist"));
    }
}

contract TokensArrayTest is TestSetupState {
    event TokensArray__TokenAdded(address indexed tokenAddress, TokensArray.TokenType tokenType);
    event TokensArray__TokenRemoved(address indexed tokenAddress, TokensArray.TokenType tokenType);

    function testSuccessfulAddingToken() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldata = abi.encode(
            address(123), // token address
            0, // token type
            true // add
        );

        // act + assert emit
        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit TokensArray__TokenAdded(address(123), TokensArray.TokenType(0));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(tokensArray).executeLaw(address(0), lawCalldata, keccak256("Adding a token"));

        // assert state
        (address tokenAddress, TokensArray.TokenType tokenType) = TokensArray(tokensArray).tokens(0);
        assertEq(tokenAddress, address(123));
        assertEq(TokensArray(tokensArray).numberOfTokens(), 1);

        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testSuccessfulRemovingToken() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldataAdd = abi.encode(
            address(123), // token address
            0, // token type
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // token address
            0, // token type
            false // remove
        );
        vm.startPrank(address(daoMock));
        Law(tokensArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a token"));

        // act + assert emit
        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit TokensArray__TokenRemoved(address(123), TokensArray.TokenType(0));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut) = Law(tokensArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a token"));

        // assert state
        assertEq(TokensArray(tokensArray).numberOfTokens(), 0);
        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testRemovingTokenRevertsIfNotAdded() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // token address
            0, // token type
            false // remove
        );

        // act + assert revert
        vm.startPrank(address(daoMock));
        vm.expectRevert("Token not found.");
        Law(tokensArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a non-existent token"));

        // assert state
        assertEq(TokensArray(tokensArray).numberOfTokens(), 0);
    }

    function testRemovingTokenRevertsIfTokenNotFound() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldataAdd = abi.encode(
            address(321), // token address
            1, // token type
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // token address
            0, // token type
            false // remove
        );
        vm.startPrank(address(daoMock));
        Law(tokensArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a token"));

        // act + assert revert
        vm.startPrank(address(daoMock));
        vm.expectRevert("Token not found.");
        Law(tokensArray).executeLaw(
            address(0), lawCalldataRemove, keccak256("Removing a token that had not been added")
        );

        // assert state
        assertEq(TokensArray(tokensArray).numberOfTokens(), 1);
    }
}

contract NominateMeTest is TestSetupState {
    event NominateMe__NominationReceived(address indexed nominee);
    event NominateMe__NominationRevoked(address indexed nominee);

    function testAssignNominationSucceeds() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(true); // nominateMe

        // act & assert
        vm.expectEmit(true, false, false, false);
        emit NominateMe__NominationReceived(charlotte);
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    // test addition to count

    function testAssignNominationRevertsWhenAlreadyNominated() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(true); // nominateMe

        // nominate once..
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldata, bytes32(0));

        // and try to nominate twice.
        vm.startPrank(address(daoMock));
        vm.expectRevert("Nominee already nominated.");
        Law(nominateMe).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testRevokeNominationSucceeds() public {
        // prep 1: nominate charlotte
        address nominateMe = laws[3];
        bytes memory lawCalldata1 = abi.encode(true); // nominateMe
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldata1, bytes32(0));

        // prep 2: revoke nomination.
        bytes memory lawCalldata2 = abi.encode(false); // revokeNomination

        // act & assert
        vm.expectEmit(true, false, false, false);
        emit NominateMe__NominationRevoked(charlotte);
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldata2, bytes32(0));
    }

    // test subtraction from count

    function testRevokeNominationRevertsWhenNotNominated() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(false); // revokeNomination

        // charlotte tries to revoke nomination, without being nominated.
        vm.startPrank(address(daoMock));
        vm.expectRevert("Nominee not nominated.");
        Law(nominateMe).executeLaw(charlotte, lawCalldata, bytes32(0));
    }
}

contract ElectionVotesTest is TestSetupState {
    event ElectionVotes__VoteCast(address voter);

    function testVoteCorrectlyRegistered() public {
        // prep
        address nominateMe = laws[3];
        address peerVote = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        bytes memory lawCalldataVote = abi.encode(charlotte); // peerVote
        // nominate charlotte
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act + assert emit
        vm.roll(51); // vote starts at block 50.
        vm.expectEmit(true, false, false, false);
        emit ElectionVotes__VoteCast(charlotte);
        vm.startPrank(address(daoMock));
        Law(peerVote).executeLaw(alice, lawCalldataVote, bytes32(0));

        assertEq(ElectionVotes(peerVote).hasVoted(alice), true);
        assertEq(ElectionVotes(peerVote).votes(charlotte), 1);
    }

    function testVoteRevertsIfElectionNotOpen() public {
        // prep
        address nominateMe = laws[3];
        address peerVote = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        bytes memory lawCalldataVote = abi.encode(charlotte); // peerVote

        // nominate charlotte
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act + assert revert
        vm.roll(40); // vote starts at block 50.
        vm.expectRevert("Election not open.");
        vm.startPrank(address(daoMock));
        Law(peerVote).executeLaw(alice, lawCalldataVote, bytes32(0));
    }

    function testVoteRevertsIfAlreadyVoted() public {
        // prep
        address nominateMe = laws[3];
        address peerVote = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        bytes memory lawCalldataVote = abi.encode(charlotte); // peerVote
        // nominate charlotte
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));
        vm.roll(51); // vote starts at block 50.
        // alice votes a first time...
        vm.startPrank(address(daoMock));
        Law(peerVote).executeLaw(alice, lawCalldataVote, bytes32(0));

        // act + assert revert
        // alice votes tries to vote a second time...
        vm.expectRevert("Already voted.");
        vm.startPrank(address(daoMock));
        Law(peerVote).executeLaw(alice, lawCalldataVote, bytes32(0));
    }

    function testVoteRevertsIfNotNominee() public {
        // prep. note: no one is nominated.
        address peerVote = laws[4];
        bytes memory lawCalldataVote = abi.encode(charlotte); // peerVote

        // act + assert revert
        vm.roll(51); // vote starts at block 50.
        vm.expectRevert("Not a nominee.");
        vm.startPrank(address(daoMock));
        Law(peerVote).executeLaw(alice, lawCalldataVote, bytes32(0));
    }
}
