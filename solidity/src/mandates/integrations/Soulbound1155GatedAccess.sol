// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { IPowers } from "../../interfaces/IPowers.sol"; 
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";

/**
 * @title Soulbound1155GatedAccess
 * @notice Mandate to gate access to a role based on Soulbound1155 tokens.
 * @dev Integrates with Soulbound1155.sol to create flexible gated access to roleId in Powers organisations.
 */
contract Soulbound1155GatedAccess is Mandate {
    using Strings for uint256;

    struct Mem {
        bytes config;
        address soulbound1155Address;
        uint256 roleId;
        uint48 blocksThreshold;
        uint48 tokensThreshold;
        uint256 i; 
        uint256[] tokenIds; 
        uint256 tokenId;
        uint256 actionId;
        address minter;
        uint48 mintBlock;
    }

    error Soulbound1155GatedAccess__InsufficientTokens();
    error Soulbound1155GatedAccess__NotOwnerOfToken(uint256 tokenId);
    error Soulbound1155GatedAccess__TokenNotFromParent(uint256 tokenId);
    error Soulbound1155GatedAccess__TokenExpiredOrInvalid(uint256 tokenId);

    constructor() {
        bytes memory configParams = abi.encode(
            "address soulbound1155",
            "uint256 roleId",
            "uint48 blocksThreshold",
            "uint48 tokensThreshold"
        );
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        string[] memory params = new string[](1);
        params[0] = "uint256[] tokenIds"; 
        
        super.initializeMandate(index, nameDescription, abi.encode(params), config);
    }

    function handleRequest(
        address caller,
        address powers,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;
        actionId = MandateUtilities.computeActionId(mandateId, mandateCalldata, nonce);

        // 1. Get config
        mem.config = getConfig(powers, mandateId);
        (mem.soulbound1155Address, mem.roleId, mem.blocksThreshold, mem.tokensThreshold) = 
            abi.decode(mem.config, (address, uint256, uint48, uint48));

        // 2. Decode input params
        mem.tokenIds = abi.decode(mandateCalldata, (uint256[]));

        // Check 0: checks if number of tokens is > tokensThreshold
        if (mem.tokenIds.length <= mem.tokensThreshold) {
            revert Soulbound1155GatedAccess__InsufficientTokens();
        }

        IERC1155 sb1155 = IERC1155(mem.soulbound1155Address);

        for (mem.i = 0; mem.i < mem.tokenIds.length; mem.i++) {
            mem.tokenId = mem.tokenIds[mem.i];

            // Check 1: checks if caller balance of tokenIds is > 0
            // Check 2: if not on one of tokens, reverts (with tokenId provided)
            if (sb1155.balanceOf(caller, mem.tokenId) == 0) {
                revert Soulbound1155GatedAccess__NotOwnerOfToken(mem.tokenId);
            }

            // Check 3: If passes, check if tokens are all from parent Powers org. If not, revert (with tokenId provided)
            // tokenId encodes minter address in high bits
            mem.minter = address(uint160(mem.tokenId >> 48));
            if (mem.minter != powers) {
                revert Soulbound1155GatedAccess__TokenNotFromParent(mem.tokenId);
            }

            // Check 4: If passes, check if tokens are within block threshold. If not, revert (with tokenId provided)
            // tokenId encodes block number in lower 48 bits
            mem.mintBlock = uint48(mem.tokenId);
            if (mem.mintBlock != 0) { // if threshold is set to zero, skip check
                // Check for underflow just in case current block is lower than mint block (should not happen in valid chain)
                // but block.number should be >= mintBlock if it exists.
                if (block.number < mem.mintBlock || (block.number - mem.mintBlock) > mem.blocksThreshold) {
                    revert Soulbound1155GatedAccess__TokenExpiredOrInvalid(mem.tokenId);
                }    
            }

        }

        // Check 5: if everything passes, assign roleId to caller.
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, mem.roleId, caller);

        return (actionId, targets, values, calldatas);
    }
}
