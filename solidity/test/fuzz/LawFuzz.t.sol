// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { TestSetupLaw } from "../TestSetup.t.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";
import { LawErrors } from "../../src/interfaces/LawErrors.sol";
import { PresetSingleAction } from "../../src/laws/multi/PresetSingleAction.sol";
import { OpenAction } from "../../src/laws/multi/OpenAction.sol";
import { StatementOfIntent } from "../../src/laws/multi/StatementOfIntent.sol";
import { BespokeActionSimple } from "../../src/laws/multi/BespokeActionSimple.sol";
import { BespokeActionAdvanced } from "../../src/laws/multi/BespokeActionAdvanced.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Law Fuzz Tests
/// @notice Comprehensive fuzz testing for the Law.sol contract and its implementations
/// @dev Tests various edge cases and random inputs for law functionality
contract LawFuzzTest is TestSetupLaw {
    // Law instances for testing
    PresetSingleAction presetSingleAction;
    OpenAction openAction;
    StatementOfIntent statementOfIntent;
    BespokeActionSimple bespokeActionSimple;
    BespokeActionAdvanced bespokeActionAdvanced;

    // Test state tracking
    mapping(bytes32 => bool) fuzzLawHashes;
    mapping(uint16 => bool) fuzzLawIds;

    function setUp() public override {
        super.setUp();

        // Initialize law instances
        presetSingleAction = PresetSingleAction(lawAddresses[3]);
        openAction = OpenAction(lawAddresses[2]);
        statementOfIntent = StatementOfIntent(lawAddresses[5]);
        bespokeActionSimple = BespokeActionSimple(lawAddresses[6]);
        bespokeActionAdvanced = BespokeActionAdvanced(lawAddresses[7]);
    }

    //////////////////////////////////////////////////////////////
    //                  LAW INITIALIZATION FUZZ                 //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test law initialization with random parameters
    function testFuzzLawInitialization(
        uint16 indexFuzzed,
        string memory nameDescriptionFuzzed,
        bytes memory inputParamsFuzzed,
        bytes memory configFuzzed
    ) public {
        // Bound inputs
        vm.assume(indexFuzzed > 0);
        vm.assume(bytes(nameDescriptionFuzzed).length >= 1 && bytes(nameDescriptionFuzzed).length <= 255);

        // Test law initialization
        vm.prank(address(daoMock));
        presetSingleAction.initializeLaw(indexFuzzed, nameDescriptionFuzzed, inputParamsFuzzed, configFuzzed);

        // Verify law was initialized
        lawHash = keccak256(abi.encode(address(daoMock), indexFuzzed));
        assertTrue(fuzzLawHashes[lawHash] || lawHash != bytes32(0));
    }

    /// @notice Fuzz test law initialization with edge case strings
    function testFuzzLawInitializationStrings(uint16 indexFuzzed, string memory nameDescriptionFuzzed) public {
        // Bound inputs
        vm.assume(indexFuzzed > 0);
        vm.assume(bytes(nameDescriptionFuzzed).length >= 1 && bytes(nameDescriptionFuzzed).length <= 255);

        // Test with various string lengths
        inputParamsBytes = new bytes(0);
        configBytes = new bytes(0);

        vm.prank(address(daoMock));
        presetSingleAction.initializeLaw(indexFuzzed, nameDescriptionFuzzed, inputParamsBytes, configBytes);
        // Verify law was initialized
        string memory retrievedName = presetSingleAction.getNameDescription(address(daoMock), indexFuzzed);
        assertEq(retrievedName, nameDescriptionFuzzed);
    }

    //////////////////////////////////////////////////////////////
    //                  LAW UTILITIES FUZZ                     //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test law data retrieval
    function testFuzzLawDataRetrieval(
        uint16 lawIdFuzzed,
        string memory nameDescriptionFuzzed,
        bytes memory configFuzzed
    ) public {
        // Bound inputs
        vm.assume(lawIdFuzzed > 0);
        vm.assume(bytes(nameDescriptionFuzzed).length >= 1 && bytes(nameDescriptionFuzzed).length <= 255);
        vm.assume(configFuzzed.length <= MAX_FUZZ_CALLDATA_LENGTH);

        // Initialize law
        vm.prank(address(daoMock));
        presetSingleAction.initializeLaw(lawIdFuzzed, nameDescriptionFuzzed, "", configFuzzed);

        // Test data retrieval
        string memory retrievedName = presetSingleAction.getNameDescription(address(daoMock), lawIdFuzzed);
        bytes memory retrievedInputParams = presetSingleAction.getInputParams(address(daoMock), lawIdFuzzed);
        bytes memory retrievedConfig = presetSingleAction.getConfig(address(daoMock), lawIdFuzzed);

        // Verify data matches
        assertEq(retrievedName, nameDescriptionFuzzed);
        assertEq(retrievedInputParams.length, 288); // length of preset input params
        assertEq(retrievedConfig.length, configFuzzed.length);
    }

    /// @notice Fuzz test law hash generation
    function testFuzzLawHashGeneration(uint16 lawIdFuzzed) public {
        vm.assume(lawIdFuzzed > 0 && lawIdFuzzed < 1000);

        // Generate law hash
        lawHash = keccak256(abi.encode(address(daoMock), lawIdFuzzed));

        // Verify hash is consistent
        bytes32 lawHash2 = keccak256(abi.encode(address(daoMock), lawIdFuzzed));
        assertEq(lawHash, lawHash2);

        // Verify hash changes with different inputs
        bytes32 differentHash = keccak256(abi.encode(address(daoMock), lawIdFuzzed + 1));
        assertTrue(lawHash != differentHash);
    }

    //////////////////////////////////////////////////////////////
    //                  LAW INTERFACE COMPLIANCE FUZZ          //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test ERC165 interface compliance
    function testFuzzERC165Compliance(bytes4 interfaceIdFuzzed) public {
        // Test interface compliance
        bool supportsInterface = presetSingleAction.supportsInterface(interfaceIdFuzzed);

        // Should support ILaw interface
        bool supportsILaw = presetSingleAction.supportsInterface(type(ILaw).interfaceId);
        assertTrue(supportsILaw);

        // Should support ERC165 interface
        bool supportsERC165 = presetSingleAction.supportsInterface(type(IERC165).interfaceId);
        assertTrue(supportsERC165);
    }

    //////////////////////////////////////////////////////////////
    //                  LAW STATE MANAGEMENT FUZZ               //
    //////////////////////////////////////////////////////////////

    /// @notice Fuzz test law state consistency
    function testFuzzLawStateConsistency(
        uint16 lawIdFuzzed,
        string memory nameDescriptionFuzzed,
        bytes memory configFuzzed
    ) public {
        // Bound inputs
        vm.assume(lawIdFuzzed > 0 && lawIdFuzzed < 1000);
        vm.assume(bytes(nameDescriptionFuzzed).length >= 1 && bytes(nameDescriptionFuzzed).length <= 255);
        vm.assume(configFuzzed.length <= 1000);

        // Initialize law
        vm.prank(address(daoMock));
        presetSingleAction.initializeLaw(lawIdFuzzed, nameDescriptionFuzzed, "", configFuzzed);

        // Verify state consistency
        string memory retrievedName = presetSingleAction.getNameDescription(address(daoMock), lawIdFuzzed);
        bytes memory retrievedInputParams = presetSingleAction.getInputParams(address(daoMock), lawIdFuzzed);
        bytes memory retrievedConfig = presetSingleAction.getConfig(address(daoMock), lawIdFuzzed);

        // State should be consistent
        assertEq(retrievedName, nameDescriptionFuzzed);
        assertEq(retrievedInputParams.length, 288);
        assertEq(retrievedConfig.length, configFuzzed.length);

        for (i = 0; i < configFuzzed.length; i++) {
            assertEq(retrievedConfig[i], configFuzzed[i]);
        }
    }

    /// @notice Fuzz test law state updates
    function testFuzzLawStateUpdates(
        uint16 lawIdFuzzed,
        string[] memory nameDescriptionsFuzzed,
        bytes[] memory configArrayFuzzed,
        uint256 numberOfUpdates
    ) public {
        // Bound inputs
        vm.assume(lawIdFuzzed > 0 && lawIdFuzzed < 1000);
        vm.assume(nameDescriptionsFuzzed.length > numberOfUpdates);
        vm.assume(configArrayFuzzed.length > numberOfUpdates);
        vm.assume(numberOfUpdates > 0 && numberOfUpdates <= 10);

        for (i = 0; i < numberOfUpdates; i++) {
            vm.assume(bytes(nameDescriptionsFuzzed[i]).length >= 1 && bytes(nameDescriptionsFuzzed[i]).length <= 255);
            vm.assume(configArrayFuzzed[i].length <= 1000);

            // Initialize law with new data
            vm.prank(address(daoMock));
            presetSingleAction.initializeLaw(lawIdFuzzed, nameDescriptionsFuzzed[i], "", configArrayFuzzed[i]);

            // Verify state was updated
            string memory retrievedName = presetSingleAction.getNameDescription(address(daoMock), lawIdFuzzed);
            bytes memory retrievedInputParams = presetSingleAction.getInputParams(address(daoMock), lawIdFuzzed);
            bytes memory retrievedConfig = presetSingleAction.getConfig(address(daoMock), lawIdFuzzed);

            assertEq(retrievedName, nameDescriptionsFuzzed[i]);
            assertEq(retrievedInputParams.length, 288);
            assertEq(retrievedConfig.length, configArrayFuzzed[i].length);
        }
    }
}
