'use client'

import React, { act, useCallback, useEffect, useMemo } from 'react'
import ReactFlow, {
  Node,
  Edge,
  Background,
  MiniMap,
  useNodesState,
  useEdgesState,
  addEdge,
  Connection,
  ConnectionMode,
  Handle,
  Position,
  NodeProps,
  useReactFlow,
  ReactFlowProvider,
  MarkerType,
} from 'reactflow'
import 'reactflow/dist/style.css'
import { Law, Powers, Action, Status } from '@/context/types'
import { toFullDateFormat, toEurTimeFormat } from '@/utils/toDates'
import { useBlocks } from '@/hooks/useBlocks'
import { parseChainId } from '@/utils/parsers'
import { State, useBlockNumber, useChains } from 'wagmi'
import {
  CalendarDaysIcon,
  QueueListIcon,  
  DocumentCheckIcon,
  ShieldCheckIcon,
  ClipboardDocumentCheckIcon,
  CheckCircleIcon,
  RocketLaunchIcon,
  ArchiveBoxIcon,
  FlagIcon
} from '@heroicons/react/24/outline'
import { useParams, usePathname, useRouter } from 'next/navigation'
import { setAction, useActionStore, usePowersStore } from '@/context/store'
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo'
import HeaderLaw from '@/components/HeaderLaw'
import { hashAction } from '@/utils/hashAction'
import { useChecks } from '@/hooks/useChecks'
import { useWallets } from '@privy-io/react-auth'

// Default colors for all nodes
const DEFAULT_NODE_COLOR = '#475569' // slate-600
const DEFAULT_BORDER_CLASS = 'border-slate-600'
const EXECUTED_BORDER_CLASS = 'border-green-600'

function getNodeBorderClass(action: Action | undefined): string {
  // Check if the action has been successfully executed (fulfilledAt > 0)
  if (action && action.fulfilledAt && action.fulfilledAt > 0n) {
    return EXECUTED_BORDER_CLASS
  }
  return DEFAULT_BORDER_CLASS
}

// Helper function to get action data for all laws in the dependency chain
function getActionDataForChain(
  selectedAction: Action | undefined,
  laws: Law[],
  powers: Powers
): Map<string, Action> {
  const actionDataMap = new Map<string, Action>()
  
  // If no selected action or no calldata/nonce, return empty map
  if (!selectedAction || !selectedAction.callData || !selectedAction.nonce) {
    return actionDataMap
  }
  
  // For each law, calculate the actionId and look up the action data
  laws.forEach(law => {
    const lawId = law.index
    const calculatedActionId = hashAction(lawId, selectedAction.callData!, BigInt(selectedAction.nonce!))
    
    // Check if this action exists in the Powers object
    const lawData = powers.laws?.find(l => l.index === lawId)
    if (lawData && lawData.actions) {
      const action = lawData.actions.find(a => a.actionId === String(calculatedActionId))
      if (action) {
        actionDataMap.set(String(lawId), action)
      }
    }
  })
  
  return actionDataMap
}

interface LawSchemaNodeData {
  powers: Powers
  law: Law
  roleColor: string
  onNodeClick?: (lawId: string) => void
  selectedLawId?: string
  connectedNodes?: Set<string>
  actionDataTimestamp?: number
  selectedAction?: Action
  chainActionData: Map<string, Action>
}

