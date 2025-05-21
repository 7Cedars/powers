// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
// import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
// import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// import { Powers} from "../../../src/Powers.sol";
// import { PowersEvents } from "../../../src/interfaces/PowersEvents.sol";
// import { Law } from "../../../src/Law.sol";
// import { ILaw } from "../../../src/interfaces/ILaw.sol";

// import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
// import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";
// import { Erc20TaxedMock } from "../../../test/mocks/Erc20TaxedMock.sol";
// import { StringsArray } from "../../../src/laws/state/StringsArray.sol";
// import { Grant } from "../../../src/laws/bespoke/governYourTax/Grant.sol";
// import { VoteOnAccounts } from "../../../src/laws/state/VoteOnAccounts.sol";
// import { NominateMe } from "../../../src/laws/state/NominateMe.sol";
// import { ElectionCall } from "../../../src/laws/electoral/ElectionCall.sol";

// import { TestSetupGovernYourTax_fuzzIntegration } from "../../../test/TestSetup.t.sol";
// import { HelperConfig } from "../../../script/HelperConfig.s.sol";

// contract GovernYourTax_fuzzIntegrationTest is TestSetupGovernYourTax_fuzzIntegration {
//     //////////////////////////////////////////////////////////////
//     //              CHAPTER 1: EXECUTIVE ACTIONS                //
//     //////////////////////////////////////////////////////////////

//     function testFuzz_GovernYourTax_CreateUseAndEndGrants(
//         uint256 seed,
//         uint256 step0Chance,
//         uint256 step1Chance
//     ) public {

//         // mint erc20 Tokens to organisation.
//         vm.prank(address(governYourTax));
//         Erc20TaxedMock(erc20TaxedMock).mint(1 * 10 ** 18);

//         seed = bound(seed, 250, 1000);
//         step0Chance = bound(step0Chance, 15, 100);
//         step1Chance = bound(step1Chance, 15, 100);

//         // assign roles
//         vm.startPrank(address(governYourTax));
//         governYourTax.assignRole(1, alice); // role 1s
//         governYourTax.assignRole(1, bob);
//         governYourTax.assignRole(1, charlotte);
//         governYourTax.assignRole(2, david); // role 2s
//         governYourTax.assignRole(2, eve);
//         governYourTax.assignRole(2, frank);
//         // grant council roles:
//         governYourTax.assignRole(uint32((seed % 3) + 4), gary); // assign role of grant council
//         governYourTax.assignRole(uint32((seed % 3) + 4), helen); // assign role of grant council
//         governYourTax.assignRole(uint32((seed % 3) + 4), ian); // assign role of grant council
//         governYourTax.assignRole(uint32((seed % 3) + 4), jacob); // assign role of grant council
//         governYourTax.assignRole(uint32((seed % 3) + 4), kate); // assign role of grant council
//         governYourTax.assignRole(uint32((seed % 3) + 4), lisa); // assign role of grant council
//         vm.stopPrank();

//         // step 0: create a grant
//         description = "Test grant";
//         lawCalldata = abi.encode(
//             "Test Grant1", // name
//             "This is a test grant.", // description
//             uint48(seed), // duration grant
//             seed, // budget grant max = 2000
//             erc20TaxedMock, // token address
//             uint32((seed % 3) + 4), // grant council
//             laws[0] // nominees
//         );

//         // Calculate future grant address. -- maybe place this in separate function. £todo
//         (,, bytes[] memory calldatasOut,) = Law(laws[1]).handleRequest(
//             eve, lawCalldata, nonce
//         );
//         bytes memory dataWithoutSelector = new bytes(calldatasOut[0].length - 4);
//         for (uint16 i = 0; i < (calldatasOut[0].length - 4); i++) {
//             dataWithoutSelector[i] = calldatasOut[0][i + 4];
//         }
//         address grantAddress = abi.decode(dataWithoutSelector, (address));

//         // making proposal
//         vm.prank(david); // has role 2
//         actionId = governYourTax.propose(laws[1], lawCalldata, description);
//         // voting on proposal
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(governYourTax)),
//             laws[1],
//             actionId,
//             users,
//             seed,
//             step0Chance
//         );

