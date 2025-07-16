type Constants = {
  BLOCKS_PER_HOUR: number; 
}


// Type for deployment returns data
type DeploymentReturns = {
  addresses: {
    internal_type: string;
    value: string; // JSON string array of addresses
  };
  names: {
    internal_type: string;
    value: string; // JSON string array of names
  };
};

// Type for deployment file structure
type DeploymentFile = {
  returns: DeploymentReturns;
};

/**
 * Reads deployment data from DeployLaws.s.sol broadcast files and creates a mapping of law addresses
 * @param chainId - The chain ID to get deployment data for
 * @returns A mapping of law names to their deployed addresses
 */
export const getDeployedLawAddresses = (lawName: string): `0x${string}` | undefined => {
  const lawNames: string[] = [
    "DelegateSelect", "DirectSelect", "PeerSelect", "RenounceRole", "SelfSelect", 
    "BespokeAction", "OpenAction", "PresetAction", "StatementOfIntent", "AddressesMapping", 
    "NominateMe", "StringsArray", "TokensArray", "TaxSelect", "HolderSelect", 
    "Grant", "StartGrant", "EndGrant", "AdoptLaw", "VoteOnAccounts", 
    "DirectDeselect", "Subscription", "StartElection", "EndElection", "GovernorCreateProposal", 
    "GovernorExecuteProposal", "SnapToGov_CheckSnapExists", "SnapToGov_CheckSnapPassed", "SnapToGov_CreateGov", "SnapToGov_CancelGov", 
    "SnapToGov_ExecuteGov"
  ] 
  const lawAddresses: string[] = [
    "0x3Dd2B6982ccC9FBfF3c7995a09649Ca86B92Ba61", "0x458dB0C9930cF11c8C071D782f70414868b0cacD", "0xc29F9C05Ad10F415a0D3b20e70981325DC292774", "0x0F326187968a12A4672a39fE2b11115c2ffF0459", "0x3103B1E05123d0A3D110d891BfB8512aE6D78415", 
    "0x9B5576d05524c371010D44168349EcFcE39629Ac", "0x1dCE375A3e48236a324D3B5981d43987ADAf36Ac", "0xE0E3296bfAed00eD16a0A11d36C4819992c2B705", "0x4d30c1B4f522af77d9208472af616bAE8E550615", "0xB9260dD1b3bf29E81F5C21bC6A7A7B3F3Ce0C832", 
    "0x2274716cBDB7588Bf2dFa09744998DAdD06EdC43", "0xb1115dA4fF650AA685600B37A23009B2cDeCc830", "0x3E38A61C98204c6d507F7Df18015478fEe3ffA47", "0x5E0B5B52340b9b4dF683a7560e0e783E6e7B8F82", "0x525C7Ce8Db8745AD74A4f3110908C775205278d4", 
    "0x07A2FCC652E91B0e80a34F671213C08e5A5180fc", "0x7b4B4dFCee8fe1Fb2f95121f8925e17a9f72F07F", "0x29da0f1A6bFB57AECF9DC114dCbc426400B2B543", "0x84172AC5E14dC09f8E506975D63be04A7d828356", "0x0aB735F24cc09E4E3f692c501BdbE47A999e55bA", 
    "0xDBEf9280dd21d318Ea3b8af18Fe5fC72D7a347eE", "0x9b024C825DBA0f0fa181FE8853A73507e6bA547F", "0xE15d3921fbb83Fd6f7B0d33751344616CDf32254", "0x2B3ebF29548E7d51c26BCFE6d235dA7e9B6874f3", "0x1e181080fA3591D84Bc0eddD8224640088bAeD5E", 
    "0xd5Bd408dA78258D032796a65b7182DC13487eeA9", "0x797594B56fBef90d024121f31737f534D5d188Fa", "0xd21713620305cE99802e143dBB52EC0515513F75", "0x1cA157bf1a6d8B262e7E957a60FAd620Bd46A9d6", "0x070a0b84747DE3F543CC6F2bc2eA0Ecdeb4c0bF5", 
    "0x0eC676F77DAF19c05D03cDfb7095511859370649"
  ] 

  // Find the index of the law name in the names array
  const index = lawNames.indexOf(lawName);
  
  // If the law name is found, return the corresponding address
  if (index !== -1 && index < lawAddresses.length) {
    return lawAddresses[index] as `0x${string}`;
  } else {
    return undefined;
  }
};

export const getConstants = (chainId: number): Constants => {
  switch (chainId) {
    case 421614: // arb sepolia
      return {
        BLOCKS_PER_HOUR: 300
      }
    case 11155420: // optimism sepolia
      return {
        BLOCKS_PER_HOUR: 1800
      }
    case 11155111: // mainnet sepolia
      return {
        BLOCKS_PER_HOUR: 300
      }
    case 31337: // anvil local
      return {
        BLOCKS_PER_HOUR: 300
      }
    default:
      return {
        BLOCKS_PER_HOUR: 300
      }
  }
}