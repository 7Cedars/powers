// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// test setup
import "forge-std/Test.sol";
import { TestSetupDiversifiedGrants } from "../../../TestSetup.t.sol";

// protocol
import { Powers } from "../../../../src/Powers.sol";
import { Law } from "../../../../src/Law.sol";
import { Erc1155Mock } from "../../../mocks/Erc1155Mock.sol";
import { Erc20VotesMock } from "../../../mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../../../mocks/Erc20TaxedMock.sol";

// law contracts being tested
import { Grant } from "../../../../src/laws/bespoke/diversifiedGrants/Grant.sol";
import { StartGrant } from "../../../../src/laws/bespoke/diversifiedGrants/StartGrant.sol";
import { StopGrant } from "../../../../src/laws/bespoke/diversifiedGrants/StopGrant.sol";
import { SelfDestructPresetAction } from "../../../../src/laws/executive/SelfDestructPresetAction.sol";

import { Erc20VotesMock } from "../../../mocks/Erc20VotesMock.sol";


// openzeppelin contracts
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract AssignCouncilRoleTest is TestSetupDiversifiedGrants {

  function testAssignCouncillor() public {
    // prep
    address nominateMe = laws[5];
    address assignCouncilRole = laws[6];
    bytes memory lawCalldata = abi.encode(
      4, // roleId  
      alice // account
    );

    // assign roles 
    vm.prank(address(daoMock));
    daoMock.assignRole(1, alice); // assign alice to role 1

    vm.prank(alice); 
    daoMock.execute(
      nominateMe, 
      abi.encode(true), 
      "Alice nominates herself"
    );

    vm.startPrank(address(daoMock));
    (
      address[] memory targetsOut, 
      uint256[] memory valuesOut, 
      bytes[] memory calldatasOut) = Law(assignCouncilRole).executeLaw(
        alice, // alice = initiator
        lawCalldata,
        keccak256("Alice is assigned council role")
    );
    vm.stopPrank();

    // assert output
    assertEq(targetsOut[0], address(daoMock));
    assertEq(valuesOut[0], 0);
    assertEq(calldatasOut[0], abi.encodeWithSelector(Powers.assignRole.selector, 4, alice));
  }

  function testAssignCouncilRoleRevertsIfRoleNotAllowed() public {
    // prep
    address nominateMe = laws[5];
    address assignCouncilRole = laws[6];
    bytes memory lawCalldata = abi.encode(
      1, // roleId  
      alice // account
    );
    
    // assign roles 
    vm.prank(address(daoMock));
    daoMock.assignRole(1, alice); // assign alice to role 1

    vm.prank(alice);
    daoMock.execute(
      nominateMe, 
      abi.encode(true), 
      "Alice nominates herself"
    );

    vm.expectRevert("Role not allowed.");
    vm.prank(address(daoMock));
    Law(assignCouncilRole).executeLaw(
      alice, // alice = initiator
      lawCalldata,
      keccak256("Alice is assigned a disallowed council role")
    );
  }

  function testAssignCouncilRoleRevertsIfAccountNotNominated() public {
    // prep
    address assignCouncilRole = laws[6];
    bytes memory lawCalldata = abi.encode(
      4, // allowed roleId  
      alice // account
    );

    // note: no nomination. 

    vm.expectRevert("Account not nominated.");
    vm.prank(address(daoMock));
    Law(assignCouncilRole).executeLaw(
      alice, // alice = initiator
      lawCalldata,
      keccak256("Trying to assign Alice to council role. Should revert because she did not nominate herself.")
    );
  }
}

// contract Grant1155Test is TestSetupDiversifiedGrants {
//     function testGrantRequestRevertsWithAddressZeroGrant() public {
//         // prep
//         address grant1155 = laws[0];
//         uint256 amountRequested = 100;
//         bytes memory lawCalldata = abi.encode(
//             alice, // grantee
//             address(0), // grant address = address(0) contract
//             amountRequested
//         );

//         // act
//         vm.startPrank(address(daoMock));
//         vm.expectRevert("Incorrect grant address.");
//         Law(grant1155).executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests fund payment with address(0) contract address")
//         );
//     }

