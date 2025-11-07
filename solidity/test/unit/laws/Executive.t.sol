// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { TestSetupExecutive, TestSetupMulti } from "../../TestSetup.t.sol";
import { AdoptLawsPackage } from "../../../src/laws/executive/AdoptLawsPackage.sol"; 
import { SimpleGovernor } from "@mocks/SimpleGovernor.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";
import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";
import { PresetSingleAction } from "../../../src/laws/executive/PresetSingleAction.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol"; 
import { StatementOfIntent } from "../../../src/laws/executive/StatementOfIntent.sol";
import { BespokeActionSimple } from "../../../src/laws/executive/BespokeActionSimple.sol"; 
import { PresetMultipleActions } from "../../../src/laws/executive/PresetMultipleActions.sol";
import { BespokeActionAdvanced } from "../../../src/laws/executive/BespokeActionAdvanced.sol";


/// @notice Comprehensive unit tests for all executive laws
/// @dev Tests all functionality of executive laws including initialization, execution, and edge cases

//////////////////////////////////////////////////
//              OPEN ACTION TESTS              //
//////////////////////////////////////////////////
contract OpenActionTest is TestSetupMulti {
    OpenAction openAction;

    function setUp() public override {
        super.setUp();
        openAction = OpenAction(lawAddresses[3]); // OpenAction from multi constitution
        lawId = 1; // OpenAction law ID in multi constitution
    }

    function testOpenActionInitialization() public {
        // Verify law is properly initialized
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        // OpenAction doesn't store data, just verifies it's accessible
        assertTrue(address(openAction) != address(0));
    }

    function testOpenActionWithValidCall() public {
        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Execute open action
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test open action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testOpenActionWithMultipleCalls() public {
        // Setup multiple calls
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

        // Execute open action
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test multiple calls");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testOpenActionWithEmptyInput() public {
        // Execute with empty input
        vm.prank(alice);

        // Should fail: no targets, values, calldata provided
        vm.expectRevert();
        daoMock.request(lawId, abi.encode(), nonce, "Test empty input");
    }

    function testOpenActionHandleRequestDirectly() public {
        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Call handleRequest directly to ensure coverage
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = openAction.handleRequest(alice, address(daoMock), lawId, abi.encode(targets, values, calldatas), nonce);

        // Verify the returned values match what we sent
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce))));
        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], address(daoMock));
        assertEq(returnedValues.length, 1);
        assertEq(returnedValues[0], 0);
        assertEq(returnedCalldatas.length, 1);
        assertEq(returnedCalldatas[0], calldatas[0]);
    }
}

//////////////////////////////////////////////////
//          STATEMENT OF INTENT TESTS         //
//////////////////////////////////////////////////
contract StatementOfIntentTest is TestSetupMulti {
    StatementOfIntent statementOfIntent;

    function setUp() public override {
        super.setUp();
        statementOfIntent = StatementOfIntent(lawAddresses[4]); // StatementOfIntent from multi constitution
        lawId = 2; // StatementOfIntent law ID in multi constitution
    }

    function testStatementOfIntentInitialization() public {
        // Verify law is properly initialized
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        // StatementOfIntent doesn't store data, just verifies it's accessible
        assertTrue(address(statementOfIntent) != address(0));
    }

    function testStatementOfIntentWithValidCall() public {
        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Execute statement of intent
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test statement of intent");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testStatementOfIntentWithMultipleCalls() public {
        // Setup multiple calls
        targets = new address[](2);
        targets[0] = address(daoMock);
        targets[1] = address(daoMock);

        values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        calldatas = new bytes[](2);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(daoMock.labelRole.selector, 2, "Delegate");

        // Execute statement of intent
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test multiple statements");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testStatementOfIntentHandleRequestDirectly() public {
        // Setup call data
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test Role");

        // Call handleRequest directly to ensure coverage
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = statementOfIntent.handleRequest(
            alice, address(daoMock), lawId, abi.encode(targets, values, calldatas), nonce
        );

        // Verify the returned values is empty
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce))));
        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], address(0));
        assertEq(returnedValues.length, 1);
        assertEq(returnedValues[0], 0);
        assertEq(returnedCalldatas.length, 1);
    }
}

