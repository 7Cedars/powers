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

import { Law } from "../../Law.sol";
import { Powers} from "../../Powers.sol";

abstract contract HasNotRoleCheck is Law {
    function checksAtPropose(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
    {
        (uint32[] memory roles) = hasNotRoles();

        for (uint32 i = 0; i < roles.length; i++) {
            uint48 since = Powers(powers).hasRoleSince(initiator, roles[i]);
            if (since == 0) {
                revert ("Does have role."); 
            }
        }

        super.checksAtPropose(initiator, lawCalldata, descriptionHash);
    }

    function hasNotRoles() internal view virtual returns (uint32[] memory) {
        return new uint32[](0);
    }
}
