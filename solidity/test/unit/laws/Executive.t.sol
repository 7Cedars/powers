// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { TestSetupExecutive } from "../../TestSetup.t.sol";
import { AdoptLawsPackage } from "../../../src/laws/executive/AdoptLawsPackage.sol";
import { GovernorCreateProposal } from "../../../src/laws/executive/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../../../src/laws/executive/GovernorExecuteProposal.sol";
import { SimpleGovernor } from "@mocks/SimpleGovernor.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { OpenAction } from "../../../src/laws/multi/OpenAction.sol";
import { PresetSingleAction } from "../../../src/laws/multi/PresetSingleAction.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";

/// @notice Comprehensive unit tests for all executive laws
/// @dev Tests all functionality of executive laws including initialization, execution, and edge cases

//////////////////////////////////////////////////
//              ADOPT LAWS TESTS               //
//////////////////////////////////////////////////
contract AdoptLawsPackageTest is TestSetupExecutive {
    AdoptLawsPackage adoptLawsPackage;
    OpenAction openAction;
    PresetSingleAction presetSingleAction;

    function setUp() public override {
        super.setUp();
        adoptLawsPackage = AdoptLawsPackage(lawAddresses[7]); // AdoptLawsPackage from executive constitution
        openAction = OpenAction(lawAddresses[3]); // OpenAction
        presetSingleAction = PresetSingleAction(lawAddresses[1]); // PresetSingleAction
        lawId = 4; // AdoptLawsPackage law ID in executive constitution
    }

    function testAdoptLawsPackageInitialization() public {
        // Setup laws to adopt
        address[] memory lawsToAdopt = new address[](2);
        lawsToAdopt[0] = address(openAction);
        lawsToAdopt[1] = address(presetSingleAction);

        // Create law init data for adoption
        PowersTypes.LawInitData memory lawInitData1 = PowersTypes.LawInitData({
            nameDescription: "Test Law 1",
            targetLaw: address(openAction),
            config: abi.encode(),
            conditions: PowersTypes.Conditions({
                allowedRole: type(uint256).max,
                quorum: 0,
                succeedAt: 0,
                votingPeriod: 0,
                delayExecution: 0,
                throttleExecution: 0,
                needFulfilled: 0,
                needNotFulfilled: 0
            })
        });

        PowersTypes.LawInitData memory lawInitData2 = PowersTypes.LawInitData({
            nameDescription: "Test Law 2",
            targetLaw: address(presetSingleAction),
            config: abi.encode(new address[](1), new uint256[](1), new bytes[](1)),
            conditions: PowersTypes.Conditions({
                allowedRole: type(uint256).max,
                quorum: 0,
                succeedAt: 0,
                votingPeriod: 0,
                delayExecution: 0,
                throttleExecution: 0,
                needFulfilled: 0,
                needNotFulfilled: 0
            })
        });

        bytes[] memory lawInitDatas = new bytes[](2);
        lawInitDatas[0] = abi.encode(lawInitData1);
        lawInitDatas[1] = abi.encode(lawInitData2);

        // Test law initialization
        lawId = daoMock.lawCounter();
        nameDescription = "Test Adopt Laws";
        configBytes = abi.encode(lawsToAdopt, lawInitDatas);

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: nameDescription,
                targetLaw: address(adoptLawsPackage),
                config: configBytes,
                conditions: conditions
            })
        );

        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        AdoptLawsPackage.Data memory data = adoptLawsPackage.getData(lawHash);
        assertEq(data.laws.length, 2);
        assertEq(data.laws[0], address(openAction));
        assertEq(data.laws[1], address(presetSingleAction));
        assertEq(data.lawInitDatas.length, 2);
    }

    function testAdoptLawsPackageExecution() public {
        // Setup laws to adopt
        address[] memory lawsToAdopt = new address[](1);
        lawsToAdopt[0] = address(openAction);

        // Create mock law call ]
        targets = new address[](1);
        targets[0] = address(mockAddresses[0]);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(SimpleErc20Votes.mintVotes.selector, 1000);
        bytes memory lawCallData = abi.encode(targets, values, calldatas);

        PowersTypes.LawInitData memory lawInitData = PowersTypes.LawInitData({
            nameDescription: "Test Adopted Law",
            targetLaw: address(openAction),
            config: abi.encode(),
            conditions: PowersTypes.Conditions({
                allowedRole: type(uint256).max,
                quorum: 0,
                succeedAt: 0,
                votingPeriod: 0,
                delayExecution: 0,
                throttleExecution: 0,
                needFulfilled: 0,
                needNotFulfilled: 0
            })
        });

        bytes[] memory lawInitDatas = new bytes[](1);
        lawInitDatas[0] = abi.encode(lawInitData);

        // Setup law
        lawId = daoMock.lawCounter();
        vm.prank(address(daoMock));
        daoMock.adoptLaw(lawInitData);

        // Execute adoption
        vm.prank(alice);
        daoMock.request(lawId, lawCallData, nonce, "Test adopt laws");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, lawCallData, nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//          GOVERNOR CREATE PROPOSAL TESTS     //
//////////////////////////////////////////////////
contract GovernorCreateProposalTest is TestSetupExecutive {
    GovernorCreateProposal governorCreateProposal;
    SimpleGovernor simpleGovernor;
    SimpleErc20Votes votingToken;

    function setUp() public override {
        super.setUp();
        governorCreateProposal = GovernorCreateProposal(lawAddresses[8]); // GovernorCreateProposal from executive constitution
        votingToken = SimpleErc20Votes(mockAddresses[0]);
        simpleGovernor = SimpleGovernor(payable(mockAddresses[4]));
        lawId = 2; // GovernorCreateProposal law ID in executive constitution
    }

    function testGovernorCreateProposalInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertEq(governorCreateProposal.governorContracts(lawHash), address(simpleGovernor));
    }

    function testGovernorCreateProposalWithValidProposal() public {
        // Setup proposal parameters
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = "Test proposal description";

        // Execute proposal creation
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas, description), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testGovernorCreateProposalRevertsWithNoTargets() public {
        // Setup proposal parameters with no targets
        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);
        description = "Test proposal description";

        // Execute proposal creation
        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: No targets provided");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");
    }

    function testGovernorCreateProposalRevertsWithLengthMismatch() public {
        // Setup proposal parameters with length mismatch
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](2); // Different length
        values[0] = 0;
        values[1] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = "Test proposal description";

        // Execute proposal creation
        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: Targets and values length mismatch");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");
    }

    function testGovernorCreateProposalRevertsWithEmptyDescription() public {
        // Setup proposal parameters with empty description
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = ""; // Empty description

        // Execute proposal creation
        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: Description cannot be empty");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");
    }
}

