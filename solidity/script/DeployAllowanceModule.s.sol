// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import { Script } from "forge-std/Script.sol";

import { AllowanceModule } from "lib/safe-modules/modules/allowances/contracts/AllowanceModule.sol";

// @dev this script deploys Safe Allowance Module. 
contract DeployAllowanceModule is Script {
    AllowanceModule allowanceModule; 

    function run() external returns (address allowanceModuleAddress) {
        bytes32 salt = keccak256(abi.encodePacked("PowersSalt"));
        vm.startBroadcast();
        allowanceModule = new AllowanceModule{salt: salt}();
        vm.stopBroadcast();
        
        return address(allowanceModule);
    }
}