//     function testGrantRequestRevertsWithIncorrectGrantAddress() public {
//         // prep
//         address grant1155 = laws[0];
//         uint256 amountRequested = 100;
//         bytes memory lawCalldata = abi.encode(
//             alice, // grantee
//             address(123), // incorrect grant address
//             amountRequested
//         );

//         // act
//         vm.startPrank(address(daoMock));
//         vm.expectRevert("Incorrect grant address.");
//         Law(grant1155).executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests fund payment with address(0) contract address")
//         );
//     }

//     function testGrantRequestRevertsWithInsufficientFunds() public {
//         // prep
//         address grant1155 = laws[0];
//         uint256 amountRequested = 6000;
//         bytes memory lawCalldata = abi.encode(
//             alice, // grantee
//             address(grant1155), // incorrect grant address
//             amountRequested
//         );

//         // act
//         vm.startPrank(address(daoMock));
//         vm.expectRevert("Request amount exceeds available funds.");
//         Law(grant1155).executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests more than the available funds.")
//         );
//     }

//     function testGrantRevertsAfterFundsSpent() public {
//         // prep
//         address grant1155 = laws[0];
//         uint256 budget = Grant(grant1155).budget();
//         uint256 amountRequested = 55;
//         uint256 totalRequested;
//         bytes memory lawCalldata = abi.encode(
//             alice, // grantee
//             address(grant1155), // incorrect grant address
//             amountRequested
//         );

//         // act
//         while (totalRequested + amountRequested < budget) {
//             vm.startPrank(address(daoMock));
//             Law(grant1155).executeLaw(
//                 alice, // alice = initiator
//                 lawCalldata,
//                 keccak256("Alice requests more than the available funds.")
//             );
//             totalRequested += amountRequested;
//         }

//         vm.startPrank(address(daoMock));
//         vm.expectRevert("Request amount exceeds available funds.");
//         Law(grant1155).executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests more than the available funds.")
//         );
//     }
// }

// contract Grant20Test is TestSetupDiversifiedGrants {
//   function testGrantRequestRevertsWithAddressZeroGrant() public {
//     // prep
//     address grant20 = laws[1];
//     uint256 amountRequested = 100;
//     bytes memory lawCalldata = abi.encode(
//       alice, // grantee
//       address(0), // grant address = address(0) contract
//       amountRequested
//     );

//     function testGrantSuccessfulTransfer() public {
//         // prep
//         address grant20 = laws[1];
//         uint256 amountRequested = 100;
//         bytes memory lawCalldata = abi.encode(
//             alice, // grantee
//             laws[1], // grant address
//             amountRequested
//         );
//         Erc20VotesMock(erc20VotesMock).balanceOf(address(daoMock));

//         // act
//         vm.startPrank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(grant20).executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests fund payment")
//         );

//         // assert
//         assertEq(targetsOut[0], address(erc20VotesMock));
//         assertEq(valuesOut[0], 0);
//         assertEq(
//             calldatasOut[0],
//             abi.encodeWithSelector(
//                 ERC20.transfer.selector,
//                 alice, // to
//                 amountRequested // amount
//             )
//         );
//     }
// }

// contract StartGrantTest is TestSetupDiversifiedGrants {
//     Grant.LawConfig public configNewGrants; // config for new grants.

//     function testErc20SuccessfulSetup() public {
//         // prep
//         address startGrant = laws[3];
//         uint48 duration = 3000;
//         uint256 budget = 1000;
//         uint256 tokenId = 0;
//         uint32 allowedRole = 2;

//         configNewGrants.quorum = 80;
//         configNewGrants.succeedAt = 66;
//         configNewGrants.votingPeriod = 1200;
//         configNewGrants.needCompleted = laws[2];

//         bytes memory lawCalldata = abi.encode(
//             "ERC20 grant", // name
//             "This is an ERC20 grant", // description
//             duration, // duration
//             budget, // budget
//             address(erc20VotesMock), // token address
//             uint256(Grant.TokenType.ERC20), // token type
//             tokenId, // token id (unused because Erc20 grant)
//             allowedRole // allowedRole
//         );
//         vm.prank(address(daoMock));
//         Erc20VotesMock(erc20VotesMock).mintVotes(10_000);

