// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Powers } from "../../../src/Powers.sol";
import { TestSetupExecutive } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";
import { LawUtilities } from "../../../src/LawUtilities.sol";
import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";
import { Erc20VotesMock } from "../../mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../../mocks/Erc20TaxedMock.sol";
import { Grant } from "../../../src/laws/state/Grant.sol";
import { VoteOnNominees } from "../../../src/laws/state/VoteOnNominees.sol";
import { AddressesMapping } from "../../../src/laws/state/AddressesMapping.sol";
import { BespokeAction } from "../../../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../../../src/laws/executive/PresetAction.sol";
import { StartGrant } from "../../../src/laws/executive/StartGrant.sol";

contract OpenActionTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the OpenAction contract from the test setup
        uint16 openAction = 2;
        (address openActionAddress, , ) = daoMock.getActiveLaw(openAction);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(openActionAddress).getConditions(openAction).allowedRole, type(uint256).max, "Allowed role should be set to public access");
        assertEq(Law(openActionAddress).getExecutions(openAction).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testExecuteAction() public {
        // prep
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = mockAddresses[5];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        uint16 openAction = 2;
        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
        description = "Execute open action to mint coins";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        Powers(daoMock).request(openAction, lawCalldata, nonce, description);

        // assert
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 123);
    }

    function testExecuteMultipleActions() public {
        // prep
        address[] memory targetsIn = new address[](2);
        uint256[] memory valuesIn = new uint256[](2);
        bytes[] memory calldatasIn = new bytes[](2);
        
        targetsIn[0] = mockAddresses[5];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);
        
        targetsIn[1] = mockAddresses[5];
        valuesIn[1] = 0;
        calldatasIn[1] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 456);

        uint16 openAction = 2;
        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
        description = "Execute multiple open actions";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        Powers(daoMock).request(openAction, lawCalldata, nonce, description);

        // assert
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 579);
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 openAction = 2;
        (address openActionAddress, , ) = daoMock.getActiveLaw(openAction);
        
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = mockAddresses[5];
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);
        
        lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(openActionAddress).handleRequest(alice, address(daoMock), openAction, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], mockAddresses[5], "Target should be the ERC1155 mock");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(calldatas[0], abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123), "Calldata should match input");
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

contract BespokeActionTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the BespokeAction contract from the test setup
        uint16 bespokeAction = 3;
        (address bespokeActionAddress, , ) = daoMock.getActiveLaw(bespokeAction);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(bespokeActionAddress).getConditions(bespokeAction).allowedRole, ROLE_ONE, "Allowed role should be set to role 1");
        assertEq(Law(bespokeActionAddress).getExecutions(bespokeAction).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testExecuteBespokeAction() public {
        // prep
        uint16 bespokeAction = 3;
        lawCalldata = abi.encode(123); // quantity parameter for mintCoins
        description = "Execute bespoke action to mint coins";

        // act
        vm.prank(alice);
        Powers(daoMock).request(bespokeAction, lawCalldata, nonce, description);

        // assert
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 123, "Should have minted 123 coins");
    }

    function testExecuteMultipleBespokeActions() public {
        // prep
        uint16 bespokeAction = 3;
        
        // First mint
        lawCalldata = abi.encode(123);
        vm.prank(alice);
        Powers(daoMock).request(bespokeAction, lawCalldata, nonce, "First mint");
        nonce++;

        // Second mint
        lawCalldata = abi.encode(456);
        vm.prank(alice);
        Powers(daoMock).request(bespokeAction, lawCalldata, nonce, "Second mint");

        // assert
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 579, "Should have minted total of 579 coins");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 bespokeAction = 3;
        (address bespokeActionAddress, , ) = daoMock.getActiveLaw(bespokeAction);
        
        lawCalldata = abi.encode(123);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(bespokeActionAddress).handleRequest(alice, address(daoMock), bespokeAction, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], mockAddresses[5], "Target should be the ERC1155 mock");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(calldatas[0], abi.encodePacked(Erc1155Mock.mintCoins.selector, abi.encode(123)), "Calldata should match input");
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testVerifyTargetContractAndFunction() public {
        // prep
        uint16 bespokeAction = 3;
        (address bespokeActionAddress, , ) = daoMock.getActiveLaw(bespokeAction);
        lawHash = LawUtilities.hashLaw(address(daoMock), bespokeAction);

        // assert
        assertEq(
            BespokeAction(bespokeActionAddress).targetContract(lawHash),
            mockAddresses[5],
            "Target contract should be ERC1155 mock"
        );
        assertEq(
            BespokeAction(bespokeActionAddress).targetFunction(lawHash),
            Erc1155Mock.mintCoins.selector,
            "Target function should be mintCoins"
        );
    }
}

