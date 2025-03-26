// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { IPowers } from "../../src/interfaces/IPowers.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";

import { Erc1155Mock } from "./Erc1155Mock.sol";
import { DaoMock } from "./DaoMock.sol";
import { BaseSetup } from "../TestSetup.t.sol";
import { LawUtilities } from "../../src/LawUtilities.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract ConstitutionsMock is Test {
    //////////////////////////////////////////////////////////////
    //                  FIRST CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    function initiatePowersConstitution(
        bytes[] memory creationCodes, 
        address payable dao_, 
        address payable mock20Votes_
        ) external returns (
            PowersTypes.LawInitData[] memory lawInitData)
        {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](7);

        // dummy call.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        // directSelect
        conditions.allowedRole = type(uint32).max;
        lawInitData[0] = PowersTypes.LawInitData({
            // = directSelect
            targetLaw: calculateLawAddress(
                creationCodes[1],
                "DirectSelect" // to ensure we are using the correct law, we do not retrieve the name from DeployLaws.s.sol.
            ), 
            config: abi.encode(1), // role that can be assigned.
            conditions: conditions, 
            description: "A law to select an account to a specific role directly."
        });
        delete conditions;

        // nominateMe
        conditions.allowedRole = type(uint32).max;
        lawInitData[1] = PowersTypes.LawInitData({
            // = nominateMe
            targetLaw: calculateLawAddress(
                creationCodes[10], 
                "NominateMe" // to ensure we are using the correct law, we do not retrieve the name from DeployLaws.s.sol.
            ), 
            config: abi.encode(), // empty config. 
            conditions: conditions,
            description: "A law for accounts to nominate themselves for a role."
        });
        delete conditions;

        // delegateSelect
        conditions.allowedRole = 1;
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: calculateLawAddress(
                creationCodes[0], 
                "DelegateSelect" // to ensure we are using the correct law, we do not retrieve the name from DeployLaws.s.sol.
            ), 
            config: abi.encode(
                mock20Votes_,
                15, // max role holders
                2 // roleId to be elected
            ), // role that can call the law.
            conditions: conditions,
            description: "A law to select a role by delegated votes."
        });
        delete conditions;

        // proposalOnly
        string[] memory inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = 3;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: calculateLawAddress(
                creationCodes[8], 
                "ProposalOnly" // to ensure we are using the correct law, we do not retrieve the name from DeployLaws.s.sol.
            ), 
            config: abi.encode(inputParams), 
            conditions: conditions,
            description: "A law to propose a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented."
        });
        delete conditions; 

        // OpenAction
        conditions.allowedRole = 2;
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: calculateLawAddress(
                creationCodes[6], 
                "OpenAction" // to ensure we are using the correct law, we do not retrieve the name from DeployLaws.s.sol.
            ), 
            config: abi.encode(), // empty config.
            conditions: conditions,
            description: "A law to execute an open action."
        });
        delete conditions;

        // PresetAction
        conditions.allowedRole = 1;
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needCompleted = 3;
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: calculateLawAddress(
                creationCodes[7], 
                "PresetAction" // to ensure we are using the correct law, we do not retrieve the name from DeployLaws.s.sol.
            ), 
            config: abi.encode(
                targets,
                values,
                calldatas
            ), // empty config.
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;

        // PresetAction
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_, 7);
        conditions.allowedRole = 0;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: calculateLawAddress(
                creationCodes[7], 
                "PresetAction" // to ensure we are using the correct law, we do not retrieve the name from DeployLaws.s.sol.
            ), 
            config: abi.encode(
                targetsRoles,
                valuesRoles,
                calldatasRoles
            ), // empty config.
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions; 
    }

    //////////////////////////////////////////////////////////////
    //                  SECOND CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateBasicDaoConstitution(
        bytes[] memory creationCodes
    )
        external
        returns (PowersTypes.LawInitData[] memory lawInitData)
    {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](1);

        // OpenAction
        conditions.allowedRole = 0;
        lawInitData[0] = PowersTypes.LawInitData({
            targetLaw: calculateLawAddress(
                creationCodes[6], 
                "OpenAction" // to ensure we are using the correct law, we do not retrieve the name from DeployLaws.s.sol.
            ), 
            config: abi.encode(), // empty config.
            conditions: conditions,
            description: "The admin has the power to execute any internal or external action."
        });
        delete conditions;
    }

