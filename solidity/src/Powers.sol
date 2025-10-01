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

/// @title Powers Protocol v.0.4
/// @notice Powers is a Role Based Governance Protocol. It provides a modular, flexible,  DAOs.
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
import { PowersUtilities } from "./PowersUtilities.sol";
import { ERC165Checker } from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import { Address } from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { EIP712 } from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

// import { console2 } from "forge-std/console2.sol"; // remove before deploying.

contract Powers is EIP712, IPowers {
    //////////////////////////////////////////////////////////////
    //                           STORAGE                        //
    /////////////////////////////////////////////////////////////
    mapping(uint256 actionId => Action) internal _actions; // mapping actionId to Action struct
    mapping(uint16 lawId => AdoptedLaw) internal laws; //mapping law address to Law struct
    mapping(uint256 roleId => Role) internal roles; // mapping roleId to Role struct)
    mapping(address account => bool blacklisted) internal _blacklist; // mapping accounts to blacklisted status

    // two roles are preset: ADMIN_ROLE == 0 and PUBLIC_ROLE == type(uint256).max.
    uint256 public constant ADMIN_ROLE = type(uint256).min; // == 0
    uint256 public constant PUBLIC_ROLE = type(uint256).max; // == a lot
    uint256 public constant DENOMINATOR = 100; // == 100%

    uint256 public immutable MAX_CALLDATA_LENGTH;  
    uint256 public immutable MAX_EXECUTIONS_LENGTH; 
    
    // NB! this is a gotcha: laws start counting a 1, NOT 0!. 0 is used as a default 'false' value.
    uint16 public lawCount = 1; // number of laws that have been initiated throughout the life of the organisation.
    string public name; // name of the DAO.  
    string public uri; // a uri to metadata of the DAO. // note can be altered 
    bool public payableEnabled; // is payable enabled?
    bool private _constituteExecuted; // has the constitute function been called before?

    //////////////////////////////////////////////////////////////
    //                          MODIFIERS                       //
    //////////////////////////////////////////////////////////////
    /// @notice A modifier that sets a function to only be callable by the {Powers} contract.
    modifier onlyPowers() {
        if (msg.sender != address(this)) revert Powers__OnlyPowers();
        _;
    }

    /// @notice A modifier that sets a function to only be callable by the {Powers} contract.
    modifier onlyAdoptedLaw(uint16 lawId) {
        if (laws[lawId].active == false) revert Powers__LawNotActive();
        _;
    }

    //////////////////////////////////////////////////////////////
    //              CONSTRUCTOR & RECEIVE                       //
    //////////////////////////////////////////////////////////////
    /// @notice  Sets the value for {name} at the time of construction.
    ///
    /// @param name_ name of the contract

    // TODO: add validation params here. 
    constructor(string memory name_, string memory uri_, uint256 maxCallDataLength, uint256 maxExecutionsLength) EIP712(name_, version()) {
        if (bytes(name_).length == 0) revert Powers__InvalidName();
        name = name_;
        uri = uri_;
        MAX_CALLDATA_LENGTH = maxCallDataLength;
        MAX_EXECUTIONS_LENGTH = maxExecutionsLength;

        _setRole(ADMIN_ROLE, msg.sender, true); // the account that initiates a Powerscontract is set to its admin.

        emit Powers__Initialized(address(this), name, uri);
    }

    /// @notice receive function enabling ETH deposits.
    ///
    /// @dev This is a virtual function, and can be overridden in the DAO implementation.
    /// @dev If payable is enabled, anyone can send funds in native currency into the contract.
    /// @dev No access control on this function. 
    receive() external payable virtual {
        if (!payableEnabled) revert Powers__PayableNotEnabled();
        emit FundsReceived(msg.value, msg.sender);
    }

    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE LOGIC                        //
    //////////////////////////////////////////////////////////////
    /// @inheritdoc IPowers
    /// @dev The request -> fulfill functions follow a call-and-return mechanism. This allows for async execution of laws.
    function request(uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriAction)
        external
        payable
        virtual
        onlyAdoptedLaw(lawId)
        returns (uint256 actionId)
    {
        actionId = _hashAction(lawId, lawCalldata, nonce);
        AdoptedLaw memory law = laws[lawId];

        // check 0 is calldata length is too long
        if (lawCalldata.length > MAX_CALLDATA_LENGTH) revert Powers__CalldataTooLong();

        // check 1: is msg.sender blacklisted?
        if (isBlacklisted(msg.sender)) revert Powers__AddressBlacklisted();

        // check 2: does caller have access to law being executed?
        if (!canCallLaw(msg.sender, lawId)) revert Powers__CannotCallLaw();

        // check 3: has action already been set as requested?
        if (_hasBeenRequested(actionId)) revert Powers__ActionAlreadyInitiated();

        // check 4: is proposedAction cancelled?
        if (_actions[actionId].cancelledAt > 0) revert Powers__ActionCancelled();

        // check 5: do checks pass? 
        PowersUtilities.checksAtRequest(lawId, lawCalldata, address(this), nonce, law.fulfilledAt);

        // If everything passed, set action as requested.
        Action storage action = _actions[actionId];
        action.caller = msg.sender; // note if caller had been set during proposedAction, it will be overwritten.
        action.lawId = lawId;
        action.requestedAt = uint48(block.number);
        action.lawCalldata = lawCalldata;
        action.uri = uriAction;
        action.nonce = nonce;

        // execute law.
        (bool success) = ILaw(law.targetLaw).executeLaw(msg.sender, lawId, lawCalldata, nonce);
        if (!success) revert Powers__LawRequestFailed();

        // emit event.
        emit ActionRequested(msg.sender, lawId, lawCalldata, nonce, uriAction);

        return actionId;
    }

    /// @inheritdoc IPowers
    function fulfill(
        uint16 lawId,
        uint256 actionId,
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas
    ) external payable virtual onlyAdoptedLaw(lawId) {
        AdoptedLaw memory law = laws[lawId];

        // check 1: is law active?
        if (!law.active) revert Powers__LawNotActive();

        // check 2: is msg.sender the targetLaw?
        if (law.targetLaw != msg.sender) revert Powers__CallerNotTargetLaw();

        // check 3: has action already been set as requested?
        if (!_hasBeenRequested(actionId)) revert Powers__ActionNotRequested();

        // check 4: has action already been fulfilled?
        if (_actions[actionId].fulfilledAt > 0) revert Powers__ActionAlreadyFulfilled();

        // check 5: are the lengths of targets, values and calldatas equal?
        if (targets.length != values.length || targets.length != calldatas.length) revert Powers__InvalidCallData();

        // check 6: check array length is too long
        if (targets.length > MAX_EXECUTIONS_LENGTH) revert Powers__ExecutionArrayTooLong();

        // check 7: for each target, check if calldata does not exceed MAX_CALLDATA_LENGTH + targets have not been blacklisted. 
        for (uint256 i = 0; i < targets.length; ++i) {
            if (calldatas[i].length > MAX_CALLDATA_LENGTH) revert Powers__CalldataTooLong();
            if (isBlacklisted(targets[i])) revert Powers__AddressBlacklisted();
        }

        // set action as fulfilled
        _actions[actionId].fulfilledAt = uint48(block.number);

        // execute targets[], values[], calldatas[] received from law.
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{ value: values[i] }(calldatas[i]);
            Address.verifyCallResult(success, returndata);
        }

        // register fulfillment at law.
        laws[lawId].fulfilledAt.push(uint48(block.number));
        laws[lawId].actionIds.push(actionId);

        // emit event.
        emit ActionExecuted(lawId, actionId, targets, values, calldatas);
    }

    /// @inheritdoc IPowers
    function propose(uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriAction)
        external
        virtual
        onlyAdoptedLaw(lawId)
        returns (uint256 actionId)
    {
        AdoptedLaw memory law = laws[lawId];

        // check 1: is targetLaw is an active law?
        if (!law.active) revert Powers__LawNotActive();

        // check 2: does msg.sender have access to targetLaw?
        if (!canCallLaw(msg.sender, lawId)) revert Powers__CannotCallLaw();

        // check 3: is caller blacklisted?
        if (isBlacklisted(msg.sender)) revert Powers__AddressBlacklisted();

        // check 4: is caller too long?
        if (lawCalldata.length > MAX_CALLDATA_LENGTH) revert Powers__CalldataTooLong();

        // if checks pass: propose.
        actionId = _propose(msg.sender, lawId, lawCalldata, nonce, uriAction);

        return actionId;
    }

    /// @notice Internal propose mechanism. Can be overridden to add more logic on proposedAction creation.
    ///
    /// @dev The mechanism checks for the length of targets and calldatas.
    ///
    /// Emits a {SeperatedPowersEvents::proposedActionCreated} event.
    function _propose(address caller, uint16 lawId, bytes calldata lawCalldata, uint256 nonce, string memory uriAction)
        internal
        virtual
        returns (uint256 actionId)
    {
        // (uint8 quorum,, uint32 votingPeriod,,,,,) = Law(targetLaw).conditions();
        Conditions memory conditions = getConditions(lawId);
        actionId = _hashAction(lawId, lawCalldata, nonce);

        // check 1: does target law need proposedAction vote to pass?
        if (conditions.quorum == 0) revert Powers__NoVoteNeeded();

        // check 2: do we have a proposedAction with the same targetLaw and lawCalldata?
        if (_actions[actionId].voteStart != 0) revert Powers__UnexpectedActionState();

        // check 3: do proposedAction checks of the law pass?
       PowersUtilities.checksAtPropose(lawId, lawCalldata, address(this), nonce);

        // if checks pass: create proposedAction
        Action storage action = _actions[actionId];
        action.lawCalldata = lawCalldata;
        action.proposedAt = uint48(block.number);
        action.lawId = lawId;
        action.voteStart = uint48(block.number); // note that the moment proposedAction is made, voting start. Delay functionality has to be implemeted at the law level.
        action.voteDuration = conditions.votingPeriod;
        action.caller = caller;
        action.uri = uriAction;
        action.nonce = nonce;

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
        onlyAdoptedLaw(lawId)
        returns (uint256)
    {
        uint256 actionId = _hashAction(lawId, lawCalldata, nonce);
        
        // check: is caller the caller of the proposedAction?
        if (msg.sender != _actions[actionId].caller) revert Powers__NotProposerAction();
 
        return _cancel(lawId, lawCalldata, nonce);
    }

    /// @notice Internal cancel mechanism with minimal restrictions. A proposedAction can be cancelled in any state other than
    /// Cancelled or Executed. Once cancelled a proposedAction cannot be re-submitted.
    /// Emits a {SeperatedPowersEvents::proposedActionCanceled} event.
    function _cancel(uint16 lawId, bytes calldata lawCalldata, uint256 nonce) internal virtual returns (uint256) {
        uint256 actionId = _hashAction(lawId, lawCalldata, nonce);

        // check 1: does action exist? 
        if (_actions[actionId].proposedAt == 0) revert Powers__ActionNotProposed();

        // check 2: is action already fulfilled or cancelled?
        if (_actions[actionId].fulfilledAt > 0 || _actions[actionId].cancelledAt > 0) revert Powers__UnexpectedActionState();  

        // set action as cancelled.
        _actions[actionId].cancelledAt = uint48(block.number);

        // emit event.
        emit ProposedActionCancelled(actionId);

        return actionId;
    }

    /// @inheritdoc IPowers
    function castVote(uint256 actionId, uint8 support) external virtual {
        return _castVote(actionId, msg.sender, support, "");
    }

    /// @inheritdoc IPowers
    function castVoteWithReason(uint256 actionId, uint8 support, string calldata reason) public virtual {
        return _castVote(actionId, msg.sender, support, reason);
    }

    /// @notice Internal vote casting mechanism.
    /// Check that the proposedAction is active, and that account is has access to targetLaw.
    ///
    /// Emits a {SeperatedPowersEvents::VoteCast} event.
    function _castVote(uint256 actionId, address account, uint8 support, string memory reason) internal virtual {
        // Check that the proposedAction is active, that it has not been paused, cancelled or ended yet.
        if (getActionState(actionId) != ActionState.Active) {
            revert Powers__ProposedActionNotActive();
        }

        // Note that we check if account has access to the law targetted in the proposedAction.
        uint16 lawId = _actions[actionId].lawId;
        if (!canCallLaw(account, lawId)) revert Powers__CannotCallLaw();
 
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
        if (roles[ADMIN_ROLE].members[msg.sender] == 0) revert Powers__NotAdmin();

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
    function adoptLaw(LawInitData memory lawInitData) public onlyPowers returns (uint256 lawId) {
        lawId = _adoptLaw(lawInitData);

        return lawId;
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
    function _adoptLaw(LawInitData memory lawInitData) internal virtual returns (uint256 lawId) {
        // check if added address is indeed a law. Note that this will also revert with address(0).
        if (!ERC165Checker.supportsInterface(lawInitData.targetLaw, type(ILaw).interfaceId)) {
            revert Powers__IncorrectInterface();
        }

        // check if targetLaw is blacklisted
        if (isBlacklisted(lawInitData.targetLaw)) revert Powers__AddressBlacklisted();

        // if checks pass, set law as active.
        laws[lawCount].active = true;
        laws[lawCount].targetLaw = lawInitData.targetLaw;
        laws[lawCount].conditions = lawInitData.conditions;
        lawCount++;

        Law(lawInitData.targetLaw).initializeLaw(
            lawCount - 1, lawInitData.nameDescription, "", lawInitData.config
        );

        // emit event.
        emit LawAdopted(lawCount - 1);

        return lawCount - 1;
    }

    /// @inheritdoc IPowers
    function assignRole(uint256 roleId, address account) public onlyPowers {
        if (isBlacklisted(account)) revert Powers__AddressBlacklisted();

        _setRole(roleId, account, true);
    }

    /// @inheritdoc IPowers
    function revokeRole(uint256 roleId, address account) public onlyPowers {
        _setRole(roleId, account, false);
    }

    /// @inheritdoc IPowers
    function labelRole(uint256 roleId, string memory label) public virtual onlyPowers {
        if (roleId == ADMIN_ROLE || roleId == PUBLIC_ROLE) revert Powers__LockedRole();
        if (bytes(label).length == 0) revert Powers__InvalidLabel();
        if (bytes(label).length > 255) revert Powers__LabelTooLong();

        roles[roleId].label = label;
        emit RoleLabel(roleId, label);
    }

    /// @notice Internal version of {setRole} without access control.
    /// @dev This function is used to set a role for a given account. Public role is locked as everyone has it.
    /// @dev Note that it does allow Admin role to be assigned and revoked.
    /// @dev Note that the function does not revert if trying to remove a role someone does not have, or add a role someone already has. 
    ///
    /// Emits a {SeperatedPowersEvents::RolSet} event.
    function _setRole(uint256 roleId, address account, bool access) internal virtual {
        // check 1: Public role is locked.
        if (roleId == PUBLIC_ROLE) revert Powers__CannotSetPublicRole();
        // check 2: Zero address is not allowed.
        if (account == address(0)) revert Powers__CannotAddZeroAddress();
        
        bool newMember = roles[roleId].members[account] == 0;
        // add role if role requested and account does not already have role.         
        if (access && newMember) {
            roles[roleId].members[account] = roles[roleId].membersArray.length + 1; // 'index of new member is length of array + 1. index = 0 is used a 'undefined' value.. 
            roles[roleId].membersArray.push(Member(account, uint48(block.number)));
        // remove role if access set to false and account has role. 
        } else if (!access && !newMember) {
            uint256 indexEnd = roles[roleId].membersArray.length - 1;
            Member memory memberEnd = roles[roleId].membersArray[indexEnd];
            uint256 indexAccount = roles[roleId].members[account];  

            // updating array. Note that 1 is added to the index to avoid 0 index of first member in array. We here have to subtract it. 
            roles[roleId].membersArray[indexAccount - 1] = memberEnd; // replace account with last member account.
            roles[roleId].membersArray.pop(); // remove last member.
            
            // updating indices in mapping. 
            roles[roleId].members[memberEnd.account] = indexAccount; // update index of last member in list
            roles[roleId].members[account] = 0; // 'index of removed member is set to 0.
        }
        // note: nothing happens when 1: access is requested and not a new member 2: access is false and account does not have role. No revert. 

        emit RoleSet(roleId, account, access);
    }

    /// @inheritdoc IPowers
    function blacklistAddress(address account, bool blacklisted) public virtual onlyPowers {
        _blacklist[account] = blacklisted;
        emit BlacklistSet(account, blacklisted);
    }

    /// @inheritdoc IPowers
    function setPayableEnabled(bool payableEnabled_) public virtual onlyPowers {
        payableEnabled = payableEnabled_;
    } 

    /// @inheritdoc IPowers
    function setUri(string memory newUri) public virtual onlyPowers {
        uri = newUri;
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
        Conditions memory conditions = getConditions(proposedAction.lawId);
        uint256 amountMembers = _countMembersRole(conditions.allowedRole);

        // check if quorum is set to 0 in a Law, it will automatically return true. Otherwise, check if quorum has been reached.
        return (
            conditions.quorum == 0
                || amountMembers * conditions.quorum
                    <= (proposedAction.forVotes + proposedAction.abstainVotes) * DENOMINATOR
        );
    }

    // @notice internal function {_hasBeenRequested} that checks if a given action has been requested.
    ///
    /// @param actionId id of the action.
    ///
    /// @return bool true if the action has been requested, false otherwise.
    function _hasBeenRequested(uint256 actionId) internal view virtual returns (bool) {
        ActionState state = getActionState(actionId);
        if (state == ActionState.Requested || state == ActionState.Fulfilled) {
            return true;
        }
        return false;
    }

    // @notice internal function {hasBeenProposed} that checks if a given action has been proposed.
    ///
    /// @param actionId id of the action.
    ///
    /// @return bool true if the action has been proposed, false otherwise.
    function _hasBeenProposed(uint256 actionId) internal view virtual returns (bool) {
        ActionState state = getActionState(actionId);
        if (
            state != ActionState.NonExistent
            ) {
                return true;
        }
        return false;
    }

    /// @notice internal function {voteSucceeded} that checks if a vote for a given proposedAction has succeeded.
    ///
    /// @param actionId id of the proposedAction.
    function _voteSucceeded(uint256 actionId) internal view virtual returns (bool) {
        // retrieve quorum and success threshold from law.
        Action storage proposedAction = _actions[actionId];
        Conditions memory conditions = getConditions(proposedAction.lawId);
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
        return roles[roleId].membersArray.length;
    }

    //////////////////////////////////////////////////////////////
    //                 VIEW / GETTER FUNCTIONS                  //
    //////////////////////////////////////////////////////////////
    /// @notice saves the version of the Powersimplementation.
    function version() public pure returns (string memory) {
        return "0.4";
    }

    /// @inheritdoc IPowers
    function canCallLaw(address caller, uint16 lawId) public view virtual returns (bool) {
        uint256 allowedRole = getConditions(lawId).allowedRole;
        uint48 since = hasRoleSince(caller, allowedRole);

        return since != 0 || allowedRole == PUBLIC_ROLE;
    }

    /// @inheritdoc IPowers
    function hasRoleSince(address account, uint256 roleId) public view returns (uint48 since) {
        uint256 index = roles[roleId].members[account];
        if (index == 0) {
            return 0;
        }
        return roles[roleId].membersArray[index - 1].since;
    }

    /// @inheritdoc IPowers
    function getAmountRoleHolders(uint256 roleId) public view returns (uint256 amountMembers) {
        return roles[roleId].membersArray.length;
    }

    function getRoleHolders(uint256 roleId) public view returns (address[] memory members) {
        members = new address[](roles[roleId].membersArray.length);
        if (roles[roleId].membersArray.length == 0) {
            return new address[](0);
        }
        for (uint256 i = 0; i < roles[roleId].membersArray.length; i++) {
            members[i] = roles[roleId].membersArray[i].account;
        }
        return members;
    }

    function getRoleLabel(uint256 roleId) public view returns (string memory label) {
        return roles[roleId].label;
    }
    
    /// @inheritdoc IPowers
    function getActionState(uint256 actionId) public view virtual returns (ActionState) {
        // We read the struct fields into the stack at once so Solidity emits a single SLOAD
        Action storage action = _actions[actionId];

        if (action.proposedAt == 0 && action.requestedAt == 0 && action.fulfilledAt == 0 && action.cancelledAt == 0) {
            return ActionState.NonExistent;
        }
        if (action.fulfilledAt > 0) {
            return ActionState.Fulfilled;
        }
        if (action.cancelledAt > 0) {
            return ActionState.Cancelled;
        }
        if (action.requestedAt > 0) {
            return ActionState.Requested;
        }

        uint256 deadline = getActionDeadline(actionId);

        if (deadline >= block.number) {
            return ActionState.Active;
        } else if (!_quorumReached(actionId) || !_voteSucceeded(actionId)) {
            return ActionState.Defeated;
        } else {
            return ActionState.Succeeded;
        }
    }

    /// @inheritdoc IPowers
    function getActionData(uint256 actionId)
        public
        view
        virtual
        returns (
            uint16 lawId,
            uint48 proposedAt,
            uint48 requestedAt,
            uint48 fulfilledAt,
            uint48 cancelledAt,
            address caller,
            uint256 nonce
        )
    {
        Action storage action = _actions[actionId];

        return (
            action.lawId,
            action.proposedAt,
            action.requestedAt,
            action.fulfilledAt,
            action.cancelledAt,
            action.caller,
            action.nonce
        );
    }

    function getActionVoteData(uint256 actionId) 
        public 
        view 
        virtual 
        returns (
            uint48 voteStart,
            uint32 voteDuration,
            uint256 voteEnd,
            uint32 againstVotes, 
            uint32 forVotes, 
            uint32 abstainVotes
            ) 
        {
        Action storage action = _actions[actionId];

        return (
            action.voteStart,
            action.voteDuration,
            action.voteStart + action.voteDuration,
            action.againstVotes,
            action.forVotes,
            action.abstainVotes
        );
    }

    function getActionCalldata(uint256 actionId) public view virtual returns (bytes memory callData) {
        return _actions[actionId].lawCalldata;
    }

    function getActionUri(uint256 actionId) public view virtual returns (string memory _uri) {
        _uri = _actions[actionId].uri;
    }

    function getActionNonce(uint256 actionId) public view virtual returns (uint256 nonce) {
        return _actions[actionId].nonce;
    }

    /// @inheritdoc IPowers
    function getActionDeadline(uint256 actionId) public view virtual returns (uint256) {
        // uint48 + uint32 => uint256. £test if this works properly.
        return _actions[actionId].voteStart + _actions[actionId].voteDuration;
    }

    /// @inheritdoc IPowers
    function hasVoted(uint256 actionId, address account) public view virtual returns (bool) {
        return _actions[actionId].hasVoted[account];
    }

    /// @inheritdoc IPowers
    function getAdoptedLaw(uint16 lawId) external view returns (address law, bytes32 lawHash, bool active) {
        law = laws[lawId].targetLaw;
        active = laws[lawId].active;
        lawHash = keccak256(abi.encode(address(this), lawId));

        return (law, lawHash, active);
    }

    function getConditions(uint16 lawId) public view returns (Conditions memory conditions) {
        return laws[lawId].conditions;
    } 

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
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
