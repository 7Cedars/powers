"use client";

import { useParams, usePathname } from 'next/navigation';
import type { PropsWithChildren } from "react";
import { useRouter } from 'next/navigation'
import { useEffect } from "react";
import Image from 'next/image'
import { Button } from "./Button";
import { 
  MagnifyingGlassIcon, 
  HomeIcon, 
  BookOpenIcon,
  IdentificationIcon,
  ChatBubbleBottomCenterIcon,
  BuildingLibraryIcon
} from '@heroicons/react/24/outline';
import { ConnectButton } from './ConnectButton';
import { usePowers } from '@/hooks/usePowers';

const layoutIconBox: string = 'flex flex-row md:gap-2 gap-0 align-middle items-center'
const layoutIcons: string = 'h-5 w-5'
const layoutText: string = 'lg:opacity-100 lg:text-sm text-[0px] lg:w-fit w-0 opacity-0'
const layoutButton: string = `w-full h-full flex flex-row justify-center items-center rounded-md border aria-selected:bg-slate-200 md:hover:border-slate-600 text-sm aria-selected:text-slate-700 text-slate-500 border-transparent`

const NavigationBar = () => {
  const router = useRouter();
  const { powers: addressPowers } = useParams<{ powers: string }>()  
  const path = usePathname()
  const { status: statusUpdate, fetchPowers } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])

  return (
    <div className="w-full h-full flex flex-row gap-1 justify-center items-center px-2 py-1 md:py-0 overflow-hidden"> 
            <button 
              onClick={() => router.push(`/${addressPowers}`)}
              aria-selected={path == `/${addressPowers}`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <HomeIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Home </p>
                </div> 
            </button>

            <button 
              onClick={() => router.push(`/${addressPowers}/laws`)}
              aria-selected={path == `/${addressPowers}/laws`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <BookOpenIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Laws </p>      
                </div> 
            </button>

            <button 
              onClick={() => router.push(`/${addressPowers}/proposals`)}
              aria-selected={path == `/${addressPowers}/proposals`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <ChatBubbleBottomCenterIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Proposals </p>      
                </div> 
            </button>

            <button 
              onClick={() => router.push(`/${addressPowers}/roles`)}
              aria-selected={path == `/${addressPowers}/roles`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <IdentificationIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Roles </p>
                </div> 
            </button>

            <button 
              onClick={() => router.push(`/${addressPowers}/treasury`)}
              aria-selected={path == `/${addressPowers}/treasury`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <BuildingLibraryIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Treasury </p>
                </div> 
            </button>
          </div>
  )
}

const Header = () => {
  const router = useRouter();

  const { powers: addressPowers } = useParams<{ powers: string }>()  
  const path = usePathname()
  const { status: statusUpdate, fetchPowers, powers } = usePowers()

  useEffect(() => {
    if (addressPowers) {
      fetchPowers(addressPowers as `0x${string}`)
    }
  }, [addressPowers, fetchPowers])
 
  return (
    <div className="absolute top-0 z-20 h-14 w-screen py-2 flex justify-around text-sm bg-slate-50 border-b border-slate-300 overflow-hidden">
    <section className="grow flex flex-row gap-1 justify-between px-2 max-w-screen-xl">
      <div className="flex flex-row gap-1 min-w-16"> 
        <a href="/"  
            className="flex flex-row min-w-12 p-1 justify-center items-center border border-slate-300 bg-slate-50 rounded-md"
            >  
          <Image 
            src='/logo.png' 
            width={28}
            height={28}
            alt="Logo Separated Powers"
            >
          </Image>
        </a> 
        <div className="">
      
        </div>
      </div>
      {
        <div className="flex flex-row grow gap-2 md:max-w-2xl opacity-0 md:opacity-100 max-w-0">
          {addressPowers != '' ? NavigationBar() : null }
        </div>
      }
        {path == `/` ? null : <ConnectButton /> }
    </section>
  </div>
  )
}

const Footer = () => {  
  return (
     <div className="absolute bottom-0 z-20 bg-slate-50 flex justify-between border-t border-slate-300 h-14 items-center md:collapse w-full text-sm px-4 overflow-hidden">
        {NavigationBar()}  
    </div>
  )
}

export const NavBars = (props: PropsWithChildren<{}>) => {
  // need to include error handling for when the powers are not found - todo 
  const path = usePathname()

  return (
    <>
      {
      path == '/' ? 
      <div className="w-full h-full grid grid-cols-1 overflow-y-scroll">
        <main className="w-full h-full grid grid-cols-1 overflow-y-scroll">
          {props.children}
        </main>
        {/* <Footer /> */}
      </div>
      : 
      <div className="w-full h-full flex flex-col justify-start items-center">
        <Header /> 
        <main className="w-full h-full flex flex-col justify-start items-center max-w-6xl overflow-x-scroll">
          {props.children}   
        </main>
        <Footer /> 
      </div>
      }
    </>
  )
}