//////////////////////////////////////////////////
//         BESPOKE ACTION SIMPLE TESTS        //
//////////////////////////////////////////////////
contract BespokeActionSimpleTest is TestSetupMulti {
    BespokeActionSimple bespokeActionSimple;
    SimpleErc1155 erc1155Mock;

    function setUp() public override {
        super.setUp();
        bespokeActionSimple = BespokeActionSimple(lawAddresses[6]); // BespokeActionSimple from multi constitution
        erc1155Mock = SimpleErc1155(mockAddresses[3]); // SimpleErc1155 mock
        lawId = 3; // BespokeActionSimple law ID in multi constitution
    }

    function testBespokeActionSimpleInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertEq(bespokeActionSimple.targetContract(lawHash), address(erc1155Mock));
        assertEq(bespokeActionSimple.targetFunction(lawHash), SimpleErc1155.mintCoins.selector);
    }

    function testBespokeActionSimpleWithValidCall() public {
        // Execute with valid parameters
        uint256 quantity = 100;
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(quantity), nonce, "Test bespoke simple");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(quantity), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBespokeActionSimpleWithZeroQuantity() public {
        // Execute with zero quantity
        uint256 quantity = 0;
        vm.prank(alice);
        vm.expectRevert(SimpleErc1155.SimpleErc1155__NoZeroAmount.selector);
        daoMock.request(lawId, abi.encode(quantity), nonce, "Test zero quantity");
    }

    function testBespokeActionSimpleWithLargeQuantity() public {
        // Execute with large quantity
        uint256 quantity = 1_000_000;
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(quantity), nonce, "Test large quantity");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(quantity), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//         PRESET SINGLE ACTION TESTS        //
//////////////////////////////////////////////////
contract PresetSingleActionTest is TestSetupMulti {
    PresetSingleAction presetSingleAction;

    function setUp() public override {
        super.setUp();
        presetSingleAction = PresetSingleAction(lawAddresses[1]); // PresetSingleAction from multi constitution
        lawId = 5; // PresetSingleAction law ID in multi constitution
    }

    function testPresetSingleActionInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        PresetSingleAction.Data memory data = presetSingleAction.getData(lawHash);
        assertEq(data.targets.length, 2);
        assertEq(data.targets[0], address(daoMock));
        assertEq(data.targets[1], address(daoMock));
        assertEq(data.values.length, 2);
        assertEq(data.calldatas.length, 2);
    }

    function testPresetSingleActionExecution() public {
        // Execute preset action (no input needed, just trigger)
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(), nonce, "Test preset single action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetSingleActionWithInput() public {
        // Execute with input (should be ignored for preset actions)
        vm.prank(alice);
        daoMock.request(lawId, abi.encode("some input"), nonce, "Test preset with input");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode("some input"), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//        PRESET MULTIPLE ACTIONS TESTS       //
//////////////////////////////////////////////////
contract PresetMultipleActionsTest is TestSetupMulti {
    PresetMultipleActions presetMultipleActions;

    function setUp() public override {
        super.setUp();
        presetMultipleActions = PresetMultipleActions(lawAddresses[2]); // PresetMultipleActions from multi constitution
        lawId = 6; // PresetMultipleActions law ID in multi constitution
    }

    function testPresetMultipleActionsInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        PresetMultipleActions.Data memory data = presetMultipleActions.getData(lawHash);
        assertEq(data.descriptions.length, 2);
        assertEq(data.targets.length, 2);
        assertEq(data.values.length, 2);
        assertEq(data.calldatas.length, 2);
    }

    function testPresetMultipleActionsWithFirstAction() public {
        // Execute first action only
        bool[] memory selections = new bool[](2);
        selections[0] = true; // Select first action
        selections[1] = false; // Don't select second action

        vm.prank(alice);
        daoMock.request(lawId, abi.encode(selections), nonce, "Test first action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsWithSecondAction() public {
        // Execute second action only
        bool[] memory selections = new bool[](2);
        selections[0] = false; // Don't select first action
        selections[1] = true; // Select second action

        vm.prank(alice);
        daoMock.request(lawId, abi.encode(selections), nonce, "Test second action");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsWithBothActions() public {
        // Execute both actions
        bool[] memory selections = new bool[](2);
        selections[0] = true; // Select first action
        selections[1] = true; // Select second action

        vm.prank(alice);
        daoMock.request(lawId, abi.encode(selections), nonce, "Test both actions");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsWithNoActions() public {
        // Execute no actions
        bool[] memory selections = new bool[](2);
        selections[0] = false; // Don't select first action
        selections[1] = false; // Don't select second action

        vm.prank(alice);
        daoMock.request(lawId, abi.encode(selections), nonce, "Test no actions");

        // Should succeed (no operations)
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsHandleRequestDirectly() public {
        // Execute first action only
        bool[] memory selections = new bool[](2);
        selections[0] = true; // Select first action
        selections[1] = false; // Don't select second action

        // Call handleRequest directly to ensure coverage
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = presetMultipleActions.handleRequest(alice, address(daoMock), lawId, abi.encode(selections), nonce);

        // Verify the returned values
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, abi.encode(selections), nonce))));
        assertEq(returnedTargets.length, 1); // Only first action selected
        assertEq(returnedValues.length, 1);
        assertEq(returnedCalldatas.length, 1);
        // Should be the first action's call to labelRole
        assertEq(returnedTargets[0], address(daoMock));
        assertEq(returnedValues[0], 0);
    }
}

