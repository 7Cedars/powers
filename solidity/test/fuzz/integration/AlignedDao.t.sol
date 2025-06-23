// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
// import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// import { Powers} from "../../../src/Powers.sol";
// import { PowersEvents } from "../../../src/interfaces/PowersEvents.sol";
// import { Law } from "../../../src/Law.sol";
// import { ILaw } from "../../../src/interfaces/ILaw.sol";

// import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
// import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";
// import { Erc20VotesMock } from "../../../test/mocks/Erc20VotesMock.sol";
// import { Erc20TaxedMock } from "../../../test/mocks/Erc20TaxedMock.sol";
// import { StringsArray } from "../../../src/laws/state/StringsArray.sol";

// import { TestSetupAlignedDao_fuzzIntegration } from "../../../test/TestSetup.t.sol";
// import { HelperConfig } from "../../../script/HelperConfig.s.sol";

// contract AlignedDao_fuzzIntegrationTest is TestSetupAlignedDao_fuzzIntegration {
//     //////////////////////////////////////////////////////////////
//     //              CHAPTER 1: EXECUTIVE ACTIONS                //
//     //////////////////////////////////////////////////////////////
//     function testFuzz_AlignedDao_ProposeAndAdoptValues(
//          uint256 step1,
//          uint256 step2
//     ) public {
//         uint256 step1Chance = bound(step1, 0, 100);
//         uint256 step2Chance = bound(step2, 0, 100);
//         uint256 seed = 530975438721; // additional randomiser
//         uint256 numberOfValuesBefore = StringsArray(laws[1]).numberOfStrings();
//         // need to check adopted strings before?
//         bool[] memory stepsPassed = new bool[](2);

//         vm.startPrank(address(alignedDao));
//         alignedDao.assignRole(0, alice); // ADMIN ROLE
//         alignedDao.assignRole(1, bob); // role 1s
//         alignedDao.assignRole(1, charlotte);
//         alignedDao.assignRole(1, david);
//         alignedDao.assignRole(1, eve);
//         alignedDao.assignRole(1, frank);
//         alignedDao.assignRole(2, gary); // role 2s
//         alignedDao.assignRole(2, helen);
//         vm.stopPrank();

//         // step 0 action: propose a new value.
//         string memory newValue = "Be nice";
//         bool add = true;

//         lawCalldata = abi.encode("Be nice", true); // velue = "Be nice", add = true
//         description = "Propose to add `Be nice` to the list of values of the Dao.";
//         vm.prank(bob); // has role 1.
//         actionId = alignedDao.propose(laws[0], lawCalldata, description);

//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(alignedDao)),
//             laws[0],
//             actionId,
//             users,
//             seed,
//             step1Chance
//         );

//         // step 0 results.
//         (quorum, succeedAt, votingPeriod,,,,,) = Law(laws[0]).conditions();
//         quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
//         voteSucceeded = forVote * 100 / roleCount > succeedAt;
//         stepsPassed[0] = quorumReached && voteSucceeded;
//         // // role forward in time.
//         vm.roll(block.number + votingPeriod + 1);
//         if (stepsPassed[0]) {
//             console.log("step 0 action: Bob EXECUTES and thus formally proposes new value!");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(bob, laws[0], lawCalldata, description);
//             vm.prank(bob);
//             alignedDao.execute(laws[0], lawCalldata, description);
//         }

//         // // only resume if first proposal passed
//         vm.assume(stepsPassed[0]);
//         // step 1 action: propose and vote on newly accepted proposed value.
//         vm.prank(gary); // has role 2.
//         actionId = alignedDao.propose(laws[1], lawCalldata, description);

//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(alignedDao)),
//             laws[1],
//             actionId,
//             users,
//             seed,
//             step2Chance
//         );

//         // step 1 results.
//         (quorum, succeedAt, votingPeriod,,, delayExecution,,) = Law(laws[1]).conditions();
//         quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
//         voteSucceeded = forVote * 100 / roleCount > succeedAt;
//         stepsPassed[1] = quorumReached && voteSucceeded;
//         vm.roll(block.number + votingPeriod + delayExecution + 1);
//         console.log("step 1 result: quorum reached and vote succeeded?");
//         console.log(quorumReached, voteSucceeded);

