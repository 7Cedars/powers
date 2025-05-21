// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20TaxedMock is ERC20, Ownable {
    error Erc20TaxedMock__NoZeroAmount();
    error Erc20TaxedMock__TaxRateOverflow();
    error Erc20TaxedMock__InsufficientBalanceForTax();
    error Erc20TaxedMock__FaucetPaused();

    uint256 public taxRate;
    bool public faucetPaused;
    uint256 public immutable AMOUNT_FAUCET = 1 * 10 ** 18;
    uint8 public immutable DENOMINATOR;
    uint48 public immutable epochDuration;
    mapping(uint48 epoch => mapping(address account => uint256 taxPaid)) public taxLogs;

    constructor()
        ERC20("mockTaxed", "MTXD")
        Ownable(msg.sender)
    {
        // Note: hard coded values for testing.
        taxRate = 10;
        DENOMINATOR = 100;
        epochDuration = 900; // 900 blocks, about 30 minutes on optimism sepolia, about 3 hours on arbitrum and mainnet sepolia. 
        _mint(msg.sender, 1 * 10 ** 18); // start with one million tokens.
    }

    // a public non-restricted function that allows anyone to mint coins. Only restricted by max allowed coins to mint.
    function mint(uint256 amount) public onlyOwner {
        if (amount == 0) {
            revert Erc20TaxedMock__NoZeroAmount();
        }
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        if (amount == 0) {
            revert Erc20TaxedMock__NoZeroAmount();
        }
        _burn(msg.sender, amount);
    }

    function faucet() public {
        if (faucetPaused) {
            revert Erc20TaxedMock__FaucetPaused();
        }
        _mint(msg.sender, AMOUNT_FAUCET);
    }

    function pauseFaucet() public onlyOwner {
        faucetPaused = !faucetPaused;
    }

    function changeTaxRate(uint256 newTaxRate) public onlyOwner {
        if (newTaxRate >= DENOMINATOR - 1) {
            revert Erc20TaxedMock__TaxRateOverflow();
        }
        taxRate = newTaxRate;
    }

    // replaces the standard update function, adding tax collection and registration.
    function _update(address from, address to, uint256 value) internal override {
        // adds tax collection and registration to transfers. Note that tax is _added_ to amount transferred.
        // if taxed amount cannot be collected, it will revert.
        // taxes are not collected when minting, burning or transferring to or from owner.
        if (from != owner() && to != owner() && from != address(0) && to != address(0) && value != 0) {
            uint256 tax = (value * taxRate) / DENOMINATOR;
            uint256 fromBalance = balanceOf(from);

            if (fromBalance < value + tax) {
                revert Erc20TaxedMock__InsufficientBalanceForTax();
            }

            // transfer tax to owner of token
            _transfer(from, owner(), tax);

            // register tax in contract.
            uint48 currentEpoch = uint48(block.number) / epochDuration;
            taxLogs[currentEpoch][from] += tax;
        }

        // continue with legacy _update function:
        super._update(from, to, value);
    }

    ////////////////////////////////////////////
    //             Getter functions           //
    ////////////////////////////////////////////

    function getTaxLogs(uint48 blockNumber, address account) external view returns (uint256 taxPaid) {
        uint48 epoch = blockNumber / epochDuration;
        return taxLogs[epoch][account];
    }

    // /// @notice implements ERC165 so that token can be recognized as a taxed Erc20 by other contracts
    // function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
    //     return interfaceId == type(Erc20TaxedMock).interfaceId || super.supportsInterface(interfaceId);
    // }
}
