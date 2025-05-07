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



