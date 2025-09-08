'use client'

import React from 'react'
import { Powers } from '@/context/types'

export default function Incoming({hasRoles, powers}: {hasRoles: {role: bigint, since: bigint}[], powers: Powers}) {
  return (
    <div className="w-full mx-auto">
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm">
        <div className="p-4 border-b border-slate-100">
          <h2 className="text-lg font-semibold text-slate-800">Incoming</h2>
          <p className="text-sm text-slate-600">Pending actions and proposals</p>
        </div>
        
        <div className="p-4">
          <p className="text-sm text-slate-500 italic">
            {hasRoles.map(role => role.role).join(', ')}
          </p>
          <ul className="space-y-3">
            {/* List items will be populated here */}
            <li className="text-sm text-slate-500 italic">
              No incoming items yet
            </li>
          </ul>
        </div>
      </div>
    </div>
  )
}
