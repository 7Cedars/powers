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
} from 'reactflow'
import 'reactflow/dist/style.css'
import { Law, Powers, Checks } from '@/context/types'
import { parseRole } from '@/utils/parsers'
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
import { setAction, useActionStore } from '@/context/store'
import { LoadingBox } from '@/components/LoadingBox'

// Role colors matching LawBox.tsx color scheme
const ROLE_COLORS = [
  '#2563EB', // blue-600
  '#DC2626', // red-600  
  '#D97706', // yellow-600 (amber-600 for better contrast)
  '#9333EA', // purple-600
  '#16A34A', // green-600
  '#EA580C', // orange-600
  '#475569', // slate-600
]

const ROLE_BORDER_COLORS = [
  'border-blue-600',
  'border-red-600', 
  'border-yellow-600',
  'border-purple-600',
  'border-green-600',
  'border-orange-600',
  'border-slate-600',
]

function getRoleColor(roleId: bigint): string {
  const roleIndex = parseRole(roleId) % ROLE_COLORS.length
  return ROLE_COLORS[roleIndex]
}

function getRoleBorderClass(roleId: bigint): string {
  const roleIndex = parseRole(roleId) % ROLE_BORDER_COLORS.length
  return ROLE_BORDER_COLORS[roleIndex]
}

interface LawSchemaNodeData {
  law: Law
  checks?: Checks
  roleColor: string
  onNodeClick?: (lawId: string) => void
  selectedLawId?: string
  connectedNodes?: Set<string>
}

const LawSchemaNode: React.FC<NodeProps<LawSchemaNodeData>> = ({ data, id }) => {
  const { law, checks, roleColor, onNodeClick, selectedLawId, connectedNodes } = data

  // Debug logging
  console.log(`LawSchemaNode ${law.index} - checks:`, checks)

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
    if (!checks) return []
    
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
        status: checks.throttlePassed,
        hasHandle: false
      })
    }
    
    // 2 & 3. Law completed and Law not completed (dependency checks)
    if (law.conditions) {
      if (Number(law.conditions.needCompleted) !== 0) {
        items.push({ 
          key: 'needCompleted', 
          label: `Law ${law.conditions.needCompleted} Completed`, 
          status: checks.lawCompleted,
          hasHandle: true,
          targetLaw: law.conditions.needCompleted,
          edgeType: 'needCompleted'
        })
      }
      
      if (Number(law.conditions.needNotCompleted) !== 0) {
        items.push({ 
          key: 'needNotCompleted', 
          label: `Law ${law.conditions.needNotCompleted} Not Completed`, 
          status: checks.lawNotCompleted,
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
        status: checks.proposalExists ?? false,
        hasHandle: false
      })
      
      items.push({ 
        key: 'voteStarted', 
        label: 'Vote Started', 
        status: (checks as any).voteStarted ?? false,
        hasHandle: false
      })
      
      items.push({ 
        key: 'voteEnded', 
        label: 'Vote Ended', 
        status: (checks as any).voteEnded ?? false,
        hasHandle: false
      })
      
      // 5. Proposal passed
      items.push({ 
        key: 'proposalPassed', 
        label: 'Proposal Passed', 
        status: checks.proposalPassed,
        hasHandle: false
      })
    }
    
    // 6. Delay passed
    if (Number(law.conditions?.delayExecution) != 0) {
      items.push({ 
        key: 'delay', 
        label: 'Delay Passed', 
        status: checks.delayPassed,
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
      status: checks.allPassed ?? false,
      hasHandle: false
    })
    
    return items
  }, [checks, law.conditions])

  const allChecksPassing = checkItems.filter(item => item.status !== undefined).every(item => item.status === true)
  const anyChecksFailing = checkItems.filter(item => item.status !== undefined).some(item => item.status === false)

  const roleBorderClass = law.conditions 
    ? getRoleBorderClass(law.conditions.allowedRole)
    : 'border-slate-600'

  return (
    <div 
      className={`shadow-lg rounded-lg bg-white ${borderThickness} min-w-[300px] max-w-[380px] w-[380px] overflow-hidden ${roleBorderClass} cursor-pointer hover:shadow-xl transition-shadow ${opacityClass}`}
      onClick={handleClick}
    >
      {/* Law Header - Database Table Style */}
      <div 
        className="px-4 py-3 border-b border-gray-300 bg-slate-100"
        style={{ borderBottomColor: roleColor }}
      >
        <div className="flex items-center justify-between">
          <div className="flex-1 min-w-0">
            <div className="font-bold text-sm mb-1 break-words text-slate-800">
              📋 #{Number(law.index)}{law.nameDescription ? `: ${law.nameDescription.split(':')[0]}` : ""}
            </div>
            
            <div className="text-xs text-gray-700 mb-1 font-medium break-words">
              {law.nameDescription ? `${law.nameDescription.split(':')[1]}` : ""}
              </div>
            
            <div className="flex items-center space-x-4 text-xs text-gray-600">
              {law.conditions && (
                <>
                  <span className="truncate">Role: {
                    Number(law.conditions.allowedRole) === 0 
                      ? "Admin" 
                      : Number(law.conditions.allowedRole) > 10000000000000000 
                      ? "Public"
                      : Number(law.conditions.allowedRole)
                  }</span>
                </>
              )}
            </div>
          </div>
          
        
        </div>
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
                          <RocketLaunchIcon className={`w-4 h-4 ${allChecksPassing ? 'text-black' : 'text-gray-400'}`} />
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
                    <div className="text-[10px] text-gray-400 mb-0.5">Dec 15, 2024 - 14:32</div>
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
  )
}

