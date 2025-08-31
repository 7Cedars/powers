'use client'

import React from 'react'

export default function ProfilePage() {
  return (
    <div className="w-full h-full flex flex-col justify-center items-center p-8">
      <div className="max-w-4xl w-full bg-white rounded-lg shadow-lg p-8">
        <h1 className="text-3xl font-bold text-slate-800 mb-6 text-center">
          Profile
        </h1>
        <p className="text-lg text-slate-600 text-center mb-8">
          This is your profile page in the portal.
        </p>
        <div className="bg-slate-50 rounded-lg p-6 border border-slate-200">
          <h2 className="text-xl font-semibold text-slate-700 mb-3">Profile Information</h2>
          <p className="text-slate-600">
            Your profile details and settings will be displayed here.
          </p>
        </div>
      </div>
    </div>
  )
}
