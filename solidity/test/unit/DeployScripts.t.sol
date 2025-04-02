// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/utils/ShortStrings.sol";
// import { Powers} from "../../src/Powers.sol";
// import { ILaw } from "../../src/interfaces/ILaw.sol";
// import { DeployAlignedDao } from "../../script/DeployAlignedDao.s.sol";

// //////////////////////////////////////////////////
// //                  SETUP                       //
// //////////////////////////////////////////////////

// //////////////////////////////////////////////////
// //                  TESTS                       //
// //////////////////////////////////////////////////
// contract DeployAlignedDaoTest is Test {
//     using ShortStrings for *;

//     DeployAlignedDao deployAlignedGrants = new DeployAlignedDao();

//     function testDeployScriptAlignedGrants() public {
//         (
//           AlignedGrants alignedGrants,
//           address[] memory laws,
//           uint32[] memory allowedRoles,
//            LawUtilities.Conditions[] memory Conditionss,
//           uint32[] memory constituentRoles,
//           address[] memory constituentAccounts
//           ) = deployAlignedGrants.run();
//     }

//     function testDeployEmitsEvent() public {
//         vm.expectEmit(false, false, false, false);
//         emit Law__Initialized(address(0));
//         Law lawMock = new OpenAction("OpenAction Mock", "This is a mock of the open action law contract", address(123));
//     }
// }
