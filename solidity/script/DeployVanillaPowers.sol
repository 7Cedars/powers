// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";

// core protocol
import { Powers } from "../src/Powers.sol";

// @dev this script is used to deploy the vanilla powers contract.
contract DeployVanillaPowers is Script {
    function run() external returns (address payable powers_) {
        vm.startBroadcast();
        Powers powers = new Powers(
            "Vanilla Powers",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreieioptfopmddgpiowg6duuzsd4n6koibutthev72dnmweczjybs4q"
        );
        vm.stopBroadcast();

        powers_ = payable(address(powers));
    }
}
