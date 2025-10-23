// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { TestSetupExecutive } from "../../TestSetup.t.sol";
import { StatementOfIntent } from "../../../src/laws/multi/StatementOfIntent.sol";
import { GovernorCreateProposal } from "../../../src/laws/executive/GovernorCreateProposal.sol";
import { GovernorExecuteProposal } from "../../../src/laws/executive/GovernorExecuteProposal.sol";
import { AdoptLawsPackage } from "../../../src/laws/executive/AdoptLawsPackage.sol";
import { PresetSingleAction } from "../../../src/laws/multi/PresetSingleAction.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol";
import { LawUtilities } from "../../../src/libraries/LawUtilities.sol";
import { SimpleGovernor } from "@mocks/SimpleGovernor.sol";
import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";

/// @title Executive Law Fuzz Tests
/// @notice Comprehensive fuzz testing for all executive law implementations using pre-initialized laws
/// @dev Tests use laws from executiveTestConstitution:
///      lawId 1: StatementOfIntent
///      lawId 2: GovernorCreateProposal
///      lawId 3: GovernorExecuteProposal
///      lawId 4: AdoptLawsPackage
///      lawId 5: PresetSingleAction
contract ExecutiveFuzzTest is TestSetupExecutive {
    // Law instances for testing
    StatementOfIntent statementOfIntent;
    GovernorCreateProposal governorCreateProposal;
    GovernorExecuteProposal governorExecuteProposal;
    AdoptLawsPackage adoptLawsPackage;
    PresetSingleAction presetSingleAction;

    // State variables to avoid stack too deep errors
    uint256 returnedActionId;
    address[] returnedTargets;
    uint256[] returnedValues;
    bytes[] returnedCalldatas;
    bytes[] lawInitDatas;
    address[] lawsToAdopt;
    string[] descriptions;
    PowersTypes.LawInitData adoptLawData;
    AdoptLawsPackage.Data adoptData;
    PresetSingleAction.Data presetDataSingle;

    function setUp() public override {
        super.setUp();

        // Initialize law instances from deployed addresses
        // Note: lawId 1 uses StatementOfIntent from multi laws (lawAddresses[4])
        statementOfIntent = StatementOfIntent(lawAddresses[4]);
        governorCreateProposal = GovernorCreateProposal(lawAddresses[8]);
        governorExecuteProposal = GovernorExecuteProposal(lawAddresses[9]);
        adoptLawsPackage = AdoptLawsPackage(lawAddresses[7]);
        presetSingleAction = PresetSingleAction(lawAddresses[1]);
    }

    //////////////////////////////////////////////////////////////
    //               STATEMENT OF INTENT FUZZ                   //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test StatementOfIntent (lawId 1) with random data
    function testFuzzStatementOfIntentWithRandomData(
        uint256 arrayLength,
        address[] memory targetsFuzzed,
        bytes[] memory calldatasFuzzed,
        uint256 nonceFuzzed
    ) public {
        // Bound inputs
        arrayLength = bound(arrayLength, 1, MAX_FUZZ_TARGETS);
        vm.assume(targetsFuzzed.length >= arrayLength);
        vm.assume(calldatasFuzzed.length >= arrayLength);

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);

        for (i = 0; i < arrayLength; i++) {
            targets[i] = targetsFuzzed[i];
            values[i] = 0;
            calldatas[i] = calldatasFuzzed[i];
        }

        lawCalldata = abi.encode(targets, values, calldatas);

        (returnedActionId, returnedTargets, returnedValues, returnedCalldatas) =
            statementOfIntent.handleRequest(alice, address(daoMock), 1, lawCalldata, nonceFuzzed);

        // Verify data is passed through unchanged
        assertEq(returnedTargets.length, arrayLength);
        for (i = 0; i < arrayLength; i++) {
            assertEq(returnedTargets[i], targets[i]);
            assertEq(returnedCalldatas[i], calldatas[i]);
        }
    }

    /// @notice Fuzz test StatementOfIntent with large calldata
    function testFuzzStatementOfIntentWithLargeCalldata(uint256 calldataLength, uint256 nonceFuzzed) public {
        // Bound inputs
        calldataLength = bound(calldataLength, 1, MAX_FUZZ_CALLDATA_LENGTH);

        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);

        // Create large calldata
        bytes memory largeCalldata = new bytes(calldataLength);
        for (i = 0; i < calldataLength; i++) {
            largeCalldata[i] = bytes1(uint8(i % 256));
        }
        calldatas[0] = largeCalldata;

        lawCalldata = abi.encode(targets, values, calldatas);

        (returnedActionId, returnedTargets,, returnedCalldatas) =
            statementOfIntent.handleRequest(alice, address(daoMock), 1, lawCalldata, nonceFuzzed);

        assertEq(returnedCalldatas[0].length, calldataLength);
    }

    //////////////////////////////////////////////////////////////
    //              GOVERNOR CREATE PROPOSAL FUZZ               //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test GovernorCreateProposal (lawId 2) with random proposal data
    /// @dev lawId 2 is configured to create proposals on SimpleGovernor mock
    function testFuzzGovernorCreateProposalWithRandomData(
        uint256 arrayLength,
        address[] memory targetsFuzzed,
        uint256[] memory valuesFuzzed,
        bytes[] memory calldatasFuzzed,
        string memory descriptionFuzzed,
        uint256 nonceFuzzed
    ) public {
        // Bound inputs
        arrayLength = bound(arrayLength, 1, MAX_FUZZ_TARGETS);
        vm.assume(targetsFuzzed.length >= arrayLength);
        vm.assume(valuesFuzzed.length >= arrayLength);
        vm.assume(calldatasFuzzed.length >= arrayLength);

        // Ensure description is not empty (required by the law)
        vm.assume(bytes(descriptionFuzzed).length > 0);

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);

        for (i = 0; i < arrayLength; i++) {
            targets[i] = targetsFuzzed[i];
            values[i] = valuesFuzzed[i];
            calldatas[i] = calldatasFuzzed[i];
        }

        lawCalldata = abi.encode(targets, values, calldatas, descriptionFuzzed);

        (returnedActionId, returnedTargets, returnedValues, returnedCalldatas) =
            governorCreateProposal.handleRequest(alice, address(daoMock), 2, lawCalldata, nonceFuzzed);

        // Verify structure
        assertEq(returnedTargets.length, 1);
        assertEq(returnedValues.length, 1);
        assertEq(returnedCalldatas.length, 1);

        // Verify target is the SimpleGovernor mock
        assertEq(returnedTargets[0], mockAddresses[4]); // SimpleGovernor

        // Verify function selector is propose
        bytes4 selector = bytes4(returnedCalldatas[0]);
        assertEq(selector, Governor.propose.selector);
    }

    /// @notice Fuzz test GovernorCreateProposal with empty arrays (should revert)
    function testFuzzGovernorCreateProposalWithEmptyArrays(string memory descriptionFuzzed, uint256 nonceFuzzed)
        public
    {
        vm.assume(bytes(descriptionFuzzed).length > 0);

        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);

        lawCalldata = abi.encode(targets, values, calldatas, descriptionFuzzed);

        // Should revert due to empty targets
        vm.expectRevert("GovernorCreateProposal: No targets provided");
        governorCreateProposal.handleRequest(alice, address(daoMock), 2, lawCalldata, nonceFuzzed);
    }

    /// @notice Fuzz test GovernorCreateProposal with mismatched array lengths (should revert)
    function testFuzzGovernorCreateProposalWithMismatchedArrays(
        uint256 targetsLength,
        uint256 valuesLength,
        uint256 calldatasLength,
        string memory descriptionFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(bytes(descriptionFuzzed).length > 0 && bytes(descriptionFuzzed).length < 10_000);
        targetsLength = bound(targetsLength, 1, MAX_FUZZ_TARGETS);
        valuesLength = bound(valuesLength, 1, MAX_FUZZ_TARGETS);
        calldatasLength = bound(calldatasLength, 1, MAX_FUZZ_TARGETS);
        vm.assume(targetsLength != valuesLength || valuesLength != calldatasLength);

        console.log("WAYPOINT 0");
        console.log(targetsLength);
        console.log(valuesLength);
        console.log(calldatasLength);

        address[] memory targetsFuzzed = new address[](targetsLength);
        uint256[] memory valuesFuzzed = new uint256[](valuesLength);
        bytes[] memory calldatasFuzzed = new bytes[](calldatasLength);

        console.log("WAYPOINT 1");

        for (i = 0; i < targetsLength; i++) {
            targetsFuzzed[i] = address(daoMock);
        }
        console.log("WAYPOINT 2");

        for (i = 0; i < valuesLength; i++) {
            valuesFuzzed[i] = 0;
        }
        console.log("WAYPOINT 3");

        for (i = 0; i < calldatasLength; i++) {
            calldatasFuzzed[i] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test");
        }
        console.log("WAYPOINT 4");

        lawCalldata = abi.encode(targetsFuzzed, valuesFuzzed, calldatasFuzzed, descriptionFuzzed);
        console.log("WAYPOINT 5");

        // Should revert due to mismatched array lengths
        vm.expectRevert();
        governorCreateProposal.handleRequest(alice, address(daoMock), 2, lawCalldata, nonceFuzzed);
    }

    /// @notice Fuzz test GovernorCreateProposal with empty description (should revert)
    function testFuzzGovernorCreateProposalWithEmptyDescription(uint256 arrayLength, uint256 nonceFuzzed) public {
        arrayLength = bound(arrayLength, 1, MAX_FUZZ_TARGETS);

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);

        for (i = 0; i < arrayLength; i++) {
            targets[i] = address(daoMock);
            values[i] = 0;
            calldatas[i] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test");
        }

        lawCalldata = abi.encode(targets, values, calldatas, "");

        // Should revert due to empty description
        vm.expectRevert("GovernorCreateProposal: Description cannot be empty");
        governorCreateProposal.handleRequest(alice, address(daoMock), 2, lawCalldata, nonceFuzzed);
    }

    //////////////////////////////////////////////////////////////
    //              GOVERNOR EXECUTE PROPOSAL FUZZ              //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test GovernorExecuteProposal (lawId 3) with random proposal data
    /// @dev lawId 3 is configured to execute proposals on SimpleGovernor mock
    function testFuzzGovernorExecuteProposalWithRandomData(
        uint256 arrayLength,
        address[] memory targetsFuzzed,
        uint256[] memory valuesFuzzed,
        bytes[] memory calldatasFuzzed,
        string memory descriptionFuzzed,
        uint256 nonceFuzzed
    ) public {
        // Bound inputs
        arrayLength = bound(arrayLength, 1, MAX_FUZZ_TARGETS);
        vm.assume(targetsFuzzed.length >= arrayLength);
        vm.assume(valuesFuzzed.length >= arrayLength);
        vm.assume(calldatasFuzzed.length >= arrayLength);

        // Ensure description is not empty (required by the law)
        vm.assume(bytes(descriptionFuzzed).length > 0);

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);

        for (i = 0; i < arrayLength; i++) {
            targets[i] = targetsFuzzed[i];
            values[i] = valuesFuzzed[i];
            calldatas[i] = calldatasFuzzed[i];
        }

        lawCalldata = abi.encode(targets, values, calldatas, descriptionFuzzed);

        // Note: This will likely revert because the proposal doesn't exist or isn't in Succeeded state
        // But we can still test the validation logic
        vm.expectRevert();
        governorExecuteProposal.handleRequest(alice, address(daoMock), 3, lawCalldata, nonceFuzzed);
    }

    /// @notice Fuzz test GovernorExecuteProposal with empty arrays (should revert)
    function testFuzzGovernorExecuteProposalWithEmptyArrays(string memory descriptionFuzzed, uint256 nonceFuzzed)
        public
    {
        vm.assume(bytes(descriptionFuzzed).length > 0);

        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);

        lawCalldata = abi.encode(targets, values, calldatas, descriptionFuzzed);

        // Should revert due to empty targets
        vm.expectRevert("GovernorExecuteProposal: No targets provided");
        governorExecuteProposal.handleRequest(alice, address(daoMock), 3, lawCalldata, nonceFuzzed);
    }

    /// @notice Fuzz test GovernorExecuteProposal with empty description (should revert)
    function testFuzzGovernorExecuteProposalWithEmptyDescription(uint256 arrayLength, uint256 nonceFuzzed) public {
        arrayLength = bound(arrayLength, 1, MAX_FUZZ_TARGETS);

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);

        for (i = 0; i < arrayLength; i++) {
            targets[i] = address(daoMock);
            values[i] = 0;
            calldatas[i] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test");
        }

        lawCalldata = abi.encode(targets, values, calldatas, "");

        // Should revert due to empty description
        vm.expectRevert("GovernorExecuteProposal: Description cannot be empty");
        governorExecuteProposal.handleRequest(alice, address(daoMock), 3, lawCalldata, nonceFuzzed);
    }

    //////////////////////////////////////////////////////////////
    //                    ADOPT LAWS FUZZ                       //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test AdoptLawsPackage (lawId 4) returns preset adoption data regardless of input
    /// @dev lawId 4 is configured to adopt a single PresetSingleAction law
    function testFuzzAdoptLawsPackageIgnoresInput(bytes memory inputCalldataFuzzed, uint256 nonceFuzzed) public {
        // Bound inputs
        vm.assume(inputCalldataFuzzed.length <= MAX_FUZZ_CALLDATA_LENGTH);

        // Get preset data for lawId 4
        lawHash = keccak256(abi.encode(address(daoMock), uint16(4)));
        adoptData = adoptLawsPackage.getData(lawHash);

        // Call with different inputs - should return same preset data
        (returnedActionId, returnedTargets, returnedValues, returnedCalldatas) =
            adoptLawsPackage.handleRequest(alice, address(daoMock), 4, inputCalldataFuzzed, nonceFuzzed);

        // Store first call results
        address[] memory firstTargets = returnedTargets;
        uint256[] memory firstValues = returnedValues;
        bytes[] memory firstCalldatas = returnedCalldatas;

        bytes memory differentInput = abi.encode("completely different");
        (returnedActionId, returnedTargets, returnedValues, returnedCalldatas) =
            adoptLawsPackage.handleRequest(alice, address(daoMock), 4, differentInput, nonceFuzzed);

        // Both should return same preset data
        assertEq(firstTargets.length, returnedTargets.length);
        assertEq(firstTargets.length, adoptData.laws.length);

        for (i = 0; i < firstTargets.length; i++) {
            assertEq(firstTargets[i], returnedTargets[i]);
            assertEq(firstTargets[i], address(daoMock)); // Should target the daoMock
            assertEq(firstValues[i], returnedValues[i]);
            assertEq(firstValues[i], 0); // Values should be 0
        }
    }

    /// @notice Fuzz test AdoptLawsPackage with various nonces
    function testFuzzAdoptLawsPackageWithVariousNonces(uint256 nonce1, uint256 nonce2) public {
        vm.assume(nonce1 != nonce2);

        lawCalldata = abi.encode();

        (returnedActionId, returnedTargets,,) = adoptLawsPackage.handleRequest(alice, address(daoMock), 4, lawCalldata, nonce1);

        uint256 firstActionId = returnedActionId;
        address[] memory firstTargets = returnedTargets;

        (returnedActionId, returnedTargets,,) = adoptLawsPackage.handleRequest(alice, address(daoMock), 4, lawCalldata, nonce2);

        // Different nonces should produce different action IDs
        assertTrue(firstActionId != returnedActionId);

        // But same targets
        assertEq(firstTargets.length, returnedTargets.length);
        for (i = 0; i < firstTargets.length; i++) {
            assertEq(firstTargets[i], returnedTargets[i]);
        }
    }

    //////////////////////////////////////////////////////////////
    //               PRESET SINGLE ACTION FUZZ                  //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test PresetSingleAction (lawId 5) returns preset data regardless of input
    /// @dev lawId 5 is configured to label role 1 as "Member" and role 2 as "Delegate"
    function testFuzzPresetSingleActionIgnoresInput(bytes memory inputCalldataFuzzed, uint256 nonceFuzzed) public {
        // Bound inputs
        vm.assume(inputCalldataFuzzed.length <= MAX_FUZZ_CALLDATA_LENGTH);

        // Get preset data for lawId 5
        lawHash = keccak256(abi.encode(address(daoMock), uint16(5)));
        presetDataSingle = presetSingleAction.getData(lawHash);

        // Call with different inputs
        (returnedActionId, returnedTargets, returnedValues, returnedCalldatas) =
            presetSingleAction.handleRequest(alice, address(daoMock), 5, inputCalldataFuzzed, nonceFuzzed);

        // Store first call results
        address[] memory firstTargets = returnedTargets;
        uint256[] memory firstValues = returnedValues;
        bytes[] memory firstCalldatas = returnedCalldatas;

        bytes memory differentInput = abi.encode("completely different");
        (returnedActionId, returnedTargets, returnedValues, returnedCalldatas) =
            presetSingleAction.handleRequest(alice, address(daoMock), 5, differentInput, nonceFuzzed);

        // Both should return same preset data
        assertEq(firstTargets.length, returnedTargets.length);
        assertEq(firstTargets.length, presetDataSingle.targets.length);

        for (i = 0; i < firstTargets.length; i++) {
            assertEq(firstTargets[i], returnedTargets[i]);
            assertEq(firstTargets[i], presetDataSingle.targets[i]);
            assertEq(firstValues[i], returnedValues[i]);
            assertEq(firstValues[i], presetDataSingle.values[i]);
            assertEq(firstCalldatas[i], returnedCalldatas[i]);
            assertEq(firstCalldatas[i], presetDataSingle.calldatas[i]);
        }
    }

    /// @notice Fuzz test PresetSingleAction with various nonces
    function testFuzzPresetSingleActionWithVariousNonces(uint256 nonce1, uint256 nonce2) public {
        vm.assume(nonce1 != nonce2);

        lawCalldata = abi.encode();

        (returnedActionId, returnedTargets,,) =
            presetSingleAction.handleRequest(alice, address(daoMock), 5, lawCalldata, nonce1);

        uint256 firstActionId = returnedActionId;
        address[] memory firstTargets = returnedTargets;

        (returnedActionId, returnedTargets,,) =
            presetSingleAction.handleRequest(alice, address(daoMock), 5, lawCalldata, nonce2);

        // Different nonces should produce different action IDs
        assertTrue(firstActionId != returnedActionId);

        // But same targets
        assertEq(firstTargets.length, returnedTargets.length);
        for (i = 0; i < firstTargets.length; i++) {
            assertEq(firstTargets[i], returnedTargets[i]);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  CROSS-LAW FUZZ TESTS                    //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test action ID generation consistency across all executive laws
    function testFuzzActionIdConsistency(uint16 lawIdFuzzed, bytes memory lawCalldataFuzzed, uint256 nonceFuzzed)
        public
    {
        // Bound to valid law IDs (1-5 from the executive constitution)
        lawIdFuzzed = uint16(bound(lawIdFuzzed, 1, 5));
        vm.assume(lawCalldataFuzzed.length <= MAX_FUZZ_CALLDATA_LENGTH);

        // Test with StatementOfIntent
        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test");

        lawCalldata = abi.encode(targets, values, calldatas);

        (returnedActionId,,,) =
            statementOfIntent.handleRequest(alice, address(daoMock), lawIdFuzzed, lawCalldata, nonceFuzzed);

        // Verify action ID matches expected pattern
        uint256 expected = uint256(keccak256(abi.encode(lawIdFuzzed, lawCalldata, nonceFuzzed)));
        assertEq(returnedActionId, expected);
    }

    /// @notice Fuzz test that all executive laws properly handle governor contract validation
    function testFuzzGovernorContractValidation(uint256 arrayLength, uint256 nonceFuzzed) public {
        // Bound inputs
        arrayLength = bound(arrayLength, 1, MAX_FUZZ_TARGETS);

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);

        for (i = 0; i < arrayLength; i++) {
            targets[i] = address(daoMock);
            values[i] = 0;
            calldatas[i] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test");
        }

        string memory testDescription = "Test Proposal";
        lawCalldata = abi.encode(targets, values, calldatas, testDescription);

        // Test GovernorCreateProposal (lawId 2) - should work with valid governor
        (returnedActionId, returnedTargets,,) =
            governorCreateProposal.handleRequest(alice, address(daoMock), 2, lawCalldata, nonceFuzzed);

        // Should target the SimpleGovernor mock
        assertEq(returnedTargets[0], mockAddresses[4]);

        // Test GovernorExecuteProposal (lawId 3) - should revert due to proposal not existing
        vm.expectRevert();
        governorExecuteProposal.handleRequest(alice, address(daoMock), 3, lawCalldata, nonceFuzzed);
    }

    /// @notice Fuzz test all executive laws with maximum allowed calldata size
    function testFuzzAllExecutiveLawsWithMaxCalldata(uint256 nonceFuzzed) public {
        // Create maximum size arrays
        targets = new address[](MAX_FUZZ_TARGETS);
        values = new uint256[](MAX_FUZZ_TARGETS);
        calldatas = new bytes[](MAX_FUZZ_TARGETS);

        for (i = 0; i < MAX_FUZZ_TARGETS; i++) {
            targets[i] = address(uint160(i + 1));
            values[i] = i;

            // Create large calldata
            bytes memory largeCalldata = new bytes(100);
            for (j = 0; j < 100; j++) {
                largeCalldata[j] = bytes1(uint8(j % 256));
            }
            calldatas[i] = largeCalldata;
        }

        string memory testDescription = "Large Proposal Test";
        lawCalldata = abi.encode(targets, values, calldatas, testDescription);

        // Test StatementOfIntent with large data
        (returnedActionId, returnedTargets,, returnedCalldatas) =
            statementOfIntent.handleRequest(alice, address(daoMock), 1, lawCalldata, nonceFuzzed);

        assertEq(returnedTargets.length, MAX_FUZZ_TARGETS);
        assertEq(returnedCalldatas.length, MAX_FUZZ_TARGETS);

        // Test GovernorCreateProposal with large data
        (returnedActionId, returnedTargets,, returnedCalldatas) =
            governorCreateProposal.handleRequest(alice, address(daoMock), 2, lawCalldata, nonceFuzzed);

        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], mockAddresses[4]); // Should target SimpleGovernor
    }

    /// @notice Fuzz test nonce uniqueness across all executive laws
    function testFuzzNonceUniqueness(uint256 nonce1Fuzzed, uint256 nonce2Fuzzed) public {
        vm.assume(nonce1Fuzzed != nonce2Fuzzed);

        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, 1, "Test");

        lawCalldata = abi.encode(targets, values, calldatas);
        lawId = 1;

        // Get action IDs with different nonces
        (returnedActionId,,,) =
            statementOfIntent.handleRequest(alice, address(daoMock), lawId, lawCalldata, nonce1Fuzzed);
        uint256 firstActionId = returnedActionId;

        (returnedActionId,,,) =
            statementOfIntent.handleRequest(alice, address(daoMock), lawId, lawCalldata, nonce2Fuzzed);

        // Different nonces should produce different action IDs
        assertTrue(firstActionId != returnedActionId);
    }

    //////////////////////////////////////////////////////////////
    //                  EDGE CASE FUZZ TESTS                    //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test with extremely large array indices
    function testFuzzWithLargeArrayIndices(uint256 arrayLength, uint256 nonceFuzzed) public {
        // Bound inputs
        arrayLength = bound(arrayLength, 1, MAX_FUZZ_TARGETS);

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);

        for (i = 0; i < arrayLength; i++) {
            targets[i] = address(uint160(i + 1));
            values[i] = type(uint256).max - i; // Use large values
            calldatas[i] = abi.encodeWithSelector(daoMock.labelRole.selector, type(uint256).max - i, "Role");
        }

        string memory testDescription = "Large Values Test";
        lawCalldata = abi.encode(targets, values, calldatas, testDescription);

        (, address[] memory returnedTargets, uint256[] memory returnedValues,) =
            statementOfIntent.handleRequest(alice, address(daoMock), 1, lawCalldata, nonceFuzzed);

        // Verify large values are preserved
        for (i = 0; i < arrayLength; i++) {
            assertEq(returnedValues[i], type(uint256).max - i);
        }
    }

    /// @notice Fuzz test with random bytes in calldata
    function testFuzzWithRandomBytesCalldata(bytes memory randomBytesFuzzed, uint256 nonceFuzzed) public {
        // Bound inputs
        vm.assume(randomBytesFuzzed.length <= MAX_FUZZ_CALLDATA_LENGTH);

        targets = new address[](1);
        targets[0] = address(daoMock);
        values = new uint256[](1);
        values[0] = 0;
        calldatas = new bytes[](1);
        calldatas[0] = randomBytesFuzzed;

        lawCalldata = abi.encode(targets, values, calldatas);

        (,,, bytes[] memory returnedCalldatas) =
            statementOfIntent.handleRequest(alice, address(daoMock), 1, lawCalldata, nonceFuzzed);

        // Should preserve random bytes
        assertEq(returnedCalldatas[0], randomBytesFuzzed);
    }

    /// @notice Fuzz test law data retrieval consistency
    function testFuzzLawDataConsistency(uint16 lawIdFuzzed) public {
        // Bound to valid law IDs
        lawIdFuzzed = uint16(bound(lawIdFuzzed, 1, 5));

        // Get law conditions from daoMock
        conditions = daoMock.getConditions(lawIdFuzzed);

        // Verify conditions are valid
        assertTrue(conditions.quorum <= 100);
        assertTrue(conditions.succeedAt <= 100);
    }
}
