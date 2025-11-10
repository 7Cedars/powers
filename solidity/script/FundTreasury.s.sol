// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
// core protocol
import { Powers } from "../src/Powers.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { TreasuryPools } from "../src/helpers/TreasuryPools.sol";
import { Erc20Taxed } from "../test/mocks/Erc20Taxed.sol";
import { SimpleErc20Votes } from "../test/mocks/SimpleErc20Votes.sol";

// @dev Very simple script to fund the TreasuryPools contract with some ETH and ERC20 tokens for testing purposes.
// all addresses are hardcoded for the sepolia testnet deployment.
// I can make this dynamic using config files later if needed.
contract FundTreasury is Script {
    TreasuryPools treasuryPools;
    Erc20Taxed erc20Taxed;
    SimpleErc20Votes erc20Votes;

    function run() external returns (uint256 receiptId){
            uint256 fundAmount = 1 ether / 2; // amount to fund = half an ether. 
            treasuryPools = TreasuryPools(payable(0x5C6a6dAB2C054821A938de7D80A64Cc30F731FDa));
            erc20Taxed = Erc20Taxed(0x987F3Ac339F083061A6169021706A20842503283);
            erc20Votes = SimpleErc20Votes(0xd22b61aE36427e66a7f9Bb2D9b13573BC598a231);
            
            // Execute Funding calls to treasury
            vm.startBroadcast();  
            (receiptId) = treasuryPools.depositNative{value: 1 ether}();
            // (bool success,) = address(treasuryPools).call{value: fundAmount}("");
            erc20Taxed.faucet();
            erc20Taxed.transfer(address(treasuryPools), fundAmount);

            erc20Votes.mintVotes(1 ether);
            erc20Votes.transfer(address(treasuryPools), fundAmount);

            vm.stopBroadcast(); 
    }
}