// //     //////////////////////////////////////////////////////////////
// //     //                  THIRD CONSTITUTION                     //
// //     //////////////////////////////////////////////////////////////
// //     function initiateLawTestConstitution(
// //         address payable dao_, 
// //         address payable mock1155_
// //     )
// //         external
// //         returns (address[] memory laws)
// //     {
// //         Law law;
// //         laws = new address[](6);

// //         // dummy call: mint coins at mock1155 contract.
// //         address[] memory targets = new address[](1);
// //         uint256[] memory values = new uint256[](1);
// //         bytes[] memory calldatas = new bytes[](1);
// //         targets[0] = mock1155_;
// //         values[0] = 0;
// //         calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

// //         // setting up config file
// //          LawUtilities.Conditions memory Conditions;
// //         Conditions.quorum = 20; // = 30% quorum needed
// //         Conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
// //         Conditions.votingPeriod = 1200; // = number of blocks
// //         // initiating law.
// //         law = new PresetAction(
// //             "Needs Proposal Vote", // max 31 chars
// //             "Needs Proposal Vote to pass",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             targets,
// //             values,
// //             calldatas
// //         );
// //         laws[0] = address(law);

// //         // setting up config file
// //         delete Conditions;
// //         Conditions.needCompleted = laws[0];
// //         // initiating law.
// //         law = new PresetAction(
// //             "Needs Parent Completed", // max 31 chars
// //             "Needs Parent Completed to pass",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             targets,
// //             values,
// //             calldatas
// //         );
// //         laws[1] = address(law);

// //         // setting up config file
// //         delete Conditions;
// //         Conditions.needNotCompleted = laws[0];
// //         // initiating law.
// //         law = new PresetAction(
// //             "Parent Can Block", // max 31 chars
// //             "Parent can block a law, making it impossible to pass",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             targets,
// //             values,
// //             calldatas
// //         );
// //         laws[2] = address(law);

// //         // setting up config file
// //         delete Conditions;
// //         Conditions.quorum = 30; // = 30% quorum needed
// //         Conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
// //         Conditions.votingPeriod = 1200; // = number of blocks
// //         Conditions.delayExecution = 5000;
// //         // initiating law.
// //         law = new PresetAction(
// //             "Delay Execution", // max 31 chars
// //             "Delay execution of a law, by a preset number of blocks . ",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             targets,
// //             values,
// //             calldatas
// //         );
// //         laws[3] = address(law);

// //         // setting up config file
// //         delete Conditions;
// //         Conditions.throttleExecution = 10;
// //         // initiating law.
// //         law = new PresetAction(
// //             "Throttle Executions", // max 31 chars
// //             "Throttle the number of executions of a by setting minimum time that should have passed since last execution.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             targets,
// //             values,
// //             calldatas
// //         );
// //         laws[4] = address(law);

// //         // get calldata
// //         (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
// //         // set config
// //         // setting the throttle to max means the law can only be called once.
// //         Conditions.throttleExecution = type(uint48).max - uint48(block.number);
// //         // initiate law
// //         vm.startBroadcast();
// //         law = new PresetAction(
// //             "Admin assigns initial roles",
// //             "The admin assigns initial roles. This law can only be used once.",
// //             dao_, // separated powers
// //             0, // access role = ADMIN
// //             Conditions,
// //             targetsRoles,
// //             valuesRoles,
// //             calldatasRoles
// //         );
// //         vm.stopBroadcast();
// //         laws[5] = address(law);
// //         delete Conditions;
// //     }

// //     //////////////////////////////////////////////////////////////
// //     //            CONSTITUTION: Electoral Laws                  //
// //     //////////////////////////////////////////////////////////////
// //     function initiateElectoralTestConstitution(
// //         address payable dao_,
// //         address payable mock1155_,
// //         address payable mock20Votes_
// //     ) external returns (address[] memory laws) {
// //         Law law;
// //         laws = new address[](10);
// //          LawUtilities.Conditions memory Conditions;

