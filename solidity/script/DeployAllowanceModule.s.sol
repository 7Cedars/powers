// // // SPDX-License-Identifier: MIT
// pragma solidity 0.7.6;

// import { Script } from "forge-std/Script.sol";
// import { console2 } from "forge-std/console2.sol"; 
// import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

// import { AllowanceModule } from "lib/safe-modules/modules/allowances/contracts/AllowanceModule.sol";

 
// // @dev this script deploys custom law packages to the chain.
// contract DeployAllowanceModule is Script { 
//     function run() external returns (address allowanceModuleAddress) {
//         vm.startBroadcast(); 
//         allowanceModuleAddress = new AllowanceModule{salt: bytes32(abi.encodePacked("PowersSalt"));}();
//         vm.stopBroadcast();
//     }
// }
