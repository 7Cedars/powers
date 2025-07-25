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
import { VoteOnAccounts } from "../../../src/laws/state/VoteOnAccounts.sol";
import { AddressesMapping } from "../../../src/laws/state/AddressesMapping.sol";
import { BespokeAction } from "../../../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../../../src/laws/executive/PresetAction.sol";
import { StartGrant } from "../../../src/laws/executive/StartGrant.sol";
import { EndGrant } from "../../../src/laws/executive/EndGrant.sol";
import { AdoptLaw } from "../../../src/laws/executive/AdoptLaw.sol";


contract OpenActionTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the OpenAction contract from the test setup
        uint16 openAction = 2;
        (address openActionAddress, , ) = daoMock.getActiveLaw(openAction);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(openActionAddress).getConditions(address(daoMock), openAction).allowedRole, type(uint256).max, "Allowed role should be set to public access");
        assertEq(Law(openActionAddress).getExecutions(address(daoMock), openAction).powers, address(daoMock), "Powers address should be set correctly");
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
        daoMock.request(openAction, lawCalldata, nonce, description);

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
        daoMock.request(openAction, lawCalldata, nonce, description);

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
        assertEq(Law(bespokeActionAddress).getConditions(address(daoMock),bespokeAction).allowedRole, ROLE_ONE, "Allowed role should be set to role 1");
        assertEq(Law(bespokeActionAddress).getExecutions(address(daoMock),bespokeAction).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testExecuteBespokeAction() public {
        // prep
        uint16 bespokeAction = 3;
        lawCalldata = abi.encode(123); // quantity parameter for mintCoins
        description = "Execute bespoke action to mint coins";

        // act
        vm.prank(alice);
        daoMock.request(bespokeAction, lawCalldata, nonce, description);

        // assert
        assertEq(Erc1155Mock(mockAddresses[5]).balanceOf(address(daoMock), 0), 123, "Should have minted 123 coins");
    }

    function testExecuteMultipleBespokeActions() public {
        // prep
        uint16 bespokeAction = 3;
        
        // First mint
        lawCalldata = abi.encode(123);
        vm.prank(alice);
        daoMock.request(bespokeAction, lawCalldata, nonce, "First mint");
        nonce++;

        // Second mint
        lawCalldata = abi.encode(456);
        vm.prank(alice);
        daoMock.request(bespokeAction, lawCalldata, nonce, "Second mint");

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
        assertEq(Law(presetActionAddress).getConditions(address(daoMock),presetAction).allowedRole, ROLE_ONE, "Allowed role should be set to role 1");
        assertEq(Law(presetActionAddress).getExecutions(address(daoMock),presetAction).powers, address(daoMock), "Powers address should be set correctly");
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
        daoMock.request(presetAction, lawCalldata, nonce, description);

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
        daoMock.request(presetAction, lawCalldata, nonce, "First execution");
        nonce++;

        // Second execution
        vm.prank(alice);
        daoMock.request(presetAction, lawCalldata, nonce, "Second execution");

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
        daoMock.request(presetAction, lawCalldata, nonce, "Unauthorized execution");
    }
}

