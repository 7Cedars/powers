// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Powers } from "../../../src/Powers.sol";
import { TestSetupElectoral } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";
import { ElectionVotes } from "../../../src/laws/state/ElectionVotes.sol";
import { ElectionCall } from "../../../src/laws/electoral/ElectionCall.sol";
import { ElectionTally } from "../../../src/laws/electoral/ElectionTally.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract DirectSelectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testAssignSucceeds() public {
        // prep: check if alice does NOT have role 3
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0);
        address directSelect = laws[2];
        bytes memory lawCalldata = abi.encode(false, charlotte); // revoke
        bytes memory expectedCalldata = abi.encodeWithSelector(
            Powers.assignRole.selector, ROLE_THREE, charlotte
            );

        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testAssignReverts() public {
        // prep: check if alice does have role 3
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
        address directSelect = laws[2];
        bytes memory lawCalldata = abi.encode(false, alice); // revoke
        abi.encodeWithSelector(Powers.assignRole.selector, ROLE_THREE, alice);

        // act & assert
        vm.startPrank(address(daoMock));
        vm.expectRevert("Account already has role.");
        Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));
    }

    function testRevokeSucceeds() public {
        // prep: check if alice does have role 3
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
        address directSelect = laws[2];
        bytes memory lawCalldata = abi.encode(true, alice); // revoke
        bytes memory expectedCalldata = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_THREE, alice);
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));

        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testRevokeReverts() public {
        // prep: check if alice does have role 3
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0);
        address directSelect = laws[2];
        bytes memory lawCalldata = abi.encode(true, charlotte); // revoke
        abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_THREE, charlotte);

        // act & assert
        vm.expectRevert("Account does not have role.");
        vm.startPrank(address(daoMock));
        Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }
}

contract RandomlySelectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testAssignRolesWithFewNominees() public {
        // prep
        address nominateMe = laws[0];
        address randomlySelect = laws[3];

        bytes memory lawCalldataNominate = abi.encode(true);
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        bytes memory expectedCalldata = abi.encodeWithSelector(
            Powers.assignRole.selector, ROLE_THREE, charlotte
            );
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert
        assertEq(targetsOut.length, 1);
        assertEq(valuesOut.length, 1);
        assertEq(calldatasOut.length, 1);
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testAssignRandomRolesWithManyNominees() public {
        // prep -- nominate all users
        address nominateMe = laws[0];
        address randomlySelect = laws[3];

        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert
        assertEq(targetsOut.length, 3);
        assertEq(valuesOut.length, 3);
        assertEq(calldatasOut.length, 3);
        for (uint256 i = 0; i < targetsOut.length; i++) {
            assertEq(targetsOut[i], address(daoMock));
            assertEq(valuesOut[i], 0);
            if (i != 0) {
                assertNotEq(calldatasOut[i], calldatasOut[i - 1]);
            }
        }
    }

    function testRandomReelectionWorks() public {
        // prep -- nominate all users
        address nominateMe = laws[0];
        address randomlySelect = laws[3];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        vm.startPrank(address(daoMock));
        (,, bytes[] memory calldatasOut1) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + block.number + 100);

        // act: second election
        vm.startPrank(address(daoMock));
        address[] memory revokees = new address[](3);
        revokees[0] = users[0];
        revokees[1] = users[1];
        revokees[2] = users[2];
        bytes memory lawCalldataElect2 = abi.encode(revokees); // no one to revoke
        (
            address[] memory targetsOut2, 
            uint256[] memory valuesOut2, 
            bytes[] memory calldatasOut2
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect2, bytes32(0));

        // assert
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}

