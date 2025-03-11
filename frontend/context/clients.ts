import { http, createPublicClient, createClient } from "viem";
import { foundry, arbitrumSepolia } from "viem/chains";

export const publicClient = createPublicClient({
  chain: arbitrumSepolia,
  // transport: http("http://localhost:8545"), 
  transport: http(process.env.NEXT_PUBLIC_ALCHEMY_ARB_SEPOLIA_HTTPS)
});