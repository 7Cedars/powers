// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { Law } from "../../src/Law.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { LawErrors } from "../../src/interfaces/LawErrors.sol";
import { PowersEvents } from "../../src/interfaces/PowersEvents.sol";
import { TestSetupLaw } from "../TestSetup.t.sol";
import { OpenAction } from "../../src/laws/multi/OpenAction.sol";
import { PresetSingleAction } from "../../src/laws/multi/PresetSingleAction.sol";

/// @notice Comprehensive unit tests for Law.sol contract
/// @dev Tests all functionality of the Law base contract including initialization, execution, and helper functions

//////////////////////////////////////////////////
//              BASIC LAW TESTS                //
//////////////////////////////////////////////////
contract LawBasicTest is TestSetupLaw {
    Law testLaw;

    
    function setUp() public override {
        super.setUp();

        vm.prank(address(daoMock));
        testLaw = new OpenAction();
    }

    function testInitializeLawSetsCorrectState() public {
        // prep: create test data
        lawId = daoMock.lawCount();
        nameDescription = "Test Law";
        bytes memory localConfig = abi.encode();

        // act: initialize the law
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));

        // assert: verify law data is set correctly
        assertEq(testLaw.getNameDescription(address(daoMock), lawId), nameDescription);
        assertEq(keccak256(testLaw.getConfig(address(daoMock), lawId)), keccak256(localConfig));
    }

    function testInitializeLawEmitsEvent() public {
        // prep: create test data
        lawId = daoMock.lawCount();
        nameDescription = "Test Law";
        bytes memory localConfig = abi.encode("test config");

        // assert: verify event is emitted
        vm.expectEmit(true, true, false, true);
        emit PowersEvents.LawAdopted(lawId);
        
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));
    }

    function testInitializeLawRevertsWithEmptyName() public {
        // prep: create test data with empty name
        lawId = daoMock.lawCount();
        nameDescription = "";
        bytes memory localConfig = abi.encode("test config");

        // act & assert: verify initialization reverts
        vm.expectRevert("String too short");
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));
    }

    function testInitializeLawRevertsWithTooLongName() public {
        // prep: create test data with too long name
        lawId = daoMock.lawCount();
        nameDescription = string(abi.encodePacked(new bytes(256))); // 256 character string
        bytes memory localConfig = abi.encode();

        // act & assert: verify initialization reverts
        vm.expectRevert("String too long");
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));
    }

    function testExecuteLawRevertsIfNotCalledFromPowers() public {
        // prep: initialize the law
        lawId = daoMock.lawCount();
        nameDescription = "Test Law";
        bytes memory localConfig = abi.encode("test config");
        
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));

        // act & assert: verify execution reverts when not called from Powers
        vm.expectRevert(LawErrors.Law__OnlyPowers.selector);
        vm.prank(alice);
        testLaw.executeLaw(alice, lawId, abi.encode(true), nonce);
    }

    function testExecuteLawSucceedsWhenCalledFromPowers() public {
        // prep: initialize the law
        lawId = daoMock.lawCount();
        nameDescription = "Test Law";
        bytes memory localConfig = abi.encode("test config");
        conditions.allowedRole = 1;
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        targets = new address[](1);
        targets[0] = address(daoMock);

        values = new uint256[](1);
        values[0] = 0;

        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(daoMock.labelRole.selector, ROLE_ONE, "Member");
        
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));

        // act: execute law from Powers contract
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(targets, values, calldatas), nonce, "Test Law");

        actionId = LawUtilities.hashActionId(lawId, abi.encode(targets, values, calldatas), nonce);

        // assert: verify execution succeeds
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//              HELPER FUNCTION TESTS          //
//////////////////////////////////////////////////
contract LawHelperTest is TestSetupLaw {
    Law testLaw;
    
    function setUp() public override {
        super.setUp();
        testLaw = new OpenAction();
    }

    function testGetNameDescription() public {
        // prep: initialize law
        lawId = 1;
        nameDescription = "Test Law Name";
        inputParams = abi.encode("test input");
        bytes memory localConfig = abi.encode();
        
        vm.prank(address(daoMock));
        testLaw.initializeLaw(lawId, nameDescription, inputParams, localConfig);

        // act: get name description
        string memory retrievedName = testLaw.getNameDescription(address(daoMock), lawId);

        // assert: verify name is correct
        assertEq(retrievedName, nameDescription);
        delete inputParams; // clean up
    }

    function testGetConfig() public {
        // prep: initialize law
        lawId = 1;
        nameDescription = "Test Law";
        inputParams = abi.encode("test input");
        bytes memory localConfig = abi.encode("test config", 456, false);
        
        vm.prank(address(daoMock));
        testLaw.initializeLaw(lawId, nameDescription, inputParams, localConfig);

        // act: get config
        bytes memory retrievedConfig = testLaw.getConfig(address(daoMock), lawId);

        // assert: verify config is correct
        assertEq(keccak256(retrievedConfig), keccak256(localConfig));
        delete inputParams; // clean up
    }

    function testGetNameDescriptionRevertsForNonExistentLaw() public view {
        // act & assert: verify getting name for non-existent law returns empty string
        string memory retrievedName = testLaw.getNameDescription(address(daoMock), 999);
        assertEq(retrievedName, "");
    }

    function testGetInputParamsRevertsForNonExistentLaw() public view {
        // act & assert: verify getting params for non-existent law returns empty bytes
        bytes memory retrievedParams = testLaw.getInputParams(address(daoMock), 999);
        assertEq(retrievedParams.length, 0);
    }

    function testGetConfigRevertsForNonExistentLaw() public view {
        // act & assert: verify getting config for non-existent law returns empty bytes
        bytes memory retrievedConfig = testLaw.getConfig(address(daoMock), 999);
        assertEq(retrievedConfig.length, 0);
    }
}

