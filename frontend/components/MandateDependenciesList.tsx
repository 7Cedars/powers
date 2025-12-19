import React from 'react'
import { Mandate, Powers } from '@/context/types'
import HeaderMandate from '@/components/HeaderMandate'
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo'

interface MandateImpactListProps {
  mandates: Mandate[]
  mode: 'enables' | 'blocks'
  powers: Powers
  blockExplorerUrl?: string
}

export const MandateDependenciesList: React.FC<MandateImpactListProps> = ({ 
  mandates, 
  mode, 
  powers, 
  blockExplorerUrl 
}) => {
  if (mandates.length === 0) return null

  return (
    <div className="mt-6">
      <h3 className="text-sm font-medium text-slate-700 mb-3 italic">
        Execution <b>{mode}</b> the following mandates:
      </h3>
      <div className="space-y-2">
        {mandates.map((mandate: Mandate) => (
          <div 
            key={`${mode}-${mandate.mandateAddress}-${mandate.index}`}
            className="w-full bg-slate-50 border-2 rounded-md overflow-hidden border-slate-600 opacity-50"
          >
            <div className="w-full border-b border-slate-300 bg-slate-100 py-4 ps-6 pe-2">
              <HeaderMandate
                powers={powers}
                mandateName={mandate?.nameDescription ? `#${Number(mandate.index)}: ${mandate.nameDescription.split(':')[0]}` : `#${Number(mandate.index)}`}
                roleName={mandate?.conditions && powers ? bigintToRole(mandate.conditions.allowedRole, powers) : ''}
                numHolders={mandate?.conditions && powers ? bigintToRoleHolders(mandate.conditions.allowedRole, powers).toString() : ''}
                description={mandate?.nameDescription ? mandate.nameDescription.split(':')[1] || '' : ''}
                contractAddress={mandate.mandateAddress}
                blockExplorerUrl={blockExplorerUrl}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
