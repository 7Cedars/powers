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

/// @title Deploy script Powers 101 
/// @notice Powers 101 is a simple example of a DAO. It acts as an introductory example of the Powers protocol. 
/// 
/// @author 7Cedars

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
// import { console2 } from "forge-std/console2.sol";

// core protocol
import { Powers} from "../src/Powers.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { DeployLaws } from "./DeployLaws.s.sol";
import { DeployMocks } from "./DeployMocks.s.sol";
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../test/mocks/Erc20TaxedMock.sol";
import { HelperConfig } from "./HelperConfig.s.sol";


/// @notice core script to deploy a dao
/// Note the {run} function for deploying the dao can be used without changes.
/// Note  the {initiateConstitution} function for creating bespoke constitution for the DAO.
/// Note the {getFounders} function for setting founders' roles.
contract DeployPowers101 is Script {
    string[] names;
    address[] lawAddresses;
    string[] mockNames;
    address[] mockAddresses;
    uint256 blocksPerHour;

    function run() external returns (address payable powers_, string[] memory mockNames_, address[] memory mockAddresses_) {
        HelperConfig helperConfig = new HelperConfig();
        blocksPerHour = helperConfig.getConfig().blocksPerHour;

        // Deploy the DAO and a mock erc20 votes contract.
        vm.startBroadcast();
        Powers powers = new Powers(
            "Powers 101",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreieioptfopmddgpiowg6duuzsd4n6koibutthev72dnmweczjybs4q"
        );
        vm.stopBroadcast();

        powers_ = payable(address(powers));

        // Deploy the laws.
        DeployLaws deployLaws = new DeployLaws();
        (names, lawAddresses) = deployLaws.run();
        DeployMocks deployMocks = new DeployMocks();
        (mockNames, mockAddresses) = deployMocks.run();

        // Create the constitution.
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(powers_);

        // constitute dao.
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (powers_, mockNames, mockAddresses);
    }

    function createConstitution(
        address payable powers_
    ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](8);
        
        //////////////////////////////////////////////////////////////////
        //                       Electoral laws                         // 
        //////////////////////////////////////////////////////////////////
        // This law allows accounts to self-nominate for any role
        // It can be used by community members
        conditions.allowedRole = 1; 
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Nominate me for delegate: Nominate yourself for a delegate role. You need to be a community member to use this law.",
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // This law enables role selection through delegated voting using an ERC20 token
        // Only role 0 (admin) can use this law
        conditions.allowedRole = 0;
        conditions.readStateFrom = 1;
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Elect delegates: Elect delegates using delegated votes. You need to be an admin to use this law.",
            targetLaw: parseLawAddress(0, "DelegateSelect"),
            config: abi.encode(
                parseMockAddress(2, "Erc20VotesMock"),
                15, // max role holders
                2 // roleId to be elected
            ),
            conditions: conditions
        });
        delete conditions;

        // This law enables anyone to select themselves as a community member. 
        // Any one can use this law
        conditions.throttleExecution = 25; // this law can be called once every 25 blocks. 
        conditions.allowedRole = type(uint256).max;
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "Self select as community member: Self select as a community member. Anyone can call this law.",
            targetLaw: parseLawAddress(4, "SelfSelect"),
            config: abi.encode(
                1 // roleId to be elected
            ),
            conditions: conditions
        });
        delete conditions;

        //////////////////////////////////////////////////////////////////
        //                       Executive laws                         // 
        //////////////////////////////////////////////////////////////////

        // This law allows proposing changes to core values of the DAO
        // Only community members can use this law. It is subject to a vote. 
        string[] memory inputParams = new string[](3);
        inputParams[0] = "address[] Targets";
        inputParams[1] = "uint256[] Values";
        inputParams[2] = "bytes[] Calldatas";

        conditions.allowedRole = 1;
        conditions.votingPeriod = minutesToBlocks(5); // = number of blocks = about 5 minutes. 
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members
        conditions.quorum = 20; // = 20% quorum needed
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "Statement of Intent: Create an SoI for an action that can later be executed by Delegates.",
            targetLaw: parseLawAddress(8, "StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        // This law allows a proposed action to be vetoed. 
        // Only the admin can use this law // not subhject to a vote, but the proposal needs to have passed by the community members. 
        conditions.allowedRole = 0;
        conditions.needCompleted = 4;
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetLaw: parseLawAddress(8, "StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        // This law allows executing any action with voting requirements
        // Only role 2 can use this law
        // Requires 20% quorum and 51% majority to pass
        conditions.allowedRole = 2;
        conditions.quorum = 50; // = 50% quorum needed
        conditions.succeedAt = 77; // = 77% simple majority needed for executing an action
        conditions.votingPeriod = minutesToBlocks(5); 
        conditions.needCompleted = 4;
        conditions.needNotCompleted = 5;
        conditions.delayExecution = minutesToBlocks(3); // = 15 blocks = about 3 minutes. This gives admin time to veto the action.  
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "Execute an action: Execute an action that has been proposed by the community.",
            targetLaw: parseLawAddress(6, "OpenAction"),
            config: abi.encode(), // empty config, an open action takes address[], uint256[], bytes[] as input.             
            conditions: conditions
        });
        delete conditions;

        // PresetAction for roles
        // This law sets up initial role assignments for the DAO & role labelling. It is a law that self destructs when executed. 
        // Only the admin can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(powers_, mockAddresses, 7);
        conditions.allowedRole = 0;
        lawInitData[7] = PowersTypes.LawInitData({
            nameDescription: "Initial setup: Assign labels and mint tokens. This law can only be executed once.",
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions
        });
        delete conditions;
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        // 
    //////////////////////////////////////////////////////////////

    function _getActions(address payable powers_, address[] memory mocks, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // call to set initial roles
        // NB! NEW ACTIONS ADDED HERE! 
        targets = new address[](5);
        values = new uint256[](5);
        calldatas = new bytes[](5);

        targets[0] = powers_;
        targets[1] = powers_;

        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegates");
        
        targets[2] =  mocks[2];
        calldatas[2] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 1000000000000000000);

        targets[3] = mocks[3];
        calldatas[3] = abi.encodeWithSelector(Erc20TaxedMock.faucet.selector);

        targets[4] = powers_;
        calldatas[4] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        
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
