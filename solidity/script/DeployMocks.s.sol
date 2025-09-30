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
import { SimpleGovernor } from "@mocks/SimpleGovernor.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";
import { SoulboundErc721 } from "@mocks/SoulboundErc721.sol";
import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";

// law contracts from @mocks/
import { Donations } from "@mocks/Donations.sol";
import { FlagActions } from "@mocks/FlagActions.sol";
import { Grant } from "@mocks/Grant.sol";
import { OpenElection } from "@mocks/OpenElection.sol";
import { Nominees } from "@mocks/Nominees.sol";
import { Erc20DelegateElection } from "@mocks/Erc20DelegateElection.sol";

// @dev this script is used to deploy the mocks to the chain.
// Note: we do not return addresses of the deployed mocks. -- I am thinking about scrapping it. It is more trouble than its worth
// addresses should be computed on basis of deployment data using create2.
contract DeployMocks is Script {
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.

    function run() external returns (string[] memory names, address[] memory addresses) {
        names = new string[](11);
        addresses = new address[](11);
        bytes[] memory creationCodes = new bytes[](11);

        names[0] = "SimpleErc20Votes";
        creationCodes[0] = type(SimpleErc20Votes).creationCode;
        addresses[0] = deployMock(creationCodes[0], names[0]);

        names[1] = "Erc20Taxed";
        creationCodes[1] = type(Erc20Taxed).creationCode;
        addresses[1] = deployMock(creationCodes[1], names[1]);

        names[2] = "SoulboundErc721";
        creationCodes[2] = type(SoulboundErc721).creationCode;
        addresses[2] = deployMock(creationCodes[2], names[2]);

        names[3] = "SimpleErc1155";
        creationCodes[3] = type(SimpleErc1155).creationCode;
        addresses[3] = deployMock(creationCodes[3], names[3]);

        names[4] = "SimpleGovernor";
        creationCodes[4] = abi.encodePacked(type(SimpleGovernor).creationCode, abi.encode(
            computeMockAddress(creationCodes[0], names[0])
        ));
        addresses[4] = deployMock(creationCodes[4], names[4]);

        // Deploy law contracts from @mocks/
        names[5] = "Donations";
        creationCodes[5] = type(Donations).creationCode;
        addresses[5] = deployMock(creationCodes[5], names[5]);

        names[6] = "FlagActions";
        creationCodes[6] = type(FlagActions).creationCode;
        addresses[6] = deployMock(creationCodes[6], names[6]);

        names[7] = "Grant";
        creationCodes[7] = type(Grant).creationCode;
        addresses[7] = deployMock(creationCodes[7], names[7]);

        names[8] = "Nominees";
        creationCodes[8] = type(Nominees).creationCode;
        addresses[8] = deployMock(creationCodes[8], names[8]);

        names[9] = "OpenElection";
        creationCodes[9] = type(OpenElection).creationCode;
        addresses[9] = deployMock(creationCodes[9], names[9]);

        names[10] = "Erc20DelegateElection";
        creationCodes[10] = abi.encodePacked(type(Erc20DelegateElection).creationCode, abi.encode(addresses[0]));
        addresses[10] = deployMock(creationCodes[10], names[10]);
    }

    //////////////////////////////////////////////////////////////
    //                   LAW DEPLOYMENT                         //
    //////////////////////////////////////////////////////////////
    function computeMockAddress(bytes memory creationCode, string memory name) public returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(name));
        return Create2.computeAddress(salt, keccak256(abi.encodePacked(creationCode)), create2Factory);
    }


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
