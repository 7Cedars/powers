'use client'

import React, { useState } from 'react'
import { Powers } from '@/context/types'
import { PowersFlow } from './PowersFlow'
import { usePowersFlow } from '@/hooks/usePowersFlow'
import { ConnectedWallet } from '@privy-io/react-auth'
import { Button } from './Button'
import { LoadingBox } from './LoadingBox'
import { ChevronLeftIcon, ChevronRightIcon } from '@heroicons/react/24/outline'

interface PowersOverviewProps {
  powers: Powers
  wallets: ConnectedWallet[]
}

export const PowersOverview: React.FC<PowersOverviewProps> = ({ powers, wallets }) => {
  const { lawChecks, isLoading, error, refreshChecks } = usePowersFlow({ powers, wallets })
  const [isCollapsed, setIsCollapsed] = useState(false)

  return (
    <div className="absolute top-0 left-0 z-10 w-screen h-screen flex">
      {/* Side Panel */}
      <div className={`bg-white border-r border-gray-200 shadow-lg overflow-hidden transition-all duration-300 ${
        isCollapsed ? 'w-12' : 'w-96'
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
          <div className="w-96">
            <div className="p-6 pt-20">
              {/* Header with collapse button */}
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-gray-900">Law Details</h2>
                <button
                  onClick={() => setIsCollapsed(true)}
                  className="p-2 hover:bg-gray-100 rounded-md transition-colors border border-gray-300 bg-white"
                  title="Collapse panel"
                >
                  <span className="text-gray-600 font-mono text-sm">◀</span>
                </button>
              </div>
              
              {/* Panel Content */}
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
                
                {/* Placeholder for future content */}
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
          </div>
        )}
      </div>
      
      {/* Main Flow Diagram */}
      <div className="flex-1 bg-gray-50" style={{ boxShadow: 'inset 8px 0 16px -8px rgba(0, 0, 0, 0.1)' }}>
        <PowersFlow powers={powers} lawChecks={lawChecks} />
      </div>
    </div>
  )
}

export default PowersOverview 