//////////////////////////////////////////////////
//        BESPOKE ACTION ADVANCED TESTS       //
//////////////////////////////////////////////////
contract BespokeActionAdvancedTest is TestSetupMulti {
    BespokeActionAdvanced bespokeActionAdvanced;

    function setUp() public override {
        super.setUp();
        bespokeActionAdvanced = BespokeActionAdvanced(lawAddresses[5]); // BespokeActionAdvanced from multi constitution
        lawId = 4; // BespokeActionAdvanced law ID in multi constitution
    }

    function testBespokeActionAdvancedInitialization() public {
        // Verify law is properly initialized
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        // BespokeActionAdvanced stores data internally, just verify it's accessible
        assertTrue(address(bespokeActionAdvanced) != address(0));
    }

    function testBespokeActionAdvancedWithValidCall() public {
        // Execute with valid account parameter
        bytes[] memory dynamicParts = new bytes[](1);
        dynamicParts[0] = abi.encode(alice); // account to assign role to

        vm.prank(alice);
        daoMock.request(lawId, abi.encode(dynamicParts), nonce, "Test bespoke advanced");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(dynamicParts), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBespokeActionAdvancedWithDifferentAccount() public {
        // Execute with different account
        bytes[] memory dynamicParts = new bytes[](1);
        dynamicParts[0] = abi.encode(bob); // different account

        vm.prank(alice);
        daoMock.request(lawId, abi.encode(dynamicParts), nonce, "Test different account");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(dynamicParts), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBespokeActionAdvancedHandleRequestDirectly() public {
        // Setup dynamic parts for the function call
        bytes[] memory dynamicParts = new bytes[](1);
        dynamicParts[0] = abi.encode(alice); // account to assign role to

        // Call handleRequest directly to ensure coverage
        (
            uint256 actionId,
            address[] memory returnedTargets,
            uint256[] memory returnedValues,
            bytes[] memory returnedCalldatas
        ) = bespokeActionAdvanced.handleRequest(alice, address(daoMock), lawId, abi.encode(dynamicParts), nonce);

        // Verify the returned values
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, abi.encode(dynamicParts), nonce))));
        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], address(daoMock));
        assertEq(returnedValues.length, 1);
        assertEq(returnedValues[0], 0);
        assertEq(returnedCalldatas.length, 1);
        // The calldata should be the encoded function call to assignRole
        assertEq(returnedCalldatas[0], abi.encodeWithSelector(daoMock.assignRole.selector, 1, alice));
    }
}

