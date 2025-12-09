// SPDX-License-Identifier: MIT

/// @notice Adopt a set of laws configured at initialization.
/// @dev Builds calls to `IPowers.adoptLaw` for each configured law. No self-destruction occurs.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

contract AdoptLaws is Law {
    constructor() {
        bytes memory configParams = abi.encode();
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        inputParams = abi.encode("address[] lawAddress", "uint256[] roleIds");
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Build calls to adopt the configured laws
    /// @param lawCalldata Unused for this law
    function handleRequest(
        address,
        /*caller*/
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (address[] memory laws_, uint256[] memory roleIds_) = abi.decode(lawCalldata, (address[], uint256[]));

        // Create arrays for the calls to adoptLaw
        uint256 length = laws_.length;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);
        PowersTypes.Conditions memory conditions;

        for (uint256 i; i < length; i++) {
            conditions.allowedRole = roleIds_[i];
            PowersTypes.LawInitData memory lawInitData = PowersTypes.LawInitData({
                nameDescription: "Reform law", targetLaw: laws_[i], config: abi.encode(), conditions: conditions
            });
            targets[i] = powers;
            calldatas[i] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
        }
        return (actionId, targets, values, calldatas);
    }
}
