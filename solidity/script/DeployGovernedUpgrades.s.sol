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

// mocks
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";

contract DeployGovernedUpgrades is Script {
    string[] names;
    address[] lawAddresses;

    function run() external returns (address payable dao_, address payable mock20votes_) {
        // Deploy the DAO and a mock erc20 votes contract
        vm.startBroadcast();
        Powers powers = new Powers(
            "Governed Upgrades",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiebpc5ynyisal3ee426jgpib2vawejibzfgmopjxtmucranjy26py"
        );
        Erc20VotesMock erc20VotesMock = new Erc20VotesMock();
        vm.stopBroadcast();

        dao_ = payable(address(powers));
        mock20votes_ = payable(address(erc20VotesMock));

        // Deploy the laws
        DeployLaws deployLaws = new DeployLaws();
        (names, lawAddresses) = deployLaws.run();

        // Create the constitution
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(dao_, mock20votes_);

        // constitute dao
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (dao_, mock20votes_);
    }

    function createConstitution(
        address payable dao_,
        address payable mock20votes_
    ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](9);

        //////////////////////////////////////////////////////
        //               Executive Laws                     // 
        //////////////////////////////////////////////////////

        // Law to adopt a law
        // Only previous DAO (role 1) can use this law
        string[] memory inputParamsAdopt = new string[](1);
        inputParamsAdopt[0] = "newLaw address";

        conditions.allowedRole = 1; // previous DAO role
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[0] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParamsAdopt),
            conditions: conditions,
            description: "A law to adopt new laws in the DAO."
        });
        delete conditions;

        // Law to revoke a law
        string[] memory inputParamsRevoke = new string[](1);
        inputParamsRevoke[0] = "lawId uint16";

        // Only previous DAO (role 1) can use this law
        conditions.allowedRole = 1; // previous DAO role
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParamsRevoke),
            conditions: conditions,
            description: "A law to revoke existing laws in the DAO."
        });
        delete conditions;

        // Law to veto adopting a law
        // Only delegates (role 2) can use this law
        conditions.allowedRole = 2; // delegate role
        conditions.needCompleted = 0; // law 0 needs to have passed
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParamsAdopt),
            conditions: conditions,
            description: "A law to veto the adoption of new laws."
        });
        delete conditions;

        // Law to veto revoking a law
        // Only delegates (role 2) can use this law
        conditions.allowedRole = 2; // delegate role
        conditions.needCompleted = 1; // law 1 needs to have passed
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(inputParamsRevoke),
            conditions: conditions,
            description: "A law to veto the revocation of existing laws."
        });
        delete conditions;

        // Preset law for token exchange
        // Only delegates (role 2) can use this law
        address[] memory exchangeTargets = new address[](1);
        uint256[] memory exchangeValues = new uint256[](1);
        bytes[] memory exchangeCalldatas = new bytes[](1);
        // Mock exchange call - replace with actual Uniswap call
        exchangeTargets[0] = address(0x123); // Mock Uniswap router
        exchangeCalldatas[0] = abi.encode("swapExactTokensForTokens");

        conditions.allowedRole = 2; // delegate role
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(exchangeTargets, exchangeValues, exchangeCalldatas),
            conditions: conditions,
            description: "A preset law to exchange tokens on Uniswap."
        });
        delete conditions;

        // Preset law to veto token exchange
        // Only previous DAO (role 1) can use this law
        conditions.allowedRole = 1; // previous DAO role
        conditions.needCompleted = 4; // law 4 needs to have passed
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(8, "ProposalOnly"),
            config: abi.encode(exchangeTargets, exchangeValues, exchangeCalldatas),
            conditions: conditions,
            description: "A law to veto token exchange operations."
        });
        delete conditions;

        //////////////////////////////////////////////////////
        //                 Electoral Laws                   // 
        //////////////////////////////////////////////////////

        // Law to nominate oneself for delegate role
        // No role restrictions, anyone can use this law
        conditions.allowedRole = type(uint32).max; // no role restriction
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(10, "NominateMe"),
            config: abi.encode(),
            conditions: conditions,
            description: "A law to nominate oneself for the delegate role."
        });
        delete conditions;

        // Law to assign delegate role through voting
        // Only delegates (role 2) can use this law
        conditions.allowedRole = 2; // delegate role
        conditions.votingPeriod = 1000; // 1000 blocks
        conditions.quorum = 30; // 30% quorum
        conditions.succeedAt = 51; // 51% majority
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(0, "DelegateSelect"),
            config: abi.encode(
                mock20votes_,
                10, // max delegate holders
                2 // delegate role ID
            ),
            conditions: conditions,
            description: "A law to assign delegate roles through voting."
        });
        delete conditions;

        // Preset law to assign previous DAO role
        // Only admin (role 0) can use this law
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_, 8);
        conditions.allowedRole = 0; // admin role
        lawInitData[8] = PowersTypes.LawInitData({
            targetLaw: parseLawAddress(7, "PresetAction"),
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions,
            description: "A preset law to assign the previous DAO role."
        });

        return lawInitData;
    }

    function _getRoles(address payable dao_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses
        address previousDAO = makeAddr("previousDAO");

        // call to set initial roles
        targets = new address[](2);
        values = new uint256[](2);
        calldatas = new bytes[](2);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }

        calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, previousDAO);
        // revoke law after use
        if (lawId != 0) {
            calldatas[1] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
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

