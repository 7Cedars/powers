'use client'

import React, { useState, useMemo } from 'react'
import { Powers, Law, Checks, LawSimulation, LawExecutions, Status, InputType } from '@/context/types'
import { PowersFlow } from './PowersFlow'
import { usePowersFlow } from '@/hooks/usePowersFlow'
import { ConnectedWallet } from '@privy-io/react-auth'
import { Button } from './Button'
import { LoadingBox } from './LoadingBox'
import { ChevronLeftIcon, ChevronRightIcon } from '@heroicons/react/24/outline'
import { LawBox } from '@/app/[chainId]/[powers]/flow/laws/[lawId]/LawBox'

interface PowersOverviewProps {
  powers: Powers
  wallets: ConnectedWallet[]
  selectedLawId?: string
  // Law-specific props for LawBox integration
  law?: Law
  checks?: Checks
  simulation?: LawSimulation
  executions?: LawExecutions
  statusLaw?: Status
  onSimulate?: (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void
  onExecute?: (law: Law, paramValues: (InputType | InputType[])[], nonce: bigint, description: string) => void
  children?: React.ReactNode
}

export const PowersOverview: React.FC<PowersOverviewProps> = ({ 
  powers, 
  wallets, 
  selectedLawId,
  law,
  checks: lawSpecificChecks,
  simulation,
  executions,
  statusLaw,
  onSimulate,
  onExecute,
  children
}) => {
  const { lawChecks, isLoading, error, refreshChecks } = usePowersFlow({ powers, wallets })
  const [isCollapsed, setIsCollapsed] = useState(false)

  // Find the selected law (fallback to prop)
  const selectedLaw = useMemo(() => {
    if (law) return law // Use prop if provided
    if (!selectedLawId || !powers.activeLaws) return null
    return powers.activeLaws.find(law => law.index.toString() === selectedLawId) || null
  }, [law, selectedLawId, powers.activeLaws])

  // Get checks for the selected law (fallback to prop)
  const selectedLawChecks = useMemo(() => {
    if (lawSpecificChecks) return lawSpecificChecks // Use prop if provided
    if (!selectedLawId || !lawChecks) return undefined
    return lawChecks.get(selectedLawId)
  }, [lawSpecificChecks, selectedLawId, lawChecks])

  return (
    <div className="absolute top-0 left-0 z-10 w-screen h-screen flex">
      {/* Side Panel */}
      <div className={`bg-white border-r border-gray-200 shadow-lg overflow-hidden transition-all duration-300 ${
        isCollapsed ? 'w-12' : 'w-1/3 min-w-[480px]'
      }`}>
        {isCollapsed ? (
          // Collapsed state - just toggle button
          <div className="p-3 h-full flex flex-col pt-20">
            <button
              onClick={() => setIsCollapsed(false)}
              className="p-2 hover:bg-gray-100 rounded-md transition-colors border border-gray-300 bg-white"
              title="Expand panel"
            >
              <span className="text-gray-600 font-mono text-sm">▶</span>
            </button>
          </div>
        ) : (
          // Expanded state - full content
          <div className="w-full h-full flex flex-col">
            {/* Header with collapse button */}
            <div className="p-6 pt-20 border-b border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-gray-900">
                  {selectedLaw ? `Law #${selectedLaw.index}` : 'Law Details'}
                </h2>
                <button
                  onClick={() => setIsCollapsed(true)}
                  className="p-2 hover:bg-gray-100 rounded-md transition-colors border border-gray-300 bg-white"
                  title="Collapse panel"
                >
                  <span className="text-gray-600 font-mono text-sm">◀</span>
                </button>
              </div>
            </div>
            
            {/* Panel Content */}
            <div className="flex-1 overflow-y-auto">
              {children ? (
                // Render children when provided (from layout)
                children
              ) : selectedLaw && selectedLawChecks && onSimulate && onExecute ? (
                // Show LawBox for selected law
                <div className="h-full p-6">
                  <LawBox 
                    law={selectedLaw}
                    checks={selectedLawChecks}
                    params={selectedLaw.params || []}
                    status={statusLaw || 'idle'}
                    simulation={simulation}
                    selectedExecution={undefined} // You can add this prop if needed
                    onChange={() => {
                      // Handle change if needed
                    }}
                    onSimulate={(paramValues, nonce, description) => 
                      onSimulate(selectedLaw, paramValues, nonce, description)
                    }
                    onExecute={(paramValues, nonce, description) => 
                      onExecute(selectedLaw, paramValues, nonce, description)
                    }
                  />
                </div>
              ) : selectedLaw ? (
                // Show basic law info when no handlers are provided
                <div className="p-6">
                  <div className="bg-gray-50 rounded-lg p-4 mb-4">
                    <h3 className="text-sm font-medium text-gray-700 mb-2">Selected Law</h3>
                    <p className="text-sm text-gray-600">
                      {selectedLaw.nameDescription || `Law #${selectedLaw.index}`}
                    </p>
                    <div className="mt-2 text-xs text-gray-500">
                      Law Address: {selectedLaw.lawAddress}
                    </div>
                  </div>
                  
                  {selectedLawChecks && (
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                      <h4 className="text-sm font-medium text-blue-800 mb-2">Law Checks</h4>
                      <div className="space-y-2 text-xs text-blue-700">
                        {Object.entries(selectedLawChecks).map(([key, value]) => (
                          <div key={key} className="flex justify-between">
                            <span className="capitalize">{key.replace(/([A-Z])/g, ' $1')}</span>
                            <span>{value !== undefined ? String(value) : 'N/A'}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              ) : (
                // Show default content when no law is selected
                <div className="p-6">
                  <div className="space-y-4">
                    <div className="bg-gray-50 rounded-lg p-4">
                      <h3 className="text-sm font-medium text-gray-700 mb-2">Overview</h3>
                      <p className="text-sm text-gray-600">
                        Select a law node to view detailed information about its checks, dependencies, and execution status.
                      </p>
                    </div>
                    
                    <div className="bg-gray-50 rounded-lg p-4">
                      <h3 className="text-sm font-medium text-gray-700 mb-2">Statistics</h3>
                      <div className="space-y-2">
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-600">Total Laws:</span>
                          <span className="font-medium">{powers.activeLaws?.length || 0}</span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-600">Active Proposals:</span>
                          <span className="font-medium">{powers.proposals?.length || 0}</span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="bg-gray-50 rounded-lg p-4">
                      <h3 className="text-sm font-medium text-gray-700 mb-2">Quick Actions</h3>
                      <div className="space-y-2">
                        <Button 
                          size={0}
                          align={0}
                          onClick={refreshChecks}
                        >
                          Refresh Checks
                        </Button>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
      
      {/* Main Flow Diagram */}
      <div className="flex-1 bg-gray-50" style={{ boxShadow: 'inset 8px 0 16px -8px rgba(0, 0, 0, 0.1)' }}>
        <PowersFlow 
          key={`powers-flow-${powers.contractAddress}`}
          powers={powers} 
          lawChecks={lawChecks} 
          selectedLawId={selectedLawId} 
        />
      </div>
    </div>
  )
}

export default PowersOverview 