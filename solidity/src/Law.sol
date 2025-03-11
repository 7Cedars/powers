// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and its contracts have not been audited.           ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title Law.sol v.0.2
/// @notice Base implementation of a Law in the Powers protocol. Meant to be inherited by law implementations.
///
/// @dev Laws are role restricted contracts that are executed by the Powers.sol. The provide the following functionality:
/// 1 - Role restricting a community's actions
/// 2 - Transforming a {lawCalldata) input into an output of targets[], values[], calldatas[] to be executed by the core protocol.
/// 3 - Saving a the state of a community.
/// 4 - Adding conditions to the creation of proposals for and/or execution of the law.
/// 5 - Prior to changing state and returning output data, all checks are run. 
///
/// Laws can be adapted through the following ways: 
/// - By inheriting and changing the implementing of the {simulateLaw} function.
/// - By changing setting of the {config} variable in the constructor.
/// - By changing any other (bespoke) parameters in the constructor.
/// Combined, they allow for a wide range of executive, legislative and electoral logics to be implemented.
///
/// To enable front end UIs to dynamically generate UIs to interact with laws a `paramsInput` and `stateVars` variable are included.
/// - paramsInput: an abi.encoded array of strings that denote the input parameters. 
/// - stateVars: an abi.encoded array of strings that denote the variables that are saved in state. 
///
/// @author 7Cedars
pragma solidity 0.8.26;

import { Powers} from "./Powers.sol";
import { PowersTypes } from "./interfaces/PowersTypes.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
 
contract Law is ERC165, ILaw {
    using ShortStrings for *;

    //////////////////////////////////////////////////
    //                 variables                    //
    //////////////////////////////////////////////////
    // required parameters
    uint32 public allowedRole;
    ShortString public immutable name; // name of the law
    address payable public powers; // the address of the core governance protocol
    string public description; // description of the law
    bytes public inputParams; // an abi.encoded array of strings that denote the input parameters. For example: abi.encode("address", "address", "uint256", "address[]");
    bytes public stateVars; // an abi.encoded array of strings that denote the variables that are saved in state. For example: abi.encode("address", "address", "uint256", "address[]");

    // optional parameters
    LawConfig public config;

    // optional storage
    uint48[] public executions = [0]; // log of when the law was executed in block.number.

    //////////////////////////////////////////////////
    //                 FUNCTIONS                    //
    //////////////////////////////////////////////////
    /// @dev Constructor function for Law contract.
    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) {
        powers = powers_;
        name = name_.toShortString();
        description = description_;
        allowedRole = allowedRole_;
        config = config_;

        emit Law__Initialized(address(this), powers, name_, description, allowedRole, config);
    }

    /// note this is the function that is called by the Powers protocol. It always runs checks before execution of law logic.
    /// @inheritdoc ILaw
    function executeLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        if (msg.sender != powers) {
            revert Law__OnlyPowers();
        }
        checksAtPropose(initiator, lawCalldata, descriptionHash);
        checksAtExecute(initiator, lawCalldata, descriptionHash);
        bytes memory stateChange;
        (targets, values, calldatas, stateChange) = simulateLaw(initiator, lawCalldata, descriptionHash);
        _changeStateVariables(stateChange);
        executions.push(uint48(block.number));
    }

    /// note NB! this function needs to be overwritten by law implementations to include law specific logics.
    /// @inheritdoc ILaw
    function simulateLaw(
        address initiator,
        bytes memory lawCalldata,
        bytes32 descriptionHash // NB. £bug: simulateLaw can change state of law _without_ checks having been run!
    )
        public
        view // CANNOT change state of law.
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // Empty law logic. Needs to be overridden by law implementations
    }

    //////////////////////////////////////////////////
    //                  CHECKS                      //
    //////////////////////////////////////////////////
    /// @inheritdoc ILaw
    function checksAtPropose(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
    {
        /// Optional check 1: make law conditional on a parent law being completed.
        if (config.needCompleted != address(0)) {
            uint256 parentProposalId = _hashProposal(config.needCompleted, lawCalldata, descriptionHash);
            if (
                Powers(payable(powers)).state(parentProposalId)
                    != PowersTypes.ProposalState.Completed
            ) {
                revert Law__ParentNotCompleted();
            }
        }

        /// Optional check 2: make law conditional on a parent law NOT being completed.
        /// Note this means a roleId can be given an effective veto to a legal process. If the RoleId does nothing, the law will pass. If they actively oppose, it will fail.
        if (config.needNotCompleted != address(0)) {
            uint256 parentProposalId = _hashProposal(config.needNotCompleted, lawCalldata, descriptionHash);
            if (
                Powers(payable(powers)).state(parentProposalId)
                    == PowersTypes.ProposalState.Completed
            ) {
                revert Law__ParentBlocksCompletion();
            }
        }
    }

    /// @inheritdoc ILaw
    function checksAtExecute(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
    {
        /// Optional check 3: throttle how often the law can be executed.
        if (config.throttleExecution != 0) {
            uint256 numberOfExecutions = executions.length - 1;
            if (
                executions[numberOfExecutions] != 0
                    && block.number - executions[numberOfExecutions] < config.throttleExecution
            ) {
                revert Law__ExecutionGapTooSmall();
            }
        }

        // Optional check 4: make law conditional on a proposal succeeding.
        if (config.quorum != 0) {
            uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
            if (
                Powers(payable(powers)).state(proposalId)
                    != PowersTypes.ProposalState.Succeeded
            ) {
                revert Law__ProposalNotSucceeded();
            }
        }

        /// Optional check 5: set a deadline for how long after its proposal passed it can be executed.
        if (config.delayExecution != 0) {
            uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
            uint256 currentBlock = block.number;
            uint256 deadline = Powers(payable(powers)).proposalDeadline(proposalId);

            if (deadline + config.delayExecution > currentBlock) {
                revert Law__DeadlineNotPassed();
            }
        }
    }

    //////////////////////////////////////////////////
    //                 INTERNALS                    //
    //////////////////////////////////////////////////
    function _changeStateVariables(bytes memory stateChange) internal virtual {
        // Empty function. Needs to be overridden by law implementations
    }

    //////////////////////////////////////////////////
    //           HELPER & VIEW FUNCTIONS            //
    //////////////////////////////////////////////////
    /// @notice implements ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice an internal helper function for hashing proposals.
    function _hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }
}
