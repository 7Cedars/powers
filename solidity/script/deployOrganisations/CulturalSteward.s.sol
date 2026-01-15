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
import { SafeProxyFactory } from "lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";
import { ModuleManager } from "lib/safe-smart-account/contracts/base/ModuleManager.sol";

// powers contracts
import { PowersTypes } from "@src/interfaces/PowersTypes.sol";
import { Powers } from "@src/Powers.sol";
import { IPowers } from "@src/interfaces/IPowers.sol";

// helpers
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { Soulbound1155 } from "@src/helpers/Soulbound1155.sol";
import { AllowedTokens } from "@src/helpers/AllowedTokens.sol";
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
    Soulbound1155 soulbound1155;

    uint256 constitutionLength;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string[] inputParams;
    string[] dynamicParams;
    uint16 mandateCount;
    address treasury;

    function run() external {
        // step 0, setup.
        initialisePowers = new InitialisePowers(); 
        initialisePowers.run();
        helperConfig = new Configurations(); 
        config = helperConfig.getConfig(); 
        soulbound1155 = new Soulbound1155("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighx6axdemwbjara3xhhfn5yaiktidgljykzx3vsrqtymicxxtgvi");

        // Create constitutions 
        console2.log("Creating constitutions...");
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
        console2.log("Deploying Powers contracts...");
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
 
        // step 3: setup Safe treasury. 
        address[] memory owners = new address[](1);
        owners[0] = address(parentDAO);

        vm.startBroadcast();
        console2.log("Setting up Safe treasuries for Parent DAO and Digital DAO...");
        treasury = address(
            SafeProxyFactory(config.safeProxyFactory)
                .createProxyWithNonce(
                    config.safeL2Canonical,
                    abi.encodeWithSelector(
                        Safe.setup.selector,
                        owners,
                        1, // threshold
                        address(0), // to
                        "", // data
                        address(0), // fallbackHandler
                        address(0), // paymentToken
                        0, // payment
                        address(0) // paymentReceiver
                    ),
                    1 // = nonce
                )
        );
        vm.stopBroadcast();

        // step 4: run constitute on vanilla DAOs. 
        vm.startBroadcast();
        console2.log("Constituting Parent DAO and Digital DAO...");
        parentDAO.constitute(parentConstitution, msg.sender); // set msg.sender as admin
        digitalDAO.constitute(digitalConstitution, msg.sender); // set msg.sender as admin
        vm.stopBroadcast();

        // step 5: transfer ownership of factories to parent DAO.
        vm.startBroadcast();
        console2.log("Transferring ownership of DAO factories to Parent DAO...");
        ideasDaoFactory.transferOwnership(address(parentDAO));
        physicalDaoFactory.transferOwnership(address(parentDAO)); 
        vm.stopBroadcast();

        console2.log("Success! All contracts succefully deployed and configured.");
    }


    ////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////// 
    //                        PARENT DAO CONSTITUTION                         //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function createParentConstitution() internal returns (uint256 constitutionLength) {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup calls //
        // signature for Safe module enabling call
        bytes memory signature = abi.encodePacked(
            uint256(uint160(address(parentDAO))), // r = address of the signer (powers contract)
            uint256(0), // s = 0
            uint8(1) // v = 1 This is a type 1 call. See Safe.sol for details.
        );

        targets = new address[](9);
        values = new uint256[](9);
        calldatas = new bytes[](9);
        
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(parentDAO); 
        }
        targets[6] = address(treasury); // the Safe treasury address.
        targets[7] = address(treasury); // the Safe treasury address.

        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Executives");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Physical DAOs");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Ideas DAOs");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Digital DAOs");
        calldatas[5] = abi.encodeWithSelector(IPowers.setTreasury.selector, payable(treasury));
        calldatas[6] = abi.encodeWithSelector( // cal to set allowance module to the Safe treasury.
            Safe.execTransaction.selector,
            treasury, // The internal transaction's destination
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
            abi.encodeWithSelector( // the call to be executed by the Safe: enabling the module.
                ModuleManager.enableModule.selector,
                config.safeAllowanceModule
            ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            signature // the signature constructed above
        );
        calldatas[7] = abi.encodeWithSelector( // call to set Digital DAO as delegate to the Safe treasury.
            Safe.execTransaction.selector,
            config.safeAllowanceModule, // The internal transaction's destination: the Allowance Module.
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
            abi.encodePacked(
                bytes4(0xe71bdf41), // == AllowanceModule.addDelegate.selector,  (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                address(digitalDAO)
                ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            signature // the signature constructed above
        );
        calldatas[8] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assigns role labels, sets up the allowance module, the treasury and revokes itself after execution",
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
        // note: no allowance assigned. Ideas DAO do not control assets. 

        // Members: Initiate Ideas DAO creation
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 5; // = 5% quorum. Note: very low quorum to encourage experimentation.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Ideas DAO: Initiate creation of Ideas DAO",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions 
        }));
        delete conditions;

        // Executives: Execute Ideas DAO creation
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create Ideas DAO: Execute Ideas DAO creation",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                ideasDaoFactory, // calling the ideas factory
                PowersFactory.createPowers.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Assign role Id to Ideas DAO // 
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Assign role Id to DAO: Assign role id 4 (Ideas DAO) to the new DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnReturnValue"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.assignRole.selector, // function selector to call
                abi.encode(uint16(4)), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 1, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // Members: Revoke Ideas DAO creation mandate //
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto revoke Ideas DAO: Veto the revoking of an Ideas DAO from Cultural Stewards",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Revoke Role ID //  
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 2; // need the previous mandate to be fulfilled.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke role Id: Revoke role id 4 (Ideas DAO) from the DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnReturnValue"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.revokeRole.selector, // function selector to call
                abi.encode(uint16(4)), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 3, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // CREATE AND REVOKE PHYSICAL DAO //
        inputParams = new string[](3);
        inputParams[0] = "string name";
        inputParams[1] = "string uri";
        // note: an allowance is set when DAO is created. 

        // Members: Initiate Physical DAO creation
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 5; // = 5% quorum. Note: very low quorum to encourage experimentation.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Physical DAO: Initiate creation of Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions 
        }));
        delete conditions;

        // Executives: Execute Physical DAO creation
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create Physical DAO: Execute Physical DAO creation",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                physicalDaoFactory, // calling the Physical factory
                PowersFactory.createPowers.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Assign role Id to Physical DAO //  
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Assign role Id: Assign role Id 3 to Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnReturnValue"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.assignRole.selector, // function selector to call
                abi.encode(uint16(3)), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 1, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions;

        // Executives: delegate status to Physical DAO in Safe //
        // todo 

        // Members: Revoke Physical DAO creation mandate //
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto revoke Physical DAO: Veto the revoking of an Physical DAO from Cultural Stewards",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Revoke Role ID //
        mandateCount++;
        conditions.allowedRole = 2; 
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 10 minutes timelock before execution.
        conditions.needFulfilled = mandateCount - 2; // need the previous mandate to be fulfilled.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke Physical DAO: Revoke role Id 3 from Physical DAO"
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnReturnValue"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.revokeRole.selector, // function selector to call
                abi.encode(uint16(3)), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 4, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // TODO: Executives: Revoke Allowance DAO //  
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 5; // = 5% quorum. Note: very low quorum to encourage experimentation.
        conditions.needNotFulfilled = mandateCount - 1; // need the previous mandate to be NOT fulfilled (veto).
        conditions.needFulfilled = mandateCount - 2; // need the assign role to have been fulfilled. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke Physical DAO: PLACEHOLDER - Revoke delegate status at safe", 
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(inputParams),
            conditions: conditions 
        }));
        delete conditions; 

        // ASSIGN ALLOWANCE TO PHYSICAL DAO OR DIGITAL DAO //
        inputParams = new string[](5);
        inputParams[0] = "address DigitalDAO";
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";

        mandateCount++;
        conditions.allowedRole = 3; // = Members can veto this call.
        conditions.quorum = 66; // = 66% quorum needed
        conditions.succeedAt = 66; // = 66% majority needed for veto.
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = number of blocks
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto allowance: Veto settin an allowance to either Digital DAO or a Physical DAO.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = 3; // = physical DAO. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request additional allowance: Any Physical DAO can request an allowance from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = 2; // = Executives.
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = number of blocks
        conditions.needFulfilled = mandateCount - 1; // = the proposal mandate.
        conditions.needNotFulfilled = mandateCount - 2; // = the veto mandate.
        conditions.timelock = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 10 minutes timelock before execution.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Set Allowance: Execute and set allowance for a Physical DAO.",
            targetMandate: initialisePowers.getMandateAddress("SafeAllowance_Action"),
            config: abi.encode(
                inputParams,
                bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                config.safeAllowanceModule 
            ),
            conditions: conditions // everythign zero == Only admin can call directly
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = 5; // = digital DAO. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request additional allowance: The Digital DAO can request an allowance from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = 2; // = Executives.
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = number of blocks
        conditions.needFulfilled = mandateCount - 1; // = the proposal mandate.
        conditions.needNotFulfilled = mandateCount - 4; // = the veto mandate.
        conditions.timelock = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 10 minutes timelock before execution.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Set Allowance: Execute and set allowance for the Digital DAO.",
            targetMandate: initialisePowers.getMandateAddress("SafeAllowance_Action"),
            config: abi.encode(
                inputParams,
                bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                config.safeAllowanceModule 
            ),
            conditions: conditions // everythign zero == Only admin can call directly
        }));
        delete conditions;

        // UPDATE URI // 
        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // members: veto update URI
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto update URI: Members can veto updating the Parent DAO URI",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // executives: update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needNotFulfilled = mandateCount - 1; // the previous VETO mandate should not have been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Cultural Stewards DAOs",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                address(parentDAO), // calling the allowed tokens contract
                Powers.setUri.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Ideas DAOs: MINT NFTS IDEAS DAO - ERC 1155 //
        inputParams = new string[](1);
        inputParams[0] = "address To";

        mandateCount++;
        conditions.allowedRole = 4; // = Ideas DAOs
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint token Ideas DAO: Any Ideas DAO can mint new NFTs",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                address(soulbound1155), // calling the allowed tokens contract
                Soulbound1155.mint.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Physical DAOs: MINT NFTS PHYSICAL DAO - ERC 1155 // 
        mandateCount++;
        conditions.allowedRole = 3; // = Physical DAOs
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint token Physical DAO: Any Physical DAO can mint new NFTs",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                address(soulbound1155), // calling the allowed tokens contract
                Soulbound1155.mint.selector, // function selector to call
                abi.encode(inputParams) // note: same input params as Ideas DAO
            ),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Excutives. Any executive can call this mandate.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the Parent DAO can be recovered by sending them to the treasury",
            targetMandate: initialisePowers.getMandateAddress("Safe_RecoverTokens"), 
            config: abi.encode(
                treasury, // this should be the safe treasury! 
                config.safeAllowanceModule // allowance module address
            ),
            conditions: conditions
        }));
        delete conditions;


        ////////////////////////////////////////////////////////////////////// 
        //                      ELECTORAL MANDATES                          // 
        //////////////////////////////////////////////////////////////////////

        // CLAIM MEMBERSHIP PARENT DAO // 
        // todo 

        // ELECT EXECUTIVES // 
        // Members: Nominate for Executive role
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for Executives: Members can nominate themselves for the Executive role.",
            targetMandate: initialisePowers.getMandateAddress("Nominate"),
            config: abi.encode(
                address(openElection)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Start an election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Start an election: an election can be initiated be any voter.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionStart"),
            config: abi.encode(
                address(openElection),
                initialisePowers.getMandateAddress("OpenElectionVote"), // Vote mandate address
                minutesToBlocks(10, config.BLOCKS_PER_HOUR), // duration of election 
                1 // Role id that can vote = Members
            ),
            conditions: conditions
        }));
        delete conditions;

        // Mandate 4: End and Tally elections
        mandateCount++;
        conditions.allowedRole = 1; // = Member
        conditions.needFulfilled = mandateCount - 1; // = Start election
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "End and Tally elections: After an election has finished, assign the Executive role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionEnd"),
            config: abi.encode(
                address(openElection),
                2, // RoleId for Executives
                5 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////

        // Adopt mandate // 
        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Any executive: Propose Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Executives 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate mandate adoption: Any executive can propose adopting new mandates into the organization.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Members: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = mandateCount - 1;
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto Adopting Mandates: Members can veto proposals to adopt new mandates",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Physical DAOs: Ok Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 3; // Physical DAO
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 51;
        conditions.quorum = 20;
        conditions.needFulfilled = mandateCount - 2;  
        conditions.needNotFulfilled = mandateCount - 1;  
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Ok adopting Mandates: Ok to adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Ideas DAOs: Ok Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 4; // Ideas DAO
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 51;
        conditions.quorum = 20;
        conditions.needFulfilled = mandateCount - 1;  
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Ok adopting Mandates: Ok to adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Digital DAO: Ok Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 5; // Digital DAO
        conditions.needFulfilled = mandateCount - 1;   
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Ok adopting Mandates: Ok to adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Executives
        conditions.needFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 80;   
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt new Mandates: Executives can adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("AdoptMandates"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return parentConstitution.length;
    }


    ////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////// 
    //                       DIGITAL DAO CONSTITUTION                         //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function createDigitalConstitution() internal returns (uint256 constitutionLength) {
        mandateCount = 0; // resetting mandate count.
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
        
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
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
        
        // PAYMENT OF RECEIPTS //
        string[] memory params = new string[](3);
        params[0] = "address Token";
        params[1] = "uint256 Amount";
        params[2] = "address PayableTo";

        // submitting a receipt for payment reimbursement // -- payment AFTER action
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // This is a public mandate. Anyone can call it.   
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Submit a Receipt: Anyone can submit a receipt for payment reimbursement.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(params),
            conditions: conditions
        }));
        delete conditions;
        
        // ok receipt - avoid spam
        mandateCount++;
        conditions.allowedRole = 2; // any convener can ok a receipt.   
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "OK a receipt: Any convener can ok a receipt for payment reimbursement.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(params),
            conditions: conditions
        }));
        delete conditions;

        // approve payment of receipt //
        mandateCount++;
        conditions.allowedRole = 2; // Conveners 
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 67;
        conditions.quorum = 50;
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Approve payment of receipt: Execute a transaction from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("SafeAllowance_Transfer"),
            config: abi.encode(
                config.safeAllowanceModule,
                address(treasury) 
            ),
            conditions: conditions
        }));
        delete conditions;

        // PAYMENT OF PROJECTS //
        string[] memory params = new string[](3);
        params[0] = "address Token";
        params[1] = "uint256 Amount";
        params[2] = "address PayableTo";

        // submitting a project for payment // (payment BEFORE action)
        mandateCount++;
        conditions.allowedRole = 1; // Members can propose a project.   
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 51;
        conditions.quorum = 5; // note the low quorum to encourage proposals.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Submit a project for Funding: Any member can submit a project for funding.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(params),
            conditions: conditions
        }));
        delete conditions;

        // approve funding of project //
        mandateCount++;
        conditions.allowedRole = 2; // Conveners 
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 67;
        conditions.quorum = 50;
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Approve funding of project: Execute a transaction from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("SafeAllowance_Transfer"),
            config: abi.encode(
                config.safeAllowanceModule,
                address(treasury) 
            ),
            conditions: conditions
        }));
        delete conditions;

        // UPDATE URI // 
        params = new string[](1);
        params[0] = "string newUri";
        
        // conveners: update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum 
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnOwnPowers"), 
            config: abi.encode( 
                Powers.setUri.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners. Any con can call this mandate.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
            targetMandate: initialisePowers.getMandateAddress("Safe_RecoverTokens"), 
            config: abi.encode(
                treasury, // this should be the safe treasury! 
                config.safeAllowanceModule // allowance module address
            ),
            conditions: conditions
        }));
        delete conditions;
   

        ////////////////////////////////////////////////////////////////////// 
        //                      ELECTORAL MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        
        // ASSIGN MEMBERSHIP // -- on the basis of contributions to website
        // todo: needs to be configured with github repo details etc. 
        string[] memory paths = new string[](3);
        paths[0] = "documentation"; paths[1] = "frontend"; paths[2] = "solidity"; // can be anything 
        uint256[] memory roleIds = new uint256[](3);
        roleIds[0] = 2; roleIds[1] = 3; roleIds[2] = 4;

        // public: Apply for member role 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // Public
        conditions.throttleExecution = minutesToBlocks(3, config.BLOCKS_PER_HOUR); // to avoid spamming, the law is throttled. 
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Apply for Member Role: Anyone can claim member roles based on their GitHub contributions to the DAO's repository", // crrently the path is set at 7cedars/powers
            targetMandate: initialisePowers.getMandateAddress("ClaimRoleWithGitSig"), // £todo needs to be more configurable
            config: abi.encode(
                "develop", // branch
                paths,
                roleIds,
                "signed", // signatureString
                config.chainlinkFunctionsSubscriptionId,
                config.chainlinkFunctionsGasLimit,
                config.chainlinkFunctionsDonId
            ),
            conditions: conditions
        }));
        delete conditions;

        // Public: Claim Member Role
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // Public
        conditions.needFulfilled = mandateCount - 1; // must have applied for member role.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Claim Member Role: Following a successful initial claim, members can get member role assigned to their account.",
            targetMandate: initialisePowers.getMandateAddress("AssignRoleWithGitSig"),
            config: abi.encode(), // empty config
            conditions: conditions
        }));
        delete conditions;

        // ELECT CONVENERS // 
        // Members: Nominate for convener role
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for Conveners: Members can nominate themselves for the Convener role.",
            targetMandate: initialisePowers.getMandateAddress("Nominate"),
            config: abi.encode(
                address(openElection)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Start an election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Start an election: an election can be initiated be any voter.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionStart"),
            config: abi.encode(
                address(openElection),
                initialisePowers.getMandateAddress("OpenElectionVote"), // Vote mandate address
                minutesToBlocks(10, config.BLOCKS_PER_HOUR), // duration of election 
                1 // Role id that can vote = Members
            ),
            conditions: conditions
        }));
        delete conditions;

        // Mandate 4: End and Tally elections
        mandateCount++;
        conditions.allowedRole = 1; // = Member
        conditions.needFulfilled = mandateCount - 1; // = Start election
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "End and Tally elections: After an election has finished, assign the Convener role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionEnd"),
            config: abi.encode(
                address(openElection),
                2, // RoleId for Conveners
                3 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////
        
        // ADOPT MANDATES // 
        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Members: initiate Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = mandateCount - 1;
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Adopting Mandates: Members can initiate adopting new mandates",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // ParentDAO: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 3; // ParentDAO 
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto Adopting Mandates: ParentDAO can veto proposals to adopt new mandates", // £todo: ParentDAO actually does not have a lw yet to cast a veto.. 
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Conveners: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Conveners
        conditions.needFulfilled = mandateCount - 2;
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 80;   
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt new Mandates: Conveners can adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("AdoptMandates"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return digitalConstitution.length;

    }


    ////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////// 
    //                        IDEAS DAO CONSTITUTION                          //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function createIdeasConstitution() internal returns (uint256 constitutionLength) {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](5);
        values = new uint256[](5);
        calldatas = new bytes[](5);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO");
        calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, address(ParentDAO)); // assign Parent DAO role to Parent DAO address. 
        calldatas[4] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.
        
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
         
        // MINT ACTIVE IDEAS TOKENS //
        // This is the first time I properly use this. Will need proper testing! 
        bytes[] memory StaticParams = new bytes[](2);
        StaticParams[0] = abi.encode(1); // mandate id .
        StaticParams[1] = abi.encode("Minting Ideas Token"); // address of parent DAO.
        string[] memory DynamicParams = new string[](2);
        DynamicParams[0] = "address To";
        DynamicParams[1] = "uint256 NonceMint"; 
        uint8[] memory IndexDynamicParams = new uint8[](2);
        IndexDynamicParams[0] = 1; // address To
        IndexDynamicParams[1] = 1; // uint256 NonceMint

        // public: mint an active ideas token      
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = Public
        conditions.throttleExecution = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // note: the more people try to gain access, the harder it will be to get as supply is fixed. 
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint activity token: Anyone can mint an Active Ideas token. One token is available per 5 minutes.",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionAdvanced"), 
            config: abi.encode(
                address(parentDAO),
                Powers.request.selector, 
                StaticParams,
                DynamicParams
                ),
            conditions: conditions
        }));
        delete conditions;

        // UPDATE URI // 
        params = new string[](1);
        params[0] = "string newUri";
        
        // conveners: update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum 
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnOwnPowers"), 
            config: abi.encode( 
                Powers.setUri.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners. Any con can call this mandate.
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
            targetMandate: initialisePowers.getMandateAddress("Safe_RecoverTokens"), 
            config: abi.encode(
                treasury, // this should be the safe treasury! 
                config.safeAllowanceModule // allowance module address
            ),
            conditions: conditions
        }));
        delete conditions;
   

        ////////////////////////////////////////////////////////////////////// 
        //                      ELECTORAL MANDATES                          // 
        ////////////////////////////////////////////////////////////////////// 
        // ASSIGN MEMBERSHIP // -- on the basis of collected tokens from the org. 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request Membership: Anyone can become a member if they have sufficient activity token from the DAO: N tokens during the last M days.",
            targetMandate: initialisePowers.getMandateAddress("Soulbound1155_GatedAccess"),
            config: abi.encode(
                address(soulBound1155), // soulbound token contract
                1, // member role Id
                0, // checks if token is from address that holds role Id 0 (meaning the admin, which is the DAO itself). 
                5, // number of tokens required
                daysToBlocks(30, config.BLOCKS_PER_HOUR) // look back period in blocks = 30 days. 
            ),
            conditions: conditions
        }));
        delete conditions;

        // ELECT CONVENERS // 
        // Members: Nominate for convener role
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for Conveners: Members can nominate themselves for the Convener role.",
            targetMandate: initialisePowers.getMandateAddress("Nominate"),
            config: abi.encode(
                address(openElection)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Start an election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Start an election: an election can be initiated be any voter.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionStart"),
            config: abi.encode(
                address(openElection),
                initialisePowers.getMandateAddress("OpenElectionVote"), // Vote mandate address
                minutesToBlocks(10, config.BLOCKS_PER_HOUR), // duration of election 
                1 // Role id that can vote = Members
            ),
            conditions: conditions
        }));
        delete conditions;

        // Mandate 4: End and Tally elections
        mandateCount++;
        conditions.allowedRole = 1; // = Member
        conditions.needFulfilled = mandateCount - 1; // = Start election
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "End and Tally elections: After an election has finished, assign the Convener role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionEnd"),
            config: abi.encode(
                address(openElection),
                2, // RoleId for Conveners
                3 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////
        
        // Adopt mandate // 
        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Members: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = mandateCount - 1;
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto Adopting Mandates: Members can veto proposals to adopt new mandates",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Conveners: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Conveners
        conditions.needFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 80;   
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt new Mandates: Conveners can adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("AdoptMandates"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return ideasConstitution.length;
    }



    ////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////// 
    //                       PHYSICAL DAO CONSTITUTION                        //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function createPhysicalConstitution() internal returns (uint256 constitutionLength) {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](5);
        values = new uint256[](5);
        calldatas = new bytes[](5);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, address(ParentDAO)); // assign Parent DAO role to Parent DAO address.
        calldatas[4] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.
        
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
         
        // MINT POAPS //
        // This is the first time I properly use this. Will need proper testing! 
        bytes[] memory StaticParams = new bytes[](2);
        StaticParams[0] = abi.encode(1); // mandate id .
        StaticParams[1] = abi.encode("Minting POAP"); // address of parent DAO.
        string[] memory DynamicParams = new string[](2);
        DynamicParams[0] = "address To";
        DynamicParams[1] = "uint256 NonceMint"; 
        uint8[] memory IndexDynamicParams = new uint8[](2);
        IndexDynamicParams[0] = 1; // address To
        IndexDynamicParams[1] = 1; // uint256 NonceMint

        // convener: mint POAP      
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners  
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint POAP: Any Convener can mint a POAP.",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionAdvanced"), 
            config: abi.encode(
                address(parentDAO),
                Powers.request.selector, 
                StaticParams,
                DynamicParams
                ),
            conditions: conditions
        }));
        delete conditions;

        // UPDATE URI // 
        params = new string[](1);
        params[0] = "string newUri";

        // conveners: update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum 
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnOwnPowers"), 
            config: abi.encode( 
                Powers.setUri.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners. Any con can call this mandate.
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
            targetMandate: initialisePowers.getMandateAddress("Safe_RecoverTokens"), 
            config: abi.encode(
                treasury, // this should be the safe treasury! 
                config.safeAllowanceModule // allowance module address
            ),
            conditions: conditions
        }));
        delete conditions;
   

        ////////////////////////////////////////////////////////////////////// 
        //                      ELECTORAL MANDATES                          // 
        ////////////////////////////////////////////////////////////////////// 
        // ASSIGN MEMBERSHIP // -- on the basis of POAPS. 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request Membership: Anyone can become a member if they have sufficient activity token from the DAO: N tokens during the last M days.",
            targetMandate: initialisePowers.getMandateAddress("Soulbound1155_GatedAccess"),
            config: abi.encode(
                address(soulBound1155), // soulbound token contract
                1, // member role Id
                0, // checks if token is from address that holds role Id 0 (meaning the admin, which is the DAO itself). 
                1, // number of tokens required. Only one POAP needed for membership.
                daysToBlocks(15, config.BLOCKS_PER_HOUR) // look back period in blocks = 15 days. 
            ),
            conditions: conditions
        }));
        delete conditions;

        // ELECT CONVENERS // 
        // Members: Nominate for convener role
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for Conveners: Members can nominate themselves for the Convener role.",
            targetMandate: initialisePowers.getMandateAddress("Nominate"),
            config: abi.encode(
                address(openElection)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Start an election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Start an election: an election can be initiated be any voter.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionStart"),
            config: abi.encode(
                address(openElection),
                initialisePowers.getMandateAddress("OpenElectionVote"), // Vote mandate address
                minutesToBlocks(10, config.BLOCKS_PER_HOUR), // duration of election 
                1 // Role id that can vote = Members
            ),
            conditions: conditions
        }));
        delete conditions;

        // Mandate 4: End and Tally elections
        mandateCount++;
        conditions.allowedRole = 1; // = Member
        conditions.needFulfilled = mandateCount - 1; // = Start election
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "End and Tally elections: After an election has finished, assign the Convener role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionEnd"),
            config: abi.encode(
                address(openElection),
                2, // RoleId for Conveners
                3 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////
        
        // ADOPT MANDATES // 
        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Members: initiate Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = mandateCount - 1;
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Adopting Mandates: Members can initiate adopting new mandates",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // ParentDAO: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 3; // ParentDAO 
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto Adopting Mandates: ParentDAO can veto proposals to adopt new mandates", // £todo: ParentDAO actually does not have a lw yet to cast a veto.. 
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Conveners: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Conveners
        conditions.needFulfilled = mandateCount - 2;
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 80;   
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt new Mandates: Conveners can adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("AdoptMandates"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;
        
        return physicalConstitution.length;
    }

}
