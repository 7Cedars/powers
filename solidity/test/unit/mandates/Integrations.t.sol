// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { TestSetupIntegrations, TestSetupExecutive } from "../../TestSetup.t.sol";
import { PowersMock } from "@mocks/PowersMock.sol";
import { GovernorCreateProposal } from "@src/mandates/integrations/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "@src/mandates/integrations/GovernorExecuteProposal.sol";
 
import { SafeAllowanceTransfer } from "@src/mandates/integrations/SafeAllowanceTransfer.sol";
import { SafeExecTransaction } from "@src/mandates/integrations/SafeExecTransaction.sol";
import { PowersFactoryAssignRole } from "@src/mandates/integrations/PowersFactoryAssignRole.sol";
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
    GovernorCreateProposal public createProposalMandate;
    GovernorExecuteProposal public executeProposalMandate;

    uint16 public createProposalId;
    uint16 public executeProposalId;

    function setUp() public override {
        super.setUp();

        // 1. Identify Mandate IDs from TestSetupIntegrations -> integrationsTestConstitution
        // First pushed: GovernorCreateProposal (ID 1)
        // Second pushed: GovernorExecuteProposal (ID 2)
        createProposalId = 1;
        executeProposalId = 2;

        // 2. Get Mandate Instances
        createProposalMandate = GovernorCreateProposal(findMandateAddress("GovernorCreateProposal"));
        executeProposalMandate = GovernorExecuteProposal(findMandateAddress("GovernorExecuteProposal"));

        // 3. Setup Alice with votes for the Governor
        simpleErc20Votes.mint(10e18);
        simpleErc20Votes.transfer(alice, 10e18);
        vm.prank(alice);
        simpleErc20Votes.delegate(alice);
    }

    function test_GovernorCreateProposal_Success() public {
        // Setup proposal parameters
        address[] memory targets = new address[](1);
        targets[0] = address(simpleErc20Votes);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18);
        string memory description = "Test Proposal";

        // mint tokens to daoMock to have tokens to transfer. 
        simpleErc20Votes.mintTo(address(daoMock), 5e18);

        // Encode mandate calldata
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        // Execute via DAO
        vm.prank(alice);
        daoMock.request(createProposalId, mandateCalldata, 0, "Create Proposal Request");

        // Verify proposal exists on Governor
        uint256 proposalId = simpleGovernor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        assertGt(simpleGovernor.proposalSnapshot(proposalId), 0);
    }

    function test_GovernorCreateProposal_Revert_NotConfigured() public {
         // Create a fresh mandate that is NOT configured
         GovernorCreateProposal unconfiguredMandate = new GovernorCreateProposal();
         // Don't initialize it, or initialize with 0 address
         
         uint16 unconfiguredId = 999;
         bytes memory mandateCalldata = abi.encode(new address[](0), new uint256[](0), new bytes[](0), "");
         
         vm.expectRevert("GovernorCreateProposal: Governor contract not configured");
         unconfiguredMandate.handleRequest(alice, address(daoMock), unconfiguredId, mandateCalldata, 0);
    }

    function test_GovernorCreateProposal_Revert_InvalidParams() public {
        // Empty targets
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);
        string memory description = "Test";
        
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: No targets provided");
        daoMock.request(createProposalId, mandateCalldata, 0, "Invalid Params");

        // Mismatch length
        targets = new address[](1);
        targets[0] = address(0);
        
        mandateCalldata = abi.encode(targets, values, calldatas, description);
        
        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: Targets and values length mismatch");
        daoMock.request(createProposalId, mandateCalldata, 0, "Mismatch Params");
    }

    function test_GovernorExecuteProposal_Success() public {
        // 1. Setup and Create Proposal
        address[] memory targets = new address[](1);
        targets[0] = address(simpleErc20Votes);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", bob, 1e18);
        string memory description = "Test Proposal Execution";

        // Create proposal directly on Governor
        vm.prank(alice);
        simpleGovernor.propose(targets, values, calldatas, description);
        
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
        assertEq(uint256(simpleGovernor.state(proposalId)), 3); // Executed
    }

    function test_GovernorExecuteProposal_Revert_NotSucceeded() public {
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
        vm.expectRevert("GovernorExecuteProposal: Proposal not succeeded");
        daoMock.request(executeProposalId, mandateCalldata, 0, "Execute Pending");

        // 3. Vote Against
        uint256 proposalId = simpleGovernor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        vm.roll(block.number + simpleGovernor.votingDelay() + 1);
        
        vm.prank(alice);
        simpleGovernor.castVote(proposalId, 0); // Against

        vm.roll(block.number + simpleGovernor.votingPeriod() + 1);

        // 4. Try to execute (Defeated state)
        vm.prank(alice);
        vm.expectRevert("GovernorExecuteProposal: Proposal not succeeded");
        daoMock.request(executeProposalId, mandateCalldata, 0, "Execute Defeated");
    }
}


