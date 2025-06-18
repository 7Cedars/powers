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
/// @notice Beyond Powers is a simple example of a DAO that integrates with Tally.xyz and (TBI) snapshot. 
///
/// Currently, this example implements:
/// - A law to create a proposal on Tally.xyz that includes a quantity (of tokens to mint).
/// - A law to check the status of a Tally.xyz proposal.
///
/// Future plans:
/// - A law to create a proposal on snapshot that includes a quantity (of tokens to mint).
/// - A law to check the status of a snapshot proposal.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

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

    function run() external returns (address payable powers_) {
        blocksPerHour = helperConfig.getConfig().blocksPerHour;
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
        lawInitData = new PowersTypes.LawInitData[](6);

        //////////////////////////////////////////////////////
        //               Executive Laws                     // 
        //////////////////////////////////////////////////////

        string[] memory inputParams = new string[](4);
        inputParams[0] = "address[] Targets";
        inputParams[1] = "uint256[] Values";
        inputParams[2] = "bytes[] Calldatas"; 
        inputParams[3] = "string Description";
    
        // A Law to allows a proposal to be made.
        conditions.allowedRole = 1; // member role
        conditions.votingPeriod = minutesToBlocks(5); // about 5 minutes
        conditions.quorum = 50; // 30% quorum
        conditions.succeedAt = 33; // 51% majority
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Propose an action: Propose an action inside Powers.",
            targetLaw: parseLawAddress(8, "StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        // Law to send proposal to tally.xyz
        // any one can use this law.
        conditions.allowedRole = type(uint256).max; // anyone 
        conditions.needCompleted = 1; // law 1 should have passed
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Send to Governor: Send a proposal to Governor.sol.",
            targetLaw: parseLawAddress(24, "GovernorCreateProposal"),
            config: abi.encode(parseMockAddress(2, "Erc20VotesMock")),
            conditions: conditions
        });
        delete conditions;

        // Law to check the Tally.xyz proposal and execute in case it has passed the vote. 
        // Only previous DAO (role 1) can use this law
        conditions.allowedRole = type(uint256).max; // anyone  
        conditions.needCompleted = 2; // law 2 should have passed
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "Execute proposal: Check the status of a proposal at Governor.sol. If it has passed its vote, execute the proposal.",
            targetLaw: parseLawAddress(25, "GovernorExecuteProposal"),
            config: abi.encode(parseMockAddress(2, "Erc20VotesMock")),
            conditions: conditions
        });
        delete conditions;


        //////////////////////////////////////////////////////
        //                 Electoral Laws                   // 
        //////////////////////////////////////////////////////
        // Law to nominate oneself for member role
        // No role restrictions, anyone can use this law
        conditions.throttleExecution = 25; // this law can be called once every 25 blocks. 
        conditions.allowedRole = type(uint256).max;
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "Self select as community member: Self select as a community member. Anyone can call this law.",
            targetLaw: parseLawAddress(4, "SelfSelect"),
            config: abi.encode(
                1 // roleId to be elected
            ),
            conditions: conditions
        });
        delete conditions;

        // Preset law to assign previous DAO role
        // Only admin (role 0) can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(powers_, uint16(lawInitData.length - 1));
        conditions.allowedRole = 0; // admin role
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "Initial setup: Assign labels. This law can only be executed once.",
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

