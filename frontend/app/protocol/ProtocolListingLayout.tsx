'use client'

import React from 'react'
import Image from 'next/image'
import { ConnectButton } from '../../components/ConnectButton'
import { Footer } from '@/app/Footer'

const ProtocolHeader = () => {
  return (
    <div className="absolute top-0 left-0 z-30 h-14 w-screen py-2 flex justify-around text-sm bg-slate-50 border-b border-slate-300 overflow-hidden">
      <section className="grow flex flex-row gap-1 justify-between pe-2">
        <div className="flex flex-row gap-2 items-center"> 
          <a href="/protocol"  
              className="flex flex-row justify-center items-center rounded-md p-1 px-2"
              >  
            <Image 
              src='/logo1_notext.png' 
              width={40}
              height={40}
              alt="Logo Powers Protocol"
              >
            </Image>
          </a> 
        </div>
        
        <div className="flex flex-row gap-2 items-center">
          <ConnectButton />
        </div>
      </section>
    </div>
  )
}

export const ProtocolListingLayout = ({ children }: { children: React.ReactNode }) => {
  return (
    <div className="w-full h-full flex flex-col justify-start items-center">
      <ProtocolHeader /> 
      <main className="w-screen flex-1 flex flex-col justify-start items-center overflow-y-auto">
        {children}
        <Footer />   
      </main>
    </div>
  )
}
