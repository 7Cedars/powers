// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AllowedTokens
 * @notice Simple registry of allowed ERC20 tokens managed by the owner
 */
contract AllowedTokens is Ownable {
    mapping(address => bool) private _allowedTokens;

    event TokenAllowed(address indexed token, bool allowed);

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Sets the allowed status of a token
     * @param token The address of the token
     * @param allowed The new status (true for allowed, false for disallowed)
     */
    function setTokenAllowed(address token, bool allowed) external onlyOwner {
        _allowedTokens[token] = allowed;
        emit TokenAllowed(token, allowed);
    }

    /**
     * @notice Checks if a token is allowed
     * @param token The address of the token to check
     * @return bool True if the token is allowed
     */
    function isTokenAllowed(address token) external view returns (bool) {
        return _allowedTokens[token];
    }
}