const LawSchemaNode: React.FC<NodeProps<LawSchemaNodeData>> = ( {data} ) => {
  const { law, roleColor, onNodeClick, selectedLawId, connectedNodes, powers, chainActionData } = data
  const action  = useActionStore()
  const { timestamps, fetchTimestamps } = useBlocks()
  const chainId = useParams().chainId as string
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const { data: blockNumber } = useBlockNumber()
  const { checks, fetchChecks } = useChecks()
  const { wallets } = useWallets()

  // Get action data for this law from the chain action data
  const currentLawAction = chainActionData.get(String(law.index))

  // Fetch timestamps for the current law's action data
  React.useEffect(() => {
    // console.log("LAW schema node triggered", {law, chainActionData})
    const currentLawAction = chainActionData.get(String(law.index))
    // console.log( "@PowersFlow: ", {currentLawAction} )
    if (currentLawAction) {
      const blockNumbers: bigint[] = []
      
      // Collect all block numbers that need timestamps
      // proposedAt is used for proposal created, vote started, and calculating vote ended
      if (currentLawAction.proposedAt && currentLawAction.proposedAt !== 0n) {
        blockNumbers.push(currentLawAction.proposedAt)
      }
      if (currentLawAction.requestedAt && currentLawAction.requestedAt !== 0n) {
        blockNumbers.push(currentLawAction.requestedAt)
      }
      if (currentLawAction.fulfilledAt && currentLawAction.fulfilledAt !== 0n) {
        blockNumbers.push(currentLawAction.fulfilledAt)
      }
      
      // Also fetch timestamps for dependent laws
      if (law.conditions) {
        if (law.conditions.needFulfilled != null && BigInt(law.conditions.needFulfilled) != 0n) {
          const dependentAction = chainActionData.get(String(law.conditions.needFulfilled))
          if (dependentAction && dependentAction.fulfilledAt && dependentAction.fulfilledAt != 0n) {
            blockNumbers.push(dependentAction.fulfilledAt)
          }
        }
        if (law.conditions.needNotFulfilled != null && BigInt(law.conditions.needNotFulfilled) != 0n) {
          const dependentAction = chainActionData.get(String(law.conditions.needNotFulfilled))
          if (dependentAction && dependentAction.fulfilledAt && dependentAction.fulfilledAt != 0n) {
            blockNumbers.push(dependentAction.fulfilledAt)
          }
        }
      }
      
      // Fetch timestamps if we have block numbers
      if (blockNumbers.length > 0) {
        fetchTimestamps(blockNumbers, chainId)
      }
    }
  }, [chainActionData, law.index, law.conditions, chainId, fetchTimestamps])
  
  // Helper function to format block number or timestamp to desired format
  const formatBlockNumberOrTimestamp = (value: bigint | undefined): string | null => {
    if (!value || value === 0n) {
      return null
    }
    
    try {
      // First, check if we have this as a cached timestamp from useBlocks
      const cacheKey = `${chainId}:${value}`
      const cachedTimestamp = timestamps.get(cacheKey)
      
      if (cachedTimestamp && cachedTimestamp.timestamp) {
        // Convert bigint timestamp to number for the utility functions
        const timestampNumber = Number(cachedTimestamp.timestamp)
        const dateStr = toFullDateFormat(timestampNumber)
        const timeStr = toEurTimeFormat(timestampNumber)
        return `${dateStr}: ${timeStr}`
      }
      
      // If not in cache, it might be a direct timestamp (fallback)
      // Check if the value looks like a timestamp (large number) vs block number (smaller)
      const valueNumber = Number(value)
      
      // If it's a very large number, treat as timestamp
      if (valueNumber > 1000000000) { // Unix timestamp threshold
        const dateStr = toFullDateFormat(valueNumber)
        const timeStr = toEurTimeFormat(valueNumber)
        return `${dateStr}: ${timeStr}`
      }
      
      // If it's a smaller number, it's likely a block number that hasn't been fetched yet
      return null
    } catch (error) {
      return null
    }
  }

  // Helper function to get date for each check item
  const getCheckItemDate = (itemKey: string): string | null => {
    const currentLawAction = chainActionData.get(String(law.index))
    console.log("currentLawAction", currentLawAction)
    
    switch (itemKey) {
      case 'needFulfilled':
      case 'needNotFulfilled': {
        // Get executedAt from the dependent law - this should work regardless of current law's action data
        const dependentLawId = itemKey == 'needFulfilled' 
          ? law.conditions?.needFulfilled 
          : law.conditions?.needNotFulfilled
        
        if (dependentLawId && dependentLawId != 0n) {
          const dependentAction = chainActionData.get(String(dependentLawId))
          
          return formatBlockNumberOrTimestamp(dependentAction?.fulfilledAt)
        }
        return null
      }
      
      case 'proposalCreated': {
        // Show proposal creation time - use proposedAt from current law's action data
        if (currentLawAction && currentLawAction.proposedAt && currentLawAction.proposedAt != 0n) {
          return formatBlockNumberOrTimestamp(currentLawAction.proposedAt)
        }
        return null
      }
      
      case 'voteStarted': {
        // Vote started is the same as proposal created (proposedAt)
        if (currentLawAction && currentLawAction.proposedAt && currentLawAction.proposedAt != 0n) {
          return formatBlockNumberOrTimestamp(currentLawAction.proposedAt)
        }
        return null
      }
      
      case 'voteEnded': {
        // Calculate vote end time using proposedAt + votingPeriod
        if (currentLawAction && currentLawAction.proposedAt && currentLawAction.proposedAt != 0n && law.conditions?.votingPeriod) {
          // Get the timestamp for proposedAt block
          const cacheKey = `${chainId}:${currentLawAction.proposedAt}`
          const cachedTimestamp = timestamps.get(cacheKey)
          
          if (cachedTimestamp && cachedTimestamp.timestamp) {
            // Add voting period to get vote end time
            const proposedTimestamp = Number(cachedTimestamp.timestamp)
            const voteEndTimestamp = proposedTimestamp + Number(law.conditions.votingPeriod)
            
            const dateStr = toFullDateFormat(voteEndTimestamp)
            const timeStr = toEurTimeFormat(voteEndTimestamp)
            return `${dateStr}: ${timeStr}`
          }
        }
        return null
      }

      case 'delay': {
        // Calculate delay pass time if requestedAt exists and delay > 0
        // Only show if current law has action data with requestedAt
        if (currentLawAction && currentLawAction.proposedAt && currentLawAction.proposedAt != 0n && law.conditions?.votingPeriod && law.conditions.delayExecution != 0n) {
          // Get the timestamp for proposedAt block
          const cacheKey = `${chainId}:${currentLawAction.proposedAt}`
          const cachedTimestamp = timestamps.get(cacheKey)
          
          if (cachedTimestamp && cachedTimestamp.timestamp) {
            // Add voting period to get vote end time
            const proposedTimestamp = Number(cachedTimestamp.timestamp)
            const voteEndTimestamp = proposedTimestamp + Number(law.conditions.votingPeriod) + Number(law.conditions.delayExecution)
            
            const dateStr = toFullDateFormat(voteEndTimestamp)
            const timeStr = toEurTimeFormat(voteEndTimestamp)
            return `${dateStr}: ${timeStr}`
          }
        }
        // Return null if no action data or no delay condition
        return null
      }
      
      case 'requested': {
        // Use requestedAt field - show when proposal was requested (after vote passed)
        if (currentLawAction && currentLawAction.requestedAt && currentLawAction.requestedAt != 0n) {
          return formatBlockNumberOrTimestamp(currentLawAction.requestedAt)
        }
        return null
      }
      
      case 'throttle':
        // Keep as null for now
        return null
      
      case 'fulfilled':        
        // Only show date if actually fulfilled (fulfilledAt > 0)
        if (currentLawAction && currentLawAction.fulfilledAt && currentLawAction.fulfilledAt != 0n) {
          return formatBlockNumberOrTimestamp(currentLawAction.fulfilledAt)
        }
        return null
      
      default:
        return null
    }
  }

  const handleClick = () => {
    if (onNodeClick) {
      onNodeClick(String(law.index))
    }
  }

  const isSelected = selectedLawId === String(law.index)
  const borderThickness = isSelected ? 'border-4' : 'border'
  
  // Apply opacity based on connection to selected node
  const isConnected = !selectedLawId || !connectedNodes || connectedNodes.has(String(law.index))
  const opacityClass = isConnected ? 'opacity-100' : 'opacity-50'

  const checkItems = useMemo(() => {
    const items: { 
      key: string
      label: string
      blockNumber?: bigint
      state?: Status
      hasHandle: boolean
      targetLaw?: bigint
      edgeType?: string
    }[] = []

    // console.log("checkItems triggered", {law, chainActionData})
    
    // 1. Dependency checks - show only if dependent laws exist (condition != 0)
    if (law.conditions) {
      if (law.conditions.needFulfilled > 0n) {
        const dependentAction = chainActionData.get(String(law.conditions.needFulfilled))
        items.push({ 
          key: 'needFulfilled', 
          label: `Law ${law.conditions.needFulfilled} Fulfilled`, 
          blockNumber: dependentAction?.fulfilledAt,
          state: dependentAction?.fulfilledAt && dependentAction.fulfilledAt > 0n ? "success" : "pending",
          hasHandle: true,
          targetLaw: law.conditions.needFulfilled,
          edgeType: 'needFulfilled'
        })
      }
      
      if (law.conditions.needNotFulfilled > 0n) {
        const dependentAction = chainActionData.get(String(law.conditions.needNotFulfilled))
        // For needNotFulfilled, show green when the dependent law is NOT fulfilled (blockNumber is 0 or undefined) 
        items.push({ 
          key: 'needNotFulfilled', 
          label: `Law ${law.conditions.needNotFulfilled} Not Fulfilled`, 
          blockNumber: dependentAction?.fulfilledAt,
          state: dependentAction?.fulfilledAt && dependentAction.fulfilledAt > 0n ? "error" : "success",
          hasHandle: true,
          targetLaw: law.conditions.needNotFulfilled,
          edgeType: 'needNotFulfilled'
        })
      }
    }
    
    // 2. Throttle check - show only if throttle condition exists (throttleExecution > 0)
    if (law.conditions && law.conditions.throttleExecution != null && law.conditions.throttleExecution > 0n) {
      // Show as completed if we have action data (simplified - could be enhanced with actual throttle check)
      const latestFulfilledAction =  Math.max(...law.actions?.map(action => Number(action.fulfilledAt)) || [0])
      const throttledPassed = latestFulfilledAction + Number(law.conditions.throttleExecution) < (blockNumber || 0)

      items.push({ 
        key: 'throttle', 
        label: 'Throttle Passed', 
        blockNumber: BigInt(latestFulfilledAction + Number(law.conditions.throttleExecution)),
        state: throttledPassed ? "success" : "pending",
        hasHandle: false
      })
    }
    
    // 3. Vote flow - show only when quorum > 0
    if (law.conditions && law.conditions.quorum != null && law.conditions.quorum > 0n) {
      items.push({ 
        key: 'proposalCreated', 
        label: 'Proposal Created', 
        blockNumber: currentLawAction?.proposedAt,
        state: currentLawAction?.proposedAt && currentLawAction.proposedAt > 0n ? "success" : "pending",
        hasHandle: false
      })
      
      items.push({ 
        key: 'voteStarted', 
        label: 'Vote Started', 
        // Vote started is the same as proposal created
        blockNumber: currentLawAction?.proposedAt,
        state: currentLawAction?.proposedAt && currentLawAction.proposedAt > 0n ? "success" : "pending",
        hasHandle: false
      })
      
      items.push({ 
        key: 'voteEnded', 
        label: 'Vote Ended', 
        // Show as completed if we have proposedAt (vote will end at proposedAt + votingPeriod)
        blockNumber: currentLawAction?.proposedAt,
        state: 
          currentLawAction?.state && currentLawAction?.state == 4 ? "error" :
          currentLawAction?.state && currentLawAction?.state >= 5 ? "success" :
          "pending",
        hasHandle: false
      })

          
      // 4. Delay - show only if delayExecution > 0
      if (law.conditions && law.conditions.delayExecution != null && currentLawAction?.proposedAt && law.conditions.delayExecution > 0n) {
        items.push({ 
          key: 'delay', 
          label: 'Delay Passed', 
          // For delay, we use proposedAt as the reference block (the delay is calculated from it: proposedAt + votingPeriod + delay)
          blockNumber: currentLawAction?.proposedAt,
          state: currentLawAction?.proposedAt + law.conditions.votingPeriod + law.conditions.delayExecution < BigInt(blockNumber || 0) ? "success" : "pending",
          hasHandle: false
        })
      }
      
      items.push({ 
        key: 'requested', 
        label: 'Requested', 
        // Show green if action has been requested (requestedAt > 0)
        blockNumber: currentLawAction?.requestedAt || 0n,
        state: currentLawAction?.requestedAt && currentLawAction.requestedAt > 0n ? "success" : "pending",
        hasHandle: false
      })
    }

    // 5. Fulfilled - always show
    items.push({ 
      key: 'fulfilled', 
      label: 'Fulfilled', 
      blockNumber: currentLawAction?.fulfilledAt,
      state: currentLawAction?.fulfilledAt && currentLawAction.fulfilledAt > 0n ? "success" : "pending",
      hasHandle: false
    })
    
    return items
  }, [currentLawAction, law.conditions, chainActionData])

  const roleBorderClass = getNodeBorderClass(currentLawAction)

  // Helper values for HeaderLaw
  const lawName = law.nameDescription ? `#${Number(law.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law.index)}`;
  const roleName = law.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : '';
  const numHolders = law.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers) : '';
  const description = law.nameDescription ? law.nameDescription.split(':')[1] || '' : '';
  const contractAddress = law.lawAddress;
  const blockExplorerUrl = supportedChain?.blockExplorers?.default.url;

  return (
    <div 
      className={`shadow-lg rounded-lg bg-white ${borderThickness} min-w-[300px] max-w-[380px] w-[380px] overflow-hidden ${roleBorderClass} cursor-pointer hover:shadow-xl transition-shadow ${opacityClass} relative`}
      help-nav-item="flow-node"
      onClick={handleClick}
    >        
        {/* Law Header - replaced with HeaderLaw */}
        <div className="px-4 py-3 border-b border-gray-300 bg-slate-100" style={{ borderBottomColor: roleColor }}>
          <HeaderLaw
            powers={powers as Powers}
            lawName={lawName}
            roleName={roleName}
            numHolders={numHolders}
            description={description}
            contractAddress={contractAddress}
            blockExplorerUrl={blockExplorerUrl}
          />
        </div>
        
        {/* Action Steps Section */}
        {checkItems.length > 0 && (
          <div className="relative bg-slate-50">
            {checkItems.map((item, index) => {
              // Determine if this step is completed based on blockNumber
              const iconColor = item.state === "success" ? 'text-green-600' : item.state === "error" ? 'text-red-600' : 'text-black'

              return (
              <div key={item.key} className="relative">
                <div className="px-4 py-2 flex items-center justify-between text-xs relative">
                <div className="flex items-center space-x-2 flex-1">
                    <div className="w-6 h-6 flex justify-center items-center relative">
                      {item.key === 'fulfilled' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <RocketLaunchIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      ) : item.key === 'requested' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <CheckCircleIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      ) : item.key === 'delay' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <CalendarDaysIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      ) : item.key === 'throttle' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <QueueListIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      ) : item.key === 'needFulfilled' || item.key === 'needNotFulfilled' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <DocumentCheckIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      ) : item.key === 'voteStarted' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <ArchiveBoxIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      ) : item.key === 'voteEnded' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <FlagIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      ) : item.key === 'proposalCreated' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <ClipboardDocumentCheckIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      ) : (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <ShieldCheckIcon className={`w-4 h-4 ${iconColor}`} />
                        </div>
                      )}
                    </div>
                    <div className="flex-1 flex flex-col min-w-0">
                      {getCheckItemDate(item.key) && (
                        <div className="text-[10px] text-gray-400 mb-0.5">{getCheckItemDate(item.key)}</div>
                      )}
                      <span className="text-gray-700 font-medium break-words">{item.label}</span>
                    </div>
                </div>
                
                {/* Connection handle for dependency checks */}
                {item.hasHandle && (
                  <Handle
                    type="source"
                    position={Position.Left}
                    id={`${item.key}-handle`}
                    style={{ 
                      background: roleColor, // Use role color instead of gray
                      width: 8,
                      height: 8,
                      left: -4,
                      top: '50%',
                      transform: 'translateY(-50%)'
                      }}
                    />
                  )}
                  
                  {/* Target handle for fulfilled check */}
                  {item.key === 'fulfilled' && (
                    <Handle
                      type="target"
                      position={Position.Right}
                      id="fulfilled-target"
                      style={{ 
                        background: roleColor, // Use role color instead of gray
                        width: 10,
                        height: 10,
                        right: -5,
                        top: '50%',
                        transform: 'translateY(-50%)'
                      }}
                    />
                  )}
                </div>
                
                {/* Vertical connecting line to next item */}
                {index < checkItems.length - 1 && (
                  <div 
                    className="absolute w-px bg-black"
                    style={{ 
                      left: '28px', // 16px padding + 12px (half of 24px circle width)
                      top: 'calc(50% + 12px)', // Start from bottom of current circle
                      height: 'calc(100% - 12px)', // Extend to top of next circle
                    }}
                  />
                )}
              </div>
            )})}
          </div>
        )}
      </div>
  )
}