//         // // step 2: conditional execute of proposal
//         if (stepsPassed[1]) {
//             console.log("step 1 action: ACTION WILL BE EXECUTED");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(gary, laws[1], lawCalldata, description);
//             vm.prank(gary); // has role 1
//             alignedDao.execute(laws[1], lawCalldata, description);
//             uint256 numberOfValuesAfter = StringsArray(laws[1]).numberOfStrings();
//             assertEq(numberOfValuesAfter, numberOfValuesBefore + 1);
//         } else {
//             vm.expectRevert();
//             vm.prank(gary);
//             alignedDao.execute(laws[1], lawCalldata, description);
//             uint256 numberOfValuesAfter = StringsArray(laws[1]).numberOfStrings();
//             assertEq(numberOfValuesAfter, numberOfValuesBefore);
//         }
//     }

//     function testFuzz_AlignedDao_RevokeAndReinstateMembership(
//         uint256 step0,
//         uint256 step1,
//         uint256 step2,
//         uint256 seed
//     ) public {
//         uint256 step0Chance = bound(step0, 0, 100);
//         uint256 step1Chance = bound(step1, 0, 100);
//         uint256 step2Chance = bound(step2, 0, 100);
//         uint256 seed = bound(seed, 100, 100_000);
//         bool[] memory stepsPassed = new bool[](3);

//         // give everyone a NFT. Note: NftId == index of user.
//         for (uint256 i = 0; i < users.length; i++) {
//             vm.startPrank(users[i]);
//             erc721Mock.cheatMint(i);
//             vm.stopPrank();
//         }
//         // assign roles.
//         vm.startPrank(address(alignedDao));
//         alignedDao.assignRole(1, alice); // role 1s
//         alignedDao.assignRole(1, bob);
//         alignedDao.assignRole(1, charlotte);
//         alignedDao.assignRole(2, david); // role 2s
//         alignedDao.assignRole(2, eve);
//         alignedDao.assignRole(3, frank); // role 3s
//         alignedDao.assignRole(3, gary);
//         alignedDao.assignRole(3, helen);
//         vm.stopPrank();

//         // step 0 action: propose to revoke membership.
//         uint256 index = seed % 3;  // choose one of the users that has role 1.
//         lawCalldata = abi.encode(index, users[index]); // tokenId, address
//         description = "Propose to revoke a users membership.";
//         vm.prank(frank); // has role 3.
//         actionId = alignedDao.propose(
//             laws[2], // = RevokeMembership
//             lawCalldata,
//             description
//         );
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(alignedDao)),
//             laws[2],
//             actionId,
//             users,
//             seed,
//             step0Chance
//         );
//         console.log("step 0 votes: roleCount, againstVote, forVote, abstainVote");
//         console.log(roleCount, againstVote, forVote, abstainVote);

//         // step 0 results
//         (quorum, succeedAt, votingPeriod,,, delayExecution,,) = Law(laws[2]).conditions();
//         quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
//         voteSucceeded = roleCount * succeedAt <= forVote * 100;
//         stepsPassed[0] = quorumReached && voteSucceeded;
//         vm.roll(block.number + votingPeriod + delayExecution + 1);
//         console.log("step 0 result: quorum reached and vote succeeded?");
//         console.log(quorumReached, voteSucceeded);
//         if (stepsPassed[0]) {
//             console.log("step 0 action: Frank EXECUTES and thus revokes membership!");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(frank, laws[2], lawCalldata, description);
//             vm.prank(frank);
//             alignedDao.execute(laws[2], lawCalldata, description);
//         } else {
//             vm.expectRevert();
//             vm.prank(frank);
//             alignedDao.execute(laws[2], lawCalldata, description);
//         }

//         // only continue if previous step passed.
//         vm.assume(stepsPassed[0]);

//         // step 1: challenge revoke of membership.
//         // NB: we do not know if Alice has had her role revoked, hence we need to select another person if she had.
//         bool aliceCanCall = Powers(alignedDao).canCallLaw(alice, laws[3]);
//         address caller;
//         if (!aliceCanCall) {
//             caller = bob;
//         } else {
//             caller = alice;
//         }
//         // has role 1.
//         vm.prank(caller);
//         actionId = alignedDao.propose(
//             laws[3], // = StatementOfIntent (reinstate membership)
//             lawCalldata, // note: same lawCalldata as step 0.
//             description // note: same description as step 0.
//         );
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(alignedDao)),
//             laws[3],
//             actionId,
//             users,
//             seed,
//             step1Chance
//         );

