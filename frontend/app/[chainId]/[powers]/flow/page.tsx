'use client'

import React from 'react'
import { Button } from '@/components/Button'

export default function FlowPage() {
  return (
    <div className="p-6">
      <div className="space-y-4">
        <div className="bg-gray-50 rounded-lg p-4">
          <h3 className="text-sm font-medium text-gray-700 mb-2">Overview</h3>
          <p className="text-sm text-gray-600">
            Select a law node to view detailed information about its checks, dependencies, and execution status.
          </p>
        </div>
        
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h3 className="text-sm font-medium text-blue-800 mb-2">Flow Diagram</h3>
          <p className="text-sm text-blue-700 mb-3">
            Click on any law node in the diagram to explore its details, simulate actions, or execute proposals.
          </p>
          <p className="text-xs text-blue-600">
            The diagram shows dependency relationships between laws and their current execution status.
          </p>
        </div>
        
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <h3 className="text-sm font-medium text-green-800 mb-2">Navigation</h3>
          <p className="text-sm text-green-700">
            Use the controls at the bottom right to zoom and pan around the diagram. The minimap shows your current viewport position.
          </p>
        </div>
      </div>
    </div>
  )
} 