//////////////////////////////////////////////////
//              INTERFACE SUPPORT TESTS        //
//////////////////////////////////////////////////
contract LawInterfaceTest is TestSetupLaw {
    Law testLaw;
    
    function setUp() public override {
        super.setUp();
        testLaw = new OpenAction();
    }

    function testSupportsILawInterface() public view {
        // act: check if contract supports ILaw interface
        bool supportsILaw = testLaw.supportsInterface(type(ILaw).interfaceId);

        // assert: verify interface is supported
        assertTrue(supportsILaw);
    }

    function testSupportsERC165Interface() public view {
        // act: check if contract supports ERC165 interface
        bool supportsERC165 = testLaw.supportsInterface(type(IERC165).interfaceId);

        // assert: verify interface is supported
        assertTrue(supportsERC165);
    }

    function testDoesNotSupportRandomInterface() public view {
        // act: check if contract supports random interface
        bool supportsRandom = testLaw.supportsInterface(0x12345678);

        // assert: verify interface is not supported
        assertFalse(supportsRandom);
    }
}

//////////////////////////////////////////////////
//              LAW UTILITIES TESTS            //
//////////////////////////////////////////////////
contract LawUtilitiesTest is TestSetupLaw {
    function testHashActionIdReturnsConsistentHash() public {
        // prep: create test data
        lawId = 1;
        lawCalldata = abi.encode(true, "test", 123);
        nonce = 123;

        // act: hash the action ID
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // assert: verify hash is consistent
        assertEq(actionId, uint256(keccak256(abi.encode(lawId, lawCalldata, nonce))));
    }

    function testHashLawReturnsConsistentHash() public {
        // prep: create test data
        lawId = 1;
        address powersAddress = address(daoMock);

        // act: hash the law
        lawHash = LawUtilities.hashLaw(powersAddress, lawId);

        // assert: verify hash is consistent
        assertEq(lawHash, keccak256(abi.encode(powersAddress, lawId)));
    }

    function testCreateEmptyArraysReturnsCorrectArrays() public {
        // prep: create test data
        uint256 length = 5;

        // act: create empty arrays
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);

        // assert: verify arrays are created with correct length
        assertEq(targets.length, length);
        assertEq(values.length, length);
        assertEq(calldatas.length, length);
        
        // assert: verify all elements are zero/empty
        for (i = 0; i < length; i++) {
            assertEq(targets[i], address(0));
            assertEq(values[i], 0);
            assertEq(calldatas[i].length, 0);
        }
    }

    function testCheckStringLengthWithValidString() public pure {
        // act & assert: verify valid string length passes
        LawUtilities.checkStringLength("Valid String", 1, 100);
    }

    function testCheckStringLengthRevertsWithTooShort() public {
        // act & assert: verify too short string reverts
        vm.expectRevert("String too short");
        LawUtilities.checkStringLength("", 1, 100);
    }

    function testCheckStringLengthRevertsWithTooLong() public {
        // prep: create a string longer than max length
        string memory longString = string(abi.encodePacked(new bytes(300)));
        
        // act & assert: verify too long string reverts
        vm.expectRevert("String too long");
        LawUtilities.checkStringLength(longString, 1, 100);
    }
}

