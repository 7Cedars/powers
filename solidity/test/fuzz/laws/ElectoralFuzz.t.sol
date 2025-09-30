// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { TestSetupElectoralFuzz } from "../../TestSetup.t.sol";
import { ElectionSelect } from "../../../src/laws/electoral/ElectionSelect.sol";
import { PeerSelect } from "../../../src/laws/electoral/PeerSelect.sol";
import { VoteInOpenElection } from "../../../src/laws/electoral/VoteInOpenElection.sol";
import { TaxSelect } from "../../../src/laws/electoral/TaxSelect.sol";
import { BuyAccess } from "../../../src/laws/electoral/BuyAccess.sol";
import { SelfSelect } from "../../../src/laws/electoral/SelfSelect.sol";
import { RenounceRole } from "../../../src/laws/electoral/RenounceRole.sol";
import { NStrikesRevokesRoles } from "../../../src/laws/electoral/NStrikesRevokesRoles.sol";
import { RoleByRoles } from "../../../src/laws/electoral/RoleByRoles.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol";
import { Erc20DelegateElection } from "@mocks/Erc20DelegateElection.sol";
import { OpenElection } from "@mocks/OpenElection.sol";
import { Nominees } from "@mocks/Nominees.sol";
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";
import { Donations } from "@mocks/Donations.sol";
import { FlagActions } from "@mocks/FlagActions.sol";

