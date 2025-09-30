// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { TestSetupMulti } from "../TestSetup.t.sol";
import { OpenAction } from "../../src/laws/multi/OpenAction.sol";
import { StatementOfIntent } from "../../src/laws/multi/StatementOfIntent.sol";
import { BespokeActionSimple } from "../../src/laws/multi/BespokeActionSimple.sol";
import { PresetSingleAction } from "../../src/laws/multi/PresetSingleAction.sol";
import { PresetMultipleActions } from "../../src/laws/multi/PresetMultipleActions.sol";
import { BespokeActionAdvanced } from "../../src/laws/multi/BespokeActionAdvanced.sol";
import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";

/// @notice Comprehensive unit tests for all multi laws
/// @dev Tests all functionality of multi laws including initialization, execution, and edge cases

//////////////////////////////////////////////////
//              OPEN ACTION TESTS              //
//////////////////////////////////////////////////
contract OpenActionTest is TestSetupMulti {
    OpenAction openAction;

    function setUp() public override {
        super.setUp();
        openAction = OpenAction(lawAddresses[2]); // OpenAction from multi constitution
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
        statementOfIntent = StatementOfIntent(lawAddresses[3]); // StatementOfIntent from multi constitution
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
        ) = statementOfIntent.handleRequest(alice, address(daoMock), lawId, abi.encode(targets, values, calldatas), nonce);

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
//         BESPOKE ACTION SIMPLE TESTS        //
//////////////////////////////////////////////////
contract BespokeActionSimpleTest is TestSetupMulti {
    BespokeActionSimple bespokeActionSimple;
    SimpleErc1155 erc1155Mock;

    function setUp() public override {
        super.setUp();
        bespokeActionSimple = BespokeActionSimple(lawAddresses[5]); // BespokeActionSimple from multi constitution
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
        uint256 quantity = 1000000;
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
        presetSingleAction = PresetSingleAction(lawAddresses[0]); // PresetSingleAction from multi constitution
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
        presetMultipleActions = PresetMultipleActions(lawAddresses[1]); // PresetMultipleActions from multi constitution
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
        selections[0] = true;  // Select first action
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
        selections[1] = true;  // Select second action

        vm.prank(alice);
        daoMock.request(lawId, abi.encode(selections), nonce, "Test second action");
        
        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(selections), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPresetMultipleActionsWithBothActions() public {
        // Execute both actions
        bool[] memory selections = new bool[](2);
        selections[0] = true;  // Select first action
        selections[1] = true;  // Select second action

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
        selections[0] = true;  // Select first action
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
        bespokeActionAdvanced = BespokeActionAdvanced(lawAddresses[4]); // BespokeActionAdvanced from multi constitution
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
        openAction = OpenAction(lawAddresses[2]);
        statementOfIntent = StatementOfIntent(lawAddresses[3]);
        bespokeActionSimple = BespokeActionSimple(lawAddresses[5]);
        presetSingleAction = PresetSingleAction(lawAddresses[0]);
        presetMultipleActions = PresetMultipleActions(lawAddresses[1]);
        bespokeActionAdvanced = BespokeActionAdvanced(lawAddresses[4]);
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
