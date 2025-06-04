# Powers Protocol Flow Visualization

This document describes the new dynamic visualization feature for Powers protocol deployments using React Flow.

## Overview

The Powers Flow visualization provides a dynamic, interactive graph showing:
- **Law Groups**: Self-contained components representing each law with embedded checks
- **Collapsible Checks**: Individual checks displayed within law components with expand/collapse functionality
- **Dependencies as edges**: Connections between law groups based on their relationships
- **Status Indicators**: Visual status indicators for both individual checks and overall law status

## Components

### 1. PowersFlow Component (`/components/PowersFlow.tsx`)

The main React Flow component that renders the visualization using grouped law components.

**Features:**
- Self-contained law group nodes with embedded checks
- Collapsible check sections for better space management
- Color-coded law groups based on role IDs
- Interactive node positioning (drag and drop)
- Zoom and pan controls
- Dependency edges with different styles
- Real-time status indicators

**Props:**
- `powers`: Powers protocol data
- `lawChecks`: Map of law checks (optional)

### 2. PowersOverview Component (`/components/PowersOverview.tsx`)

A comprehensive wrapper that includes:
- Protocol statistics
- Updated legend explaining the grouped approach
- Error handling and loading states
- Law details panel
- Refresh functionality

### 3. usePowersFlow Hook (`/hooks/usePowersFlow.ts`)

Custom hook for managing law checks data:
- Fetches check status for all active laws
- Calculates basic checks based on law conditions
- Provides loading states and error handling

## Node Types

### Law Group Nodes
- **Self-contained components** representing individual laws
- Color-coded by role ID using a 15-color palette
- **Header section** with law number, name/description, and role information
- **Embedded checks section** showing individual check statuses
- **Collapse/expand functionality** for better space management
- **Overall status indicator** (green = all passing, red = some failing, yellow = mixed)
- Positioned in a grid layout (3 columns)

## Law Checks Visualization

Each law group contains its own embedded checks with collapsible display:

### Included Checks
- **Delay Passed**: Whether the execution delay requirement is met
- **Throttle Passed**: Whether the throttle execution requirement is met  
- **Action Not Completed**: Whether the action hasn't been completed yet
- **Law Completed**: Whether prerequisite laws have been completed
- **Law Not Completed**: Whether blocking laws haven't been completed

### Excluded Checks
- **Authorised**: User authorization check (excluded as requested)
- **Proposal Exists**: Proposal existence check (excluded as requested)

### Visual Indicators

#### Individual Check Status (within expanded law groups)
- 🟢 **Green dot (small)**: Check is passing
- 🔴 **Red dot (small)**: Check is failing
- ⚪ **Gray dot (small)**: Check status unknown

#### Overall Law Status (in law header)
- 🟢 **Green indicator**: All checks are passing
- 🔴 **Red indicator**: Some checks are failing
- 🟡 **Yellow indicator**: Mixed status or unknown checks

#### Expand/Collapse Control
- 🔽 **Down arrow**: Checks are expanded (clickable to collapse)
- 🔼 **Right arrow**: Checks are collapsed (clickable to expand)

## Dependencies (Edges)

The visualization shows law dependencies between law group nodes:

### Needs Completed (Green solid line)
- **Condition**: `needCompleted !== 0n`
- **Meaning**: Target law must be completed before source law can execute
- **Visual**: Thick solid green line

### Needs Not Completed (Red dashed line)
- **Condition**: `needNotCompleted !== 0n`
- **Meaning**: Target law must NOT be completed for source law to execute
- **Visual**: Thick dashed red line

### Read State From (Blue dotted line)
- **Condition**: `readStateFrom !== 0n`
- **Meaning**: Source law reads state from target law
- **Visual**: Thick dotted blue line

## Layout and Positioning

### Automatic Layout
- **Law groups**: Arranged in a 3-column grid with 350px horizontal spacing
- **Compact design**: Reduced spacing due to embedded checks (250px vertical spacing)
- **Self-contained**: Each law group manages its own check display

### Interactive Features
- **Drag law groups**: Rearrange the layout by dragging entire law components
- **Expand/Collapse**: Click the arrow button to show/hide checks within each law
- **Zoom/Pan**: Use mouse wheel to zoom, drag background to pan
- **Selection**: Click law groups to select them
- **Controls**: Built-in React Flow controls for navigation