contract StatementOfIntentTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the StatementOfIntent contract from the test setup
        uint16 proposalOnly = 1;
        (address proposalOnlyAddress, , ) = daoMock.getActiveLaw(proposalOnly);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(proposalOnlyAddress).getConditions(address(daoMock),proposalOnly).allowedRole, type(uint256).max, "Allowed role should be set to public access");
        assertEq(Law(proposalOnlyAddress).getExecutions(address(daoMock),proposalOnly).powers, address(daoMock), "Powers address should be set correctly");
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
        daoMock.request(proposalOnly, lawCalldata, nonce, description);

        // assert
        // Note: StatementOfIntent doesn't execute the action, it just creates a proposal
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
        daoMock.request(proposalOnly, lawCalldata, nonce, "First proposal");
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
        daoMock.request(proposalOnly, lawCalldata, nonce, "Second proposal");

        // assert
        // Note: StatementOfIntent doesn't execute the actions, it just creates proposals
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
        assertEq(Law(startGrantAddress).getConditions(address(daoMock),startGrant).allowedRole, ROLE_ONE, "Allowed role should be set to role 1");
        assertEq(Law(startGrantAddress).getExecutions(address(daoMock),startGrant).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testStartGrant() public {
        // prep
        uint16 startGrant = 6;
        uint48 duration = 25;
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
        daoMock.request(startGrant, lawCalldata, nonce, description);

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
            uint48(25),
            1 * 10 ** 18,
            mockAddresses[3],
            "First grant"
        );
        vm.prank(alice);
        daoMock.request(startGrant, lawCalldata, nonce, "First grant");
        nonce++;

        // Second grant
        lawCalldata = abi.encode(
            uint48(25),
            2 * 10 ** 18,
            mockAddresses[3],
            "Second grant"
        );
        vm.prank(alice);
        daoMock.request(startGrant, lawCalldata, nonce, "Second grant");

        // assert
        (address startGrantAddress, , ) = daoMock.getActiveLaw(startGrant);
        lawHash = LawUtilities.hashLaw(address(daoMock), startGrant);
        
        // Get grant IDs for both grants
        bytes memory firstGrantCalldata = abi.encode(
            uint48(25),
            1 * 10 ** 18,
            mockAddresses[3],
            "First grant"
        );
        bytes memory secondGrantCalldata = abi.encode(
            uint48(25),
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
            uint48(25),
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
        daoMock.request(startGrant, lawCalldata, nonce, "Unauthorized grant start");
    }
}

