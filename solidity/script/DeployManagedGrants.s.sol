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

/// @title Deploy script Managed Grants
/// @notice Managed Grants is a DAO example that implements a grant management system with multiple roles and checks and balances.
/// 
/// This example implements: (implementation is not fully complete.)
/// Executive laws: 
/// - A law to start grants: BespokeAction, access role = delegates. By majority vote.
/// - A law to stop grants: BespokeAction, access role = delegates. By majority vote.
/// - A law that allows community members to request assets from a specific grant law, access role = members.
/// - A law that allows allocators to assign assets to a grant request. Access role = allocator.
/// - A law to challenge a decision by allocators. Access role = members.
/// - A law to revert a decision by allocators. Can only react to a challenge from a public account. Access role = judge.
///
/// Electoral laws: (possible roles: allocator, judge, community member, delegate)
/// - a law to self select as community member. Access role: public.
/// - a law to assign and revoke account to judge role. Access role: Admin. 
/// - a law to nominate oneself for a delegate role. Access role: public.
/// - a law to assign a delegate role to a nominated account. Access role: public, delegate election.
/// - a law to nominate oneself for an allocator role. Access role: public.
/// - a law to assign or revoke allocator role to a nominated account. Access role: delegate, using majority vote.

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

contract DeployManagedGrants is Script {
    string[] names;
    address[] lawAddresses;
    string[] mockNames;
    address[] mockAddresses;

    function run() external returns (address payable powers_) {
        // Deploy the DAO 
        vm.startBroadcast();
        Powers powers = new Powers(
            "Managed Grants",
            // TODO: this is still a placeholder: it is the data for Powers 101
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiebpc5ynyisal3ee426jgpib2vawejibzfgmopjxtmucranjy26py"
        );
        vm.stopBroadcast();
        powers_ = payable(address(powers));

        // Deploy laws & mocks 
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
        ILaw.Conditions memory grantConditions;
        lawInitData = new PowersTypes.LawInitData[](13);

        //////////////////////////////////////////////////////
        //               Executive Laws                     // 
        //////////////////////////////////////////////////////
        // This law allows community members to request a grant from a Grant program. 
        // Access role = members.
        conditions.allowedRole = 1; // member role
        string[] memory inputParams = new string[](3);
        inputParams[0] = "address Grantee";
        inputParams[1] = "address Grant";
        inputParams[2] = "uint256 Quantity";
         
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParams), 
            conditions: conditions,
            description: "Request a grant."
        });
        delete conditions;

        // This law allows judges to veto the deployment of a new grant program. 
        // Access role = judges.
        conditions.allowedRole = 3; // judge role
        conditions.votingPeriod = 60; // 60 blocks, about 5 minutes
        conditions.quorum = 66; // 66% quorum: 66% of judges need to vote for a new grant program to be deployed. 
        conditions.succeedAt = 66; // 66% majority
        
        inputParams = new string[](4);
        inputParams[0] = "uint48 Duration";
        inputParams[1] = "uint256 Budget";
        inputParams[2] = "address TokenAddress";
        inputParams[3] = "string GrantDescription";
 
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParams), 
            conditions: conditions,
            description: "Request a grant."
        });
        delete conditions;

        // This law allows delegates to start a grant program. 
        // Access role = delegates.
        // NB: these are the conditions for grant programs that will be deployed.
        grantConditions.allowedRole = 4; // allocator role
        grantConditions.needCompleted = 1; // A member needs to have passed a grant request proposal. 
        grantConditions.quorum = 33; // 33% quorum need to ok a grant request. 
        grantConditions.votingPeriod = 60; // 60 blocks, about 5 minutes
        grantConditions.succeedAt = 51; // simple 51% majority 

        // NB: these are the conditions for the deploy grants law.  
        conditions.allowedRole = 2; // delegate role
        conditions.votingPeriod = 60; // 60 blocks, about 5 minutes
        conditions.quorum = 66; // 66% quorum: 66% of delegates need to vote for a new grant program to be deployed. 
        conditions.succeedAt = 66; // 66% majority
        conditions.delayExecution = 120; // 240 blocks, about 20 minutes
        conditions.needNotCompleted = 2; // judges should not have vetoed the grant program. 

        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(16, "StartGrant"),
            config: abi.encode(parseLawAddress(15, "Grant"), abi.encode(grantConditions)), // the same input params as the proposal law
            conditions: conditions,
            description: "Deploy a grant program."
        });
        delete conditions;
        delete grantConditions;

        // This law allows delegates to stop a grant program. -- but only if the grant has spent nearly all its tokens or expired. 
        conditions.allowedRole = 2; // delegate role
        conditions.votingPeriod = 60; // 60 blocks, about 5 minutes
        conditions.quorum = 66; // 66% quorum: 66% of delegates need to vote for a new grant program to be deployed. 
        conditions.succeedAt = 66; // 66% majority
        conditions.needCompleted = 3; // a delegate needs to have started a grant program. 

        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(17, "StopGrant"),
            config: abi.encode(10, true),
            conditions: conditions,
            description: "Stop a grant program."
        });
        delete conditions;

        // Judges can stop a grant program at any time. 
        conditions.allowedRole = 3; // judge role
        conditions.votingPeriod = 60; // 60 blocks, about 5 minutes
        conditions.quorum = 75; // 66% quorum: 66% of judges need to vote to stop a grant program. 
        conditions.succeedAt = 51; // 66% majority 
        conditions.needCompleted = 2; // a delegate needs to have started a grant program. 
        
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(17, "StopGrant"),
            config: abi.encode(0, false), // Note: no checks. 
            conditions: conditions,
            description: "Stop a grant program."
        });
        delete conditions;

        // //////////////////////////////////////////////////////
        // //                 Electoral Laws                   // 
        // //////////////////////////////////////////////////////
           // This law allows accounts to self-nominate for any role
        // It can be used by community members
        conditions.allowedRole = 1; 
        lawInitData[6] = PowersTypes.LawInitData({
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
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(0, "DelegateSelect"),
            config: abi.encode(
                parseMockAddress(2, "Erc20VotesMock"),
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
        lawInitData[8] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(4, "SelfSelect"),
            config: abi.encode(
                1 // roleId to be elected
            ),
            conditions: conditions,
            description: "Self select as community member."
        });
        delete conditions;

        // This law allows members to nominate themselves for an allocator role. 
        conditions.allowedRole = 1; // member role
        lawInitData[9] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(), // empty config
            conditions: conditions,
            description: "Nominate yourself for an allocator role."
        });
        delete conditions;

        // This law allows delegates to assign or revoke an allocator role to a nominated account. 
        conditions.allowedRole = 2; // delegate role
        conditions.votingPeriod = 60; // 60 blocks, about 5 minutes
        conditions.quorum = 66; // 66% quorum: 66% of delegates need to vote to assign an allocator role to a nominated account. 
        conditions.succeedAt = 66; // 66% majority  
        
        lawInitData[10] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(1, "DirectSelect"),
            config: abi.encode(4), // allocator role
            conditions: conditions,
            description: "Assign an allocator role to a nominated account."
        });
        delete conditions;

        // This law allows the admin to assign or revoke a judge role to a nominated account. 
        conditions.allowedRole = 0;
        lawInitData[11] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(1, "DirectSelect"),
            config: abi.encode(3), // judge role
            conditions: conditions,
            description: "Assign a judge role to a nominated account."
        });
        delete conditions;

        // this law allowd the amdin to set role labels. If will self destruct.
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(powers_, 11);
        conditions.allowedRole = 0;
        lawInitData[12] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions,
            description: "Assigns roles and labels."
        });
        delete conditions;

        return lawInitData;
    }

    function _getActions(address payable powers_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // call to set initial roles
        targets = new address[](5);
        values = new uint256[](5);
        calldatas = new bytes[](5);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = powers_;
        }

        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Member");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegate");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Judge");
        calldatas[3]= abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Allocator");
        // possibly add: subscribers. 
        // revoke law after use
        if (lawId != 0) {
            calldatas[4] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        }

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
} 