//         // act
//         vm.startPrank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(startGrant)
//             .executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests creation of an ERC20 grant")
//         );
//         // retrieve new grant address from calldatasOut
//         uint256 BYTES4_SIZE = 4;
//         uint256 bytesSize = calldatasOut[0].length - BYTES4_SIZE;
//         bytes memory dataWithoutSelector = new bytes(bytesSize);
//         for (uint16 i = 0; i < bytesSize; i++) {
//             dataWithoutSelector[i] = calldatasOut[0][i + BYTES4_SIZE];
//         }
//         address grantAddress = abi.decode(dataWithoutSelector, (address));

//         // assert output
//         assertEq(targetsOut[0], address(daoMock));
//         assertEq(valuesOut[0], 0);
//         assertNotEq(grantAddress.code.length, 0);
//     }

//     function testErc20SetupRevertsWithInsufficientFunds() public {
//         // prep
//         address startGrant = laws[3];
//         uint48 duration = 3000;
//         uint256 budget = 10_000;
//         uint256 tokenId = 0;
//         uint32 allowedRole = 2;

//         bytes memory lawCalldata = abi.encode(
//             "ERC20 grant", // name
//             "This is an ERC20 grant", // description
//             duration, // duration
//             budget, // budget
//             address(erc20VotesMock), // token address
//             uint256(Grant.TokenType.ERC20), // token type
//             tokenId, // token id (unused because Erc20 grant)
//             allowedRole // allowedRole
//         );
//         vm.prank(address(daoMock));
//         Erc20VotesMock(erc20VotesMock).mintVotes(1000); // too few tokens for grant to be created.

//         // act
//         vm.expectRevert("Request amount exceeds available funds.");
//         vm.startPrank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(startGrant)
//             .executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests creation of an ERC20 grant")
//         );
//     }

//     function testErc1155SuccessfulSetup() public {
//         // prep
//         address startGrant = laws[3];
//         uint48 duration = 3000;
//         uint256 budget = 1000;
//         uint256 tokenId = 0;
//         uint32 allowedRole = 2;

//         configNewGrants.quorum = 80;
//         configNewGrants.succeedAt = 66;
//         configNewGrants.votingPeriod = 1200;
//         configNewGrants.needCompleted = laws[2];

//         bytes memory lawCalldata = abi.encode(
//             "ERC1155 grant", // name
//             "This is an ERC1155 grant", // description
//             duration, // duration
//             budget, // budget
//             address(erc1155Mock), // token address
//             uint256(Grant.TokenType.ERC1155), // token type
//             tokenId, // token id (unused because Erc20 grant)
//             allowedRole // allowedRole
//         );
//         vm.prank(address(daoMock));
//         Erc1155Mock(erc1155Mock).mintCoins(10_000);

//         // act
//         vm.startPrank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(startGrant)
//             .executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests creation of an ERC1155 grant")
//         );
//         // retrieve new grant address from calldatasOut
//         uint256 BYTES4_SIZE = 4;
//         uint256 bytesSize = calldatasOut[0].length - BYTES4_SIZE;
//         bytes memory dataWithoutSelector = new bytes(bytesSize);
//         for (uint16 i = 0; i < bytesSize; i++) {
//             dataWithoutSelector[i] = calldatasOut[0][i + BYTES4_SIZE];
//         }
//         address grantAddress = abi.decode(dataWithoutSelector, (address));

//         // assert output
//         assertEq(targetsOut[0], address(daoMock));
//         assertEq(valuesOut[0], 0);
//         assertNotEq(grantAddress.code.length, 0);
//     }

//     function testErc1155SetupRevertsWithInsufficientFunds() public {
//         // prep
//         address startGrant = laws[3];
//         uint48 duration = 3000;
//         uint256 budget = 10_000;
//         uint256 tokenId = 0;
//         uint32 allowedRole = 2;

//         bytes memory lawCalldata = abi.encode(
//             "ERC1155 grant", // name
//             "This is an ERC1155 grant", // description
//             duration, // duration
//             budget, // budget
//             address(erc1155Mock), // token address
//             uint256(Grant.TokenType.ERC1155), // token type
//             tokenId, // token id (unused because Erc20 grant)
//             allowedRole // allowedRole
//         );
//         vm.prank(address(daoMock));
//         Erc1155Mock(erc1155Mock).mintCoins(1000);

//         // act
//         vm.expectRevert("Request amount exceeds available funds.");
//         vm.startPrank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(startGrant)
//             .executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests creation of an ERC1155 grant")
//         );
//     }
// }

