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

/// @notice Natspecs are tbi. 
///
/// @author 7Cedars
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { Powers } from "../../../Powers.sol";
import { Erc20TaxedMock } from "../../../../test/mocks/Erc20TaxedMock.sol";
import { LawUtils } from "../../LawUtils.sol";

contract RoleByTaxPaid is Law {
    address public erc20TaxedMock;
    uint256 public thresholdTaxPaid;
    uint256 public roleIdToSet;
    constructor(
        // standard
        string memory name_,
        string memory description_,
        address payable powers_,
        uint256 allowedRole_,
        LawChecks memory config_,
        // bespoke 
        uint256 roleIdToSet_,
        address erc20TaxedMock_,
        uint256 thresholdTaxPaid_
    ) Law(name_, powers_, allowedRole_, config_) {
        roleIdToSet = roleIdToSet_;
        erc20TaxedMock = erc20TaxedMock_;
        thresholdTaxPaid = thresholdTaxPaid_;

        bytes memory params = abi.encode("address Account");
        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    function handleRequest(address caller, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: create actionId & decode the calldata.
        actionId = LawUtils.hashActionId(address(this), lawCalldata, nonce);
        (address account) = abi.decode(lawCalldata, (address));

        // step 1: retrieve data 
        uint48 epochDuration = Erc20TaxedMock(erc20TaxedMock).epochDuration();
        uint48 currentEpoch = uint48(block.number) / epochDuration;
        if (currentEpoch == 0) {
            revert ("No finished epoch yet."); 
        }

        // step 2: retrieve data on tax paid and role
        bool hasRole = Powers(payable(powers)).hasRoleSince(caller, roleIdToSet) != 0;
        uint256 taxPaid = Erc20TaxedMock(erc20TaxedMock).getTaxLogs(uint48(block.number) - epochDuration, account);

        // step 3: create arrays
        if (hasRole && taxPaid < thresholdTaxPaid) {
            (targets, values, calldatas) = LawUtils.createEmptyArrays(1);
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, roleIdToSet, account); 
        } else if (!hasRole && taxPaid >= thresholdTaxPaid) { 
            (targets, values, calldatas) = LawUtils.createEmptyArrays(1);
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, roleIdToSet, account);
        }

        // step 4: return data
        return (actionId, targets, values, calldatas, "");
    }
}