contract PresetActionTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the PresetAction contract from the test setup
        uint16 presetAction = 4;
        (address presetActionAddress, , ) = daoMock.getActiveLaw(presetAction);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(presetActionAddress).getConditions(presetAction).allowedRole, ROLE_ONE, "Allowed role should be set to role 1");
        assertEq(Law(presetActionAddress).getExecutions(presetAction).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testExecutePresetAction() public {
        // prep
        uint16 presetAction = 4;
        lawCalldata = abi.encode(true); // execute the preset action
        description = "Execute preset action to mint coins";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        Powers(daoMock).request(presetAction, lawCalldata, nonce, description);

        // assert
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 123, "Should have minted 123 coins");
    }

    function testExecuteMultiplePresetActions() public {
        // prep
        uint16 presetAction = 4;
        
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // First execution
        lawCalldata = abi.encode(true);
        vm.prank(alice);
        Powers(daoMock).request(presetAction, lawCalldata, nonce, "First execution");
        nonce++;

        // Second execution
        vm.prank(alice);
        Powers(daoMock).request(presetAction, lawCalldata, nonce, "Second execution");

        // assert
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 246, "Should have minted 246 coins total");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 presetAction = 4;
        (address presetActionAddress, , ) = daoMock.getActiveLaw(presetAction);
        
        lawCalldata = abi.encode(true);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(presetActionAddress).handleRequest(alice, address(daoMock), presetAction, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], mockAddresses[5], "Target should be the ERC1155 mock");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(calldatas[0], abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123), "Calldata should match preset action");
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testVerifyStoredPresetAction() public {
        // prep
        uint16 presetAction = 4;
        (address presetActionAddress, , ) = daoMock.getActiveLaw(presetAction);
        lawHash = LawUtilities.hashLaw(address(daoMock), presetAction);

        // assert
        address[] memory storedTargets = PresetAction(presetActionAddress).getData(lawHash).targets;
        uint256[] memory storedValues = PresetAction(presetActionAddress).getData(lawHash).values;
        bytes[] memory storedCalldatas = PresetAction(presetActionAddress).getData(lawHash).calldatas;

        assertEq(storedTargets.length, 1, "Should have one stored target");
        assertEq(storedValues.length, 1, "Should have one stored value");
        assertEq(storedCalldatas.length, 1, "Should have one stored calldata");
        
        assertEq(storedTargets[0], mockAddresses[5], "Stored target should be ERC1155 mock");
        assertEq(storedValues[0], 0, "Stored value should be 0");
        assertEq(storedCalldatas[0], abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123), "Stored calldata should match preset action");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 presetAction = 4;
        lawCalldata = abi.encode(true);

        // Try to execute without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        Powers(daoMock).request(presetAction, lawCalldata, nonce, "Unauthorized execution");
    }
}

