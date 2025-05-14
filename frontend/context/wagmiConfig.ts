import { createConfig, http, webSocket } from '@wagmi/core'
import { foundry, sepolia, polygonMumbai, baseSepolia, optimismSepolia, arbitrumSepolia, mainnet, xLayerTestnet } from '@wagmi/core/chains'

// [ = preferred ]
export const wagmiConfig = createConfig({
  chains: [sepolia, arbitrumSepolia, optimismSepolia, baseSepolia, foundry], //  foundry,  arbitrumSepolia, sepolia,  baseSepolia, [ optimismSepolia ], polygonMumbai
  batch: { multicall: true }, 
  transports: {
    [sepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_SEPOLIA_HTTPS), 
    [arbitrumSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_ARB_SEPOLIA_HTTPS), 
    [optimismSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_OPT_SEPOLIA_HTTPS),
    [baseSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_BASE_SEPOLIA_HTTPS),
    [foundry.id]: http("http://localhost:8545"),   
  },
  ssr: true,
  // storage: createStorage({
  //   storage: cookieStorage
  // })
})