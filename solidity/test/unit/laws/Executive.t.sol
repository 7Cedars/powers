// SPDX-License-Identifier: UNLICENSED
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
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = address(erc1155Mock);
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        address openAction = laws[1];
        bytes memory lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(openAction).executeLaw(address(0), lawCalldata, bytes32(0));

        assertEq(targetsOut[0], targetsIn[0]);
        assertEq(valuesOut[0], valuesIn[0]);
        assertEq(calldatasOut[0], calldatasIn[0]);
    }
}

contract ProposalOnlyTest is TestSetupExecutive {
    using ShortStrings for *;

    function testReturnDataProposalOnly() public {
        address proposalOnly = laws[3];
        bytes memory lawCalldata = abi.encode(Erc1155Mock.mintCoins.selector, 123);

        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut,
            ) = Law(proposalOnly).executeLaw(address(0), lawCalldata, keccak256("this is a proposal"));

        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
    }
}

contract BespokeActionTest is TestSetupExecutive {
    function testReturnDataBespokeAction() public {
        // this bespoke action mints coins in the mock1155 contract.
        address bespokeAction = laws[2];
        bytes memory lawCalldata = abi.encode(123); // the amount of coins to mint.
        bytes memory expectedCalldata = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(bespokeAction).executeLaw(address(0), lawCalldata, keccak256("this is a proposal"));

        assertEq(targetsOut[0], address(erc1155Mock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }
}

contract SelfDestructPresetActionTest is TestSetupExecutive {
    function testSuccessfulSelfDestruct() public {
        address selfDestructPresetAction = laws[5];
        bytes memory lawCalldata = abi.encode();

        vm.prank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(
            selfDestructPresetAction
        ).executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice executes law")
        );

        // assert output: last item in output array should be self destruct
        assertEq(targetsOut[targetsOut.length - 1], address(daoMock));
        assertEq(valuesOut[valuesOut.length - 1], 0);
        assertEq(
            calldatasOut[calldatasOut.length - 1],
            abi.encodeWithSelector(Powers.revokeLaw.selector, selfDestructPresetAction)
        );
    }
}

