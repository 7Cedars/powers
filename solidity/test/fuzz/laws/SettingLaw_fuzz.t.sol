// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// import {Test, console, console2} from "lib/forge-std/src/Test.sol";
// import {DeployAgDao} from "../../script/DeployAgDao.s.sol";
// import {Powers} from "../src/Powers.sol";
// import {AgDao} from   "../src/implementation/DAOs/AgDao.sol";
// import {AgCoins} from "../src/implementation/DAOs/AgCoins.sol";
// import {Law} from "../src/Law.sol";
// import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";
// import {IPowers} from "../src/interfaces/IPowers.sol";

// // constitutional laws
// import {Admin_setLaw} from "../src/implementation/DAOs/laws/Admin_setLaw.sol";
// import {Public_assignRole} from "../src/implementation/DAOs/laws/Public_assignRole.sol";
// import {Public_challengeRevoke} from "../src/implementation/DAOs/laws/Public_challengeRevoke.sol";
// import {Member_proposeCoreValue} from "../src/implementation/DAOs/laws/Member_proposeCoreValue.sol";
// import {Senior_acceptProposedLaw} from "../src/implementation/DAOs/laws/Senior_acceptProposedLaw.sol";
// import {Senior_assignRole} from "../src/implementation/DAOs/laws/Senior_assignRole.sol";
// import {Senior_reinstateMember} from "../src/implementation/DAOs/laws/Senior_reinstateMember.sol";
// import {Senior_revokeRole} from "../src/implementation/DAOs/laws/Senior_revokeRole.sol";
// import {Whale_acceptCoreValue} from "../src/implementation/DAOs/laws/Whale_acceptCoreValue.sol";
// import {Member_assignWhale} from "../src/implementation/DAOs/laws/Member_assignWhale.sol";
// import {Whale_proposeLaw} from "../src/implementation/DAOs/laws/Whale_proposeLaw.sol";
// import {Whale_revokeMember} from "../src/implementation/DAOs/laws/Whale_revokeMember.sol";

// /**
// * @notice Unit tests for the core Separated Powers protocol.
// *
// * @dev tests build on the agDao example.
// * @dev for chained proposal tests, see the 'chain propsals' section.
// */

// contract PowersTest is Test {
//   /* Type declarations */
//   Powers powers;
//   AgDao agDao;
//   AgCoins agCoins;
//   address[] constituentLaws;

//   /* addresses */
//   address alice = makeAddr("alice");
//   address bob = makeAddr("bob");
//   address charlotte = makeAddr("charlotte");
//   address david = makeAddr("david");
//   address eve = makeAddr("eve");
//   address frank = makeAddr("frank");
//   address[] allAdresses = [alice, bob, charlotte, david, eve, frank];

//   /* state variables */
//   uint48 public constant ADMIN_ROLE = type(uint48).min; // == 0
//   uint48 public constant PUBLIC_ROLE = type(uint48).max; // == a lot. This role is for everyone.
//   uint48 public constant SENIOR_ROLE = 1;
//   uint48 public constant WHALE_ROLE = 2;
//   uint48 public constant MEMBER_ROLE = 3;
//   bytes32 SALT = bytes32(hex'7ceda5');

//   /* modifiers */

//   ///////////////////////////////////////////////
//   ///                   Setup                 ///
//   ///////////////////////////////////////////////
//   function setUp() public {
//     vm.roll(block.number + 10);
//     vm.startBroadcast(alice);
//       agDao = new AgDao();
//       agCoins = new AgCoins(address(agDao));
//     vm.stopBroadcast();

//     /* setup roles */
//     IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](10);
//     constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
//     constituentRoles[1] = IAuthoritiesManager.ConstituentRole(bob, MEMBER_ROLE);
//     constituentRoles[2] = IAuthoritiesManager.ConstituentRole(charlotte, MEMBER_ROLE);
//     constituentRoles[3] = IAuthoritiesManager.ConstituentRole(david, MEMBER_ROLE);
//     constituentRoles[4] = IAuthoritiesManager.ConstituentRole(eve, MEMBER_ROLE);
//     constituentRoles[5] = IAuthoritiesManager.ConstituentRole(alice, SENIOR_ROLE);
//     constituentRoles[6] = IAuthoritiesManager.ConstituentRole(bob, SENIOR_ROLE);
//     constituentRoles[7] = IAuthoritiesManager.ConstituentRole(charlotte, SENIOR_ROLE);
//     constituentRoles[8] = IAuthoritiesManager.ConstituentRole(david, WHALE_ROLE);
//     constituentRoles[9] = IAuthoritiesManager.ConstituentRole(eve, WHALE_ROLE);

//     /* setup laws */
//     constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));

//     vm.startBroadcast(alice);
//     agDao.constitute(constituentLaws, constituentRoles);
//     vm.stopBroadcast();
//   }