contract EndGrantTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the EndGrant contract from the test setup
        uint16 endGrant = 7;
        (address endGrantAddress, , ) = daoMock.getActiveLaw(endGrant);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(endGrantAddress).getConditions(address(daoMock),endGrant).allowedRole, ROLE_ONE, "Allowed role should be set to role 1");
        assertEq(Law(endGrantAddress).getExecutions(address(daoMock), endGrant).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testEndGrantWhenTokensSpent() public {
        // prep
        uint16 endGrant = 7;
        uint16 startGrant = 6;
        
        // First start a grant
        uint48 duration = 25;
        uint256 budget = 1 * 10 ** 18;
        address tokenAddress = mockAddresses[3]; // erc20TaxedMock
        string memory grantDescription = "Test grant";

        lawCalldata = abi.encode(
            duration,
            budget,
            tokenAddress,
            grantDescription
        );

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        vm.prank(alice);
        daoMock.request(startGrant, lawCalldata, nonce, "Starting grant");
        // NB: we do NOT increase the nonce. We need to keep on using the same nonce! 

        // spending tokens 
        uint16 grantId = daoMock.lawCount() - 1; 
        (address grantAddress, , ) = daoMock.getActiveLaw(grantId);
        bytes memory lawCalldataSpending = abi.encode(
            alice, 
            grantAddress, 
            budget
        );
        vm.prank(alice);
        daoMock.request(grantId, lawCalldataSpending, nonce, "Spending tokens");

        vm.roll(block.number + duration + 1);

        vm.prank(alice);
        daoMock.request(endGrant, lawCalldata, nonce, "Stopping grant");

        // assert
        (address endGrantAddress, , ) = daoMock.getActiveLaw(endGrant);
        lawHash = LawUtilities.hashLaw(address(daoMock), endGrant);
        EndGrant.Data memory data = EndGrant(endGrantAddress).getData(lawHash);
        assertEq(data.maxBudgetLeft, 1000, "Max budget left should be set correctly");
        assertTrue(data.checkDuration, "Check duration should be true");
    }

    function testCannotEndGrantWithTokensLeft() public {
        // prep
        uint16 endGrant = 7;
        uint16 startGrant = 6;
        
        // First start a grant
        uint48 duration = 25;
        uint256 budget = 1 * 10 ** 18;
        address tokenAddress = mockAddresses[3]; // erc20TaxedMock
        string memory grantDescription = "Test grant";

        lawCalldata = abi.encode(
            duration,
            budget,
            tokenAddress,
            grantDescription
        );

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        vm.prank(alice);
        daoMock.request(startGrant, lawCalldata, nonce, "Starting grant");

        vm.prank(alice);
        vm.expectRevert("Grant has not spent all tokens.");
        daoMock.request(endGrant, lawCalldata, nonce, "Stopping grant with tokens left");
    }

    function testCannotEndGrantBeforeDuration() public {
        // prep
        uint16 endGrant = 7;
        uint16 startGrant = 6;
        
        // First start a grant
        uint48 duration = 25;
        uint256 budget = 0; // Set budget to 0 to pass token check
        address tokenAddress = mockAddresses[3]; // erc20TaxedMock
        string memory grantDescription = "Test grant";

        lawCalldata = abi.encode(
            duration,
            budget,
            tokenAddress,
            grantDescription
        );

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        vm.prank(alice);
        daoMock.request(startGrant, lawCalldata, nonce, "Starting grant");

        // Now try to stop the grant before duration expires
        lawCalldata = abi.encode(
            duration,
            budget,
            tokenAddress,
            grantDescription
        );

        vm.prank(alice);
        vm.expectRevert("Grant has not expired.");
        daoMock.request(endGrant, lawCalldata, nonce, "Stopping grant before duration");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 endGrant = 7;
        uint16 startGrant = 6;
        (address endGrantAddress, , ) = daoMock.getActiveLaw(endGrant);
        
        // First start a grant
        uint48 duration = 25;
        uint256 budget = 1 * 10 ** 18;
        address tokenAddress = mockAddresses[3]; // erc20TaxedMock
        string memory grantDescription = "Test grant";

        lawCalldata = abi.encode(
            duration,
            budget,
            tokenAddress,
            grantDescription
        );

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        vm.prank(alice);
        daoMock.request(startGrant, lawCalldata, nonce, "Starting grant");

        // spending tokens 
        uint16 grantId = daoMock.lawCount() - 1; 
        (address grantAddress, , ) = daoMock.getActiveLaw(grantId);
        bytes memory lawCalldataSpending = abi.encode(
            alice, 
            grantAddress, 
            budget
        );
        vm.prank(alice);
        daoMock.request(grantId, lawCalldataSpending, nonce, "Spending tokens");

        // advance time
        vm.roll(block.number + duration + 1);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(endGrantAddress).handleRequest(alice, address(daoMock), endGrant, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the DAO");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(calldatas[0], "", "Calldata should not be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 endGrant = 7;
        lawCalldata = abi.encode(
            uint48(1000),
            0,
            mockAddresses[3],
            "Test grant"
        );

        // Try to stop grant without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(endGrant, lawCalldata, nonce, "Unauthorized grant stop");
    }
}

contract AdoptLawTest is TestSetupExecutive {
    using ShortStrings for *;

    function testConstructorInitialization() public {
        // Get the AdoptLaw contract from the test setup
        uint16 adoptLaw = 8;
        (address adoptLawAddress, , ) = daoMock.getActiveLaw(adoptLaw);
        
        vm.startPrank(address(daoMock));
        assertEq(Law(adoptLawAddress).getConditions(address(daoMock),adoptLaw).allowedRole, ROLE_ONE, "Allowed role should be set to role 1");
        assertEq(Law(adoptLawAddress).getExecutions(address(daoMock),adoptLaw).powers, address(daoMock), "Powers address should be set correctly");
        vm.stopPrank();
    }

    function testAdoptNewLaw() public {
        // prep
        uint16 adoptLaw = 8;
        uint16 newLawId = daoMock.lawCount();
        
        // Create a new law configuration
        AdoptLaw.AdoptLawConfig memory configAdoptLaw = AdoptLaw.AdoptLawConfig({
            nameDescription: "new law: new law description",
            law: lawAddresses[6], // open Action 
            allowedRole: ROLE_ONE,
            votingPeriod: 1200,
            quorum: 30,
            succeedAt: 51, 
            needCompleted: 0,
            needNotCompleted: 0,
            readStateFrom: 0,
            delayExecution: 0,
            throttleExecution: 0,
            config: abi.encode()
        });

        lawCalldata = abi.encode(configAdoptLaw);
        description = "Adopting a new open action law";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        daoMock.request(adoptLaw, lawCalldata, nonce, description);

        // assert
        (address newLawAddress, , ) = daoMock.getActiveLaw(newLawId);
        assertEq(newLawAddress, lawAddresses[6], "New law should be adopted with correct address");
    }

    function testAdoptLawWithConditions() public {
        // prep
        uint16 adoptLaw = 8;
        uint16 newLawId = daoMock.lawCount();
        
        // Create a new law configuration with specific conditions
        AdoptLaw.AdoptLawConfig memory configAdoptLaw = AdoptLaw.AdoptLawConfig({
            nameDescription: "new law: new law description",
            law: lawAddresses[6], // open Action 
            allowedRole: ROLE_TWO,
            votingPeriod: 2400,
            quorum: 40,
            succeedAt: 60, 
            needCompleted: 0,
            needNotCompleted: 0,
            readStateFrom: 0,
            delayExecution: 1000,
            throttleExecution: 2000,
            config: abi.encode()
        });

        lawCalldata = abi.encode(configAdoptLaw);
        description = "Adopting a new open action law with conditions";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        daoMock.request(adoptLaw, lawCalldata, nonce, description);

        // assert
        (address newLawAddress, , ) = daoMock.getActiveLaw(newLawId);
        conditions = Law(newLawAddress).getConditions(address(daoMock),newLawId);
        
        assertEq(conditions.allowedRole, ROLE_TWO, "Allowed role should be set correctly");
        assertEq(conditions.votingPeriod, 2400, "Voting period should be set correctly");
        assertEq(conditions.quorum, 40, "Quorum should be set correctly");
        assertEq(conditions.succeedAt, 60, "Succeed at should be set correctly");
        assertEq(conditions.needCompleted, 0, "Need completed should be set correctly");
        assertEq(conditions.needNotCompleted, 0, "Need not completed should be set correctly");
        assertEq(conditions.readStateFrom, 0, "Read state from should be set correctly");
        assertEq(conditions.delayExecution, 1000, "Delay execution should be set correctly");
        assertEq(conditions.throttleExecution, 2000, "Throttle execution should be set correctly");
    }

    function testHandleRequestOutput() public {
        // prep
        uint16 adoptLaw = 8;
        uint16 newLawId = daoMock.lawCount();
        (address adoptLawAddress, , ) = daoMock.getActiveLaw(adoptLaw);
        
        // Create a new law configuration
        AdoptLaw.AdoptLawConfig memory configAdoptLaw = AdoptLaw.AdoptLawConfig({
            nameDescription: "new law: new law description",
            law: lawAddresses[6], // open Action 
            allowedRole: ROLE_ONE,
            votingPeriod: 1200,
            quorum: 30,
            succeedAt: 51, 
            needCompleted: 0,
            needNotCompleted: 0,
            readStateFrom: 0,
            delayExecution: 0,
            throttleExecution: 0,
            config: abi.encode()
        });

        lawCalldata = abi.encode(configAdoptLaw);

        // act: call handleRequest directly to check its output
        vm.prank(address(daoMock));
        (
            actionId,
            targets,
            values,
            calldatas,
            stateChange
        ) = Law(adoptLawAddress).handleRequest(alice, address(daoMock), adoptLaw, lawCalldata, nonce);

        // assert
        assertEq(targets.length, 1, "Should have one target");
        assertEq(values.length, 1, "Should have one value");
        assertEq(calldatas.length, 1, "Should have one calldata");
        assertEq(targets[0], address(daoMock), "Target should be the powers protocol");
        assertEq(values[0], 0, "Value should be 0");
        assertNotEq(calldatas[0], "", "Calldata should not be empty");
        assertNotEq(actionId, 0, "Action ID should not be 0");
    }

    function testUnauthorizedAccess() public {
        // prep
        uint16 adoptLaw = 8;
        
        // Create a new law configuration
        AdoptLaw.AdoptLawConfig memory configAdoptLaw = AdoptLaw.AdoptLawConfig({
            nameDescription: "new law: new law description",
            law: lawAddresses[6], // open Action 
            allowedRole: ROLE_ONE,
            votingPeriod: 1200,
            quorum: 30,
            succeedAt: 51, 
            needCompleted: 0,
            needNotCompleted: 0,
            readStateFrom: 0,
            delayExecution: 0,
            throttleExecution: 0,
            config: abi.encode()
        });

        lawCalldata = abi.encode(configAdoptLaw);

        // Try to adopt law without proper role
        vm.prank(helen);
        vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
        daoMock.request(adoptLaw, lawCalldata, nonce, "Unauthorized law adoption");
    }
}








