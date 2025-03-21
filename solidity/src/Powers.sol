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

/// @title Powers Protocol v.0.3
/// @notice Powers is a Role Restricted Governance Protocol. It provides a modular, flexible, decentralised and efficient governance engine for DAOs.
///
/// @dev This contract is the core engine of the protocol. It is meant to be used in combination with implementations of {Law.sol}. The contract should be used as is, making changes to this contract should be avoided.
/// @dev Code is derived from OpenZeppelin's Governor.sol and AccessManager contracts, in addition to Haberdasher Labs Hats protocol.
/// @dev Compatibility with Governor.sol, AccessManager and the Hats protocol is high on the priority list.
///
/// Note several key differences from openzeppelin's {Governor.sol}.
/// 1 - Any DAO action needs to be encoded in role restricted external contracts, or laws, that follow the {ILaw} interface.
/// 2 - Proposing, voting, cancelling and executing actions are role restricted along the target law that is called.
/// 3 - All DAO actions need to run through the governance flow provided by Powers.sol. Calls to laws that do not need a proposedAction vote, for instance, still need to be executed through the {execute} function.
/// 4 - The core protocol uses a non-weighted voting mechanism: one account has one vote. Accounts vote with their roles, not with their tokens.
/// 5 - The core protocol is intentionally minimalistic. Any complexity (timelocks, delayed execution, guardian roles, weighted votes, staking, etc.) has to be integrated through laws.
/// 
/// For example implementations of DAOs, see the `Deploy...` files in the /script folder.
///
/// Note This protocol is a work in progress. A number of features are planned to be added in the future.
/// - Integration with, or support for OpenZeppelin's {Governor.sol} and Compound's {GovernorBravo.sol}. The same holds for the Hats Protocol.
/// - Native support for multi-chain governance.
/// - Gas efficiency improvements.
/// - Improved time management, including support for EIP-6372 {clock()} for timestamping governance processes.
/// - And more. 
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "./Law.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { IPowers } from "./interfaces/IPowers.sol";
import { ERC165Checker } from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import { Address } from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { EIP712 } from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

// import { console2 } from "forge-std/console2.sol"; // remove before deploying. 

