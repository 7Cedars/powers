// // SPDX-License-Identifier: MIT

// ///////////////////////////////////////////////////////////////////////////////
// /// This program is free software: you can redistribute it and/or modify    ///
// /// it under the terms of the MIT Public License.                           ///
// ///                                                                         ///
// /// This is a Proof Of Concept and is not intended for production use.      ///
// /// Tests are incomplete and it contracts have not been audited.            ///
// ///                                                                         ///
// /// It is distributed in the hope that it will be useful and insightful,    ///
// /// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
// /// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
// ///////////////////////////////////////////////////////////////////////////////

// /// @title Example deploy script for the Powers protocol. 
// /// @author 7Cedars

// pragma solidity 0.8.26;

// // forge imports
// import { Script } from "forge-std/Script.sol";
// import { console2 } from "forge-std/console2.sol";

// // core protocol
// import { Powers} from "../src/Powers.sol";
// import { IPowers } from "../src/interfaces/IPowers.sol";
// import { ILaw } from "../src/interfaces/ILaw.sol";
// import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

// /// @notice Example implementation of the Powers protocol.
// /// Note: all addresses are hardcoded. In practice this is not recommended and should be done dynamically.
// /// NB: All hardcoded addresses are deployed on Optimism Sepolia. This example will only work on that network!  
// /// Note: Additional notes with explanation throughout. 

// contract DeployPowers is Script {
//     function run() external returns (Powers memory powers) {
//         // Step 0: Deploy the Powers contract.
//         vm.startBroadcast();
//         Powers powers = new Powers(
//             "My First Powers", // name of the DAO
//             "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreicwiqgcvzqub6xv7ha37ohgkc3vprvh6ihqtgs7bk235apaadnqha" // IPFS link to metadata. See for an example the 'metadata folder' in this directory. 
//         );
//         vm.stopBroadcast();
        
//         // Note: at this stage the Powers contract does not have any laws. As such, it can not do anything. 
//         // We need to call the 'constitute' function to implement a constitutions. 
//         // But before we do that, we need to create the constitution of our Powers implementation.  

//         // A constitution is an array of LawInitData, that will be used as input for the constitute function. 
//         PowersTypes.LawInitData[] memory lawInitData = createConstitution(payable(address(powers))); // see the function below on how this constitution is created. 

//         // Here we call the constitute function, which will adopt the laws. 
//         vm.startBroadcast();
//         powers.constitute(lawInitData);
//         vm.stopBroadcast();

//         // And that's it! 
//         // We have deployed the Powers contract and the laws. 
//         // We can now use these laws to manage our Powers deployment. 
//         return (powers);
//     }


//     //////////////////////////////////////////////////////////////////
//     //                      CREATE CONSTITUTION                     // 
//     //////////////////////////////////////////////////////////////////
//     // The following is an example constitution for the Powers protocol. 
//     // It creates an array of LawInitData, that will be used as input for the constitute function of our Powers implementation. 
//     function createConstitution(
//         address payable powers_
//     ) public returns (PowersTypes.LawInitData[] memory lawInitData) {

//         //////////////////////////////////////////////////////////////////
//         //                          Setup                               // 
//         //////////////////////////////////////////////////////////////////
//         address[] memory deployedLaws = new address[](8);
//         address[] memory deployedMocks = new address[](4);

//         // Deployed 
//         deployedLaws[0] = "0x0000000000000000000000000000000000000000"; 
//         /// Here have to fill out most recent law addresses. (note, )


//         ILaw.Conditions memory conditions;
//         lawInitData = new PowersTypes.LawInitData[](8);
        
//         //////////////////////////////////////////////////////////////////
//         //                       Electoral laws                         // 
//         //////////////////////////////////////////////////////////////////
//         // This law allows accounts to self-nominate for any role
//         // It can be used by community members
//         conditions.allowedRole = 1; 
//         lawInitData[1] = PowersTypes.LawInitData({
//             nameDescription: "Nominate me for delegate: Nominate yourself for a delegate role. You need to be a community member to use this law.",
//             targetLaw: parseLawAddress(10, "NominateMe"),
//             config: abi.encode(), // empty config
//             conditions: conditions
//         });
//         delete conditions;

//         // This law enables role selection through delegated voting using an ERC20 token
//         // Only role 0 (admin) can use this law
//         conditions.allowedRole = 0;
//         conditions.readStateFrom = 1;
//         lawInitData[2] = PowersTypes.LawInitData({
//             nameDescription: "Elect delegates: Elect delegates using delegated votes. You need to be an admin to use this law.",
//             targetLaw: parseLawAddress(0, "DelegateSelect"),
//             config: abi.encode(
//                 parseMockAddress(2, "Erc20VotesMock"),
//                 15, // max role holders
//                 2 // roleId to be elected
//             ),
//             conditions: conditions
//         });
//         delete conditions;