// //         // dummy params
// //         string[] memory inputParams = new string[](0);

// //         law = new NominateMe(
// //             "Nominate for any role", // max 31 chars
// //             "This is a placeholder nomination law.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         );
// //         laws[0] = address(law);

// //         law = new NominateMe(
// //             "Nominate for any role", // max 31 chars
// //             "This is a placeholder nomination law.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         );
// //         laws[1] = address(law);

// //         // electoral laws //
// //         law = new DirectSelect(
// //             "Direct select role", // max 31 chars
// //             "Directly select a role.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             3
// //         );
// //         laws[2] = address(law);

// //         // // Note: all laws from here on keep the same conditions. 
// //         // Conditions.readStateFrom = laws[0];
// //         // law = new RandomlySelect(
// //         //     "Randomly select role", // max 31 chars
// //         //     "Randomly select a role.",
// //         //     dao_,
// //         //     1, // access role
// //         //     Conditions, // empty config file.
// //         //     // bespoke configs for this law:
// //         //     3, // max role holders
// //         //     3 // role id.
// //         // );
// //         // laws[3] = address(law);
        
// //         Conditions.readStateFrom = laws[0];
// //         law = new DelegateSelect(
// //             "Delegate Select", // max 31 chars
// //             "Select a role by delegated votes.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             mock20Votes_,
// //             3, // max role holders
// //             3 // role id.
// //         );
// //         laws[3] = address(law);
// //         delete Conditions;

// //         Conditions.readStateFrom = laws[0]; // NominateMe.
// //         law = new ElectionCall(
// //             "Create Election", // max 31 chars
// //             "Create an election for role 3.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             2, // voter role id 
// //             3, // elected role id
// //             2 // max elected role holders
// //         );
// //         laws[4] = address(law);
// //         delete Conditions;

// //         Conditions.needCompleted = laws[4]; // electionCall
// //         law = new ElectionTally(
// //             "Tally an election", // max 31 chars
// //             "Count votes of an election called through the call election law and assign roles.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         );
// //         laws[5] = address(law);
// //         delete Conditions;

// //         law = new SelfSelect(
// //             "Self select role", // max 31 chars
// //             "Self select a role.",
// //             dao_,
// //             type(uint32).max, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             6 // role id.
// //         );
// //         laws[6] = address(law);
// //         delete Conditions;

// //         uint32[] memory allowedRoleIds = new uint32[](1);
// //         allowedRoleIds[0] = 3;
// //         law = new RenounceRole(
// //             "Renounce role", // max 31 chars
// //             "Renounce a role.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             allowedRoleIds
// //         );
// //         laws[7] = address(law);
// //         delete Conditions;

// //         Conditions.readStateFrom = laws[0];
// //         law = new PeerSelect(
// //             "Peer select role", // max 31 chars
// //             "Peer select a role.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             2, // max role holders
// //             6 // role id.
// //         );
// //         laws[8] = address(law);
// //         delete Conditions;

// //         // get calldata
// //         (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
// //         // set config
// //         delete Conditions; // reset Conditions
// //         // config
// //         // setting the throttle to max means the law can only be called once.
// //         Conditions.throttleExecution = type(uint48).max - uint48(block.number);
// //         // initiate law
// //         vm.startBroadcast();
// //         law = new PresetAction(
// //             "Admin assigns initial roles",
// //             "The admin assigns initial roles. This law can only be used once.",
// //             dao_, // separated powers
// //             0, // access role = ADMIN
// //             Conditions,
// //             targetsRoles,
// //             valuesRoles,
// //             calldatasRoles
// //         );
// //         vm.stopBroadcast();
// //         laws[9] = address(law);
// //         delete Conditions; // reset Conditions
// //     }

// //     //////////////////////////////////////////////////////////////
// //     //            CONSTITUTION: Executive Laws                  //
// //     //////////////////////////////////////////////////////////////
// //     function initiateExecutiveTestConstitution(
// //         address payable dao_,
// //         address payable mock1155_,
// //         address payable /*mock20Votes_*/
// //     ) external returns (address[] memory laws) {
// //         Law law;
// //         laws = new address[](7);
// //          LawUtilities.Conditions memory Conditions;

