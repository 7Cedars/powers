// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Mock ERC721 contract for use in DAO example implementations of the Powers protocol.
 * IMPORTANT: This is a non-transferable NFT!
 * Note Natspecs WIP.
 */
contract SoulboundErc721 is ERC721, Ownable {

    constructor() ERC721("Soulbound", "SB") Ownable(msg.sender) { }

    function mintNFT(uint256 tokenId, address account) public onlyOwner {
        if (_ownerOf(tokenId) != address(0)) {
            revert ("Nft already exists");
        }
        _safeMint(account, tokenId);
    }

    function burnNFT(uint256 tokenId, address account) public onlyOwner {
        if (_ownerOf(tokenId) != account) {
            revert ("Incorrect account token pair");
        }
        _burn(tokenId);
    }

    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal override {
        if (auth != address(0) && to != address(0)) {
            revert ("Non transferable");
        }
        super._approve(to, tokenId, auth, emitEvent);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal override {
        if (owner != address(0) && operator != address(0)) {
            revert ("Non transferable");
        }
        super._setApprovalForAll(owner, operator, approved);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // Execute the update. Note only address(0) can transfer. Meaning that the NFT can only be minted to an address and is non-transferable.
        if (from != address(0) && to != address(0)) {
            revert ("Non transferable");
        }

        return super._update(to, tokenId, auth);
    }
}