//         // step 0 results.
//         (quorum, succeedAt, votingPeriod,,,,,) = Law(laws[1]).conditions();
//         quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
//         voteSucceeded = roleCount * succeedAt <= forVote * 100;
//         // role forward in time.
//         vm.roll(block.number + votingPeriod + 1);
//         if (quorumReached && voteSucceeded) {
//             console.log("step 0 action: eve EXECUTES and creates new grant. Budget: ", seed);
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(
//                 eve, laws[1], lawCalldata, description
//                 );
//             vm.prank(eve);
//             governYourTax.execute(laws[1], lawCalldata, description);
//         } else {
//             vm.expectRevert();
//             vm.prank(eve);
//             governYourTax.execute(laws[1], lawCalldata, description);
//         }

//         // only continue if previous step passed and a grant has been created.
//         vm.assume(quorumReached && voteSucceeded);

//         // step 1: create proposal to request funds.
//         i = 0;
//         while (Powers(governYourTax).getActiveLaw(grantAddress) == true) {
//             i++;
//             console.log("Begin run: ", i);
//             description = string.concat("Request grant, request number ", Strings.toString(i));
//             bytes memory lawCalldataRequest = abi.encode(
//                 charlotte, // grantee
//                 grantAddress, // grant that is applied to
//                 seed % 350 // amount requested
//             );
//             // making proposal
//             vm.prank(charlotte); // has role 1
//             actionId = governYourTax.propose(laws[0], lawCalldataRequest, description);
//             // voting on proposal
//             (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//                 payable(address(governYourTax)),
//                 laws[0],
//                 actionId,
//                 users,
//                 seed,
//                 step1Chance
//             );
//             console.log("step 1 votes: ", againstVote, forVote, abstainVote);

//             // step 1 results.
//             (quorum, succeedAt, votingPeriod,,,,,) = Law(laws[0]).conditions();
//             console.log("step 1 config: ", quorum, succeedAt, votingPeriod);
//             quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
//             voteSucceeded = roleCount * succeedAt <= forVote * 100;
//             console.log("step 1 results: ", quorumReached, voteSucceeded);
//             // // role forward in time.
//             vm.roll(block.number + votingPeriod + 1);
//             if (quorumReached && voteSucceeded) { // at the fourth step budget will be exhausted.
//                 console.log("step 1 action: bob EXECUTES and thus formally proposes request to the grant");
//                 vm.expectEmit(true, false, false, false);
//                 emit PowersEvents.ActionRequested(
//                     bob,
//                     laws[0],
//                     lawCalldataRequest,
//                     description
//                     );
//                 vm.prank(bob); // has role 1
//                 governYourTax.execute(laws[0], lawCalldataRequest, description);
//             } else {
//                 vm.expectRevert();
//                 vm.prank(bob); // has role 1
//                 governYourTax.execute(laws[0], lawCalldataRequest, description);
//             }

//             // only continue if previous step passed and a grant has been created.
//             vm.assume(quorumReached && voteSucceeded);

//             // step 2: grant request gets assessed and (conditionally) executed
//             // making proposal
//             vm.prank(gary); // has role of grant (assigned above)
//             actionId = governYourTax.propose(grantAddress, lawCalldataRequest, description);
//             // voting on proposal
//             (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//                 payable(address(governYourTax)),
//                 grantAddress,
//                 actionId,
//                 users,
//                 seed,
//                 step1Chance
//             );
//             console.log("step 2 votes: ", againstVote, forVote, abstainVote);

//              // step 2 results.
//             (quorum, succeedAt, votingPeriod,,,,,) = Law(grantAddress).conditions();
//             console.log("step 2 config: ", quorum, succeedAt, votingPeriod);
//             quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
//             voteSucceeded = roleCount * succeedAt <= forVote * 100;
//             console.log("step 2 results: ", quorumReached, voteSucceeded, (seed % 350) * (i + 1));
//             // // role forward in time.
//             vm.roll(block.number + votingPeriod + 1);
//             if (
//                 quorumReached &&
//                 voteSucceeded &&
//                 (seed % 350) * i <= seed) { // at the fourth step budget will be exhausted.
//                 console.log("step 2 action: Helen EXECUTES and grants grant request, money should be transferred");
//                 vm.expectEmit(true, false, false, false);
//                 emit PowersEvents.ActionRequested(
//                     helen,
//                     grantAddress,
//                     lawCalldataRequest,
//                     description
//                     );
//                 vm.prank(helen); // has role 1
//                 governYourTax.execute(grantAddress, lawCalldataRequest, description);
//             } else {
//                 vm.expectRevert();
//                 vm.prank(helen); // has role 1
//                 governYourTax.execute(grantAddress, lawCalldataRequest, description);
//             }

//             // step 3: stopping grant
//             if (
//                 Grant(grantAddress).expiryBlock() < block.number ||
//                 Grant(grantAddress).budget() == Grant(grantAddress).spent()
//             ) {
//                 vm.expectEmit(true, false, false, false);
//                 emit PowersEvents.ActionRequested(
//                     eve,
//                     laws[2],
//                     lawCalldata,
//                     "Test grant"
//                     );
//                 vm.prank(eve); // has role 2
//                 governYourTax.execute(
//                     laws[2],
//                     lawCalldata,
//                     "Test grant"
//                     );
//             }
//         }
//     }

//   function  testFuzz_GovernYourTax_StopAndRestartLaws(
//         uint256 seed,
//         uint256 step0Chance,
//         uint256 step1Chance
//     ) public {
//         // mint erc20 Tokens to organisation.
//         vm.prank(address(governYourTax));
//         Erc20TaxedMock(erc20TaxedMock).mint(1 * 10 ** 18);

//         seed = bound(seed, 0, 100_000);
//         step0Chance = bound(step0Chance, 0, 100);
//         step1Chance = bound(step1Chance, 0, 100);

//         // assign roles
//         vm.startPrank(address(governYourTax));
//         governYourTax.assignRole(3, alice); // role 3s
//         governYourTax.assignRole(3, bob);
//         governYourTax.assignRole(3, charlotte);
//         governYourTax.assignRole(3, david); // role 2s
//         governYourTax.assignRole(3, eve);
//         vm.stopPrank();

//         // step 0: stop law
//         description = "Stopping an active law";

//         // check that we are not stopping the laws to stop or restart a law...
//         vm.assume(
//             laws[seed % laws.length] != laws[3] &&
//             laws[seed % laws.length] != laws[4]
//             );
//         lawCalldata = abi.encode(laws[seed % laws.length]);

//         // making proposal
//         vm.prank(alice); // has role 3
//         actionId = governYourTax.propose(laws[3], lawCalldata, description);
//         // voting on proposal
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(governYourTax)),
//             laws[3],
//             actionId,
//             users,
//             seed,
//             step0Chance
//         );

