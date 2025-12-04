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

import { TestSetupPowerBaseSafes } from "../../test/TestSetup.t.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol"; 
import { PowerBaseSafeConfig } from "../../src/laws/reform/PowerBaseSafeConfig.sol";
import { SafeExecTransaction } from "../../src/laws/integrations/SafeExecTransaction.sol";
import { SafeAllowanceAction } from "../../src/laws/integrations/SafeAllowanceAction.sol";

import { ModuleManager } from "lib/safe-smart-account/contracts/base/ModuleManager.sol";
import { OwnerManager } from "lib/safe-smart-account/contracts/base/OwnerManager.sol";
import { SafeL2 } from "lib/safe-smart-account/contracts/SafeL2.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";
import { MessageHashUtils } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract PowerBase_IntegrationTest is TestSetupPowerBaseSafes {
    // IMPORTANT NOTE: These tests are meant to be executed on a forked mainnet (sepolia) anvil chain. 
    // They will not execute if the Allowance module address is empty on the chain.  
    // This also means that any test actions persist across tests, so be careful when re-running tests!
    address safeProxy;
    address law1; 
    address law2;
    bool active1;
    bool active2;

    address safeL2Treasury;
    address newDelegate; 
    bytes proposalCalldata; 

    bool ok; 
    bytes result;

    function testPowerBase_Deployment() public {
        // Just verify setup completed successfully
        assertTrue(address(daoMock) != address(0), "Powers contract not deployed");
        assertTrue(config.SafeAllowanceModule != address(0), "Allowance module address not set");
         
        (law1, , active1) = daoMock.getAdoptedLaw(1); 
        (law2, , active2) = daoMock.getAdoptedLaw(2); 
        assertTrue(active1, "Law 1 not active");
        assertTrue(active2, "Law 2 not active");
        assertEq(law1, findLawAddress("SafeSetup"), "Law 1 target mismatch");
        assertEq(law2, findLawAddress("PowerBaseSafeConfig"), "Law 2 target mismatch");   
    }

    function testPowerBase_InitialiseSafe() public {
        // Deploy and initialise safe
        vm.prank(alice);
        daoMock.request(1, abi.encode(), nonce, "Create SafeProxy");

        safeL2Treasury = daoMock.getTreasury();
        assertTrue(safeL2Treasury != address(0), "Safe proxy not deployed");
    }

    function testPowerBase_SetupSafe() public {
        testPowerBase_InitialiseSafe(); 
        safeL2Treasury = daoMock.getTreasury();

        vm.prank(alice);
        daoMock.request(2, abi.encode(safeL2Treasury, config.SafeAllowanceModule), nonce, "Setup Safe");

        assertTrue(daoMock.lawCounter() > 1, "No new actions recorded");
        assertTrue(SafeL2(payable(safeL2Treasury)).isModuleEnabled(config.SafeAllowanceModule), "Allowance module not enabled"); 
    }

    function testPowerBase_AddDelegate() public {
        // Setup: Initialize the safe and call PowerBaseSafeConfig
        testPowerBase_SetupSafe();

        // The user roles are set up in TestSetup.t.sol in TestSetupPowerBaseSafes
        // ROLE_ONE (Funders): bob, charlotte, david, eve]
        // Based on PowerBaseSafeConfig.sol, we need roles 2, 3, 4, and 5 assigned.
        vm.startPrank(address(daoMock));
        // ROLE_TWO (Doc Contributors)
        daoMock.assignRole(2, charlotte);
        daoMock.assignRole(2, david);
        // ROLE_THREE (Frontend Contributors)
        daoMock.assignRole(3, frank);
        daoMock.assignRole(3, gary);
        // ROLE_FOUR (Protocol Contributors)
        daoMock.assignRole(4, gary);
        daoMock.assignRole(4, helen);
        // ROLE_FIVE (Members)
        daoMock.assignRole(5, helen);
        daoMock.assignRole(5, ian);
        vm.stopPrank();

        newDelegate = alice; // making an EOA a delegate. 

        uint256 amountDocContribs = daoMock.getAmountRoleHolders(2); // Doc Contributors
        console2.log("Doc Contributors:", amountDocContribs);

        // Step 1: Member proposes to add a new delegate.
        // Law counter starts at 1, SafeSetup is law 1, PowerBaseSafeConfig is law 2. It adds 9(?) laws.
        lawId = 3; // Law adopted by PowerBaseSafeConfig
        (address lawTarget, , ) = daoMock.getAdoptedLaw(lawId);
        assertEq(lawTarget, findLawAddress("StatementOfIntent"), "Proposal law should be StatementOfIntent");

        console2.log("MEMBERS PROPOSE TO ADD DELEGATE");
        vm.prank(helen); // Member
        (actionId) = daoMock.propose(lawId, abi.encode(newDelegate), nonce, "Add new delegate");

        // Step 2: Members vote to pass the proposal.
        vm.prank(helen);
        daoMock.castVote(actionId, FOR);
        vm.prank(ian);
        daoMock.castVote(actionId, FOR);

        // Fast forward time to end voting period
        vm.roll(block.number + 1201);

        // Execute the proposal
        vm.prank(helen);
        daoMock.request(lawId, abi.encode(newDelegate), nonce, "Add new delegate");

        // Step 3: Doc Contributors OK the proposal.
        console2.log("DOC CONTRIBUTORS OK TO ADD DELEGATE");
        lawId = 5;
        vm.prank(charlotte); // Doc Contributor
        (actionId) = daoMock.propose(lawId, abi.encode(newDelegate), nonce, "Doc OK");

        vm.prank(charlotte);
        daoMock.castVote(actionId, FOR);
        vm.prank(david);
        daoMock.castVote(actionId, FOR);
        vm.roll(block.number + 1201);

        vm.prank(charlotte);
        daoMock.request(lawId, abi.encode(newDelegate), nonce, "Doc OK");

        // Step 4: Frontend Contributors OK the proposal.
        console2.log("FRONTEND CONTRIBUTORS OK TO ADD DELEGATE");
        lawId = 6;
        vm.prank(frank); // Frontend Contributor
        (actionId) = daoMock.propose(lawId, abi.encode(newDelegate), nonce, "Frontend OK");
        
        vm.prank(frank);
        daoMock.castVote(actionId, FOR);
        vm.prank(gary);
        daoMock.castVote(actionId, FOR);

        vm.roll(block.number + 1201);

        vm.prank(frank);
        daoMock.request(lawId, abi.encode(newDelegate), nonce, "Frontend OK");
        
        // Step 5: Protocol Contributors execute the proposal.
        console2.log("PROTOCOL CONTRIBUTORS EXECUTE TO ADD DELEGATE");
        lawId = 7;
        vm.prank(gary); // Protocol Contributor
        (actionId) = daoMock.propose(lawId, abi.encode(newDelegate), nonce, "Execute add delegate");

        vm.prank(gary);
        daoMock.castVote(actionId, FOR);
        vm.prank(helen);
        daoMock.castVote(actionId, FOR);

        vm.roll(block.number + 1201);

        vm.deal(gary, 100 ether); // Fund the daoMock to pay for gas costs
        vm.prank(gary);
        daoMock.request(lawId, abi.encode(newDelegate), nonce, "Execute add delegate");

        // Verification
        // We need to interact with the AllowanceModule to check if the delegate was added.
        // The address of the allowance module is config.SafeAllowanceModule
        // getDelegates = 0xeb37abe0
        safeL2Treasury = daoMock.getTreasury();
        vm.prank(safeL2Treasury);
        (ok, result) = config.SafeAllowanceModule.staticcall(
            abi.encodeWithSignature("getDelegates(address,uint48,uint8)", safeL2Treasury, 0, 10)
        );

        require(ok, "Static call to getDelegates failed");
        (address[] memory delegates, ) = abi.decode(result, (address[], uint48));
        assertTrue(delegates.length > 0, "New delegate should be added to the allowance module");
        assertTrue(delegates[0] == newDelegate, "New delegate address mismatch");
    }

    function testPowerBase_AddAllowance() public {
        // Setup: Initialize the safe and call PowerBaseSafeConfig
        testPowerBase_AddDelegate();

        // The user roles are set up in TestSetup.t.sol in TestSetupPowerBaseSafes
        vm.startPrank(address(daoMock));
        daoMock.assignRole(2, charlotte);
        daoMock.assignRole(2, david);
        daoMock.assignRole(3, frank);
        daoMock.assignRole(3, gary);
        daoMock.assignRole(4, gary);
        daoMock.assignRole(4, helen);
        daoMock.assignRole(5, helen);
        daoMock.assignRole(5, ian);
        vm.stopPrank();

        safeL2Treasury = daoMock.getTreasury();
        
        // Fund the treasury with tokens
        address token = findLawAddress("Erc20Taxed");
        Erc20Taxed(token).faucet();

        // Step 1: Member proposes to add an allowance.
        lawId = 8;
        proposalCalldata = abi.encode(
            alice, // has been set as delegate in previous test 
            token, 
            11111, // allowanceAmount, 
            22222, // resetTimeMin, 
            33333 // resetBaseMin
            );

        console2.log("MEMBERS PROPOSE TO ADD ALLOWANCE");
        vm.prank(helen); // Member
        (actionId) = daoMock.propose(lawId, proposalCalldata, nonce, "Add new allowance");

        // Step 2: Members vote to pass the proposal.
        vm.prank(helen);
        daoMock.castVote(actionId, FOR);
        vm.prank(ian);
        daoMock.castVote(actionId, FOR);

        vm.roll(block.number + 1201);

        vm.prank(helen);
        daoMock.request(lawId, proposalCalldata, nonce, "Add new allowance");

        // Step 3: Doc Contributors OK the proposal.
        console2.log("DOC CONTRIBUTORS OK TO ADD ALLOWANCE");
        lawId = 10;
        vm.prank(charlotte); // Doc Contributor
        (actionId) = daoMock.propose(lawId, proposalCalldata, nonce, "Doc OK");

        vm.prank(charlotte);
        daoMock.castVote(actionId, FOR);
        vm.prank(david);
        daoMock.castVote(actionId, FOR);
        vm.roll(block.number + 1201);

        vm.prank(charlotte);
        daoMock.request(lawId, proposalCalldata, nonce, "Doc OK");

        // Step 4: Frontend Contributors OK the proposal.
        console2.log("FRONTEND CONTRIBUTORS OK TO ADD ALLOWANCE");
        lawId = 11;
        vm.prank(frank); // Frontend Contributor
        (actionId) = daoMock.propose(lawId, proposalCalldata, nonce, "Frontend OK");

        vm.prank(frank);
        daoMock.castVote(actionId, FOR);
        vm.prank(gary);
        daoMock.castVote(actionId, FOR);

        vm.roll(block.number + 1201);

        vm.prank(frank);
        daoMock.request(lawId, proposalCalldata, nonce, "Frontend OK");

        // Step 5: Protocol Contributors execute the proposal.
        console2.log("PROTOCOL CONTRIBUTORS EXECUTE TO ADD ALLOWANCE");
        lawId = 12;
        vm.prank(gary); // Protocol Contributor
        (actionId) = daoMock.propose(lawId, proposalCalldata, nonce, "Execute add allowance");

        vm.prank(gary);
        daoMock.castVote(actionId, FOR);
        vm.prank(helen);
        daoMock.castVote(actionId, FOR);

        vm.roll(block.number + 1201);

        vm.deal(gary, 100 ether); // Fund the daoMock to pay for gas costs
        vm.prank(gary);
        daoMock.request(lawId, proposalCalldata, nonce, "Execute add allowance");

        // Verification
        (ok, result) = config.SafeAllowanceModule.staticcall(
            abi.encodeWithSignature("getTokenAllowance(address,address,address)", safeL2Treasury, alice, token)
        );

        require(ok, "Static call to getTokenAllowance failed");
        (uint256 amount, , uint256 resetTime, , ) = abi.decode(result, (uint256, uint256, uint256, uint256, uint256));

        assertEq(amount, 11111, "Allowance amount mismatch");
        assertEq(resetTime, 22222, "Reset time mismatch"); 
    }
}
