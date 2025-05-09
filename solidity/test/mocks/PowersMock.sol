// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Powers } from "../../src/Powers.sol";

/// @notice Example DAO contract based on the Powers protocol.
contract PowersMock is Powers {
    constructor()
        Powers("This is a test DAO", "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibd3qgeohyjeamqtfgk66lr427gpp4ify5q4civ2khcgkwyvz5hcq") // name of the DAO.
    { }
}
