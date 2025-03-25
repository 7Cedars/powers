// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

// core protocol
import { Powers} from "../src/Powers.sol";
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

// A script that will deploy all the existing laws to the network.
// It checks if a law has already been deployed and if so, it will not be deployed again.
contract DeployLaws is Script {
    struct LawDeployData {
        string name;
        string description;
        bytes creationCode;
    }
    function run() external returns (address[] memory) {
        LawDeployData[] memory laws = new LawDeployData[](1);
        
        // laws[0] = LawDeployData({
        //     name: "DelegateSelect",
        //     description: "A law to elect accounts to roles via delegated votes.",
        //     creationCode: type(DelegateSelect).creationCode
        // });
        // laws[1] = LawDeployData({
        //     name: "DirectSelect",
        //     description: "A law to select an account to a specific role directly.",
        //     creationCode: type(DirectSelect).creationCode
        // });
        // laws[2] = LawDeployData({
        //     name: "PeerSelect",
        //     description: "A law to elect accounts to by their peers.",
        //     creationCode: type(PeerSelect).creationCode
        // });
        // laws[3] = LawDeployData({
        //     name: "RenounceRole",
        //     description: "A law to renounce a role.",
        //     creationCode: type(RenounceRole).creationCode
        // });
        // laws[4] = LawDeployData({
        //     name: "SelfSelect",
        //     description: "A law to select a role for oneself.",
        //     creationCode: type(SelfSelect).creationCode
        // });
        // laws[5] = LawDeployData({
        //     name: "BespokeAction",
        //     description: "A law to execute a bespoke action.",
        //     creationCode: type(BespokeAction).creationCode
        // });
        // laws[6] = LawDeployData({
        //     name: "OpenAction",
        //     description: "A law to execute an open action.",
        //     creationCode: type(OpenAction).creationCode
        // });
        // laws[7] = LawDeployData({
        //     name: "PresetAction",
        //     description: "A law to execute a preset action.",
        //     creationCode: type(PresetAction).creationCode
        // });
        laws[0] = LawDeployData({
            name: "ProposalOnly",
            description: "A law to propose a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented.",
            creationCode: type(ProposalOnly).creationCode
        });
        // // state laws
        // laws[9] = LawDeployData({
        //     name: "AddressesMapping",
        //     description: "A law to add and remove addresses from a mapping.",
        //     creationCode: type(AddressesMapping).creationCode
        // });
        // laws[10] = LawDeployData({
        //     name: "NominateMe",
        //     description: "A law for accounts to nominate themselves for a role.",
        //     creationCode: type(NominateMe).creationCode
        // });
        // laws[11] = LawDeployData({
        //     name: "StringsArray",
        //     description: "A law to add and remove values from an array.",
        //     creationCode: type(StringsArray).creationCode
        // });
        // laws[12] = LawDeployData({
        //     name: "TokensArray",
        //     description: "A law to add and remove values from an array.",
        //     creationCode: type(TokensArray).creationCode
        // });

        address[] memory lawsDeployed = new address[](laws.length);

        for (uint256 i = 0; i < laws.length; i++) {
            lawsDeployed[i] = deployLaw(
                laws[i].name,
                laws[i].description,
                laws[i].creationCode
            );
        }

        return lawsDeployed;
    }

    //////////////////////////////////////////////////////////////
    //                   LAW DEPLOYMENT                         //
    //////////////////////////////////////////////////////////////

    function deployLaw(
        string memory name,
        string memory description, 
        bytes memory creationCode
    ) public returns (address lawAddress) {
        if (creationCode.length == 0) {
            return address(0);
        }
        lawAddress = Create2.computeAddress(
            bytes32(keccak256(abi.encodePacked(description))),
            keccak256(
                abi.encodePacked(
                    creationCode, 
                    abi.encodePacked(name, description)
                )
            )
        );

        if (lawAddress.code.length > 0) {   
            return lawAddress;
        } else {
            vm.startBroadcast();
            lawAddress = Create2.deploy(
                0, 
                bytes32(keccak256(abi.encodePacked("test"))),
                abi.encodePacked(
                    creationCode, 
                    abi.encodePacked(name, description)
                )
            );
            vm.stopBroadcast();
            return lawAddress;
        }
    }

}