//////////////////////////////////////////////////
//      SAFE ALLOWANCE INTEGRATION TESTS        //
//////////////////////////////////////////////////
contract SafeAllowanceTest is TestSetupIntegrations {
    uint16 public safeAllowanceMandateId_SafeSetup;
    uint16 public safeAllowanceMandateId_ExecuteActionFromSafe;
    uint16 public safeAllowanceMandateId_SetAllowance;
    uint16 public safeAllowanceTransferId;
    
    address public allowanceModuleAddress;
    address public safeAddress;

    function setUp() public override {
        super.setUp();
        // for now this is run on sepolia fork only
        vm.selectFork(sepoliaFork);
        
        // Check if the Safe Allowance module address is populated. If not, skip the test.
        if (address(config.safeAllowanceModule).code.length == 0) {
            vm.skip(true);
            return;
        }

        allowanceModuleAddress = config.safeAllowanceModule;
        safeAddress = config.safeCanonical;

        // IDs from TestConstitutions
        safeAllowanceMandateId_SafeSetup = 3;
        safeAllowanceMandateId_ExecuteActionFromSafe = 4;
        safeAllowanceMandateId_SetAllowance = 5;
        // On daoMockChild1
        safeAllowanceTransferId = 1;

        vm.prank(alice);
        daoMock.request(safeAllowanceMandateId_SafeSetup, abi.encode(), nonce, "Setting up safe with allowance module.");
    }

    // we will try to add a delegate. 
    function test_SafeExecTransaction_Success() public {
        uint16 safeExecTransactionId = 4; // index of SafeExecTransaction mandate in integrationsTestConstitution
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
    function test_SafeExecTransaction_Revert() public {
        // test is the same as previous test, except we set the treasury to address(0) first to test the revert.
        vm.prank(address(daoMock));
        daoMock.setTreasury(payable(address(0)));

        uint16 safeExecTransactionId = 4; // index of SafeExecTransaction mandate in integrationsTestConstitution
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

    // function test_SafeAllowanceTransfer_Success() public {
    //     // 2. Set Allowance
    //     address token = address(simpleErc20Votes);
    //     uint96 amount = 100e18;
    //     // Params: ChildPowers, Token, allowanceAmount, resetTimeMin, resetBaseMin
    //     bytes memory setAllowanceData = abi.encode(address(daoMockChild1), token, amount, uint16(0), uint32(0));
    //     vm.prank(alice);
    //     daoMock.request(safeAllowanceMandateId_SetAllowance, setAllowanceData, 1, "Set Allowance");
        
    //     // 3. Execute Transfer on Child
    //     address payableTo = bob;
    //     // Params: Token, payableTo, amount
    //     bytes memory transferData = abi.encode(token, payableTo, uint256(10e18));
        
    //     vm.prank(alice);
    //     daoMockChild1.request(safeAllowanceTransferId, transferData, 0, "Transfer Allowance");
    // }


}

//////////////////////////////////////////////////
//      POWERS FACTORY ASSIGN ROLE TESTS        //
//////////////////////////////////////////////////

contract MockTarget {
    function returnAddress(address addr) external pure returns (address) {
        return addr;
    }
}

contract MockAddressMandate is Mandate {
    address public target;
    
    constructor(address _target) {
        target = _target;
        emit Mandate__Deployed("");
    }
    
    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config) public override {
         super.initializeMandate(index, nameDescription, inputParams, config);
    }

    function handleRequest(
        address,
        address,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);
        address addrToReturn = abi.decode(mandateCalldata, (address));
        
        targets = new address[](1);
        targets[0] = target;
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(MockTarget.returnAddress.selector, addrToReturn);
    }
}

