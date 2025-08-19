'use client';

import { useState, useEffect } from 'react';
import { useBlockNumber, usePublicClient } from 'wagmi';
import { ArrowPathIcon } from '@heroicons/react/24/outline';

export function BlockCounter() {
  const [blockNumber, setBlockNumber] = useState<bigint | undefined>(undefined);
  const [isLoading, setIsLoading] = useState(false);
  const publicClient = usePublicClient();

  // Fetch initial block number
  useEffect(() => {
    const fetchBlockNumber = async () => {
      if (!publicClient) return;
      
      try {
        const number = await publicClient.getBlockNumber();
        setBlockNumber(number);
      } catch (error) {
        console.error('Failed to fetch block number:', error);
      }
    };

    fetchBlockNumber();
  }, [publicClient]);

  const handleRefresh = async () => {
    if (!publicClient) return;
    
    setIsLoading(true);
    try {
      const number = await publicClient.getBlockNumber();
      setBlockNumber(number);
    } catch (error) {
      console.error('Failed to refresh block number:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <button
      onClick={handleRefresh}
      disabled={isLoading || !publicClient}
      className="h-full flex items-center gap-2 px-3 py-1 bg-slate-100 rounded-md border border-slate-200 hover:border-slate-300 transition-colors disabled:opacity-50 disabled:cursor-not-allowed hidden md:flex"
      title="Refresh block number"
    >
      <div className="flex items-center gap-1">
        <span className="text-sm text-slate-600 font-mono leading-none">Block</span>
        <span className="text-sm text-slate-600 font-mono leading-none">
          {blockNumber ? blockNumber.toString() : '...'}
        </span>
      </div>
      <div className="pb-0.5 text-slate-600 hover:text-slate-700 transition-colors">
        <ArrowPathIcon 
          className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} 
        />
      </div>
    </button>
  );
} 