//         // step 1 results
//         (quorum, succeedAt, votingPeriod,,, delayExecution,,) = Law(laws[3]).conditions();
//         quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
//         voteSucceeded = forVote * 100 / roleCount > succeedAt;
//         stepsPassed[1] = quorumReached && voteSucceeded;
//         vm.roll(block.number + votingPeriod + delayExecution + 1);
//         console.log("step 1 result: quorum reached and vote succeeded?");
//         console.log(quorumReached, voteSucceeded);
//         if (stepsPassed[1]) {
//             console.log("step 1 action: caller EXECUTES and thus formalises challenge to revoke!");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(caller, laws[3], lawCalldata, description);
//             vm.prank(caller);
//             alignedDao.execute(laws[3], lawCalldata, description);
//         } else {
//             vm.expectRevert();
//             vm.prank(caller);
//             alignedDao.execute(laws[3], lawCalldata, description);
//         }

//         // only continue if previous step passed.
//         vm.assume(stepsPassed[1]);

//         // step 2: accept challenge and reinstate membership.
//         vm.prank(david); // has role 2.
//         actionId = alignedDao.propose(
//             laws[4], // = StatementOfIntent (reinstate membership)
//             lawCalldata, // note: same lawCalldata as step 0.
//             description // note: same description as step 0.
//         );
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(alignedDao)),
//             laws[4],
//             actionId,
//             users,
//             seed,
//             step2Chance
//         );

//         // step 2 results
//         (quorum, succeedAt, votingPeriod,,, delayExecution,,) = Law(laws[4]).conditions();
//         quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
//         voteSucceeded = forVote * 100 / roleCount > succeedAt;
//         stepsPassed[2] = quorumReached && voteSucceeded;
//         vm.roll(block.number + votingPeriod + delayExecution + 1);
//         console.log("step 2 result: quorum reached and vote succeeded?");
//         console.log(quorumReached, voteSucceeded);
//         if (stepsPassed[2]) {
//             console.log("step 2 action: david EXECUTES and reinstates membership!");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(david, laws[4], lawCalldata, description);
//             vm.prank(david);
//             alignedDao.execute(laws[4], lawCalldata, description);
//         } else {
//             vm.expectRevert();
//             vm.prank(david);
//             alignedDao.execute(laws[4], lawCalldata, description);
//         }

//         if (stepsPassed[0] && stepsPassed[1] && stepsPassed[2] ) {
//             assertEq(Powers(alignedDao).hasRoleSince(users[index], 1), block.number);
//         }
//     }

//     function testFuzz_AlignedDao_MembersRequestPayment(
//         uint256 selectUser,
//         uint256 duration,
//         uint256 numberSteps
//     ) public {
//         selectUser = bound(selectUser, 0, users.length - 1);
//         duration = bound(duration, 200, 1000);
//         numberSteps = bound(numberSteps, 5, 100);
//         uint256 balanceBefore = Erc20TaxedMock(erc20TaxedMock).balanceOf(users[selectUser]);

//         // mint funds
//         vm.prank(address(alignedDao));
//         Erc20TaxedMock(erc20TaxedMock).mint(1 * 10 ** 18);

//         // assign roles.
//         vm.startPrank(address(alignedDao));
//         alignedDao.assignRole(1, alice); // role 1s
//         alignedDao.assignRole(1, bob);
//         alignedDao.assignRole(1, charlotte);
//         alignedDao.assignRole(1, david);
//         alignedDao.assignRole(1, eve);
//         alignedDao.assignRole(1, frank);
//         alignedDao.assignRole(1, gary);
//         alignedDao.assignRole(1, helen);
//         vm.stopPrank();

