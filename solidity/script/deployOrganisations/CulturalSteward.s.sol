// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// scripts 
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@script/Configurations.s.sol";
import { InitialisePowers } from "@script/InitialisePowers.s.sol";
import { DeploySetup } from "./DeploySetup.s.sol";

// external protocols 
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

// powers contracts
import { PowersTypes } from "@src/interfaces/PowersTypes.sol";
import { Powers } from "@src/Powers.sol";
import { IPowers } from "@src/interfaces/IPowers.sol";

// mocks
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";

/// @title Power Labs Deployment Script
contract PowerLabs is DeploySetup {
    InitialisePowers initialisePowers;
    Configurations helperConfig;
    Configurations.NetworkConfig public config; 

    PowersTypes.Conditions conditions;
    PowersTypes.MandateInitData[] parentConstitution;
    PowersTypes.MandateInitData[] digitalConstitution;
    PowersTypes.MandateInitData[] ideasConstitution;
    PowersTypes.MandateInitData[] physicalConstitution;
    Powers parentDAO;
    Powers digitalDAO;
    Powers ideasDAO;
    Powers physicalDAO;

    uint256 constitutionLength;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string[] inputParams;
    string[] dynamicParams;
    uint16 mandateCount;

    function run() external {
        // step 0, setup.
        initialisePowers = new InitialisePowers(); 
        initialisePowers.run();
        helperConfig = new Configurations(); 
        config = helperConfig.getConfig();

        constitutionLength = createIdeasConstitution();
        console2.log("Ideas Constitution created with length:");
        console2.logUint(constitutionLength); 

        constitutionLength = createPhysicalConstitution();
        console2.log("Digital Constitution created with length:");
        console2.logUint(constitutionLength);
        
        vm.startBroadcast();
        // step 1: deploy Helper contracts if any.
        // a: deploy factory ideas DAO - todo 
        
        // DO DEPLOY HERE. 
        // b: deploy factory physical DAO - todo 

        // step 2: deploy Powers
        parentDAO = new Powers(
            "Parent DAO", // name
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibnvjwah2wdgd3fhak3sedriwt5xemjlacmrabt6mrht7f24m5w3i", // uri
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        );

        digitalDAO = new Powers(
            "Digital DAO", // name
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreichqvnlmfgkw2jeqgerae2torhgbcgdomxzqxiymx77yhflpnniii", // uri
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        );
        vm.stopBroadcast();

        console2.log("Parent DAO deployed at:", address(parentDAO));
        console2.log("Digital DAO deployed at:", address(digitalDAO));
        // console2.log("Ideas DAO deployed at:", address(ideasDAO));
        // console2.log("Physical DAO deployed at:", address(physicalDAO));

        // step 2: create constitution 
        constitutionLength = createParentConstitution();
        console2.log("Parent Constitution created with length:");
        console2.logUint(constitutionLength);

        // Mandate 17 in Parent is "Adopt a Child Mandate"
        constitutionLength = createDigitalConstitution();
        console2.log("Digital Constitution created with length:");
        console2.logUint(constitutionLength);

        // step 3: run constitute. 
        vm.startBroadcast();
        parentDAO.constitute(parentConstitution);
        digitalDAO.constitute(digitalConstitution);
        vm.stopBroadcast();
        console2.log("Parent and Child Powers successfully constituted.");
    }

    function createParentConstitution() internal returns (uint256 constitutionLength) {

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////

        // Create and revoke Ideas DAO // 


        // Create and revoke Physical DAO //


        // Assign additional allowances to Physical DAO or Digital DAO //


        // Set allowed tokens // 


        // Update uri // 


        // Mint NFTs Ideas DAO - ERC 1155 //


        /// Mint NFTs Physical DAO - ERC 1155 // 

        ////////////////////////////////////////////////////////////////////// 
        //                      ELECTORAL MANDATES                          // 
        //////////////////////////////////////////////////////////////////////

        // Claim membership Parent DAO // 

        // Elect Executives // 


        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////

        // Adopt mandate // 


        // Revoke mandate // 


    }

    function createDigitalConstitution() internal returns (uint256 constitutionLength) {

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        
        // Payment of receipts // 


        // Payment of projects // 


        // Update uri // 

        // Transfer tokens to parent DAO // 
 

        ////////////////////////////////////////////////////////////////////// 
        //                      ELECTORAL MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        
        // Assign membership // 

        // Elect Conveners // 


        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////
        
        // Adopt mandate // 


        // Revoke mandate // 


    }

    function createIdeasConstitution() internal returns (uint256 constitutionLength) {

        // to do ( copy - paste from Digital and modify )
        
         
    }

    function createPhysicalConstitution() internal returns (uint256 constitutionLength) {

        // to do ( copy - paste from Digital and modify )
         
    }

}
