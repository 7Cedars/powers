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
import { console2 } from "forge-std/console2.sol";

// core protocol
import { Powers} from "../src/Powers.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { DeployLaws } from "./DeployLaws.s.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

// mocks
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol"; 

/// @notice core script to deploy a dao
/// Note the {run} function for deploying the dao can be used without changes.
/// Note  the {initiateConstitution} function for creating bespoke constitution for the DAO.
/// Note the {getFounders} function for setting founders' roles.
contract DeployPowers101 is Script {
    string[] names;
    address[] lawAddresses;
    function run()
        external
        returns (
            address payable dao,
            address payable mock20votes_
            )
    {
        // Deploy the DAO and a mock erc20 votes contract.
        vm.startBroadcast();
        Powers powers = new Powers(
            "Powers 101",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreifn5azisbssrldl4tqfwdmiebzfx4wupefvxw4j74wdudxagodshe"
        );
        Erc20VotesMock erc20VotesMock = new Erc20VotesMock();
        vm.stopBroadcast();

        dao = payable(address(powers));
        mock20votes_ = payable(address(erc20VotesMock));

        // Deploy the laws.
        DeployLaws deployLaws = new DeployLaws();
        (names, lawAddresses) = deployLaws.run();

        // Create the constitution.
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(dao, mock20votes_);

        // constitute dao.
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (dao, mock20votes_);
    }

    function createConstitution(
        address payable dao_,
        address payable mock20votes_
        ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](8);
        
        //////////////////////////////////////////////////////////////////
        //                       Electoral laws                         // 
        //////////////////////////////////////////////////////////////////
        // This law allows accounts to self-nominate for any role
        // It can be used by any one (allowedRole = type(uint32).max)
        conditions.allowedRole = type(uint32).max; 
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(), // empty config
            conditions: conditions,
            description: "Nominate yourself for a delegate role."
        });
        delete conditions;

        // This law enables role selection through delegated voting using an ERC20 token
        // Only role 0 (admin) can use this law
        conditions.allowedRole = 0;
        conditions.readStateFrom = 1;
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(0, "DelegateSelect"),
            config: abi.encode(
                mock20votes_,
                15, // max role holders
                2 // roleId to be elected
            ),
            conditions: conditions,
            description: "Elect delegates using delegated votes."
        });
        delete conditions;

        // This law enables anyone to select themselves as a community member. 
        // Any one can use this law
        conditions.allowedRole = type(uint32).max;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(4, "SelfSelect"),
            config: abi.encode(
                1 // roleId to be elected
            ),
            conditions: conditions,
            description: "Self select as community member."
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
        conditions.votingPeriod = 60; // = number of blocks = about 5 minutes. 
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members
        conditions.quorum = 20; // = 20% quorum needed
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParams),
            conditions: conditions,
            description: "Propose a new action."
        });
        delete conditions;

        // This law allows a proposed action to be vetoed. 
        // Only the admin can use this law // not subhject to a vote, but the proposal needs to have passed by the community members. 
        conditions.allowedRole = 0;
        conditions.needCompleted = 4;
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParams),
            conditions: conditions,
            description: "Veto a proposed action."
        });
        delete conditions;

        // This law allows executing any action with voting requirements
        // Only role 2 can use this law
        // Requires 20% quorum and 51% majority to pass
        conditions.allowedRole = 2;
        conditions.quorum = 50; // = 50% quorum needed
        conditions.succeedAt = 77; // = 77% simple majority needed for executing an action
        conditions.votingPeriod = 60; // = number of blocks = about 5 minutes. 
        conditions.needCompleted = 4;
        conditions.needNotCompleted = 5;
        conditions.delayExecution = 120; // = 120 blocks = about 10 minutes. This gives admin time to veto the action.  
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(6, "OpenAction"),
            config: abi.encode(), // empty config, an open action takes address[], uint256[], bytes[] as input.             
            conditions: conditions,
            description: "Execute an open action."
        });
        delete conditions;

        // PresetAction for roles
        // This law sets up initial role assignments for the DAO & role labelling. It is a law that self destructs when executed. 
        // Only the admin can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(dao_, 7);
        conditions.allowedRole = 0;
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions,
            description: "Assigns roles and labels."
        });
        delete conditions;
    }

    function _getActions(address payable dao_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");
        address gary = makeAddr("gary");

        // call to set initial roles
        targets = new address[](13);
        values = new uint256[](13);
        calldatas = new bytes[](13);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }

        calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, alice);
        calldatas[1] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, bob);
        calldatas[2] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, charlotte);
        calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, david);
        calldatas[4] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, eve);
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, frank);
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, gary);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, alice);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, bob);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, charlotte);
        calldatas[10] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[11] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegates");
        // revoke law after use
        if (lawId != 0) {
            calldatas[12] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        }
        return (targets, values, calldatas);
    }
    
    function parseLawAddress(uint256 index, string memory lawName) public view returns (address lawAddress) {
        if (keccak256(abi.encodePacked(lawName)) != keccak256(abi.encodePacked(names[index]))) {
            revert("Law name does not match");
        }
        return lawAddresses[index];
    }
} 
