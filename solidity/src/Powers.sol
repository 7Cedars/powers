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
    mapping(uint256 actionId => Action) internal _actions; // mapping actionId to Action struct
    mapping(uint16 lawId => ActiveLaw) internal laws; // mapping law address to Law struct
    mapping(uint256 roleId => Role) internal roles; // mapping roleId to Role struct

    // two roles are preset: ADMIN_ROLE == 0 and PUBLIC_ROLE == type(uint256).max.
    uint256 public constant ADMIN_ROLE = type(uint256).min; // == 0
    uint256 public constant PUBLIC_ROLE = type(uint256).max; // == a lot
    uint256 public constant DENOMINATOR = 100; // == 100%

    string public name; // name of the DAO.
    string public uri; // a uri to metadata of the DAO.
    bool private _constituteExecuted; // has the constitute function been called before?
    // NB! this is a gotcha: laws start counting a 1, NOT 0!. 0 is used as a default 'false' value.
    uint16 public lawCount = 1; // number of laws that have been initiated throughout the life of the organisation.

    //////////////////////////////////////////////////////////////
    //                          MODIFIERS                       //
    //////////////////////////////////////////////////////////////
    /// @notice A modifier that sets a function to only be callable by the {Powers} contract.
    modifier onlyPowers() {
        if (msg.sender != address(this)) revert Powers__OnlyPowers();
        _;
    }

    /// @notice A modifier that sets a function to only be callable by the {Powers} contract.
    modifier onlyActiveLaw(uint16 lawId) {
        if (laws[lawId].active == false) revert Powers__LawNotActive();
        _;
    }

    //////////////////////////////////////////////////////////////
    //              CONSTRUCTOR & RECEIVE                       //
    //////////////////////////////////////////////////////////////
    /// @notice  Sets the value for {name} at the time of construction.
    ///
    /// @param name_ name of the contract
    constructor(string memory name_, string memory uri_) EIP712(name_, version()) {
        if (bytes(name_).length == 0) revert Powers__InvalidName();
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
    /// @dev No access control on this function: anyone can send funds in native currency into the contract.
    receive() external payable virtual {
        emit FundsReceived(msg.value, msg.sender);
    }

    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE LOGIC                        //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc IPowers
    /// @dev The execute function follows a call-and-return mechanism. This allows for async execution of laws.
    function request(uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriAction)
        external
        payable
        virtual
        onlyActiveLaw(lawId)
    {
        uint256 actionId = _hashAction(lawId, lawCalldata, nonce);
        ActiveLaw memory law = laws[lawId];

        // check 1: does executioner have access to law being executed?
        if (!canCallLaw(msg.sender, lawId)) revert Powers__AccessDenied();

        // check 2: has action already been set as requested?
        if (_actions[actionId].requested == true) revert Powers__ActionAlreadyInitiated();

        // check 3: is proposedAction cancelled?
        // if law did not need a proposedAction proposedAction vote to start with, check will pass.
        if (_actions[actionId].cancelled == true) revert Powers__ActionCancelled();

        // If checks passed, set action as requested.
        _actions[actionId].caller = msg.sender; // note if caller had been set during proposedAction, it will be overwritten.
        _actions[actionId].lawId = lawId;
        _actions[actionId].requested = true;
        _actions[actionId].lawCalldata = lawCalldata;
        _actions[actionId].uri = uriAction;
        _actions[actionId].nonce = nonce;
        
        // execute law.
        (bool success) = ILaw(law.targetLaw).executeLaw(msg.sender, lawId, lawCalldata, nonce);
        if (!success) revert Powers__LawDidNotPassChecks();

        // emit event.
        emit ActionRequested(msg.sender, lawId, lawCalldata, nonce, uriAction);
    }

    /// @inheritdoc IPowers
    function fulfill(
        uint16 lawId,
        uint256 actionId,
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas
    ) external payable virtual onlyActiveLaw(lawId) {
        ActiveLaw memory law = laws[lawId];
        // check 1: is msg.sender a targetLaw?
        if (!law.active) revert Powers__LawNotActive();

        // check 2: is msg.sender the targetLaw?
        if (law.targetLaw != msg.sender) revert Powers__AccessDenied();

        // check 3: has action already been set as requested?
        if (_actions[actionId].requested != true) revert Powers__ActionNotRequested();

        // check 4: are the lengths of targets, values and calldatas equal?
        if (targets.length != values.length || targets.length != calldatas.length) revert Powers__InvalidCallData();

        // set action as fulfilled.
        _actions[actionId].fulfilled = true;

        // execute targets[], values[], calldatas[] received from law.
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{ value: values[i] }(calldatas[i]);
            Address.verifyCallResult(success, returndata);
        }

        // emit event.
        emit ActionExecuted(lawId, actionId, targets, values, calldatas);
    }

    /// @inheritdoc IPowers
    function propose(uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriAction)
        external
        virtual
        onlyActiveLaw(lawId)
        returns (uint256)
    {
        ActiveLaw memory law = laws[lawId];

        // check 1: is targetLaw is an active law?
        if (!law.active) revert Powers__LawNotActive();

        // check 2: does msg.sender have access to targetLaw?
        if (!canCallLaw(msg.sender, lawId)) revert Powers__AccessDenied();

        // if checks pass: propose.
        return _propose(msg.sender, lawId, lawCalldata, nonce, uriAction);
    }

    /// @notice Internal propose mechanism. Can be overridden to add more logic on proposedAction creation.
    ///
    /// @dev The mechanism checks for the length of targets and calldatas.
    ///
    /// Emits a {SeperatedPowersEvents::proposedActionCreated} event.
    function _propose(
        address caller,
        uint16 lawId,
        bytes calldata lawCalldata,
        uint256 nonce,
        string memory uriAction
    ) internal virtual returns (uint256 actionId) {
        ActiveLaw memory law = laws[lawId];
        // (uint8 quorum,, uint32 votingPeriod,,,,,) = Law(targetLaw).conditions();
        ILaw.Conditions memory conditions = Law(law.targetLaw).getConditions(address(this), lawId);
        actionId = _hashAction(lawId, lawCalldata, nonce);

        // check 1: does target law need proposedAction vote to pass?
        if (conditions.quorum == 0) revert Powers__NoVoteNeeded();

        // check 2: do we have a proposedAction with the same targetLaw and lawCalldata?
        if (_actions[actionId].voteStart != 0) revert Powers__UnexpectedActionState();

        // check 3: do proposedAction checks of the law pass?
        Law(law.targetLaw).checksAtPropose(caller, conditions, lawCalldata, nonce, address(this));

        // if checks pass: create proposedAction
        Action storage proposedAction = _actions[actionId];
        proposedAction.lawCalldata = lawCalldata;
        proposedAction.lawId = lawId;
        proposedAction.voteStart = uint48(block.number); // note that the moment proposedAction is made, voting start. Delay functionality has to be implemeted at the law level.
        proposedAction.voteDuration = conditions.votingPeriod;
        proposedAction.caller = caller;
        proposedAction.uri = uriAction;
        proposedAction.nonce = nonce;
        
        emit ProposedActionCreated(
            actionId,
            caller,
            lawId,
            "",
            lawCalldata,
            block.number,
            block.number + conditions.votingPeriod,
            nonce,
            uriAction
        );
    }

    /// @inheritdoc IPowers
    /// @dev the account to cancel must be the account that created the proposedAction.
    function cancel(uint16 lawId, bytes calldata lawCalldata, uint256 nonce)
        public
        virtual
        onlyActiveLaw(lawId)
        returns (uint256)
    {
        uint256 actionId = _hashAction(lawId, lawCalldata, nonce);
        // only caller can cancel a proposedAction, also checks if proposedAction exists (otherwise _actions[actionId].caller == address(0))
        if (msg.sender != _actions[actionId].caller) revert Powers__AccessDenied();

        return _cancel(lawId, lawCalldata, nonce);
    }

    /// @notice Internal cancel mechanism with minimal restrictions. A proposedAction can be cancelled in any state other than
    /// Cancelled or Executed. Once cancelled a proposedAction cannot be re-submitted.
    /// Emits a {SeperatedPowersEvents::proposedActionCanceled} event.
    function _cancel(uint16 lawId, bytes calldata lawCalldata, uint256 nonce) internal virtual returns (uint256) {
        uint256 actionId = _hashAction(lawId, lawCalldata, nonce);

        // check 1: is action already fulfilled or cancelled?
        if (_actions[actionId].fulfilled || _actions[actionId].cancelled) revert Powers__UnexpectedActionState();

        // set action as cancelled.
        _actions[actionId].cancelled = true;

        // emit event.
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
        uint16 lawId = _actions[actionId].lawId;
        if (!canCallLaw(account, lawId)) revert Powers__AccessDenied();

        // if all this passes: cast vote.
        _countVote(actionId, account, support);

        emit VoteCast(account, actionId, support, reason);
    }

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                      //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc IPowers
    function constitute(LawInitData[] memory constituentLaws) external virtual {
        // check 1: only admin can call this function
        if (roles[ADMIN_ROLE].members[msg.sender] == 0) revert Powers__AccessDenied();
        
        // check 2: this function can only be called once.
        if (_constituteExecuted) revert Powers__ConstitutionAlreadyExecuted();

        // if checks pass, set _constituentLawsExecuted to true...
        _constituteExecuted = true;
        
        // ...and set laws as active.
        for (uint256 i = 0; i < constituentLaws.length; i++) {
            // note: ignore empty slots in LawInitData array.
            if (constituentLaws[i].targetLaw != address(0)) {
                _adoptLaw(constituentLaws[i]);
            }
        }
    }

    /// @inheritdoc IPowers
    function adoptLaw(LawInitData memory lawInitData) public onlyPowers {
        _adoptLaw(lawInitData);
    }

    /// @inheritdoc IPowers
    function revokeLaw(uint16 lawId) public onlyPowers {
        if (laws[lawId].active == false) revert Powers__LawNotActive();

        laws[lawId].active = false;
        emit LawRevoked(lawId);
    }

    /// @notice internal function to set a law or revoke it.
    ///
    /// @param lawInitData data of the law.
    ///
    /// Emits a {SeperatedPowersEvents::LawAdopted} event.
    function _adoptLaw(LawInitData memory lawInitData) internal virtual {
        // check if added address is indeed a law. Note that this will also revert with address(0).
        if (!ERC165Checker.supportsInterface(lawInitData.targetLaw, type(ILaw).interfaceId)) {
            revert Powers__IncorrectInterface();
        }

        laws[lawCount].active = true;
        laws[lawCount].targetLaw = lawInitData.targetLaw;
        lawCount++;

        Law(lawInitData.targetLaw).initializeLaw(
            lawCount - 1, 
            lawInitData.nameDescription,
            "", 
            lawInitData.conditions, 
            lawInitData.config
        );

        // emit event.
        emit LawAdopted(lawCount - 1);
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
        if (roleId == ADMIN_ROLE || roleId == PUBLIC_ROLE) revert Powers__LockedRole();
        roles[roleId].label = label;
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
        if (roleId == PUBLIC_ROLE) revert Powers__CannotAddToPublicRole();
        // check 2: Zero address is not allowed.
        if (account == address(0)) revert Powers__CannotAddZeroAddress();

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
    function _hashAction(uint16 lawId, bytes calldata lawCalldata, uint256 nonce)
        internal
        view
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(lawId, lawCalldata, nonce)));
    }

    /// @notice internal function {quorumReached} that checks if the quorum for a given proposedAction has been reached.
    ///
    /// @param actionId id of the proposedAction.
    ///
    function _quorumReached(uint256 actionId) internal view virtual returns (bool) {
        // retrieve quorum and allowedRole from law.
        Action storage proposedAction = _actions[actionId];
        ActiveLaw memory law = laws[proposedAction.lawId];
        ILaw.Conditions memory conditions = Law(law.targetLaw).getConditions(address(this), proposedAction.lawId);
        uint256 amountMembers = _countMembersRole(conditions.allowedRole);

        // check if quorum is set to 0 in a Law, it will automatically return true. Otherwise, check if quorum has been reached.
        return (
            conditions.quorum == 0
                || amountMembers * conditions.quorum
                    <= (proposedAction.forVotes + proposedAction.abstainVotes) * DENOMINATOR
        );
    }

    /// @notice internal function {voteSucceeded} that checks if a vote for a given proposedAction has succeeded.
    ///
    /// @param actionId id of the proposedAction.
    function _voteSucceeded(uint256 actionId) internal view virtual returns (bool) {
        // retrieve quorum and success threshold from law.
        Action storage proposedAction = _actions[actionId];
        ActiveLaw memory law = laws[proposedAction.lawId];
        ILaw.Conditions memory conditions = Law(law.targetLaw).getConditions(address(this), proposedAction.lawId);
        uint256 amountMembers = _countMembersRole(conditions.allowedRole);

        // note if quorum is set to 0 in a Law, it will automatically return true. Otherwise, check if success threshold has been reached.
        return conditions.quorum == 0 || amountMembers * conditions.succeedAt <= proposedAction.forVotes * DENOMINATOR;
    }

    /// @notice internal function {countVote} that counts against, for, and abstain votes for a given proposedAction.
    ///
    /// @dev In this module, the support follows the `VoteType` enum (from Governor Bravo).
    /// @dev It does not check if account has roleId referenced in actionId. This has to be done by {Powers.castVote} function.
    function _countVote(uint256 actionId, address account, uint8 support) internal virtual {
        Action storage proposedAction = _actions[actionId];

        // check 1: has account already voted?
        if (proposedAction.hasVoted[account]) revert Powers__AlreadyCastVote();

        // set account as voted.
        proposedAction.hasVoted[account] = true;

        // add vote to tally.
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

    /// @notice internal function {countMembersRole} that counts the number of members in a given role.
    /// @dev If needed, this function can be overridden with bespoke logic.
    ///
    /// @param roleId id of the role.
    ///
    /// @return amountMembers number of members in the role.
    function _countMembersRole(uint256 roleId) internal view virtual returns (uint256 amountMembers) {
        return roles[roleId].amountMembers;
    }

    /// @inheritdoc IPowers
    function setUri(string memory newUri) public virtual onlyPowers {
        uri = newUri;
    }

    //////////////////////////////////////////////////////////////
    //                 VIEW / GETTER FUNCTIONS                  //
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

        if (deadline >= block.number) {
            return ActionState.Active;
        } else if (!_quorumReached(actionId) || !_voteSucceeded(actionId)) {
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
    function canCallLaw(address caller, uint16 lawId) public view virtual returns (bool) {
        uint256 allowedRole = Law(laws[lawId].targetLaw).getConditions(address(this), lawId).allowedRole;
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
    function getActionData(uint256 actionId)
        public
        view
        virtual
        returns (
            bool cancelled, 
            bool requested, 
            bool fulfilled, 
            uint16 lawId, 
            uint48 voteStart, 
            uint32 voteDuration, 
            uint256 voteEnd,
            address caller, 
            uint32 againstVotes, 
            uint32 forVotes, 
            uint32 abstainVotes, 
            uint256 nonce
            )
    {
        Action storage action = _actions[actionId];
        return (
            action.cancelled, 
            action.requested, 
            action.fulfilled, 
            action.lawId, 
            action.voteStart, 
            action.voteDuration,
            action.voteStart + action.voteDuration,
            action.caller, 
            action.againstVotes, 
            action.forVotes, 
            action.abstainVotes, 
            action.nonce
        );
    }

    function getActionCalldata(uint256 actionId)
        public
        view
        virtual
        returns (bytes memory callData)
    {
        return _actions[actionId].lawCalldata;
    }

    function getActionUri(uint256 actionId)
        public
        view
        virtual
        returns (string memory _uri)
    {
        _uri = _actions[actionId].uri;
    }

    function getActionNonce(uint256 actionId)
        public
        view
        virtual
        returns (uint256 nonce)
    {
        return _actions[actionId].nonce;
    }

    
    /// @inheritdoc IPowers
    function getAmountRoleHolders(uint256 roleId) public view returns (uint256 amountMembers) {
        return roles[roleId].amountMembers;
    }

    function getRoleLabel(uint256 roleId) public view returns (string memory label) {
        return roles[roleId].label;
    }

    /// @inheritdoc IPowers
    function getProposedActionDeadline(uint256 actionId) public view virtual returns (uint256) {
        // uint48 + uint32 => uint256. £test if this works properly.
        return _actions[actionId].voteStart + _actions[actionId].voteDuration;
    }

    /// @inheritdoc IPowers
    function getActiveLaw(uint16 lawId)
        external
        view
        returns (address law, bytes32 lawHash, bool active)
    {
        law = laws[lawId].targetLaw;
        active = laws[lawId].active;
        lawHash = keccak256(abi.encode(address(this), lawId));

        return (law, lawHash, active);
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
