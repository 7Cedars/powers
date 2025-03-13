// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Powers } from "../../src/Powers.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

/// @notice Example DAO contract based on the Powers protocol.
contract DaoMock is Powers{
    using ShortStrings for *;

    // Optional naming uint48 roles at initiation.
    uint32 public constant ROLE_ONE = 1;
    uint32 public constant ROLE_TWO = 2;
    uint32 public constant ROLE_THREE = 3;

    constructor()
        Powers("DaoMock", "") // name of the DAO.
    { }
}