contract Powers is EIP712, IPowers {
    //////////////////////////////////////////////////////////////
    //                           STORAGE                        //
    /////////////////////////////////////////////////////////////
    mapping(uint256 actionId => Action) private _actions;  // mapping actionId to Action struct
    mapping(address lawAddress => bool active) public laws; // mapping law address to bool (true if law is active)
    mapping(uint256 roleId => Role) public roles; // mapping roleId to Role struct

    // two roles are preset: ADMIN_ROLE == 0 and PUBLIC_ROLE == type(uint48).max.
    uint32 public constant ADMIN_ROLE = type(uint32).min; // == 0
    uint32 public constant PUBLIC_ROLE = type(uint32).max; // == a lot
    uint256 constant DENOMINATOR = 100; // = 100%

    string public name; // name of the DAO.
    string public uri; // a uri to metadata of the DAO.
    bool private _constituteExecuted; // has the constitute function been called before?

    //////////////////////////////////////////////////////////////
    //                          MODIFIERS                       //
    //////////////////////////////////////////////////////////////
    /// @notice A modifier that sets a function to only be callable by the {Powers} contract.
    modifier onlyPowers() {
        if (msg.sender != address(this)) {
            revert Powers__OnlyPowers();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //              CONSTRUCTOR & RECEIVE                       //
    //////////////////////////////////////////////////////////////
    /// @notice  Sets the value for {name} at the time of construction.
    ///
    /// @param name_ name of the contract
    constructor(string memory name_, string memory uri_) EIP712(name_, version()) {
        if (bytes(name_).length == 0) { revert Powers__InvalidName(); } 
        name = name_;
        uri = uri_;
        
        _setRole(ADMIN_ROLE, msg.sender, true); // the account that initiates a Powerscontract is set to its admin.
        roles[ADMIN_ROLE].amountMembers = 1; // the number of admins at set up is 1.
        roles[PUBLIC_ROLE].amountMembers = type(uint256).max; // the number for holders of the PUBLIC_ROLE is type(uint256).max. As in, everyone has this role.

        emit Powers__Initialized(address(this), name, uri);
    }

    /// @notice receive function enabling ETH deposits.
    ///
    /// @dev This is a virtual function, and can be overridden in the DAO implementation.
    /// @dev No access control on this function: anyone can send funds into the main contract.
    receive() external payable virtual {
        emit FundsReceived(msg.value);
    }

    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE LOGIC                        //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc IPowers
    /// @dev The execute function follows a call-and-return mechanism. This allows for async execution of laws.
    function request(address targetLaw, bytes calldata lawCalldata, uint256 nonce, string memory description) external payable virtual {
        uint256 actionId = _hashAction(targetLaw, lawCalldata, nonce);

        // check 1: does executioner have access to law being executed?
        if (!canCallLaw(msg.sender, targetLaw)) {
            revert Powers__AccessDenied();
        }
        // check 2: is targetLaw is an active law?
        if (!laws[targetLaw]) {
            revert Powers__NotActiveLaw();
        }
        // check 3: has action already been set as requested?
        if (_actions[actionId].requested == true) { 
            revert Powers__ActionAlreadyInitiated();
        }
        // check 4: is proposedAction cancelled?
        // if law did not need a proposedAction proposedAction vote to start with, check will pass.
        if (_actions[actionId].cancelled == true) {
            revert Powers__ActionCancelled();
        }
        // if checks pass, call executeLaw function of target law. 
                // If checks passed, set proposedAction as completed and emit event.
        _actions[actionId].caller = msg.sender; // note if caller had been set during proposedAction, it will be overwritten.
        _actions[actionId].requested = true;

        (bool success) = ILaw(targetLaw).executeLaw(msg.sender, lawCalldata, nonce);
        if (!success) {
            revert Powers__LawDidNotPassChecks();
        }
        emit ActionRequested(msg.sender, targetLaw, lawCalldata, nonce, description);
    }

    /// @inheritdoc IPowers
    function fulfill(uint256 actionId, address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas) external payable virtual {
        // check 1: is msg.sender a targetLaw?
        if (!laws[msg.sender]) {
            revert Powers__NotActiveLaw();
        }
        // check 2: has action already been set as requested?
        if (_actions[actionId].requested != true) {
            revert Powers__ActionNotRequested();
        }
        // check 3: are the lengths of targets, values and calldatas equal?
        if (targets.length != values.length || targets.length != calldatas.length) {
            revert Powers__InvalidCallData();
        }
        // check 4: execute targets[], values[], calldatas[] received from law.
        _actions[actionId].fulfilled = true;
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{ value: values[i] }(calldatas[i]);
            Address.verifyCallResult(success, returndata);
        } 
        emit ActionExecuted(actionId,targets, values, calldatas);
    }

    /// @inheritdoc IPowers
    function propose(address targetLaw, bytes calldata lawCalldata, uint256 nonce, string memory description)
        external
        virtual
        returns (uint256)
    {
        // check 1: is targetLaw is an active law?
        if (!laws[targetLaw]) {
            revert Powers__NotActiveLaw();
        }
        //check 2: does msg.sender have access to targetLaw?
        if (!canCallLaw(msg.sender, targetLaw)) {
            revert Powers__AccessDenied();
        }
        // if check passes: propose.
        return _propose(msg.sender, targetLaw, lawCalldata, nonce, description);
    }

    /// @notice Internal propose mechanism. Can be overridden to add more logic on proposedAction creation.
    ///
    /// @dev The mechanism checks for the length of targets and calldatas.
    ///
    /// Emits a {SeperatedPowersEvents::proposedActionCreated} event.
    function _propose(address caller, address targetLaw, bytes calldata lawCalldata, uint256 nonce, string memory description)
        internal
        virtual
        returns (uint256 actionId)
    {
        // (uint8 quorum,, uint32 votingPeriod,,,,,) = Law(targetLaw).conditions();
        ( , , , , uint32 votingPeriod, uint8 quorum, ,) = Law(targetLaw).conditions();
        actionId = _hashAction(targetLaw, lawCalldata, nonce);

        // check 1: does target law need proposedAction vote to pass?
        if (quorum == 0) {
            revert Powers__NoVoteNeeded();
        }
        // check 2: do we have a proposedAction with the same targetLaw and lawCalldata?
        if (_actions[actionId].voteStart != 0) {
            revert Powers__UnexpectedActionState();
        }
        // check 3: do proposedAction checks of the law pass?
        Law(targetLaw).checksAtPropose(caller, lawCalldata, nonce);

        // if checks pass: create proposedAction
        uint32 duration = votingPeriod;
        Action storage proposedAction = _actions[actionId];
        proposedAction.targetLaw = targetLaw;
        proposedAction.voteStart = uint48(block.number); // note that the moment proposedAction is made, voting start. Delay functionality has to be implemeted at the law level.
        proposedAction.voteDuration = duration;
        proposedAction.caller = caller;

        emit ProposedActionCreated(
            actionId, caller, targetLaw, "", lawCalldata, block.number, block.number + duration, nonce, description
        );
    }

    /// @inheritdoc IPowers
    /// @dev the account to cancel must be the account that created the proposedAction.
    function cancel(address targetLaw, bytes calldata lawCalldata, uint256 nonce, string memory description)
        public
        virtual
        returns (uint256)
    {
        uint256 actionId = _hashAction(targetLaw, lawCalldata, nonce);
        // only caller can cancel a proposedAction, also checks if proposedAction exists (otherwise _actions[actionId].caller == address(0))
        if (msg.sender != _actions[actionId].caller) {
            revert Powers__AccessDenied();
        }

        return _cancel(targetLaw, lawCalldata, nonce);
    }

    /// @notice Internal cancel mechanism with minimal restrictions. A proposedAction can be cancelled in any state other than
    /// Cancelled or Executed. Once cancelled a proposedAction cannot be re-submitted.
    /// Emits a {SeperatedPowersEvents::proposedActionCanceled} event.
    function _cancel(address targetLaw, bytes calldata lawCalldata, uint256 nonce)
        internal
        virtual
        returns (uint256)
    {
        uint256 actionId = _hashAction(targetLaw, lawCalldata, nonce);

        if (_actions[actionId].fulfilled || _actions[actionId].cancelled) {
            revert Powers__UnexpectedActionState();
        }

        _actions[actionId].cancelled = true;
        emit ProposedActionCancelled(actionId);

        return actionId;
    }

    /// @inheritdoc IPowers
    function castVote(uint256 actionId, uint8 support) external virtual {
        address voter = msg.sender;
        return _castVote(actionId, voter, support, "");
    }

    /// @inheritdoc IPowers
    function castVoteWithReason(uint256 actionId, uint8 support, string calldata reason) public virtual {
        address voter = msg.sender;
        return _castVote(actionId, voter, support, reason);
    }

    /// @notice Internal vote casting mechanism.
    /// Check that the proposedAction is active, and that account is has access to targetLaw.
    ///
    /// Emits a {SeperatedPowersEvents::VoteCast} event.
    function _castVote(uint256 actionId, address account, uint8 support, string memory reason) internal virtual {
        // Check that the proposedAction is active, that it has not been paused, cancelled or ended yet.
        if (Powers(payable(address(this))).state(actionId) != ActionState.Active) {
            revert Powers__ProposedActionNotActive();
        }
        // Note that we check if account has access to the law targetted in the proposedAction.
        address targetLaw = _actions[actionId].targetLaw;
        if (!canCallLaw(account, targetLaw)) {
            revert Powers__AccessDenied();
        }
        // if all this passes: cast vote.
        _countVote(actionId, account, support);

        emit VoteCast(account, actionId, support, reason);
    }

   

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                      //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc IPowers
    function constitute(address[] memory constituentLaws) external virtual {
        // check 1: only admin can call this function
        if (roles[ADMIN_ROLE].members[msg.sender] == 0) {
            revert Powers__AccessDenied();
        }
        // check 2: this function can only be called once.
        if (_constituteExecuted) {
            revert Powers__ConstitutionAlreadyExecuted();
        }

        // if checks pass, set _constituentLawsExecuted to true...
        _constituteExecuted = true;
        // ...and set laws
        for (uint256 i = 0; i < constituentLaws.length; i++) {
            _adoptLaw(constituentLaws[i]);
        }
    }

    /// @inheritdoc IPowers
    function adoptLaw(address law) public onlyPowers {
        if (laws[law]) {
            revert Powers__LawAlreadyActive();
        }
        _adoptLaw(law);
    }

    /// @inheritdoc IPowers
    function revokeLaw(address law) public onlyPowers {
        if (!laws[law]) {
            revert Powers__LawNotActive();
        }
        emit LawRevoked(law);
        laws[law] = false;
    }

    /// @notice internal function to set a law or revoke it.
    ///
    /// @param law address of the law.
    ///
    /// Emits a {SeperatedPowersEvents::LawAdopted} event.
    function _adoptLaw(address law) internal virtual {
        // check if added address is indeed a law. Note that this will also revert with address(0).
        if (!ERC165Checker.supportsInterface(law, type(ILaw).interfaceId)) {
            revert Powers__IncorrectInterface();
        }
        laws[law] = true;

        emit LawAdopted(law);
    }

    /// @inheritdoc IPowers
    function assignRole(uint256 roleId, address account) public virtual onlyPowers {
        _setRole(roleId, account, true);
    }

    /// @inheritdoc IPowers
    function revokeRole(uint256 roleId, address account) public virtual onlyPowers {
        _setRole(roleId, account, false);
    }

    /// @inheritdoc IPowers
    function labelRole(uint256 roleId, string memory label) public virtual onlyPowers {
        if (roleId == ADMIN_ROLE || roleId == PUBLIC_ROLE) {
            revert Powers__LockedRole();
        }
        emit RoleLabel(roleId, label);
    }

    /// @notice Internal version of {setRole} without access control.
    /// @dev This function is used to set a role for a given account. Public role is locked as everyone has it.
    /// @dev Note that it does allow Admin role to be assigned and revoked. 
    ///
    /// Emits a {SeperatedPowersEvents::RolSet} event.
    function _setRole(uint256 roleId, address account, bool access) internal virtual {
        bool newMember = roles[roleId].members[account] == 0;
        // check 1: Public role is locked.
        if (roleId == PUBLIC_ROLE) {
            revert Powers__CannotAddToPublicRole();
        }
        // check 2: Zero address is not allowed.
        if (account == address(0)) {
            revert Powers__CannotAddZeroAddress();
        }

        if (access) {
            roles[roleId].members[account] = uint48(block.number); // 'since' is set at current block.number
            if (newMember) {
                roles[roleId].amountMembers++;
            }
        } else {
            roles[roleId].members[account] = 0;
            if (!newMember) {
                roles[roleId].amountMembers--;
            }
        }
        emit RoleSet(roleId, account, access);
    }

    //////////////////////////////////////////////////////////////
    //                     HELPER FUNCTIONS                     //
    //////////////////////////////////////////////////////////////
    function _hashAction(address targetLaw, bytes calldata lawCalldata, uint256 nonce) internal view virtual returns (uint256) {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, nonce)));
    }

    /// @notice internal function {quorumReached} that checks if the quorum for a given proposedAction has been reached.
    ///
    /// @param actionId id of the proposedAction.
    /// @param targetLaw address of the law that the proposedAction belongs to.
    ///
    function _quorumReached(uint256 actionId, address targetLaw) internal view virtual returns (bool) {
        Action storage proposedAction = _actions[actionId];
        ( , , , , , uint8 quorum, ,) = Law(targetLaw).conditions();
        uint256 allowedRole = Law(targetLaw).allowedRole();
        uint256 amountMembers = _countMembersRole(allowedRole);

        return (quorum == 0 || amountMembers * quorum <= (proposedAction.forVotes + proposedAction.abstainVotes) * DENOMINATOR); 
    }

    /// @notice internal function {voteSucceeded} that checks if a vote for a given proposedAction has succeeded.
    ///
    /// @param actionId id of the proposedAction.
    /// @param targetLaw address of the law that the proposedAction belongs to.
    function _voteSucceeded(uint256 actionId, address targetLaw) internal view virtual returns (bool) {
        Action storage proposedAction = _actions[actionId];
        (, , , , , uint8 quorum, uint8 succeedAt ,) = Law(targetLaw).conditions();
        uint256 allowedRole = Law(targetLaw).allowedRole();
        uint256 amountMembers = _countMembersRole(allowedRole);

        // note if quorum is set to 0 in a Law, it will automatically return true.
        return quorum == 0 || amountMembers * succeedAt <= proposedAction.forVotes * DENOMINATOR;
    }

    /// @notice internal function {countVote} that counts against, for, and abstain votes for a given proposedAction.
    ///
    /// @dev In this module, the support follows the `VoteType` enum (from Governor Bravo).
    /// @dev It does not check if account has roleId referenced in actionId. This has to be done by {Powers.castVote} function.
    function _countVote(uint256 actionId, address account, uint8 support) internal virtual {
        Action storage proposedAction = _actions[actionId];

        if (proposedAction.hasVoted[account]) {
            revert Powers__AlreadyCastVote();
        }
        proposedAction.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposedAction.againstVotes++;
        } else if (support == uint8(VoteType.For)) {
            proposedAction.forVotes++;
        } else if (support == uint8(VoteType.Abstain)) {
            proposedAction.abstainVotes++;
        } else {
            revert Powers__InvalidVoteType();
        }
    }

    function _countMembersRole(uint256 roleId) internal view virtual returns (uint256 amountMembers) {
        return roles[roleId].amountMembers;
    }

    /// @inheritdoc IPowers
    function setUri(string memory newUri) public virtual onlyPowers {
        uri = newUri;
    }

    //////////////////////////////////////////////////////////////
    //                      VIEW FUNCTIONS                      //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc IPowers
    function state(uint256 actionId) public view virtual returns (ActionState) {
        // We read the struct fields into the stack at once so Solidity emits a single SLOAD
        Action storage proposedAction = _actions[actionId];
        bool ActionFulfilled = proposedAction.fulfilled;
        bool proposedActionCancelled = proposedAction.cancelled;

        if (ActionFulfilled) {
            return ActionState.Fulfilled;
        }
        if (proposedActionCancelled) {
            return ActionState.Cancelled;
        }

        uint256 start = _actions[actionId].voteStart; // = startDate
        if (start == 0) {
            return ActionState.NonExistent;
        }

        uint256 deadline = getProposedActionDeadline(actionId);
        address targetLaw = _actions[actionId].targetLaw;

        if (deadline >= block.number) {
            return ActionState.Active;
        } else if (!_quorumReached(actionId, targetLaw) || !_voteSucceeded(actionId, targetLaw)) {
            return ActionState.Defeated;
        } else {
            return ActionState.Succeeded;
        }
    }

    /// @notice saves the version of the Powersimplementation.
    function version() public pure returns (string memory) {
        return "0.3";
    }

     /// @inheritdoc IPowers
    function canCallLaw(address caller, address targetLaw) public virtual view returns (bool) {
        uint256 allowedRole = Law(targetLaw).allowedRole();
        uint48 since = hasRoleSince(caller, allowedRole);

        return since != 0 || allowedRole == PUBLIC_ROLE;
    }

    /// @inheritdoc IPowers
    function hasRoleSince(address account, uint256 roleId) public view returns (uint48 since) {
        return roles[roleId].members[account];
    }

    /// @inheritdoc IPowers
    function hasVoted(uint256 actionId, address account) public view virtual returns (bool) {
        return _actions[actionId].hasVoted[account];
    }

    /// @inheritdoc IPowers
    function getProposedActionVotes(uint256 actionId)
        public
        view
        virtual
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
    {
        Action storage proposedAction = _actions[actionId];
        return (proposedAction.againstVotes, proposedAction.forVotes, proposedAction.abstainVotes);
    }

    /// @inheritdoc IPowers
    function getAmountRoleHolders(uint256 roleId) public view returns (uint256 amountMembers) {
        return roles[roleId].amountMembers;
    }

    /// @inheritdoc IPowers
    function getProposedActionDeadline(uint256 actionId) public view virtual returns (uint256) {
        // uint48 + uint32 => uint256. £test if this works properly.
        return _actions[actionId].voteStart + _actions[actionId].voteDuration;
    }

    /// @inheritdoc IPowers
    function getActiveLaw(address law) external view returns (bool active) {
        return laws[law];
    }

    //////////////////////////////////////////////////////////////
    //                       COMPLIANCE                         //
    //////////////////////////////////////////////////////////////
    /// @notice implements ERC721Receiver
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice implements ERC1155Receiver
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @notice implements ERC1155BatchReceiver
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
