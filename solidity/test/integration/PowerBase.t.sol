// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Powers } from "../../src/Powers.sol";
import { IPowers } from "../../src/interfaces/IPowers.sol";
import { PowersTypes } from "../../src/interfaces/PowersTypes.sol";
import { PowersEvents } from "../../src/interfaces/PowersEvents.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";

import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";

import { TestSetupPowerBaseSafes } from "../../test/TestSetup.t.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { InitialiseSafe } from "../../script/InitialiseSafe.s.sol";
import { PowerBaseSafeSetup } from "../../src/laws/reform/PowerBaseSafeSetup.sol";
import { SafeExecTransaction } from "../../src/laws/integrations/SafeExecTransaction.sol";
import { SafeAllowanceAction } from "../../src/laws/integrations/SafeAllowanceAction.sol";

import { ModuleManager } from "lib/safe-smart-account/contracts/base/ModuleManager.sol";
import { OwnerManager } from "lib/safe-smart-account/contracts/base/OwnerManager.sol";
import { SafeL2 } from "lib/safe-smart-account/contracts/SafeL2.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";
import { MessageHashUtils } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract PowerBase_IntegrationTest is TestSetupPowerBaseSafes {
    // IMPORTANT NOTE: These tests are meant to be executed on a forked mainnet (sepolia) anvil chain. 
    // They will not execute if the Allowance module address is empty.  
    // This also means that any test actions persist across tests, so be careful when re-running tests!
    address allowanceModule = 0xAA46724893dedD72658219405185Fb0Fc91e091C; // Sepolia Allowance Module - should be set in config file.
    address safeProxy;

    function testPowerBase_Deployment() public {
        // Just verify setup completed successfully
        assertTrue(address(daoMock) != address(0), "Powers contract not deployed");
        
        // Verify constitution laws
        // Law 1: Initial Setup
        // Law 2: Setup Safe
        
        (address law1, , bool active1) = daoMock.getAdoptedLaw(1);
        (address law2, , bool active2) = daoMock.getAdoptedLaw(2);
        
        assertTrue(active1, "Law 1 not active");
        assertTrue(active2, "Law 2 not active");
        assertEq(law1, findLawAddress("PresetSingleAction"), "Law 1 target mismatch");  
        assertEq(law2, findLawAddress("PowerBaseSafeSetup"), "Law 2 target mismatch");  
    }

    function testPowerBase_InitialiseSafe() public {
        // Deploy and initialise safe
        InitialiseSafe initSafe = new InitialiseSafe();
        safeProxy = initSafe.run(address(daoMock));
        
        assertTrue(safeProxy != address(0), "Safe proxy not deployed");
    }

    function testPowerBase_CallPowerBaseSafeSetup() public {
        InitialiseSafe initSafe = new InitialiseSafe();
        safeProxy = initSafe.run(address(daoMock));
        
        vm.prank(alice);
        daoMock.request(2, abi.encode(safeProxy, allowanceModule), nonce, "Setup Safe");

        assertTrue(daoMock.lawCounter() > 2, "No new actions recorded");
        assertTrue(SafeL2(payable(safeProxy)).isModuleEnabled(allowanceModule), "Allowance module not enabled"); 


        // console2.log("next module address: ");
        // console2.logAddress(next);
        // console2.log("Safe Modules after PowerBaseSafeSetup:");
        // for (uint256 i = 0; i < modules.length; i++) {
        //     console2.log("Module ", i, ": ", modules[i]);
        // } 
    }

    // function testPowerBase_AdoptAllowanceModule() public {
    //     // Assumne that the safePorxy has been initialised and that the PowerBaseSafeSetup has been called.
    //     vm.assume(safeProxy != address(0)); 
    //     vm.assume(daoMock.lawCounter() > 2);

    //     // Verify law execution success
    //     (address lawAddress, , ) = daoMock.getAdoptedLaw(3); // The 3rd law should be the allowance module adoption
    //     PowerBaseSafeSetup powerBaseSetupLaw = PowerBaseSafeSetup(findLawAddress("PowerBaseSafeSetup"));
    //     (address expectedLawAddress, ) = powerBaseSetupLaw.getAllowanceModuleAdoptionLaw(address(daoMock));
    //     assertEq(lawAddress, expectedLawAddress, "Allowance module adoption law address mismatch");

    //     // calling the allowance module adoption law. 
    //     vm.prank(alice);
    //     daoMock.request(3, abi.encode(safeProxy), nonce, "Setup Safe");



        // // 3. Set an allowance for the daoMock
        // Erc20Taxed dummyToken = new Erc20Taxed();
        // bytes memory setAllowanceCalldata = abi.encodeWithSelector(
        //     bytes4(0xbeaeb388), // = allowanceModule.setAllowance.selector, 
        //     address(daoMock), 
        //     address(dummyToken), 
        //     2 ether, 0, 0
        //     );
        // bytes memory lawCalldataForAllowance = abi.encode(
        //     allowanceModule, // to
        //     0, // value
        //     setAllowanceCalldata, // data
        //     Enum.Operation.Call // operation
        // );
        // vm.prank(alice);
        // daoMock.request(uint16(lawIdForSetup), lawCalldataForAllowance, nonce + 1, "Set Allowance");


        // // 4. Adopt the SafeAllowanceAction law
        // SafeAllowanceAction safeAllowanceExecLaw = new SafeAllowanceAction();
        // bytes memory config = abi.encode(safeProxy, allowanceModule, address(dummyToken), 0);
        // PowersTypes.LawInitData memory lawInitData = PowersTypes.LawInitData({
        //     targetLaw: address(safeAllowanceExecLaw),
        //     conditions: PowersTypes.Conditions({ 
        //         allowedRole: PUBLIC_ROLE, 
        //         quorum: 0, 
        //         succeedAt: 0, 
        //         votingPeriod: 0,
        //         needFulfilled: 0, 
        //         needNotFulfilled: 0, 
        //         delayExecution: 0, 
        //         throttleExecution: 0 
        //         }),
        //     config: config,
        //     nameDescription: "Execute an allowance transaction on the Safe"
        // });
        // vm.prank(address(daoMock));
        // uint256 lawId = daoMock.adoptLaw(lawInitData);

        // // 5. Prepare the internal transaction for the safe
        // bytes memory lawCalldata = abi.encode(
        //     address(dummyToken), // token
        //     bob, // to
        //     uint96(1 ether), // amount
        //     address(daoMock) // delegate
        // );

        // // 6. Execute the law
        // vm.prank(alice);
        // daoMock.request(uint16(lawId), lawCalldata, nonce, "Execute Safe Allowance Transaction");

        // // 7. Verify the outcome
        // assertEq(dummyToken.balanceOf(bob), 1 ether, "Dummy token transfer should have been successful");
    // }

    // function test_SafeExecTransaction_Law() public {
    //     // 1. Initialise Safe
    //     InitialiseSafe initSafe = new InitialiseSafe();
    //     address safeProxy = initSafe.run(address(daoMock));

    //     // 3. Adopt the SafeExecTransaction law
    //     SafeExecTransaction safeExecLaw = new SafeExecTransaction();
    //     bytes memory config = abi.encode(new string[](0), safeProxy);
    //     PowersTypes.LawInitData memory lawInitData = PowersTypes.LawInitData({
    //         targetLaw: address(safeExecLaw),
    //         conditions: PowersTypes.Conditions({
    //             allowedRole: PUBLIC_ROLE, // Allow anyone to propose executions
    //             quorum: 0,
    //             succeedAt: 0,
    //             votingPeriod: 0,
    //             needFulfilled: 0,
    //             needNotFulfilled: 0,
    //             delayExecution: 0,
    //             throttleExecution: 0
    //         }),
    //         config: config,
    //         nameDescription: "Execute a transaction on the Safe"
    //     });
    //     vm.prank(address(daoMock));
    //     uint256 lawId = daoMock.adoptLaw(lawInitData);

    //     // 4. Prepare the internal transaction for the safe
    //     Erc20Taxed dummyToken = new Erc20Taxed();
    //     bytes memory internalTxData = abi.encodeWithSelector(dummyToken.transfer.selector, bob, 1 ether);
        
    //     bytes memory lawCalldata = abi.encode(
    //         address(dummyToken), // to
    //         0, // value
    //         internalTxData, // data
    //         Enum.Operation.Call // operation
    //     );

    //     // 5. Execute the law
    //     vm.prank(alice);
    //     daoMock.request(uint16(lawId), lawCalldata, nonce, "Execute Safe Transaction");

    //     // 6. Verify the outcome
    //     assertEq(dummyToken.balanceOf(bob), 1 ether, "Dummy token transfer should have been successful");
    // }

    // function test_Fail_SafeExecTransaction_Law_When_Not_Owner() public {
    //     // 1. Initialise Safe
    //     InitialiseSafe initSafe = new InitialiseSafe();
    //     address safeProxy = initSafe.run(address(daoMock));

    //     // Note: We DO NOT make the daoMock an owner of the safe in this test.

    //     // 2. Adopt the SafeExecTransaction law
    //     SafeExecTransaction safeExecLaw = new SafeExecTransaction();
    //     bytes memory config = abi.encode(new string[](0), safeProxy);
    //     PowersTypes.LawInitData memory lawInitData = PowersTypes.LawInitData({
    //         targetLaw: address(safeExecLaw),
    //         conditions: PowersTypes.Conditions({
    //             allowedRole: PUBLIC_ROLE, // Allow anyone to propose executions
    //             quorum: 0,
    //             succeedAt: 0,
    //             votingPeriod: 0,
    //             needFulfilled: 0,
    //             needNotFulfilled: 0,
    //             delayExecution: 0,
    //             throttleExecution: 0
    //         }),
    //         config: config,
    //         nameDescription: "Execute a transaction on the Safe"
    //     });
    //     vm.prank(address(daoMock));
    //     uint256 lawId = daoMock.adoptLaw(lawInitData);

    //     // 3. Prepare the internal transaction for the safe
    //     Erc20Taxed dummyToken = new Erc20Taxed();
    //     bytes memory internalTxData = abi.encodeWithSelector(dummyToken.transfer.selector, bob, 1 ether);
        
    //     bytes memory lawCalldata = abi.encode(
    //         address(dummyToken), // to
    //         0, // value
    //         internalTxData, // data
    //         Enum.Operation.Call // operation
    //     );

    //     // 4. Execute the law - this should fail
    //     vm.prank(alice);
    //     vm.expectRevert("GS026"); // Expecting Safe revert with invalid owner
    //     daoMock.request(uint16(lawId), lawCalldata, nonce, "Execute Safe Transaction");
    // }

    // function test_SafeAllowanceAction_Law() public {
    //     // 1. Initialise Safe and enable allowance module
    //     InitialiseSafe initSafe = new InitialiseSafe();
    //     address safeProxy = initSafe.run(address(daoMock));
    //     bytes memory enableModuleCalldata = abi.encodeWithSelector(ModuleManager.enableModule.selector, allowanceModule);
    //     vm.prank(address(daoMock));
    //     (bool success, ) = safeProxy.call(enableModuleCalldata);
    //     require(success, "Failed to add daoMock as owner");

    //     // 2. Add daoMock as a delegate in the allowance module
    //     bytes memory addDelegateCalldata = abi.encodeWithSelector(
    //         bytes4(0xe71bdf41), // = allowanceModule.addDelegate.selector, 
    //         address(daoMock)
    //         );
    //     // This needs to be executed by the safe itself
    //     bytes memory lawCalldataForDelegate = abi.encode(
    //         allowanceModule, // to
    //         0, // value
    //         addDelegateCalldata, // data
    //         Enum.Operation.Call // operation
    //     );
    //     // We can reuse the SafeExecTransaction law for this setup
    //     SafeExecTransaction safeExecLawForSetup = new SafeExecTransaction();
    //     bytes memory configForSetup = abi.encode(new string[](0), safeProxy);
    //     PowersTypes.LawInitData memory lawInitDataForSetup = PowersTypes.LawInitData({
    //         targetLaw: address(safeExecLawForSetup),
    //         conditions: PowersTypes.Conditions({ 
    //             allowedRole: PUBLIC_ROLE, 
    //             quorum: 0, 
    //             succeedAt: 0, 
    //             votingPeriod: 0, 
    //             needFulfilled: 0, 
    //             needNotFulfilled: 0, 
    //             delayExecution: 0, 
    //             throttleExecution: 0 
    //             }),
    //         config: configForSetup,
    //         nameDescription: "Setup Delegate"
    //     });
    //     vm.prank(address(daoMock));
    //     uint256 lawIdForSetup = daoMock.adoptLaw(lawInitDataForSetup);
    //     vm.prank(alice);
    //     daoMock.request(uint16(lawIdForSetup), lawCalldataForDelegate, nonce, "Add Delegate");

    //     // 3. Set an allowance for the daoMock
    //     Erc20Taxed dummyToken = new Erc20Taxed();
    //     bytes memory setAllowanceCalldata = abi.encodeWithSelector(
    //         bytes4(0xbeaeb388), // = allowanceModule.setAllowance.selector, 
    //         address(daoMock), 
    //         address(dummyToken), 
    //         2 ether, 0, 0
    //         );
    //     bytes memory lawCalldataForAllowance = abi.encode(
    //         allowanceModule, // to
    //         0, // value
    //         setAllowanceCalldata, // data
    //         Enum.Operation.Call // operation
    //     );
    //     vm.prank(alice);
    //     daoMock.request(uint16(lawIdForSetup), lawCalldataForAllowance, nonce + 1, "Set Allowance");


    //     // 4. Adopt the SafeAllowanceAction law
    //     SafeAllowanceAction safeAllowanceExecLaw = new SafeAllowanceAction();
    //     bytes memory config = abi.encode(safeProxy, allowanceModule, address(dummyToken), 0);
    //     PowersTypes.LawInitData memory lawInitData = PowersTypes.LawInitData({
    //         targetLaw: address(safeAllowanceExecLaw),
    //         conditions: PowersTypes.Conditions({ 
    //             allowedRole: PUBLIC_ROLE, 
    //             quorum: 0, 
    //             succeedAt: 0, 
    //             votingPeriod: 0,
    //             needFulfilled: 0, 
    //             needNotFulfilled: 0, 
    //             delayExecution: 0, 
    //             throttleExecution: 0 
    //             }),
    //         config: config,
    //         nameDescription: "Execute an allowance transaction on the Safe"
    //     });
    //     vm.prank(address(daoMock));
    //     uint256 lawId = daoMock.adoptLaw(lawInitData);

    //     // 5. Prepare the internal transaction for the safe
    //     bytes memory lawCalldata = abi.encode(
    //         address(dummyToken), // token
    //         bob, // to
    //         uint96(1 ether), // amount
    //         address(daoMock) // delegate
    //     );

    //     // 6. Execute the law
    //     vm.prank(alice);
    //     daoMock.request(uint16(lawId), lawCalldata, nonce, "Execute Safe Allowance Transaction");

    //     // 7. Verify the outcome
    //     assertEq(dummyToken.balanceOf(bob), 1 ether, "Dummy token transfer should have been successful");
    // }
}
