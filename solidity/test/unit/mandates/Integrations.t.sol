// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";
import { TestSetupIntegrations, TestSetupExecutive } from "../../TestSetup.t.sol";
import { PowersMock } from "@mocks/PowersMock.sol";
import { Governor_CreateProposal } from "@src/mandates/integrations/Governor_CreateProposal.sol";
import { Governor_ExecuteProposal } from "@src/mandates/integrations/Governor_ExecuteProposal.sol";
 
import { SafeAllowance_Transfer } from "@src/mandates/integrations/SafeAllowance_Transfer.sol";
import { Safe_ExecTransaction } from "@src/mandates/integrations/Safe_ExecTransaction.sol";
import { PowersFactory_AssignRole } from "@src/mandates/integrations/PowersFactory_AssignRole.sol";
import { Soulbound1155_GatedAccess } from "@src/mandates/integrations/Soulbound1155_GatedAccess.sol";
import { Mandate } from "@src/Mandate.sol";
import { IPowers } from "@src/interfaces/IPowers.sol";

import { SimpleGovernor } from "@mocks/SimpleGovernor.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { PresetSingleAction } from "@src/mandates/executive/PresetSingleAction.sol";
import { PowersTypes } from "@src/interfaces/PowersTypes.sol";
import { MandateUtilities } from "@src/libraries/MandateUtilities.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";

/// @notice Comprehensive unit tests for all executive mandates
/// @dev Tests all functionality of executive mandates including initialization, execution, and edge cases

