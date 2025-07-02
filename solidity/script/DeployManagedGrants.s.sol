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
import { Erc20TaxedMock } from "../test/mocks/Erc20TaxedMock.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployManagedGrants is Script {
    HelperConfig helperConfig = new HelperConfig();
    string[] names;
    address[] lawAddresses;
    string[] mockNames;
    address[] mockAddresses;
    uint256 blocksPerHour;

    function run() external returns (address payable powers_) {
        blocksPerHour = helperConfig.getConfig().blocksPerHour;
        // Deploy the DAO 
        vm.startBroadcast();
        Powers powers = new Powers(
            "Managed Grants",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiduudrmyjwrv3krxl2kg6dfuofyag7u2d22beyu5os5kcitghtjbm"
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
            nameDescription: "Request a grant: Community members can request a grant from a grant program.",
            targetLaw: parseLawAddress(8, "StatementOfIntent"),
            config: abi.encode(inputParams), 
            conditions: conditions
        });
        delete conditions;

        // This law allows judges to veto the deployment of a new grant program. 
        // Access role = judges.
        conditions.allowedRole = 3; // judge role
        conditions.votingPeriod = minutesToBlocks(5); // 5 minutes
        conditions.quorum = 66; // 66% quorum: 66% of judges need to vote for a new grant program to be deployed. 
        conditions.succeedAt = 66; // 66% majority
        
        inputParams = new string[](4);
        inputParams[0] = "uint48 Duration";
        inputParams[1] = "uint256 Budget";
        inputParams[2] = "address Address";
        inputParams[3] = "string Description";
 
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Veto grant program: Judges can veto the deployment of a new grant program.",
            targetLaw: parseLawAddress(8, "StatementOfIntent"),
            config: abi.encode(inputParams), 
            conditions: conditions
        });
        delete conditions;

        // This law allows allocators to start a grant program. 
        // Access role = allocators.
        // NB: these are the conditions for grant programs that will be deployed.
        grantConditions.allowedRole = 4; // allocator role
        grantConditions.needCompleted = 1; // A member needs to have passed a grant request proposal. 
        grantConditions.quorum = 33; // 33% quorum need to ok a grant request. 
        grantConditions.votingPeriod = minutesToBlocks(5); // 5 minutes
        grantConditions.succeedAt = 51; // simple 51% majority 

        // NB: these are the conditions for the deploy grants law.  
        conditions.allowedRole = 2; // governor role
        conditions.votingPeriod = minutesToBlocks(5); // 5 minutes
        conditions.quorum = 66; // 66% quorum: 66% of governors need to vote for a new grant program to be deployed. 
        conditions.succeedAt = 66; // 66% majority
        conditions.delayExecution = minutesToBlocks(3); // 10 minutes
        conditions.needNotCompleted = 2; // judges should not have vetoed the grant program. 

        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "Deploy grant program: Governors can deploy a new grant program, as long as it has not been vetoed by judges.",
            targetLaw: parseLawAddress(16, "StartGrant"),
            config: abi.encode(parseLawAddress(15, "Grant"), abi.encode(grantConditions)),
            conditions: conditions
        });
        delete conditions;
        delete grantConditions;

        // This law allows governors to stop a grant program. -- but only if the grant has spent nearly all its tokens or expired. 
        conditions.allowedRole = 2; // governor role
        conditions.votingPeriod = minutesToBlocks(5); // 5 minutes
        conditions.quorum = 66; // 66% quorum: 66% of governors need to vote for a new grant program to be deployed. 
        conditions.succeedAt = 66; // 66% majority
        conditions.needCompleted = 3; // a governor needs to have started a grant program. 

        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "End grant program: Governors can stop a grant program when it has spent nearly all its tokens and it has expired.",
            targetLaw: parseLawAddress(17, "EndGrant"),
            config: abi.encode(
                10, // the maximum amount of tokens left in the grant before it can be stopped. 
                true // if true, the grant can only be stopped after it deadline has passed.  
                ),
            conditions: conditions
        });
        delete conditions;

        // Judges can stop a grant program at any time. 
        conditions.allowedRole = 3; // judge role
        conditions.votingPeriod = minutesToBlocks(5); // 5 minutes
        conditions.quorum = 75; // 66% quorum: 66% of judges need to vote to stop a grant program. 
        conditions.needCompleted = 3; // a governor needs to have started a grant program. 
        conditions.succeedAt = 51; // 66% majority 
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "End grant program: Judges can stop a grant program at any time.",
            targetLaw: parseLawAddress(17, "EndGrant"),
            config: abi.encode(
                0, // no checks. 
                false // no deadline. 
            ), 
            conditions: conditions
        });
        delete conditions;

        // //////////////////////////////////////////////////////
        // //                 Electoral Laws                   // 
        // //////////////////////////////////////////////////////
        // This law allows accounts to self-nominate for any role
        // It can be used by community members to self select for a governor role. 
        conditions.allowedRole = 1; 
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "Nominate for governor: Community members can use this law to nominate themselves for a governor role.",
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // This law enables role selection through delegated voting using an ERC20 token
        // Only role 0 (admin) can use this law
        conditions.allowedRole = 5;
        conditions.readStateFrom = 6;
        lawInitData[7] = PowersTypes.LawInitData({
            nameDescription: "Elect governors: Only the DAO admin can use this law to elect governors.",
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
        conditions.allowedRole = type(uint256).max;
        lawInitData[8] = PowersTypes.LawInitData({
            nameDescription: "Self select: Anyone can self select for a member role.",
            targetLaw: parseLawAddress(4, "SelfSelect"),
            config: abi.encode(
                1 // roleId to be elected
            ),
            conditions: conditions
        });
        delete conditions;

        // This law allows members to nominate themselves for an allocator role. 
        conditions.allowedRole = 1; // member role
        lawInitData[9] = PowersTypes.LawInitData({
            nameDescription: "Nominate for allocator: Community members can use this law to nominate themselves for an allocator role.",
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(), // empty config
            conditions: conditions
        });
        delete conditions;

        // This law allows governors to assign or revoke an allocator role to a nominated account. 
        conditions.allowedRole = 2; // governor role
        conditions.votingPeriod = minutesToBlocks(5); // 5 minutes
        conditions.quorum = 66; // 66% quorum: 66% of governors need to vote to assign an allocator role to a nominated account. 
        conditions.succeedAt = 66; // 66% majority  
        
        lawInitData[10] = PowersTypes.LawInitData({
            nameDescription: "Assign allocator role: Governors can assign or revoke an allocator role to a nominated account.",
            targetLaw: parseLawAddress(1, "DirectSelect"),
            config: abi.encode(4), // allocator role
            conditions: conditions
        });
        delete conditions;

        // This law allows the admin to assign or revoke a judge role to a nominated account. 
        conditions.allowedRole = 5;
        lawInitData[11] = PowersTypes.LawInitData({
            nameDescription: "Assign judge role: The DAO admin can assign or revoke a judge role to any account.",
            targetLaw: parseLawAddress(1, "DirectSelect"),
            config: abi.encode(3), // judge role
            conditions: conditions
        });
        delete conditions;

        // this law allowd the amdin to set role labels. If will self destruct.
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(powers_, 12);
        conditions.allowedRole = 0;
        lawInitData[12] = PowersTypes.LawInitData({
            nameDescription: "Initial setup: Assign labels and mint tokens. This law can only be executed once.",
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions
        });
        delete conditions;
    }

    function _getActions(address payable powers_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // call to set initial roles
        targets = new address[](9);
        values = new uint256[](9);
        calldatas = new bytes[](9);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = powers_;
        }

        address DEV2_ADDRESS = vm.envAddress("DEV2_ADDRESS");
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Governors");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Judges");
        calldatas[3]= abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Allocators");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Legacy DAO");
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 5, parseMockAddress(1, "GovernorMock")); // assign previous DAO role as admin
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 5, DEV2_ADDRESS); // assign Governor role
        targets[7] = parseMockAddress(3, "Erc20TaxedMock");
        calldatas[7] = abi.encodeWithSelector(Erc20TaxedMock.faucet.selector);
        calldatas[8] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);

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

