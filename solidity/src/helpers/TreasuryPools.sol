// SPDX-License-Identifier: MIT
//////////////////////////////////////////////////////////////////////////////
// This program is free software: you can redistribute it and/or modify    ///
// it under the terms of the MIT Public License.                           ///
//                                                                         ///
// This is a Proof Of Concept and is not intended for production use.      ///
// Tests are incomplete and it contracts have not been audited.            ///
//                                                                         ///
// It is distributed in the hope that it will be useful and insightful,    ///
// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                   ///
//////////////////////////////////////////////////////////////////////////////

// @notice A helper treasury contract with role-based budget pools. Should be owned by a Powers protocol to provide RBAC governance.
// @author 7Cedars,
pragma solidity 0.8.26;
 
import { TreasurySimple } from "./TreasurySimple.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TreasuryPools is TreasurySimple {
    struct Pool {
        address tokenAddress;
        uint256 budget;
    }

    uint256 public poolCount;
    mapping(uint256 => Pool) public pools;
    mapping(address => uint256) public totalAllocatedBudgets;

    event PoolCreated(uint256 indexed poolId, address indexed tokenAddress, uint256 budget);
    event BudgetIncreased(uint256 indexed poolId, uint256 amount);
    event PoolDeleted(uint256 indexed poolId);
    event Transferred(uint256 indexed poolId, address indexed to, uint256 amount);

    function deposit(address _token, uint256 _amount) public override {
        super.deposit(_token, _amount);
    }

 
    function transfer(uint256 _poolId, address payable _to, uint256 _amount) public onlyOwner {
        // Note: This function assumes an external mechanism for role-based access control, as included in the Powers protocol.
        Pool storage pool = pools[_poolId];
        require(pool.tokenAddress != address(0) || pool.budget > 0, "POOL_DELETED");
        require(_amount <= pool.budget, "AMOUNT_EXCEEDS_BUDGET");

        pool.budget -= _amount;

        super.transfer(pool.tokenAddress, _to, _amount);

        emit Transferred(_poolId, _to, _amount);
    }

    function createPool(address _tokenAddress, uint256 _initialBudget) external onlyOwner returns (uint256 poolId) {
        uint256 currentBalance = getBalance(_tokenAddress);
        require(totalAllocatedBudgets[_tokenAddress] + _initialBudget <= currentBalance, "BUDGET_EXCEEDS_BALANCE");
        
        poolCount++;
        pools[poolCount] = Pool(_tokenAddress, _initialBudget);
        totalAllocatedBudgets[_tokenAddress] += _initialBudget;

        emit PoolCreated(poolCount, _tokenAddress, _initialBudget);
        return poolCount;
    }

    function increaseBudget(uint256 _poolId, uint256 _amount) external onlyOwner {
        Pool storage pool = pools[_poolId];
        require(pool.tokenAddress != address(0) || pool.budget > 0, "POOL_DELETED");

        uint256 currentBalance = getBalance(pool.tokenAddress);
        require(totalAllocatedBudgets[pool.tokenAddress] + _amount <= currentBalance, "BUDGET_EXCEEDS_BALANCE");

        pool.budget += _amount;
        totalAllocatedBudgets[pool.tokenAddress] += _amount;

        emit BudgetIncreased(_poolId, _amount);
    }

    function deletePool(uint256 _poolId) external onlyOwner {
        Pool storage pool = pools[_poolId];
        require(pool.tokenAddress != address(0) || pool.budget > 0, "POOL_DELETED");

        totalAllocatedBudgets[pool.tokenAddress] -= pool.budget;
        delete pools[_poolId];

        emit PoolDeleted(_poolId);
    }

    function getPool(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }
}
