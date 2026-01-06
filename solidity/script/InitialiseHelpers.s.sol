// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
// import { console2 } from "forge-std/console2.sol";
// core protocol
import { Powers } from "@src/Powers.sol";
import { Mandate } from "@src/Mandate.sol";
import { IMandate } from "@src/interfaces/IMandate.sol";
import { MandateUtilities } from "@src/libraries/MandateUtilities.sol";
import { PowersTypes } from "@src/interfaces/PowersTypes.sol";

// external contracts
import { SimpleGovernor } from "@mocks/SimpleGovernor.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";
import { Erc20DelegateElection } from "@mocks/Erc20DelegateElection.sol";
import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";
import { SoulboundErc721 } from "@src/helpers/SoulboundErc721.sol";

// helper contracts
import { Donations } from "@src/helpers/Donations.sol";
import { FlagActions } from "@src/helpers/FlagActions.sol";
import { Grant } from "@src/helpers/Grant.sol";
import { OpenElection } from "@src/helpers/OpenElection.sol";
import { Nominees } from "@src/helpers/Nominees.sol";
import { TreasurySimple } from "@src/helpers/TreasurySimple.sol";
import { TreasuryPools } from "@src/helpers/TreasuryPools.sol";

// @dev this script is used to deploy the Helpers to the chain. 
contract InitialiseHelpers is Script {
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.
    string[] names;
    address[] addresses;
    bytes[] creationCodes; 
    uint256 index;

    function run() public {
        index = names.length;
        names.push("SimpleErc20Votes");
        creationCodes.push(type(SimpleErc20Votes).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));
        
        index = names.length;
        names.push("Erc20Taxed");
        creationCodes.push(type(Erc20Taxed).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));

        index = names.length;
        names.push("SoulboundErc721");
        creationCodes.push(type(SoulboundErc721).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));

        index = names.length;
        names.push("SimpleErc1155");
        creationCodes.push(type(SimpleErc1155).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));

        index = names.length;
        names.push("SimpleGovernor");
        creationCodes.push(abi.encodePacked(type(SimpleGovernor).creationCode, abi.encode(computeHelperAddress(creationCodes[0], names[0]))));
        addresses.push(deployHelper(creationCodes[index], names[index]));
 
        index = names.length;
        names.push("Donations");
        creationCodes.push(type(Donations).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));

        index = names.length;
        names.push("FlagActions");
        creationCodes.push(type(FlagActions).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));

        index = names.length;
        names.push("Grant");
        creationCodes.push(type(Grant).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));
        
        index = names.length;
        names.push("Nominees");
        creationCodes.push(type(Nominees).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));

        index = names.length;
        names.push("OpenElection");
        creationCodes.push(type(OpenElection).creationCode);    
        addresses.push(deployHelper(creationCodes[index], names[index]));
        
        index = names.length;
        names.push("Erc20DelegateElection");
        creationCodes.push(abi.encodePacked(type(Erc20DelegateElection).creationCode, abi.encode(addresses[0])));
        addresses.push(deployHelper(creationCodes[index], names[index]));

        index = names.length;
        names.push("TreasurySimple");
        creationCodes.push(type(TreasurySimple).creationCode);
        addresses.push(deployHelper(creationCodes[index], names[index]));

        index = names.length;
        names.push("TreasuryPools");
        creationCodes.push(abi.encodePacked(type(TreasuryPools).creationCode, abi.encode(addresses[0])));
        addresses.push(deployHelper(creationCodes[index], names[index]));
    }

    //////////////////////////////////////////////////////////////
    //                   LAW DEPLOYMENT                         //
    //////////////////////////////////////////////////////////////
    function computeHelperAddress(bytes memory creationCode, string memory name) public returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(name));
        return Create2.computeAddress(salt, keccak256(abi.encodePacked(creationCode)), create2Factory);
    }

    function deployHelper(bytes memory creationCode, string memory name) public returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(name));

        address computedAddress = Create2.computeAddress(
            salt,
            keccak256(abi.encodePacked(creationCode)),
            create2Factory // create2 factory address. NEED TO INCLUDE THIS!
        );

        if (computedAddress.code.length == 0) {
            vm.startBroadcast();
            address HelperAddress = Create2.deploy(0, salt, abi.encodePacked(creationCode));
            vm.stopBroadcast();
            return HelperAddress;
        } else {
            return computedAddress;
        }
    }

    function getDeployedHelpers() external returns (string[] memory, address[] memory) {
        run();
        return (names, addresses);
    }

    function getHelperAddress(string memory helperName) external view returns (address) {
        bytes32 mandateHash = keccak256(abi.encodePacked(helperName));
        for (uint256 i = 0; i < names.length; i++) {
            bytes32 nameHash = keccak256(abi.encodePacked(names[i]));
            if (nameHash == mandateHash) {
                return addresses[i];
            }
        }
        revert("Helper not found");
    }
}
