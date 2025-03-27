// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract Erc20VotesMock is ERC20Votes {
    error Erc20VotesMock__NoZeroAmount();
    error Erc20VotesMock__AmountExceedsMax(uint256 amount, uint256 maxAmount);

    uint256 constant MAX_AMOUNT_VOTES_TO_MINT = 100 * 10 ** 18;

    constructor() ERC20("mock", "MOCK") EIP712("mock", "0.1") {
        _mint(msg.sender, 1 * 10 ** 18); // start with one million tokens for DAO.
    }

    // a public non-restricted function that allows anyone to mint coins. Only restricted by max allowed coins to mint.
    function mintVotes(uint256 amount) public {
        if (amount == 0) {
            revert Erc20VotesMock__NoZeroAmount();
        }
        if (amount > MAX_AMOUNT_VOTES_TO_MINT) {
            revert Erc20VotesMock__AmountExceedsMax(amount, MAX_AMOUNT_VOTES_TO_MINT);
        }
        _mint(msg.sender, amount);
    }
}