// //         // dummy call: mint coins at mock1155 contract.
// //         address[] memory targets = new address[](1);
// //         uint256[] memory values = new uint256[](1);
// //         bytes[] memory calldatas = new bytes[](1);
// //         targets[0] = mock1155_;
// //         values[0] = 0;
// //         calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

// //         // dummy params
// //         string[] memory inputParams = new string[](0);

// //         // setting up config file
// //         Conditions.quorum = 30; // = 30% quorum needed
// //         Conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
// //         Conditions.votingPeriod = 1200; // = number of blocks
// //         // initiating law.
// //         law = new ProposalOnly(
// //             "Proposal Only With Vote", // max 31 chars
// //             "Proposal Only With Vote to pass.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             params
// //         );
// //         laws[0] = address(law);
// //         delete Conditions; // reset Conditions.

// //         law = new OpenAction(
// //             "Open Action", // max 31 chars
// //             "Execute an action, any action.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         );
// //         laws[1] = address(law);

// //         // need to setup a memory array of bytes4 for setting bespoke params
// //         string[] memory bespokeParams = new string[](1);
// //         bespokeParams[0] = "uint256";
// //         law = new BespokeAction(
// //             "Bespoke Action", // max 31 chars
// //             "Execute any action, but confined by a contract and function selector.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             mock1155_, // target contract that can be called.
// //             Erc1155Mock.mintCoins.selector, // the function selector that can be called.
// //             bespokeParams
// //         );
// //         laws[2] = address(law);

// //         law = new ProposalOnly(
// //             "Proposal Only", // max 31 chars
// //             "Proposal Only without vote or other checks.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             params
// //         );
// //         laws[3] = address(law);
// //         delete Conditions; // reset Conditions

// //         // config
// //         // get calldata
// //         (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
// //         // setting the throttle to max means the law can only be called once.
// //         Conditions.throttleExecution = type(uint48).max - uint48(block.number);
// //         // initiate law
// //         vm.startBroadcast();
// //         law = new PresetAction(
// //             "Admin assigns initial roles",
// //             "The admin assigns initial roles. This law can only be used once.",
// //             dao_, // separated powers
// //             0, // access role = ADMIN
// //             Conditions,
// //             targetsRoles,
// //             valuesRoles,
// //             calldatasRoles
// //         );
// //         vm.stopBroadcast();
// //         laws[4] = address(law);
// //         delete Conditions; // reset Conditions

// //         law = new SelfDestructAction(
// //             "Admin assigns initial roles",
// //             "The admin assigns initial roles. This law will self destruct when used.",
// //             dao_, // separated powers
// //             0, // access role = ADMIN
// //             Conditions,
// //             targetsRoles,
// //             valuesRoles,
// //             calldatasRoles
// //         );
// //         laws[5] = address(law);
// //         delete Conditions; // reset Conditions

// //         law = new SelfDestructAction(
// //             "Admin assigns initial roles",
// //             "The admin assigns initial roles. This law will self destruct when used.",
// //             dao_, // separated powers
// //             0, // access role = ADMIN
// //             Conditions,
// //             targetsRoles,
// //             valuesRoles,
// //             calldatasRoles
// //         );
// //         laws[6] = address(law);
// //         delete Conditions; // reset Conditions
// //     }

// //     //////////////////////////////////////////////////////////////
// //     //                CONSTITUTION: STATE LAWS                  //
// //     //////////////////////////////////////////////////////////////
// //     function initiateStateTestConstitution(
// //         address payable dao_,
// //         address payable /*mock1155_*/,
// //         address payable /*mock20Votes_*/
// //     ) external returns (address[] memory laws) {
// //         Law law;
// //         laws = new address[](6);
// //          LawUtilities.Conditions memory Conditions;

// //         // dummy params
// //         string[] memory inputParams = new string[](0);
// //         // initiating law.
// //         law = new AddressesMapping(
// //             "Free Address Mapping", // max 31 chars
// //             "Free address mapping without additional checks.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         );
// //         laws[0] = address(law);

