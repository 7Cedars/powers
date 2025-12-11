import React from 'react'
import { Law, Powers } from '@/context/types'
import HeaderLaw from '@/components/HeaderLaw'
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo'

interface LawImpactListProps {
  laws: Law[]
  mode: 'enables' | 'blocks'
  powers: Powers
  blockExplorerUrl?: string
}

export const LawDependenciesList: React.FC<LawImpactListProps> = ({ 
  laws, 
  mode, 
  powers, 
  blockExplorerUrl 
}) => {
  if (laws.length === 0) return null

  return (
    <div className="mt-6">
      <h3 className="text-sm font-medium text-slate-700 mb-3 italic">
        Execution <b>{mode}</b> the following laws:
      </h3>
      <div className="space-y-2">
        {laws.map((law: Law) => (
          <div 
            key={`${mode}-${law.lawAddress}-${law.index}`}
            className="w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 opacity-50"
          >
            <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
              <HeaderLaw
                powers={powers}
                lawName={law?.nameDescription ? `#${Number(law.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law.index)}`}
                roleName={law?.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : ''}
                numHolders={law?.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers).toString() : ''}
                description={law?.nameDescription ? law.nameDescription.split(':')[1] || '' : ''}
                contractAddress={law.lawAddress}
                blockExplorerUrl={blockExplorerUrl}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