const nodeTypes = {
  lawSchema: LawSchemaNode,
}

// Helper function to find all nodes connected to a selected node through dependencies
function findConnectedNodes(powers: Powers, selectedLawId: string): Set<string> {
  const connected = new Set<string>()
  const visited = new Set<string>()

  const laws = powers?.laws || []

  // Build dependency maps
  const dependencies = new Map<string, Set<string>>()
  const dependents = new Map<string, Set<string>>()
  
  laws.forEach(law => {
    const lawId = String(law.index)
    dependencies.set(lawId, new Set())
    dependents.set(lawId, new Set())
  })
  
  // Populate dependency relationships
  laws.forEach(law => {
    const lawId = String(law.index)
    if (law.conditions) {
      if (law.conditions.needFulfilled != null && law.conditions.needFulfilled !== 0n) {
        const targetId = String(law.conditions.needFulfilled)
        if (dependencies.has(targetId)) {
        dependencies.get(lawId)?.add(targetId)
        dependents.get(targetId)?.add(lawId)
        }
      }
      if (law.conditions.needNotFulfilled != null && law.conditions.needNotFulfilled !== 0n) {
        const targetId = String(law.conditions.needNotFulfilled)
        if (dependencies.has(targetId)) {
        dependencies.get(lawId)?.add(targetId)
        dependents.get(targetId)?.add(lawId)
        }
      }
    }
  })
  
  // Recursive function to find all connected nodes
  const traverse = (nodeId: string) => {
    if (visited.has(nodeId)) return
    visited.add(nodeId)
    connected.add(nodeId)
    
    // Add all dependencies
    const deps = dependencies.get(nodeId) || new Set()
    deps.forEach(depId => traverse(depId))
    
    // Add all dependents  
    const dependentNodes = dependents.get(nodeId) || new Set()
    dependentNodes.forEach(depId => traverse(depId))
  }
  
  traverse(selectedLawId)
  return connected
}

