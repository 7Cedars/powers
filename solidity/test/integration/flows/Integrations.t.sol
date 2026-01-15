// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { TestSetupSafeProtocolFlow } from "../../TestSetup.t.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol";
import { IPowers } from "../../../src/interfaces/IPowers.sol";
import { IMandate } from "../../../src/interfaces/IMandate.sol";
import { console2 } from "forge-std/console2.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";

contract SafeProtocolFlowTest is TestSetupSafeProtocolFlow {

    function testSafeProtocolFlow() public {
        // Check skip condition from setup (Safe Allowance Module must be configured)
        if (address(config.safeAllowanceModule).code.length == 0) {
            console2.log("Skipping test: Safe Allowance Module not configured");
            return;
        }

        vm.startPrank(alice);

        // ---------------------------------------------------------
        // 1. Setup Safe on Parent (Mandate 1)
        // ---------------------------------------------------------
        // Mandate 1 in SafeProtocol_Parent constitution is "Setup Safe".
        // It uses Safe_Setup mandate which requires no input params in execution as everything is in config.
        nonce = 123;
        console2.log("Executing Safe Setup...");
        daoMock.request(1, "", nonce, "");

        // Use getTreasury() from IPowers interface
        safeTreasury = daoMock.getTreasury();
        console2.log("Safe Treasury deployed at:", safeTreasury);
        assertTrue(safeTreasury != address(0), "Safe treasury should be set");
        assertTrue(safeTreasury.code.length > 0, "Safe treasury should have code");

        // ---------------------------------------------------------
        // 2. Fix Child Constitution (Add Mandate with correct Safe)
        // ---------------------------------------------------------
        // The default child constitution setup in TestConstitutions uses `parent` (daoMock) to get treasury.
        // At setup time, it was 0. Now it is set.
        // We re-constitute the child using the helper function which now returns the correct data.
        
        console2.log("Re-constituting Child with correct Safe address...");
        
        PowersTypes.MandateInitData[] memory newMandateData = testConstitutions.safeProtocol_Child_IntegrationTestConstitution(
            address(daoMockChild1), 
            address(daoMock)
        );

        vm.stopPrank();
        daoMockChild1.constitute(newMandateData);
        uint16 mandateId = 2; // New ID because initial one (ID 1) was constituted in setup

        vm.startPrank(alice);

        // ---------------------------------------------------------
        // 3. Add Child as Delegate on Parent (Mandate 2)
        // ---------------------------------------------------------
        // Mandate 2: Add Delegate. Input: address NewChildPowers
        console2.log("Adding Child as Delegate on Parent...");
        bytes memory params = abi.encode(address(daoMockChild1));
        daoMock.request(2, params, nonce, "");

        // ---------------------------------------------------------
        // 4. Set Allowance for Child on Parent (Mandate 3)
        // ---------------------------------------------------------
        
        // Deploy a token and mint to Safe
        SimpleErc20Votes token = new SimpleErc20Votes();
        token.mint(safeTreasury, 1000 ether);
        
        uint96 allowanceAmount = 100 ether;
        // Mandate 3: Set Allowance. Input: Child, Token, Amount, ResetTime, ResetBase
        console2.log("Setting Allowance for Child on Parent...");
        params = abi.encode(
            address(daoMockChild1), // ChildPowers
            address(token), // Token
            allowanceAmount, // allowanceAmount
            uint16(30), // resetTimeMin (30 mins)
            uint32(0) // resetBaseMin
        );
        daoMock.request(3, params, nonce, "");
        
        vm.stopPrank();

        // ---------------------------------------------------------
        // 5. Child executes transaction using Allowance (Child Mandate 2)
        // ---------------------------------------------------------
        // Alice has Role 1 in Child.
        vm.startPrank(alice);
        
        // Prepare execution
        address payableTo = makeAddr("recipient");
        uint256 transferAmount = 10 ether;
        
        // Input params for SafeAllowance_Transfer: Token, PayableTo, Amount
        bytes memory executionParams = abi.encode(address(token), payableTo, transferAmount);
        
        console2.log("Proposing transaction on Child...");
        // Propose
        // propose(mandateId, calldata, nonce, uri)
        uint256 childActionId = daoMockChild1.propose(mandateId, executionParams, nonce, "");
        
        // Vote
        // Alice votes FOR (1)
        console2.log("Voting on Child proposal...");
        daoMockChild1.castVote(childActionId, 1);
        
        // Check voting period
        console2.log("Rolling block number to pass voting period...");
        vm.roll(block.number + 100);
        
        // Execute
        // To fulfill, we need the execution payload (targets, values, calldatas).
        // We get this by calling handleRequest on the mandate contract.
        (address mandateAddress, , ) = daoMockChild1.getAdoptedMandate(mandateId);
        
        // Retrieve execution parameters from mandate
        ( , address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = 
            IMandate(mandateAddress).handleRequest(alice, address(daoMockChild1), mandateId, executionParams, nonce);
            
        console2.log("Executing Child proposal...");
        daoMockChild1.fulfill(mandateId, childActionId, targets, values, calldatas);
        
        // Verify transfer
        console2.log("Verifying transfer...");
        assertEq(token.balanceOf(payableTo), transferAmount, "Recipient should receive tokens");
        assertEq(token.balanceOf(safeTreasury), 1000 ether - transferAmount, "Safe should have sent tokens");
        
        vm.stopPrank();
    }
}
