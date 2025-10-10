import React from 'react';
import DynamicThumbnail from './DynamicThumbnail';
import { Powers } from '@/context/types';

interface HeaderLawSmallProps {
  powers: Powers;
  lawName: string;
  roleName: string;
  numHolders: number | string;
  contractAddress: string;
  blockExplorerUrl?: string; // Optional, for dynamic linking
  className?: string;
}

export const HeaderLawSmall: React.FC<HeaderLawSmallProps> = ({
  powers,
  lawName,
  roleName,
  numHolders,
  contractAddress,
  blockExplorerUrl,
  className = '',
}) => {
  return (
    <div className={`flex flex-row items-center gap-3 w-full ${className}`}>
      {/* Thumbnail */}
      <div className="flex-shrink-0 w-12 h-12 rounded-lg overflow-hidden">
        <DynamicThumbnail
          roleId={roleName}
          powers={powers as Powers}
          size={48}
          className="object-cover w-12 h-12"
        />
      </div>
      {/* Info stack */}
      <div className="flex flex-col flex-1 min-w-0 gap-0.5">
        {/* 1: Law name */}
        <div className="text-sm text-slate-800" title={lawName}>{lawName}</div>
        {/* 2: Role name and holders */}
        <div className="text-xs text-gray-600 truncate">Role: {roleName} ({numHolders})</div>
        {/* 3: Contract address link */}
        {blockExplorerUrl && contractAddress && (
          <a
            href={`${blockExplorerUrl}/address/${contractAddress}#code`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1 text-xs text-slate-500 hover:underline truncate"
            title={contractAddress}
            onClick={(e) => e.stopPropagation()}
          >
            {contractAddress.slice(0,8)}...{contractAddress.slice(-6)}
          </a>
        )}
      </div>
    </div>
  );
};

export default HeaderLawSmall;