//         // fuzz requests
//         // Note that also with user that is not allowed to call law, we keep on trying..
//         uint256 lastValidRequestAt;
//         uint256 numberRequests;
//         bool canCallLaw = Powers(alignedDao).canCallLaw(users[selectUser], laws[5]);
//         for (uint256 i = 0; i < numberSteps; i++) {
//            vm.roll(block.number + duration);
//            string memory description = string.concat("request payment at block: ", Strings.toString(block.number));
//            if (canCallLaw && block.number >= lastValidRequestAt + 300) { // 2000 is duration as set in law.
//                 vm.expectEmit(true, false, false, false);
//                 emit PowersEvents.ActionRequested(
//                     users[selectUser],
//                     laws[5],
//                     abi.encode(),
//                     description
//                 );
//                 vm.prank(users[selectUser]);
//                 alignedDao.execute(laws[5], abi.encode(), description);
//                 lastValidRequestAt = block.number;
//                 numberRequests++;
//            } else {
//                 vm.expectRevert();
//                 vm.prank(users[selectUser]);
//                 alignedDao.execute(laws[5], abi.encode(), description);
//            }
//         }
//         uint256 balanceAfter = Erc20TaxedMock(erc20TaxedMock).balanceOf(users[selectUser]);
//         assertEq(balanceAfter, balanceBefore + (numberRequests * 5000)); // = number tokens per request
//     }

//     //////////////////////////////////////////////////////////////
//     //              CHAPTER 2: ELECT ROLES                      //
//     //////////////////////////////////////////////////////////////
//     function testFuzz_AlignedDao_SelfSelectRoleWithNft(
//         uint256 seed,
//         uint256 density
//     ) public {
//         density = bound(density, 0, 100);
//         // step 0: distribute nfts. NFTs are distributed randomly.
//         distributeNFTs(address(erc721Mock), users, seed, density);

//         // step 1: assert that only accounts with an NFT can claim role.
//         for (uint256 i = 0; i < users.length; i++) {
//             bool hasNFT = erc721Mock.balanceOf(users[i]) > 0; // does user have NFT?
//             string memory description = string.concat("Account claims role: ", Strings.toString(i));

//             if (hasNFT) {
//                 vm.expectEmit(true, false, false, false);
//                 emit PowersEvents.ActionRequested(users[i], laws[6], abi.encode(), description);
//                 vm.prank(users[i]);
//                 alignedDao.execute(laws[6], abi.encode(false), description);
//             } else {
//                 vm.expectRevert();
//                 vm.prank(users[i]);
//                 alignedDao.execute(laws[6], abi.encode(false), description);
//             }
//         }
//     }

//     function testFuzz_AlignedDao_DelegateElect(uint256 numNominees, uint256 voteTokensRandomiser) public {
//         numNominees = bound(numNominees, 4, 10);
//         voteTokensRandomiser = bound(voteTokensRandomiser, 100_000, type(uint256).max);

//         address oracle = makeAddr("oracle");
//         vm.startPrank(address(alignedDao));
//         alignedDao.assignRole(0, alice); // alice is assigned ADMIN ROLE
//         alignedDao.assignRole(1, alice); // role 1s
//         alignedDao.assignRole(3, bob);  // role 2s
//         alignedDao.assignRole(3, charlotte);
//         alignedDao.assignRole(3, david);
//         alignedDao.assignRole(3, eve);
//         vm.stopPrank();

//         // step 0a: distribute tokens. Tokens are distributed randomly.
//         distributeERC20VoteTokens(users, voteTokensRandomiser);
//         // step 0b: set oracle address

//          // Admin proposes oracle
//         vm.prank(alice); // alice = admin.
//         alignedDao.execute(laws[11], abi.encode(false, oracle), "Let's set an oracle.");
//         // Members accept oracle
//         vm.prank(bob);
//         actionId = alignedDao.propose(laws[12], abi.encode(false, oracle), "Let's set an oracle.");
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(alignedDao)),
//             laws[12],
//             actionId,
//             users,
//             1234,
//             99 // chance of passing vote.
//         );
//         // executing: setting oracle.
//         vm.roll(block.number + 200);
//         vm.prank(bob);
//         alignedDao.execute(laws[12], abi.encode(false, oracle), "Let's set an oracle.");

//         // now to the actual election...
//         // step 1: people nominate their accounts.
//         bytes memory lawCalldataNominate = abi.encode(true); // nominateMe = true