contract TokenSelectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testAssignTokenRolesWithFewNominees() public {
        // prep -- nominate charlotte
        address nominateMe = laws[0];
        address tokenSelect = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        bytes memory expectedCalldata = abi.encodeWithSelector(
            Powers.assignRole.selector, ROLE_THREE, charlotte
            );
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert
        assertEq(targetsOut.length, 1);
        assertEq(valuesOut.length, 1);
        assertEq(calldatasOut.length, 1);
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testAssignTokenRolesWithManyNominees() public {
        // prep -- nominate all users
        address nominateMe = laws[0];
        address tokenSelect = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert
        assertEq(targetsOut.length, 3);
        assertEq(valuesOut.length, 3);
        assertEq(calldatasOut.length, 3);
        for (uint256 i = 0; i < targetsOut.length; i++) {
            assertEq(targetsOut[i], address(daoMock));
            assertEq(valuesOut[i], 0);
            if (i != 0) {
                assertNotEq(calldatasOut[i], calldatasOut[i - 1]);
            }
        }
    }

    function testTokensReelectionWorks() public {
        // prep -- nominate all users
        address nominateMe = laws[0];
        address tokenSelect = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        vm.startPrank(address(daoMock));
        (,, bytes[] memory calldatasOut1) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + block.number + 100);

        // act: second election
        address[] memory revokees = new address[](3);
        revokees[0] = users[0];
        revokees[1] = users[1];
        revokees[2] = users[2];
        bytes memory lawCalldataElect2 = abi.encode(revokees);
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut2, 
            uint256[] memory valuesOut2, 
            bytes[] memory calldatasOut2
            ) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect2, bytes32(0));

        // assert
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}

