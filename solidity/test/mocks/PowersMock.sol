// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Powers } from "../../src/Powers.sol";

/// @notice Example DAO contract based on the Powers protocol.
contract PowersMock is Powers {
    constructor()
        Powers("PowersMock", "https://example.com") // name of the DAO.
    { }
}
