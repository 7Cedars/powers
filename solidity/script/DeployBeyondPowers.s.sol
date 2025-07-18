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

contract DeployBeyondPowers is Script {
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
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreia377dgpm7276q74nr3dijipu65p2arqu2ivpioo6fwghyfsgrdpm"
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
        lawInitData = new PowersTypes.LawInitData[](10);

        //////////////////////////////////////////////////////
        //               Executive Laws                     // 
        //////////////////////////////////////////////////////

        // A Law to check if a proposal and choice exists, and linking it to targets[], values[], calldatas[].
        conditions.allowedRole = 1; // executioners can use this law
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Does proposal exist?: Check if a proposal and choice exists at the hvax.eth Snapshot space.",
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

        // A Law to check if a proposal and choice exists, and linking it to targets[], values[], calldatas[].
        conditions.allowedRole = 1; // executioners can use this law
        conditions.needCompleted = 1;
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Did choice pass?: Check if a proposal and choice passed at the hvax.eth Snapshot space.",
            targetLaw: parseLawAddress(27, "SnapToGov_CheckSnapPassed"),
            config: abi.encode(
                "hvax.eth", // spaceId
                subscriptionId,
                gasLimit,
                donID
            ),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 1; // executioners can use this law
        conditions.needCompleted = 2;
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "Create Governor.sol proposal: Create a new Governor.sol proposal using Erc20VotesMock as votes.",
            targetLaw: parseLawAddress(28, "SnapToGov_CreateGov"),
            config: abi.encode(parseMockAddress(2, "Erc20VotesMock")),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 2; // Security council members can use this law
        conditions.needCompleted = 3;
        conditions.quorum = 77; // 77% of the Security Council members must vote to cancel a proposal.
        conditions.votingPeriod = minutesToBlocks(5); // 10 minutes.
        conditions.succeedAt = 51; // 51% majority. 
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "Cancel Governor.sol proposal: Cancel a Governor.sol proposal.",
            targetLaw: parseLawAddress(29, "SnapToGov_CancelGov"),
            config: abi.encode(parseMockAddress(2, "Erc20VotesMock")),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 1; // Security council members can use this law
        conditions.needCompleted = 3;
        conditions.quorum = 10; // 10% of the Security Council members must vote to execute a proposal.
        conditions.votingPeriod = minutesToBlocks(5); // 10 minutes.
        conditions.succeedAt = 10; // 10% majority.
        conditions.delayExecution = minutesToBlocks(10); // 10 minutes.
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "Execute Governor.sol proposal: Execute a Governor.sol proposal.",
            targetLaw: parseLawAddress(30, "SnapToGov_ExecuteGov"),
            config: abi.encode(parseMockAddress(2, "Erc20VotesMock")),
            conditions: conditions
        });
        delete conditions;

        //////////////////////////////////////////////////////
        //               Electoral Laws                     // 
        //////////////////////////////////////////////////////

        // A Law to nominate oneself for Executioner role
        conditions.allowedRole = type(uint256).max; // anyone can use this law
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "Nominate oneself: Nominate oneself for the Executives role.",
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(),
            conditions: conditions
        });
        delete conditions;

        // a law to elect executioners by delegated tokens. 
        conditions.allowedRole = type(uint256).max; // anyone can use this law
        conditions.readStateFrom = 6;
        lawInitData[7] = PowersTypes.LawInitData({
            nameDescription: "Elect executives: Elect executives using delegated tokens.",
            targetLaw: parseLawAddress(0, "DelegateSelect"),
            config: abi.encode(parseMockAddress(2, "Erc20VotesMock"), 50, 1),
            conditions: conditions
        });
        delete conditions;

        // a law that allows the admin to (de)select members for the security council. 
        conditions.allowedRole = 0; // admin can use this law
        lawInitData[8] = PowersTypes.LawInitData({
            nameDescription: "Select Security Council: Select members for the Security Council.",
            targetLaw: parseLawAddress(1, "DirectSelect"),
            config: abi.encode(2), // roleId
            conditions: conditions
        });
        delete conditions;

        //////////////////////////////////////////////////////
        //               Initiation Law                     // 
        //////////////////////////////////////////////////////
        
        // Preset law to assign previous DAO role
        // Only admin (role 0) can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(powers_, 9);
        conditions.allowedRole = type(uint256).max; // anyone can use execute this law. 
        lawInitData[9] = PowersTypes.LawInitData({
            nameDescription: "Initial setup: Assign role labels. This law can only be executed once.",
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        // 
    //////////////////////////////////////////////////////////////
    function _getActions(address payable powers_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // call to set initial roles
        targets = new address[](3);
        values = new uint256[](3);
        calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = powers_;
        }
        // label roles
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Executives");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Security Council");
        calldatas[2] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
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

