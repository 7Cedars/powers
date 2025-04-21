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

// laws
import { NominateMe } from "../src/laws/state/NominateMe.sol";
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
import { OpenAction } from "../src/laws/executive/OpenAction.sol";
import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";
import { StringsArray } from "../src/laws/state/StringsArray.sol";
import { TokensArray } from "../src/laws/state/TokensArray.sol";
import { SelfSelect } from "../src/laws/electoral/SelfSelect.sol";
import { RenounceRole } from "../src/laws/electoral/RenounceRole.sol";
import { AddressesMapping } from "../src/laws/state/AddressesMapping.sol";
import { TaxSelect } from "../src/laws/electoral/TaxSelect.sol";
import { HolderSelect } from "../src/laws/electoral/HolderSelect.sol";
import { Grant } from "../src/laws/state/Grant.sol";
// @dev this script is used to deploy the laws to the chain.
// Note: we do not return addresses of the deployed laws.
// addresses should be computed on basis of deployment data using create2.
contract DeployLaws is Script {
    
    function run() external returns (string[] memory names, address[] memory addresses) {
        names = new string[](16);
        addresses = new address[](16);
        bytes[] memory creationCodes = new bytes[](16);

        names[0] = "DelegateSelect";
        creationCodes[0] = type(DelegateSelect).creationCode;

        names[1] = "DirectSelect";
        creationCodes[1] = type(DirectSelect).creationCode;

        names[2] = "PeerSelect";
        creationCodes[2] = type(PeerSelect).creationCode;

        names[3] = "RenounceRole";
        creationCodes[3] = type(RenounceRole).creationCode;

        names[4] = "SelfSelect";
        creationCodes[4] = type(SelfSelect).creationCode;

        names[5] = "BespokeAction";
        creationCodes[5] = type(BespokeAction).creationCode;

        names[6] = "OpenAction";
        creationCodes[6] = type(OpenAction).creationCode;

        names[7] = "PresetAction";
        creationCodes[7] = type(PresetAction).creationCode;

        names[8] = "ProposalOnly";
        creationCodes[8] = type(ProposalOnly).creationCode;

        names[9] = "AddressesMapping";
        creationCodes[9] = type(AddressesMapping).creationCode;

        names[10] = "NominateMe";
        creationCodes[10] = type(NominateMe).creationCode;

        names[11] = "StringsArray";
        creationCodes[11] = type(StringsArray).creationCode;

        names[12] = "TokensArray";
        creationCodes[12] = type(TokensArray).creationCode;

        names[13] = "TaxSelect";
        creationCodes[13] = type(TaxSelect).creationCode;

        names[14] = "HolderSelect";
        creationCodes[14] = type(HolderSelect).creationCode;

        names[15] = "Grant";
        creationCodes[15] = type(Grant).creationCode;

        for (uint256 i = 0; i < names.length; i++) {
           addresses[i] = deployLaw(creationCodes[i], names[i]);
        }
    }

    //////////////////////////////////////////////////////////////
    //                   LAW DEPLOYMENT                         //
    //////////////////////////////////////////////////////////////
    function deployLaw(bytes memory creationCode, string memory name) public returns (address) {
        bytes32 salt = bytes32(abi.encodePacked(name));
        address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.

        address computedAddress = Create2.computeAddress(
            salt,
            keccak256(abi.encodePacked(creationCode, abi.encode(name))),
            create2Factory // create2 factory address. NEED TO INCLUDE THIS!
        );

        if (computedAddress.code.length == 0) {
            vm.startBroadcast();
            address lawAddress = Create2.deploy(0, salt, abi.encodePacked(creationCode, abi.encode(name)));
            vm.stopBroadcast();
            // console2.log(string.concat(name, " deployed at (new deployment): "), lawAddress);
            return lawAddress;
        } else {
            // console2.log(string.concat(name, " deployed at: "), computedAddress);
            return computedAddress;
        }
    }
}
