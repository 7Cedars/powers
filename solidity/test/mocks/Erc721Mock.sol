// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Mock ERC721 contract for use in DAO example implementations of the Powers protocol.
 * IMPORTANT: This is a non-transferable NFT!
 * Note Natspecs WIP.
 */
contract Erc721Mock is ERC721, Ownable {
    error Erc721Mock__NonTransferable();
    error Erc721Mock__NftAlreadyExists();
    error Erc721Mock__IncorrectAccountTokenPair();
    error Erc721Mock__OnlyPowers();

    constructor() ERC721("mock", "MOCK") Ownable(msg.sender) { }

    function mintNFT(uint256 tokenId, address account) public onlyOwner {
        if (_ownerOf(tokenId) != address(0)) {
            revert Erc721Mock__NftAlreadyExists();
        }
        _safeMint(account, tokenId);
    }

    function burnNFT(uint256 tokenId, address account) public onlyOwner {
        if (_ownerOf(tokenId) != account) {
            revert Erc721Mock__IncorrectAccountTokenPair();
        }
        _burn(tokenId);
    }

    function cheatMint(uint256 tokenId) public {
        if (_ownerOf(tokenId) != address(0)) {
            revert Erc721Mock__NftAlreadyExists();
        }
        _safeMint(msg.sender, tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // Execute the update. Note only address(0) can transfer. Meaning that the NFT can only be minted to an address and is non-transferable.
        if (from != address(0) && to != address(0)) {
            revert Erc721Mock__NonTransferable();
        }

        return super._update(to, tokenId, auth);
    }
}
