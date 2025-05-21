type Constants = {
  BLOCKS_PER_HOUR: number;
}

export const getConstants = (chainId: number): Constants => {
  switch (chainId) {
    case 421614: // arb sepolia
      return {
        BLOCKS_PER_HOUR: 300,
      }
    case 11155420: // optimism sepolia
        return {
            BLOCKS_PER_HOUR: 1800,
        }
    case 11155111: // mainnet sepolia
      return {
        BLOCKS_PER_HOUR: 300,
      }
    default:
      return {
        BLOCKS_PER_HOUR: 300,
      }
  }
}