// //         law = new StringsArray(
// //             "Free String Array", // max 31 chars
// //             "Save strings in an array. No additional checks.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         );
// //         laws[1] = address(law);

// //         law = new TokensArray(
// //             "Free token Array", // max 31 chars
// //             "Save tokens in an array. No additional checks.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         );
// //         laws[2] = address(law);

// //         law = new NominateMe(
// //             "Nominate for any role", // max 31 chars
// //             "This is a placeholder nomination law.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         );
// //         laws[3] = address(law);

// //         Conditions.readStateFrom = laws[3]; // nominate me
// //         law = new ElectionVotes(
// //             "Collect votes for an election", // max 31 chars
// //             "This is a placeholder election law.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             50, // start vote in block number
// //             75 // end vote in block number.
// //         );
// //         laws[4] = address(law);
// //         delete Conditions; 

// //         (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
// //         Conditions.throttleExecution = type(uint48).max - uint48(block.number);
// //         law = new PresetAction(
// //             "Admin assigns initial roles",
// //             "The admin assigns initial roles. This law can only be used once.",
// //             dao_, // separated powers
// //             0, // access role = ADMIN
// //             Conditions,
// //             targetsRoles,
// //             valuesRoles,
// //             calldatasRoles
// //         );
// //         laws[5] = address(law);
// //         delete Conditions; // reset Conditions
// //     }

// //     //////////////////////////////////////////////////////////////
// //     //        SIXTH CONSTITUTION: test AlignedGrants            //
// //     //////////////////////////////////////////////////////////////
// //     function initiateAlignedDaoTestConstitution(
// //         address payable dao_,
// //         address payable mock20Votes_,
// //         address payable mock20Taxed_,
// //         address payable mock721_
// //     ) external returns (address[] memory laws) {
// //         Law law;
// //         laws = new address[](4);
// //          LawUtilities.Conditions memory Conditions;

// //         // initiating law.
// //         law = new NftSelfSelect(
// //             "Claim role", // max 31 chars
// //             "Claim role 1, conditional on owning an NFT. See asset page for address of ERC721 contract.",
// //             dao_,
// //             type(uint32).max, // access role = public.
// //             Conditions, // empty config file.
// //             1,
// //             mock721_
// //         );
// //         laws[0] = address(law);

// //         law = new RevokeMembership(
// //             "Membership can be revoked", // max 31 chars
// //             "Anyone can revoke membership for role 1. This law is unrestricted for this test.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             mock721_
// //         );
// //         laws[1] = address(law);

// //         law = new ReinstateRole(
// //             "Reinstate role 1.", // max 31 chars
// //             "Roles can be reinstated and NFTs returned. Note that this laws usually should be conditional on a needCompleted[RevokeMembership]",
// //             dao_,
// //             1, // access role
// //             Conditions,
// //             mock721_
// //         );
// //         laws[2] = address(law);
// //         delete Conditions;

// //         law = new RequestPayment(
// //             "Request preset payment", // max 31 chars
// //             "Every 100 blocks, role 1 holders can request payment of 5000 ERC20 tokens.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             mock20Taxed_,
// //             0, // tokenId
// //             5000, // amount
// //             100 // delay
// //         );
// //         laws[3] = address(law);
// //     }

// //     //////////////////////////////////////////////////////////////
// //     //      SEVENTH CONSTITUTION: test Diversified Grants       //
// //     //////////////////////////////////////////////////////////////
// //     function initiateGovernYourTaxTestConstitution(
// //         address payable dao_,
// //         address payable mock20Votes_,
// //         address payable mock20Taxed_,
// //         address payable mock1155_
// //     ) external returns (address[] memory laws) {
// //         Law law;
// //         laws = new address[](7);
// //          LawUtilities.Conditions memory Conditions;

