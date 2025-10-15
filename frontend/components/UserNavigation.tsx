'use client'

import React from 'react'
import { useRouter, usePathname } from 'next/navigation'
import Image from 'next/image'
import { 
  HomeIcon 
} from '@heroicons/react/24/outline'
import { ConnectButton } from './ConnectButton'
import { BlockCounter } from './BlockCounter'

const layoutIconBox: string = 'flex flex-row md:gap-1 gap-0 md:px-4 md:py-1 py-0 px-0 align-middle items-center'
const layoutIcons: string = 'h-6 w-6'
const layoutText: string = 'lg:opacity-100 lg:text-sm text-[0px] lg:w-fit w-0 opacity-0'
const layoutButton: string = `w-full h-full flex flex-row justify-center items-center rounded-md border aria-selected:bg-slate-200 md:hover:border-slate-600 text-sm aria-selected:text-slate-700 text-slate-500 border-transparent`

// User navigation configuration
const userNavigationConfig = [
  {
    id: 'home',
    label: 'Home',
    icon: HomeIcon,
    path: '/user',
  },
  // {
  //   id: 'settings',
  //   label: 'Settings',
  //   icon: BookOpenIcon,
  //   path: '/user/settings',
  // }
]

const UserNavigationBar = () => {
  const router = useRouter()
  const path = usePathname()

  const isSelected = (item: typeof userNavigationConfig[0]): boolean => {
    if (item.id === 'home') {
      return path === '/user' || path === '/user/'
    }
    return path === item.path
  }

  return (
    <>
      <div className="w-full h-full flex flex-row gap-2 justify-center items-center px-2 overflow-hidden navigation-bar" help-nav-item="navigation-pages"> 
        {userNavigationConfig.map((item) => (
          <button 
            key={item.id}
            onClick={() => router.push(item.path)}
            aria-selected={isSelected(item)} 
            className={layoutButton}
            help-nav-item={item.id}
          >
            <div className={layoutIconBox}> 
              <item.icon className={layoutIcons} />
              <p className={layoutText}> {item.label} </p>
            </div> 
          </button>
        ))}
      </div>
    
    </>
  )
}

const UserHeader = () => {

  return (
    <div className="absolute top-0 left-0 z-30 h-14 w-screen py-2 flex justify-around text-sm bg-slate-50 border-b border-slate-300 overflow-hidden" help-nav-item="navigation">
      <section className="grow flex flex-row gap-1 justify-between pe-2">
        <div className="flex flex-row gap-2 items-center"> 
          <a href="/"  
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
          <BlockCounter />
        </div>
        
        <div className="flex flex-row gap-2 items-center">
          <div className="w-fit min-w-44 md:min-w-2xl flex flex-row opacity-0 md:opacity-100">
            <UserNavigationBar />
          </div>
          
          <ConnectButton />
        </div>
      </section>
    </div>
  )
}

const UserFooter = () => {  
  return (
     <div className="absolute bottom-0 z-20 pt-1 bg-slate-100 flex justify-between border-t border-slate-300 h-12 items-center md:collapse w-full text-sm overflow-hidden">
        <UserNavigationBar />
    </div>
  )
}

interface UserNavigationProps {
  children: React.ReactNode
}

export const UserNavigation = ({ children }: UserNavigationProps) => {
  return (
    <div className="w-full h-full flex flex-col justify-center items-center">
      <UserHeader /> 
      <main className="w-screen h-full flex flex-col justify-center items-center">
        {children}   
      </main>
      <UserFooter /> 
    </div>
  )
}
