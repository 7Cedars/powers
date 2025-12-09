// SPDX-License-Identifier: MIT

/// @notice An example implementation of a Law Package that adopts multiple laws into the Powers protocol.
/// @dev It is meant to be adopted through the AdoptLaws law, and then be executed to adopt multiple laws in a single transaction.
/// @dev The law self-destructs after execution.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../Law.sol";
import { LawUtilities } from "../libraries/LawUtilities.sol";
import { IPowers } from "../interfaces/IPowers.sol";
import { Powers } from "../Powers.sol";
import { PowersTypes } from "../interfaces/PowersTypes.sol";
import { ILaw } from "../interfaces/ILaw.sol";
import { IERC165 } from "../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

contract LawPackage is Law {
    address[] private sLawAddresses;

    // in this case lawAddresses should be [openAction, statementOfIntent] -- we only need those two laws for this package.
    constructor(address[] memory lawAddresses) {
        sLawAddresses = lawAddresses;
        emit Law__Deployed(abi.encode());
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        inputParams = abi.encode();
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
        uint16 lawCount = Powers(powers).lawCounter();
        PowersTypes.LawInitData[] memory slawInitData = getNewLaws(sLawAddresses, powers, lawCount);

        // Create arrays for the calls to adoptLaw
        uint256 length = slawInitData.length;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length + 1);
        for (uint256 i; i < length; i++) {
            targets[i] = powers;
            calldatas[i] = abi.encodeWithSelector(IPowers.adoptLaw.selector, slawInitData[i]);
        }
        // Final call to self-destruct the LawPackage after adopting the laws
        targets[length] = powers;
        calldatas[length] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        return (actionId, targets, values, calldatas);
    }

    /// @notice Generates LawInitData for a set of new laws to be adopted.
    /// @param lawAddresses The addresses of the laws to be adopted.
    /// @param powers The address of the Powers contract.
    /// @return lawInitData An array of LawInitData structs for the new laws.
    /// @dev the function follows the same pattern as TestConstitutions.sol
    /// this function can be overwritten to create different law packages.
    function getNewLaws(address[] memory lawAddresses, address powers, uint16 lawCount)
        public
        view
        virtual
        returns (PowersTypes.LawInitData[] memory lawInitData)
    {
        lawInitData = new PowersTypes.LawInitData[](3);
        PowersTypes.Conditions memory conditions;

        // statementOfIntent params
        string[] memory inputParams = new string[](3);
        inputParams[0] = "address[] Targets";
        inputParams[1] = "uint256[] Values";
        inputParams[2] = "bytes[] Calldatas";

        conditions.allowedRole = 1; // = role that can call this law.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[0] = PowersTypes.LawInitData({
            nameDescription: "StatementOfIntent: Propose any kind of action.",
            targetLaw: lawAddresses[1], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 0; // = admin.
        conditions.needFulfilled = lawCount; // = law that must be completed before this one.
        lawInitData[1] = PowersTypes.LawInitData({
            nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
            targetLaw: lawAddresses[1], // statementOfIntent
            config: abi.encode(inputParams),
            conditions: conditions
        });
        delete conditions;

        conditions.allowedRole = 2; // = role that can call this law.
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.succeedAt = 66; // = 51% simple majority needed for executing an action.
        conditions.quorum = 20; // = 30% quorum needed
        conditions.needFulfilled = lawCount; // = law that must be completed before this one.
        conditions.needNotFulfilled = lawCount + 1; // = law that must not be completed before this one.
        lawInitData[2] = PowersTypes.LawInitData({
            nameDescription: "Execute an action: Execute an action that has been proposed by the community and should not have been vetoed by an admin.",
            targetLaw: lawAddresses[0], // openAction.
            config: abi.encode(), // empty config.
            conditions: conditions
        });
        delete conditions;
    }
}