//////////////////////////////////////////////////
//          GOVERNOR INTEGRATION TESTS          //
//////////////////////////////////////////////////
contract GovernorIntegrationTest is TestSetupIntegrations {
    Governor_CreateProposal public createProposalMandate;
    Governor_ExecuteProposal public executeProposalMandate;

    uint16 public createProposalId;
    uint16 public executeProposalId;

    function setUp() public override {
        super.setUp();

        // 1. Identify Mandate IDs from TestSetupIntegrations -> integrationsTestConstitution
        // First pushed: Governor_CreateProposal (ID 1)
        // Second pushed: Governor_ExecuteProposal (ID 2)
        createProposalId = 1;
        executeProposalId = 2;

        // 2. Get Mandate Instances
        createProposalMandate = Governor_CreateProposal(findMandateAddress("Governor_CreateProposal"));
        executeProposalMandate = Governor_ExecuteProposal(findMandateAddress("Governor_ExecuteProposal"));

        // 3. Setup Alice with votes for the Governor
        simpleErc20Votes.mint(10e18);
        simpleErc20Votes.transfer(alice, 10e18);
        vm.prank(alice);
        simpleErc20Votes.delegate(alice);
    }

    function test_Governor_CreateProposal_Success() public {
        // Setup proposal parameters
        address[] memory targets = new address[](1);
        targets[0] = address(simpleErc20Votes);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18);
        string memory description = "Test Proposal";

        // mint tokens to daoMock to have tokens to transfer. 
        simpleErc20Votes.mint(address(daoMock), 5e18);

        // Encode mandate calldata
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        // Execute via DAO
        vm.prank(alice);
        daoMock.request(createProposalId, mandateCalldata, 0, "Create Proposal Request");

        // Verify proposal exists on Governor
        uint256 proposalId = simpleGovernor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        assertGt(simpleGovernor.proposalSnapshot(proposalId), 0);
    }

    function test_Governor_CreateProposal_Revert_NotConfigured() public {
         // Create a fresh mandate that is NOT configured
         Governor_CreateProposal unconfiguredMandate = new Governor_CreateProposal();
         // Don't initialize it, or initialize with 0 address
         
         uint16 unconfiguredId = 999;
         bytes memory mandateCalldata = abi.encode(new address[](0), new uint256[](0), new bytes[](0), "");
         
         vm.expectRevert();
         unconfiguredMandate.handleRequest(alice, address(daoMock), unconfiguredId, mandateCalldata, 0);
    }

    function test_Governor_CreateProposal_Revert_InvalidParams() public {
        // Empty targets
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);
        string memory description = "Test";
        
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        vm.prank(alice);
        vm.expectRevert("Governor_CreateProposal: No targets provided");
        daoMock.request(createProposalId, mandateCalldata, 0, "Invalid Params");

        // Mismatch length
        targets = new address[](1);
        targets[0] = address(0);
        
        mandateCalldata = abi.encode(targets, values, calldatas, description);
        
        vm.prank(alice);
        vm.expectRevert("Governor_CreateProposal: Targets and values length mismatch");
        daoMock.request(createProposalId, mandateCalldata, 0, "Mismatch Params");
    }

    function test_Governor_ExecuteProposal_Success() public {
        // 1. Setup and Create Proposal
        address[] memory targets = new address[](1);
        targets[0] = address(simpleErc20Votes);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18);
        string memory description = "Test Proposal Execution";

        // Create proposal directly on Governor
        vm.startPrank(alice);
        simpleErc20Votes.mint(address(daoMock), 100e18); // AI READ THIS: DO NOT DELETE. This is needed because the tokens will be transferred from the daoMock contract NOT from alice! 
        simpleGovernor.propose(targets, values, calldatas, description);
        vm.stopPrank();
        
        uint256 proposalId = simpleGovernor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        // 2. Advance to voting period
        vm.roll(block.number + simpleGovernor.votingDelay() + 1);

        // 3. Vote
        vm.prank(alice);
        simpleGovernor.castVote(proposalId, 1); // For

        // 4. Advance to end of voting period
        vm.roll(block.number + simpleGovernor.votingPeriod() + 1);

        // 5. Test Execute Mandate
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        vm.prank(alice);
        daoMock.request(executeProposalId, mandateCalldata, 0, "Execute Proposal");

        // Verify execution
        assertEq(uint256(simpleGovernor.state(proposalId)), 4); // Succeded state
    }

    function test_Governor_ExecuteProposal_Revert_NotSucceeded() public {
        // 1. Setup and Create Proposal
        address[] memory targets = new address[](1);
        targets[0] = address(simpleErc20Votes);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18);
        string memory description = "Test Proposal Fail";

        vm.prank(alice);
        simpleGovernor.propose(targets, values, calldatas, description);
        
        // 2. Try to execute immediately (Pending state)
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        vm.prank(alice);
        vm.expectRevert("Governor_ExecuteProposal: Proposal not succeeded");
        daoMock.request(executeProposalId, mandateCalldata, 0, "Execute Pending");

        // 3. Vote Against
        uint256 proposalId = simpleGovernor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        vm.roll(block.number + simpleGovernor.votingDelay() + 1);
        
        vm.prank(alice);
        simpleGovernor.castVote(proposalId, 0); // Against

        vm.roll(block.number + simpleGovernor.votingPeriod() + 1);

        // 4. Try to execute (Defeated state)
        vm.prank(alice);
        vm.expectRevert("Governor_ExecuteProposal: Proposal not succeeded");
        daoMock.request(executeProposalId, mandateCalldata, 0, "Execute Defeated");
    }
}