//         for (uint256 i = 0; i < numNominees; i++) {
//             vm.prank(users[i]);
//             alignedDao.execute(
//                  laws[7], lawCalldataNominate, string.concat("Account nominates themselves: ", Strings.toString(i))
//             );
//         }
//         // step 2: run election.
//         bytes memory lawCalldataElect = abi.encode(); // empty calldata
//         vm.prank(oracle);
//         alignedDao.execute(laws[8], lawCalldataElect, "The oracle executes an election.");

//         // step 3: assert that the elected accounts are correct.
//         for (uint256 i = 0; i < numNominees; i++) {
//             for (uint256 j = 0; j < numNominees; j++) {
//                 address nominee = users[i];
//                 address nominee2 = users[j];
//                 if (alignedDao.hasRoleSince(nominee, 2) != 0 && alignedDao.hasRoleSince(nominee2, 2) == 0) {
//                     uint256 balanceNominee = Erc20VotesMock(address(erc20VotesMock)).balanceOf(nominee);
//                     uint256 balanceNominee2 = Erc20VotesMock(address(erc20VotesMock)).balanceOf(nominee2);
//                     assertGe(balanceNominee, balanceNominee2); // assert that nominee has more tokens than nominee2.
//                 }
//                 if (alignedDao.hasRoleSince(nominee, 2) == 0 && alignedDao.hasRoleSince(nominee2, 2) != 0) {
//                     uint256 balanceNominee = Erc20VotesMock(address(erc20VotesMock)).balanceOf(nominee);
//                     uint256 balanceNominee2 = Erc20VotesMock(address(erc20VotesMock)).balanceOf(nominee2);
//                     assertLe(balanceNominee, balanceNominee2); // assert that nominee has fewer tokens than nominee2.
//                 }
//             }
//         }
//     }

//     function testFuzz_AlignedDao_PeerSelect(
//         uint256 succeedPassChance
//     ) public {
//         succeedPassChance = bound(succeedPassChance, 0, 100);

//         // assigning necessary roles.
//         vm.startPrank(address(alignedDao));
//         alignedDao.assignRole(3, alice);
//         alignedDao.assignRole(3, bob);
//         alignedDao.assignRole(3, charlotte);
//         alignedDao.assignRole(3, david);
//         vm.stopPrank();

//         // step 1: people nominate their accounts.
//         uint256 numNominees;
//         for (uint256 i = 0; i < users.length; i++) {
//             if (alignedDao.hasRoleSince(users[i], 1) == 0) {
//                 vm.prank(users[i]);
//                 alignedDao.execute(
//                      laws[9], abi.encode(true), string.concat("Account nominates themself", Strings.toString(i))
//                 );
//             }
//             numNominees++;
//         }

//         // step 2: propose action and run election.
//         bytes memory lawCalldataSelect = abi.encode(0, false); // = revoke = false
//         string memory descriptionSelect = "Elect an account to role 3.";
//         vm.prank(charlotte); // already has role 3.
//         uint256 actionId = alignedDao.propose(laws[10], lawCalldataSelect, descriptionSelect);

//         (uint256 roleCount, uint256 againstVote, uint256 forVote, uint256 abstainVote) = voteOnProposal(
//             payable(address(alignedDao)),
//             laws[10],
//             actionId,
//             users,
//             243432432,
//             succeedPassChance
//         );

//         // step 3:  assert that the elected accounts are correct.
//         (uint8 quorum, uint8 succeedAt, uint32 votingPeriod,,,,,) = Law(laws[10]).conditions();
//         bool quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
//         bool succeeded = forVote * 100 / roleCount > succeedAt;

//         vm.roll(block.number + votingPeriod + 1);
//         console.log(uint8(alignedDao.state(actionId)));
//         if (quorumReached && succeeded) {
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(alice, laws[10], lawCalldataSelect, descriptionSelect);
//             vm.prank(alice);
//             alignedDao.execute(laws[10], lawCalldataSelect, descriptionSelect);
//         } else {
//             vm.expectRevert();
//             vm.prank(alice);
//             alignedDao.execute(laws[10], lawCalldataSelect, descriptionSelect);
//         }
//     }
// }