// Helper function to create a compact layered tree layout based on dependencies
function createHierarchicalLayout(laws: Law[], savedLayout?: Record<string, { x: number; y: number }>): Map<string, { x: number; y: number }> {
  const positions = new Map<string, { x: number; y: number }>()

  // If we have saved layout, use it first
  if (savedLayout) {
    laws.forEach(law => {
      const lawId = String(law.index)
      if (savedLayout[lawId]) {
        positions.set(lawId, savedLayout[lawId])
      }
    })
    if (positions.size === laws.length) {
      return positions
    }
  }

  // Build dependency and dependent maps
  const dependencies = new Map<string, Set<string>>()
  const dependents = new Map<string, Set<string>>()
  laws.forEach(law => {
    const lawId = String(law.index)
    dependencies.set(lawId, new Set())
    dependents.set(lawId, new Set())
  })
  laws.forEach(law => {
    const lawId = String(law.index)
    if (law.conditions) {
      if (law.conditions.needFulfilled != null && law.conditions.needFulfilled !== 0n) {
        const targetId = String(law.conditions.needFulfilled)
        if (dependencies.has(targetId)) {
          dependencies.get(lawId)?.add(targetId)
          dependents.get(targetId)?.add(lawId)
        }
      }
      if (law.conditions.needNotFulfilled != null && law.conditions.needNotFulfilled !== 0n) {
        const targetId = String(law.conditions.needNotFulfilled)
        if (dependencies.has(targetId)) {
          dependencies.get(lawId)?.add(targetId)
          dependents.get(targetId)?.add(lawId)
        }
      }
    }
  })

  // Find root nodes (no dependencies)
  const allLawIds = laws.map(law => String(law.index))
  const rootNodes = allLawIds.filter(lawId => (dependencies.get(lawId)?.size || 0) === 0)

  // Layout constants (flipped axes)
  const NODE_SPACING_X = 500 // Now used for depth (main flow, horizontal)
  const NODE_SPACING_Y = 450 // Now used for siblings (vertical stack)

  // Track placed nodes to avoid cycles
  const placed = new Set<string>()

  // Compute the size (number of rows) of each subtree
  const subtreeSize = new Map<string, number>()
  function computeSubtreeSize(lawId: string, visiting: Set<string> = new Set()): number {
    if (visiting.has(lawId)) return 0; // Prevent cycles
    visiting.add(lawId);
    const children = Array.from(dependents.get(lawId) || [])
    if (children.length === 0) {
      subtreeSize.set(lawId, 1)
      visiting.delete(lawId);
      return 1
    }
    // Compute size for all children
    const sizes = children.map(childId => computeSubtreeSize(childId, visiting))
    const total = sizes.reduce((a, b) => a + b, 0)
    subtreeSize.set(lawId, total)
    visiting.delete(lawId);
    return total
  }
  rootNodes.forEach(rootId => computeSubtreeSize(rootId))

  // Track the next available y row
  let nextY = 0

  // Recursive function to place nodes (cycle-safe)
  function placeNode(lawId: string, x: number, y: number, visiting: Set<string> = new Set()) {
    if (placed.has(lawId)) return;
    if (visiting.has(lawId)) return; // Prevent cycles
    placed.add(lawId);
    positions.set(lawId, { x: x * NODE_SPACING_X, y: y * NODE_SPACING_Y });

    visiting.add(lawId);
    const children = Array.from(dependents.get(lawId) || []);
    if (children.length === 0) {
      visiting.delete(lawId);
      return;
    }
    // Sort children by subtree size descending, so the largest is the 'main' child
    children.sort((a, b) => (subtreeSize.get(b) || 1) - (subtreeSize.get(a) || 1));
    let childY = y;
    for (let i = 0; i < children.length; i++) {
      const childId = children[i];
      placeNode(childId, x + 1, childY, visiting);
      childY += subtreeSize.get(childId) || 1;
    }
    visiting.delete(lawId);
  }

  // Place all root nodes, stacking them vertically
  rootNodes.forEach(rootId => {
    placeNode(rootId, 0, nextY)
    nextY += subtreeSize.get(rootId) || 1
  })

  // Place any unplaced nodes (disconnected or cycles)
  // Collect all singletons (no dependencies and no dependents)
  const singletons: string[] = []
  allLawIds.forEach(lawId => {
    if (!placed.has(lawId)) {
      if ((dependencies.get(lawId)?.size || 0) === 0 && (dependents.get(lawId)?.size || 0) === 0) {
        singletons.push(lawId)
      } else {
        positions.set(lawId, { x: 0, y: nextY * NODE_SPACING_Y })
        nextY += 1
        placed.add(lawId)
      }
    }
  })

  // --- COMPACTION PASS ---
  // Find all used y rows, sort, and remap to compact (no gaps)
  const usedYRows = Array.from(new Set(Array.from(positions.values()).map(pos => pos.y / NODE_SPACING_Y))).sort((a, b) => a - b)
  const yRowMap = new Map<number, number>()
  usedYRows.forEach((row, idx) => yRowMap.set(row, idx))
  // Shift all nodes up to fill gaps
    positions.forEach((pos, lawId) => {
      const oldRow = pos.y / NODE_SPACING_Y
      const newRow = yRowMap.get(oldRow)
      if (newRow !== undefined) {
        positions.set(lawId, { x: pos.x, y: newRow * NODE_SPACING_Y })
      }
    })

  // Place all singletons in a horizontal row at the bottom
  // Find all y rows (in row units, not pixels) used by non-singleton nodes
  const singletonSet = new Set(singletons);
  let maxRow = 0;
  positions.forEach((pos, lawId) => {
    if (!singletonSet.has(lawId)) {
      const row = Math.round(pos.y / NODE_SPACING_Y);
      if (row > maxRow) maxRow = row;
    }
  });
  const singletonRow = maxRow + 1;
  singletons.forEach((lawId, idx) => {
    positions.set(lawId, { x: idx * NODE_SPACING_X, y: singletonRow * NODE_SPACING_Y });
    placed.add(lawId);
  });

  return positions
}