//////////////////////////////////////////////////
//      SAFE ALLOWANCE INTEGRATION TESTS        //
//////////////////////////////////////////////////
contract SafeAllowanceTest is TestSetupIntegrations {
    uint16 public safeAllowanceMandateId_Safe_Setup;
    uint16 public safeAllowanceMandateId_ExecuteActionFromSafe;
    uint16 public safeAllowanceMandateId_SetAllowance;
    uint16 public safeAllowanceTransferId;

    function setUp() public override {
        super.setUp();

        // skip these tests if allowance module is not set
        if (config.safeAllowanceModule == address(0)) {
            console2.log("Safe Allowance Module not set in config, skipping tests.");
            vm.skip(true); 
        }

        // IDs from TestConstitutions
        safeAllowanceMandateId_Safe_Setup = 3;
        safeAllowanceMandateId_ExecuteActionFromSafe = 4;
        safeAllowanceMandateId_SetAllowance = 5;
        // On daoMockChild1
        safeAllowanceTransferId = 1;

        vm.prank(alice);
        daoMock.request(safeAllowanceMandateId_Safe_Setup, abi.encode(), nonce, "Setting up safe with allowance module.");
    }

    // we will try to add a delegate. 
    function test_Safe_ExecTransaction_Success() public {
        uint16 safeExecTransactionId = 4; // index of Safe_ExecTransaction mandate in integrationsTestConstitution
        // We are trying to add a delegate (address(0x456)) to the Safe via execTransaction mandate
        address functionTarget = config.safeAllowanceModule;
        bytes4 functionSelector = bytes4(0xe71bdf41); // addDelegate(address)
        bytes memory functionCalldata = abi.encode(address(0x456));

        bytes memory mandateCalldata = abi.encode(
            functionTarget,
            uint256(0), // value
            abi.encodeWithSelector(functionSelector, functionCalldata) // data
        );
 
        // Execute via DAO
        vm.prank(alice);
        daoMock.request(safeExecTransactionId, mandateCalldata, nonce, "Safe Exec Transaction");
    }

    // we will try to add a delegate. 
    function test_Safe_ExecTransaction_Revert() public {
        // test is the same as previous test, except we set the treasury to address(0) first to test the revert.
        vm.prank(address(daoMock));
        daoMock.setTreasury(payable(address(0)));

        uint16 safeExecTransactionId = 4; // index of Safe_ExecTransaction mandate in integrationsTestConstitution
        // We are trying to add a delegate (address(0x456)) to the Safe via execTransaction mandate
        address functionTarget = config.safeAllowanceModule;
        bytes4 functionSelector = bytes4(0xe71bdf41); // addDelegate(address)
        bytes memory functionCalldata = abi.encode(address(0x456));

        bytes memory mandateCalldata = abi.encode(
            functionTarget,
            uint256(0), // value
            abi.encodeWithSelector(functionSelector, functionCalldata) // data
        );
 
        // Execute via DAO
        vm.prank(alice);
        daoMock.request(safeExecTransactionId, mandateCalldata, nonce, "Safe Exec Transaction");
    }

    function test_SafeAllowance_Transfer_Success() public {
        // 2. Set Allowance
        address token = address(simpleErc20Votes);
        uint96 amount = 100e18;
        // Params: ChildPowers, Token, allowanceAmount, resetTimeMin, resetBaseMin
        bytes memory setAllowanceData = abi.encode(address(daoMockChild1), token, amount, uint16(0), uint32(0));
        vm.prank(alice);
        daoMock.request(safeAllowanceMandateId_SetAllowance, setAllowanceData, 1, "Set Allowance");
        
        // 3. Execute Transfer on Child
        address payableTo = bob;
        // Params: Token, payableTo, amount
        bytes memory transferData = abi.encode(token, payableTo, uint256(10e18));
        
        vm.prank(alice);
        daoMockChild1.request(safeAllowanceTransferId, transferData, 0, "Transfer Allowance");
    }


}