//         // This law enables anyone to select themselves as a community member. 
//         // Any one can use this law
//         conditions.throttleExecution = 25; // this law can be called once every 25 blocks. 
//         conditions.allowedRole = type(uint256).max;
//         lawInitData[3] = PowersTypes.LawInitData({
//             nameDescription: "Self select as community member: Self select as a community member. Anyone can call this law.",
//             targetLaw: parseLawAddress(4, "SelfSelect"),
//             config: abi.encode(
//                 1 // roleId to be elected
//             ),
//             conditions: conditions
//         });
//         delete conditions;

//         //////////////////////////////////////////////////////////////////
//         //                       Executive laws                         // 
//         //////////////////////////////////////////////////////////////////

//         // This law allows proposing changes to core values of the DAO
//         // Only community members can use this law. It is subject to a vote. 
//         string[] memory inputParams = new string[](3);
//         inputParams[0] = "address[] Targets";
//         inputParams[1] = "uint256[] Values";
//         inputParams[2] = "bytes[] Calldatas";

//         conditions.allowedRole = 1;
//         conditions.votingPeriod = minutesToBlocks(5); // = number of blocks = about 5 minutes. 
//         conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members
//         conditions.quorum = 20; // = 20% quorum needed
//         lawInitData[4] = PowersTypes.LawInitData({
//             nameDescription: "Propose an action: Propose an action that can later be executed by Delegates.",
//             targetLaw: parseLawAddress(8, "ProposalOnly"),
//             config: abi.encode(inputParams),
//             conditions: conditions
//         });
//         delete conditions;

//         // This law allows a proposed action to be vetoed. 
//         // Only the admin can use this law // not subhject to a vote, but the proposal needs to have passed by the community members. 
//         conditions.allowedRole = 0;
//         conditions.needCompleted = 4;
//         lawInitData[5] = PowersTypes.LawInitData({
//             nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
//             targetLaw: parseLawAddress(8, "ProposalOnly"),
//             config: abi.encode(inputParams),
//             conditions: conditions
//         });
//         delete conditions;

//         // This law allows executing any action with voting requirements
//         // Only role 2 can use this law
//         // Requires 20% quorum and 51% majority to pass
//         conditions.allowedRole = 2;
//         conditions.quorum = 50; // = 50% quorum needed
//         conditions.succeedAt = 77; // = 77% simple majority needed for executing an action
//         conditions.votingPeriod = minutesToBlocks(5); // = number of blocks = about 5 minutes. 
//         conditions.needCompleted = 4;
//         conditions.needNotCompleted = 5;
//         conditions.delayExecution = minutesToBlocks(10); // = 50 blocks = about 10 minutes. This gives admin time to veto the action.  
//         lawInitData[6] = PowersTypes.LawInitData({
//             nameDescription: "Execute an action: Execute an action that has been proposed by the community.",
//             targetLaw: parseLawAddress(6, "OpenAction"),
//             config: abi.encode(), // empty config, an open action takes address[], uint256[], bytes[] as input.             
//             conditions: conditions
//         });
//         delete conditions;

//         // PresetAction for roles
//         // This law sets up initial role assignments for the DAO & role labelling. It is a law that self destructs when executed. 
//         // Only the admin can use this law
//         (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getActions(powers_, mockAddresses, 7);
//         conditions.allowedRole = 0;
//         lawInitData[7] = PowersTypes.LawInitData({
//             nameDescription: "Initial setup: Assign labels and mint tokens. This law can only be executed once.",
//             targetLaw: parseLawAddress(7, "PresetAction"),
//             config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
//             conditions: conditions
//         });
//         delete conditions;
//     }

//     //////////////////////////////////////////////////////////////
//     //                  HELPER FUNCTIONS                        // 
//     //////////////////////////////////////////////////////////////

//     function _getActions(address payable powers_, address[] memory mocks, uint16 lawId)
//         internal
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
//     {
//         // call to set initial roles
//         // NB! NEW ACTIONS ADDED HERE! 
//         targets = new address[](5);
//         values = new uint256[](5);
//         calldatas = new bytes[](5);

//         targets[0] = powers_;
//         targets[1] = powers_;

//         calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
//         calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Delegates");
        
//         targets[2] =  mocks[2];
//         calldatas[2] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 1000000000000000000);

//         targets[3] = mocks[3];
//         calldatas[3] = abi.encodeWithSelector(Erc20TaxedMock.faucet.selector);

//         targets[4] = powers_;
//         calldatas[4] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        
//         return (targets, values, calldatas);
//     }
    
//     function parseLawAddress(uint256 index, string memory lawName) public view returns (address lawAddress) {
//         if (keccak256(abi.encodePacked(lawName)) != keccak256(abi.encodePacked(names[index]))) {
//             revert("Law name does not match");
//         }
//         return lawAddresses[index];
//     }

//     function parseMockAddress(uint256 index, string memory mockName) public view returns (address mockAddress) {
//         if (keccak256(abi.encodePacked(mockName)) != keccak256(abi.encodePacked(mockNames[index]))) {
//             revert("Mock name does not match");
//         }
//         return mockAddresses[index];
//     }

//     function minutesToBlocks(uint256 min) public view returns (uint32 blocks) {
//         blocks = uint32(min * blocksPerHour / 60);
//     }
// } 
