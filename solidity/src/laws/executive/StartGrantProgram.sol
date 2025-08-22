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

/// @notice NB, this is still WIP! -- it should be possible to do this simpler.. 
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";

contract StartGrantProgram is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.
    mapping(bytes32 lawHash => address grantLaw) public grantLaws;
    mapping(bytes32 lawHash => uint256 granteeRoleId) public granteeRoleIds;
    mapping(bytes32 lawHash => ILaw.Conditions grantCondition) public grantConditions;


    /// @notice constructor of the law
        constructor() {
        bytes memory configParams = abi.encode(
            "address grantProgramLaw",
            "address grantLaw", // Address of grant law
            "uint32 VotingPeriod",
            "uint8 Quorum",
            "uint8 SucceedAt"
        );
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions,
        bytes memory config
    ) public override {
        (address grantProgramLaw, address grantLaw, uint256 granteeRoleId, uint32 votingPeriod, uint8 quorum, uint8 succeedAt) =
            abi.decode(config, (address, address, uint256, uint32, uint8, uint8));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

        grantLaws[lawHash] = grantLaw;
        granteeRoleIds[lawHash] = granteeRoleId;
        // note: incomplete conditions. Other fields are set when the grant program law is adopted.
        grantConditions[lawHash] = ILaw.Conditions({
            law: grantProgramLaw,
            allowedRole: granteeRoleId,
            votingPeriod: votingPeriod,
            quorum: quorum,
            succeedAt: succeedAt
        });

        inputParams = abi.encode(
            "uint256 roleId", // Role ID of those that can assign grants to grantees.
            "address[] allowedTokens",  // Addresses of ERC20 tokens that can be used to fund grants.
            "uint256[] budgetTokens", // Total funds in the grant program, in each allowed token.
        );

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (uint256 roleId, address[] memory allowedTokens, uint256[] memory budgetTokens) =
            abi.decode(lawCalldata, (uint256, address[], uint256[]));

        Conditions memory conditions = grantConditions[lawHash];
        conditions.allowedRole = roleId;

        config = abi.encode(allowedTokens, budgetTokens, grantLaws[lawHash], granteeRoleIds[lawHash], abi.encode(
            // these are the conditions for the separate grants that are issued. NOT the conditions for the grant program!
            ILaw.Conditions({
                law: grantLaws[lawHash],
                allowedRole: roleId
            })
        ));

        // send the calldata to the target function
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = targetContract[lawHash];
        calldatas[0] = abi.encodePacked(targetFunction[lawHash], lawCalldata);

        return (actionId, targets, values, calldatas, "");
    }
}