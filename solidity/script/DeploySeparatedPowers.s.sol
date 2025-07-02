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

/// @title Deploy script Separated Powers 
/// @notice Separated Powers is an example of a DAO. It acts as an example of separaing powers between roles in a DAO. 
/// 
/// @dev this example has not been fully implemented. 
/// 
/// In this example: 
/// - 'Users' have the power to propose an action, 
/// - 'holders' the power to execute a (previously proposed) action 
/// - and 'developers' the power to veto an action. 

/// - Accounts can self select for a 'user' role if they paid more that 100 gwei in tax during the last 1000 blocks
/// - Accounts can self select for a 'holder' position if they hold more than 1*10^18 in tokens. 
/// - The 'developer' role is assigned and revoked by developers themselves. 
/// - Note: there is no mechanism to avoid double roles for one account. This can be added in the future.  

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

contract DeploySeparatedPowers is Script {
    HelperConfig helperConfig = new HelperConfig();
    string[] names;
    address[] lawAddresses;
    string[] mockNames;
    address[] mockAddresses;
    uint256 blocksPerHour;
    function run() external returns (address payable powers_) {
        blocksPerHour = helperConfig.getConfig().blocksPerHour;
        // Deploy the DAO and the taxed ERC20 token
        vm.startBroadcast();
        Powers powers = new Powers(
            "Separated Powers",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreidvtdjbajp5u6miavuiw3utuqburheqrjgin4orpg6leb27po2hzu"
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
        lawInitData = new PowersTypes.LawInitData[](10);

        //////////////////////////////////////////////////////
        //               Executive Laws                     // 
        //////////////////////////////////////////////////////

        // This law allows users to propose actions
        // Only users can use this law
        string[] memory inputParams = new string[](3);
        inputParams[0] = "address[] Targets";
        inputParams[1] = "uint256[] Values";
        inputParams[2] = "bytes[] Calldatas";

        conditions.allowedRole = 1; // user role
        conditions.votingPeriod = minutesToBlocks(5);
        conditions.quorum = 10; // 10% quorum
        conditions.succeedAt = 50; // 50% majority
        conditions.delayExecution = minutesToBlocks(5);  
        conditions.throttleExecution = minutesToBlocks(4); // can only be executed once every twenty blocks 
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Propose new actions: Propose a new action to the DAO that can later be executed by holders.",
            targetLaw: parseLawAddress(8, "StatementOfIntent"),
            config: abi.encode(inputParams), // the input params are the targets, values, and calldatas
            conditions: conditions
        });
        delete conditions;

        // This law allows developers to veto proposed actions
        // Only developers can use this law
        conditions.allowedRole = 3; // developer role
        conditions.needCompleted = 1; // law 1 needs to have passed. 
        conditions.votingPeriod = minutesToBlocks(5);
        conditions.quorum = 10; // 10% quorum
        conditions.succeedAt = 50; // 50% majority
        conditions.delayExecution = minutesToBlocks(4); //
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Veto an action: Veto an action that was proposed by users.",
            targetLaw: parseLawAddress(8, "StatementOfIntent"),
            config: abi.encode(inputParams), // the same input params as the proposal law
            conditions: conditions
        });
        delete conditions;

        // This law allows subscribers to veto proposed actions
        // Only subscribers can use this law
        conditions.allowedRole = 4; // subscriber role
        conditions.needCompleted = 1; // law 2 needs to have passed. 
        conditions.votingPeriod = minutesToBlocks(5);
        conditions.quorum = 20; // 20% quorum
        conditions.succeedAt = 66; // 66% majority 
        conditions.delayExecution = minutesToBlocks(6);  
        lawInitData[3] = PowersTypes.LawInitData({
            nameDescription: "Ok an action: Ok an action that was proposed by users.",
            targetLaw: parseLawAddress(8, "StatementOfIntent"),
            config: abi.encode(inputParams), // the same input params as the proposal law
            conditions: conditions
        });
        delete conditions;

        // This law allows holders to execute previously proposed actions
        // Only holders can use this law
        conditions.allowedRole = 2; // holder role
        conditions.needCompleted = 3; // law 3 needs to have passed. 
        conditions.needNotCompleted = 2; // law 2 needs to have not passed. 
        conditions.votingPeriod = minutesToBlocks(5);
        conditions.quorum = 80; // 80% quorum
        conditions.succeedAt = 50; // 50% majority
        lawInitData[4] = PowersTypes.LawInitData({
            nameDescription: "Execute action: Execute an action that was proposed by users and that has not been vetoed by developers.",
            targetLaw: parseLawAddress(6, "OpenAction"),
            config: abi.encode(inputParams), // the same input params as the proposal law
            conditions: conditions
        });
        delete conditions;

        //////////////////////////////////////////////////////
        //                 Electoral Laws                   // 
        //////////////////////////////////////////////////////

        // Law for users to self-select based on tax payments
        // No role restrictions, anyone can use this law
        conditions.allowedRole = type(uint256).max; // no role restriction
        lawInitData[5] = PowersTypes.LawInitData({
            nameDescription: "Assign user role: Assign user role. The account will need to pay at least a 100 MockTaxed tokens in tax.",
            targetLaw: parseLawAddress(13, "TaxSelect"),
            config: abi.encode(parseMockAddress(3, "Erc20TaxedMock"), 25, 1), // 25 gwei tax threshold, role 1 (user)
            conditions: conditions
        });
        delete conditions;

        // Law for holders to self-select based on token holdings
        // No role restrictions, anyone can use this law
        conditions.allowedRole = type(uint256).max; // no role restriction
        lawInitData[6] = PowersTypes.LawInitData({
            nameDescription: "Assign holder role: Assign an account to the holder role. The account has to hold at least 1e18 MockTaxed tokens.",
            targetLaw: parseLawAddress(14, "HolderSelect"),
            config: abi.encode(parseMockAddress(3, "Erc20TaxedMock"), 1e18, 2), // 1e18 token threshold, role 2 (holder)
            conditions: conditions
        });
        delete conditions;

        // Law for subscribers to self-select based on subscription payments
        // No role restrictions, anyone can use this law
        conditions.allowedRole = type(uint256).max; // no role restriction
        lawInitData[7] = PowersTypes.LawInitData({
            nameDescription: "Assign subscriber role: Assign an account as subscriber. The account will need to pay 1000 gwei in Eth to Powers.",
            targetLaw: parseLawAddress(21, "Subscription"),
            config: abi.encode(300, 1000, 4), // 1000 subscription amount, role 4 (subscriber), 300 epoch duration = 1 hour 
            conditions: conditions
        });
        delete conditions;

        // Here add a law that is base don subscription. 
        // to do. 

        // Law for developers to manage their own role
        // Only developers can use this law
        conditions.allowedRole = 3; // developer role
        conditions.votingPeriod = minutesToBlocks(5);
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 50% vote majority
        lawInitData[8] = PowersTypes.LawInitData({
            nameDescription: "Assign developer role: Assign an account to the developer role. Developers decide to assign an account to the developer role.",
            targetLaw: parseLawAddress(1, "DirectSelect"),
            config: abi.encode(3), // role 3 (developer)
            conditions: conditions
        });
        delete conditions;

        // PresetAction for roles
        // This law sets up initial role assignments for the DAO
        // Only role 0 can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(powers_, 9);
        conditions.allowedRole = 0;
        lawInitData[9] = PowersTypes.LawInitData({
            nameDescription: "Assign initial roles and labels: This law can only be used once. It self-destructs after use.",
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
        // create addresses
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // call to set initial roles
        targets = new address[](6);
        values = new uint256[](6);
        calldatas = new bytes[](6);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = powers_;
        }

        address DEV2_ADDRESS = vm.envAddress("DEV2_ADDRESS");
        calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, DEV2_ADDRESS);
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Users");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Holders");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Developers");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Subscribers");
        // possibly add: subscribers. 
        // revoke law after use
        if (lawId != 0) {
            calldatas[5] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
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

    function minutesToBlocks(uint256 min) public view returns (uint32 blocks) {
        blocks = uint32(min * blocksPerHour / 60);
    }
}










