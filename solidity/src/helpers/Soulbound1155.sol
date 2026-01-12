// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Soulbound1155 is meant as a simple token that logs activity in a soulbound way.
 * it allows the owner of the contract to mint unique tokens that encode the minter address and block number.
 * ints tokens that are soulbound (non-transferable).
 */
contract Soulbound1155 is ERC1155, Ownable {
    error Soulbound1155__NoZeroAmount(); 

    // the dao address receives half of mintable coins.
    constructor()
        ERC1155("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighx6axdemwbjara3xhhfn5yaiktidgljykzx3vsrqtymicxxtgvi")
        Ownable(msg.sender)
    { }

    // Mint tokenIds that encode the minter address and block number.
    function mint(address to) public onlyOwner {
        uint48 blockNumber = uint48(block.number);
        address sender = msg.sender; 

        uint256 tokenId = (uint256(uint160(sender)) << 48) | uint256(blockNumber);

        _mint(to, tokenId, 1, "");
    }

    // override to prevent transfers.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual override {
        // allow minting and burning
        if (from != address(0) && to != address(0)) {
            revert("Soulbound1155: Transfers are disabled");    
        }

        super._update(from, to, ids, values);
    }
}
