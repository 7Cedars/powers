'use client'

import React, { useCallback, useMemo } from 'react'
import ReactFlow, {
  Node,
  Edge,
  Controls,
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
  useStore,
  MarkerType,
} from 'reactflow'
import 'reactflow/dist/style.css'
import { Law, Powers, Checks } from '@/context/types'
import { parseRole } from '@/utils/parsers'
import { toFullDateFormat, toEurTimeFormat } from '@/utils/toDates'
import { useBlocks } from '@/hooks/useBlocks'
import { parseChainId } from '@/utils/parsers'
import { useBlockNumber, useChains } from 'wagmi'
import {
  CalendarDaysIcon,
  QueueListIcon,
  CheckIcon,
  XMarkIcon,
  UserGroupIcon,
  LinkIcon,
  PlayIcon,
  HandThumbUpIcon,
  DocumentCheckIcon,
  ShieldCheckIcon,
  ClipboardDocumentCheckIcon,
  ClockIcon,
  StopIcon,
  CheckCircleIcon,
  SparklesIcon,
  RocketLaunchIcon,
  ArchiveBoxIcon,
  FlagIcon
} from '@heroicons/react/24/outline'
import { useParams, usePathname, useRouter } from 'next/navigation'
import { setAction, useActionStore, useChecksStatusStore, useActionDataStore } from '@/context/store'
import { LoadingBox } from '@/components/LoadingBox'
import { useChecksStore } from '@/context/store'
import { powersAbi } from '@/context/abi'
import { usePowers } from '@/hooks/usePowers'
import { bigintToRole, bigintToRoleHolders } from '@/utils/bigintTo'
import { NodeStatusIndicator } from '@/components/NodeStatusIndicator'
import HeaderLaw from '@/components/HeaderLaw'

// Default colors for all nodes
const DEFAULT_NODE_COLOR = '#475569' // slate-600
const DEFAULT_BORDER_CLASS = 'border-slate-600'
const EXECUTED_BORDER_CLASS = 'border-green-600'

function getRoleColor(roleId: bigint): string {
  return DEFAULT_NODE_COLOR
}

function getRoleBorderClass(roleId: bigint): string {
  return DEFAULT_BORDER_CLASS
}

function getNodeBorderClass(law: Law, checks: Checks | undefined): string {
  // Check if the action has been successfully executed
  if (checks && checks.actionNotCompleted === false) {
    return EXECUTED_BORDER_CLASS
  }
  return DEFAULT_BORDER_CLASS
}

interface LawSchemaNodeData {
  powers: Powers
  law: Law
  roleColor: string
  onNodeClick?: (lawId: string) => void
  selectedLawId?: string
  connectedNodes?: Set<string>
  actionDataTimestamp?: number
}