//         // step 0 results.
//         (quorum, succeedAt, votingPeriod,,,,,) = Law(laws[3]).conditions();
//         quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
//         voteSucceeded = roleCount * succeedAt <= forVote * 100;
//         // role forward in time.
//         vm.roll(block.number + votingPeriod + 1);
//         if (quorumReached && voteSucceeded) {
//             console.log("step 0 action: alice EXECUTES and stops law.");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(
//                 alice, laws[3], lawCalldata, description
//                 );
//             vm.prank(alice);
//             governYourTax.execute(laws[3], lawCalldata, description);
//         } else {
//             vm.expectRevert();
//             vm.prank(alice);
//             governYourTax.execute(laws[3], lawCalldata, description);
//         }

//         // only continue if law was actually stopped.
//         vm.assume(quorumReached && voteSucceeded);

//         // making proposal
//         vm.roll(block.number +  10);
//         vm.prank(charlotte); // has role 3
//         actionId = governYourTax.propose(
//             laws[4],
//             lawCalldata, // note: exact same lawCalldata as laws[3]
//             description // note: exact same description as laws[3]
//         );
//         // voting on proposal
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(governYourTax)),
//             laws[4],
//             actionId,
//             users,
//             seed,
//             step1Chance
//         );

//         // step 1 results.
//         (quorum, succeedAt, votingPeriod,,,,,) = Law(laws[4]).conditions();
//         quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
//         voteSucceeded = roleCount * succeedAt <= forVote * 100;
//         // role forward in time.
//         vm.roll(block.number + votingPeriod + 1);
//         if (quorumReached && voteSucceeded) {
//             console.log("step 1 action: bob EXECUTES and restarts law.");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(
//                 bob, laws[4], lawCalldata, description
//                 );
//             vm.prank(bob);
//             governYourTax.execute(laws[4], lawCalldata, description);
//         } else {
//             vm.expectRevert();
//             vm.prank(bob);
//             governYourTax.execute(laws[4], lawCalldata, description);
//         }
//     }