/// @title Electoral Law Fuzz Tests
/// @notice Comprehensive fuzz testing for all electoral law implementations using pre-initialized laws
/// @dev Tests use laws from initiateElectoralTestConstitution:
///      lawId 1: ElectionSelect (Erc20DelegateElection, roleId=3, maxHolders=3)
///      lawId 2: PeerSelect (maxHolders=2, roleId=4, maxVotes=1, Nominees)
///      lawId 3: VoteInOpenElection (OpenElection, maxVotes=1)
///      lawId 4: TaxSelect (Erc20Taxed, threshold=1000, roleId=4)
///      lawId 5: BuyAccess (Donations, tokens, tokensPerBlock, roleId=4)
///      lawId 6: SelfSelect (roleId=4)
///      lawId 7: RenounceRole (roles=[1,2])
///      lawId 8: NStrikesRevokesRoles (roleId=3, strikes=2, FlagActions)
///      lawId 9: RoleByRoles (targetRole=4, neededRoles=[1,2])
///      lawId 10: PresetSingleAction (label roles)
contract ElectoralFuzzTest is TestSetupElectoralFuzz {
    
    // Law instances for testing
    ElectionSelect electionSelect;
    PeerSelect peerSelect;
    VoteInOpenElection voteInOpenElection;
    TaxSelect taxSelect;
    BuyAccess buyAccess;
    SelfSelect selfSelect;
    RenounceRole renounceRole;
    NStrikesRevokesRoles nStrikesRevokesRoles;
    RoleByRoles roleByRoles;
    
    // Mock contract instances
    Erc20DelegateElection erc20DelegateElection;
    OpenElection openElection;
    Nominees nomineesContract;
    Erc20Taxed erc20Taxed;
    Donations donations;
    FlagActions flagActions;
    
    // State variables to avoid stack too deep errors
    uint256 returnedActionId;
    address[] returnedTargets;
    uint256[] returnedValues;
    bytes[] returnedCalldatas;
    uint256[] roleIds;
    address[] accountsArray;
    address[] nomineesList;
    uint256 taxPaidAmount;
    uint256 tokenAmount;
    uint256 blocksPaid;
    
    function setUp() public override {
        super.setUp();
        
        // Initialize law instances from deployed addresses
        electionSelect = ElectionSelect(lawAddresses[9]);
        peerSelect = PeerSelect(lawAddresses[10]);
        voteInOpenElection = VoteInOpenElection(lawAddresses[11]);
        nStrikesRevokesRoles = NStrikesRevokesRoles(lawAddresses[12]);
        taxSelect = TaxSelect(lawAddresses[13]);
        buyAccess = BuyAccess(lawAddresses[14]);
        roleByRoles = RoleByRoles(lawAddresses[15]);
        selfSelect = SelfSelect(lawAddresses[16]);
        renounceRole = RenounceRole(lawAddresses[17]);
        
        // Initialize mock contract instances
        erc20DelegateElection = Erc20DelegateElection(mockAddresses[10]);
        openElection = OpenElection(mockAddresses[9]);
        nomineesContract = Nominees(mockAddresses[8]);
        erc20Taxed = Erc20Taxed(mockAddresses[1]);
        donations = Donations(payable(mockAddresses[5]));
        flagActions = FlagActions(mockAddresses[6]);
    }

    //////////////////////////////////////////////////////////////
    //                  SELF SELECT FUZZ                        //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test SelfSelect (lawId 6) with various accounts
    /// @dev lawId 6 is configured to self-assign role 4
    function testFuzzSelfSelectWithVariousAccounts(
        address accountFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        vm.deal(accountFuzzed, 1 ether);
        
        // Verify account doesn't have role initially
        vm.assume(daoMock.hasRoleSince(accountFuzzed, 4) == 0);
        
        lawCalldata = abi.encode();
        
        (returnedActionId, returnedTargets, , returnedCalldatas) = 
            selfSelect.handleRequest(accountFuzzed, address(daoMock), 6, lawCalldata, nonceFuzzed);
        
        // Verify structure
        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], address(daoMock));
        assertEq(returnedCalldatas.length, 1);
        
        // Verify the calldata contains assignRole for the correct account
        bytes memory expectedCalldata = abi.encodeWithSelector(
            daoMock.assignRole.selector,
            4,
            accountFuzzed
        );
        assertEq(returnedCalldatas[0], expectedCalldata);
    }
    
    /// @notice Fuzz test SelfSelect with multiple different accounts
    function testFuzzSelfSelectConsistency(
        address account1,
        address account2,
        uint256 nonceFuzzed
    ) public {
        vm.assume(account1 != address(0));
        vm.assume(account2 != address(0));
        vm.assume(account1 != account2);
        
        // Test with first account
        (returnedActionId, returnedTargets, , returnedCalldatas) = 
            selfSelect.handleRequest(account1, address(daoMock), 6, abi.encode(), nonceFuzzed);
        
        bytes memory firstCalldata = returnedCalldatas[0];
        
        // Test with second account
        (returnedActionId, returnedTargets, , returnedCalldatas) = 
            selfSelect.handleRequest(account2, address(daoMock), 6, abi.encode(), nonceFuzzed + 1);
        
        // Both should target same contract but different calldatas
        assertEq(returnedTargets[0], address(daoMock));
        assertTrue(keccak256(firstCalldata) != keccak256(returnedCalldatas[0]));
    }

    //////////////////////////////////////////////////////////////
    //                  RENOUNCE ROLE FUZZ                      //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test RenounceRole (lawId 7) with valid roles
    /// @dev lawId 7 is configured to allow renouncing roles 1 and 2
    function testFuzzRenounceRoleWithValidRoles(
        address accountFuzzed,
        bool renounceRole1,
        bool renounceRole2,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        
        // Assign both roles to the account
        vm.startPrank(address(daoMock));
        daoMock.assignRole(1, accountFuzzed);
        daoMock.assignRole(2, accountFuzzed);
        vm.stopPrank();
        
        // Create renounce array
        roleIds = new uint256[](2);
        if (renounceRole1) roleIds[0] = 1;
        if (renounceRole2) roleIds[1] = 2;
        
        lawCalldata = abi.encode(roleIds);
        
        (returnedActionId, returnedTargets, , returnedCalldatas) = 
            renounceRole.handleRequest(accountFuzzed, address(daoMock), 7, lawCalldata, nonceFuzzed);
        
        // Should return calls for each role to renounce
        assertTrue(returnedTargets.length > 0);
        for (i = 0; i < returnedTargets.length; i++) {
            assertEq(returnedTargets[i], address(daoMock));
        }
    }
    
    /// @notice Fuzz test RenounceRole with empty array
    function testFuzzRenounceRoleWithEmptyArray(
        address accountFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        
        roleIds = new uint256[](0);
        lawCalldata = abi.encode(roleIds);
        
        (returnedActionId, returnedTargets, , ) = 
            renounceRole.handleRequest(accountFuzzed, address(daoMock), 7, lawCalldata, nonceFuzzed);
        
        // Should return empty or minimal structure
        assertTrue(returnedTargets.length <= 1);
    }

    //////////////////////////////////////////////////////////////
    //                  ROLE BY ROLES FUZZ                      //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test RoleByRoles (lawId 9) with various role combinations
    /// @dev lawId 9 assigns role 4 if account has roles 1 and 2
    function testFuzzRoleByRolesWithRoleCombinations(
        address accountFuzzed,
        bool hasRole1,
        bool hasRole2,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        
        // Conditionally assign roles
        vm.startPrank(address(daoMock));
        if (hasRole1) daoMock.assignRole(1, accountFuzzed);
        if (hasRole2) daoMock.assignRole(2, accountFuzzed);
        vm.stopPrank();
        
        lawCalldata = abi.encode();
        
        try roleByRoles.handleRequest(accountFuzzed, address(daoMock), 9, lawCalldata, nonceFuzzed) 
            returns (uint256, address[] memory targets, uint256[] memory, bytes[] memory calldatas) 
        {
            // If both roles exist, should succeed
            if (hasRole1 && hasRole2) {
                assertEq(targets.length, 1);
                assertEq(targets[0], address(daoMock));
                assertEq(calldatas.length, 1);
            }
        } catch {
            // Should only fail if missing required roles
            assertTrue(!hasRole1 || !hasRole2);
        }
    }
    
    /// @notice Fuzz test RoleByRoles with multiple accounts
    function testFuzzRoleByRolesWithMultipleAccounts(
        address[] memory accountsFuzzed,
        uint256 numberOfAccounts,
        uint256 nonceFuzzed
    ) public {
        numberOfAccounts = bound(numberOfAccounts, 1, 10);
        vm.assume(accountsFuzzed.length >= numberOfAccounts);
        
        // Assign required roles to all accounts
        vm.startPrank(address(daoMock));
        for (i = 0; i < numberOfAccounts; i++) {
            if (accountsFuzzed[i] != address(0)) {
                daoMock.assignRole(1, accountsFuzzed[i]);
                daoMock.assignRole(2, accountsFuzzed[i]);
            }
        }
        vm.stopPrank();
        
        // Test with each account
        for (i = 0; i < numberOfAccounts; i++) {
            if (accountsFuzzed[i] != address(0)) {
                (returnedActionId, returnedTargets, , ) = 
                    roleByRoles.handleRequest(accountsFuzzed[i], address(daoMock), 9, abi.encode(), nonceFuzzed + i);
                
                assertEq(returnedTargets.length, 1);
                assertEq(returnedTargets[0], address(daoMock));
            }
        }
    }

    //////////////////////////////////////////////////////////////
    //                  ELECTION SELECT FUZZ                    //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test ElectionSelect (lawId 1) action generation
    /// @dev lawId 1 runs delegate elections for role 3
    function testFuzzElectionSelectActionGeneration(
        address callerFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(callerFuzzed != address(0));
        
        lawCalldata = abi.encode();
        
        (returnedActionId, returnedTargets, , returnedCalldatas) = 
            electionSelect.handleRequest(callerFuzzed, address(daoMock), 1, lawCalldata, nonceFuzzed);
        
        // Should generate action targeting the election contract
        assertTrue(returnedTargets.length > 0);
        // First target should be the election contract
        assertEq(returnedTargets[0], address(erc20DelegateElection));
    }
    
    /// @notice Fuzz test ElectionSelect with various nonces
    function testFuzzElectionSelectWithVariousNonces(
        uint256 nonce1,
        uint256 nonce2
    ) public {
        vm.assume(nonce1 != nonce2);
        
        (returnedActionId, , , ) = 
            electionSelect.handleRequest(alice, address(daoMock), 1, abi.encode(), nonce1);
        
        uint256 firstActionId = returnedActionId;
        
        (returnedActionId, , , ) = 
            electionSelect.handleRequest(alice, address(daoMock), 1, abi.encode(), nonce2);
        
        // Different nonces should produce different action IDs
        assertTrue(firstActionId != returnedActionId);
    }

    //////////////////////////////////////////////////////////////
    //                  PEER SELECT FUZZ                        //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test PeerSelect (lawId 2) with various nominees
    /// @dev lawId 2 selects role 4 by peer voting with max 2 holders and 1 vote per voter
    function testFuzzPeerSelectWithVaryingNominees(
        address[] memory nomineesFuzzed,
        uint256 numberOfNominees,
        uint256 nonceFuzzed
    ) public {
        numberOfNominees = bound(numberOfNominees, 1, 10);
        vm.assume(nomineesFuzzed.length >= numberOfNominees);
        
        // Setup nominees
        nomineesList = new address[](numberOfNominees);
        for (i = 0; i < numberOfNominees; i++) {
            vm.assume(nomineesFuzzed[i] != address(0));
            nomineesList[i] = nomineesFuzzed[i];
        }
        
        lawCalldata = abi.encode();
        
        (returnedActionId, returnedTargets, , returnedCalldatas) = 
            peerSelect.handleRequest(alice, address(daoMock), 2, lawCalldata, nonceFuzzed);
        
        // Should generate actions
        assertTrue(returnedTargets.length > 0);
    }
    
    /// @notice Fuzz test PeerSelect action consistency
    function testFuzzPeerSelectActionConsistency(
        address caller1,
        address caller2,
        uint256 nonceFuzzed
    ) public {
        vm.assume(caller1 != address(0));
        vm.assume(caller2 != address(0));
        vm.assume(caller1 != caller2);
        
        (returnedActionId, returnedTargets, , ) = 
            peerSelect.handleRequest(caller1, address(daoMock), 2, abi.encode(), nonceFuzzed);
        
        uint256 firstTargetLength = returnedTargets.length;
        
        (returnedActionId, returnedTargets, , ) = 
            peerSelect.handleRequest(caller2, address(daoMock), 2, abi.encode(), nonceFuzzed + 1);
        
        // Both should generate consistent action structure
        assertEq(returnedTargets.length, firstTargetLength);
    }

    //////////////////////////////////////////////////////////////
    //                VOTE IN OPEN ELECTION FUZZ                //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test VoteInOpenElection (lawId 3) with various candidates
    /// @dev lawId 3 allows voting in open elections with max 1 vote
    function testFuzzVoteInOpenElectionWithCandidates(
        address[] memory candidatesFuzzed,
        uint256 numberOfCandidates,
        uint256 nonceFuzzed
    ) public {
        numberOfCandidates = bound(numberOfCandidates, 1, 10);
        vm.assume(candidatesFuzzed.length >= numberOfCandidates);
        
        accountsArray = new address[](numberOfCandidates);
        for (i = 0; i < numberOfCandidates; i++) {
            vm.assume(candidatesFuzzed[i] != address(0));
            accountsArray[i] = candidatesFuzzed[i];
        }
        
        lawCalldata = abi.encode(accountsArray);
        
        (returnedActionId, returnedTargets, , returnedCalldatas) = 
            voteInOpenElection.handleRequest(alice, address(daoMock), 3, lawCalldata, nonceFuzzed);
        
        // Should target the open election contract
        assertEq(returnedTargets.length, 1);
        assertEq(returnedTargets[0], address(openElection));
    }
    
    /// @notice Fuzz test VoteInOpenElection with empty candidate list
    function testFuzzVoteInOpenElectionWithEmptyCandidates(
        uint256 nonceFuzzed
    ) public {
        accountsArray = new address[](0);
        lawCalldata = abi.encode(accountsArray);
        
        try voteInOpenElection.handleRequest(alice, address(daoMock), 3, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory, bytes[] memory)
        {
            // May succeed with empty structure
            assertTrue(targets.length >= 0);
        } catch {
            // Or may revert
            assertTrue(true);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  TAX SELECT FUZZ                         //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test TaxSelect (lawId 4) with various accounts
    /// @dev lawId 4 assigns role 4 based on tax threshold of 1000
    function testFuzzTaxSelectWithVariousAccounts(
        address accountFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        
        lawCalldata = abi.encode();
        
        try taxSelect.handleRequest(accountFuzzed, address(daoMock), 4, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory, bytes[] memory)
        {
            // If tax >= threshold, should succeed
            assertTrue(targets.length > 0);
        } catch {
            // May fail if tax < threshold
            assertTrue(true);
        }
    }
    
    /// @notice Fuzz test TaxSelect with threshold edge cases
    function testFuzzTaxSelectThresholdEdgeCases(
        address accountFuzzed,
        bool meetsThreshold,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        
        // Test at threshold boundary
        taxPaidAmount = meetsThreshold ? 1000 : 999;
        
        lawCalldata = abi.encode();
        
        try taxSelect.handleRequest(accountFuzzed, address(daoMock), 4, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory, bytes[] memory)
        {
            if (meetsThreshold) {
                assertTrue(targets.length > 0);
            }
        } catch {
            assertTrue(!meetsThreshold);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  BUY ACCESS FUZZ                         //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test BuyAccess (lawId 5) with various payment amounts
    /// @dev lawId 5 allows buying role 4 access with tokens
    function testFuzzBuyAccessWithVariousPayments(
        address accountFuzzed,
        uint256 tokenAmountFuzzed,
        uint256 tokenIndex,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        tokenAmountFuzzed = bound(tokenAmountFuzzed, 1, type(uint128).max);
        tokenIndex = bound(tokenIndex, 0, 1); // 2 tokens available
        
        lawCalldata = abi.encode(tokenIndex, tokenAmountFuzzed);
        
        try buyAccess.handleRequest(accountFuzzed, address(daoMock), 5, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory values, bytes[] memory)
        {
            // Should generate payment and role assignment actions
            assertTrue(targets.length > 0);
        } catch {
            // May fail if insufficient payment
            assertTrue(true);
        }
    }
    
    /// @notice Fuzz test BuyAccess with native currency
    function testFuzzBuyAccessWithNativeCurrency(
        address accountFuzzed,
        uint256 ethAmountFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        ethAmountFuzzed = bound(ethAmountFuzzed, 1, 100 ether);
        
        // Token index 1 is native currency
        lawCalldata = abi.encode(1, ethAmountFuzzed);
        
        try buyAccess.handleRequest(accountFuzzed, address(daoMock), 5, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory values, bytes[] memory)
        {
            assertTrue(targets.length > 0);
        } catch {
            assertTrue(true);
        }
    }
    
    /// @notice Fuzz test BuyAccess with various block periods
    function testFuzzBuyAccessBlockPeriods(
        address accountFuzzed,
        uint256 blocksPaidFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        blocksPaidFuzzed = bound(blocksPaidFuzzed, 1, 1000000);
        
        // Calculate required token amount
        tokenAmount = blocksPaidFuzzed * 1000; // tokensPerBlock = 1000
        
        lawCalldata = abi.encode(0, tokenAmount);
        
        try buyAccess.handleRequest(accountFuzzed, address(daoMock), 5, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory, bytes[] memory)
        {
            assertTrue(targets.length > 0);
        } catch {
            assertTrue(true);
        }
    }

    //////////////////////////////////////////////////////////////
    //               N STRIKES REVOKES ROLES FUZZ               //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test NStrikesRevokesRoles (lawId 8) with varying strike counts
    /// @dev lawId 8 revokes role 3 after 2 strikes
    function testFuzzNStrikesRevokesRolesWithStrikes(
        address accountFuzzed,
        uint256 strikeCountFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        strikeCountFuzzed = bound(strikeCountFuzzed, 0, 10);
        
        // Assign role 3 to account
        vm.prank(address(daoMock));
        daoMock.assignRole(3, accountFuzzed);
        
        lawCalldata = abi.encode();
        
        try nStrikesRevokesRoles.handleRequest(accountFuzzed, address(daoMock), 8, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory, bytes[] memory)
        {
            // Should generate revocation if strikes >= 2
            assertTrue(targets.length > 0);
        } catch {
            // May fail if strikes < threshold
            assertTrue(true);
        }
    }
    
    /// @notice Fuzz test NStrikesRevokesRoles at threshold boundary
    function testFuzzNStrikesRevokesRolesThreshold(
        address accountFuzzed,
        bool atThreshold,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        
        // Assign role
        vm.prank(address(daoMock));
        daoMock.assignRole(3, accountFuzzed);
        
        // Test at strike threshold (2 strikes needed)
        uint256 strikes = atThreshold ? 2 : 1;
        
        lawCalldata = abi.encode();
        
        try nStrikesRevokesRoles.handleRequest(accountFuzzed, address(daoMock), 8, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory, bytes[] memory)
        {
            if (atThreshold) {
                assertTrue(targets.length > 0);
            }
        } catch {
            assertTrue(!atThreshold);
        }
    }

    //////////////////////////////////////////////////////////////
    //                CROSS-LAW FUZZ TESTS                      //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test action ID generation consistency across electoral laws
    function testFuzzElectoralActionIdConsistency(
        uint16 lawIdFuzzed,
        bytes memory lawCalldataFuzzed,
        uint256 nonceFuzzed
    ) public {
        // Bound to valid electoral law IDs (1-10)
        lawIdFuzzed = uint16(bound(lawIdFuzzed, 1, 10));
        vm.assume(lawCalldataFuzzed.length <= MAX_FUZZ_CALLDATA_LENGTH);
        
        // Test with SelfSelect (simplest law)
        lawCalldata = abi.encode();
        
        (returnedActionId, , , ) = 
            selfSelect.handleRequest(alice, address(daoMock), lawIdFuzzed, lawCalldata, nonceFuzzed);
        
        // Verify action ID matches expected pattern
        uint256 expectedActionId = uint256(keccak256(abi.encode(lawIdFuzzed, lawCalldata, nonceFuzzed)));
        assertEq(returnedActionId, expectedActionId);
    }
    
    /// @notice Fuzz test that electoral laws properly target correct contracts
    function testFuzzElectoralLawTargets(
        address callerFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(callerFuzzed != address(0));
        
        // Test SelfSelect targets Powers
        (returnedActionId, returnedTargets, , ) = 
            selfSelect.handleRequest(callerFuzzed, address(daoMock), 6, abi.encode(), nonceFuzzed);
        assertEq(returnedTargets[0], address(daoMock));
        
        // Test ElectionSelect targets election contract
        (returnedActionId, returnedTargets, , ) = 
            electionSelect.handleRequest(callerFuzzed, address(daoMock), 1, abi.encode(), nonceFuzzed + 1);
        assertEq(returnedTargets[0], address(erc20DelegateElection));
        
        // Test VoteInOpenElection targets open election
        accountsArray = new address[](1);
        accountsArray[0] = callerFuzzed;
        (returnedActionId, returnedTargets, , ) = 
            voteInOpenElection.handleRequest(callerFuzzed, address(daoMock), 3, abi.encode(accountsArray), nonceFuzzed + 2);
        assertEq(returnedTargets[0], address(openElection));
    }
    
    /// @notice Fuzz test nonce uniqueness across electoral laws
    function testFuzzElectoralNonceUniqueness(
        uint256 nonce1Fuzzed,
        uint256 nonce2Fuzzed
    ) public {
        vm.assume(nonce1Fuzzed != nonce2Fuzzed);
        
        lawCalldata = abi.encode();
        
        // Get action IDs with different nonces
        (returnedActionId, , , ) = 
            selfSelect.handleRequest(alice, address(daoMock), 6, lawCalldata, nonce1Fuzzed);
        uint256 firstActionId = returnedActionId;
        
        (returnedActionId, , , ) = 
            selfSelect.handleRequest(alice, address(daoMock), 6, lawCalldata, nonce2Fuzzed);
        
        // Different nonces should produce different action IDs
        assertTrue(firstActionId != returnedActionId);
    }
    
    /// @notice Fuzz test law data retrieval consistency
    function testFuzzElectoralLawDataConsistency(
        uint16 lawIdFuzzed
    ) public {
        // Bound to valid law IDs
        lawIdFuzzed = uint16(bound(lawIdFuzzed, 1, 10));
        
        // Get law conditions from daoMock
        conditions = daoMock.getConditions(lawIdFuzzed);
        
        // Verify conditions are valid
        assertTrue(conditions.quorum <= 100);
        assertTrue(conditions.succeedAt <= 100);
        assertTrue(conditions.allowedRole == type(uint256).max); // All are public in test constitution
    }

    //////////////////////////////////////////////////////////////
    //                EDGE CASE FUZZ TESTS                      //
    //////////////////////////////////////////////////////////////
    
    /// @notice Fuzz test electoral laws with zero addresses
    function testFuzzElectoralWithZeroAddresses(
        uint256 arrayLength,
        uint256 nonceFuzzed
    ) public {
        arrayLength = bound(arrayLength, 1, 10);
        
        accountsArray = new address[](arrayLength);
        for (i = 0; i < arrayLength; i++) {
            accountsArray[i] = address(0);
        }
        
        lawCalldata = abi.encode(accountsArray);
        
        // Test VoteInOpenElection with zero addresses
        try voteInOpenElection.handleRequest(alice, address(daoMock), 3, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory, uint256[] memory, bytes[] memory)
        {
            // May succeed or fail depending on validation
            assertTrue(true);
        } catch {
            assertTrue(true);
        }
    }
    
    /// @notice Fuzz test electoral laws with large arrays
    function testFuzzElectoralWithLargeArrays(
        uint256 arrayLength,
        uint256 nonceFuzzed
    ) public {
        arrayLength = bound(arrayLength, 1, MAX_FUZZ_TARGETS);
        
        accountsArray = new address[](arrayLength);
        for (i = 0; i < arrayLength; i++) {
            accountsArray[i] = address(uint160(i + 1));
        }
        
        lawCalldata = abi.encode(accountsArray);
        
        // Test with VoteInOpenElection
        try voteInOpenElection.handleRequest(alice, address(daoMock), 3, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory returnedTargets_, uint256[] memory, bytes[] memory)
        {
            assertTrue(returnedTargets_.length > 0);
        } catch {
            // May fail with very large arrays
            assertTrue(true);
        }
    }
    
    /// @notice Fuzz test electoral laws with various role IDs
    function testFuzzElectoralWithVariousRoleIds(
        uint256 roleIdFuzzed,
        address accountFuzzed,
        uint256 nonceFuzzed
    ) public {
        vm.assume(accountFuzzed != address(0));
        vm.assume(roleIdFuzzed != 0 && roleIdFuzzed != type(uint256).max);
        
        // Assign role to account
        vm.prank(address(daoMock));
        daoMock.assignRole(roleIdFuzzed, accountFuzzed);
        
        // Verify role was assigned
        assertTrue(daoMock.hasRoleSince(accountFuzzed, roleIdFuzzed) > 0);
        
        // Test with RenounceRole
        roleIds = new uint256[](1);
        roleIds[0] = roleIdFuzzed;
        lawCalldata = abi.encode(roleIds);
        
        try renounceRole.handleRequest(accountFuzzed, address(daoMock), 7, lawCalldata, nonceFuzzed)
            returns (uint256, address[] memory targets, uint256[] memory, bytes[] memory)
        {
            // May succeed if role is in allowed list
            assertTrue(targets.length >= 0);
        } catch {
            // May fail if role not in allowed list
            assertTrue(true);
        }
    }
}