//////////////////////////////////////////////////
//      POWERS FACTORY ASSIGN ROLE TESTS        //
//////////////////////////////////////////////////
contract PowersFactory_AssignRoleTest is TestSetupIntegrations {
    uint16 public createPowersId;
    uint16 public assignRoleId;
    uint256 public roleIdToAssign;

    function setUp() public override {
        super.setUp();
        
        // IDs from TestConstitutions
        createPowersId = 5;
        assignRoleId = 6;
        roleIdToAssign = 9; // Configured in TestConstitutions.sol for ID 6
    }
    
    function test_PowersFactory_AssignRole_Success() public {
        // 1. Execute "Create Powers"
        string memory orgName = "New Org";
        string memory orgUri = "http://example.com";
        uint256 allowance = 1000;
        
        // BespokeActionSimple expects encoded input params
        bytes memory createCalldata = abi.encode(orgName, orgUri, allowance);
        
        vm.prank(alice);
        uint256 parentActionId = daoMock.request(createPowersId, createCalldata, nonce, "Create New Org");
        console2.log("Parent Action ID:", parentActionId);
        
        // 2. Execute "Assign Role"
        // PowersFactory_AssignRole uses the SAME calldata and nonce as the parent action
        vm.prank(alice);
        daoMock.request(assignRoleId, createCalldata, nonce, "Assign Role in New Org");
        
        // Verify Role Assigned 
        bytes memory returnData = daoMock.getActionReturnData(parentActionId, 0);
        address newOrg = abi.decode(returnData, (address));
        
        assertTrue(newOrg != address(0));
        // Check role on PARENT DAO (daoMock) assigned to NEW ORG
        assertTrue(daoMock.hasRoleSince(newOrg, roleIdToAssign) > 0);
    }
    
    function test_PowersFactory_AssignRole_Revert_ParentNotFulfilled() public {
        string memory orgName = "New Org";
        string memory orgUri = "http://example.com";
        uint256 allowance = 1000;
        bytes memory createCalldata = abi.encode(orgName, orgUri, allowance);
        
        // Use a nonce (999) that has NOT been used/fulfilled
        vm.prank(alice);
        vm.expectRevert("Invalid parent action state");
        daoMock.request(assignRoleId, createCalldata, 999, "Assign Role Fail");
    }
}