const nodeTypes = {
  lawSchema: LawSchemaNode,
}

interface PowersFlowProps {
  powers: Powers
  chainChecks?: Map<string, Checks>
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

// Helper function to create a hierarchical layout based on dependencies
function createHierarchicalLayout(laws: Law[]): Map<string, { x: number; y: number }> {
  const positions = new Map<string, { x: number; y: number }>()
  
  // Build dependency graph
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
        // Only add if the target law actually exists
        if (dependencies.has(targetId)) {
          dependencies.get(lawId)?.add(targetId)
          dependents.get(targetId)?.add(lawId)
        }
      }
      if (law.conditions.needNotCompleted !== 0n) {
        const targetId = String(law.conditions.needNotCompleted)
        // Only add if the target law actually exists
        if (dependencies.has(targetId)) {
          dependencies.get(lawId)?.add(targetId)
          dependents.get(targetId)?.add(lawId)
        }
      }
      if (law.conditions.readStateFrom !== 0n) {
        const targetId = String(law.conditions.readStateFrom)
        // Only add if the target law actually exists
        if (dependencies.has(targetId)) {
          dependencies.get(lawId)?.add(targetId)
          dependents.get(targetId)?.add(lawId)
        }
      }
    }
  })
  
  // Find independent nodes (nodes with no dependencies and no dependents)
  const independentNodes = Array.from(dependencies.keys()).filter(lawId => {
    const hasDependencies = (dependencies.get(lawId)?.size || 0) > 0
    const hasDependents = (dependents.get(lawId)?.size || 0) > 0
    return !hasDependencies && !hasDependents
  })
  
  // Find all dependency chains (excluding independent nodes from chain building)
  const findChains = (): string[][] => {
    const visited = new Set<string>()
    const chains: string[][] = []
    
    // Only consider nodes that have dependencies or dependents for chain building
    // AND exclude independent nodes explicitly
    const chainNodes = Array.from(dependencies.keys()).filter(lawId => {
      const hasDependencies = (dependencies.get(lawId)?.size || 0) > 0
      const hasDependents = (dependents.get(lawId)?.size || 0) > 0
      // Must have either dependencies OR dependents (or both) to be part of a chain
      return hasDependencies || hasDependents
    })
    
    // Find nodes with no dependencies (but have dependents) - start of chains
    const startNodes = chainNodes.filter(lawId => 
      dependencies.get(lawId)?.size === 0 && (dependents.get(lawId)?.size || 0) > 0
    )
    
    // Build chains starting from each start node
    const buildChain = (startNode: string, currentChain: string[] = []): string[][] => {
      if (visited.has(startNode)) return []
      
      const newChain = [...currentChain, startNode]
      visited.add(startNode)
      
      const dependentNodes = Array.from(dependents.get(startNode) || [])
        .filter(dep => chainNodes.includes(dep)) // Only follow chain nodes
      
      if (dependentNodes.length === 0) {
        // End of chain
        return [newChain]
      }
      
      // Continue chain with each dependent
      const subChains: string[][] = []
      dependentNodes.forEach(dependent => {
        const subChain = buildChain(dependent, newChain)
        subChains.push(...subChain)
      })
      
      return subChains.length > 0 ? subChains : [newChain]
    }
    
    // Build chains from start nodes
    startNodes.forEach(startNode => {
      const nodeChains = buildChain(startNode)
      chains.push(...nodeChains)
    })
    
    // Handle any remaining unvisited chain nodes that might be part of cycles
    // or disconnected components, but ONLY if they have actual dependencies
    const unvisited = chainNodes.filter(lawId => 
      !visited.has(lawId) && (dependencies.get(lawId)?.size || 0) > 0
    )
    
    unvisited.forEach(lawId => {
      if (!visited.has(lawId)) {
        const nodeChains = buildChain(lawId)
        chains.push(...nodeChains)
      }
    })
    
    return chains
  }
  
  // Get all dependency chains and sort by length (longest first)
  const chains = findChains().sort((a, b) => b.length - a.length)
  
  // Layout constants
  const NODE_SPACING_X = 500 // Horizontal spacing between nodes
  const NODE_SPACING_Y = 450 // Vertical spacing between rows
  const MAX_NODES_PER_ROW = 6 // Maximum nodes per row
  
  const positionedNodes = new Set<string>()
  
  // Position dependency chains in horizontal rows
  let currentY = 0
  
  chains.forEach(chain => {
    if (chain.some(node => positionedNodes.has(node))) return // Skip if any node already positioned
    
    // Position chain horizontally
    chain.forEach((lawId, index) => {
      if (!positionedNodes.has(lawId)) {
        const x = index * NODE_SPACING_X
        positions.set(lawId, { x, y: currentY })
        positionedNodes.add(lawId)
      }
    })
    
    currentY += NODE_SPACING_Y
  })
  
  // Position ALL independent nodes in a single horizontal row
  if (independentNodes.length > 0) {
    // Add some extra space before independent nodes row if there are chains above
    if (chains.length > 0) {
      currentY += NODE_SPACING_Y * 0.01 // Add half spacing for visual separation
    }
    
    // Position all independent nodes in a single horizontal row
    independentNodes.forEach((lawId, index) => {
      const x = index * NODE_SPACING_X
      positions.set(lawId, { x, y: currentY })
      positionedNodes.add(lawId)
    })
  }
  
  // Handle any remaining unpositioned nodes (shouldn't happen, but just in case)
  const remainingNodes = Array.from(dependencies.keys()).filter(lawId => !positionedNodes.has(lawId))
  if (remainingNodes.length > 0) {
    remainingNodes.forEach((lawId, index) => {
      const x = index * NODE_SPACING_X
      const y = currentY + NODE_SPACING_Y
      positions.set(lawId, { x, y })
    })
  }
  
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

