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

/// @title Deploy script Governed Upgrades
/// @notice Governed Upgrades is a simple example of a DAO. It acts as an introductory example of governed upgrades using the Powers protocol. 
/// 
/// This example implements:
/// Executive laws: 
/// - A law to adopt a law. Access role = previous DAO 
/// - A law to revoke a law. Access role = previous DAO 
/// - A law to veto adopting a law. Access role = delegates
/// - A law to veto revoking a law. Access role = delegates
/// - A preset law to Exchange tokens at uniswap or sth similar chain. Access role = delegates
/// - A preset law to to veto Exchange tokens at uniswap or sth similar chain veto. Access role = previous DAO.

/// Electoral laws: (possible roles: previous DAO, delegates)
/// - a law to nominate oneself for a delegate role. Access role: public.
/// - a law to assign a delegate role to a nominated account. Access role: delegate, using delegate election vote. Simple majority vote.
/// - a preset self destruct law to assign role to previous DAO. Access role = admin. 

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

// mocks
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";

contract DeployGovernedUpgrades is Script {
    string[] names;
    address[] lawAddresses;
    string[] mockNames;
    address[] mockAddresses;

    function run() external returns (address payable powers_) {
        vm.startBroadcast();
        Powers powers = new Powers(
            "Governed Upgrades",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiebpc5ynyisal3ee426jgpib2vawejibzfgmopjxtmucranjy26py"
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
        string[] memory inputParamsAdopt = new string[](11);

        inputParamsAdopt[0] = "address Law";
        inputParamsAdopt[1] = "uint256 AllowedRole";

        inputParamsAdopt[2] = "uint32 VotingPeriod";
        inputParamsAdopt[3] = "uint8 Quorum";
        inputParamsAdopt[4] = "uint8 SucceedAt";
        
        inputParamsAdopt[5] = "uint16 NeedCompleted";
        inputParamsAdopt[6] = "uint16 NeedNotCompleted";
        inputParamsAdopt[7] = "uint16 ReadStateFrom";
        inputParamsAdopt[8] = "uint48 DelayExecution";
        inputParamsAdopt[9] = "uint48 ThrottleExecution";
        inputParamsAdopt[10] = "bytes Config";
        inputParamsAdopt[11] = "string Description";

        // Law to veto adopting a law
        conditions.allowedRole = 1; // delegate role
        conditions.votingPeriod = 60; // about 5 minutes
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParamsAdopt),
            conditions: conditions,
            description: "Veto adoption of law: Veto the adoption of a new law."
        });
        delete conditions;

        // Law to veto revoking a law
        // Only delegates (role 2) can use this law
        conditions.allowedRole = 1; // delegate role
        conditions.votingPeriod = 60; // about 5 minutes
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode("uint16 LawId"),
            conditions: conditions,
            description: "Veto revocation of law: Veto the revocation of an existing law."
        });
        delete conditions;

        // Law to adopt a law
        // Only previous DAO (role 1) can use this law
        bytes memory configAdopt = abi.encode(powers_, IPowers.adoptLaw.selector, inputParamsAdopt);
        conditions.allowedRole = 0; // previous DAO role
        conditions.needNotCompleted = 1; // law 1 should NOT have passed
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(18, "AdoptLaw"),
            config: abi.encode(""),
            conditions: conditions,
            description: "Adopt a new law: Adopt a new law into Powers."
        });
        delete conditions;

        // Law to revoke a law
        // Only previous DAO (role 1) can use this law
        bytes memory configRevoke = abi.encode(powers_, IPowers.revokeLaw.selector, "uint16 LawId");
        conditions.allowedRole = 0; // previous DAO role
        conditions.needNotCompleted = 2; // law 2 should NOT have passed
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(5, "BespokeAction"),
            config: configRevoke,
            conditions: conditions,
            description: "Revoke a law: Revoke a law in Powers."
        });
        delete conditions;

        // Preset law for token exchange
        // Only delegates (role 2) can use this law
        bytes[] memory configMint = abi.encodeWithSelector(
            parseMockAddress(2, "Erc20VotesMock"), 
            Erc20VotesMock.mintVotes.selector, 
            "uint256 amount"
            );

        // Preset law to veto token exchange
        // Only previous DAO (role 1) can use this law
        conditions.allowedRole = 0; // previous DAO role
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: configMint,
            conditions: conditions,
            description: "Veto token mint: veto minting of tokens to a delegate."
        });
        delete conditions;

        conditions.allowedRole = 1; // delegate role
        conditions.votingPeriod = 60; // about 5 minutes
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        conditions.needNotCompleted = 5; // law 5 needs to have passed
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(5, "BespokeAction"),
            config: configMint,
            conditions: conditions,
            description: "Mint Tokens: Mint tokens to a delegate address. Note that the address is the executioner of the law."
        });
        delete conditions;

        //////////////////////////////////////////////////////
        //                 Electoral Laws                   // 
        //////////////////////////////////////////////////////
        // Law to nominate oneself for delegate role
        // No role restrictions, anyone can use this law
        conditions.allowedRole = type(uint32).max; // no role restriction
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(),
            conditions: conditions,
            description: "Nominate oneself for a delegate role."
        });
        delete conditions;

        // Law to assign delegate role through voting 
        conditions.allowedRole = type(uint32).max; // no role restriction
        conditions.votingPeriod = 60; // about 5 minutes
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[8] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(0, "DelegateSelect"),
            config: abi.encode(
                parseMockAddress(2, "Erc20VotesMock"),
                10, // max delegate holders
                2 // delegate role ID
            ),
            conditions: conditions,
            description: "Call delegate election (and pay for it)."
        });
        delete conditions;

        // Preset law to assign previous DAO role
        // Only admin (role 0) can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(powers_, 9);
        conditions.allowedRole = 0; // admin role
        lawInitData[9] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions,
            description: "Assign previous DAO role and label roles."
        });

        return lawInitData;
    }

    //////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                        // 
    //////////////////////////////////////////////////////////////
    function _getActions(address payable powers_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // call to set initial roles
        targets = new address[](5);
        values = new uint256[](5);
        calldatas = new bytes[](5);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = powers_;
        }

        calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, 0, parseMockAddress(1, "GovernorMock")); // assign previous DAO role as admin
        calldatas[1] = abi.encodeWithSelector(IPowers.revokeRole.selector, 0, msg.sender); // revoke admin role of address that created the protocol. 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "DAO admin");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Previous DAO");

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

