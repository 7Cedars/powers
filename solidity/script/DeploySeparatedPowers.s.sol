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
/// - No account is allowed to hold more than one role.

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

    function run() external returns (address payable dao, address payable taxedToken_) {
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

        dao = payable(address(powers));
        taxedToken_ = payable(address(taxedToken));

        // Deploy the laws
        DeployLaws deployLaws = new DeployLaws();
        (names, lawAddresses) = deployLaws.run();

        // Create the constitution
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(taxedToken_);

        // constitute dao
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (dao, taxedToken_);
    }

    function createConstitution(
        address payable taxedToken_
    ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](4);

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
        lawInitData[2] = PowersTypes.LawInitData({
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
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(6, "OpenAction"),
            config: abi.encode(inputParams), // the same input params as the proposal law
            conditions: conditions,
            description: "A law to execute previously proposed actions."
        });
        delete conditions;

        //////////////////////////////////////////////////////
        //                 Electoral Laws                   // 
        //////////////////////////////////////////////////////

        // From here on, laws create by AI are nonsense. 
        // A main reason for this is that the necessary laws are not yet created. 
        // See: TaxSelect & HoldersSelect

        // This law handles role selection based on token holdings and tax payments
        // It can be used by any role
        conditions.allowedRole = type(uint32).max; // this is a publically accesible law
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(
                taxedToken_, // token address
                1 * 10**18, // minimum token balance for holder role
                100 gwei, // minimum tax paid for user role
                1000 // blocks to look back for tax payments
            ),
            conditions: conditions,
            description: "A law for accounts to nominate themselves for roles based on token holdings and tax payments."
        });
        delete conditions;




    }

    function parseLawAddress(uint256 index, string memory lawName) public view returns (address lawAddress) {
        if (keccak256(abi.encodePacked(lawName)) != keccak256(abi.encodePacked(names[index]))) {
            revert("Law name does not match");
        }
        return lawAddresses[index];
    }
}










