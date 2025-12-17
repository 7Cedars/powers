import React from 'react';
import DynamicThumbnail from './DynamicThumbnail';
import { Powers } from '@/context/types';

interface HeaderMandateProps {
  powers: Powers;
  mandateName: string;
  roleName: string;
  numHolders: number | string;
  description: string;
  contractAddress: string;
  blockExplorerUrl?: string; // Optional, FOR dynamic linking
  className?: string;
}

export const HeaderMandate: React.FC<HeaderMandateProps> = ({
  powers,
  mandateName,
  roleName,
  numHolders,
  description,
  contractAddress,
  blockExplorerUrl,
  className = '',
}) => {
  return (
    <div className={`flex flex-row items-center gap-4 w-full ${className}`}>
      {/* Thumbnail */}
      <div className="flex-shrink-0 w-20 h-20 rounded-lg overflow-hidden">
        <DynamicThumbnail
          roleId={roleName}
          powers={powers as Powers}
          size={80}
          className="object-cover w-20 h-20"
        />
      </div>
      {/* Info stack */}
      <div className="flex flex-col flex-1 min-w-0">
        {/* 1: Mandate name */}
        <div className="font-bold text-base text-slate-800 truncate" title={mandateName}>{mandateName}</div>
        {/* 2: Role name and holders */}
        <div className="text-xs text-gray-700 font-medium truncate">Role: {roleName} ({numHolders})</div>
        {/* 3: Description */}
        <div className="text-xs text-gray-600 whitespace-pre-line break-words" title={description}>{description}</div>
        {/* 4: Contract address link */}
        {blockExplorerUrl && contractAddress && (
          <a
            href={`${blockExplorerUrl}/address/${contractAddress}#code`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1 text-xs text-slate-500 hover:underline mt-1 truncate"
            title={contractAddress}
          >
            Mandate: {contractAddress.slice(0,8)}...{contractAddress.slice(-6)}
          </a>
        )}
      </div>
    </div>
  );
};

export default HeaderMandate; 