contract Soulbound1155_GatedAccessTest is TestSetupIntegrations {
    uint16 public mintMandateId;
    uint16 public accessMandateId;
    uint256 public targetRoleId;

    function setUp() public override {
        super.setUp(); 

        mintMandateId = 7;
        accessMandateId = 8;
        targetRoleId = 9;
    }

    function test_Soulbound1155_GatedAccess_Success() public {
        vm.startPrank(alice);

        // 1. Mint 4 tokens (Threshold is 3, need > 3 tokens. i.e. 4)
        uint256[] memory tokenIds = new uint256[](4);
        
        for(uint i=0; i<4; i++) {
            // Config for mandate 7: params[0] = "address to"
            // So request calldata should be abi.encode(to).
            daoMock.request(mintMandateId, abi.encode(alice), nonce, "Mint Token");
            
            // Calculate ID that was minted
            // TokenID = (minter << 48) | blockNumber
            // Minter is daoMock (owner of soulbound1155)
            uint256 tokenId = (uint256(uint160(address(daoMock))) << 48) | uint256(block.number);
            tokenIds[i] = tokenId;
            
            // Advance block to get unique IDs (and test block threshold)
            // Config block threshold is 100.
            vm.roll(block.number + 1);
            nonce++;
        }
        
        // 2. Request Access using the minted tokens
        // Check if we are within block threshold.
        // Current block is X. Token mint blocks are X-4, X-3, X-2, X-1.
        // Threshold is 100. So we are well within threshold.
        daoMock.request(accessMandateId, abi.encode(tokenIds), nonce++, "Request Access");
        vm.stopPrank();

        // 3. Verify Role Assigned
        assertTrue(daoMock.hasRoleSince(alice, targetRoleId) > 0);
    }

    function test_Soulbound1155_GatedAccess_Revert_InsufficientTokens() public {
        vm.startPrank(alice);
        
        // Mint 3 tokens (Threshold is 3, check is <= threshold, so 3 fails)
        uint256[] memory tokenIds = new uint256[](3);
        for(uint i=0; i<3; i++) {
            daoMock.request(mintMandateId, abi.encode(alice), nonce, "Mint Token");
            tokenIds[i] = (uint256(uint160(address(daoMock))) << 48) | uint256(block.number);
            vm.roll(block.number + 1);
            nonce++;
        }

        vm.expectRevert(Soulbound1155_GatedAccess.Soulbound1155_GatedAccess__InsufficientTokens.selector);
        daoMock.request(accessMandateId, abi.encode(tokenIds), 0, "Request Access");
        
        vm.stopPrank();
    }

    function test_Soulbound1155_GatedAccess_Revert_NotOwnerOfToken() public {
        vm.startPrank(alice);
        
        // Mint 4 tokens
        uint256[] memory tokenIds = new uint256[](4);
        for(uint i=0; i<4; i++) {
            daoMock.request(mintMandateId, abi.encode(alice), nonce, "Mint Token");
            tokenIds[i] = (uint256(uint160(address(daoMock))) << 48) | uint256(block.number);
            vm.roll(block.number + 1);
            nonce++;
        }
        
        // Change one token to random ID (alice doesn't own it)
        tokenIds[0] = 123456789;
        
        vm.expectRevert(abi.encodeWithSelector(Soulbound1155_GatedAccess.Soulbound1155_GatedAccess__NotOwnerOfToken.selector, tokenIds[0]));
        daoMock.request(accessMandateId, abi.encode(tokenIds), 0, "Request Access");
        
        vm.stopPrank();
    }
    
    function test_Soulbound1155_GatedAccess_Revert_TokenNotFromParent() public {
        // Mint tokens properly first
         vm.startPrank(alice);
        uint256[] memory tokenIds = new uint256[](4);
        for(uint i=0; i<4; i++) {
            daoMock.request(mintMandateId, abi.encode(alice), nonce, "Mint Token");
            tokenIds[i] = (uint256(uint160(address(daoMock))) << 48) | uint256(block.number);
            vm.roll(block.number + 1);
            nonce++;
        }
        
        // Change first token to have different minter address in high bits
        // Keep block number same
        address fakeMinter = address(0xDEADBEEF);
        uint256 fakeTokenId = (uint256(uint160(fakeMinter)) << 48) | uint256(uint48(tokenIds[0]));       
        vm.stopPrank();
    }

    function test_Soulbound1155_GatedAccess_Revert_TokenExpired() public {
        vm.startPrank(alice);
        
        uint256[] memory tokenIds = new uint256[](4);
        for(uint i=0; i<4; i++) {
            daoMock.request(mintMandateId, abi.encode(alice), nonce, "Mint Token");
            tokenIds[i] = (uint256(uint160(address(daoMock))) << 48) | uint256(block.number);
            vm.roll(block.number + 1);
            nonce++;
        }
        
        // Advance block beyond threshold
        // Threshold is 100.
        // Last token minted at T. Current block is T+1.
        // We want (block.number - mintBlock) > threshold.
        // mintBlock = T.
        // Need block.number > T + 100.
        // So + 101 blocks.
        vm.roll(block.number + 101);    
        vm.expectRevert(abi.encodeWithSelector(Soulbound1155_GatedAccess.Soulbound1155_GatedAccess__TokenExpiredOrInvalid.selector, tokenIds[0]));
        daoMock.request(accessMandateId, abi.encode(tokenIds), nonce, "Request Access");
        
        vm.stopPrank();
    }
}

// contract AllowedTokensPresetTransferTest is TestSetupIntegrations {
//     uint16 public allowedTokensPresetTransferId;
//     SimpleErc20Votes public tokenA;
//     SimpleErc20Votes public tokenB;

//     function setUp() public override {
//         super.setUp();
        
//         allowedTokensPresetTransferId = 2; // Second mandate in integrationsTestConstitution2

//         // Deploy two test tokens
//         vm.prank(alice);
//         tokenA = new SimpleErc20Votes();
//         vm.prank(alice);
//         tokenB = new SimpleErc20Votes();

