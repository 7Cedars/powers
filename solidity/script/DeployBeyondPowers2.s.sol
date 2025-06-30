// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title Deploy script Beyond Powers
/// @notice Beyond Powers showcases a DAO that integrates on- and off-chain discussion and voting, integrating snapshot and tally into one governance system.
///         It uses Chainlink Functions to fetch the latest off-chain data from Snapshot.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
// import { console2 } from "forge-std/console2.sol";

// core protocol 
import { Powers } from "../src/Powers.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { DeployLaws } from "./DeployLaws.s.sol";
import { DeployMocks } from "./DeployMocks.s.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

// mocks
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { GovernorMock } from "../test/mocks/GovernorMock.sol";

contract DeployBeyondPowers2 is Script {
    string[] names;
    address[] lawAddresses;
    string[] mockNames;
    address[] mockAddresses;
    string[] inputParamsAdopt;

    HelperConfig helperConfig = new HelperConfig();
    uint256 blocksPerHour;
    uint64 subscriptionId;
    uint32 gasLimit;
    bytes32 donID;

    function run() external returns (address payable powers_) {
        blocksPerHour = helperConfig.getConfig().blocksPerHour;
        subscriptionId = helperConfig.getConfig().chainlinkFunctionsSubscriptionId;
        gasLimit = helperConfig.getConfig().chainlinkFunctionsGasLimit;
        donID = helperConfig.getConfig().chainlinkFunctionsDonId;
        
        vm.startBroadcast();
        Powers powers = new Powers(
            "Beyond Powers",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibb4fcsnon2xzjcq63notbdhgxzy6v2khgkvd5fwz5j3cb3vhbp6m"
        );
        vm.stopBroadcast();
        powers_ = payable(address(powers));

        // Deploy the laws
        DeployLaws deployLaws = new DeployLaws();
        (names, lawAddresses) = deployLaws.run();
        DeployMocks deployMocks = new DeployMocks();
        (mockNames, mockAddresses) = deployMocks.run();

        // Create the constitution
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(powers_);

        // console2.log("lawInitData[0]");
        // console2.logBytes(lawInitData[0].config);
        // console2.log("lawInitData[1]");
        // console2.logBytes(lawInitData[1].config);

        // constitute dao
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (powers_);
    }

    function createConstitution(
        address payable powers_
    ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](2);

        //////////////////////////////////////////////////////
        //               Executive Laws                     // 
        //////////////////////////////////////////////////////

        // A Law to allows a proposal to be made.
        conditions.allowedRole = type(uint256).max; // any one can use this law
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Does proposal exist: Check if a proposal and choice exists at the hvax.eth Snapshot space.",
            targetLaw: parseLawAddress(26, "SnapToGov_CheckSnapExists"),
            config: abi.encode(
                "hvax.eth", // spaceId
                subscriptionId,
                gasLimit,
                donID
            ),
            conditions: conditions
        });
        delete conditions;

      return lawInitData;
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        // 
    //////////////////////////////////////////////////////////////
    function _getActions(address payable powers_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // call to set initial roles
        targets = new address[](2);
        values = new uint256[](2);
        calldatas = new bytes[](2);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = powers_;
        }
        // label roles
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        return (targets, values, calldatas);
    }

    function parseLawAddress(uint256 index, string memory lawName) public view returns (address lawAddress) {
        if (keccak256(abi.encodePacked(lawName)) != keccak256(abi.encodePacked(names[index]))) {
            revert("Law name does not match");
        }
        return lawAddresses[index];
    }

    function parseMockAddress(uint256 index, string memory mockName) public view returns (address mockAddress) {
        if (keccak256(abi.encodePacked(mockName)) != keccak256(abi.encodePacked(mockNames[index]))) {
            revert("Mock name does not match");
        }
        return mockAddresses[index];
    }

    function minutesToBlocks(uint256 min) public view returns (uint32 blocks) {
        blocks = uint32(min * blocksPerHour / 60);
    }
}