const FlowContent: React.FC<PowersFlowProps> = ({ powers, chainChecks, selectedLawId }) => {
  const { fitView, getNode, getNodes, setCenter, getViewport, setViewport } = useReactFlow()
  const router = useRouter()
  const chainId = useParams().chainId as string
  const action = useActionStore()
  const [lastSelectedLawId, setLastSelectedLawId] = React.useState<bigint>(action.lawId)
  const [isInitialized, setIsInitialized] = React.useState(false)
  const reactFlowInstanceRef = React.useRef<any>(null)

  // Helper function to calculate proper centering coordinates accounting for panel width
  const calculateCenterPosition = useCallback((nodeX: number, nodeY: number) => {
    // Calculate panel width based on PowersOverview logic
    const viewportWidth = window.innerWidth
    const expandedPanelWidth = Math.min(640, viewportWidth - 40)
    const collapsedPanelWidth = 32
    
    // For now, assume panel is expanded (we could pass this as a prop if needed)
    // We need to shift the center point LEFT so the visible result appears centered in the visible area
    const panelWidth = expandedPanelWidth
    const centerOffsetX = panelWidth / 2
    
    return {
      x: nodeX + 200 - centerOffsetX, // 200 is half the node width, subtract centerOffsetX to shift left
      y: nodeY + 150 // Keep existing vertical offset
    }
  }, [])

  // Helper function to calculate fitView options accounting for panel width
  const calculateFitViewOptions = useCallback(() => {
    const viewportWidth = window.innerWidth
    const expandedPanelWidth = Math.min(640, viewportWidth - 40)
    
    // Calculate the percentage of the screen the panel takes up
    const panelWidthRatio = expandedPanelWidth / viewportWidth
    
    return {
      padding: 0.2,
      duration: 800,
      // Adjust the fit area to exclude the panel area
      includeHiddenNodes: false,
      // We can't directly exclude the panel area, so we'll use a smaller effective area
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
    
    // Calculate the available area for the flow chart (excluding panel)
    const availableWidth = viewportWidth - expandedPanelWidth
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
    
    // Calculate center position accounting for panel
    const contentCenterX = (minX + maxX) / 2
    const contentCenterY = (minY + maxY) / 2
    
    // Position content in the center of the available area (to the right of panel)
    // The center of the available area is at: expandedPanelWidth + availableWidth / 2
    const availableAreaCenterX = expandedPanelWidth + availableWidth / 2
    const x = -contentCenterX * zoom + availableAreaCenterX
    const y = -contentCenterY * zoom + availableHeight / 2
    
    setViewport({ x, y, zoom }, { duration: 800 })
  }, [getNodes, setViewport])

  const handleNodeClick = useCallback((lawId: string) => {
    // Store current viewport before navigation
    const currentViewport = getViewport()
    setStoredViewport(currentViewport)
    
    // Navigate to the law page within the flow layout
    setAction({
      ...action,
      lawId: BigInt(lawId),
    })
    router.push(`/${chainId}/${powers?.contractAddress}/flow/laws/${lawId}`)
  }, [router, chainId, powers?.contractAddress, action, getViewport])

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

  // Auto-zoom to selected law from store or restore previous viewport
  React.useEffect(() => {
    if (!isInitialized) return // Don't run until ReactFlow is initialized
    
    const timer = setTimeout(() => {
      // Only auto-zoom if the selected law has actually changed
      if (action.lawId !== lastSelectedLawId) {
        setLastSelectedLawId(action.lawId)
        
        if (action.lawId && action.lawId !== 0n) {
          // Zoom to the law stored in the action store
          const selectedNode = getNode(String(action.lawId))
          if (selectedNode) {
            const centerPos = calculateCenterPosition(selectedNode.position.x, selectedNode.position.y)
            setCenter(centerPos.x, centerPos.y, {
              zoom: 1.6,
              duration: 800,
            })
          }
        } else {
          // No law selected, show all nodes (main flow page)
          fitViewWithPanel()
        }
      } else if (getStoredViewport() && !action.lawId && isInitialized) {
        // If no law is selected but we have stored state, still fit all nodes (main page behavior)
        fitViewWithPanel()
      }
    }, 100)
    
    return () => clearTimeout(timer)
  }, [action.lawId, getNode, setCenter, fitView, setViewport, lastSelectedLawId, isInitialized, getViewport, calculateCenterPosition, calculateFitViewOptions, fitViewWithPanel])

  // Legacy auto-zoom to selected law (keep for backward compatibility but only if no store state)
  React.useEffect(() => {
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
  }, [selectedLawId, getNode, setCenter, action.lawId, calculateCenterPosition])

  // Create nodes and edges from laws
  const { initialNodes, initialEdges } = useMemo(() => {
    if (!powers.activeLaws) return { initialNodes: [], initialEdges: [] }
    
    const nodes: Node[] = []
    const edges: Edge[] = []
    
    // Use hierarchical layout instead of simple grid
    const positions = createHierarchicalLayout(powers.activeLaws)
    
    // Find connected nodes if a law is selected
    const selectedLawIdFromStore = action.lawId !== 0n ? String(action.lawId) : undefined
    const connectedNodes = selectedLawIdFromStore 
      ? findConnectedNodes(selectedLawIdFromStore, powers.activeLaws!)
      : undefined
    
    powers.activeLaws.forEach((law, lawIndex) => {
      const roleColor = law.conditions 
        ? getRoleColor(law.conditions.allowedRole)
        : '#475569' // slate-600 as fallback
      
      const roleBorderClass = law.conditions 
        ? getRoleBorderClass(law.conditions.allowedRole)
        : 'border-slate-600'
      
      const lawId = String(law.index)
      const position = positions.get(lawId) || { x: 0, y: 0 }
      
      // Get checks for this law
      const checks = chainChecks?.get(lawId)
      
      // Create law schema node
      nodes.push({
        id: lawId,
        type: 'lawSchema',
        position,
        data: {
          law,
          checks,
          roleColor,
          onNodeClick: handleNodeClick,
          selectedLawId: selectedLawIdFromStore,
          connectedNodes,
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
            labelBgStyle: { fill: 'white', fillOpacity: 0.8 * edgeOpacity },
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
            labelBgStyle: { fill: 'white', fillOpacity: 0.8 * edgeOpacity },
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
            labelBgStyle: { fill: 'white', fillOpacity: 0.8 * edgeOpacity },
            zIndex: 10,
          })
        }
      }
    })
    
    return { initialNodes: nodes, initialEdges: edges }
  }, [powers.activeLaws, chainChecks, handleNodeClick, selectedLawId, action.lawId])

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
  }, [getViewport])

  // Update nodes when props change
  React.useEffect(() => {
    setNodes(initialNodes)
  }, [initialNodes, setNodes])

  // Update edges when props change
  React.useEffect(() => {
    setEdges(initialEdges)
  }, [initialEdges, setEdges])

  if (!powers.activeLaws || powers.activeLaws.length === 0) {
    return (
      <div className="w-full h-[600px] flex items-center justify-center bg-gray-50 rounded-lg">
        <div className="text-center">
          <div className="text-gray-500 text-lg mb-2">No active laws found</div>
          <div className="text-gray-400 text-sm">Deploy some laws to see the visualization</div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full h-full bg-slate-100 overflow-hidden">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
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
        onMoveEnd={onMoveEnd}
        onInit={onInit}
      >
        <Controls />
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