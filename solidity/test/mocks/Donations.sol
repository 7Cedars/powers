// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { console2 } from "forge-std/console2.sol";

/// @title Donations - Standalone Donation Management Contract
/// @notice Allows users to donate ERC20 tokens or native currency to the contract owner
/// @dev All state-changing functions are restricted to the contract owner
/// @author 7Cedars
contract Donations is Ownable, ReentrancyGuard {
    /// @notice Structure to store donation information
    struct Donation {
        address donor;          // Address of the donor
        address token;          // Token address (address(0) for native currency)
        uint256 amount;         // Amount donated
        uint256 blockNumber;    // Block number when donation was made
    }

    /// @notice Mapping to track whitelisted tokens
    mapping(address => bool) public whitelistedTokens;
    
    /// @notice Array to store all donations
    Donation[] public donations;
    /// @notice Mapping to track donations by donor address
    mapping(address => uint256[]) public donorDonations;

    /// @notice Events
    event TokenWhitelisted(address indexed token, bool whitelisted);
    event DonationReceived(
        address indexed donor,
        address indexed token,
        uint256 amount,
        uint256 donationIndex
    );
    event NativeCurrencyReceived(address indexed donor, uint256 amount);

    /// @notice Constructor sets the owner
    constructor() Ownable(msg.sender) {}

    receive() external payable {
        if(!whitelistedTokens[address(0)]) revert("Native currency not whitelisted");
        if(msg.value == 0) revert("Amount must be greater than 0");

        // Transfer native currency to contract owner
        console2.log("Transferring native currency to contract owner");
        console2.log("Owner:", owner());
        console2.log("Value:", msg.value);
        
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        if(!success) revert("Native currency transfer failed");

        // Record the donation
        _recordDonation(msg.sender, address(0), msg.value);
        
        emit NativeCurrencyReceived(msg.sender, msg.value);
    }

    /// @notice Whitelist or remove a token from the whitelist
    /// @param token The token address to whitelist/remove (address(0) for native currency)
    /// @param whitelisted Whether to whitelist or remove the token
    function setWhitelistedToken(address token, bool whitelisted) external onlyOwner {
        whitelistedTokens[token] = whitelisted;
        emit TokenWhitelisted(token, whitelisted);
    }

    /// @notice Donate ERC20 tokens to the contract owner
    /// @param token The token address to donate
    /// @param amount The amount of tokens to donate
    function donateToken(address token, uint256 amount) external nonReentrant {
        if(!whitelistedTokens[token]) revert("Token not whitelisted");
        if(amount == 0) revert("Amount must be greater than 0");
        if(token == address(0)) revert("Use donateNative() for native currency");

        // Transfer tokens from donor to contract owner
        IERC20(token).transferFrom(msg.sender, owner(), amount);

        // Record the donation
        _recordDonation(msg.sender, token, amount);
    }


    /// @notice Internal function to record a donation
    /// @param donor The address of the donor
    /// @param token The token address (address(0) for native currency)
    /// @param amount The amount donated
    function _recordDonation(address donor, address token, uint256 amount) internal {
        Donation memory donation = Donation({
            donor: donor,
            token: token,
            amount: amount,
            blockNumber: block.number
        });

        donations.push(donation);
        donorDonations[donor].push(donations.length - 1);

        emit DonationReceived(donor, token, amount, donations.length - 1);
    }

    /// @notice Get all donations
    /// @return Array of all donations
    function getAllDonations() external view returns (Donation[] memory) {
        return donations;
    }

    /// @notice Get donations by a specific donor
    /// @param donor The donor address
    /// @return Array of donation indices for the donor
    function getDonorDonations(address donor) external view returns (uint256[] memory) {
        return donorDonations[donor];
    }

    /// @notice Get donation details by index
    /// @param index The donation index
    /// @return Donation details
    function getDonation(uint256 index) external view returns (Donation memory) {
        if(index >= donations.length) revert("Donation index out of bounds");
        return donations[index];
    }

    /// @notice Get total number of donations
    /// @return Total number of donations
    function getTotalDonations() external view returns (uint256) {
        return donations.length;
    }

    /// @notice Get donations in a range
    /// @param startIndex Starting index (inclusive)
    /// @param endIndex Ending index (exclusive)
    /// @return Array of donations in the specified range
    function getDonationsRange(uint256 startIndex, uint256 endIndex) 
        external 
        view 
        returns (Donation[] memory) 
    {
        if(startIndex >= endIndex) revert("Invalid range");
        if(startIndex >= donations.length) revert("Start index out of bounds");
        if(endIndex > donations.length) revert("End index out of bounds");
        
        Donation[] memory result = new Donation[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = donations[i];
        }
        return result;
    }

    /// @notice Get total amount donated for a specific token
    /// @param token The token address (address(0) for native currency)
    /// @return Total amount donated for the token
    function getTotalDonatedForToken(address token) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            if (donations[i].token == token) {
                total += donations[i].amount;
            }
        }
        return total;
    }

    /// @notice Check if a token is whitelisted
    /// @param token The token address to check
    /// @return Whether the token is whitelisted
    function isTokenWhitelisted(address token) external view returns (bool) {
        return whitelistedTokens[token];
    }

    /// @notice Emergency function to withdraw any accidentally sent tokens
    /// @param token The token address to withdraw (address(0) for native currency)
    function emergencyWithdraw(address token) external onlyOwner {
        if (token == address(0)) {
            // Withdraw native currency
            uint256 balance = address(this).balance;
            if (balance > 0) {
                (bool success, ) = payable(owner()).call{value: balance}("");
                if(!success) revert("Native currency withdrawal failed");
            }
        } else {
            // Withdraw ERC20 tokens
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).transfer(owner(), balance);
            }
        }
    }
}