// contract StopGrantTest is TestSetupDiversifiedGrants {
//     Grant.LawConfig public configNewGrants; // config for new grants.

//     function testSuccessfulGrantStop() public {
//         // prep
//         uint48 duration = 3000;
//         uint256 budget = 1000;
//         address grantAddress = _deployErc1155Grant(duration, budget);
//         assertNotEq(grantAddress.code.length, 0);
//         address stopGrant = laws[4];
//         bytes memory lawCalldata = abi.encode(grantAddress);

//         // act
//         vm.roll(block.number + duration + 1);
//         vm.prank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(stopGrant)
//             .executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests top of an ERC1155 grant")
//         );

//         // assert output
//         assertEq(targetsOut[0], address(daoMock));
//         assertEq(valuesOut[0], 0);
//         assertEq(calldatasOut[0], abi.encodeWithSelector(Powers.revokeLaw.selector, grantAddress));
//     }

//     function testGrantStopRevertsWithFundsAndDurationRemaining() public {
//         // prep
//         uint48 duration = 3000;
//         uint256 budget = 1000;
//         address grantAddress = _deployErc1155Grant(duration, budget);
//         assertNotEq(grantAddress.code.length, 0);
//         address stopGrant = laws[4];
//         bytes memory lawCalldata = abi.encode(grantAddress);

//         // act
//         vm.expectRevert("Grant not expired.");
//         vm.prank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(stopGrant)
//             .executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests top of an ERC1155 grant")
//         );
//     }

//     function testGrantStopSucceedsWithNoFunds() public {
//         // prep
//         uint48 duration = 3000;
//         uint256 budget = 0;
//         address grantAddress = _deployErc1155Grant(duration, budget);
//         assertNotEq(grantAddress.code.length, 0);
//         address stopGrant = laws[4];
//         bytes memory lawCalldata = abi.encode(grantAddress);

//         // act
//         vm.roll(block.number + duration + 1);
//         vm.prank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(stopGrant)
//             .executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests stop of an empty ERC1155 grant")
//         );

//         // assert output
//         assertEq(targetsOut[0], address(daoMock));
//         assertEq(valuesOut[0], 0);
//         assertEq(calldatasOut[0], abi.encodeWithSelector(Powers.revokeLaw.selector, grantAddress));
//     }

//     //   HELPER FUNCTIONS  //
//     function _deployErc1155Grant(uint48 duration, uint256 budget) internal returns (address grantAddress) {
//         address startGrant = laws[3];
//         uint256 tokenId = 0;
//         uint32 allowedRole = 2;
//         vm.prank(address(daoMock));
//         Erc1155Mock(erc1155Mock).mintCoins(10_000);

//         configNewGrants.quorum = 80;
//         configNewGrants.succeedAt = 66;
//         configNewGrants.votingPeriod = 1200;
//         configNewGrants.needCompleted = laws[2];

//         bytes memory lawCalldata = abi.encode(
//             "ERC1155 grant", // name
//             "This is an ERC1155 grant", // description
//             duration, // duration
//             budget, // budget
//             address(erc1155Mock), // token address
//             uint256(Grant.TokenType.ERC1155), // token type
//             tokenId, // token id (unused because Erc20 grant)
//             allowedRole // allowedRole
//         );

//         // act
//         vm.prank(address(daoMock));
//         (,, bytes[] memory calldatasOut) = Law(startGrant).executeLaw(
//             alice, // alice = initiator
//             lawCalldata,
//             keccak256("Alice requests creation of an ERC1155 grant")
//         );
//         // retrieve new grant address from calldatasOut
//         uint256 BYTES4_SIZE = 4;
//         uint256 bytesSize = calldatasOut[0].length - BYTES4_SIZE;
//         bytes memory dataWithoutSelector = new bytes(bytesSize);
//         for (uint16 i = 0; i < bytesSize; i++) {
//             dataWithoutSelector[i] = calldatasOut[0][i + BYTES4_SIZE];
//         }

//         return (abi.decode(dataWithoutSelector, (address)));
//     }
// }

