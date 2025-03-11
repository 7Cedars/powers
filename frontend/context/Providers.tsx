'use client';

import { PrivyClientConfig, PrivyProvider } from '@privy-io/react-auth';
import { arbitrumSepolia} from 'viem/chains';
import { wagmiConfig } from './wagmiConfig'  
import {WagmiProvider} from '@privy-io/wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const queryClient = new QueryClient()

const privyConfig: PrivyClientConfig = {
  defaultChain: arbitrumSepolia,
  supportedChains: [arbitrumSepolia],
  // loginMethods: ['wallet'],
  appearance: {
      theme: 'light',
      accentColor: '#676FFF',
      logo: '/logo.png', 
      walletList: ["metamask", "coinbase_wallet", "rainbow", "phantom", "zerion", "detected_wallets", "wallet_connect" ]
  }
};

export function Providers({children}: {children: React.ReactNode}) {
  return (  
      <PrivyProvider
        appId={process.env.NEXT_PUBLIC_PRIVY_APP_ID as string}
        // clientId={process.env.NEXT_PUBLIC_PRIVY_CLIENT_ID as string} 
        config={privyConfig} 
        >
          <QueryClientProvider client={queryClient}>
            <WagmiProvider config={wagmiConfig}>
                {children}
            </WagmiProvider>
          </QueryClientProvider>
      </PrivyProvider> 
  );
}