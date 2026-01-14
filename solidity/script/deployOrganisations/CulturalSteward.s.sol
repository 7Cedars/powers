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

// helpers
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { PowersFactory } from "@src/helpers/PowersFactory.sol";

/// @title Cultural Stewards DAO - Deployment Script
/// Note: all days are turned into minutes for testing purposes. These should be changed before production deployment: ctrl-f minutesToBlocks -> daysToBlocks.  
contract CulturalStewardsDAO is DeploySetup {
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

    PowersFactory ideasDaoFactory;
    PowersFactory physicalDaoFactory;

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

        // Create constitutions 
        constitutionLength = createParentConstitution();
        console2.log("Parent Constitution, length:", constitutionLength);

        constitutionLength = createDigitalConstitution();
        console2.log("Digital Constitution, length:", constitutionLength);

        constitutionLength = createIdeasConstitution();
        console2.log("Ideas Constitution, length:", constitutionLength);

        constitutionLength = createPhysicalConstitution();
        console2.log("Digital Constitution, length:", constitutionLength);

        // Deploy vanilla DAOs (parent and digital) and DAO factories (for ideas and physical).  
        vm.startBroadcast();
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

        ideasDaoFactory = new PowersFactory(
            ideasConstitution, // mandate init data
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        ); 

        physicalDaoFactory = new PowersFactory(
            physicalConstitution, // mandate init data
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        ); 
        vm.stopBroadcast();

        console2.log("Parent DAO deployed at:", address(parentDAO));
        console2.log("Digital DAO deployed at:", address(digitalDAO));
        console2.log("Ideas DAO factory deployed at:", address(ideasDaoFactory));
        console2.log("Physical DAO factory deployed at:", address(physicalDaoFactory));

        // step 3: run constitute on vanilla. 
        vm.startBroadcast();
        parentDAO.constitute(parentConstitution);
        digitalDAO.constitute(digitalConstitution);
        vm.stopBroadcast();

        // step 4: transfer ownership of factories to parent DAO.
        vm.startBroadcast();
        ideasDaoFactory.transferOwnership(address(parentDAO));
        physicalDaoFactory.transferOwnership(address(parentDAO));
        vm.stopBroadcast();

        console2.log("Success! All contracts succefully deployed and configured.");
    }

    function createParentConstitution() internal returns (uint256 constitutionLength) {
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels // 
        targets = new address[](6);
        values = new uint256[](6);
        calldatas = new bytes[](6);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(parentDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Executives");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Physical DAOs");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Ideas DAOs");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Digital DAOs");
        calldatas[5] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.

        conditions.allowedRole = 0; // = admin.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        // CREATE AND REVOKE IDEAS DAO // 
        inputParams = new string[](2);
        inputParams[0] = "string name";
        inputParams[1] = "string uri";

        // Members: Initiate Ideas DAO creation
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 10; // = 10% quorum
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Ideas DAO: Initiate creation of Ideas DAO",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;



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

        return parentConstitution.length;

    }

    function createDigitalConstitution() internal returns (uint256 constitutionLength) {
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](4);
        values = new uint256[](4);
        calldatas = new bytes[](4);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.

        conditions.allowedRole = 0; // = admin.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

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

        return digitalConstitution.length;

    }

    function createIdeasConstitution() internal returns (uint256 constitutionLength) {
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](4);
        values = new uint256[](4);
        calldatas = new bytes[](4); 
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.

        conditions.allowedRole = 0; // = admin.
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;
        
        return ideasConstitution.length;
    }

    function createPhysicalConstitution() internal returns (uint256 constitutionLength) {
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](4);
        values = new uint256[](4);
        calldatas = new bytes[](4);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.

        conditions.allowedRole = 0; // = admin.
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;
        
        return physicalConstitution.length;
    }

}
