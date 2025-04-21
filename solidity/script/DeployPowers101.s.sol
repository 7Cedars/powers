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
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiebpc5ynyisal3ee426jgpib2vawejibzfgmopjxtmucranjy26py"
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
        
        // This law allows direct selection of accounts to specific roles without voting
        // It can be used by any role (allowedRole = type(uint32).max)
        conditions.allowedRole = type(uint32).max;
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(1, "DirectSelect"),
            config: abi.encode(1), // role that can be assigned
            conditions: conditions,
            description: "A law to select an account to a specific role directly."
        });
        delete conditions;

        // This law allows accounts to self-nominate for any role
        // It can be used by any role (allowedRole = type(uint32).max)
        conditions.allowedRole = type(uint32).max;
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(), // empty config
            conditions: conditions,
            description: "A law for accounts to nominate themselves for a role."
        });
        delete conditions;

        // This law enables role selection through delegated voting using an ERC20 token
        // Only role 1 can use this law
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(0, "DelegateSelect"),
            config: abi.encode(
                mock20votes_,
                15, // max role holders
                2 // roleId to be elected
            ),
            conditions: conditions,
            description: "A law to select a role by delegated votes."
        });
        delete conditions;

        // This law allows proposing changes to core values of the DAO
        // Only role 3 can use this law
        string[] memory inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = 3;
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParams),
            conditions: conditions,
            description: "A law to propose a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented."
        });
        delete conditions;

        // This law allows executing any action with voting requirements
        // Only role 2 can use this law
        // Requires 30% quorum and 51% majority to pass
        conditions.allowedRole = 2;
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(6, "OpenAction"),
            config: abi.encode(), // empty config
            conditions: conditions,
            description: "A law to execute an open action."
        });
        delete conditions;

        // This law allows executing predefined actions with voting requirements
        // Only role 1 can use this law
        // Requires 30% quorum, 51% majority, and 3 completed actions to pass
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");
        // 
        conditions.allowedRole = 1;
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needCompleted = 3;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targets, values, calldatas),
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;

        // PresetAction for roles
        // This law sets up initial role assignments for the DAO
        // Only role 0 can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_, 7);
        conditions.allowedRole = 0;
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;
    }

    function _getRoles(address payable dao_, uint16 lawId)
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
        calldatas[10] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, alice);
        calldatas[11] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, bob);
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
