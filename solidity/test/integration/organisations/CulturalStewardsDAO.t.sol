// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test, console, console2 } from "forge-std/Test.sol";
import { Powers } from "../../../src/Powers.sol";
import { IPowers } from "../../../src/interfaces/IPowers.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol";
import { CulturalStewardsDAO } from "../../../script/deployOrganisations/CulturalStewardsDAO.s.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";

interface IAllowanceModule {
    function delegates(address safe, uint48 index) external view returns (address delegate, uint48 prev, uint48 next);
    function getTokenAllowance(address safe, address delegate, address token) external view returns (uint256[5] memory);
}

// Expose internal variables for testing
contract TestableCulturalStewardsDAO is CulturalStewardsDAO {
    function getParentDAO() public view returns (Powers) { return parentDAO; }
    function getDigitalDAO() public view returns (Powers) { return digitalDAO; }
    function getTreasury() public view returns (address) { return treasury; }
    function getParentConstitutionLength() public view returns (uint256) { return parentConstitution.length; }
    function getSafeAllowanceModule() public view returns (address) { return config.safeAllowanceModule; }
}

contract CulturalStewardsDAO_IntegrationTest is Test {
    struct Mem { 
        address admin;
        uint16 initialSetupMandateId;
        uint16 setDelegateMandateId;
        uint16 initiateIdeasMandateId;
        uint16 createIdeasMandateId;
        uint16 assignRoleMandateId;
        uint16 revokeIdeasMandateId;
        uint16 initiatePhysicalId;
        uint16 createPhysicalId;
        uint16 assignRoleId;
        uint16 assignAllowanceId;
        uint16 revokeRoleId;
        uint16 revokeAllowanceId;
        uint16 assignDelegateId;
        uint16 requestPhysicalAllowanceId; 
        uint16 grantPhysicalAllowanceId;
        uint16 requestDigitalAllowanceId;
        uint16 grantDigitalAllowanceId;

        uint256 actionId;
        // Added fields to avoid stack too deep
        uint256 constitutionLength;
        uint256 packageSize;
        uint256 numPackages;
        bytes params;
        uint256 nonce;
        address physicalDAOAddress;
        bytes revokeParams;
        // Additional fields for other tests
        uint48 delegateIndex;
        address delegateAddr;
        bool isActive;
        bool isEnabled;
        address ideasDAOAddress;
        uint32 votingPeriod;
        uint32 timelock;
        uint48 roleSince;
        bytes returnData;

        address token; // ETH
        uint96 amount;
        uint16 resetTime;
        uint32 resetBase;
        address digitalDAOAddr;
        bytes allowanceParams; 

    }
    Mem mem;
    
    TestableCulturalStewardsDAO deployScript;
    Powers parentDAO;
    address treasury;
    address safeAllowanceModule;
    uint256 sepoliaFork;

    function setUp() public {
        vm.skip(false); // Remove this line to run the test
        // Create and select fork
        sepoliaFork = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
        vm.selectFork(sepoliaFork);

        // Deploy the script
        deployScript = new TestableCulturalStewardsDAO();
        deployScript.run();

        // Get the deployed contracts
        parentDAO = deployScript.getParentDAO();
        treasury = deployScript.getTreasury();
        safeAllowanceModule = deployScript.getSafeAllowanceModule();
    }

    function test_InitialSetup() public {
        // 1. Unpack mandates
        mem.constitutionLength = deployScript.getParentConstitutionLength();
        mem.packageSize = 10; 
        mem.numPackages = (mem.constitutionLength + mem.packageSize - 1) / mem.packageSize;

        console.log("Unpacking %s packages...", mem.numPackages);
        
        // Execute package mandates (sequentially)
        for (uint256 i = 1; i <= mem.numPackages; i++) {
            parentDAO.request(uint16(i), "", 0, ""); 
        }

        // 2. Identify Mandate IDs
        mem.initialSetupMandateId = uint16(mem.numPackages + 1);
        
        console.log("Executing Initial Setup Mandate ID: %s", mem.initialSetupMandateId);
        
        // 3. Execute "Initial Setup"
        parentDAO.request(mem.initialSetupMandateId, "", 0, "");

        // 4. Verify Role Labels
        assertEq(parentDAO.getRoleLabel(1), "Members", "Role 1 should be Members");
        assertEq(parentDAO.getRoleLabel(2), "Executives", "Role 2 should be Executives");
        assertEq(parentDAO.getRoleLabel(3), "Physical DAOs", "Role 3 should be Physical DAOs");
        assertEq(parentDAO.getRoleLabel(4), "Ideas DAOs", "Role 4 should be Ideas DAOs");
        assertEq(parentDAO.getRoleLabel(5), "Digital DAOs", "Role 5 should be Digital DAOs");

        // 5. Verify Treasury
        assertEq(parentDAO.getTreasury(), payable(treasury), "Treasury should be set to Safe");

        // 6. Verify Safe Module
        mem.isEnabled = Safe(payable(treasury)).isModuleEnabled(safeAllowanceModule);
        assertTrue(mem.isEnabled, "Allowance Module should be enabled on Safe");

        // 7. Verify Mandate 1 is Revoked
        (,, mem.isActive) = parentDAO.getAdoptedMandate(1); 
        assertFalse(mem.isActive, "Mandate 1 should be revoked");

        // 9. Verify Digital DAO is Delegate
        Powers digitalDAO = deployScript.getDigitalDAO();
        mem.delegateIndex = uint48(uint160(address(digitalDAO)));
        
        (mem.delegateAddr, , ) = IAllowanceModule(safeAllowanceModule).delegates(treasury, mem.delegateIndex);
        assertEq(mem.delegateAddr, address(digitalDAO), "Digital DAO should be a delegate on Allowance Module");
    }

    function test_CreateAndRevokeIdeasDAO() public {
        // 1. Unpack mandates (setup)
        mem.constitutionLength = deployScript.getParentConstitutionLength();
        mem.packageSize = 10; 
        mem.numPackages = (mem.constitutionLength + mem.packageSize - 1) / mem.packageSize;
        
        // Execute package mandates (sequentially)
        for (uint256 i = 1; i <= mem.numPackages; i++) {
            parentDAO.request(uint16(i), "", 0, ""); 
        }

        // 2. Identify Mandate IDs
        mem.initialSetupMandateId = uint16(mem.numPackages + 1);
        
        // 3. Execute "Initial Setup"
        parentDAO.request(mem.initialSetupMandateId, "", 0, "");

        // 4. Get admin user (Role 1 and 2 holder)
        mem.admin = parentDAO.getRoleHolderAtIndex(1, 0);
        console.log("Admin address: %s", mem.admin);

        // 5. Define Mandate IDs
        mem.initiateIdeasMandateId = mem.initialSetupMandateId + 1;
        mem.createIdeasMandateId = mem.initialSetupMandateId + 2;
        mem.assignRoleMandateId = mem.initialSetupMandateId + 3;
        mem.revokeIdeasMandateId = mem.initialSetupMandateId + 5;

        // --- Step 1: Initiate Ideas DAO (Members) ---
        vm.startPrank(mem.admin);
        
        mem.params = abi.encode("Test Ideas DAO", "ipfs://test");
        mem.nonce = 1;

        console.log("Initiating Ideas DAO...");
        // Propose
        mem.actionId = parentDAO.propose(mem.initiateIdeasMandateId, mem.params, mem.nonce, "");
        
        // Vote
        parentDAO.castVote(mem.actionId, 1); // 1 = For
        
        // Wait for voting period
        mem.votingPeriod = parentDAO.getConditions(mem.initiateIdeasMandateId).votingPeriod;
        vm.roll(block.number + mem.votingPeriod + 1);

        // Execute (Request)
        parentDAO.request(mem.initiateIdeasMandateId, mem.params, mem.nonce, "");
        vm.stopPrank();

        // --- Step 2: Create Ideas DAO (Executives) ---
        vm.startPrank(mem.admin);
        console.log("Creating Ideas DAO...");
        
        // Propose
        mem.actionId = parentDAO.propose(mem.createIdeasMandateId, mem.params, mem.nonce, "");
        
        // Vote
        parentDAO.castVote(mem.actionId, 1);
        
        // Wait
        mem.votingPeriod = parentDAO.getConditions(mem.createIdeasMandateId).votingPeriod;
        vm.roll(block.number + mem.votingPeriod + 1);
        
        // Execute
        mem.actionId = parentDAO.request(mem.createIdeasMandateId, mem.params, mem.nonce, "");
        vm.stopPrank();

        // --- Step 3: Assign Role Id (Executives) ---
        vm.startPrank(mem.admin);
        console.log("Assigning Role...");
        
        // Execute (No quorum, immediate execution)
        parentDAO.request(mem.assignRoleMandateId, mem.params, mem.nonce, "");
        vm.stopPrank();
        
        // --- Verify Creation ---
        mem.returnData = parentDAO.getActionReturnData(mem.actionId, 0);
        mem.ideasDAOAddress = abi.decode(mem.returnData, (address));
        console.log("Ideas DAO created at: %s", mem.ideasDAOAddress);
        
        mem.roleSince = parentDAO.hasRoleSince(mem.ideasDAOAddress, 4);
        assertTrue(mem.roleSince > 0, "Ideas DAO should have Role 4");

        // --- Step 4: Revoke Ideas DAO (Executives) ---
        vm.startPrank(mem.admin);
        console.log("Revoking Ideas DAO...");
        
        mem.revokeParams = abi.encode(mem.ideasDAOAddress);
        mem.nonce++; 
        
        // Propose Revoke
        mem.actionId = parentDAO.propose(mem.revokeIdeasMandateId, mem.revokeParams, mem.nonce, "");
        
        // Vote
        parentDAO.castVote(mem.actionId, 1);
        
        // Wait voting period + timelock
        mem.votingPeriod = parentDAO.getConditions(mem.revokeIdeasMandateId).votingPeriod;
        mem.timelock = parentDAO.getConditions(mem.revokeIdeasMandateId).timelock;
        vm.roll(block.number + mem.votingPeriod + mem.timelock + 1);
        
        // Execute
        parentDAO.request(mem.revokeIdeasMandateId, mem.revokeParams, mem.nonce, "");
        vm.stopPrank();
        
        // --- Verify Revocation ---
        mem.roleSince = parentDAO.hasRoleSince(mem.ideasDAOAddress, 4);
        assertEq(mem.roleSince, 0, "Ideas DAO should NOT have Role 4 anymore");
    }

    function test_CreateAndRevokePhysicalDAO() public {
        // 1. Unpack mandates (setup)
        mem.constitutionLength = deployScript.getParentConstitutionLength();
        mem.packageSize = 10; 
        mem.numPackages = (mem.constitutionLength + mem.packageSize - 1) / mem.packageSize;
        
        for (uint256 i = 1; i <= mem.numPackages; i++) {
            parentDAO.request(uint16(i), "", 0, ""); 
        }

        mem.initialSetupMandateId = uint16(mem.numPackages + 1);
        parentDAO.request(mem.initialSetupMandateId, "", 0, "");

        mem.admin = parentDAO.getRoleHolderAtIndex(1, 0);
        console.log("Admin: %s", mem.admin);

        // Mandate IDs
        mem.initiatePhysicalId = mem.initialSetupMandateId + 6;
        mem.createPhysicalId = mem.initialSetupMandateId + 7;
        mem.assignRoleId = mem.initialSetupMandateId + 8;
        mem.assignAllowanceId = mem.initialSetupMandateId + 9;
        mem.revokeRoleId = mem.initialSetupMandateId + 11;
        mem.revokeAllowanceId = mem.initialSetupMandateId + 12;

        vm.startPrank(mem.admin);
        
        // --- Step 1: Initiate Physical DAO ---
        mem.params = abi.encode("Physical DAO", "ipfs://physical");
        mem.nonce = 10;

        console.log("Initiating Physical DAO...");
        // Propose
        mem.actionId = parentDAO.propose(mem.initiatePhysicalId, mem.params, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        vm.roll(block.number + parentDAO.getConditions(mem.initiatePhysicalId).votingPeriod + 1);
        parentDAO.request(mem.initiatePhysicalId, mem.params, mem.nonce, "");
        
        // --- Step 2: Create Physical DAO ---
        console.log("Creating Physical DAO...");
        mem.actionId = parentDAO.propose(mem.createPhysicalId, mem.params, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        vm.roll(block.number + parentDAO.getConditions(mem.createPhysicalId).votingPeriod + 1);
        mem.actionId = parentDAO.request(mem.createPhysicalId, mem.params, mem.nonce, "");
        
        // Get address
        bytes memory returnData = parentDAO.getActionReturnData(mem.actionId, 0);
        mem.physicalDAOAddress = abi.decode(returnData, (address));
        console.log("Physical DAO created at: %s", mem.physicalDAOAddress);

        // --- Step 3: Assign Role ---
        console.log("Assigning Role...");
        parentDAO.request(mem.assignRoleId, mem.params, mem.nonce, "");
        
        // Verify Role 3 (Physical DAOs)
        assertTrue(parentDAO.hasRoleSince(mem.physicalDAOAddress, 3) > 0, "Role 3 missing");

        // --- Step 4: Assign Allowance ---
        console.log("Assigning Allowance...");
        parentDAO.request(mem.assignAllowanceId, mem.params, mem.nonce, "");
        
        // Verify Status (Delegate)  
        mem.delegateIndex = uint48(uint160(address(mem.physicalDAOAddress)));
        (mem.delegateAddr, , ) = IAllowanceModule(safeAllowanceModule).delegates(treasury, mem.delegateIndex);
        assertEq(mem.delegateAddr, mem.physicalDAOAddress, "Digital DAO should be a delegate on Allowance Module");
 
        // --- Step 5: Revoke Physical DAO ---
        console.log("Revoking Physical DAO...");
        mem.revokeParams = abi.encode(mem.physicalDAOAddress, true); // address, bool
        mem.nonce++; 

        // Revoke Role
        console.log("Revoking Role...");
        mem.actionId = parentDAO.propose(mem.revokeRoleId, mem.revokeParams, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        vm.roll(block.number + parentDAO.getConditions(mem.revokeRoleId).votingPeriod + parentDAO.getConditions(mem.revokeRoleId).timelock + 1);
        parentDAO.request(mem.revokeRoleId, mem.revokeParams, mem.nonce, "");
        
        // Verify Role Revoked
        assertEq(parentDAO.hasRoleSince(mem.physicalDAOAddress, 3), 0, "Role 3 not revoked");

        // Revoke Allowance
        console.log("Revoking Allowance...");
        parentDAO.request(mem.revokeAllowanceId, mem.revokeParams, mem.nonce, "");
        
        // Verify Allowance Revoked
        mem.delegateIndex = uint48(uint160(address(mem.physicalDAOAddress)));
        (mem.delegateAddr, , ) = IAllowanceModule(safeAllowanceModule).delegates(treasury, mem.delegateIndex);
        assertEq(mem.delegateAddr, address(0), "Digital DAO should NOT be a delegate on Allowance Module anymore");

        vm.stopPrank();
    }

    function test_AddAllowances() public {
        // 1. Unpack mandates (setup)
        mem.constitutionLength = deployScript.getParentConstitutionLength();
        mem.packageSize = 10; 
        mem.numPackages = (mem.constitutionLength + mem.packageSize - 1) / mem.packageSize;
        
        for (uint256 i = 1; i <= mem.numPackages; i++) {
            parentDAO.request(uint16(i), "", 0, ""); 
        }

        mem.initialSetupMandateId = uint16(mem.numPackages + 1);
        parentDAO.request(mem.initialSetupMandateId, "", 0, "");

        mem.admin = parentDAO.getRoleHolderAtIndex(1, 0);
        
        // Define Mandate IDs relative to Initial Setup
        // Based on script/deployOrganisations/CulturalStewardsDAO.s.sol
        mem.initiatePhysicalId = mem.initialSetupMandateId + 6;
        mem.createPhysicalId = mem.initialSetupMandateId + 7;
        mem.assignRoleId = mem.initialSetupMandateId + 8;
        mem.assignDelegateId = mem.initialSetupMandateId + 9;
        // ... (skips)
        mem.requestPhysicalAllowanceId = mem.initialSetupMandateId + 14;
        mem.grantPhysicalAllowanceId = mem.initialSetupMandateId + 15;
        mem.requestDigitalAllowanceId = mem.initialSetupMandateId + 16;
        mem.grantDigitalAllowanceId = mem.initialSetupMandateId + 17;

        // --- PREP: Create Physical DAO first ---
        vm.startPrank(mem.admin);
        mem.params = abi.encode("Physical DAO", "ipfs://physical");
        mem.nonce = 20;

        // Initiate
        mem.actionId = parentDAO.propose(mem.initiatePhysicalId, mem.params, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        vm.roll(block.number + parentDAO.getConditions(mem.initiatePhysicalId).votingPeriod + 1);
        parentDAO.request(mem.initiatePhysicalId, mem.params, mem.nonce, "");
        
        // Create
        mem.actionId = parentDAO.propose(mem.createPhysicalId, mem.params, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        vm.roll(block.number + parentDAO.getConditions(mem.createPhysicalId).votingPeriod + 1);
        mem.actionId = parentDAO.request(mem.createPhysicalId, mem.params, mem.nonce, "");
        mem.physicalDAOAddress = abi.decode(parentDAO.getActionReturnData(mem.actionId, 0), (address));
        
        // Assign Role
        parentDAO.request(mem.assignRoleId, mem.params, mem.nonce, "");
        
        // Assign Delegate Status (Necessary for Allowance Module)
        parentDAO.request(mem.assignDelegateId, mem.params, mem.nonce, "");
        vm.stopPrank();

        // --- TEST 1: Physical DAO Allowance Flow ---
        
        // Params for allowance: Sub-DAO, Token, Amount, ResetTime, ResetBase
        mem.token = address(0); // ETH
        mem.amount = 1 ether;
        mem.resetTime = 100;
        mem.resetBase = 0;
        
        mem.allowanceParams = abi.encode(
            mem.physicalDAOAddress, 
            mem.token, 
            mem.amount, 
            mem.resetTime, 
            mem.resetBase
        );
        mem.nonce++;

        // 1. Physical DAO requests allowance
        // Must be called by Role 3 (Physical DAOs). Since physicalDAOAddress holds Role 3 (via assignRole above):
        vm.startPrank(mem.physicalDAOAddress); 
        console.log("Physical DAO requesting allowance...");
        
        // Note: StatementOfIntent mandates often don't have voting periods/quorum set in script (defaults to 0),
        // effectively making them executable immediately by the proposer if allowed role matches.
        parentDAO.request(mem.requestPhysicalAllowanceId, mem.allowanceParams, mem.nonce, "");
        vm.stopPrank();

        // 2. Executives grant allowance
        vm.startPrank(mem.admin); // correct role Id? 
        console.log("Executives granting allowance to Physical DAO...");
        
        mem.actionId = parentDAO.propose(mem.grantPhysicalAllowanceId, mem.allowanceParams, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        
        // Wait voting + timelock
        mem.votingPeriod = parentDAO.getConditions(mem.grantPhysicalAllowanceId).votingPeriod;
        mem.timelock = parentDAO.getConditions(mem.grantPhysicalAllowanceId).timelock;
        vm.roll(block.number + mem.votingPeriod + mem.timelock + 1);
        
        parentDAO.request(mem.grantPhysicalAllowanceId, mem.allowanceParams, mem.nonce, "");
        vm.stopPrank();

        // Verify Allowance
        uint256[5] memory allowanceInfo = IAllowanceModule(safeAllowanceModule).getTokenAllowance(treasury, mem.physicalDAOAddress, mem.token);
        assertEq(uint96(allowanceInfo[0]), mem.amount, "Physical DAO allowance should be set");


        // --- TEST 2: Digital DAO Allowance Flow ---
        
        // Verify Digital DAO has delegate status (Checked in InitialSetup)
        Powers digitalDAO = deployScript.getDigitalDAO();
        mem.digitalDAOAddr = address(digitalDAO); // Usually this should be the address
        
        // Params for allowance
        mem.allowanceParams = abi.encode(
            mem.digitalDAOAddr, 
            mem.token, 
            mem.amount, 
            mem.resetTime, 
            mem.resetBase
        );
        mem.nonce++;

        // 1. Digital DAO requests allowance
        // Role 5 is required. In script, Role 5 is assigned to 'Cedars' address.
        // address Cedars = 0x328735d26e5Ada93610F0006c32abE2278c46211;
        address cedars = 0x328735d26e5Ada93610F0006c32abE2278c46211;
        
        vm.startPrank(cedars);
        console.log("Digital DAO (via Cedars) requesting allowance...");
        parentDAO.request(mem.requestDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
        vm.stopPrank();

        // 2. Executives grant allowance
        vm.startPrank(mem.admin);
        console.log("Executives granting allowance to Digital DAO...");
        
        mem.actionId = parentDAO.propose(mem.grantDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        
        mem.votingPeriod = parentDAO.getConditions(mem.grantDigitalAllowanceId).votingPeriod;
        mem.timelock = parentDAO.getConditions(mem.grantDigitalAllowanceId).timelock;
        vm.roll(block.number + mem.votingPeriod + mem.timelock + 1);
        
        parentDAO.request(mem.grantDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
        vm.stopPrank();

        // Verify Allowance
        allowanceInfo = IAllowanceModule(safeAllowanceModule).getTokenAllowance(treasury, mem.digitalDAOAddr, mem.token);
        assertEq(uint96(allowanceInfo[0]), mem.amount, "Digital DAO allowance should be set");
    }

    function test_PaymentOfReceipts_DigitalDAO() public {
        // --- Setup Parent DAO ---
        mem.constitutionLength = deployScript.getParentConstitutionLength();
        mem.packageSize = 10; 
        mem.numPackages = (mem.constitutionLength + mem.packageSize - 1) / mem.packageSize;
        
        for (uint256 i = 1; i <= mem.numPackages; i++) {
            parentDAO.request(uint16(i), "", 0, ""); 
        }

        mem.initialSetupMandateId = uint16(mem.numPackages + 1);
        parentDAO.request(mem.initialSetupMandateId, "", 0, "");

        mem.admin = parentDAO.getRoleHolderAtIndex(1, 0);
        
        Powers digitalDAO = deployScript.getDigitalDAO();
        mem.digitalDAOAddr = address(digitalDAO);
        
        console.log("Unpacking Digital DAO packages...");
        // Digital DAO constitution length
        // We can get it from the contract or assuming from script.
        // But better just blindly execute Mandate 1 if it's "Initial Setup".
        // In script `createDigitalConstitution`, first mandate is Initial Setup.
        // Wait, `constitute` packs mandates?
        // `digitalDAO.constitute` takes `PowersTypes.MandateInitData[]`. It doesn't automatically pack them unless `packageInitData` is called.
        // In script: `digitalDAO.constitute(digitalConstitution, msg.sender);`. It passes the array directly.
        // So Mandate 1 is indeed "Initial Setup".
        
        // Execute Digital DAO Initial Setup
        // Who can execute? `allowedRole = public`.
        console.log("Executing Digital DAO Initial Setup...");
        digitalDAO.request(1, "", 0, "");

        // --- Grant Allowance to Digital DAO (Parent DAO side) ---
        // Reusing logic from test_AddAllowances
        // Mandate IDs
        mem.requestDigitalAllowanceId = mem.initialSetupMandateId + 16;
        mem.grantDigitalAllowanceId = mem.initialSetupMandateId + 17;

        mem.token = address(0); // ETH
        mem.amount = 1 ether;
        mem.resetTime = 100;
        mem.resetBase = 0;
        
        mem.allowanceParams = abi.encode(
            mem.digitalDAOAddr, 
            mem.token, 
            mem.amount, 
            mem.resetTime, 
            mem.resetBase
        );
        mem.nonce = 100;

        // 1. Request Allowance (by Cedars - Role 5)
        address cedars = 0x328735d26e5Ada93610F0006c32abE2278c46211;
        vm.startPrank(cedars);
        mem.actionId = parentDAO.propose(mem.requestDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        parentDAO.request(mem.requestDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
        vm.stopPrank();

        // 2. Grant Allowance (by Admin - Role 2)
        vm.startPrank(mem.admin);
        mem.actionId = parentDAO.propose(mem.grantDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
        parentDAO.castVote(mem.actionId, 1);
        
        uint32 votingPeriod = parentDAO.getConditions(mem.grantDigitalAllowanceId).votingPeriod;
        uint32 timelock = parentDAO.getConditions(mem.grantDigitalAllowanceId).timelock;
        vm.roll(block.number + votingPeriod + timelock + 1);
        
        parentDAO.request(mem.grantDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
        vm.stopPrank();

        // Verify Allowance
        uint256[5] memory allowanceInfo = IAllowanceModule(safeAllowanceModule).getTokenAllowance(treasury, mem.digitalDAOAddr, mem.token);
        assertEq(uint96(allowanceInfo[0]), mem.amount, "Digital DAO allowance should be set");

        // Fund Treasury
        vm.deal(treasury, 10 ether);
        assertEq(treasury.balance, 10 ether, "Treasury should have funds");

        // --- Digital DAO Payment Flow ---
        // Mandates:
        // 2: Submit Receipt (Public)
        // 3: OK Receipt (Conveners)
        // 4: Approve Payment (Conveners)

        address recipient = address(0x123456789);
        uint256 paymentAmount = 0.5 ether;
        
        // Params: address Token, uint256 Amount, address PayableTo
        bytes memory paymentParams = abi.encode(mem.token, paymentAmount, recipient);
        
        // Step 1: Submit Receipt (Public)
        address publicUser = address(0x999);
        vm.startPrank(publicUser);
        console.log("Submitting receipt...");
        // Propose
        mem.nonce++;
        mem.actionId = digitalDAO.propose(2, paymentParams, mem.nonce, "");
        // Request (Condition: Public, usually implicit vote or direct request if StatementOfIntent)
        // Checking script: allowedRole = max (public). No voting period set -> defaults to 0.
        // So we can request immediately.
        digitalDAO.request(2, paymentParams, mem.nonce, "");
        vm.stopPrank();

        // Step 2: OK Receipt (Conveners)
        // Who is convener? Cedars (assigned in Mandate 1).
        vm.startPrank(cedars);
        console.log("OK'ing receipt...");
        mem.nonce++;
        mem.actionId = digitalDAO.propose(3, paymentParams, mem.nonce, "");
        // Request (Condition: Role 2. No voting period set).
        digitalDAO.request(3, paymentParams, mem.nonce, "");
        vm.stopPrank();

        // Step 3: Approve Payment (Conveners)
        vm.startPrank(cedars);
        console.log("Approving payment...");
        mem.nonce++;
        mem.actionId = digitalDAO.propose(4, paymentParams, mem.nonce, "");
        
        // Vote (Quorum 50%, SucceedAt 67%)
        // Cedars is likely the only role holder?
        // In Mandate 1, only Cedars is assigned Role 2.
        // So 1 vote should be 100%.
        digitalDAO.castVote(mem.actionId, 1);
        
        // Wait voting period (5 mins)
        votingPeriod = digitalDAO.getConditions(4).votingPeriod;
        vm.roll(block.number + votingPeriod + 1);
        
        // Execute
        digitalDAO.request(4, paymentParams, mem.nonce, "");
        vm.stopPrank();

        // Verify Payment
        assertEq(recipient.balance, paymentAmount, "Recipient should have received payment");
        
        // Verify Allowance Spent
        allowanceInfo = IAllowanceModule(safeAllowanceModule).getTokenAllowance(treasury, mem.digitalDAOAddr, mem.token);
        assertEq(uint96(allowanceInfo[1]), paymentAmount, "Allowance spent should match payment");
    }
}
