// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Powers} from "../../src/Powers.sol";
import { IPowers } from "../../src/interfaces/IPowers.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";
import { PowersEvents } from "../../src/interfaces/PowersEvents.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";

import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";

import { TestSetupPowers101 } from "../../test/TestSetup.t.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";

contract Powers101_fuzzIntegrationTest is TestSetupPowers101 {
    //////////////////////////////////////////////////////////////
    //         GOVERNANCE PATH 1: EXECUTE AN ACTION             //
    //////////////////////////////////////////////////////////////

    function testFuzzPowers101_ExecuteAction(
        uint256 step0Chance,
        uint256 step1Chance,
        uint256 step2Chance
    ) public {
        console.log("WAYPOINT 0");

        step0Chance = bound(step0Chance, 0, 100);
        step1Chance = bound(step1Chance, 0, 100);
        step2Chance = bound(step2Chance, 0, 100);
        uint256 balanceBefore = Erc20Taxed(mockAddresses[1]).balanceOf(address(daoMock));
        uint256 seed = 9034273427;
        uint256 amountToMint = 123 * 10**18;
        PowersTypes.ActionState actionState;

        bool[] memory stepsPassed = new bool[](3);

        console.log("WAYPOINT 1");

        // step 0 action: mint tokens at Erc20Taxed mock.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = mockAddresses[1]; // Erc20Taxed mock
        calldatas[0] = abi.encodeWithSelector(Erc20Taxed.mint.selector, amountToMint);

        console.log("WAYPOINT 2");

        lawId = 4; // statement of intent.  = roleId 1 
        lawCalldata = abi.encode(targets, values, calldatas); // 
        description = string.concat("Propose minting ", Strings.toString(amountToMint), "ETH in coins to the daoMock");
        
        console.log("WAYPOINT 3");

        console.log("step 0 action: BOB EXECUTES!"); // alice == admin.         
        vm.prank(bob); // has role 1.
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
        conditions = daoMock.getConditions(lawId);

        console.log("WAYPOINT 4");

        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(daoMock)),
            lawId,
            actionId,
            users,
            seed,
            step0Chance
        );

        console.log("WAYPOINT 5");

        // step 0 results.
        vm.roll(block.number + conditions.votingPeriod + 1);
        actionState = daoMock.getActionState(actionId);
        stepsPassed[0] = actionState == PowersTypes.ActionState.Succeeded;
        if (stepsPassed[0]) {
            console.log("step 1 action: BOB EXECUTES!"); // bob == role 1. 
            vm.expectEmit(true, false, false, false);
            emit PowersEvents.ActionRequested(bob, lawId, lawCalldata, nonce, description);
            vm.prank(bob);
            daoMock.request(lawId, lawCalldata, nonce, description);
        }
        actionState = daoMock.getActionState(actionId);
        stepsPassed[0] = actionState == PowersTypes.ActionState.Fulfilled;

        console.log("WAYPOINT 6"); 

        // step 1 action: cast veto?.
        lawId = 5; // veto law.  = roleId 2
        if (stepsPassed[0] && step1Chance > 50) { // 50% chance of veto.
            console.log("step 2 action: ALICE CASTS VETO!"); // alice == admin. 
            vm.expectEmit(true, false, false, false);
            emit PowersEvents.ActionRequested(alice, lawId, lawCalldata, nonce, description);
            vm.prank(alice); // has admin role. Note: no voting.
            actionId = daoMock.request(lawId, lawCalldata, nonce, description);

            // step 1 results.
            actionState = daoMock.getActionState(actionId);
            console.log("step 2 result: proposal vetoState: ", uint8(actionState));
        } else if (stepsPassed[0]) {
            console.log("step 2 action: ALICE DOES NOT CASTS VETO!");
            stepsPassed[1] = true;
        }

        console.log("WAYPOINT 8");

        // step 2 action: propose and vote on action.
        lawId = 6; // execute law.  = roleId 3
        if (stepsPassed[1]) {
            vm.prank(charlotte); // has role 2.
            actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
            conditions = daoMock.getConditions(lawId);

            console.log("WAYPOINT 9");

            (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
                payable(address(daoMock)),
                lawId,
                actionId,
                users,
                seed,
                step2Chance
            );

            console.log("WAYPOINT 10"); 

            // step 2 results.
            vm.roll(block.number + conditions.votingPeriod + 1);
            actionState = daoMock.getActionState(actionId);
            stepsPassed[2] = actionState == PowersTypes.ActionState.Succeeded;
            console.log("step 3 result: actionState: ", uint8(actionState));
        }

        console.log("WAYPOINT 11");

        // step 3: conditional execute of proposal
        if (stepsPassed[2]) {
            console.log("step 4 action: ACTION WILL BE EXECUTED");
            vm.expectEmit(true, false, false, false);
            emit PowersEvents.ActionRequested(charlotte, lawId, lawCalldata, nonce, description);
            uint256 balanceBefore = Erc20Taxed(mockAddresses[1]).balanceOf(address(daoMock));
            vm.prank(charlotte); // has role 2
            daoMock.request(lawId, lawCalldata, nonce, description);
            uint256 balanceAfter = Erc20Taxed(mockAddresses[1]).balanceOf(address(daoMock));
            assertEq(balanceBefore + amountToMint, balanceAfter);
        } else {
            vm.expectRevert();
            vm.prank(charlotte);
            daoMock.request(lawId, lawCalldata, nonce, description);
        }

        console.log("WAYPOINT 12");
    }

    //////////////////////////////////////////////////////////////
    //         GOVERNANCE PATH 2: ELECT ROLES                   //
    //////////////////////////////////////////////////////////////

    function testFuzzPowers101_DelegateElect(uint256 numNominees, uint256 voteTokensRandomiser) public {
        numNominees = bound(numNominees, 4, 10);
        voteTokensRandomiser = bound(voteTokensRandomiser, 100_000, type(uint256).max);

        // Get law addresses from the powers101Constitution
        // Law 2: Nominate Me (nomination for delegate election)
        // Law 3: Delegate Nominees (run delegate election)
        uint16 nominateMeLaw = 2;  // Law 2 in powers101Constitution
        uint16 delegateSelectLaw = 3;  // Law 3 in powers101Constitution

        // step 0: distribute tokens. Tokens are distributed randomly.
        distributeERC20VoteTokens(users, voteTokensRandomiser);

        // step 1: people nominate their accounts using Law 2 (Nominate Me)
        for (i = 0; i < numNominees; i++) {
            lawCalldataNominate = abi.encode(users[i], true); // nominateMe = true
            vm.prank(users[i]);
            daoMock.request(
                nominateMeLaw, lawCalldataNominate, nonce, string.concat("Account nominates themselves: ", Strings.toString(i))
            );
        }
        
        // step 2: run election using Law 3 (Delegate Nominees)
        lawCalldataElect = abi.encode(); // empty calldata
        address executioner = users[voteTokensRandomiser % users.length];
        vm.prank(executioner);
        daoMock.request(delegateSelectLaw, lawCalldataElect, nonce, "Account executes an election.");

        // step 3: assert that the elected accounts are correct.
        // The election should assign role 2 (Delegate) to the top nominees based on token balance
        for (i = 0; i < numNominees; i++) {
            for (j = 0; j < numNominees; j++) {
                nominee1 = users[i];
                nominee2 = users[j];
                if (daoMock.hasRoleSince(nominee1, 2) != 0 && daoMock.hasRoleSince(nominee2, 2) == 0) {
                    uint256 balanceNominee = SimpleErc20Votes(mockAddresses[0]).balanceOf(nominee1);
                    uint256 balanceNominee2 = SimpleErc20Votes(mockAddresses[0]).balanceOf(nominee2);
                    assertGe(balanceNominee, balanceNominee2); // assert that nominee has more tokens than nominee2.
                }
                if (daoMock.hasRoleSince(nominee1, 2) == 0 && daoMock.hasRoleSince(nominee2, 2) != 0) {
                    uint256 balanceNominee = SimpleErc20Votes(mockAddresses[0]).balanceOf(nominee1);
                    uint256 balanceNominee2 = SimpleErc20Votes(mockAddresses[0]).balanceOf(nominee2);
                    assertLe(balanceNominee, balanceNominee2); // assert that nominee has fewer tokens than nominee2.
                }
            }
        }
    }

}