//////////////////////////////////////////////////
//              EDGE CASE TESTS               //
//////////////////////////////////////////////////
contract MultiEdgeCaseTest is TestSetupMulti {
    OpenAction openAction;
    StatementOfIntent statementOfIntent;
    BespokeActionSimple bespokeActionSimple;
    PresetSingleAction presetSingleAction;
    PresetMultipleActions presetMultipleActions;
    BespokeActionAdvanced bespokeActionAdvanced;

    function setUp() public override {
        super.setUp();
        openAction = OpenAction(lawAddresses[3]);
        statementOfIntent = StatementOfIntent(lawAddresses[4]);
        bespokeActionSimple = BespokeActionSimple(lawAddresses[6]);
        presetSingleAction = PresetSingleAction(lawAddresses[1]);
        presetMultipleActions = PresetMultipleActions(lawAddresses[2]);
        bespokeActionAdvanced = BespokeActionAdvanced(lawAddresses[5]);
    }

    function testAllMultiLawsInitialization() public {
        // Test that all multi laws are properly initialized from constitution
        // OpenAction (lawId = 1)
        lawId = 1;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertTrue(address(openAction) != address(0));

        // StatementOfIntent (lawId = 2)
        lawId = 2;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertTrue(address(statementOfIntent) != address(0));

        // BespokeActionSimple (lawId = 3)
        lawId = 3;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertEq(bespokeActionSimple.targetContract(lawHash), mockAddresses[3]);

        // BespokeActionAdvanced (lawId = 4)
        lawId = 4;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertTrue(address(bespokeActionAdvanced) != address(0));

        // PresetSingleAction (lawId = 5)
        lawId = 5;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        PresetSingleAction.Data memory data = presetSingleAction.getData(lawHash);
        assertEq(data.targets.length, 2);

        // PresetMultipleActions (lawId = 6)
        lawId = 6;
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        PresetMultipleActions.Data memory multiData = presetMultipleActions.getData(lawHash);
        assertEq(multiData.descriptions.length, 2);
    }

    function testMultiLawsWithComplexProposals() public {
        // Test with complex multi-action proposals
        lawId = 1; // OpenAction law ID

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

        // Execute complex proposal
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test complex proposal");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testMultiLawsWithLargeArrays() public {
        // Test with large arrays
        lawId = 1; // OpenAction law ID

        // Setup large arrays
        targets = new address[](10);
        values = new uint256[](10);
        calldatas = new bytes[](10);

        for (uint256 i = 0; i < 10; i++) {
            targets[i] = address(daoMock);
            values[i] = 0;
            calldatas[i] = abi.encodeWithSelector(daoMock.labelRole.selector, uint256(i + 1), "Role");
        }

        // Execute with large arrays
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test large arrays");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testMultiLawsWithZeroAddressTargets() public {
        // Test with zero address targets
        lawId = 1; // OpenAction law ID

        targets = new address[](1);
        targets[0] = address(0); // zero address
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test");

        // Execute with zero address target
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test zero address target");

        // Should succeed (but will fail when executed)
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    // function testMultiLawsWithEtherValues() public {
    //     // Test with ether values
    //     lawId = 1; // OpenAction law ID

    //     targets = new address[](1);
    //     targets[0] = address(daoMock);
    //     values = new uint256[](1);
    //     values[0] = 1 ether; // Send ether
    //     calldatas = new bytes[](1);
    //     calldatas[0] = abi.encodeWithSelector(daoMock.receive.selector);

    //     // Execute with ether value
    //     vm.prank(alice);
    //     daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test ether value");

    //     // Should succeed
    //     actionId = uint256(keccak256(abi.encode(lawId, abi.encode(targets, values, calldatas), nonce)));
    //     assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    // }
}


//////////////////////////////////////////////////
//              ADOPT LAWS TESTS               //
//////////////////////////////////////////////////
contract AdoptLawsPackageTest is TestSetupExecutive {
    AdoptLawsPackage adoptLawsPackage;
    OpenAction openAction;
    PresetSingleAction presetSingleAction;

    function setUp() public override {
        super.setUp();
        adoptLawsPackage = AdoptLawsPackage(lawAddresses[8]); // AdoptLaws from executive constitution
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
//              EDGE CASE TESTS                //
//////////////////////////////////////////////////
contract ExecutiveEdgeCaseTest is TestSetupExecutive {
    AdoptLawsPackage adoptLawsPackage; 
    OpenAction openAction;
    PresetSingleAction presetSingleAction;
    SimpleGovernor simpleGovernor;

    function setUp() public override {
        super.setUp();
        adoptLawsPackage = AdoptLawsPackage(lawAddresses[8]); 
        openAction = OpenAction(lawAddresses[3]);
        presetSingleAction = PresetSingleAction(lawAddresses[1]);
        simpleGovernor = SimpleGovernor(payable(mockAddresses[4]));
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
