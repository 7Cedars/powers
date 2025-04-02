// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Powers } from "../../src/Powers.sol";

/// @notice Example DAO contract based on the Powers protocol.
contract DaoMock is Powers {
    constructor()
        Powers("DaoMock", "https://example.com") // name of the DAO.
    { }
}