contract DelegateSelectTest is TestSetupElectoral {
    using ShortStrings for *;

    function testAssignDelegateRolesWithFewNominees() public {
        // prep -- nominate charlotte
        address nominateMe = laws[0];
        address delegateSelect = laws[5];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        bytes memory lawCalldataElect = abi.encode(); // empty calldata
        bytes memory expectedCalldata = abi.encodeWithSelector(
            Powers.assignRole.selector, ROLE_THREE, charlotte
            );
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(delegateSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert
        assertEq(targetsOut.length, 1);
        assertEq(valuesOut.length, 1);
        assertEq(calldatasOut.length, 1);
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testAssignDelegateRolesWithManyNominees() public {
        // prep -- nominate all users
        address nominateMe = laws[0];
        address delegateSelect = laws[5];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        // nominate
        for (uint256 i = 4; i < users.length; i++) {
            vm.prank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
            vm.stopPrank();
        }
        // mint vote
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            erc20VotesMock.mintVotes(100 + i * 2);
            erc20VotesMock.delegate(users[i]); // delegate votes to themselves
            vm.stopPrank();
        }

        // act
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // empty calldata
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(delegateSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert
        assertEq(targetsOut.length, 3);
        assertEq(valuesOut.length, 3);
        assertEq(calldatasOut.length, 3);
        for (uint256 i = 0; i < targetsOut.length; i++) {
            assertEq(targetsOut[i], address(daoMock));
            assertEq(valuesOut[i], 0);
            if (i != 0) {
                assertNotEq(calldatasOut[i], calldatasOut[i - 1]);
            }
        }
    }

    function testDelegatesReelectionWorks() public {
        // prep -- nominate all users
        address nominateMe = laws[0];
        address delegateSelect = laws[5];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // empty calldata
        vm.startPrank(address(daoMock));
        (,, bytes[] memory calldatasOut1) = Law(delegateSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + block.number + 100);

        // act: second election
        address[] memory revokees = new address[](3);
        revokees[0] = users[0];
        revokees[1] = users[1];
        revokees[2] = users[2];
        bytes memory lawCalldataElect2 = abi.encode(revokees);
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut2, 
            uint256[] memory valuesOut2, 
            bytes[] memory calldatasOut2
            ) = Law(delegateSelect).executeLaw(charlotte, lawCalldataElect2, bytes32(0));

        // assert
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}

contract ElectionCallTest is TestSetupElectoral {
    function testElectionVotesContractCorrectlyDeployed() public {
        // prep: data
        address electionCall = laws[6];
        bytes memory lawCalldata = abi.encode(
            "This is a test election",
            50, // startVote
            75 // endVote
        );

        // act + assert emit
        vm.startPrank(address(daoMock));

        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(electionCall).executeLaw(charlotte, lawCalldata, bytes32(0));

        // retrieve new grant address from calldatasOut
        uint256 BYTES4_SIZE = 4;
        uint256 bytesSize = calldatasOut[0].length - BYTES4_SIZE;
        bytes memory dataWithoutSelector = new bytes(bytesSize);
        for (uint16 i = 0; i < bytesSize; i++) {
            dataWithoutSelector[i] = calldatasOut[0][i + BYTES4_SIZE];
        }
        address electionVotesAddress = abi.decode(dataWithoutSelector, (address));

        // assert output
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertNotEq(electionVotesAddress.code.length, 0);
    }

    function testElectionVotesContractRevertsIfAlreadyDeployed() public {
        // prep: data
        address electionCall = laws[6];
        bytes memory lawCalldata = abi.encode(
            "This is a test election",
            50, // startVote
            75 // endVote
        );
        // deploy once..
        vm.prank(address(daoMock));
        Law(electionCall).executeLaw(charlotte, lawCalldata, bytes32(0));

        // act: deploy again
        vm.expectRevert("Election Votes address already exists.");
        vm.prank(address(daoMock));
        Law(electionCall).executeLaw(charlotte, lawCalldata, bytes32(0));
    }
}

contract ElectionTallyTest is TestSetupElectoral {
    function testNomineesCorrectlyElectedWithManyNominees() public {
        // prep: data
        address nominateMe = laws[0];
        address electionCall = laws[6];
        address electionTally = laws[7];
        uint48 startVote = 50;
        uint48 endVote = 150;

        bytes memory lawCalldataNominate = abi.encode(true);
        bytes memory lawCalldataElection = abi.encode(
            "This is a test election",
            startVote, // startVote
            endVote // endVote
        );

        // create an election 
        vm.prank(address(charlotte));
        Powers(payable(address(daoMock))).execute(
            electionCall, 
            lawCalldataElection,
            "Test calling an election!"
        );
        address electionVotesAddress = ElectionCall(electionCall).electionVotes();

        // prep: nominate accounts.
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
            vm.stopPrank();
        }
        // prep: vote on accounts.
        vm.roll(startVote + 1);
        for (uint256 i = 0; i < users.length; i++) {
            if (i <= 4) {
                vm.startPrank(address(daoMock));
                ElectionVotes(electionVotesAddress).executeLaw(users[i], abi.encode(alice), bytes32(0));
            }
            if (i > 4 && i <= 7) {
                vm.startPrank(address(daoMock));
                ElectionVotes(electionVotesAddress).executeLaw(users[i], abi.encode(bob), bytes32(0));
            }
            if (i > 8 && i <= 9) {
                vm.startPrank(address(daoMock));
                ElectionVotes(electionVotesAddress).executeLaw(users[i], abi.encode(charlotte), bytes32(0));
            }
        }

        // act + assert emit
        vm.roll(endVote + 1);
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(electionTally).executeLaw(
                charlotte, 
                lawCalldataElection, 
                bytes32(keccak256("Test calling an election!"))
                );

        // assert output
        assertEq(targetsOut.length, 3);
        assertEq(valuesOut.length, 3);
        assertEq(calldatasOut.length, 3);
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encodeWithSelector(Powers.assignRole.selector, 3, alice));
        assertEq(targetsOut[1], address(daoMock));
        assertEq(valuesOut[1], 0);
        assertEq(calldatasOut[1], abi.encodeWithSelector(Powers.assignRole.selector, 3, bob));

        // assert state
        assertEq(ElectionTally(electionTally).electedAccounts(0), alice);
        assertEq(ElectionTally(electionTally).electedAccounts(1), bob);
    }

    function testNomineesCorrectlyElectedWithFewNominees() public {
        // prep: data
        address nominateMe = laws[0];
        address electionCall = laws[6];
        address electionTally = laws[7];
        uint48 startVote = 50;
        uint48 endVote = 150;

        bytes memory lawCalldataNominate = abi.encode(true);
        bytes memory lawCalldataElection = abi.encode(
            "This is a test election",
            startVote, // startVote
            endVote // endVote
        ); 

        // prep: nominate accounts.
        vm.prank(address(daoMock));
        Law(nominateMe).executeLaw(alice, lawCalldataNominate, bytes32(0));
        
        // create an election 
        vm.prank(address(charlotte));
        Powers(payable(address(daoMock))).execute(
            electionCall, 
            lawCalldataElection,
            "Test calling an election!"
        );
        address electionVotesAddress = ElectionCall(electionCall).electionVotes();

        // prep: vote on alice.
        vm.roll(startVote + 1);
        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(address(daoMock));
            ElectionVotes(electionVotesAddress).executeLaw(users[i], abi.encode(alice), bytes32(0));
        }

        // act + assert emit
        vm.roll(endVote + 1);
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(electionTally).executeLaw(
                charlotte, 
                lawCalldataElection, 
                bytes32(keccak256("Test calling an election!"))
                );

        // assert output
        assertEq(targetsOut.length, 2);
        assertEq(valuesOut.length, 2);
        assertEq(calldatasOut.length, 2);
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encodeWithSelector(Powers.assignRole.selector, 3, alice));
        // assert state
        assertEq(ElectionTally(electionTally).electedAccounts(0), alice);
    }

    function testTallyRevertsIfElectionVotesNotFinishedYet() public {
        // prep: data
        address nominateMe = laws[0];
        address electionCall = laws[6];
        address electionTally = laws[7];
        uint48 startVote = 50;
        uint48 endVote = 150;

        bytes memory lawCalldataNominate = abi.encode(true);
        bytes memory lawCalldataElection = abi.encode(
            "This is a test election",
            startVote, // startVote
            endVote // endVote
        );

        // create an election 
        vm.prank(address(charlotte));
        Powers(payable(address(daoMock))).execute(
            electionCall, 
            lawCalldataElection,
            "Test calling an election!"
        );
        address electionVotesAddress = ElectionCall(electionCall).electionVotes();

        // prep: nominate alice only.
        vm.prank(address(daoMock));
        Law(nominateMe).executeLaw(alice, lawCalldataNominate, bytes32(0));

        // prep: vote on alice.
        vm.roll(startVote + 1);
        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(address(daoMock));
            ElectionVotes(electionVotesAddress).executeLaw(users[i], abi.encode(alice), bytes32(0));
        }

        // act + assert emit
        vm.roll(endVote - 10);
        vm.expectRevert("Election still active.");
        vm.startPrank(address(daoMock));
        Law(electionTally).executeLaw(
            charlotte, 
            lawCalldataElection, 
            bytes32(keccak256("Test calling an election!"))
            );
    }

    function testTallyRevertsIfNoNominees() public {
        // prep: data
        address nominateMe = laws[0];
        address electionCall = laws[6];
        address electionTally = laws[7];
        uint48 startVote = 50;
        uint48 endVote = 150;
        
        bytes memory lawCalldataNominate = abi.encode(true);
        bytes memory lawCalldataElection = abi.encode(
            "This is a test election",
            startVote, // startVote
            endVote // endVote
        );

        // create an election 
        vm.prank(address(charlotte));
        Powers(payable(address(daoMock))).execute(
            electionCall, 
            lawCalldataElection,
            "Test calling an election!"
        );
        address electionVotesAddress = ElectionCall(electionCall).electionVotes();

        // act + assert emit
        vm.roll(endVote + 1);
        vm.expectRevert("No nominees.");
        vm.startPrank(address(daoMock));
        Law(electionTally).executeLaw(
            charlotte, 
            lawCalldataElection, 
            bytes32(keccak256("Test calling an election!"))
            );
    }

}

