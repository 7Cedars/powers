// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Powers } from "../../src/Powers.sol";
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

    function testFuzzPowers101_ExecuteAction(uint256 step0Chance, uint256 step1Chance, uint256 step2Chance) public {
        console.log("WAYPOINT 0");

        step0Chance = bound(step0Chance, 0, 100);
        step1Chance = bound(step1Chance, 0, 100);
        step2Chance = bound(step2Chance, 0, 100);
        uint256 balanceBefore = Erc20Taxed(mockAddresses[1]).balanceOf(address(daoMock));
        uint256 seed = 9_034_273_427;
        uint256 amountToMint = 123 * 10 ** 18;
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

        lawId = 3; // statement of intent.  = roleId 1
        lawCalldata = abi.encode(targets, values, calldatas); //
        description = string.concat("Propose minting ", Strings.toString(amountToMint), "ETH in coins to the daoMock");

        console.log("WAYPOINT 3");

        console.log("step 0 action: BOB PROPOSES!"); // alice == admin.
        vm.prank(bob); // has role 1.
        actionId = daoMock.propose(lawId, lawCalldata, nonce, description);

        console.log("WAYPOINT 4");
        (roleCount, againstVote, forVote, abstainVote) =
            voteOnProposal(payable(address(daoMock)), lawId, actionId, users, seed, step0Chance);

        console.log("WAYPOINT 5");

        // step 0 results.
        conditions = daoMock.getConditions(lawId);
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
        lawId = 4; // veto law.  = Admin role
        if (stepsPassed[0] && step1Chance > 50) {
            // 50% chance of veto.
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
        lawId = 5; // execute law.  = roleId 3
        if (stepsPassed[1]) {
            vm.prank(charlotte); // has role 2.
            actionId = daoMock.propose(lawId, lawCalldata, nonce, description);
            conditions = daoMock.getConditions(lawId);

            console.log("WAYPOINT 9");

            (roleCount, againstVote, forVote, abstainVote) =
                voteOnProposal(payable(address(daoMock)), lawId, actionId, users, seed, step2Chance);

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
            balanceBefore = Erc20Taxed(mockAddresses[1]).balanceOf(address(daoMock));
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
}