// Store for viewport state persistence using localStorage
const VIEWPORT_STORAGE_KEY = 'powersflow-viewport'

const getStoredViewport = () => {
  if (typeof window === 'undefined') return null
  try {
    const stored = localStorage.getItem(VIEWPORT_STORAGE_KEY)
    return stored ? JSON.parse(stored) : null
  } catch {
    return null
  }
}

const setStoredViewport = (viewport: { x: number; y: number; zoom: number }) => {
  if (typeof window === 'undefined') return
  try {
    localStorage.setItem(VIEWPORT_STORAGE_KEY, JSON.stringify(viewport))
  } catch {
    // Ignore localStorage errors
  }
}

const FlowContent: React.FC = () => {
  const { getNodes, getViewport, setViewport } = useReactFlow()
  const { lawId: selectedLawId } = useParams<{lawId: string }>()  
  const router = useRouter()
  const action = useActionStore()
  const [userHasInteracted, setUserHasInteracted] = React.useState(false)
  const reactFlowInstanceRef = React.useRef<ReturnType<typeof useReactFlow> | null>(null)
  const pathname = usePathname()
  const powers = usePowersStore()
  
  // Debounced layout saving
  const saveTimeoutRef = React.useRef<NodeJS.Timeout | null>(null)

  // Function to load saved layout from localStorage
  const loadSavedLayout = React.useCallback((): Record<string, { x: number; y: number }> | undefined => {
    try {
      const localStore = localStorage.getItem("powersProtocols")
      if (!localStore || localStore === "undefined") return undefined
      
      const saved: Powers[] = JSON.parse(localStore)
      const existing = saved.find(item => item.contractAddress === powers?.contractAddress as `0x${string}`)
      
      if (existing && existing.layout) {
        return existing.layout
      }
      
      return undefined
    } catch (error) {
      console.error('Failed to load layout from localStorage:', error)
      return undefined
    }
  }, [powers?.contractAddress])

  // Function to save powers object to localStorage (similar to usePowers.ts)
  const savePowersToLocalStorage = React.useCallback((updatedPowers: Powers) => {
    try {
      const localStore = localStorage.getItem("powersProtocols")
      const saved: Powers[] = localStore && localStore != "undefined" ? JSON.parse(localStore) : []
      const existing = saved.find(item => item.contractAddress === updatedPowers.contractAddress)
      if (existing) {
        saved.splice(saved.indexOf(existing), 1)
      }
      saved.push(updatedPowers)
      localStorage.setItem("powersProtocols", JSON.stringify(saved, (key, value) =>
        typeof value === "bigint" ? value.toString() : value,
      ))
    } catch (error) {
      console.error('Failed to save layout to localStorage:', error)
    }
  }, [])

  // Function to extract current layout from ReactFlow nodes
  const extractCurrentLayout = React.useCallback(() => {
    const nodes = getNodes()
    const layout: Record<string, { x: number; y: number }> = {}
    
    nodes.forEach(node => {
      layout[node.id] = {
        x: node.position.x,
        y: node.position.y
      }
    })
    
    return layout
  }, [getNodes])

  // Function to save layout to powers object and localStorage
  const saveLayout = React.useCallback(() => {
    const currentLayout = extractCurrentLayout()
    
    // Create updated powers object with layout data
    const updatedPowers: Powers = {
      ...powers as Powers,
      layout: currentLayout
    }
    
    // Save to localStorage
    savePowersToLocalStorage(updatedPowers)
  }, [powers, extractCurrentLayout, savePowersToLocalStorage])

  // Debounced save function
  const debouncedSaveLayout = React.useCallback(() => {
    // Clear existing timeout
    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current)
    }
    
    // Set new timeout for 0.5 seconds
    saveTimeoutRef.current = setTimeout(() => {
      saveLayout()
    }, 500)
  }, [saveLayout])

  // Cleanup timeout on unmount
  React.useEffect(() => {
    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current)
      }
    }
  }, [])


  // Helper function to calculate fitView options accounting for panel width
  const calculateFitViewOptions = useCallback(() => {
    return {
      padding: 0.2,
      duration: 800,
      includeHiddenNodes: false,
      minZoom: 0.1,
      maxZoom: 1.2,
    }
  }, [])

  // Custom fitView function that accounts for the side panel
  const fitViewWithPanel = useCallback(() => {
    const nodes = getNodes()
    if (nodes.length === 0) return

    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight
    const expandedPanelWidth = Math.min(640, viewportWidth - 40)
    const isSmallScreen = viewportWidth <= 2 * expandedPanelWidth
    // Calculate the available area for the flow chart (excluding panel)
    const availableWidth = isSmallScreen ? viewportWidth : viewportWidth - expandedPanelWidth
    const availableHeight = viewportHeight

    // Find the bounds of all nodes
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
    nodes.forEach(node => {
      const nodeWidth = 380 // Node width from the component
      const nodeHeight = 300 // Approximate node height
      minX = Math.min(minX, node.position.x)
      minY = Math.min(minY, node.position.y)
      maxX = Math.max(maxX, node.position.x + nodeWidth)
      maxY = Math.max(maxY, node.position.y + nodeHeight)
    })
    // Add padding
    const padding = 100
    const contentWidth = maxX - minX + 2 * padding
    const contentHeight = maxY - minY + 2 * padding
    // Calculate zoom to fit content in available area
    const zoomX = availableWidth / contentWidth
    const zoomY = availableHeight / contentHeight
    const zoom = Math.min(zoomX, zoomY, 1.2) // Cap at max zoom
    // Calculate center position
    const contentCenterX = (minX + maxX) / 2
    const contentCenterY = (minY + maxY) / 2
    let x, y
    if (isSmallScreen) {
      // Center in the middle of the viewport
      x = -contentCenterX * zoom + viewportWidth / 2
      y = -contentCenterY * zoom + availableHeight / 2
    } else {
      // Offset for the panel as before
      const availableAreaCenterX = expandedPanelWidth + availableWidth / 2
      x = -contentCenterX * zoom + availableAreaCenterX
      y = -contentCenterY * zoom + availableHeight / 2
    }
    setViewport({ x, y, zoom }, { duration: 800 })
  }, [getNodes, setViewport])

  const handleNodeClick = useCallback((lawId: string) => {
    // Store current viewport before navigation
    const currentViewport = getViewport()
    setStoredViewport(currentViewport)
    // console.log("@handleNodeClick: waypoint 0", {lawId, action})
    // Navigate to the law page within the flow layout
    setAction({
      ...action,
      lawId: BigInt(lawId),
      upToDate: false
    })
    router.push(`/protocol/${powers?.chainId}/${powers?.contractAddress}/laws/${lawId}`)
    // console.log("@handleNodeClick: waypoint 1", {action})
  }, [router, powers?.contractAddress, action, getViewport])

  // Handle ReactFlow initialization
  const onInit = useCallback((reactFlowInstance: ReturnType<typeof useReactFlow>) => {
    reactFlowInstanceRef.current = reactFlowInstance
    
    const storedViewport = getStoredViewport()
    
    // Only fit view on initial page load (no selected law and no stored viewport)
    if (!action.lawId && !selectedLawId && !storedViewport) {
      setTimeout(() => {
        fitViewWithPanel()
        // Save the fitted viewport
        setTimeout(() => {
          const currentViewport = getViewport()
          setStoredViewport(currentViewport)
        }, 900)
      }, 100)
    } else if (storedViewport) {
      // Restore stored viewport
      setTimeout(() => {
        setViewport(storedViewport, { duration: 0 })
      }, 100)
    }
  }, [setViewport, getViewport, action.lawId, selectedLawId, fitViewWithPanel])


  // Reset user interaction flag when navigating to home page
  React.useEffect(() => {
    const isHomePage = !pathname.includes('/laws/')
    if (isHomePage) {
      setUserHasInteracted(false)
    }
  }, [pathname])



  // Create nodes and edges from laws
  const { initialNodes, initialEdges } = useMemo(() => {
    if (!powers?.laws) return { initialNodes: [], initialEdges: [] }
    const ActiveLaws = powers?.laws.filter(law => law.active)
    if (!ActiveLaws) return { initialNodes: [], initialEdges: [] }
    
    const nodes: Node[] = []
    const edges: Edge[] = []
    
    // Use hierarchical layout instead of simple grid
    const savedLayout = loadSavedLayout()
    const positions = createHierarchicalLayout(ActiveLaws || [], savedLayout)
    
    // Find connected nodes if a law is selected
    const selectedLawIdFromStore = action.lawId !== 0n ? String(action.lawId) : undefined
    const connectedNodes = selectedLawIdFromStore 
      ? findConnectedNodes(powers as Powers, selectedLawIdFromStore as string)
      : undefined
    
    // Get the selected action from the store
    const selectedAction = action.actionId !== "0" ? action : undefined
    
    // Get action data for all laws in the chain
    const chainActionData = getActionDataForChain(
      selectedAction,
      ActiveLaws || [],
      powers
    )
    
    ActiveLaws?.forEach((law) => {
      const roleColor = DEFAULT_NODE_COLOR
      const lawId = String(law.index)
      const position = positions.get(lawId) || { x: 0, y: 0 }
      
      // Create law schema node
      nodes.push({
        id: lawId,
        type: 'lawSchema',  
        position,
        data: {
          powers,
          law,
          roleColor,
          onNodeClick: handleNodeClick,
          selectedLawId: selectedLawIdFromStore,
          connectedNodes,
          actionDataTimestamp: Date.now(),
          selectedAction,
          chainActionData,
        },
      })
      
      // Create edges from dependency checks to target laws
      if (law.conditions) {
        const sourceId = lawId
        
        // Check if the source law's action is fulfilled
        const sourceAction = chainActionData.get(sourceId)
        const isSourceFulfilled = sourceAction && sourceAction.fulfilledAt && sourceAction.fulfilledAt > 0n
        const edgeColor = '#6B7280' // green-600 if fulfilled, gray otherwise // turned off for now: isSourceFulfilled ? '#16a34a' :
        
        // Edge from needFulfilled check to target law
        if (law.conditions.needFulfilled != null && law.conditions.needFulfilled !== 0n) {
          const targetId = String(law.conditions.needFulfilled)
          // Determine if this edge should be highlighted (connected to selected node)
          const isEdgeConnected = !connectedNodes || connectedNodes.has(sourceId) || connectedNodes.has(targetId)
          const edgeOpacity = isEdgeConnected ? 1 : 0.5
          
          edges.push({
            id: `${sourceId}-needFulfilled-${targetId}`,
            source: sourceId,
            sourceHandle: 'needFulfilled-handle',
            target: targetId,
            targetHandle: 'fulfilled-target',
            type: 'smoothstep',
            label: 'Needs Fulfilled',
            style: { stroke: edgeColor, strokeWidth: 2, opacity: edgeOpacity },
            labelStyle: { fontSize: '10px', fontWeight: 'bold', fill: edgeColor, opacity: edgeOpacity },
            labelBgStyle: { fill: '#f1f5f9', fillOpacity: 0.8 * edgeOpacity },
            markerStart: {
              type: MarkerType.ArrowClosed,
              color: edgeColor,
              width: 20,
              height: 20,
            },
            zIndex: 10,
          })
        }
        
        // Edge from needNotFulfilled check to target law
        if (law.conditions.needNotFulfilled != null && law.conditions.needNotFulfilled != 0n) {
          const targetId = String(law.conditions.needNotFulfilled)
          // Determine if this edge should be highlighted (connected to selected node)
          const isEdgeConnected = !connectedNodes || connectedNodes.has(sourceId) || connectedNodes.has(targetId)
          const edgeOpacity = isEdgeConnected ? 1 : 0.5
          
          edges.push({
            id: `${sourceId}-needNotFulfilled-${targetId}`,
            source: sourceId,
            sourceHandle: 'needNotFulfilled-handle',
            target: targetId,
            targetHandle: 'fulfilled-target',
            type: 'smoothstep',
            label: 'Needs Not Fulfilled',
            style: { stroke: edgeColor, strokeWidth: 2, strokeDasharray: '6,3', opacity: edgeOpacity },
            labelStyle: { fontSize: '10px', fontWeight: 'bold', fill: edgeColor, opacity: edgeOpacity },
            labelBgStyle: { fill: '#f1f5f9', fillOpacity: 0.8 * edgeOpacity },
            markerStart: {
              type: MarkerType.ArrowClosed,
              color: edgeColor,
              width: 20,
              height: 20,
            },
            zIndex: 10,
          })
        }
        
      
      }
    })
    
    return { initialNodes: nodes, initialEdges: edges }
  }, [
    powers,
    handleNodeClick, 
    selectedLawId, 
    action.lawId, 
    loadSavedLayout
  ])

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges)

  const onConnect = useCallback(
    (params: Connection) => setEdges((eds) => addEdge(params, eds)),
    [setEdges],
  )

  // Save viewport state when user manually pans/zooms
  const onMoveEnd = useCallback(() => {
    const currentViewport = getViewport()
    setStoredViewport(currentViewport)
    // Mark that user has interacted with viewport
    setUserHasInteracted(true)
    // Trigger debounced layout save when viewport changes
    debouncedSaveLayout()
  }, [getViewport, debouncedSaveLayout])

  // Track user interactions with viewport
  const onMoveStart = useCallback(() => {
    setUserHasInteracted(true)
  }, [])

  // Reset user interaction flag after a period of inactivity
  React.useEffect(() => {
    if (userHasInteracted) {
      const timer = setTimeout(() => {
        setUserHasInteracted(false)
      }, 3000) // Reset after 3 seconds of no interaction
      
      return () => clearTimeout(timer)
    }
  }, [userHasInteracted])

  // Update nodes when props change
  React.useEffect(() => {
    setNodes(initialNodes)
  }, [initialNodes, setNodes])

  // Update edges when props change
  React.useEffect(() => {
    setEdges(initialEdges)
  }, [initialEdges, setEdges])

  // Node drag handlers to trigger layout saving
  const onNodeDragStop = useCallback(() => {
    setUserHasInteracted(true) // Mark interaction when dragging nodes
    debouncedSaveLayout()
  }, [debouncedSaveLayout])

  const onNodesChangeWithSave = useCallback((changes: { type: string; dragging?: boolean; id?: string }[]) => {
    onNodesChange(changes as any[])
    // Check if any node was dragged
    const hasDragChange = changes.some((change) => change.type === 'position' && change.dragging === false)
    if (hasDragChange) {
      setUserHasInteracted(true) // Mark interaction when dragging nodes
      debouncedSaveLayout()
    }
  }, [onNodesChange, debouncedSaveLayout])
  
  const ActiveLaws = powers?.laws?.filter(law => law.active)
  if (!ActiveLaws || ActiveLaws.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-gray-50 rounded-lg">
        <div className="text-center">
          <div className="text-gray-500 text-lg mb-2">No active laws found</div>
          <div className="text-gray-400 text-sm">Deploy some laws to see the visualization</div>
          <div className="text-gray-400 text-sm">Or press the refresh button to load the latest laws</div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full h-full bg-slate-100 overflow-hidden">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChangeWithSave}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        nodeTypes={nodeTypes}
        connectionMode={ConnectionMode.Loose}
        fitView={false}
        fitViewOptions={calculateFitViewOptions()}
        attributionPosition="bottom-left"
        nodesDraggable={true}
        nodesConnectable={false}
        elementsSelectable={true}
        maxZoom={1.2} // Also set global max zoom
        minZoom={0.1} // Global min zoom
        panOnDrag={true}
        zoomOnScroll={true}
        zoomOnPinch={true}
        zoomOnDoubleClick={true}
        panOnScroll={false}
        preventScrolling={true}
        onMoveStart={onMoveStart}
        onMoveEnd={onMoveEnd}
        onInit={onInit}
        onNodeDragStop={onNodeDragStop}
      >
        <Background />
        <MiniMap 
          nodeColor={(node) => {
            const nodeData = node.data as LawSchemaNodeData
            return nodeData.roleColor
          }}
          nodeStrokeWidth={3}
          nodeStrokeColor="#000000"
          nodeBorderRadius={8}
          maskColor="rgba(50, 50, 50, 0.6)"
          position="bottom-right"
          pannable={true}
          zoomable={true}
          ariaLabel="Flow diagram minimap"
        />
      </ReactFlow>
    </div>
  )
}

export const PowersFlow: React.FC = React.memo(() => {
  return (
    <ReactFlowProvider>
      <FlowContent />
    </ReactFlowProvider>
  )
})

export default PowersFlow 