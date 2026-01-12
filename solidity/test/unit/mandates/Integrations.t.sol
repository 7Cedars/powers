// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { TestSetupExecutive } from "../../TestSetup.t.sol";
import { PowersMock } from "@mocks/PowersMock.sol";
import { GovernorCreateProposal } from "@src/mandates/integrations/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "@src/mandates/integrations/GovernorExecuteProposal.sol";

import { SafeAllowanceAction } from "@src/mandates/integrations/SafeAllowanceAction.sol";
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
contract GovernorIntegrationTest is TestSetupExecutive {
    SimpleGovernor public governor;
    SimpleErc20Votes public votingToken;
    GovernorCreateProposal public createProposalMandate;
    GovernorExecuteProposal public executeProposalMandate;

    uint16 public createProposalId;
    uint16 public executeProposalId;

    function setUp() public override {
        super.setUp();

        // Deploy Governor ecosystem
        votingToken = new SimpleErc20Votes();
        governor = new SimpleGovernor(address(votingToken));

        // Deploy Mandates
        createProposalMandate = new GovernorCreateProposal();
        executeProposalMandate = new GovernorExecuteProposal();

        // Configure Mandates on Powers (daoMock)
        vm.startPrank(address(daoMock));
        
        // We use arbitrary IDs for testing, ensuring they don't conflict with existing ones if any
        createProposalId = 100;
        bytes memory createConfig = abi.encode(address(governor));
        createProposalMandate.initializeMandate(
            createProposalId,
            "Create Proposal",
            "",
            createConfig
        );

        executeProposalId = 101;
        bytes memory executeConfig = abi.encode(address(governor));
        executeProposalMandate.initializeMandate(
            executeProposalId,
            "Execute Proposal",
            "",
            executeConfig
        );

        vm.stopPrank();

        // Setup Alice with votes
        votingToken.mint(1000e18);
        votingToken.transfer(alice, 1000e18);
        vm.prank(alice);
        votingToken.delegate(alice);
    }

    function test_GovernorCreateProposal_Success() public {
        // Setup proposal parameters
        address[] memory targets = new address[](1);
        targets[0] = address(votingToken);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", bob, 100e18);
        string memory description = "Test Proposal";

        // Encode mandate calldata
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        // Call handleRequest
        (
            uint256 actionId, 
            address[] memory execTargets, 
            uint256[] memory execValues, 
            bytes[] memory execCalldatas
        ) = createProposalMandate.handleRequest(
            alice, 
            address(daoMock), 
            createProposalId, 
            mandateCalldata, 
            0
        );

        // Verify execution targets
        assertEq(execTargets.length, 1);
        assertEq(execTargets[0], address(governor));
        assertEq(execValues[0], 0);

        // Verify encoded call is Governor.propose
        bytes memory expectedCall = abi.encodeWithSelector(
            Governor.propose.selector,
            targets,
            values,
            calldatas,
            description
        );
        assertEq(execCalldatas[0], expectedCall);

        // Verify actionId generation
        uint256 expectedActionId = MandateUtilities.hashActionId(createProposalId, mandateCalldata, 0);
        assertEq(actionId, expectedActionId);
    }

    function test_GovernorCreateProposal_Revert_NotConfigured() public {
        uint16 unconfiguredId = 999;
        bytes memory mandateCalldata = abi.encode(new address[](0), new uint256[](0), new bytes[](0), "");
        
        vm.expectRevert("GovernorCreateProposal: Governor contract not configured");
        createProposalMandate.handleRequest(alice, address(daoMock), unconfiguredId, mandateCalldata, 0);
    }

    function test_GovernorCreateProposal_Revert_InvalidParams() public {
        // Empty targets
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);
        string memory description = "Test";
        
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        vm.expectRevert("GovernorCreateProposal: No targets provided");
        createProposalMandate.handleRequest(alice, address(daoMock), createProposalId, mandateCalldata, 0);

        // Mismatch length
        targets = new address[](1);
        targets[0] = address(0);
        
        mandateCalldata = abi.encode(targets, values, calldatas, description);
        vm.expectRevert("GovernorCreateProposal: Targets and values length mismatch");
        createProposalMandate.handleRequest(alice, address(daoMock), createProposalId, mandateCalldata, 0);
    }

    function test_GovernorExecuteProposal_Success() public {
        // 1. Setup and Create Proposal
        address[] memory targets = new address[](1);
        targets[0] = address(votingToken);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", bob, 100e18);
        string memory description = "Test Proposal Execution";

        // Execute "propose" directly on Governor to simulate successful mandate execution
        vm.prank(address(daoMock));
        governor.propose(targets, values, calldatas, description);
        
        uint256 proposalId = governor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        // 2. Advance to voting period
        vm.roll(block.number + governor.votingDelay() + 1);

        // 3. Vote
        vm.prank(alice);
        governor.castVote(proposalId, 1); // For

        // 4. Advance to end of voting period
        vm.roll(block.number + governor.votingPeriod() + 1);

        // 5. Test Execute Mandate
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        (
            ,
            address[] memory execTargets, 
            uint256[] memory execValues, 
            bytes[] memory execCalldatas
        ) = executeProposalMandate.handleRequest(
            alice, 
            address(daoMock), 
            executeProposalId, 
            mandateCalldata, 
            0
        );

        // Verify we get back the original actions to execute
        assertEq(execTargets.length, 1);
        assertEq(execTargets[0], targets[0]);
        assertEq(execValues[0], values[0]);
        assertEq(execCalldatas[0], calldatas[0]);
    }

    function test_GovernorExecuteProposal_Revert_NotSucceeded() public {
        // 1. Setup and Create Proposal
        address[] memory targets = new address[](1);
        targets[0] = address(votingToken);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", bob, 100e18);
        string memory description = "Test Proposal Fail";

        vm.prank(address(daoMock));
        governor.propose(targets, values, calldatas, description);
        
        // 2. Try to execute immediately (Pending state)
        bytes memory mandateCalldata = abi.encode(targets, values, calldatas, description);

        vm.expectRevert("GovernorExecuteProposal: Proposal not succeeded");
        executeProposalMandate.handleRequest(alice, address(daoMock), executeProposalId, mandateCalldata, 0);

        // 3. Vote Against
        uint256 proposalId = governor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        vm.roll(block.number + governor.votingDelay() + 1);
        
        vm.prank(alice);
        governor.castVote(proposalId, 0); // Against

        vm.roll(block.number + governor.votingPeriod() + 1);

        // 4. Try to execute (Defeated state)
        vm.expectRevert("GovernorExecuteProposal: Proposal not succeeded");
        executeProposalMandate.handleRequest(alice, address(daoMock), executeProposalId, mandateCalldata, 0);
    }
}


