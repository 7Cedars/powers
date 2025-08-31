'use client'

import React, { useState } from 'react'

export default function PortalPage() {
  const [activeTab, setActiveTab] = useState('New')
  const tabs = ['New', 'Incoming', 'Fulfilled']

  return (
    <div className="w-full h-full flex flex-col">
      {/* Large Banner */}
      <div className="w-full flex justify-center relative px-4 pt-20">
        <div className="max-w-6xl w-full relative">
          <img 
            src="/orgMetadatas/PowersDAO_Banner.png" 
            alt="Powers DAO Banner" 
            className="w-full h-auto object-cover rounded-lg"
          />
          
          {/* Horizontal Slider below banner */}
          <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 w-2/3 bg-slate-100/90 backdrop-blur-sm border border-slate-200 rounded-lg">
            <div className="px-8 py-2">
              <div className="relative rounded-lg p-1">
                {/* Sliding background indicator */}
                <div 
                  className="absolute top-1 bottom-1 bg-white rounded-md shadow-sm transition-all duration-300 ease-in-out"
                  style={{
                    width: `${100 / tabs.length}%`,
                    left: `${(tabs.indexOf(activeTab) * 100) / tabs.length}%`
                  }}
                />
                
                {/* Tab buttons */}
                <div className="relative flex">
                  {tabs.map((tab) => (
                    <button
                      key={tab}
                      onClick={() => setActiveTab(tab)}
                      className={`flex-1 px-4 py-2 text-center font-medium transition-colors duration-200 rounded-md relative z-10 ${
                        activeTab === tab 
                          ? 'text-slate-900' 
                          : 'text-slate-600 hover:text-slate-800'
                      }`}
                    >
                      {tab}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      {/* Rest of content */}
      <div className="w-full flex-1 flex flex-col justify-center items-center">
        <div className="text-2xl font-semibold text-slate-700">
          Welcome to the Portal
        </div>
        <div className="text-lg text-slate-500 mt-4">
          Select a tab above to get started
        </div>
      </div>
    </div>
  )
}