## Usage

### Accessing the Visualization

1. **Via Navigation**: Navigate to `/{chainId}/{powersAddress}/flow`
2. **Via Overview**: Click the map icon (🗺️) in the Powers overview page

### Example Implementation

```tsx
import { PowersOverview } from '@/components/PowersOverview'
import { usePowersFlow } from '@/hooks/usePowersFlow'

function MyPage() {
  const { powers, wallets } = useSomeHook()
  
  return (
    <PowersOverview 
      powers={powers} 
      wallets={wallets} 
    />
  )
}
```

### Direct React Flow Usage

```tsx
import { PowersFlow } from '@/components/PowersFlow'

function MyComponent() {
  const { lawChecks } = usePowersFlow({ powers, wallets })
  
  return (
    <PowersFlow 
      powers={powers} 
      lawChecks={lawChecks} 
    />
  )
}
```

## Features

### Grouped Organization
- **Self-contained law components**: Each law manages its own checks internally
- **Space-efficient**: Collapsible sections reduce visual clutter
- **Clear hierarchy**: Law information and checks are properly organized within each component

### Interactive Elements
- **Drag law groups**: Rearrange entire law components independently
- **Expand/Collapse checks**: Toggle check visibility within each law
- **Zoom/Pan**: Navigate large protocol deployments easily
- **Selection**: Select individual law groups for focus

### Enhanced User Experience
- **Better organization**: Checks are logically grouped with their parent laws
- **Reduced complexity**: Fewer visual elements on screen at once
- **Cleaner layout**: More organized and less cluttered than separate nodes
- **Contextual information**: Status indicators provide quick overview

### Responsive Design
- **Adaptive sizing**: Law groups adjust size based on content and collapse state
- **Scalable visualization**: Handles many laws efficiently with grouping
- **Mobile-friendly**: Touch controls work on mobile devices
- **Flexible layout**: Compact design works well on different screen sizes

### Real-time Updates
- **Refresh functionality**: Update all check statuses at once
- **Automatic updates**: Visualization updates when Powers data changes
- **Error handling**: Graceful handling of missing or invalid data
- **State persistence**: Collapse states are maintained during updates

## Technical Details

### Law Group Component Architecture
1. **Single node type**: `lawGroup` replaces multiple separate node types
2. **Embedded check rendering**: Checks are rendered as internal elements, not separate nodes
3. **State management**: Each law group manages its own collapse state
4. **Event handling**: Toggle collapse functionality with proper state updates

### Performance Optimizations
- **Reduced node count**: Fewer React Flow nodes improve performance
- **Memoized calculations**: Check rendering and status calculations are memoized
- **Efficient rendering**: React Flow handles fewer, more complex nodes better
- **Selective updates**: Only affected law groups update when data changes

### Dependencies
- `reactflow`: Core visualization library v11.11.4
- Existing Powers protocol hooks and types
- Tailwind CSS for styling

## Advantages of Grouped Approach

### Improved Organization
- **Logical grouping**: Checks are naturally grouped with their parent laws
- **Reduced visual noise**: Fewer lines and connections on screen
- **Better space utilization**: More compact layout with expandable details

### Enhanced Usability
- **Contextual information**: All law-related information is in one place
- **Progressive disclosure**: Users can expand details as needed
- **Simplified navigation**: Fewer elements to manage and navigate

### Better Performance
- **Fewer nodes**: React Flow handles fewer, more complex nodes more efficiently
- **Reduced complexity**: Simpler node structure with better rendering performance
- **Less edge computation**: No need for law-to-check grouping edges

## Future Enhancements

Potential improvements for future versions:
- **Custom layouts**: Hierarchical, circular, or force-directed layouts for law groups
- **Filtering**: Show/hide specific types of checks or laws
- **Export functionality**: Save visualizations as PNG/SVG
- **Real-time status**: Live blockchain check validation
- **Animation**: Animated transitions when status changes
- **Detailed tooltips**: Hover information for laws and checks
- **Minimap**: Overview minimap for large protocol deployments
- **Bulk operations**: Expand/collapse all law groups at once 