// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TreasurySimple is Ownable {
    using SafeERC20 for IERC20;
    
    struct TransferLog {
        address from;
        address token;
        uint256 amount;
        uint256 blockNumber;
    }

    TransferLog[] public transfers;
    uint256 public transferCount;
    mapping(address => bool) public whitelistedTokens;

    event Deposited(address indexed from, address indexed token, uint256 amount);
    event Transferred(address indexed to, address indexed token, uint256 amount);

    constructor() Ownable(msg.sender) {
        whitelistedTokens[address(0)] = true;
    }

    function setWhitelist(address _token, bool _isWhitelisted) external onlyOwner {
        whitelistedTokens[_token] = _isWhitelisted;
    }

    receive() external payable {
        _depositNative();
    }

    function deposit(address _token, uint256 _amount) public virtual returns (uint256 receiptId) {
        require(whitelistedTokens[_token], "TOKEN_NOT_WHITELISTED");
        require(_token != address(0), "INVALID_TOKEN");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        transfers.push(TransferLog(msg.sender, _token, _amount, block.number));
        receiptId = transferCount;
        transferCount++;
        emit Deposited(msg.sender, _token, _amount);
    }

    function depositNative() external payable returns (uint256 receiptId) {
        receiptId = _depositNative();
    }

    function _depositNative() internal returns (uint256 receiptId) {
        transfers.push(TransferLog(msg.sender, address(0), msg.value, block.number));
        receiptId = transferCount;
        transferCount++;
        emit Deposited(msg.sender, address(0), msg.value);
    }

    function transfer(address _token, address payable _to, uint256 _amount) public virtual onlyOwner {
        require(_to != address(0), "INVALID_RECIPIENT");
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "INSUFFICIENT_NATIVE_BALANCE");
            _to.transfer(_amount);
        } else {
            require(IERC20(_token).balanceOf(address(this)) >= _amount, "INSUFFICIENT_TOKEN_BALANCE");
            IERC20(_token).safeTransfer(_to, _amount);
        }
        emit Transferred(_to, _token, _amount);
    }

    function getBalance(address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(_token).balanceOf(address(this));
        }
    }

    function getTransfer(uint256 _index) external view returns (TransferLog memory) {
        return transfers[_index];
    }
}
