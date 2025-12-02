// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Powers } from "../src/Powers.sol";
import { console2 } from "forge-std/console2.sol";
import { SafeProxyFactory } from "lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { SafeL2 } from "lib/safe-smart-account/contracts/SafeL2.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";
import { ModuleManager } from "lib/safe-smart-account/contracts/base/ModuleManager.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol"; 

contract InitialiseSafe is Script {
    // Canonical addresses. Still: should be taken from config file. 
    address constant SAFE_PROXY_FACTORY = 0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67;
    address constant SAFE_L2_SINGLETON = 0x29fcB43b46531BcA003ddC8FCB67FFE91900C762;
    address constant SAFE_MODULE_ALLOWANCE = 0xAA46724893dedD72658219405185Fb0Fc91e091C; // this is the address in Sepolia. 

    function run(address powersAddress) external returns (address safeProxyAddress) {
        vm.startBroadcast();

        // 2. Prepare Safe setup data
        address[] memory owners = new address[](1);
        owners[0] = powersAddress;

        bytes memory initializer = abi.encodeWithSelector(
            Safe.setup.selector,
            owners,
            1, // threshold
            address(0), // to
            "", // data
            address(0), // fallbackHandler
            address(0), // paymentToken
            0, // payment
            address(0) // paymentReceiver
        );

        uint256 nonce = 1;
        
        safeProxyAddress = address(SafeProxyFactory(SAFE_PROXY_FACTORY).createProxyWithNonce(
            SAFE_L2_SINGLETON,
            initializer,
            nonce
        ));

        uint256 currentNonce = SafeL2(payable(safeProxyAddress)).nonce();
        console2.log("Safe Proxy nonce:", currentNonce);

        // bytes32 transactionHash = SafeL2(payable(safeProxyAddress)).getTransactionHash(
        //     SAFE_MODULE_ALLOWANCE, // to address
        //     0, // value 
        //     abi.encodeWithSelector(ModuleManager.enableModule.selector, powersAddress), // data 
        //     Enum.Operation.Call, // type of operation (0 = call or 1= delegatecall)
        //     0, // safeTxGas
        //     0, // base gas
        //     0, // gas price
        //     address(0), // gas token == native token 
        //     payable(msg.sender), // refund receiver
        //     currentNonce // nonce
        // );
        // console2.logBytes32(transactionHash); 

        vm.stopBroadcast();
        
        console2.log("Safe Proxy deployed at:", safeProxyAddress);

    }
}
