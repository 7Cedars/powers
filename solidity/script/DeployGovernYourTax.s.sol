// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// core protocol
import { Powers} from "../src/Powers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

// laws
import { NominateMe } from "../src/laws/state/NominateMe.sol"; 
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { ElectionTally } from "../src/laws/electoral/ElectionTally.sol";
import { ElectionCall } from "../src/laws/electoral/ElectionCall.sol";
import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";
import { Grant } from "../src/laws/bespoke/governYourTax/Grant.sol";
import { StartGrant } from "../src/laws/bespoke/governYourTax/StartGrant.sol";
import { StopGrant } from "../src/laws/bespoke/governYourTax/StopGrant.sol";
import { SelfDestructAction } from "../src/laws/executive/SelfDestructAction.sol";
import { RoleByTaxPaid } from "../src/laws/bespoke/governYourTax/RoleByTaxPaid.sol";
import { AssignCouncilRole } from "../src/laws/bespoke/governYourTax/AssignCouncilRole.sol";
// borrowing one law from another bespoke folder. Not ideal, but ok for now.
import { NftSelfSelect } from "../src/laws/bespoke/alignedDao/NftSelfSelect.sol";

// mocks 
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../test/mocks/Erc20TaxedMock.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";

contract DeployGovernYourTax is Script {
    address[] laws;

    function run()
        external
        returns (
            address payable dao, 
            address[] memory constituentLaws, 
            HelperConfig.NetworkConfig memory config, 
            address payable mock20Taxed_
            )
    {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfigByChainId(block.chainid);

        vm.startBroadcast();
        Powers powers = new Powers(
            "Govern Your Tax", 
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibcd4k5jmq3zpydwclgdmf3f2pkej24wlm5ufmq6x6t6yptdnubqm");
        Erc20TaxedMock erc20TaxedMock = new Erc20TaxedMock(
            10, // rate
            100, // denominator  
            25 // 7% tax, (tax = 7, denominator = 2),  25 block epoch, about 5 minutes. 
        );
        vm.stopBroadcast();

        dao = payable(address(powers));
        mock20Taxed_ = payable(address(erc20TaxedMock)); 
        initiateConstitution(dao, mock20Taxed_);

        // // constitute dao.
        vm.startBroadcast();
        powers.constitute(laws);
        // // transferring ownership of erc721 and erc20Taxed token contracts.. 
        erc20TaxedMock.transferOwnership(address(powers));
        vm.stopBroadcast();

        return (dao, laws, config, mock20Taxed_);
    }

    function initiateConstitution(
        address payable dao_,
        address payable mock20Taxed_
    ) public {
        Law law;
        ILaw.LawConfig memory lawConfig;

        //////////////////////////////////////////////////////////////
        //              CHAPTER 1: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////
        // laws[0]
        lawConfig.quorum = 60; // = 60% quorum needed
        lawConfig.succeedAt = 50; // = Simple majority vote needed.
        lawConfig.votingPeriod = 25; // = number of blocks (about half an hour) 
        // setting up params
        string[] memory inputParams = new string[](3);
        inputParams[0] = "address To"; // grantee
        inputParams[1] = "address Grant"; // grant Law address
        inputParams[2] = "uint256 Quantity"; // amount
        // initiating law.
        vm.startBroadcast();
        // Note: the grant has its token pre specified.
        law = new ProposalOnly(
            "Make a grant proposal.",
            "Make a grant proposal that will be voted on by community members. If successful, the 'quantity' of tokens held by the Grant will be sent to the 'to' address.",
            dao_,
            1, // access role
            lawConfig,
            inputParams // input parameters
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[1]
        lawConfig.quorum = 80; // = 80% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 25; // = number of blocks (about half an hour) 
        // initiating law
        vm.startBroadcast();
        law = new StartGrant(
            "Start a grant program", // max 31 chars
            "Subject to a vote, a grant program can be created. In this case, roleIds for the grant councils are 4, 5 or 6. The token, budget and duration need to be specified, as well as the roleId (of the grant council) that will govern the grant.",
            dao_, // separated powers
            2, // access role
            lawConfig, // bespoke configs for this law.
            laws[0] // law from where proposals need to be made.
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[2]
        lawConfig.needCompleted = laws[1]; // needs the exact grant to have been completed. 
        // initiating law
        vm.startBroadcast();
        law = new StopGrant(
            "Stop a grant program", // max 31 chars
            "When a grant program's budget is spent, or the grant is expired, it can be stopped. This can only be done with the exact same data used when creating the grant.",
            dao_, // separated powers
            2, // access role
            lawConfig // bespoke configs for this law.
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[3]
        lawConfig.quorum = 40; // = 40% quorum needed
        lawConfig.succeedAt = 80; // =  80 majority needed
        lawConfig.votingPeriod = 25; // = number of blocks (about half an hour) 
        // input params
        inputParams = new string[](1);
        inputParams[0] = "address Law";
        // initiating law.
        vm.startBroadcast();
        law = new BespokeAction(
            "Stop law",
            "The security council can stop any active law. This means that any grant program or council can be stopped if needed.",
            dao_, // separated powers
            3, // access role
            lawConfig, // bespoke configs for this law
            dao_,
            Powers.revokeLaw.selector,
            inputParams
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[4]
        lawConfig.quorum = 50; // = 50% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 25; // = number of blocks (about half an hour) 
        lawConfig.needCompleted = laws[3]; // NB! first a law needs to be stopped before it can be restarted!
        // This does mean that the reason given needs to be the same as when the law was stopped.
        // initiating law.
        vm.startBroadcast();
        law = new BespokeAction(
            "Restart law",
            "The security council can restart a law. They can only restart a law that they themselves stopped.",
            dao_, // separated powers
            3, // access role
            lawConfig, // bespoke configs for this law
            dao_,
            Powers.adoptLaw.selector,
            inputParams // note: same inputParams as laws [2]
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[5]
        // mint tokens 
        lawConfig.quorum = 67; // = two-thirds quorum needed
        lawConfig.succeedAt = 67; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 25; // = number of blocks (about half an hour) 
        // bespoke inputParams 
        inputParams = new string[](1);
        inputParams[0] = "uint256 Quantity"; // number of tokens to mint. 
        vm.startBroadcast();
        law = new BespokeAction(
            "Mint tokens",
            "Governors can decide to mint tokens.",
            dao_, // separated powers
            2, // access role
            lawConfig, // bespoke configs for this law
            mock20Taxed_,
            Erc20TaxedMock.mint.selector,
            inputParams  
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[6]
        // burn token 
        vm.startBroadcast();
        law = new BespokeAction(
            "Burn tokens",
            "Governors can decide to burn tokens.",
            dao_, // separated powers
            2, // access role
            lawConfig, // same lawConfig as laws[5] 
            mock20Taxed_,
            Erc20TaxedMock.burn.selector,
            inputParams // same lawConfig as laws[5]
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig; // here we delete lawConfig. 

        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////
        // laws[7]
        vm.startBroadcast();
        law = new RoleByTaxPaid(
            "Claim community membership", // max 31 chars
            string.concat(
                "Anyone who has paid sufficient tax (by using the Dao's ERC20 token @", 
                Strings.toHexString(uint256(addressToInt(mock20Taxed_)), 20), 
                ") can become a community member. The threshold is 100MCK tokens per 150 blocks. Tax rate is 10 percent(!) on each transaction and tokens can be minted at the contract's faucet function."
                ),
            dao_,
            type(uint32).max, // access role = public access
            lawConfig,
            1, // role id
            mock20Taxed_,
            100 // have to see if this is a fair amount.
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[8]
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate self for Governor", // max 31 chars
            "Anyone can nominate themselves for a governor role.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[9]
        lawConfig.readStateFrom = laws[8]; // =  nominees law. 
        vm.startBroadcast();
        law = new ElectionCall(
            "Call governor election", // max 31 chars
            "Any member of the security council can create a governor election. Calling the law creates an election contract at which people can vote on nominees between the start and end block of the election.",
            dao_, // separated powers protocol.
            3, // = role security council 
            lawConfig, //  config file.
            // bespoke configs for this law:
            1, // role id that is allowed to vote.
            2, // role id that is being elected
            3  // max role holders
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[10]
        lawConfig.needCompleted = laws[9]; // = electionCall law. 
        vm.startBroadcast();
        law = new ElectionTally(
            "Tally governor elections", // max 31 chars
            "Count votes of a governor election. Any community member can call this law and pay for tallying the votes. The nominated accounts with most votes from community members are assigned as governors",
            dao_, // separated powers protocol.
            1, // Note: any community member can tally the election. It can only be done after election duration has finished.
            lawConfig //  config file.
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[11]
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate for Security Council", // max 31 chars
            "Nominate yourself for a position in the security council.",
            dao_,
            1, // access role = 1
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[12]: security council: peer select. - role 3
        lawConfig.quorum = 66; // = Two thirds quorum needed to pass the proposal
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 25; // = number of blocks (about half an hour) 
        lawConfig.readStateFrom = laws[11]; // nominateMe
        //
        vm.startBroadcast();
        law = new PeerSelect(
            "Assign/Revoke Sec. Councillors", // max 31 chars
            "Security Council members are assigned or revoked by their peers through a majority vote.",
            dao_, // separated powers protocol.
            3, // role 3 id designation.
            lawConfig, //  config file.
            3, // maximum elected to role 
            3 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[13]:nominate self for grant council role.  
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate for a Grant Council", // max 31 chars
            "Any community member can nominate themselves to become part of a grant council.",
            dao_, // separated powers protocol.
            1, // community member
            lawConfig 
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[14]: assign members to grant councils.  
        uint32[] memory allowedRoles = new uint32[](3);
        allowedRoles[0] = 4; // Grant Council A
        allowedRoles[1] = 5; // Grant Council B
        allowedRoles[2] = 6; // Grant Council C
        //
        lawConfig.quorum = 51; // = Two thirds quorum needed to pass the proposal
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 25; // = duration in number of blocks to vote, about half an hour.
        lawConfig.readStateFrom = laws[13]; // NominateMe
        vm.startBroadcast();
        law = new AssignCouncilRole(
            "Assign grant council roles", // max 31 chars
            "Governors assign accounts to grant councils by a majority vote.",
            dao_, // separated powers protocol.
            2, // governors assign roles.
            lawConfig, //  config file.
            allowedRoles
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[15]: SelfDestructAction: assign initial accounts to security council.
        address[] memory targets = new address[](8);
        uint256[] memory values = new uint256[](8);
        bytes[] memory calldatas = new bytes[](8);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }
        calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, 3, 0x328735d26e5Ada93610F0006c32abE2278c46211);
        calldatas[1] = abi.encodeWithSelector(Powers.assignRole.selector, 1, 0x328735d26e5Ada93610F0006c32abE2278c46211);
        calldatas[2] = abi.encodeWithSelector(Powers.labelRole.selector, 1, "Member");
        calldatas[3] = abi.encodeWithSelector(Powers.labelRole.selector, 2, "Governor");
        calldatas[4] = abi.encodeWithSelector(Powers.labelRole.selector, 3, "Security Council");
        calldatas[5] = abi.encodeWithSelector(Powers.labelRole.selector, 4, "Grant Council #4");
        calldatas[6] = abi.encodeWithSelector(Powers.labelRole.selector, 5, "Grant Council #5");
        calldatas[7] = abi.encodeWithSelector(Powers.labelRole.selector, 6, "Grant Council #6");
 
        vm.startBroadcast();
        law = new SelfDestructAction(
            "Set initial roles and labels", // max 31 chars
            "The admin selects an initial account for the security council. The Admin also assigns labels to roles. The law self destructs when executed.",
            dao_, // separated powers protocol.
            0, // admin.
            lawConfig, //  config file.
            targets,
            values,
            calldatas
        );
        vm.stopBroadcast();
        laws.push(address(law));
    }

    ///////////////////////////////////////////////////////
    //                  Helper functions                //
    //////////////////////////////////////////////////////
    function addressToInt(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }
}