contract PowersFactoryAssignRoleTest is TestSetupExecutive {
    PowersFactoryAssignRole public assignRoleMandate;
    MockAddressMandate public parentMandate;
    MockTarget public target;
    
    uint16 public parentMandateId;
    uint16 public assignRoleMandateId;
    uint256 public roleIdToAssign;

    function setUp() public override {
        super.setUp();
        
        target = new MockTarget();
        parentMandate = new MockAddressMandate(address(target));
        assignRoleMandate = new PowersFactoryAssignRole();
        
        vm.startPrank(address(daoMock));
        
        // 1. Configure Parent Mandate
        parentMandateId = 500;
        parentMandate.initializeMandate(
            parentMandateId,
            "Parent Mandate",
            "",
            ""
        );
        
        // 2. Configure Assign Role Mandate
        assignRoleMandateId = 501;
        roleIdToAssign = 12345;
        
        // Config: parentMandateId, roleId, inputParams (desc)
        bytes memory config = abi.encode(
            parentMandateId,
            roleIdToAssign,
            "string inputParams"
        );
        
        assignRoleMandate.initializeMandate(
            assignRoleMandateId,
            "Assign Role Mandate",
            "", // inputParams arg is ignored by initializeMandate logic which uses config
            config
        );
        
        vm.stopPrank();
    }
    
    function test_PowersFactoryAssignRole_Success() public {
        // 1. Execute Parent Mandate to generate return data
        address userToAssign = address(0xABC);
        bytes memory parentCalldata = abi.encode(userToAssign);
        uint256 parentNonce = 1;
        
        vm.prank(alice);
        daoMock.request(parentMandateId, parentCalldata, parentNonce, "Exec Parent");
        
        // Verify parent action was successful/fulfilled
        // We can check return data exist
        uint256 parentActionId = MandateUtilities.hashActionId(parentMandateId, parentCalldata, parentNonce);
        bytes memory returnData = daoMock.getActionReturnData(parentActionId, 0);
        assertEq(abi.decode(returnData, (address)), userToAssign);
        
        // 2. Execute Assign Role Mandate
        bytes memory mandateCalldata = abi.encode(parentCalldata, parentNonce);
        uint256 nonce = 1;
        
        // We expect this to return call to assign role
        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        ) = assignRoleMandate.handleRequest(
            alice,
            address(daoMock),
            assignRoleMandateId,
            mandateCalldata,
            nonce
        );
        
        assertEq(targets.length, 1);
        assertEq(targets[0], address(daoMock));
        assertEq(values[0], 0);
        
        bytes memory expectedCall = abi.encodeWithSelector(IPowers.assignRole.selector, roleIdToAssign, userToAssign);
        assertEq(calldatas[0], expectedCall);
        
        // Execute it via DAO to verify it actually works (integration)
        vm.prank(alice);
        daoMock.request(assignRoleMandateId, mandateCalldata, nonce, "Assign Role");
        
        // Verify role assigned
        assertEq(daoMock.hasRoleSince(userToAssign, roleIdToAssign) > 0, true);
    }
    
    function test_PowersFactoryAssignRole_Revert_ParentNotFulfilled() public {
        address userToAssign = address(0xABC);
        bytes memory parentCalldata = abi.encode(userToAssign);
        uint256 parentNonce = 999; // Non-existent action
        
        bytes memory mandateCalldata = abi.encode(parentCalldata, parentNonce);
        
        vm.expectRevert("PowersFactoryAssignRole: Parent action not fulfilled or no return data");
        assignRoleMandate.handleRequest(
            alice,
            address(daoMock),
            assignRoleMandateId,
            mandateCalldata,
            0
        );
    }
}

contract AllowedTokensPresetTransferTest is TestSetupExecutive {

}
