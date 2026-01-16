// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test, console, console2 } from "forge-std/Test.sol";
import { Powers } from "../../../src/Powers.sol";
import { IPowers } from "../../../src/interfaces/IPowers.sol";
import { CulturalStewardsDAO } from "../../../script/deployOrganisations/CulturalStewardsDAO.s.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";

interface IAllowanceModule {
    function delegates(address safe, uint48 index) external view returns (address delegate, uint48 prev, uint48 next);
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
    TestableCulturalStewardsDAO deployScript;
    Powers parentDAO;
    address treasury;
    address safeAllowanceModule;
    uint256 sepoliaFork;

    function setUp() public {
        vm.skip(true); // Remove this line to run the test
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
        uint256 constitutionLength = deployScript.getParentConstitutionLength();
        uint256 packageSize = 10; 
        uint256 numPackages = (constitutionLength + packageSize - 1) / packageSize;

        console.log("Unpacking %s packages...", numPackages);
        
        // Execute package mandates (sequentially)
        for (uint256 i = 1; i <= numPackages; i++) {
            parentDAO.request(uint16(i), "", 0, ""); 
        }

        // 2. Identify Mandate IDs
        // The packages take IDs 1 to numPackages.
        // The "Initial Setup" is the first mandate in the constitution, so it is the first mandate unpacked.
        // It takes the next available ID: numPackages + 1.
        uint16 initialSetupMandateId = uint16(numPackages + 1);
        // The "Set Digital DAO delegate" is the second mandate -> ID: numPackages + 2
        uint16 setDelegateMandateId = uint16(numPackages + 2);
        
        console.log("Executing Initial Setup Mandate ID: %s", initialSetupMandateId);
        
        // 3. Execute "Initial Setup"
        // It allows public execution (allowedRole = type(uint256).max)
        parentDAO.request(initialSetupMandateId, "", 0, "");

        // 4. Verify Role Labels
        assertEq(parentDAO.getRoleLabel(1), "Members", "Role 1 should be Members");
        assertEq(parentDAO.getRoleLabel(2), "Executives", "Role 2 should be Executives");
        assertEq(parentDAO.getRoleLabel(3), "Physical DAOs", "Role 3 should be Physical DAOs");
        assertEq(parentDAO.getRoleLabel(4), "Ideas DAOs", "Role 4 should be Ideas DAOs");
        assertEq(parentDAO.getRoleLabel(5), "Digital DAOs", "Role 5 should be Digital DAOs");

        // 5. Verify Treasury
        assertEq(parentDAO.getTreasury(), payable(treasury), "Treasury should be set to Safe");

        // 6. Verify Safe Module
        bool isEnabled = Safe(payable(treasury)).isModuleEnabled(safeAllowanceModule);
        assertTrue(isEnabled, "Allowance Module should be enabled on Safe");

        // 7. Verify Mandate 1 is Revoked
        // The Initial Setup mandate (via calldata) revokes Mandate 1 (the first package)
        (,, bool active) = parentDAO.getAdoptedMandate(1); 
        assertFalse(active, "Mandate 1 should be revoked");

        // // 8. Execute "Set Digital DAO delegate"
        // console.log("Executing Set Delegate Mandate ID: %s", setDelegateMandateId);
        // parentDAO.request(setDelegateMandateId, "", 0, "");

        // 9. Verify Digital DAO is Delegate
        Powers digitalDAO = deployScript.getDigitalDAO();
        // AllowanceModule uses uint48 of address as index
        uint48 delegateIndex = uint48(uint160(address(digitalDAO)));
        
        (address delegateAddr, , ) = IAllowanceModule(safeAllowanceModule).delegates(treasury, delegateIndex);
        
        assertEq(delegateAddr, address(digitalDAO), "Digital DAO should be a delegate on Allowance Module");
    }
}