//////////////////////////////////////////////////
//              EDGE CASE TESTS                //
//////////////////////////////////////////////////
contract LawEdgeCaseTest is TestSetupLaw {
    Law testLaw;
    
    function setUp() public override {
        super.setUp();
        testLaw = new OpenAction();
    }

    function testInitializeLawWithMaximumLengthName() public {
        // prep: create test data with maximum length name (255 characters)
        lawId = daoMock.lawCount();
        nameDescription = string(abi.encodePacked(new bytes(255)));
        bytes memory localConfig = abi.encode("test config");

        // act: initialize the law
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));

        // assert: verify law is initialized successfully
        assertEq(testLaw.getNameDescription(address(daoMock), lawId), nameDescription);
    }

    function testInitializeLawWithMinimumLengthName() public {
        // prep: create test data with minimum length name (1 character)
        lawId = daoMock.lawCount();
        nameDescription = "A";
        bytes memory localConfig = abi.encode("test config");

        // act: initialize the law
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));

        // assert: verify law is initialized successfully
        assertEq(testLaw.getNameDescription(address(daoMock), lawId), nameDescription);
    }

    function testInitializeLawWithEmptyInputParams() public {
        // prep: create test data with empty input params
        lawId = daoMock.lawCount();
        nameDescription = "Test Law";
        inputParams = abi.encode();
        bytes memory localConfig = abi.encode("test config");

        // act: initialize the law
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));

        // assert: verify law is initialized successfully
        assertEq(testLaw.getInputParams(address(daoMock), lawId).length, 288);
    }

    function testInitializeLawWithEmptyConfig() public {
        // prep: create test data with empty config
        lawId = daoMock.lawCount();
        nameDescription = "Test Law";
        bytes memory localConfig = abi.encode();

        // act: initialize the law
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));

        // assert: verify law is initialized successfully
        assertEq(testLaw.getConfig(address(daoMock), lawId).length, 0);
    }

    function testInitializeLawWithComplexData() public {
        // prep: create test data with complex nested structures
        lawId = daoMock.lawCount();
        nameDescription = "Complex Test Law";
        
        // Complex config with arrays
        address[] memory configAddresses = new address[](3);
        configAddresses[0] = address(0x1);
        configAddresses[1] = address(0x2);
        configAddresses[2] = address(0x3);
        
        bytes memory localConfig = abi.encode(configAddresses, 789, false);

        // act: initialize the law
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: nameDescription,
            targetLaw: address(testLaw),
            config: localConfig,
            conditions: conditions
        }));

        // assert: verify law is initialized successfully
        assertEq(testLaw.getNameDescription(address(daoMock), lawId), nameDescription);
        assertEq(keccak256(testLaw.getConfig(address(daoMock), lawId)), keccak256(localConfig));
    }

    function testMultipleLawsWithSamePowers() public {
        // prep: initialize multiple laws with same Powers contract
        lawId = daoMock.lawCount();
        vm.startPrank(address(daoMock));
        
        // Create multiple law instances for testing
        Law testLaw1 = new OpenAction();
        Law testLaw2 = new OpenAction();
        Law testLaw3 = new OpenAction();
        
        // Adopt laws using the proper pattern
        daoMock.adoptLaw(LawInitData({
            nameDescription: "Law 1",
            targetLaw: address(testLaw1),
            config: abi.encode("config1"),
            conditions: conditions
        }));
        
        daoMock.adoptLaw(LawInitData({
            nameDescription: "Law 2",
            targetLaw: address(testLaw2),
            config: abi.encode("config2"),
            conditions: conditions
        }));
        
        daoMock.adoptLaw(LawInitData({
            nameDescription: "Law 3",
            targetLaw: address(testLaw3),
            config: abi.encode("config3"),
            conditions: conditions
        }));
        vm.stopPrank();

        // assert: verify all laws are stored correctly
        assertEq(testLaw1.getNameDescription(address(daoMock), lawId), "Law 1");
        assertEq(testLaw2.getNameDescription(address(daoMock), lawId + 1), "Law 2");
        assertEq(testLaw3.getNameDescription(address(daoMock), lawId + 2), "Law 3");
    }

    function testLawWithDifferentPowersContracts() public {
        // prep: create multiple law instances to test separation
        lawId = daoMock.lawCount();
        Law testLaw1 = new OpenAction();
        Law testLaw2 = new OpenAction();
        
        // prep: initialize laws with same Powers contract but different law instances
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: "Law for DAO",
            targetLaw: address(testLaw1),
            config: abi.encode("dao config"),
            conditions: conditions
        }));
        
        vm.prank(address(daoMock));
        daoMock.adoptLaw(LawInitData({
            nameDescription: "Law for Another DAO",
            targetLaw: address(testLaw2),
            config: abi.encode("another config"),
            conditions: conditions
        }));

        // assert: verify laws are stored separately with different law IDs
        assertEq(testLaw1.getNameDescription(address(daoMock), lawId), "Law for DAO");
        assertEq(testLaw2.getNameDescription(address(daoMock), lawId + 1), "Law for Another DAO");
    }
}

//////////////////////////////////////////////////
//              MOCK CONTRACTS                 //
//////////////////////////////////////////////////

/// @notice Mock law contract that returns empty targets for testing
contract EmptyTargetsLaw is Law {
    function handleRequest(address, address, uint16, bytes memory, uint256)
        public
        pure
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        // Return empty arrays
        actionId = 1;
        targets = new address[](0);
        values = new uint256[](0);
        calldatas = new bytes[](0);
    }
}

/// @notice Mock law contract that returns specific targets for testing
contract MockTargetsLaw is Law {
    function handleRequest(address, address, uint16, bytes memory, uint256)
        public
        pure
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        // Return specific test data
        actionId = 1;
        targets = new address[](2);
        targets[0] = address(0x1);
        targets[1] = address(0x2);
        
        values = new uint256[](2);
        values[0] = 1 ether;
        values[1] = 2 ether;
        
        calldatas = new bytes[](2);
        calldatas[0] = abi.encodeWithSignature("test1()");
        calldatas[1] = abi.encodeWithSignature("test2()");
    }
}