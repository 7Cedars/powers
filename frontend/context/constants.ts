type Constants = {
  BLOCKS_PER_HOUR: number;
  LAW_ADDRESSES: {
    [key: string]: string;
  };
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
export const getDeployedLawAddresses = (chainId: number): { [key: string]: string } => {
  const lawAddresses: { [key: string]: string } = {};
  
  try {
    // Import the deployment file dynamically based on chain ID
    const deploymentData = require(`../../solidity/broadcast/DeployLaws.s.sol/${chainId}/run-latest.json`) as DeploymentFile;
    
    // Use the returns data from the deployment script
    if (deploymentData && deploymentData.returns) {
      const { addresses, names } = deploymentData.returns;
      
      // Parse the JSON string arrays
      const addressArray = JSON.parse(addresses.value);
      const nameArray = JSON.parse(names.value);
      
      // Create mapping from names to addresses
      if (addressArray.length === nameArray.length) {
        nameArray.forEach((name: string, index: number) => {
          lawAddresses[name] = addressArray[index];
        });
      }
    }
  } catch (error) {
    console.warn(`Could not load deployment data for chain ${chainId}:`, error);
  }
  
  return lawAddresses;
};

export const getConstants = (chainId: number): Constants => {
  switch (chainId) {
    case 421614: // arb sepolia
      return {
        BLOCKS_PER_HOUR: 300,
        LAW_ADDRESSES: {
          ...getDeployedLawAddresses(421614),
          // Fallback addresses if deployment data is not available
          "": "0x0000000000000000000000000000000000000000",
        },
      }
    case 11155420: // optimism sepolia
        return {
          BLOCKS_PER_HOUR: 1800,
          LAW_ADDRESSES: {
            ...getDeployedLawAddresses(11155420),
            // Fallback addresses if deployment data is not available
            "0x0000000000000000000000000000000000000000": "0x0000000000000000000000000000000000000000",
          },
        }
    case 11155111: // mainnet sepolia
      return {
        BLOCKS_PER_HOUR: 300,
        LAW_ADDRESSES: {
          ...getDeployedLawAddresses(11155111),
          // Fallback addresses if deployment data is not available
          "0x0000000000000000000000000000000000000000": "0x0000000000000000000000000000000000000000",
        },
      }
    case 31337: // anvil local
      return {
        BLOCKS_PER_HOUR: 300,
        LAW_ADDRESSES: {
          ...getDeployedLawAddresses(31337),
        },
      }
    default:
      return {
        BLOCKS_PER_HOUR: 300,
        LAW_ADDRESSES: {
          ...getDeployedLawAddresses(chainId),
        },
      }
  }
}