// contract RoleByTaxPaidTest is TestSetupDiversifiedGrants {
//     function testSuccessfulRoleByTaxPaid() public {
//         address roleByTaxPaid = laws[5];
//         bytes memory lawCalldata = abi.encode(
//             false, // = revoke
//             alice // = account
//         );
//         uint48 epochDuration = erc20TaxedMock.epochDuration();
//         // give alice some funds
//         uint256 transferAmount1 = 10_000;
//         vm.startPrank(address(daoMock));
//         erc20TaxedMock.mint(transferAmount1);
//         erc20TaxedMock.transfer(alice, transferAmount1);
//         vm.stopPrank();

//         // alice needs to pay at least 100 tax to be eligible for role
//         // tax is set at 7% per transaction
//         // 100 tax = 100 / .07 = 1428
//         vm.prank(alice);
//         erc20TaxedMock.transfer(bob, 1430);

//         // act
//         vm.roll(block.number + epochDuration + 1);
//         vm.prank(address(daoMock));
//         (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(roleByTaxPaid)
//             .executeLaw(
//             charlotte, // charlotte = initiator
//             lawCalldata,
//             keccak256("Alice requests role by tax paid")
//         );

//         // assert output
//         assertEq(targetsOut[0], address(daoMock));
//         assertEq(valuesOut[0], 0);
//         assertEq(calldatasOut[0], abi.encodeWithSelector(Powers.assignRole.selector, 3, alice));
//     }

//     function testAssignRoleByTaxRevertsIfNoTaxPaid() public {
//         address roleByTaxPaid = laws[5];
//         bytes memory lawCalldata = abi.encode(
//             false, // = revoke
//             alice // = account
//         );
//         uint48 epochDuration = erc20TaxedMock.epochDuration();

//         // act
//         vm.roll(block.number + epochDuration + 1);
//         vm.expectRevert("Not eligible.");
//         vm.prank(address(daoMock));
//         Law(roleByTaxPaid).executeLaw(
//             charlotte, // charlotte = initiator
//             lawCalldata,
//             keccak256("Alice requests role by tax paid")
//         );
//     }

//     function testRevokeRoleByTaxRevertsIfTaxPaid() public {
//         address roleByTaxPaid = laws[5];
//         bytes memory lawCalldata = abi.encode(
//             true, // = revoke
//             alice // = account
//         );
//         uint48 epochDuration = erc20TaxedMock.epochDuration();
//         // give alice some funds
//         uint256 transferAmount1 = 10_000;
//         vm.startPrank(address(daoMock));
//         erc20TaxedMock.mint(transferAmount1);
//         erc20TaxedMock.transfer(alice, transferAmount1);
//         vm.stopPrank();

//         // alice needs to pay at least 100 tax to be eligible for role
//         // tax is set at 7% per transaction
//         // 100 tax = 100 / .07 = 1428
//         vm.prank(alice);
//         erc20TaxedMock.transfer(bob, 1430);

//         // act
//         vm.roll(block.number + epochDuration + 1);
//         vm.expectRevert("Is eligible.");
//         vm.prank(address(daoMock));
//         Law(roleByTaxPaid).executeLaw(
//             charlotte, // charlotte = initiator
//             lawCalldata,
//             keccak256("Alice requests role by tax paid")
//         );
//     }

//     function testRoleByTaxRevertsIfNoEpochFinishedYet() public {
//         address roleByTaxPaid = laws[5];
//         bytes memory lawCalldata = abi.encode(
//             false, // = revoke
//             alice // = account
//         );
//         uint48 epochDuration = erc20TaxedMock.epochDuration();
//         // give alice some funds
//         uint256 transferAmount1 = 10_000;
//         vm.startPrank(address(daoMock));
//         erc20TaxedMock.mint(transferAmount1);
//         erc20TaxedMock.transfer(alice, transferAmount1);
//         vm.stopPrank();

//         // alice needs to pay at least 100 tax to be eligible for role
//         // tax is set at 7% per transaction
//         // 100 tax = 100 / .07 = 1428
//         vm.prank(alice);
//         erc20TaxedMock.transfer(bob, 1430);

//         // act
//         vm.roll(0); // set blocknumber at genesis block
//         vm.expectRevert("No finished epoch yet.");
//         vm.prank(address(daoMock));
//         Law(roleByTaxPaid).executeLaw(
//             charlotte, // charlotte = initiator
//             lawCalldata,
//             keccak256("Alice requests role by tax paid")
//         );
//     }
// }

