// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Powers } from "../../../src/Powers.sol";
import { TestSetupExecutive } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";

contract OpenActionTest is TestSetupExecutive {
    using ShortStrings for *;

    function testExecuteAction() public {
        // prep
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = address(erc1155Mock);
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        address openAction = laws[1];
        bytes memory lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
        string memory description = "Execute open action to mint coins";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        Powers(daoMock).request(openAction, lawCalldata, description);

        // assert
        assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 123);
    }
}

contract ProposalOnlyTest is TestSetupExecutive {
    using ShortStrings for *;

    function testExecuteProposalOnly() public {
        // prep
        address proposalOnly = laws[3];
        bytes memory lawCalldata = abi.encode(Erc1155Mock.mintCoins.selector, 123);
        bytes32 descriptionHash = keccak256("Proposal only action");

        // act
        vm.prank(address(daoMock));
        bool success = Law(proposalOnly).executeLaw(address(0), lawCalldata, descriptionHash);

        // assert
        assertTrue(success);
        // Verify no state changes as this is proposal only
        assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 0);
    }
 
}

contract BespokeActionTest is TestSetupExecutive {
    function testExecuteBespokeAction() public {
        // prep
        address bespokeAction = laws[2];
        bytes memory lawCalldata = abi.encode(123); // amount of coins to mint
        string memory description = "Bespoke action to mint coins";

        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // act
        vm.prank(alice);
        Powers(daoMock).request(bespokeAction, lawCalldata, description);
 
        assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 123);
    }
}

contract SelfDestructActionTest is TestSetupExecutive {
    function testSuccessfulSelfDestruct() public {
        // prep
        address selfDestructPresetAction = laws[5];
        bytes memory lawCalldata = abi.encode();
        string memory description = "Self destruct action";

        // Store initial state
        bool initialLawStatus = Powers(daoMock).getActiveLaw(selfDestructPresetAction);
        assertTrue(initialLawStatus, "Law should be active initially");

        vm.prank(address(daoMock));
        daoMock.assignRole(0, alice);

        // act
        vm.prank(alice);
        Powers(daoMock).request(selfDestructPresetAction, lawCalldata, description);

        // assert
        assertFalse(Powers(daoMock).getActiveLaw(selfDestructPresetAction), "Law should be inactive after self-destruct");
    }
}

