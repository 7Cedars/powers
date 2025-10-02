// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Law } from "../../src/Law.sol";

/// @notice Mock law contract that returns empty targets for testing
contract EmptyTargetsLaw is Law {
    function handleRequest(address, address, uint16, bytes memory, uint256)
        public
        pure
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
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
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
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
