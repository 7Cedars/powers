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

// mocks
import { PowersMock } from "../test/mocks/PowersMock.sol";
import { GovernorMock } from "../test/mocks/GovernorMock.sol";
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../test/mocks/Erc20TaxedMock.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

// @dev this script is used to deploy the mocks to the chain.
// Note: we do not return addresses of the deployed mocks. -- I am thinking about scrapping it. It is more trouble than its worth
// addresses should be computed on basis of deployment data using create2.
contract DeployMocks is Script {
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.    
    function run() external returns (string[] memory names, address[] memory addresses) {
        names = new string[](6);
        addresses = new address[](6);
        bytes[] memory creationCodes = new bytes[](6);

        names[0] = "PowersMock";
        creationCodes[0] = type(PowersMock).creationCode;
        addresses[0] = deployMock(creationCodes[0], names[0]);
    
        names[2] = "Erc20VotesMock";
        creationCodes[2] = type(Erc20VotesMock).creationCode;
        addresses[2] = deployMock(creationCodes[2], names[2]);
        
        names[3] = "Erc20TaxedMock";
        creationCodes[3] = type(Erc20TaxedMock).creationCode;
        addresses[3] = deployMock(creationCodes[3], names[3]);

        names[4] = "Erc721Mock";
        creationCodes[4] = type(Erc721Mock).creationCode;
        addresses[4] = deployMock(creationCodes[4], names[4]);

        names[5] = "Erc1155Mock";
        creationCodes[5] = type(Erc1155Mock).creationCode;
        addresses[5] = deployMock(creationCodes[5], names[5]);

        names[1] = "GovernorMock";
        creationCodes[1] = abi.encodePacked(type(GovernorMock).creationCode, abi.encode(addresses[2]));
        addresses[1] = deployMock(creationCodes[1], names[1]);
    }

    //////////////////////////////////////////////////////////////
    //                   LAW DEPLOYMENT                         //
    //////////////////////////////////////////////////////////////
    function deployMock(bytes memory creationCode, string memory name) public returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(name));

        address computedAddress = Create2.computeAddress(
            salt,
            keccak256(abi.encodePacked(creationCode)),
            create2Factory // create2 factory address. NEED TO INCLUDE THIS!
        );

        if (computedAddress.code.length == 0) {
            vm.startBroadcast();
            address mockAddress = Create2.deploy(0, salt, abi.encodePacked(creationCode));
            vm.stopBroadcast();
            return mockAddress;
        } else {
            return computedAddress;
        }
    }
}