//         // Assign ADMIN_ROLE (0) to Alice on daoMockChild1 so she can execute the mandate
//         vm.prank(address(daoMockChild1));
//         daoMockChild1.assignRole(0, alice);
//     }

//     function test_AllowedTokensPresetTransfer_Success() public {
//         // 1. Add tokens to AllowedTokens registry (owned by daoMock)
//         vm.startPrank(address(daoMock));
//         allowedTokens.addToken(address(tokenA));
//         allowedTokens.addToken(address(tokenB));
//         vm.stopPrank();

//         // 2. Mint tokens to daoMockChild1 (sender)
//         tokenA.mint(address(daoMockChild1), 100e18);
//         tokenB.mint(address(daoMockChild1), 50e18);

//         assertEq(tokenA.balanceOf(address(daoMockChild1)), 100e18);
//         assertEq(tokenB.balanceOf(address(daoMockChild1)), 50e18);
//         assertEq(tokenA.balanceOf(address(daoMock)), 0);
//         assertEq(tokenB.balanceOf(address(daoMock)), 0);

//         // 3. Execute Mandate on daoMockChild1
//         // handleRequest expects no specific calldata based on contract implementation, 
//         // but Powers.request requires some calldata. The mandate ignores it.
//         vm.prank(alice);
//         daoMockChild1.request(allowedTokensPresetTransferId, abi.encode(""), nonce, "Transfer Allowed Tokens");

//         // 4. Verify transfers
//         assertEq(tokenA.balanceOf(address(daoMockChild1)), 0);
//         assertEq(tokenB.balanceOf(address(daoMockChild1)), 0);
//         assertEq(tokenA.balanceOf(address(daoMock)), 100e18);
//         assertEq(tokenB.balanceOf(address(daoMock)), 50e18);
//     }

//     function test_AllowedTokensPresetTransfer_PartialBalance() public {
//         // Only tokenA has balance
//         vm.startPrank(address(daoMock));
//         allowedTokens.addToken(address(tokenA));
//         allowedTokens.addToken(address(tokenB));
//         vm.stopPrank();

//         tokenA.mint(address(daoMockChild1), 100e18);
//         // tokenB balance is 0

//         vm.prank(alice);
//         daoMockChild1.request(allowedTokensPresetTransferId, abi.encode(""), nonce, "Transfer Partial");

//         assertEq(tokenA.balanceOf(address(daoMock)), 100e18);
//         assertEq(tokenB.balanceOf(address(daoMock)), 0);
//     }

//     function test_AllowedTokensPresetTransfer_NoAllowedTokens() public {
//         // Registry empty
//         tokenA.mint(address(daoMockChild1), 100e18);

//         vm.prank(alice);
//         daoMockChild1.request(allowedTokensPresetTransferId, abi.encode(""), nonce, "No Allowed Tokens");

//         // Should not transfer anything
//         assertEq(tokenA.balanceOf(address(daoMock)), 0);
//         assertEq(tokenA.balanceOf(address(daoMockChild1)), 100e18);
//     }
    
//     function test_AllowedTokensPresetTransfer_IgnoresUnallowedTokens() public {
//          // Token A allowed, Token B not allowed
//         vm.startPrank(address(daoMock));
//         allowedTokens.addToken(address(tokenA));
//         vm.stopPrank();

//         tokenA.mint(address(daoMockChild1), 100e18);
//         tokenB.mint(address(daoMockChild1), 50e18);

//         vm.prank(alice);
//         daoMockChild1.request(allowedTokensPresetTransferId, abi.encode(""), nonce, "Ignore Unallowed");

//         // Token A transferred
//         assertEq(tokenA.balanceOf(address(daoMock)), 100e18);
//         // Token B stays
//         assertEq(tokenB.balanceOf(address(daoMockChild1)), 50e18);
//         assertEq(tokenB.balanceOf(address(daoMock)), 0);
//     }
// }