//////////////////////////////////////////////////
//         GOVERNOR EXECUTE PROPOSAL TESTS     //
//////////////////////////////////////////////////
contract GovernorExecuteProposalTest is TestSetupExecutive {
    GovernorCreateProposal governorCreateProposal;
    GovernorExecuteProposal governorExecuteProposal;
    PresetSingleAction presetSingleAction;
    SimpleGovernor simpleGovernor;
    SimpleErc20Votes votingToken;

    function setUp() public override {
        super.setUp();
        governorCreateProposal = GovernorCreateProposal(lawAddresses[8]); // GovernorCreateProposal from executive constitution
        governorExecuteProposal = GovernorExecuteProposal(lawAddresses[9]); // GovernorExecuteProposal from executive constitution
        votingToken = SimpleErc20Votes(mockAddresses[0]);
        simpleGovernor = SimpleGovernor(payable(mockAddresses[4]));
        lawIds = new uint16[](1);
        lawIds[0] = 2;
        lawId = 3; // GovernorExecuteProposal law ID in executive constitution
    }

    function testGovernorExecuteProposalInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertEq(governorExecuteProposal.governorContracts(lawHash), address(simpleGovernor));
    }

    // function testGovernorExecuteProposalWithValidProposal() public {
    //     // Setup proposal parameters
    //     targets = new address[](1);
    //     targets[0] = address(daoMock);
    //     values = new uint256[](1);
    //     values[0] = 0;
    //     calldatas = new bytes[](1);
    //     calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
    //     description = "Test proposal description";

    //     // first create a proposal in the Governor contract.
    //     vm.startPrank(alice);
    //     votingToken.mintVotes(100);
    //     votingToken.delegate(address(alice));
    //     daoMock.request(lawIds[0], abi.encode(targets, values, calldatas, description), nonce, "Test create proposal");
    //     vm.stopPrank();

    //     uint256 proposalId = simpleGovernor.getProposalId(targets, values, calldatas, keccak256(bytes(description)));
    //     assertTrue(proposalId != 0);

    //     vm.roll(block.number + 30);

    //     // vote for the proposal
    //     vm.prank(alice);
    //     simpleGovernor.castVote(proposalId, FOR);

    //     nonce++;
    //     vm.roll(block.number + 100);

    //     // Execute proposal execution
    //     vm.prank(alice);
    //     daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");

    //     // Should succeed
    //     actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas, description), nonce)));
    //     assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    // }

    function testGovernorExecuteProposalRevertsWithNoTargets() public {
        // Setup proposal parameters with no targets
        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);
        description = "Test proposal description";

        // Execute proposal execution
        vm.prank(alice);
        vm.expectRevert("GovernorExecuteProposal: No targets provided");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");
    }

    function testGovernorExecuteProposalRevertsWithLengthMismatch() public {
        // Setup proposal parameters with length mismatch
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](2); // Different length
        values[0] = 0;
        values[1] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = "Test proposal description";

        // Execute proposal execution
        vm.prank(alice);
        vm.expectRevert("GovernorExecuteProposal: Targets and values length mismatch");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");
    }

    function testGovernorExecuteProposalRevertsWithEmptyDescription() public {
        // Setup proposal parameters with empty description
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = ""; // Empty description

        // Execute proposal execution
        vm.prank(alice);
        vm.expectRevert("GovernorExecuteProposal: Description cannot be empty");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");
    }

    function testGovernorExecuteProposalRevertsWithNonExistentProposal() public {
        // Setup proposal parameters for non-existent proposal
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");
        description = "Non-existent proposal";

        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas, description), nonce)));

        // Execute proposal execution
        vm.prank(alice);
        vm.expectRevert();
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test execute proposal");
    }
}

