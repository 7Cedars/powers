// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// scripts 
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

contract DeploySetup is Script {

    function daysToBlocks(uint256 quantityDays, uint256 blocksPerHour) public pure returns (uint32) {
        return uint32(quantityDays * 24 * blocksPerHour);
    }

    function hoursToBlocks(uint256 quantityHours, uint256 blocksPerHour) public pure returns (uint32) {
        return uint32(quantityHours * blocksPerHour);
    }

    function minutesToBlocks(uint256 quantityMinutes, uint256 blocksPerHour) public pure returns (uint32) {
        return uint32((quantityMinutes * blocksPerHour) / 60);
    }
}