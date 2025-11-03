// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Powers } from "../../src/Powers.sol";

/// @notice Example DAO contract based on the Powers protocol.
contract PowersMock is Powers {
    constructor()
        Powers(
            "This is a test DAO", // name
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibd3qgeohyjeamqtfgk66lr427gpp4ify5q4civ2khcgkwyvz5hcq", // uri
            10_000, // max call data length
            10_000, // max return data length
            25 // max executions length
        )
    { }
}
