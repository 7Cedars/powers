// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
// import { console2 } from "forge-std/console2.sol";
// core protocol
import { Powers } from "../src/Powers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { LawUtilities } from "../src/LawUtilities.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

import { TestConstitutions } from "../test/TestConstitutions.sol";
import { DeployMocks } from "./DeployMocks.s.sol";
import { DeployLaws } from "./DeployLaws.s.sol";

// @dev this script is used to deploy the mocks to the chain.
// Note: we do not return addresses of the deployed mocks. -- I am thinking about scrapping it. It is more trouble than its worth
// addresses should be computed on basis of deployment data using create2.
contract DeployTestOrgs is Script {
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.
    DeployMocks deployMocks;
    DeployLaws deployLaws;
    TestConstitutions testConstitutions;

    function run() external returns (address[] memory powersAddresses, string[] memory mockNames, address[] memory mockAddresses, string[] memory lawNames, address[] memory lawAddresses) {// returns  addresses of the deployed powers contracts
        deployMocks = new DeployMocks();
        deployLaws = new DeployLaws();
        testConstitutions = new TestConstitutions();

        (mockNames, mockAddresses) = deployMocks.run();
        (lawNames, lawAddresses) = deployLaws.run();
        Powers powers;
        powersAddresses = new address[](1);
        
        // Powers 101
        powers = new Powers("Test Org", "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibd3qgeohyjeamqtfgk66lr427gpp4ify5q4civ2khcgkwyvz5hcq", 10_000, 25);
        (PowersTypes.LawInitData[] memory lawInitData) = testConstitutions.powers101Constitution(
            lawNames, lawAddresses, mockNames, mockAddresses, payable(address(powers))
        );
        powers.constitute(lawInitData);
        powersAddresses[0] = address(powers);

        // here we can add more test powers implementations.

        return (powersAddresses, mockNames, mockAddresses, lawNames, lawAddresses);
    }
}