//   ///////////////////////////////////////////////
//   ///                   Tests                 ///
//   ///////////////////////////////////////////////

//   function testAddingLawFuzz(uint256 index0, uint256 index1, uint256 index2) public {
//     /* PROPOSAL LINK 1: a whale proposes a law. */
//     index0 = bound(index0, 0, 5);
//     index1 = bound(index1, 0, 5);
//     index2 = bound(index2, 0, 5);
//     address account0 = allAdresses[index0];
//     address account1 = allAdresses[index1];
//     address account2 = allAdresses[index2];

//     console2.log("FUNCTION CALLED");

//     // proposing...
//     address newLaw = address(new Public_assignRole(payable(address(agDao))));
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(newLaw, true);

//     vm.prank(account0); // = a whale
//     if (account0 != david && account0 != eve){ vm.expectRevert(); }
//     uint256 actionIdOne = agDao.propose(
//       constituentLaws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );
//     if (account0 != david && account0 != eve){ return; }

//     // whales vote in favor... David and eve are whales.
//     vm.prank(david);
//     agDao.castVote(actionIdOne, 1); // = for
//     vm.prank(eve);
//     agDao.castVote(actionIdOne, 1); // = for

//     vm.roll(block.number + 4_000);

//     // executing...
//     vm.prank(account0);
//     agDao.execute(constituentLaws[4], lawCalldata, nonce);

//     // check
//     PowersTypes.ActionState ActionStateOne = agDao.state(actionIdOne);
//     assert(uint8(ActionStateOne) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     // proposing...
//     vm.roll(block.number + 5_000);
//     vm.prank(account1); // = a senior
//     if (account1 != alice && account1 != bob && account1 != charlotte){ vm.expectRevert(); }
//     uint256 actionIdTwo = agDao.propose(
//       constituentLaws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );
//     if (account1 != alice && account1 != bob && account1 != charlotte){ return; }

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     agDao.castVote(actionIdTwo, 1); // = for
//     vm.prank(bob);
//     agDao.castVote(actionIdTwo, 1); // = for
//     vm.prank(charlotte);
//     agDao.castVote(actionIdTwo, 1); // = for

//     vm.roll(block.number + 9_000);

//     // executing...
//     vm.prank(account1);
//     agDao.execute(constituentLaws[5], lawCalldata, nonce);

//     // check
//     PowersTypes.ActionState ActionStateTwo = agDao.state(actionIdTwo);
//     assert(uint8(ActionStateTwo) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
//     vm.roll(block.number + 10_000);
//     vm.prank(account2); // = admin role
//     if (account2 != alice){ vm.expectRevert(); }
//     agDao.execute(constituentLaws[6], lawCalldata, nonce);
//     if (account2 != alice){ return; }

//     // check if law has been set to active.
//     console2.log("NEW LAW SET!");
//     bool active = agDao.activeLaws(newLaw);
//     assert (active == true);
//   }

//   ///////////////////////////////////////////////
//   ///                   Helpers               ///
//   ///////////////////////////////////////////////
//  function _deployLaws(address payable agDaoAddress_, address agCoinsAddress_) internal returns (address[] memory lawsArray) {
//       address[] memory laws = new address[](12);

//       // deploying laws //
//       vm.startPrank(bob);
//       // re assigning roles //
//       laws[0] = address(new Public_assignRole(agDaoAddress_));
//       laws[1] = address(new Senior_assignRole(agDaoAddress_, agCoinsAddress_));
//       laws[2] = address(new Senior_revokeRole(agDaoAddress_, agCoinsAddress_));
//       laws[3] = address(new Member_assignWhale(agDaoAddress_, agCoinsAddress_));

//       // re activating & deactivating laws  //
//       laws[4] = address(new Whale_proposeLaw(agDaoAddress_, agCoinsAddress_));
//       laws[5] = address(new Senior_acceptProposedLaw(agDaoAddress_, agCoinsAddress_, address(laws[4])));
//       laws[6] = address(new Admin_setLaw(agDaoAddress_, address(laws[5])));

//       // re updating core values //
//       laws[7] = address(new Member_proposeCoreValue(agDaoAddress_, agCoinsAddress_));
//       laws[8] = address(new Whale_acceptCoreValue(agDaoAddress_, agCoinsAddress_, address(laws[7])));

//       // re enforcing core values as requirement for external funding //
//       laws[9] = address(new Whale_revokeMember(agDaoAddress_, agCoinsAddress_));
//       laws[10] = address(new Public_challengeRevoke(agDaoAddress_, address(laws[9])));
//       laws[11] = address(new Senior_reinstateMember(agDaoAddress_, agCoinsAddress_, address(laws[10])));
//       vm.stopPrank();

//       return laws;
//     }
// }
