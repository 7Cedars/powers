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
  ClipboardDocumentCheckIcon
} from '@heroicons/react/24/outline'

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
  isCollapsed: boolean
  onToggleCollapse: () => void
}

const LawSchemaNode: React.FC<NodeProps<LawSchemaNodeData>> = ({ data, id }) => {
  const { law, checks, roleColor, isCollapsed, onToggleCollapse } = data

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
    if (checks.throttlePassed !== undefined) {
      items.push({ 
        key: 'throttle', 
        label: 'Throttle Passed', 
        status: checks.throttlePassed,
        hasHandle: false
      })
    }
    
    // 2 & 3. Law completed and Law not completed (dependency checks)
    if (law.conditions) {
      if (law.conditions.needCompleted !== 0n) {
        items.push({ 
          key: 'needCompleted', 
          label: `Law ${law.conditions.needCompleted} Completed`, 
          status: checks.lawCompleted,
          hasHandle: true,
          targetLaw: law.conditions.needCompleted,
          edgeType: 'needCompleted'
        })
      }
      
      if (law.conditions.needNotCompleted !== 0n) {
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
    
    // 4. Proposal passed
    items.push({ 
      key: 'proposalPassed', 
      label: 'Proposal Passed', 
      status: checks.proposalPassed,
      hasHandle: false
    })
    
    // 5. Delay passed
    if (checks.delayPassed !== undefined) {
      items.push({ 
        key: 'delay', 
        label: 'Delay Passed', 
        status: checks.delayPassed,
        hasHandle: false
      })
    }
    
    // 6. Read State From (dependency check)
    if (law.conditions && law.conditions.readStateFrom !== 0n) {
      items.push({ 
        key: 'readStateFrom', 
        label: `Read State From Law ${law.conditions.readStateFrom}`, 
        status: undefined, // This doesn't have a direct status check
        hasHandle: true,
        targetLaw: law.conditions.readStateFrom,
        edgeType: 'readStateFrom'
      })
    }
    
    // 7. Executed
    items.push({ 
      key: 'executed', 
      label: 'Executed', 
      status: checks.executed,
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
      className={`shadow-lg rounded-lg bg-white border-2 min-w-[320px] max-w-[450px] ${roleBorderClass}`}
    >
      {/* Target handle for incoming connections */}
      <Handle 
        type="target" 
        position={Position.Right} 
        id="law-target"
        style={{ 
          background: roleColor, 
          width: 10, 
          height: 10,
          top: 24, // Position at header height (roughly center of header section)
          transform: 'translateY(0)'
        }}
      />
      
      {/* Law Header - Database Table Style */}
      <div 
        className="px-4 py-3 border-b-2 border-gray-300 bg-slate-50"
        style={{ borderBottomColor: roleColor }}
      >
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <div className="font-bold text-sm mb-1" style={{ color: roleColor }}>
              📋 Law #{Number(law.index)}
            </div>
            
            {law.nameDescription && (
              <div className="text-xs text-gray-700 mb-1 font-medium">
                {law.nameDescription}
              </div>
            )}
            
            <div className="flex items-center space-x-4 text-xs text-gray-600">
              {law.conditions && (
                <>
                  <span>Role: {Number(law.conditions.allowedRole)}</span>
                  <span>Quorum: {Number(law.conditions.quorum)}%</span>
                </>
              )}
            </div>
          </div>
          
          {/* Status indicator and collapse button */}
          <div className="flex items-center space-x-2">
            {checkItems.length > 0 && (
              <div 
                className={`w-3 h-3 rounded-full border ${
                  allChecksPassing 
                    ? 'bg-green-500 border-green-600' 
                    : anyChecksFailing 
                    ? 'bg-red-500 border-red-600' 
                    : 'bg-yellow-500 border-yellow-600'
                }`}
                title={`${checkItems.filter(i => i.status === true).length}/${checkItems.filter(i => i.status !== undefined).length} checks passing`}
              />
            )}
            
            {checkItems.length > 0 && (
              <button
                onClick={onToggleCollapse}
                className="p-1 rounded hover:bg-gray-100 transition-colors"
                title={isCollapsed ? 'Expand checks' : 'Collapse checks'}
              >
                <svg 
                  className={`w-3 h-3 text-gray-600 transition-transform ${isCollapsed ? 'rotate-0' : 'rotate-90'}`}
                  fill="none" 
                  stroke="currentColor" 
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </button>
            )}
          </div>
        </div>
      </div>
      
      {/* Checks Section - Database Rows Style */}
      {!isCollapsed && checkItems.length > 0 && (
        <div className="relative">
          {checkItems.map((item, index) => (
            <div key={item.key} className="relative">
              <div className="px-4 py-2 flex items-center justify-between text-xs relative">
                <div className="flex items-center space-x-2 flex-1">
                  <div className="w-6 h-6 flex justify-center items-center relative">
                    {item.status !== undefined ? (
                      // Status-based checks with appropriate icons
                      item.key === 'executed' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <CheckIcon className="w-4 h-4 text-black" />
                        </div>
                      ) : item.key === 'proposalPassed' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <HandThumbUpIcon className="w-4 h-4 text-black" />
                        </div>
                      ) : item.key === 'delay' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <CalendarDaysIcon className="w-4 h-4 text-black" />
                        </div>
                      ) : item.key === 'throttle' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <QueueListIcon className="w-4 h-4 text-black" />
                        </div>
                      ) : item.key === 'needCompleted' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <DocumentCheckIcon className="w-4 h-4 text-black" />
                        </div>
                      ) : item.key === 'needNotCompleted' ? (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <XMarkIcon className="w-4 h-4 text-black" />
                        </div>
                      ) : (
                        <div className="w-6 h-6 rounded-full border border-black flex items-center justify-center bg-white relative z-10">
                          <ShieldCheckIcon className="w-4 h-4 text-black" />
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
                  <div className="flex-1 flex flex-col">
                    <div className="text-[10px] text-gray-400 mb-0.5">Dec 15, 2024 - 14:32</div>
                    <span className="text-gray-700 font-medium">{item.label}</span>
                  </div>
                </div>
                
                {/* Connection handle for dependency checks */}
                {item.hasHandle && (
                  <Handle
                    type="source"
                    position={Position.Left}
                    id={`${item.key}-handle`}
                    style={{ 
                      background: '#6B7280', // gray-500 for all dependency handles
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
                      background: '#374151', // gray-700 for target handle
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
      )}
      
      {/* Collapsed state info */}
      {isCollapsed && checkItems.length > 0 && (
        <div className="px-4 py-2 text-xs text-gray-500 bg-gray-50">
          <div className="flex justify-between items-center">
            <span>{checkItems.length} checks</span>
            <span>
              {checkItems.filter(i => i.status === true).length}/
              {checkItems.filter(i => i.status !== undefined).length} passing
            </span>
          </div>
        </div>
      )}
    </div>
  )
}

const nodeTypes = {
  lawSchema: LawSchemaNode,
}

interface PowersFlowProps {
  powers: Powers
  lawChecks?: Map<string, Checks>
}

// Helper function to create a hierarchical layout based on dependencies
function createHierarchicalLayout(laws: Law[]): Map<string, { x: number; y: number }> {
  const positions = new Map<string, { x: number; y: number }>()
  const visited = new Set<string>()
  const levels = new Map<number, string[]>()
  
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
        dependencies.get(lawId)?.add(targetId)
        dependents.get(targetId)?.add(lawId)
      }
      if (law.conditions.needNotCompleted !== 0n) {
        const targetId = String(law.conditions.needNotCompleted)
        dependencies.get(lawId)?.add(targetId)
        dependents.get(targetId)?.add(lawId)
      }
      if (law.conditions.readStateFrom !== 0n) {
        const targetId = String(law.conditions.readStateFrom)
        dependencies.get(lawId)?.add(targetId)
        dependents.get(targetId)?.add(lawId)
      }
    }
  })
  
  // Calculate dependency depth (how many dependencies a node has, directly or indirectly)
  const getDependencyDepth = (lawId: string, memo = new Map<string, number>(), visiting = new Set<string>()): number => {
    if (memo.has(lawId)) return memo.get(lawId)!
    if (visiting.has(lawId)) return 0 // Prevent infinite loops in cycles
    
    visiting.add(lawId)
    const deps = dependencies.get(lawId) || new Set()
    
    if (deps.size === 0) {
      memo.set(lawId, 0)
      visiting.delete(lawId)
      return 0
    }
    
    const maxDepDepth = Math.max(...Array.from(deps).map(depId => getDependencyDepth(depId, memo, visiting)))
    const depth = maxDepDepth + 1
    memo.set(lawId, depth)
    visiting.delete(lawId)
    return depth
  }
  
  // Assign laws to levels based on dependency depth
  // Level 0 = nodes with no dependencies (bottom row)
  // Higher levels = nodes with more dependencies (upper rows)
  const depthMemo = new Map<string, number>()
  laws.forEach(law => {
    const lawId = String(law.index)
    const depth = getDependencyDepth(lawId, depthMemo)
    if (!levels.has(depth)) {
      levels.set(depth, [])
    }
    levels.get(depth)!.push(lawId)
  })
  
  // Group nodes within each level by their dependency relationships
  const groupRelatedNodes = (lawIds: string[]): string[][] => {
    const groups: string[][] = []
    const processed = new Set<string>()
    
    for (const lawId of lawIds) {
      if (processed.has(lawId)) continue
      
      const group = new Set<string>([lawId])
      const toProcess = [lawId]
      
      // Find all nodes that are related through dependencies
      while (toProcess.length > 0) {
        const currentId = toProcess.pop()!
        processed.add(currentId)
        
        // Add nodes that this one depends on (if they're in the same level)
        const deps = dependencies.get(currentId) || new Set()
        for (const depId of deps) {
          if (lawIds.includes(depId) && !group.has(depId)) {
            group.add(depId)
            toProcess.push(depId)
          }
        }
        
        // Add nodes that depend on this one (if they're in the same level)
        const dependentNodes = dependents.get(currentId) || new Set()
        for (const depId of dependentNodes) {
          if (lawIds.includes(depId) && !group.has(depId)) {
            group.add(depId)
            toProcess.push(depId)
          }
        }
      }
      
      groups.push(Array.from(group))
    }
    
    return groups
  }
  
  // Position nodes with vertical arrangement
  const NODE_SPACING_X = 600 // Horizontal spacing between nodes
  const NODE_SPACING_Y = 150 // Vertical spacing between nodes
  const GROUP_SPACING_X = 200 // Additional spacing between different groups
  const LEVEL_SPACING_Y = 550 // Vertical spacing between levels
  const CATEGORY_SPACING_X = 800 // Spacing between different dependency categories
  const MAX_NODES_PER_ROW = 4 // Maximum nodes per row within a group
  
  const maxLevel = Math.max(...levels.keys())
  
  // Categorize nodes based on their dependency patterns
  const categorizeNodes = (lawIds: string[]) => {
    const categories = {
      onlyChildren: [] as string[], // Nodes that only have other nodes depending on them
      both: [] as string[], // Nodes that have both dependencies and dependents
      onlyParents: [] as string[], // Nodes that only depend on other nodes
      isolated: [] as string[] // Nodes with no dependencies at all
    }
    
    lawIds.forEach(lawId => {
      const hasDependencies = (dependencies.get(lawId)?.size || 0) > 0
      const hasDependents = (dependents.get(lawId)?.size || 0) > 0
      
      if (!hasDependencies && !hasDependents) {
        categories.isolated.push(lawId)
      } else if (!hasDependencies && hasDependents) {
        categories.onlyChildren.push(lawId)
      } else if (hasDependencies && hasDependents) {
        categories.both.push(lawId)
      } else if (hasDependencies && !hasDependents) {
        categories.onlyParents.push(lawId)
      }
    })
    
    return categories
  }
  
  Array.from(levels.entries()).forEach(([level, lawIds]) => {
    // Invert the Y position so level 0 (no dependencies) is at the bottom
    const baseY = (maxLevel - level) * LEVEL_SPACING_Y
    
    // Categorize nodes by their dependency patterns
    const categories = categorizeNodes(lawIds)
    
    let currentCategoryX = 0
    
    // Position each category from left to right: onlyChildren -> both -> onlyParents -> isolated
    const categoryOrder = [
      { name: 'onlyChildren', nodes: categories.onlyChildren },
      { name: 'both', nodes: categories.both },
      { name: 'onlyParents', nodes: categories.onlyParents },
      { name: 'isolated', nodes: categories.isolated }
    ]
    
    categoryOrder.forEach(category => {
      if (category.nodes.length === 0) return
      
      // Group related nodes within each category
      const groups = groupRelatedNodes(category.nodes)
      
      let currentGroupX = currentCategoryX
      
      groups.forEach(group => {
        group.forEach((lawId, index) => {
          const row = Math.floor(index / MAX_NODES_PER_ROW)
          const col = index % MAX_NODES_PER_ROW
          
          const x = currentGroupX + col * NODE_SPACING_X
          const y = baseY + row * NODE_SPACING_Y
          
          positions.set(lawId, { x, y })
        })
        
        // Move to next group position within the category
        const groupWidth = Math.min(group.length, MAX_NODES_PER_ROW) * NODE_SPACING_X
        currentGroupX += groupWidth + GROUP_SPACING_X
      })
      
      // Move to next category position
      const categoryWidth = currentGroupX - currentCategoryX
      currentCategoryX += Math.max(categoryWidth, NODE_SPACING_X) + CATEGORY_SPACING_X
    })
  })
  
  // If no dependencies exist, arrange in a simple grid at the bottom
  if (positions.size === 0) {
    laws.forEach((law, index) => {
      const lawId = String(law.index)
      const x = (index % 4) * NODE_SPACING_X
      const y = Math.floor(index / 4) * 150
      positions.set(lawId, { x, y })
    })
  }
  
  return positions
}

export const PowersFlow: React.FC<PowersFlowProps> = ({ powers, lawChecks }) => {
  const [collapsedLaws, setCollapsedLaws] = React.useState<Set<string>>(new Set())

  const toggleLawCollapse = useCallback((lawId: string) => {
    setCollapsedLaws(prev => {
      const newSet = new Set(prev)
      if (newSet.has(lawId)) {
        newSet.delete(lawId)
      } else {
        newSet.add(lawId)
      }
      return newSet
    })
  }, [])

  // Create nodes and edges from laws
  const { initialNodes, initialEdges } = useMemo(() => {
    if (!powers.activeLaws) return { initialNodes: [], initialEdges: [] }
    
    const nodes: Node[] = []
    const edges: Edge[] = []
    
    // Use hierarchical layout instead of simple grid
    const positions = createHierarchicalLayout(powers.activeLaws)
    
    powers.activeLaws.forEach((law, lawIndex) => {
      const roleColor = law.conditions 
        ? getRoleColor(law.conditions.allowedRole)
        : '#475569' // slate-600 as fallback
      
      const roleBorderClass = law.conditions 
        ? getRoleBorderClass(law.conditions.allowedRole)
        : 'border-slate-600'
      
      const lawId = String(law.index)
      const position = positions.get(lawId) || { x: 0, y: 0 }
      const isCollapsed = collapsedLaws.has(lawId)
      
      // Get checks for this law
      const checks = lawChecks?.get(lawId)
      
      // Create law schema node
      nodes.push({
        id: lawId,
        type: 'lawSchema',
        position,
        data: {
          law,
          checks,
          roleColor,
          isCollapsed,
          onToggleCollapse: () => toggleLawCollapse(lawId),
        },
      })
      
      // Create edges from dependency checks to target laws
      if (law.conditions) {
        const sourceId = lawId
        
        // Edge from needCompleted check to target law
        if (law.conditions.needCompleted !== 0n) {
          const targetId = String(law.conditions.needCompleted)
          edges.push({
            id: `${sourceId}-needCompleted-${targetId}`,
            source: sourceId,
            sourceHandle: 'needCompleted-handle',
            target: targetId,
            targetHandle: 'executed-target',
            type: 'smoothstep',
            label: 'Needs Completed',
            style: { stroke: '#6B7280', strokeWidth: 2 },
            labelStyle: { fontSize: '10px', fontWeight: 'bold', fill: '#6B7280' },
            labelBgStyle: { fill: 'white', fillOpacity: 0.8 },
            zIndex: 10,
          })
        }
        
        // Edge from needNotCompleted check to target law
        if (law.conditions.needNotCompleted !== 0n) {
          const targetId = String(law.conditions.needNotCompleted)
          edges.push({
            id: `${sourceId}-needNotCompleted-${targetId}`,
            source: sourceId,
            sourceHandle: 'needNotCompleted-handle',
            target: targetId,
            targetHandle: 'executed-target',
            type: 'smoothstep',
            label: 'Needs Not Completed',
            style: { stroke: '#6B7280', strokeWidth: 2, strokeDasharray: '6,3' },
            labelStyle: { fontSize: '10px', fontWeight: 'bold', fill: '#6B7280' },
            labelBgStyle: { fill: 'white', fillOpacity: 0.8 },
            zIndex: 10,
          })
        }
        
        // Edge from readStateFrom check to target law
        if (law.conditions.readStateFrom !== 0n) {
          const targetId = String(law.conditions.readStateFrom)
          edges.push({
            id: `${sourceId}-readStateFrom-${targetId}`,
            source: sourceId,
            sourceHandle: 'readStateFrom-handle',
            target: targetId,
            targetHandle: 'executed-target',
            type: 'smoothstep',
            label: 'Read State From',
            style: { stroke: '#6B7280', strokeWidth: 2, strokeDasharray: '3,3' },
            labelStyle: { fontSize: '10px', fontWeight: 'bold', fill: '#6B7280' },
            labelBgStyle: { fill: 'white', fillOpacity: 0.8 },
            zIndex: 10,
          })
        }
      }
    })
    
    return { initialNodes: nodes, initialEdges: edges }
  }, [powers.activeLaws, lawChecks, collapsedLaws, toggleLawCollapse])

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges)

  const onConnect = useCallback(
    (params: Connection) => setEdges((eds) => addEdge(params, eds)),
    [setEdges],
  )

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
    <div className="w-full h-full bg-gray-50 overflow-hidden">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        nodeTypes={nodeTypes}
        connectionMode={ConnectionMode.Loose}
        fitView
        fitViewOptions={{
          padding: 0.2, // Add 20% padding around the content
          maxZoom: 0.8, // Limit maximum zoom to prevent excessive zoom-in
          minZoom: 0.1, // Allow zooming out quite far
        }}
        defaultViewport={{ x: 0, y: 0, zoom: 0.6 }} // Start with a comfortable zoom level
        attributionPosition="bottom-left"
        nodesDraggable={true}
        nodesConnectable={false}
        elementsSelectable={true}
        maxZoom={1.2} // Also set global max zoom
        minZoom={0.1} // Global min zoom
      >
        <Controls />
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

export default PowersFlow 