const LawSchemaNode: React.FC<NodeProps<LawSchemaNodeData>> = ( {data, id} ) => {
  const { law, roleColor, onNodeClick, selectedLawId, connectedNodes, powers } = data
  const { chainChecks } = useChecksStore()
  const { status: checksStatus, chains: loadingChains } = useChecksStatusStore()
  const { actionData } = useActionDataStore()
  const { timestamps, fetchTimestamps } = useBlocks()
  const chainId = useParams().chainId as string
  const chains = useChains()
  const supportedChain = chains.find(chain => chain.id == parseChainId(chainId))
  const { data: blockNumber } = useBlockNumber()

  // Fetch timestamps for the current law's action data
  React.useEffect(() => {
    const currentLawAction = actionData.get(String(law.index))
    if (currentLawAction) {
      const blockNumbers: bigint[] = []
      
      // Collect all block numbers that need timestamps
      if (currentLawAction.voteStart && currentLawAction.voteStart !== 0n) {
        blockNumbers.push(currentLawAction.voteStart)
      }
      if (currentLawAction.voteEnd && currentLawAction.voteEnd !== 0n) {
        blockNumbers.push(currentLawAction.voteEnd)
      }
      if (currentLawAction.executedAt && currentLawAction.executedAt !== 0n) {
        blockNumbers.push(currentLawAction.executedAt)
      }
      
      // Also fetch timestamps for dependent laws
      if (law.conditions) {
        if (law.conditions.needCompleted !== 0n) {
          const dependentAction = actionData.get(String(law.conditions.needCompleted))
          if (dependentAction && dependentAction.executedAt && dependentAction.executedAt !== 0n) {
            blockNumbers.push(dependentAction.executedAt)
          }
        }
        if (law.conditions.needNotCompleted !== 0n) {
          const dependentAction = actionData.get(String(law.conditions.needNotCompleted))
          if (dependentAction && dependentAction.executedAt && dependentAction.executedAt !== 0n) {
            blockNumbers.push(dependentAction.executedAt)
          }
        }
      }
      
      // Fetch timestamps if we have block numbers
      if (blockNumbers.length > 0) {
        fetchTimestamps(blockNumbers, chainId)
      }
    }
  }, [actionData, law.index, law.conditions, chainId, fetchTimestamps])
  
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
  
  // Helper function to calculate when delay will pass with time remaining info
  const calculateDelayPassTime = (voteEndBlock: bigint | undefined, delaySeconds: bigint): string | null => {
    if (!voteEndBlock || voteEndBlock === 0n || delaySeconds === 0n) {
      return null
    }
    
    try {
      // First, get the timestamp for the voteEnd block
      const cacheKey = `${chainId}:${voteEndBlock}`
      const cachedTimestamp = timestamps.get(cacheKey)
      
      if (cachedTimestamp && cachedTimestamp.timestamp) {
        // Add the delay in seconds to the vote end timestamp
        const voteEndTimestamp = Number(cachedTimestamp.timestamp)
        const delayPassTimestamp = voteEndTimestamp + Number(delaySeconds)
        
        // Check if delay has already passed by comparing with current time
        const currentTimestamp = Math.floor(Date.now() / 1000)
        const isDelayInFuture = delayPassTimestamp > currentTimestamp
        
        // If delay is in the future and we have current block number, calculate time remaining
        if (isDelayInFuture && blockNumber) {
          // Calculate how many seconds remain
          const secondsRemaining = delayPassTimestamp - currentTimestamp
          
          // Convert to hours and minutes
          const hoursRemaining = Math.floor(secondsRemaining / 3600)
          const minutesRemaining = Math.floor((secondsRemaining % 3600) / 60)
          
          // Format the date/time when delay will pass
          const dateStr = toFullDateFormat(delayPassTimestamp)
          const timeStr = toEurTimeFormat(delayPassTimestamp)
          
          // Add time remaining info
          let timeRemainingStr = ''
          if (hoursRemaining > 0) {
            timeRemainingStr = ` (${hoursRemaining}h ${minutesRemaining}m left)`
          } else {
            timeRemainingStr = ` (${minutesRemaining}m left)`
          }
          
          return `${dateStr}: ${timeStr}${timeRemainingStr}`
        } else {
          // Delay has passed or no current block info, just show the date/time
          const dateStr = toFullDateFormat(delayPassTimestamp)
          const timeStr = toEurTimeFormat(delayPassTimestamp)
          return `${dateStr}: ${timeStr}`
        }
      }
      
      // If timestamp not available yet, return null
      return null
    } catch (error) {
      return null
    }
  }

  // Helper function to get date for each check item
  const getCheckItemDate = (itemKey: string): string | null => {
    const currentLawAction = actionData.get(String(law.index))
    // console.log("currentLawAction", currentLawAction)
    
    // Helper function to get proposal data for current law
    const getCurrentLawProposal = () => {
      if (!powers?.proposals) return null
      return powers.proposals.find(proposal => proposal.lawId === law.index)
    }
    
    switch (itemKey) {
      case 'needCompleted':
      case 'needNotCompleted':
        // Get executedAt from the dependent law - this should work regardless of current law's action data
        const dependentLawId = itemKey === 'needCompleted' 
          ? law.conditions?.needCompleted 
          : law.conditions?.needNotCompleted
        
        if (dependentLawId && dependentLawId !== 0n) {
          const dependentAction = actionData.get(String(dependentLawId))
          
          return formatBlockNumberOrTimestamp(dependentAction?.executedAt)
        }
        return null
      
      case 'proposalCreated':
        // Show proposal creation time - use voteStart from current law's action data or proposal data
        if (currentLawAction && currentLawAction.voteStart && currentLawAction.voteStart !== 0n) {
          return formatBlockNumberOrTimestamp(currentLawAction.voteStart)
        }
        // Fallback to proposal data if action data not available
        const proposal = getCurrentLawProposal()
        if (proposal && proposal.voteStart && proposal.voteStart !== 0n) {
          return formatBlockNumberOrTimestamp(proposal.voteStart)
        }
        return null
      
      case 'voteStarted':
        // Use voteStart field - show if current law has action data with voteStart
        if (currentLawAction && currentLawAction.voteStart && currentLawAction.voteStart !== 0n) {
          return formatBlockNumberOrTimestamp(currentLawAction.voteStart)
        }
        // Fallback to proposal data
        const proposalForVoteStart = getCurrentLawProposal()
        if (proposalForVoteStart && proposalForVoteStart.voteStart && proposalForVoteStart.voteStart !== 0n) {
          return formatBlockNumberOrTimestamp(proposalForVoteStart.voteStart)
        }
        return null
      
      case 'voteEnded':
        // Use voteEnd field - show when vote has ended
        if (currentLawAction && currentLawAction.voteEnd && currentLawAction.voteEnd !== 0n) {
          return formatBlockNumberOrTimestamp(currentLawAction.voteEnd)
        }
        // Fallback to proposal data
        const proposalForVoteEnd = getCurrentLawProposal()
        if (proposalForVoteEnd && proposalForVoteEnd.voteEnd && proposalForVoteEnd.voteEnd !== 0n) {
          return formatBlockNumberOrTimestamp(proposalForVoteEnd.voteEnd)
        }
        return null
      
      case 'proposalPassed':
        // Use voteEnd field - show when proposal passed (vote ended successfully)
        if (currentLawAction && currentLawAction.voteEnd && currentLawAction.voteEnd !== 0n) {
          return formatBlockNumberOrTimestamp(currentLawAction.voteEnd)
        }
        // Fallback to proposal data
        const proposalForPassed = getCurrentLawProposal()
        if (proposalForPassed && proposalForPassed.voteEnd && proposalForPassed.voteEnd !== 0n) {
          return formatBlockNumberOrTimestamp(proposalForPassed.voteEnd)
        }
        return null
      
      case 'delay':
        // Calculate delay pass time if voteEnd exists and delay > 0
        // Only show if current law has action data with voteEnd
        if (law.conditions && law.conditions.delayExecution !== 0n && currentLawAction?.voteEnd) {
          return calculateDelayPassTime(currentLawAction.voteEnd, law.conditions.delayExecution)
        }
        // Fallback to proposal data for delay calculation
        if (law.conditions && law.conditions.delayExecution !== 0n) {
          const proposalForDelay = getCurrentLawProposal()
          if (proposalForDelay && proposalForDelay.voteEnd && proposalForDelay.voteEnd !== 0n) {
            return calculateDelayPassTime(proposalForDelay.voteEnd, law.conditions.delayExecution)
          }
        }
        // Return null if no action data or no delay condition
        return null
      
      case 'throttle':
        // Keep as null for now
        return null
      
      case 'executed':        
        // Only show date if actually executed (executedAt > 0 AND actionNotCompleted is false)
        if (currentLawAction && currentLawAction.executedAt && currentLawAction.executedAt !== 0n && checks?.actionNotCompleted === false) {
          return formatBlockNumberOrTimestamp(currentLawAction.executedAt)
        }
        return null
      
      case 'readStateFrom':
        // This doesn't have a direct status check, keep as null
        return null
      
      default:
        return null
    }
  }

  let checks = chainChecks.get(String(law.index))
  if (!checks) {
    checks = {
      allPassed: false,
      delayPassed: false,
      throttlePassed: false,
      authorised: false,
      proposalExists: false,
      proposalPassed: false,
      actionNotCompleted: true,
      lawCompleted: false,
      lawNotCompleted: false,
      voteActive: false,
    }
  }

  const handleClick = () => {
    if (onNodeClick) {
      onNodeClick(String(law.index))
    }
  }

  const isSelected = selectedLawId === String(law.index)
  const borderThickness = isSelected ? 'border-2' : 'border'
  
  // Apply opacity based on connection to selected node
  const isConnected = !selectedLawId || !connectedNodes || connectedNodes.has(String(law.index))
  const opacityClass = isConnected ? 'opacity-100' : 'opacity-50'

  const checkItems = useMemo(() => {
    const items: { 
      key: string
      label: string
      status: boolean | undefined
      hasHandle: boolean
      targetLaw?: bigint
      edgeType?: string
    }[] = []
    
    // 1. Throttle passed
    if (Number(law.conditions?.throttleExecution) != 0) {
      items.push({ 
        key: 'throttle', 
        label: 'Throttle Passed', 
        status: checks?.throttlePassed,
        hasHandle: false
      })
    }
    
    // 2 & 3. Law completed and Law not completed (dependency checks)
    if (law.conditions) {
      if (Number(law.conditions.needCompleted) !== 0) {
        items.push({ 
          key: 'needCompleted', 
          label: `Law ${law.conditions.needCompleted} Completed`, 
          status: checks?.lawCompleted,
          hasHandle: true,
          targetLaw: law.conditions.needCompleted,
          edgeType: 'needCompleted'
        })
      }
      
      if (Number(law.conditions.needNotCompleted) !== 0) {
        items.push({ 
          key: 'needNotCompleted', 
          label: `Law ${law.conditions.needNotCompleted} Not Completed`, 
          status: checks?.lawNotCompleted,
          hasHandle: true,
          targetLaw: law.conditions.needNotCompleted,
          edgeType: 'needNotCompleted'
        })
      }
    }
    
    // 4. Vote started, Vote ended, and Proposal passed (only when quorum > 0)
    // These appear before executed check when voting is required
    if (law.conditions && Number(law.conditions.quorum) !== 0) {
      items.push({ 
        key: 'proposalCreated', 
        label: 'Proposal Created', 
        status: checks?.proposalExists ?? false,
        hasHandle: false
      })
      
      items.push({ 
        key: 'voteStarted', 
        label: 'Vote Started', 
        status: checks?.proposalExists ?? false, // Mirrors proposalCreated - when proposal is created, vote starts
        hasHandle: false
      })
      
      items.push({ 
        key: 'voteEnded', 
        label: 'Vote Ended', 
        status: checks?.proposalExists && checks?.voteActive == false ? true : false, // Mirrors proposalPassed - when proposal passes, vote has ended
        hasHandle: false
      })
      
      // 5. Proposal passed
      items.push({ 
        key: 'proposalPassed', 
        label: 'Proposal Passed', 
        status: checks?.proposalPassed ?? false, // Ensure consistent nullish coalescing
        hasHandle: false
      })
    }
    
    // 6. Delay passed
    if (Number(law.conditions?.delayExecution) != 0) {
      items.push({ 
        key: 'delay', 
        label: 'Delay Passed', 
        status: checks?.delayPassed,
        hasHandle: false
      })
    }
    
    // 7. Read State From (dependency check)
    if (law.conditions && Number(law.conditions.readStateFrom) !== 0) {
        items.push({ 
          key: 'readStateFrom', 
          label: `Read State From Law ${law.conditions.readStateFrom}`, 
          status: undefined, // This doesn't have a direct status check
          hasHandle: true,
          targetLaw: law.conditions.readStateFrom,
          edgeType: 'readStateFrom'
        })
      }
    
    // 8. Executed
    items.push({ 
      key: 'executed', 
      label: 'Executed', 
      status: checks?.actionNotCompleted == false,
      hasHandle: false
    })
    
    return items
  }, [checks, law.conditions])

  const allChecksPassing = checkItems.filter(item => item.status !== undefined).every(item => item.status === true)
  const anyChecksFailing = checkItems.filter(item => item.status !== undefined).some(item => item.status === false)

  const roleBorderClass = getNodeBorderClass(law, checks)

  // Helper values for HeaderLaw
  const lawName = law.nameDescription ? `#${Number(law.index)}: ${law.nameDescription.split(':')[0]}` : `#${Number(law.index)}`;
  const roleName = law.conditions && powers ? bigintToRole(law.conditions.allowedRole, powers) : '';
  const numHolders = law.conditions && powers ? bigintToRoleHolders(law.conditions.allowedRole, powers) : '';
  const description = law.nameDescription ? law.nameDescription.split(':')[1] || '' : '';
  const contractAddress = law.lawAddress;
  const blockExplorerUrl = supportedChain?.blockExplorers?.default.url;

  return (
    <NodeStatusIndicator status={ loadingChains.includes(String(law.index)) ? checksStatus as "loading" | "success" | "error" | "initial" : "success"}>
      <div 
        className={`shadow-lg rounded-lg bg-white ${borderThickness} min-w-[300px] max-w-[380px] w-[380px] overflow-hidden ${roleBorderClass} cursor-pointer hover:shadow-xl transition-shadow ${opacityClass} relative`}
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
        
        {/* Checks Section - Database Rows Style */}
        {!checks ? (
          // Loading state when checks are undefined
          <div className="relative p-4 bg-slate-50">
            <div className="flex items-center justify-center">
              <LoadingBox />
            </div>
          </div>
        ) : checkItems.length > 0 ? (
          <div className="relative bg-slate-50">
            {checkItems.map((item, index) => (
              <div key={item.key} className="relative">
                <div className="px-4 py-2 flex items-center justify-between text-xs relative">
                <div className="flex items-center space-x-2 flex-1">
                    <div className="w-6 h-6 flex justify-center items-center relative">
                    {item.status !== undefined ? (
                      // Status-based checks with appropriate icons
                        item.key === 'executed' ? (
                          <div className={`w-6 h-6 rounded-full border flex items-center justify-center bg-white relative z-10 ${allChecksPassing ? 'border-black' : 'border-gray-400'}`}>
                            <RocketLaunchIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                        ) : item.key === 'proposalPassed' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <CheckCircleIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                        ) : item.key === 'delay' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <CalendarDaysIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                      ) : item.key === 'throttle' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <QueueListIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                      ) : item.key === 'needCompleted' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <DocumentCheckIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                      ) : item.key === 'needNotCompleted' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <XMarkIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                      ) : item.key === 'voteStarted' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <ArchiveBoxIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                      ) : item.key === 'voteEnded' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <FlagIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                      ) : item.key === 'proposalCreated' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <ClipboardDocumentCheckIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                        ) : (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <ShieldCheckIcon className={`w-4 h-4 ${item.status ? 'text-green-600' : 'text-black'}`} />
                          </div>
                        )
                    ) : (
                      // Dependency checks without status
                      item.key === 'readStateFrom' ? (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <LinkIcon className="w-4 h-4 text-black" />
                          </div>
                        ) : (
                          <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                            <ClipboardDocumentCheckIcon className="w-4 h-4 text-black" />
                          </div>
                        )
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
                  
                  {/* Target handle for executed check */}
                  {item.key === 'executed' && (
                    <Handle
                      type="target"
                      position={Position.Right}
                      id="executed-target"
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
            ))}
          </div>
        ) : null}
      </div>
    </NodeStatusIndicator>
  )
}

