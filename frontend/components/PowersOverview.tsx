'use client'

import React, { useState, useMemo, useEffect } from 'react'
import { usePathname } from 'next/navigation'
import { Powers, Law, Checks, LawSimulation, LawExecutions, Status, InputType } from '@/context/types'
import { PowersFlow } from './PowersFlow'
import { ConnectedWallet } from '@privy-io/react-auth'
import { ChevronRightIcon, ArrowPathIcon } from '@heroicons/react/24/outline'

interface PowersOverviewProps {
  powers: Powers
  wallets: ConnectedWallet[]
  selectedLawId?: string
  children?: React.ReactNode
  fetchLawsAndRoles?: (powers: Powers) => Promise<Powers | undefined>
}

export const PowersOverview: React.FC<PowersOverviewProps> = ({ 
  powers, 
  selectedLawId,
  children,
  fetchLawsAndRoles
}) => {
  const [isCollapsed, setIsCollapsed] = useState(false)
  const [isRefreshing, setIsRefreshing] = useState(false)
  const pathname = usePathname()

  // Auto-expand panel when navigating to a new page
  useEffect(() => {
    setIsCollapsed(false)
  }, [pathname])

  const handleRefresh = async () => {
    if (!fetchLawsAndRoles || isRefreshing) return
    
    setIsRefreshing(true)
    try {
      await fetchLawsAndRoles(powers)
      // The viewport will be updated automatically when the component re-renders with new data
    } catch (error) {
      console.error('Failed to refresh laws and roles:', error)
    } finally {
      setIsRefreshing(false)
    }
  }

  return (
    <div className="absolute top-0 left-0 w-screen h-screen">
      {/* Refresh Button - Top Right Corner - Above everything */}
      {fetchLawsAndRoles && (
        <button
          onClick={handleRefresh}
          disabled={isRefreshing}
          className="absolute top-16 right-2 z-50 bg-slate-100/25 backdrop-blur-sm text-slate-800 border border-slate-400 hover:border-slate-600 rounded-lg p-1.5 transition-colors duration-200 flex items-center gap-2"
          title="Refresh Laws and Roles"
        > 
          <div className="flex items-center gap-2 px-2">
            <p className="text-sm font-medium text-slate-600">Refresh</p>
            <ArrowPathIcon 
              className={`w-4 h-4 text-slate-600 ${isRefreshing ? 'animate-spin' : ''}`} 
            />
          </div>
        </button>
      )}

      {/* Main Flow Diagram - Full Screen Background */}
      <div className="absolute top-0 left-0 w-full h-full bg-slate-100 z-0" style={{ boxShadow: 'inset 8px 0 16px -8px rgba(0, 0, 0, 0.1)' }}>
        <PowersFlow 
          key={`powers-flow-${powers.contractAddress}`}
          powers={powers} 
          selectedLawId={selectedLawId} 
        />
      </div>

      {/* Side Panel - Overlay */}
      <div 
        className="absolute top-0 left-0 bg-slate-100 shadow-lg overflow-hidden transition-all duration-300 ease-in-out z-20"
        style={{
          width: isCollapsed ? '32px' : 'min(640px, 100vw)',
          height: '100vh',
        }}
      >
        {/* Panel Content */}
        <div className={`h-full flex flex-col transition-opacity duration-200 ${
          isCollapsed 
            ? 'opacity-0 pointer-events-none delay-200' 
            : 'opacity-100 delay-0'
        }`} style={{ 
          width: 'min(640px,100vw)',
        }}> 
          {/* Panel Content */}
          <div className="flex-1 overflow-y-auto">
            {children ? (
              // Render children directly since they now use Zustand store
              children
            ) : 
              <div className="h-full p-6">
                ERROR: No child component provided.
              </div>
            }
          </div>
        </div>

        {/* Full-Height Collapse/Expand Button - Integrated into Right Border */}
        <button
          onClick={() => setIsCollapsed(!isCollapsed)}
          className="absolute top-0 right-0 h-full w-8 bg-slate-100 border-r border-slate-300 transition-all duration-200 flex items-center justify-center group z-20"
          title={isCollapsed ? "Expand panel" : "Collapse panel"}
          style={{
            borderTopRightRadius: '0',
            borderBottomRightRadius: '0',
          }}
        >
          <div className="flex flex-col items-center justify-center h-full">
            {/* Arrow indicator */}
            <div className={`transform transition-transform duration-300 text-slate-600 ${
              isCollapsed ? 'rotate-0' : 'rotate-180'
            }`}>
              <ChevronRightIcon className="w-6 h-6" />
            </div>
          </div>
        </button>
      </div>
    </div>
  )
}

export default PowersOverview 