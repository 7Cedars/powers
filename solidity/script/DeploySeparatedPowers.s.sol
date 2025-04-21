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
import { console2 } from "forge-std/console2.sol";

// core protocol
import { Powers } from "../src/Powers.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { DeployLaws } from "./DeployLaws.s.sol";

// mocks
import { Erc20TaxedMock } from "../test/mocks/Erc20TaxedMock.sol";

contract DeploySeparatedPowers is Script {
    string[] names;
    address[] lawAddresses;

    function run() external returns (address payable dao_, address payable taxedToken_) {
        // Deploy the DAO and the taxed ERC20 token
        vm.startBroadcast();
        Powers powers = new Powers(
            "Separated Powers",
            // TODO: this is still a placeholder: it is the data for Powers 101
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiebpc5ynyisal3ee426jgpib2vawejibzfgmopjxtmucranjy26py"
        );
        
        // Deploy taxed token with 10% tax rate, denominator of 100, and epoch duration of 1000 blocks
        Erc20TaxedMock taxedToken = new Erc20TaxedMock(10, 100, 1000);
        vm.stopBroadcast();

        dao_ = payable(address(powers));
        taxedToken_ = payable(address(taxedToken));

        // Deploy the laws
        DeployLaws deployLaws = new DeployLaws();
        (names, lawAddresses) = deployLaws.run();

        // Create the constitution
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(taxedToken_, dao_);

        // constitute dao
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (dao_, taxedToken_);
    }

    function createConstitution(
        address payable taxedToken_,
        address payable dao_
    ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](7);

        //////////////////////////////////////////////////////
        //               Executive Laws                     // 
        //////////////////////////////////////////////////////

        // This law allows users to propose actions
        // Only users can use this law
        string[] memory inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = 1; // user role
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 10; // 10% quorum
        conditions.succeedAt = 50; // 50% majority
        conditions.delayExecution = 500; // 2500 block delay
        lawInitData[0] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParams), // the input params are the targets, values, and calldatas
            conditions: conditions,
            description: "A law to propose new actions to the DAO."
        });
        delete conditions;

        // This law allows developers to veto proposed actions
        // Only developers can use this law
        conditions.allowedRole = 3; // developer role
        conditions.needCompleted = 0; // law 0 needs to have passed. 
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 10; // 10% quorum
        conditions.succeedAt = 50; // 50% majority
        conditions.delayExecution = 500; // no delay
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParams), // the same input params as the proposal law
            conditions: conditions,
            description: "A law to veto actions."
        });
        delete conditions;

        // This law allows holders to execute previously proposed actions
        // Only holders can use this law
        conditions.allowedRole = 2; // holder role
        conditions.needCompleted = 0; // law 0 needs to have passed. 
        conditions.needNotCompleted = 1; // law 1 needs to have not passed. 
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 80; // 80% quorum
        conditions.succeedAt = 50; // 50% majority
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(6, "OpenAction"),
            config: abi.encode(inputParams), // the same input params as the proposal law
            conditions: conditions,
            description: "A law to execute previously proposed actions."
        });
        delete conditions;

        //////////////////////////////////////////////////////
        //                 Electoral Laws                   // 
        //////////////////////////////////////////////////////

        // Law for users to self-select based on tax payments
        // No role restrictions, anyone can use this law
        conditions.allowedRole = type(uint32).max; // no role restriction
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(13, "TaxSelect"),
            config: abi.encode(taxedToken_, 100, 1), // 100 gwei tax threshold, role 1 (user)
            conditions: conditions,
            description: "A law to allow accounts to self-select as users based on tax payments."
        });
        delete conditions;

        // Law for holders to self-select based on token holdings
        // No role restrictions, anyone can use this law
        conditions.allowedRole = type(uint32).max; // no role restriction
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(14, "HolderSelect"),
            config: abi.encode(taxedToken_, 1e18, 2), // 1e18 token threshold, role 2 (holder)
            conditions: conditions,
            description: "A law to allow accounts to self-select as holders based on token holdings."
        });
        delete conditions;

        // Here add a law that is base don subscription. 
        // to do. 

        // Law for developers to manage their own role
        // Only developers can use this law
        conditions.allowedRole = 3; // developer role
        conditions.votingPeriod = 1200; // 1200 blocks
        conditions.quorum = 10; // 10% quorum
        conditions.succeedAt = 50; // 50% majority
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(1, "DirectSelect"),
            config: abi.encode(3), // role 3 (developer)
            conditions: conditions,
            description: "A law to allow developers to manage their own role assignments."
        });

        // PresetAction for roles
        // This law sets up initial role assignments for the DAO
        // Only role 0 can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_, 7);
        conditions.allowedRole = 0;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;

        return lawInitData;
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










