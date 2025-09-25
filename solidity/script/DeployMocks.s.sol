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

// external contracts
import { SimpleGovernor } from "../test/mocks/SimpleGovernor.sol";
import { SimpleErc20Votes } from "../test/mocks/SimpleErc20Votes.sol";
import { Erc20Taxed } from "../test/mocks/Erc20Taxed.sol";
import { SoulboundErc721 } from "../test/mocks/SoulboundErc721.sol";
import { SimpleErc1155 } from "../test/mocks/SimpleErc1155.sol";

// @dev this script is used to deploy the mocks to the chain.
// Note: we do not return addresses of the deployed mocks. -- I am thinking about scrapping it. It is more trouble than its worth
// addresses should be computed on basis of deployment data using create2.
contract DeployMocks is Script {
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.

    function run() external returns (string[] memory names, address[] memory addresses) {
        names = new string[](5);
        addresses = new address[](5);
        bytes[] memory creationCodes = new bytes[](5);

        names[0] = "SimpleErc20Votes";
        creationCodes[0] = type(SimpleErc20Votes).creationCode;
        addresses[0] = deployMock(creationCodes[0], names[0]);

        names[1] = "Erc20Taxed";
        creationCodes[1] = type(Erc20Taxed).creationCode;
        addresses[1] = deployMock(creationCodes[1], names[1]);

        names[2] = "SoulboundErc721";
        creationCodes[2] = abi.encodePacked(type(SoulboundErc721).creationCode, abi.encode(address(this)));
        addresses[2] = deployMock(creationCodes[2], names[2]);

        names[3] = "SimpleErc1155";
        creationCodes[3] = type(SimpleErc1155).creationCode;
        addresses[3] = deployMock(creationCodes[3], names[3]);

        names[4] = "SimpleGovernor";
        creationCodes[4] = abi.encodePacked(type(SimpleGovernor).creationCode, abi.encode(addresses[2]));
        addresses[4] = deployMock(creationCodes[4], names[4]);
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