const nodeTypes = {
  lawSchema: LawSchemaNode,
}

interface PowersFlowProps {
  powers: Powers
  selectedLawId?: string
}

// Helper function to find all nodes connected to a selected node through dependencies
function findConnectedNodes(selectedLawId: string, laws: Law[]): Set<string> {
  const connected = new Set<string>()
  const visited = new Set<string>()
  
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
      if (law.conditions.needCompleted !== 0n) {
        const targetId = String(law.conditions.needCompleted)
        if (dependencies.has(targetId)) {
        dependencies.get(lawId)?.add(targetId)
        dependents.get(targetId)?.add(lawId)
        }
      }
      if (law.conditions.needNotCompleted !== 0n) {
        const targetId = String(law.conditions.needNotCompleted)
        if (dependencies.has(targetId)) {
        dependencies.get(lawId)?.add(targetId)
        dependents.get(targetId)?.add(lawId)
        }
      }
      if (law.conditions.readStateFrom !== 0n) {
        const targetId = String(law.conditions.readStateFrom)
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
      if (law.conditions.needCompleted !== 0n) {
        const targetId = String(law.conditions.needCompleted)
        if (dependencies.has(targetId)) {
          dependencies.get(lawId)?.add(targetId)
          dependents.get(targetId)?.add(lawId)
        }
      }
      if (law.conditions.needNotCompleted !== 0n) {
        const targetId = String(law.conditions.needNotCompleted)
        if (dependencies.has(targetId)) {
          dependencies.get(lawId)?.add(targetId)
          dependents.get(targetId)?.add(lawId)
        }
      }
      if (law.conditions.readStateFrom !== 0n) {
        const targetId = String(law.conditions.readStateFrom)
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
    if (yRowMap.has(oldRow)) {
      positions.set(lawId, { x: pos.x, y: yRowMap.get(oldRow)! * NODE_SPACING_Y })
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

const FlowContent: React.FC<PowersFlowProps> = ({ powers, selectedLawId }) => {
  const { fitView, getNode, getNodes, setCenter, getViewport, setViewport } = useReactFlow()
  const { chainChecks } = useChecksStore()
  const { actionData } = useActionDataStore()
  const router = useRouter()
  const chainId = useParams().chainId as string
  const action = useActionStore()
  const [lastSelectedLawId, setLastSelectedLawId] = React.useState<bigint>(action.lawId)
  const [isInitialized, setIsInitialized] = React.useState(false)
  const [userHasInteracted, setUserHasInteracted] = React.useState(false)
  const reactFlowInstanceRef = React.useRef<any>(null)
  const { status: checksStatus } = useChecksStatusStore()
  const pathname = usePathname()

  // console.log("@FlowContent: waypoint 0", {action, selectedLawId, lastSelectedLawId, powers})
  
  // Debounced layout saving
  const saveTimeoutRef = React.useRef<NodeJS.Timeout | null>(null)

  // Function to load saved layout from localStorage
  const loadSavedLayout = React.useCallback((): Record<string, { x: number; y: number }> | undefined => {
    try {
      let localStore = localStorage.getItem("powersProtocols")
      if (!localStore || localStore === "undefined") return undefined
      
      const saved: Powers[] = JSON.parse(localStore)
      const existing = saved.find(item => item.contractAddress === powers.contractAddress)
      
      if (existing && existing.layout) {
        return existing.layout
      }
      
      return undefined
    } catch (error) {
      console.error('Failed to load layout from localStorage:', error)
      return undefined
    }
  }, [powers.contractAddress])

  // Function to save powers object to localStorage (similar to usePowers.ts)
  const savePowersToLocalStorage = React.useCallback((updatedPowers: Powers) => {
    try {
      let localStore = localStorage.getItem("powersProtocols")
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
      ...powers,
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

  // Helper function to calculate proper centering coordinates accounting for panel width
  const calculateCenterPosition = useCallback((nodeX: number, nodeY: number) => {
    const viewportWidth = window.innerWidth
    const expandedPanelWidth = Math.min(640, viewportWidth - 40)
    const isSmallScreen = viewportWidth <= 2 * expandedPanelWidth
    if (isSmallScreen) {
      // Center in the middle of the viewport
      return {
        x: nodeX + 200 - viewportWidth / 2,
        y: nodeY + 150
      }
    } else {
      // Offset for the panel as before
      const centerOffsetX = expandedPanelWidth / 2
      return {
        x: nodeX + 200 - centerOffsetX, // 200 is half the node width, subtract centerOffsetX to shift left
        y: nodeY + 150 // Keep existing vertical offset
      }
    }
  }, [])

  // Helper function to calculate fitView options accounting for panel width
  const calculateFitViewOptions = useCallback(() => {
    const viewportWidth = window.innerWidth
    const expandedPanelWidth = Math.min(640, viewportWidth - 40)
    const isSmallScreen = viewportWidth <= 2 * expandedPanelWidth
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
    router.push(`/${chainId}/${powers?.contractAddress}/laws/${lawId}`)
    // console.log("@handleNodeClick: waypoint 1", {action})
  }, [router, chainId, powers?.contractAddress, action, getViewport, setAction])

  // Handle ReactFlow initialization
  const onInit = useCallback((reactFlowInstance: any) => {
    reactFlowInstanceRef.current = reactFlowInstance
    setIsInitialized(true)
    
    const storedViewport = getStoredViewport()
    
    // If there's no selected law (main flow page), always fit all nodes in view
    if (!action.lawId && !selectedLawId) {
      setTimeout(() => {
        fitViewWithPanel()
        // Save the fitted viewport
        setTimeout(() => {
          const currentViewport = getViewport()
          setStoredViewport(currentViewport)
        }, 900)
      }, 100)
    } else if (storedViewport) {
      // Restore stored viewport only when there's a selected law
      setTimeout(() => {
        setViewport(storedViewport, { duration: 0 })
      }, 100)
    }
  }, [setViewport, fitView, getViewport, action.lawId, selectedLawId, calculateFitViewOptions, fitViewWithPanel])

  // Auto-fit view when navigating to home page (no selected law)
  React.useEffect(() => {
    // Don't change viewport if:
    // 1. ReactFlow isn't initialized yet
    // 2. Checks are currently being performed (pending status)
    // 3. User has manually interacted with the viewport recently
    if (!isInitialized || checksStatus === "pending" || userHasInteracted) return
    
    // Check if we're on the home page (no law selected in URL)
    const isHomePage = !pathname.includes('/laws/')
    
    // If there's no selected law (home page), fit all nodes in view
    if ((!action.lawId && !selectedLawId) || isHomePage) {
      const timer = setTimeout(() => {
        fitViewWithPanel()
        // Save the fitted viewport
        setTimeout(() => {
          const currentViewport = getViewport()
          setStoredViewport(currentViewport)
        }, 900)
      }, 100)
      
      return () => clearTimeout(timer)
    }
  }, [action.lawId, selectedLawId, isInitialized, checksStatus, userHasInteracted, fitViewWithPanel, getViewport, pathname])

  // Reset user interaction flag when navigating to home page
  React.useEffect(() => {
    const isHomePage = !pathname.includes('/laws/')
    if (isHomePage) {
      setUserHasInteracted(false)
    }
  }, [pathname])

  // Auto-zoom to selected law from store or restore previous viewport
  React.useEffect(() => {
    // Don't change viewport if:
    // 1. ReactFlow isn't initialized yet
    // 2. Checks are currently being performed (pending status)
    // 3. User has manually interacted with the viewport recently
    if (!isInitialized || checksStatus === "pending" || userHasInteracted) return
    
    const timer = setTimeout(() => {
      // Only auto-zoom if the selected law has actually changed
      if (action.lawId !== lastSelectedLawId) {
        setLastSelectedLawId(action.lawId)
        
        if (action.lawId && action.lawId !== 0n) {
          // Zoom to the law stored in the action store
          const selectedNode = getNode(String(action.lawId))
          // console.log("@onInit: waypoint 0", {selectedNode})
          if (selectedNode) {
            const centerPos = calculateCenterPosition(selectedNode.position.x, selectedNode.position.y)
            setCenter(centerPos.x, centerPos.y, {
              zoom: 1.6,
              duration: 800,
            })
          }
        }
        // Remove the automatic fitViewWithPanel call when no law is selected
        // This was causing the continuous zooming out behavior
      }
    }, 100)
    
    return () => clearTimeout(timer)
  }, [action.lawId, getNode, setCenter, lastSelectedLawId, isInitialized, calculateCenterPosition, checksStatus, userHasInteracted])

  // Legacy auto-zoom to selected law (keep for backward compatibility but only if no store state)
  React.useEffect(() => {
    // Don't change viewport during checks or if user has interacted
    if (checksStatus === "pending" || userHasInteracted) return
    
    if (selectedLawId && (!action.lawId || action.lawId === 0n) && !getStoredViewport()) {
      // Small delay to ensure nodes are rendered
      const timer = setTimeout(() => {
        const selectedNode = getNode(selectedLawId)
        if (selectedNode) {
          // Center on the selected node with proper offset for panel
          const centerPos = calculateCenterPosition(selectedNode.position.x, selectedNode.position.y)
          setCenter(centerPos.x, centerPos.y, {
            zoom: 1.6,
            duration: 800, // Smooth animation
          })
        }
      }, 100)
      
      return () => clearTimeout(timer)
    }
  }, [selectedLawId, getNode, setCenter, action.lawId, calculateCenterPosition, checksStatus, userHasInteracted])

  // Create nodes and edges from laws
  const { initialNodes, initialEdges } = useMemo(() => {
    if (!powers.activeLaws) return { initialNodes: [], initialEdges: [] }
    
    const nodes: Node[] = []
    const edges: Edge[] = []
    
    // Use hierarchical layout instead of simple grid
    const savedLayout = loadSavedLayout()
    const positions = createHierarchicalLayout(powers.activeLaws, savedLayout)
    
    // Find connected nodes if a law is selected
    const selectedLawIdFromStore = action.lawId !== 0n ? String(action.lawId) : undefined
    const connectedNodes = selectedLawIdFromStore 
      ? findConnectedNodes(selectedLawIdFromStore, powers.activeLaws!)
      : undefined
    
    powers.activeLaws.forEach((law, lawIndex) => {
      const roleColor = DEFAULT_NODE_COLOR
      
      // Get checks for this law
      const checks = chainChecks?.get(String(law.index))
      const roleBorderClass = getNodeBorderClass(law, checks)
      
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
          checks,
          roleColor,
          onNodeClick: handleNodeClick,
          selectedLawId: selectedLawIdFromStore,
          connectedNodes,
          actionDataTimestamp: Date.now(),
        },
      })
      
      // Create edges from dependency checks to target laws
      if (law.conditions) {
        const sourceId = lawId
        
        // Edge from needCompleted check to target law
        if (law.conditions.needCompleted != 0n) {
          const targetId = String(law.conditions.needCompleted)
          // Determine if this edge should be highlighted (connected to selected node)
          const isEdgeConnected = !connectedNodes || connectedNodes.has(sourceId) || connectedNodes.has(targetId)
          const edgeOpacity = isEdgeConnected ? 1 : 0.5
          
          edges.push({
            id: `${sourceId}-needCompleted-${targetId}`,
            source: sourceId,
            sourceHandle: 'needCompleted-handle',
            target: targetId,
            targetHandle: 'executed-target',
            type: 'smoothstep',
            label: 'Needs Completed',
            style: { stroke: '#6B7280', strokeWidth: 2, opacity: edgeOpacity },
            labelStyle: { fontSize: '10px', fontWeight: 'bold', fill: '#6B7280', opacity: edgeOpacity },
            labelBgStyle: { fill: '#f1f5f9', fillOpacity: 0.8 * edgeOpacity },
            markerStart: {
              type: MarkerType.ArrowClosed,
              color: '#6B7280',
              width: 20,
              height: 20,
            },
            zIndex: 10,
          })
        }
        
        // Edge from needNotCompleted check to target law
        if (law.conditions.needNotCompleted != 0n) {
          const targetId = String(law.conditions.needNotCompleted)
          // Determine if this edge should be highlighted (connected to selected node)
          const isEdgeConnected = !connectedNodes || connectedNodes.has(sourceId) || connectedNodes.has(targetId)
          const edgeOpacity = isEdgeConnected ? 1 : 0.5
          
          edges.push({
            id: `${sourceId}-needNotCompleted-${targetId}`,
            source: sourceId,
            sourceHandle: 'needNotCompleted-handle',
            target: targetId,
            targetHandle: 'executed-target',
            type: 'smoothstep',
            label: 'Needs Not Completed',
            style: { stroke: '#6B7280', strokeWidth: 2, strokeDasharray: '6,3', opacity: edgeOpacity },
            labelStyle: { fontSize: '10px', fontWeight: 'bold', fill: '#6B7280', opacity: edgeOpacity },
            labelBgStyle: { fill: '#f1f5f9', fillOpacity: 0.8 * edgeOpacity },
            markerStart: {
              type: MarkerType.ArrowClosed,
              color: '#6B7280',
              width: 20,
              height: 20,
            },
            zIndex: 10,
          })
        }
        
        // Edge from readStateFrom check to target law
        if (law.conditions.readStateFrom != 0n) {
          const targetId = String(law.conditions.readStateFrom)
          // Determine if this edge should be highlighted (connected to selected node)
          const isEdgeConnected = !connectedNodes || connectedNodes.has(sourceId) || connectedNodes.has(targetId)
          const edgeOpacity = isEdgeConnected ? 1 : 0.5
          
          edges.push({
            id: `${sourceId}-readStateFrom-${targetId}`,
            source: sourceId,
            sourceHandle: 'readStateFrom-handle',
            target: targetId,
            targetHandle: 'executed-target',
            type: 'smoothstep',
            label: 'Read State From',
            style: { stroke: '#6B7280', strokeWidth: 2, strokeDasharray: '3,3', opacity: edgeOpacity },
            labelStyle: { fontSize: '10px', fontWeight: 'bold', fill: '#6B7280', opacity: edgeOpacity },
            labelBgStyle: { fill: '#f1f5f9', fillOpacity: 0.8 * edgeOpacity },
            markerStart: {
              type: MarkerType.ArrowClosed,
              color: '#6B7280',
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
    powers.activeLaws, 
    powers.contractAddress,
    chainChecks, 
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

  const onNodesChangeWithSave = useCallback((changes: any) => {
    onNodesChange(changes)
    // Check if any node was dragged
    const hasDragChange = changes.some((change: any) => change.type === 'position' && change.dragging === false)
    if (hasDragChange) {
      setUserHasInteracted(true) // Mark interaction when dragging nodes
      debouncedSaveLayout()
    }
  }, [onNodesChange, debouncedSaveLayout])

  if (!powers.activeLaws || powers.activeLaws.length === 0) {
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

export const PowersFlow: React.FC<PowersFlowProps> = React.memo((props) => {
  return (
    <ReactFlowProvider>
      <FlowContent {...props} />
    </ReactFlowProvider>
  )
})

export default PowersFlow 