function createConstitution(
    address payable dao_,
    address payable mock20votes_
    ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
    ILaw.Conditions memory conditions;
    lawInitData = new PowersTypes.LawInitData[](8);

    // dummy call for preset actions
    address[] memory targets = new address[](1);
    uint256[] memory values = new uint256[](1);
    bytes[] memory calldatas = new bytes[](1);
    targets[0] = address(123);
    calldatas[0] = abi.encode("mockCall");

    // directSelect
    conditions.allowedRole = type(uint32).max;
    lawInitData[1] = PowersTypes.LawInitData({
        targetLaw: calculateLawAddress(
            creationCodes[1],
            "DirectSelect"
        ),
        config: abi.encode(1), // role that can be assigned
        conditions: conditions,
        description: "A law to select an account to a specific role directly."
    });
    delete conditions;

    // nominateMe
    conditions.allowedRole = type(uint32).max;
    lawInitData[2] = PowersTypes.LawInitData({
        targetLaw: calculateLawAddress(
            creationCodes[10],
            "NominateMe"
        ),
        config: abi.encode(), // empty config
        conditions: conditions,
        description: "A law for accounts to nominate themselves for a role."
    });
    delete conditions;

    // delegateSelect
    conditions.allowedRole = 1;
    lawInitData[3] = PowersTypes.LawInitData({
        targetLaw: calculateLawAddress(
            creationCodes[0],
            "DelegateSelect"
        ),
        config: abi.encode(
            mock20votes_,
            15, // max role holders
            2 // roleId to be elected
        ),
        conditions: conditions,
        description: "A law to select a role by delegated votes."
    });
    delete conditions;

    // proposalOnly
    string[] memory inputParams = new string[](3);
    inputParams[0] = "targets address[]";
    inputParams[1] = "values uint256[]";
    inputParams[2] = "calldatas bytes[]";

    conditions.allowedRole = 3;
    lawInitData[4] = PowersTypes.LawInitData({
        targetLaw: calculateLawAddress(
            creationCodes[8],
            "ProposalOnly"
        ),
        config: abi.encode(inputParams),
        conditions: conditions,
        description: "A law to propose a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented."
    });
    delete conditions;

    // OpenAction
    conditions.allowedRole = 2;
    conditions.quorum = 20; // = 30% quorum needed
    conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members
    conditions.votingPeriod = 1200; // = number of blocks
    lawInitData[5] = PowersTypes.LawInitData({
        targetLaw: calculateLawAddress(
            creationCodes[6],
            "OpenAction"
        ),
        config: abi.encode(), // empty config
        conditions: conditions,
        description: "A law to execute an open action."
    });
    delete conditions;

    // PresetAction
    conditions.allowedRole = 1;
    conditions.quorum = 30; // = 30% quorum needed
    conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members
    conditions.votingPeriod = 1200; // = number of blocks
    conditions.needCompleted = 3;
    lawInitData[6] = PowersTypes.LawInitData({
        targetLaw: calculateLawAddress(
            creationCodes[7],
            "PresetAction"
        ),
        config: abi.encode(targets, values, calldatas),
        conditions: conditions,
        description: "A law to execute a preset action."
    });
    delete conditions;

    // PresetAction for roles
    (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
        _getRoles(dao_, 7);
    conditions.allowedRole = 0;
    lawInitData[7] = PowersTypes.LawInitData({
        targetLaw: calculateLawAddress(
            creationCodes[7],
            "PresetAction"
        ),
        config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
        conditions: conditions,
        description: "A law to execute a preset action."
    });
    delete conditions;
}

function _getRoles(address payable dao_, uint16 lawId)
    internal
    returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
{
    // create addresses
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlotte = makeAddr("charlotte");
    address david = makeAddr("david");
    address eve = makeAddr("eve");
    address frank = makeAddr("frank");
    address gary = makeAddr("gary");
    address helen = makeAddr("helen");

    // call to set initial roles
    targets = new address[](13);
    values = new uint256[](13);
    calldatas = new bytes[](13);
    for (uint256 i = 0; i < targets.length; i++) {
        targets[i] = dao_;
    }

    calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, alice);
    calldatas[1] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, bob);
    calldatas[2] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, charlotte);
    calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, david);
    calldatas[4] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, eve);
    calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, frank);
    calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, gary);
    calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, alice);
    calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, bob);
    calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, charlotte);
    calldatas[10] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, alice);
    calldatas[11] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, bob);
    // revoke law after use
    if (lawId != 0) {
        calldatas[12] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
    }

    return (targets, values, calldatas);
}

function calculateLawAddress(bytes memory creationCode, string memory name)
    public
    returns (address computedAddress)
{
    bytes32 salt = bytes32(abi.encodePacked(name));
    address create2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C; // is a constant across chains

    computedAddress = Create2.computeAddress(
        salt,
        keccak256(abi.encodePacked(creationCode, abi.encode(name))),
        create2Factory
    );
    if (computedAddress.code.length == 0) {
        revert("Law does not exist. Did you make a typo or does the law really not exist?");
    }
    return computedAddress;
} 