//////////////////////////////////////////////////
//      SAFE ALLOWANCE INTEGRATION TESTS        //
//////////////////////////////////////////////////
contract SafeAllowanceTest is TestSetupExecutive {
    SafeAllowanceAction public safeAllowanceAction;
    SafeAllowanceTransfer public safeAllowanceTransfer;
    SafeExecTransaction public safeExecTransaction;

    uint16 public safeAllowanceActionId;
    uint16 public safeAllowanceTransferId;
    uint16 public safeExecTransactionId;
    
    address public allowanceModuleAddress;
    address public safeAddress;

    function setUp() public override {
        super.setUp();
        
        // Check if the Safe Allowance module address is populated. If not, skip the test.
        if (address(config.safeAllowanceModule).code.length == 0) {
            vm.skip(true);
            return;
        }

        allowanceModuleAddress = config.safeAllowanceModule;
        safeAddress = config.safeCanonical;

        // Deploy Mandates
        safeAllowanceAction = new SafeAllowanceAction();
        safeAllowanceTransfer = new SafeAllowanceTransfer();
        safeExecTransaction = new SafeExecTransaction();

        vm.startPrank(address(daoMock));
        
        // Set Treasury
        daoMock.setTreasury(payable(safeAddress));

        // 1. Configure SafeAllowanceAction
        safeAllowanceActionId = 200;
        string[] memory inputParamsAction = new string[](0);
        bytes4 selector = bytes4(keccak256("someFunction()"));
        bytes memory actionConfig = abi.encode(
            inputParamsAction, 
            selector, 
            allowanceModuleAddress
        );
        safeAllowanceAction.initializeMandate(
            safeAllowanceActionId,
            "Safe Allowance Action",
            "",
            actionConfig
        );

        // 2. Configure SafeAllowanceTransfer
        safeAllowanceTransferId = 201;
        bytes memory transferConfig = abi.encode(
            allowanceModuleAddress, 
            safeAddress
        );
        safeAllowanceTransfer.initializeMandate(
            safeAllowanceTransferId,
            "Safe Allowance Transfer",
            "",
            transferConfig
        );

        // 3. Configure SafeExecTransaction
        safeExecTransactionId = 202;
        string[] memory inputParamsExec = new string[](0);
        bytes memory execConfig = abi.encode(inputParamsExec, safeAddress);
        safeExecTransaction.initializeMandate(
            safeExecTransactionId,
            "Safe Exec Transaction",
            "",
            execConfig
        );

        vm.stopPrank();
    }

    function test_SafeAllowanceAction_Success() public {
        bytes memory mandateCalldata = abi.encode("test data");
        uint256 nonce = 1;
        
        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        ) = safeAllowanceAction.handleRequest(
            alice,
            address(daoMock),
            safeAllowanceActionId,
            mandateCalldata,
            nonce
        );
        
        assertEq(actionId, MandateUtilities.hashActionId(safeAllowanceActionId, mandateCalldata, nonce));
        assertEq(targets.length, 1);
        assertEq(targets[0], safeAddress); 
        assertEq(values[0], 0);

        // execTransaction selector: 0x6a761202
        bytes4 expectedSelector = bytes4(keccak256("execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)"));
        assertEq(bytes4(calldatas[0]), expectedSelector);
    }
    
    function test_SafeAllowanceAction_Revert_NoTreasury() public {
        // Deploy a fresh local dao without treasury
        PowersMock localDao = new PowersMock();
        SafeAllowanceAction localMandate = new SafeAllowanceAction();
        uint16 localId = 300;
        
        vm.startPrank(address(localDao));
        string[] memory inputParamsAction = new string[](0);
        bytes memory actionConfig = abi.encode(
            inputParamsAction, 
            bytes4(0xdeadbeef), 
            allowanceModuleAddress
        );
        localMandate.initializeMandate(localId, "Local", "", actionConfig);
        vm.stopPrank();

        bytes memory mandateCalldata = abi.encode("test");
        
        vm.expectRevert("SafeAllowanceAction: Treasury not set in Powers");
        localMandate.handleRequest(alice, address(localDao), localId, mandateCalldata, 0);
    }

    function test_SafeAllowanceTransfer_Success() public {
        address token = address(0x123);
        address payableTo = bob;
        uint256 amount = 100e18;
        bytes memory mandateCalldata = abi.encode(token, payableTo, amount);
        uint256 nonce = 1;

        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        ) = safeAllowanceTransfer.handleRequest(
            alice,
            address(daoMock),
            safeAllowanceTransferId,
            mandateCalldata,
            nonce
        );

        assertEq(actionId, MandateUtilities.hashActionId(safeAllowanceTransferId, mandateCalldata, nonce));
        assertEq(targets.length, 1);
        assertEq(targets[0], allowanceModuleAddress); 
        assertEq(values[0], 0);
        
        // executeAllowanceTransfer selector: 0x4515641a
        assertEq(bytes4(calldatas[0]), bytes4(0x4515641a));
    }

    function test_SafeExecTransaction_Success() public {
        address to = address(0x456);
        uint256 value = 0; 
        bytes memory data = hex"abcdef";
        bytes memory mandateCalldata = abi.encode(to, value, data);
        uint256 nonce = 1;

        (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        ) = safeExecTransaction.handleRequest(
            alice,
            address(daoMock),
            safeExecTransactionId,
            mandateCalldata,
            nonce
        );

        assertEq(actionId, MandateUtilities.hashActionId(safeExecTransactionId, mandateCalldata, nonce));
        assertEq(targets.length, 1);
        assertEq(targets[0], safeAddress);
        assertEq(values[0], 0);

        bytes4 expectedSelector = bytes4(keccak256("execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)"));
        assertEq(bytes4(calldatas[0]), expectedSelector);
    }
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