contract ProposalOnlyTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the ProposalOnly contract from the test setup
        uint16 proposalOnly = 1;
        (address proposalOnlyAddress, , ) = daoMock.getActiveLaw(proposalOnly);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(proposalOnlyAddress).getConditions(proposalOnly).allowedRole, type(uint256).max, "Allowed role should be set to public access");
        assertEq(Law(proposalOnlyAddress).getExecutions(proposalOnly).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testCreateProposal() public {
        // prep
        uint16 proposalOnly = 1;
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        
        targets[0] = mockAddresses[5]; // erc1155Mock
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        lawCalldata = abi.encode(targets, values, calldatas);
        description = "Create proposal to mint coins";

        // act
        vm.prank(alice);
        Powers(daoMock).request(proposalOnly, lawCalldata, nonce, description);

        // assert
        // Note: ProposalOnly doesn't execute the action, it just creates a proposal
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 0, "Should not have minted any coins");
    }

    function testCreateMultipleProposals() public {
        // prep
        uint16 proposalOnly = 1;
        
        // First proposal
        address[] memory targets1 = new address[](1);
        uint256[] memory values1 = new uint256[](1);
        bytes[] memory calldatas1 = new bytes[](1);
        
        targets1[0] = mockAddresses[5];
        values1[0] = 0;
        calldatas1[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        lawCalldata = abi.encode(targets1, values1, calldatas1);
        vm.prank(alice);
        Powers(daoMock).request(proposalOnly, lawCalldata, nonce, "First proposal");
        nonce++;

        // Second proposal
        address[] memory targets2 = new address[](1);
        uint256[] memory values2 = new uint256[](1);
        bytes[] memory calldatas2 = new bytes[](1);
        
        targets2[0] = mockAddresses[5];
        values2[0] = 0;
        calldatas2[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 456);

        lawCalldata = abi.encode(targets2, values2, calldatas2);
        vm.prank(alice);
        Powers(daoMock).request(proposalOnly, lawCalldata, nonce, "Second proposal");

        // assert
        // Note: ProposalOnly doesn't execute the actions, it just creates proposals
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 0, "Should not have minted any coins");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 proposalOnly = 1;
        (address proposalOnlyAddress, , ) = daoMock.getActiveLaw(proposalOnly);
        
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        
        targets[0] = mockAddresses[5];
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        lawCalldata = abi.encode(targets, values, calldatas);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(proposalOnlyAddress).handleRequest(alice, address(daoMock), proposalOnly, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(0), "Target should be empty");
        assertEq(values[0], 0, "Value should be 0");
        assertEq(calldatas[0], "", "Calldata should be empty");
        assertEq(stateChange, "", "State change should be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }
}

contract StartGrantTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the StartGrant contract from the test setup
        uint16 startGrant = 6;
        (address startGrantAddress, , ) = daoMock.getActiveLaw(startGrant);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(startGrantAddress).getConditions(startGrant).allowedRole, ROLE_ONE, "Allowed role should be set to role 1");
        assertEq(Law(startGrantAddress).getExecutions(startGrant).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testStartGrant() public {
        // prep
        uint16 startGrant = 6;
        uint48 duration = 1000;
        uint256 budget = 1 * 10 ** 18;
        address tokenAddress = mockAddresses[3]; // erc20TaxedMock
        string memory grantDescription = "Test grant";
        uint256 expectedGrantId = Powers(payable(daoMock)).lawCount();
        
        lawCalldata = abi.encode(
            duration,
            budget,
            tokenAddress,
            grantDescription
        );
        description = "Starting a new grant";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        Powers(daoMock).request(startGrant, lawCalldata, nonce, description);

        // assert
        (address startGrantAddress, , ) = daoMock.getActiveLaw(startGrant);
        lawHash = LawUtilities.hashLaw(address(daoMock), startGrant);
        
        uint16 grantId = StartGrant(startGrantAddress).getGrantId(lawHash, lawCalldata);
        assertEq(grantId, expectedGrantId, "Grant ID should be correct"); // Based on ConstitutionsMock setup
    }

    function testStartMultipleGrants() public {
        // prep
        uint16 startGrant = 6;
        uint256 expectedGrantId = Powers(payable(daoMock)).lawCount();

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // First grant
        lawCalldata = abi.encode(
            uint48(1000),
            1 * 10 ** 18,
            mockAddresses[3],
            "First grant"
        );
        vm.prank(alice);
        Powers(daoMock).request(startGrant, lawCalldata, nonce, "First grant");
        nonce++;

        // Second grant
        lawCalldata = abi.encode(
            uint48(2000),
            2 * 10 ** 18,
            mockAddresses[3],
            "Second grant"
        );
        vm.prank(alice);
        Powers(daoMock).request(startGrant, lawCalldata, nonce, "Second grant");

        // assert
        (address startGrantAddress, , ) = daoMock.getActiveLaw(startGrant);
        lawHash = LawUtilities.hashLaw(address(daoMock), startGrant);
        
        // Get grant IDs for both grants
        bytes memory firstGrantCalldata = abi.encode(
            uint48(1000),
            1 * 10 ** 18,
            mockAddresses[3],
            "First grant"
        );
        bytes memory secondGrantCalldata = abi.encode(
            uint48(2000),
            2 * 10 ** 18,
            mockAddresses[3],
            "Second grant"
        );
        
        uint16 firstGrantId = StartGrant(startGrantAddress).getGrantId(lawHash, firstGrantCalldata);
        uint16 secondGrantId = StartGrant(startGrantAddress).getGrantId(lawHash, secondGrantCalldata);
        
        assertEq(firstGrantId, expectedGrantId, "First grant ID should be correct");
        assertEq(secondGrantId, expectedGrantId + 1, "Second grant ID should be correct");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 startGrant = 6;
        (address startGrantAddress, , ) = daoMock.getActiveLaw(startGrant);
        
        lawCalldata = abi.encode(
            uint48(1000),
            1 * 10 ** 18,
            mockAddresses[3],
            "Test grant"
        );

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(startGrantAddress).handleRequest(alice, address(daoMock), startGrant, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(calldatas[0], "", "Calldata should not be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testVerifyStoredGrantData() public {
        // prep
        uint16 startGrant = 6;
        (address startGrantAddress, , ) = daoMock.getActiveLaw(startGrant);
        lawHash = LawUtilities.hashLaw(address(daoMock), startGrant);

        // assert
        StartGrant.Data memory data = StartGrant(startGrantAddress).getData(lawHash);
        assertEq(data.grantLaw, lawAddresses[15], "Grant law should be set correctly"); 
        assertNotEq(data.grantConditions, "", "Grant conditions should not be empty");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 startGrant = 6;
        lawCalldata = abi.encode(
            uint48(1000),
            1 * 10 ** 18,
            mockAddresses[3],
            "Test grant"
        );

        // Try to start grant without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        Powers(daoMock).request(startGrant, lawCalldata, nonce, "Unauthorized grant start");
    }
}







