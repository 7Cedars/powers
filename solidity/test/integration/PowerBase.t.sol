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
import { InitialiseSafe } from "../../script/InitialiseSafe.s.sol";
import { PowerBaseSafeSetup } from "../../src/laws/reform/PowerBaseSafeSetup.sol";
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

    function testPowerBase_Deployment() public {
        // Just verify setup completed successfully
        assertTrue(address(daoMock) != address(0), "Powers contract not deployed");
        assertTrue(config.SafeAllowanceModule != address(0), "Allowance module address not set");
         
        (address law1, , bool active1) = daoMock.getAdoptedLaw(1); 
        assertTrue(active1, "Law 1 not active");
        assertEq(law1, findLawAddress("PowerBaseSafeSetup"), "Law 1 target mismatch");   
    }

    function testPowerBase_InitialiseSafe() public {
        // Deploy and initialise safe
        vm.prank(alice);
        daoMock.request(1, abi.encode(), nonce, "Create SafeProxy");

        address treasury = daoMock.getTreasury();
        assertTrue(treasury != address(0), "Safe proxy not deployed");
    }

    function testPowerBase_CallPowerBaseSafeSetup() public {
        testPowerBase_InitialiseSafe(); 

        vm.prank(alice);
        daoMock.request(2, abi.encode(safeProxy, config.SafeAllowanceModule), nonce, "Setup Safe");

        assertTrue(daoMock.lawCounter() > 1, "No new actions recorded");
        assertTrue(SafeL2(payable(safeProxy)).isModuleEnabled(config.SafeAllowanceModule), "Allowance module not enabled"); 
    }

    function testPowerBase_AddDelegate() public {
        // Setup: Initialize the safe and call PowerBaseSafeSetup
        testPowerBase_CallPowerBaseSafeSetup();

        // The user roles are set up in TestSetup.t.sol in TestSetupPowerBaseSafes
        // ROLE_ONE (Funders): bob, charlotte, david, eve]
        // Based on PowerBaseSafeSetup.sol, we need roles 2, 3, 4, and 5 assigned.
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

        address newDelegate = makeAddr("newDelegate");

        // Step 1: Member proposes to add a new delegate.
        // The law to propose is the 8th law adopted (index 7 in calldatas array in PowerBaseSafeSetup.sol)
        // Law counter starts at 1, PowerBaseSafeSetup is law 1. It adds 11 laws.
        uint16 proposalLawId = 2; // Law adopted by PowerBaseSafeSetup
        (address lawTarget, , ) = daoMock.getAdoptedLaw(proposalLawId);
        assertEq(lawTarget, findLawAddress("StatementOfIntent"), "Proposal law should be StatementOfIntent");

        console2.log("MEMBERS PROPOSE TO ADD DELEGATE");
        vm.prank(helen); // Member
        (uint256 proposalActionId) = daoMock.propose(proposalLawId, abi.encode(newDelegate), nonce, "Add new delegate");

        // Step 2: Members vote to pass the proposal.
        vm.prank(helen);
        daoMock.castVote(proposalActionId, FOR);
        vm.prank(ian);
        daoMock.castVote(proposalActionId, FOR);

        // Fast forward time to end voting period
        vm.roll(block.number + 1201);

        // Execute the proposal
        vm.prank(helen);
        daoMock.request(proposalLawId, abi.encode(newDelegate), nonce, "Add new delegate");

        // Step 3: Doc Contributors OK the proposal.
        console2.log("DOC CONTRIBUTORS OK TO ADD DELEGATE");
        uint16 okDocLawId = 4;
        vm.prank(charlotte); // Doc Contributor
        (uint256 okDocActionId) = daoMock.propose(okDocLawId, abi.encode(newDelegate), nonce, "Doc OK");

        vm.prank(charlotte);
        daoMock.castVote(okDocActionId, FOR);
        vm.prank(david);
        daoMock.castVote(okDocActionId, FOR);
        vm.roll(block.number + 1201);

        vm.prank(charlotte);
        daoMock.request(okDocLawId, abi.encode(newDelegate), nonce, "Doc OK");

        // Step 4: Frontend Contributors OK the proposal.
        console2.log("FRONTEND CONTRIBUTORS OK TO ADD DELEGATE");
        uint16 okFrontendLawId = 5;
        vm.prank(frank); // Frontend Contributor
        (uint256 okFrontendActionId) = daoMock.propose(okFrontendLawId, abi.encode(newDelegate), nonce, "Frontend OK");
        
        vm.prank(frank);
        daoMock.castVote(okFrontendActionId, FOR);
        vm.prank(gary);
        daoMock.castVote(okFrontendActionId, FOR);

        vm.roll(block.number + 1201);

        vm.prank(frank);
        daoMock.request(okFrontendLawId, abi.encode(newDelegate), nonce, "Frontend OK");
        
        // Step 5: Protocol Contributors execute the proposal.
        console2.log("PROTOCOL CONTRIBUTORS EXECUTE TO ADD DELEGATE");
        uint16 executionLawId = 6;
        vm.prank(gary); // Protocol Contributor
        (uint256 executionActionId) = daoMock.propose(executionLawId, abi.encode(newDelegate), nonce, "Execute add delegate");

        vm.prank(gary);
        daoMock.castVote(executionActionId, FOR);
        vm.prank(helen);
        daoMock.castVote(executionActionId, FOR);

        vm.roll(block.number + 1201);

        vm.prank(gary);
        daoMock.request(executionLawId, abi.encode(newDelegate), nonce, "Execute add delegate");

        // Verification
        // We need to interact with the AllowanceModule to check if the delegate was added.
        // The address of the allowance module is config.SafeAllowanceModule
        // getDelegates = 0xeb37abe0
        vm.prank(address(safeProxy));
        (bool ok, bytes memory result) = config.SafeAllowanceModule.staticcall(
            abi.encodeWithSignature("getDelegates(address,uint48,uint8)", safeProxy, 1, 10)
        );

        require(ok, "Static call to getDelegates failed");
        (address[] memory delegates, ) = abi.decode(result, (address[], uint48));
        assertTrue(delegates.length > 0, "New delegate should be added to the allowance module");
        assertTrue(delegates[0] == newDelegate, "New delegate address mismatch");
    }

    function testPowerBase_AddAllowance() public { 
        // Do I have to setup safe + allowance module first again? 
        // testPowerBase_CallPowerBaseSafeSetup();

        // Step 1: create a proposal to add a allowance. 
            // get address from This HAS TO MOCKTAXED. - lawAddresses[24] "Erc20Taxed"
            // DaoMock should call the faucet function.  
            // use 1111 for allowance.
            // use resetTimeMin = 2222.
            // use resetBaseMin = 3333

        // step 2: Have Members propose and pass the proposal.

        // step 3-4: Have doc & frontend contributers ok the proposal. 

        // step 5: Have protocol contributors execute the proposal.
    }
 
        
}
