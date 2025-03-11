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

/// @notice Natspecs WIP
///
pragma solidity 0.8.26;

import { Powers} from "../../Powers.sol";
import { Law } from "../../Law.sol";
import { AddressesMapping } from "../state/AddressesMapping.sol";

abstract contract BlacklistCheck is Law {
    function checksAtPropose(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
    {
        bool blacklisted = AddressesMapping(blacklistContract()).addresses(initiator);
        if (blacklisted) {
            revert ("blacklisted");
        }

        super.checksAtPropose(initiator, lawCalldata, descriptionHash);
    }

    function blacklistContract() internal view virtual returns (address) {
        return address(0);
    }
}