//     function testFuzz_MintAndBurnTokens(
//             uint256 seed,
//             uint256 mintQuantity,
//             uint256 burnQuantity,
//             uint256 mintingChance,
//             uint256 burningChance
//         ) public {
//         // mint erc20 Tokens to organisation.
//         vm.prank(address(governYourTax));
//         Erc20TaxedMock(erc20TaxedMock).mint(100_000);
//         uint256 tokensMinted;
//         uint256 tokensBurned;

//         seed = bound(seed, 0, 10_000);
//         mintQuantity = bound(mintQuantity, 1, 10_000);
//         burnQuantity = bound(burnQuantity, 1, 10_000);
//         mintingChance = bound(mintingChance, 0, 100);
//         burningChance = bound(burningChance, 0, 100);

//         // assign roles
//         vm.startPrank(address(governYourTax));
//         for (i; i < users.length; i++) {
//             governYourTax.assignRole(2, users[i]);
//         }
//         vm.stopPrank();

//         // step 0: mint tokens
//         description = "Minting ERC20 tokens.";

//         // making proposal
//         vm.prank(alice); // has role 2
//         actionId = governYourTax.propose(laws[5], abi.encode(mintQuantity), description);
//         // voting on proposal
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(governYourTax)),
//             laws[5],
//             actionId,
//             users,
//             seed,
//             mintingChance
//         );

//         // step 0 results.
//         (quorum, succeedAt, votingPeriod,,,,,) = Law(laws[5]).conditions();
//         quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
//         voteSucceeded = roleCount * succeedAt <= forVote * 100;
//         // role forward in time.
//         vm.roll(block.number + votingPeriod + 1);
//         if (quorumReached && voteSucceeded) {
//             console.log("step 0 action: alice EXECUTES and mints tokens.");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(
//                 alice, laws[5], abi.encode(mintQuantity), description
//                 );
//             vm.prank(alice);
//             governYourTax.execute(laws[5], abi.encode(mintQuantity), description);
//             tokensMinted = tokensMinted + mintQuantity;
//         } else {
//             vm.expectRevert();
//             vm.prank(alice);
//             governYourTax.execute(laws[5], abi.encode(mintQuantity), description);
//         }

//         // step 1: burn tokens
//         description = "Burning ERC20 tokens.";
//         // making proposal
//         vm.prank(charlotte); // has role 3
//         actionId = governYourTax.propose(
//             laws[6],
//             abi.encode(burnQuantity),
//             description
//         );
//         // voting on proposal
//         (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
//             payable(address(governYourTax)),
//             laws[6],
//             actionId,
//             users,
//             seed,
//             burningChance
//         );

