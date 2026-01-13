// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { IERC20 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IAllowedTokens {
    function getAllowedTokensCount() external view returns (uint256);
    function getAllowedToken(uint256 index) external view returns (address);
}

contract AllowedTokensPresetTransfer is Mandate {
    struct Mem {
        address receiver;
        address allowedTokens;
        bytes config;
        uint256 count;
        uint256 positiveBalanceCount; 
        address token;
        uint256 balance;
        uint256 currentIndex;
    }
    
    constructor() {
        bytes memory configParams = abi.encode("address receiver", "address allowedTokens");
        emit Mandate__Deployed(configParams);
    }

    function handleRequest(
        address, /*caller*/
        address powers,
        uint16 mandateId,
        bytes memory, /*mandateCalldata*/
        uint256 /*nonce*/
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;
        // 1. Get config
        mem.config = getConfig(powers, mandateId);
        (mem.receiver, mem.allowedTokens) = abi.decode(mem.config, (address, address));

        // 2. Get allowed tokens count
        mem.count = IAllowedTokens(mem.allowedTokens).getAllowedTokensCount();
        // 3. Count tokens with positive balance
        mem.positiveBalanceCount = 0;
        for (uint256 i = 0; i < mem.count; i++) {
            mem.token = IAllowedTokens(mem.allowedTokens).getAllowedToken(i);
            if (IERC20(mem.token).balanceOf(powers) > 0) {
                mem.positiveBalanceCount++;
            }
        }

        // 4. Prepare return data
        targets = new address[](mem.positiveBalanceCount);
        values = new uint256[](mem.positiveBalanceCount);
        calldatas = new bytes[](mem.positiveBalanceCount);

        mem.currentIndex = 0;
        for (uint256 i = 0; i < mem.count; i++) {
            mem.token = IAllowedTokens(mem.allowedTokens).getAllowedToken(i);
            mem.balance = IERC20(mem.token).balanceOf(powers);
            if (mem.balance > 0) {
                targets[mem.currentIndex] = mem.token;
                // values[currentIndex] = 0; // default is 0
                calldatas[mem.currentIndex] = abi.encodeWithSelector(IERC20.transfer.selector, mem.receiver, mem.balance);
                mem.currentIndex++;
            }
        }

        return (actionId, targets, values, calldatas);
    }
}
