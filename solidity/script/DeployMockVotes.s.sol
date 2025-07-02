// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
// core protocol
// mocks
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";

// @dev this script is used to deploy the mocks to the chain.
// Note: we do not return addresses of the deployed mocks. -- I am thinking about scrapping it. It is more trouble than its worth
// addresses should be computed on basis of deployment data using create2.
contract DeployMockVotes is Script {
    function run() external returns (address mockVotes) {
        vm.startBroadcast();
        mockVotes = address(new Erc20VotesMock());
        vm.stopBroadcast();
    }
    
}