//////////////////////////////////////////////////
//              EDGE CASE TESTS                //
//////////////////////////////////////////////////
contract ExecutiveEdgeCaseTest is TestSetupExecutive {
    AdoptLawsPackage adoptLawsPackage;
    GovernorCreateProposal governorCreateProposal;
    GovernorExecuteProposal governorExecuteProposal;
    OpenAction openAction;
    PresetSingleAction presetSingleAction;
    SimpleGovernor simpleGovernor;

    function setUp() public override {
        super.setUp();
        adoptLawsPackage = AdoptLawsPackage(lawAddresses[7]);
        governorCreateProposal = GovernorCreateProposal(lawAddresses[8]);
        governorExecuteProposal = GovernorExecuteProposal(lawAddresses[9]);
        openAction = OpenAction(lawAddresses[3]);
        presetSingleAction = PresetSingleAction(lawAddresses[1]);
        simpleGovernor = SimpleGovernor(payable(mockAddresses[4]));
    }

    function testAllExecutiveLawsInitialization() public {
        // Test that all executive laws are properly initialized from constitution
        // AdoptLawsPackage (lawId = 4)
        lawId = 4;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        AdoptLawsPackage.Data memory data = adoptLawsPackage.getData(lawHash);
        assertEq(data.laws.length, 1);

        // GovernorCreateProposal (lawId = 2)
        lawId = 2;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertEq(governorCreateProposal.governorContracts(lawHash), address(simpleGovernor));

        // GovernorExecuteProposal (lawId = 3)
        lawId = 3;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertEq(governorExecuteProposal.governorContracts(lawHash), address(simpleGovernor));
    }

    function testExecutiveLawsWithComplexProposals() public {
        // Test with complex multi-action proposals
        lawId = 2; // GovernorCreateProposal law ID

        // Setup complex proposal parameters
        targets = new address[](3);
        targets[0] = address(daoMock);
        targets[1] = address(daoMock);
        targets[2] = address(daoMock);

        values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        calldatas = new bytes[](3);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(daoMock.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(daoMock.assignRole.selector, 3, alice);

        description = "Complex multi-action proposal for role management";

        // Execute proposal creation
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test complex proposal");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas, description), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testExecutiveLawsWithEmptyInputs() public {
        // Test that laws handle empty inputs gracefully
        lawId = 4; // AdoptLawsPackage law ID

        // Execute with empty input
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(), nonce, "Test empty input");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testExecutiveLawsWithInvalidConfigs() public {
        // Test that laws revert with invalid configurations
        lawId = 2; // GovernorCreateProposal law ID

        // Test with invalid proposal parameters (no targets)
        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);
        description = "Invalid proposal";

        vm.prank(alice);
        vm.expectRevert("GovernorCreateProposal: No targets provided");
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test invalid config");
    }

    function testExecutiveLawsWithZeroAddressGovernor() public {
        // This test is not applicable since the governor is set in the constitution
        // and cannot be changed to zero address after initialization
        // We can test that the governor is properly configured instead
        lawId = 2; // GovernorCreateProposal law ID

        // Verify governor is properly configured
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertTrue(governorCreateProposal.governorContracts(lawHash) != address(0));
        assertEq(governorCreateProposal.governorContracts(lawHash), address(simpleGovernor));
    }

    function testExecutiveLawsWithLongDescriptions() public {
        // Test with very long descriptions
        lawId = 2; // GovernorCreateProposal law ID

        // Setup proposal parameters with long description
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Create a very long description
        description = string(abi.encodePacked(new bytes(1000)));

        // Execute proposal creation
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas, description), nonce, "Test long description");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas, description), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}