//         // step 1 results.
//         (quorum, succeedAt, votingPeriod,,,,,) = Law(laws[6]).conditions();
//         quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
//         voteSucceeded = roleCount * succeedAt <= forVote * 100;
//         // role forward in time.
//         vm.roll(block.number + votingPeriod + 1);
//         if (
//             quorumReached &&
//             voteSucceeded &&
//             Erc20TaxedMock(
//                 erc20TaxedMock
//                 ).balanceOf(address(governYourTax)) - burnQuantity > 0
//             ) {
//             console.log("step 1 action: bob EXECUTES and burns tokens.");
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(
//                 bob, laws[6], abi.encode(burnQuantity), description
//                 );
//             vm.prank(bob);
//             governYourTax.execute(laws[6], abi.encode(burnQuantity), description);
//             tokensBurned = tokensBurned + burnQuantity;
//         } else {
//             vm.expectRevert();
//             vm.prank(bob);
//             governYourTax.execute(laws[6], abi.encode(burnQuantity), description);
//         }

//         console.log("burned, minted tokens: ", tokensBurned, tokensMinted);

//         assertEq(
//             Erc20TaxedMock(erc20TaxedMock).balanceOf(address(governYourTax)),
//             100_000 - tokensBurned + tokensMinted
//         );
//     }

//     // //////////////////////////////////////////////////////////////
//     // //              CHAPTER 2: ELECT ROLES                      //
//     // //////////////////////////////////////////////////////////////
//     function testFuzz_GovernYourTax_ClaimRoleByTax(
//             uint256 seed,
//             uint256 mintQuantity,
//             uint256 burnQuantity,
//             uint256 mintingChance,
//             uint256 burningChance
//         ) public {
//         // mint erc20 Tokens to organisation.
//         vm.prank(address(governYourTax));
//         Erc20TaxedMock(erc20TaxedMock).mint(10 * 10 ** 18);

//         // distribute tokens to users, each users get 100_000
//         for (i; i < users.length; i++) {
//             vm.prank(address(governYourTax));
//             Erc20TaxedMock(erc20TaxedMock).transfer(users[i], 100_000);
//         }
//         // we do a hundred transactions, let users pay tax

//         uint256 currentSeed;
//         for (i; i < 100; i++) {
//             address currentUser = users[currentSeed % users.length];
//             if (currentSeed < 100) {
//                 currentSeed = seed;
//             } else {
//                 currentSeed = currentSeed / 10;
//             }
//             vm.prank(currentUser);
//             Erc20TaxedMock(erc20TaxedMock).transfer(
//                 users[(currentSeed / 5) % users.length],
//                 currentSeed % 250
//             );
//             taxPaid[currentUser] += ((currentSeed % 250) * 10) / 100; // == taxPaid
//             console.log("taxPaid so far: ", taxPaid[currentUser]);
//         }

//         // let users claim - outcome conditional.
//         i = 0;
//         vm.roll(block.number + 25 + 1); // 25 is 1 epoch
//         for (i; i < users.length; i++) {
//             description = "claiming role!";
//             lawCalldata = abi.encode(false, users[i]);
//             if (taxPaid[users[i]] >= 100) { // threshold set when deploying law
//                 console.log("action: user claims role.");
//                 vm.expectEmit(true, false, false, false);
//                 emit PowersEvents.ActionRequested(
//                     users[i], laws[7], lawCalldata, description
//                     );
//                 vm.prank(users[i]);
//                 governYourTax.execute(laws[7], lawCalldata, description);
//             } else {
//                 console.log("action: user is not claiming role.");
//                 vm.expectRevert();
//                 vm.prank(users[i]);
//                 governYourTax.execute(laws[7], lawCalldata, description);
//             }
//         }
//     }

//     function  testFuzz_GovernYourTax_CallAndTallyGovernorElections(
//         uint256 seed1,
//         uint256 seed2,
//         uint256 step0Chance,
//         uint256 step1Chance
//     ) public {
//         // mint erc20 Tokens to organisation.
//         vm.prank(address(governYourTax));
//         Erc20TaxedMock(erc20TaxedMock).mint(1 * 10 ** 18);

//         seed1 = bound(seed1, 1 * 10 ** 18, 100 * 10 ** 18);
//         seed2 = bound(seed2, 1 * 10 ** 18, 100 * 10 ** 18);
//         step0Chance = bound(step0Chance, 15, 100);
//         step1Chance = bound(step1Chance, 15, 100);

//         // assign roles
//         vm.startPrank(address(governYourTax));
//         governYourTax.assignRole(3, alice); // alice is member of the security council.
//         vm.stopPrank();

//         // assign role admin, 1s, 2s + if not assigned role 2, nominate for role 2
//         vm.prank(address(governYourTax));
//         governYourTax.assignRole(0, alice); // alice is assigned as admin
//         for (i; i < users.length; i++) {
//             vm.prank(address(governYourTax));
//             governYourTax.assignRole(1, users[i]);
//             if (i < 5) {
//                 vm.prank(address(governYourTax));
//                 governYourTax.assignRole(2, users[i]);
//             } else {
//                 vm.prank(users[i]);
//                 governYourTax.execute(
//                     laws[8],
//                     abi.encode(true),
//                     string.concat("Nominating for role 2, user ", Strings.toString(i))
//                     );
//             }
//         }

//         // step 1: alice, as member of the security council, calls an election.
//         description = "Alice calls an election.";
//         lawCalldata = abi.encode(
//             "This is a test election.", // description of the actual election.
//             uint48(block.number + 1), // start vote
//             uint48(block.number + 100) // end vote.
//         );
//         vm.prank(alice); // = security
//         governYourTax.execute(laws[9], lawCalldata, description);

//         address electionVotesAddress = ElectionCall(laws[9]).getVoteOnAccountsAddress(
//             1, // voter role id
//             laws[8], // nominees
//             uint48(block.number + 1), // start vote
//             uint48(block.number + 100), // end vote
//             "This is a test election."
//         );

//         // step 2: users vote in election
//         uint256 currentSeed1;
//         uint256 currentSeed2;
//         for (uint256 i = 0; i < 25; i++) { // 25 votes will be tried to cast
//             // set randomiser..
//             if (currentSeed1 < 10) {
//                 currentSeed1 = seed1;
//             } else {
//                 currentSeed1 = currentSeed1 / 10;
//             }
//             if (currentSeed2 < 10) {
//                 currentSeed2 = seed2;
//             } else {
//                 currentSeed2 = currentSeed2 / 10;
//             }
//             address votingUser = users[currentSeed1 % users.length];
//             address userReceivingVote = users[currentSeed2 % users.length];
//             description = string.concat("Voting on user. Round ", Strings.toString(i));
//             vm.warp(currentSeed1 & 250);

//             if (
//                 governYourTax.canCallLaw(votingUser, electionVotesAddress) &&
//                 !hasVoted[votingUser] &&
//                 NominateMe(laws[8]).nominees(userReceivingVote) != 0 &&
//                 block.number > VoteOnAccounts(electionVotesAddress).startVote() &&
//                 block.number < VoteOnAccounts(electionVotesAddress).endVote()
//             ) {
//                 console.log("action: user is voting.");
//                 vm.expectEmit(true, false, false, false);
//                 emit PowersEvents.ActionRequested(
//                     votingUser,
//                     electionVotesAddress,
//                     abi.encode(userReceivingVote),
//                     description
//                     );
//                 vm.prank(votingUser);
//                 governYourTax.execute(
//                     electionVotesAddress,
//                     abi.encode(userReceivingVote),
//                     description
//                     );
//                 votesReceived[userReceivingVote]++;
//                 hasVoted[votingUser] = true;
//             } else {
//                 console.log("action: user tries to vote but should revert.");
//                 vm.expectRevert();
//                 vm.prank(votingUser);
//                 governYourTax.execute(
//                     electionVotesAddress,
//                     abi.encode(userReceivingVote),
//                     description
//                     );
//             }
//         }

//         // step 2: tally election - see if correct people have been assigned.
//         description = "Alice calls an election.";
//         vm.warp((seed1 + seed2) % 200); // should succeed in about 50% of runs.
//         console.log("block number: ", block.number);
//         if ( block.number >= VoteOnAccounts(electionVotesAddress).endVote() ) {
//             vm.expectEmit(true, false, false, false);
//             emit PowersEvents.ActionRequested(
//                 alice, // has role 1
//                 laws[10],
//                 lawCalldata,
//                 description
//                 );
//             vm.prank(alice);
//             governYourTax.execute(
//                     laws[10],
//                     lawCalldata,
//                     description
//                     );
//             } else {
//                 vm.expectRevert();
//                 vm.prank(alice);
//                 governYourTax.execute(
//                     laws[10],
//                     lawCalldata,
//                     description
//                     );
//             }

//         // only continue if tally law was called.
//         vm.assume( block.number > VoteOnAccounts(electionVotesAddress).endVote() );

//         uint256 numNominees = NominateMe(laws[8]).nomineesCount();
//         for (uint256 i = 0; i < numNominees; i++) {
//             for (uint256 j = 0; j < numNominees; j++) {
//                 address nominee = NominateMe(laws[8]).nomineesSorted(i);
//                 address nominee2 = NominateMe(laws[8]).nomineesSorted(j);
//                 if (governYourTax.hasRoleSince(nominee, 3) != 0 && governYourTax.hasRoleSince(nominee2, 3) == 0) {
//                     assertGe(votesReceived[nominee], votesReceived[nominee2]); // assert that nominee has more tokens than nominee2.
//                 }
//                 if (governYourTax.hasRoleSince(nominee, 3) == 0 && governYourTax.hasRoleSince(nominee2, 3) != 0) {
//                     assertLe(votesReceived[nominee], votesReceived[nominee2]); // assert that nominee has fewer tokens than nominee2.
//                 }
//             }
//         }
//     }
// }