// //         // grant input params.
// //         string[] memory inputParams = new string[](3);
// //         inputParams[0] = "address"; // grantee address
// //         inputParams[1] = "address"; // grant address = address(this). This is needed to make abuse of proposals across contracts impossible.
// //         inputParams[2] = "uint256"; // quantity to transfer
// //         // deploy law
// //         law = new ProposalOnly(
// //             "Proposals for grant requests", // max 31 chars
// //             "Here anyone can make a proposal for a grant request.",
// //             dao_,
// //             1, // access role
// //             Conditions, // empty config file.
// //             // bespoke configs for this law:
// //             inputParams
// //         );
// //         laws[0] = address(law);

// //         // initiating law.
// //         law = new Grant(
// //             "Open Erc20 Grant", // max 31 chars
// //             "A test grant that anyone can apply to until it is empty or it expires.",
// //             dao_,
// //             type(uint32).max, // access role = public.
// //             Conditions, // empty config file. 
// //             // grant config
// //             2700, // duration
// //             5000, // budget
// //             mock20Votes_, // contract
// //             laws[0] // address from where proposals are made.
// //         );
// //         laws[1] = address(law);

        
// //         law = new StartGrant(
// //             "Start a grant", // max 31 chars
// //             "Start a grant with a bespoke role restriction, token, budget and duration.",
// //             dao_,
// //             2, // access role
// //             Conditions, // empty config file.
// //             // start grant config
// //             laws[0] // proposals that need to be completed before grant can be considered.
// //         );
// //         laws[2] = address(law);
        
// //         Conditions.needCompleted = laws[2]; // needs the exact grant to have been completed. 
// //         law = new StopGrant(
// //             "Stop a grant", // max 31 chars
// //             "Delete Grant that has either expired or has spent its budget.",
// //             dao_,
// //             2, // access role
// //             Conditions
// //         );
// //         laws[3] = address(law);
// //         delete Conditions; 

// //         law = new RoleByTaxPaid(
// //             "(De)select role by tax paid", // max 31 chars
// //             "(De)select an account for role 3 on the basis of tax paid.",
// //             dao_,
// //             2, // access role
// //             Conditions,
// //             3, // role Id to be assigned
// //             mock20Taxed_,
// //             100 // threshold tax paid per epoch.
// //         );
// //         laws[4] = address(law);

// //         law = new NominateMe(
// //             "Nominate for any role", // max 31 chars
// //             "This is a placeholder nomination law.",
// //             dao_,
// //             1, // access role
// //             Conditions // empty config file.
// //         ); 
// //         laws[5] = address(law);

// //         Conditions.readStateFrom = laws[5]; // nominate me
// //         uint32[] memory allowedRoles = new uint32[](3);
// //         allowedRoles[0] = 4; // council A
// //         allowedRoles[1] = 5; // council B
// //         allowedRoles[2] = 6; // council C 
// //         law = new AssignCouncilRole(
// //             "Assign a council role", // max 31 chars
// //             "Assign accounts to grant council A (role 4), B (role 5) or C (role 6).",
// //             dao_,
// //             2, // access role
// //             Conditions,
// //             allowedRoles
// //         );
// //         laws[6] = address(law);
// //         delete Conditions;
// //     }

// //     //////////////////////////////////////////////////////////////
// //     //      EIGHT CONSTITUTION: test Diversified Roles          //
// //     //////////////////////////////////////////////////////////////
// //     // £todo

//////////////////////////////////////////////////////////////
//                  INTERNAL HELPER FUNCTION                //
//////////////////////////////////////////////////////////////
    function _getRoles(address payable dao_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses.
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");
        address gary = makeAddr("gary");
        address helen = makeAddr("helen");

        // call to set initial roles. Also used as dummy call data.
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
        if (lawId != 0) {
            calldatas[12] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        }

        return (targets, values, calldatas);
    }

    function calculateLawAddress(bytes memory creationCode, string memory name) public returns (address computedAddress) {
        bytes32 salt = bytes32(abi.encodePacked(name));
        address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains.
        
        computedAddress = Create2.computeAddress(
            salt, 
            keccak256(abi.encodePacked(creationCode, abi.encode(name))),
            create2Factory // create2 factory address. NEED TO INCLUDE THIS! 
            );
        if (computedAddress.code.length == 0) {
            revert ("Law does not exist. Did you make a typo or does the law really not exist?");
        }
        return computedAddress;
    }
}
