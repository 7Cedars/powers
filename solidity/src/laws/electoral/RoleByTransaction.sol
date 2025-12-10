// SPDX-License-Identifier: MIT

/// @notice A simple law that assigns a role after a succesful transaction of a specific token and preset amount.
// It is a simple threshold logic. If the transfer is of sufficient size & succesful, the role is granted.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";

// import "forge-std/Test.sol"; // for testing only. remove before deployment.

contract RoleByTransaction is Law {
    struct Data {
        uint256 newRoleId;
        address token;
        uint256 thresholdAmount;
        address safeProxy;
    }

    struct Mem {
        address token;
        uint256 amount;
        uint256 newRoleId;
        address safeProxy;
    }

    mapping(bytes32 lawHash => Data data) public data;

    /// @notice Constructor for RoleByRoles law
    constructor() {
        bytes memory configParams =
            abi.encode("address Token", "uint256 ThresholdAmount", "uint256 NewRoleId", "address SafeProxy");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {   
        Mem memory mem;

        (mem.token, mem.amount, mem.newRoleId, mem.safeProxy) =
            abi.decode(config, (address, uint256, uint256, address));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        if (mem.token == address(0)) {
            revert ("Native token transfers not supported");
        }
        data[lawHash] = Data({ token: mem.token, thresholdAmount: mem.amount, newRoleId: mem.newRoleId, safeProxy: mem.safeProxy });

        inputParams = abi.encode("uint256 Amount");

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step 1: decode the calldata & create hashes
        (uint256 amount) = abi.decode(lawCalldata, (uint256));
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        calldatas = new bytes[](2);
        calldatas[0] = lawCalldata;
        calldatas[1] = abi.encode(caller);
    }

    function _externalCall(
        uint16 lawId,
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal override {
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, lawId);
        Data memory data_ = data[lawHash];
        uint256 amount = abi.decode(calldatas[0], (uint256));
        address account = abi.decode(calldatas[1], (address));
        bool success;

        require(amount >= data_.thresholdAmount, "Amount below threshold");

        if (data_.token == address(0)) {
            (success,) = data_.safeProxy.call{ value: amount }("");
        } else {
            (success,) = data_.token
                .call(
                    abi.encodeWithSignature("transferFrom(address,address,uint256)", account, data_.safeProxy, amount)
                );
        }
        require(success, "Transaction failed");

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = msg.sender;
        calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, data_.newRoleId, account);

        // step 2: execute the role assignment if the amount threshold is met
        _replyPowers(lawId, actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
