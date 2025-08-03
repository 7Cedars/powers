"use client";

import { useParams, usePathname } from 'next/navigation';
import type { PropsWithChildren } from "react";
import { useRouter } from 'next/navigation'
import { useEffect } from "react";
import Image from 'next/image'
import { 
  HomeIcon, 
  BookOpenIcon,
  IdentificationIcon,
  ChatBubbleBottomCenterIcon,
  BuildingLibraryIcon,
  NewspaperIcon
} from '@heroicons/react/24/outline';
import { ConnectButton } from './ConnectButton';
import { BlockCounter } from './BlockCounter';
import { usePowers } from '@/hooks/usePowers';
import { useAccount, useSwitchChain } from 'wagmi'

const layoutIconBox: string = 'flex flex-row md:gap-1 gap-0 md:px-4 md:py-1 py-0 px-0 align-middle items-center'
const layoutIcons: string = 'h-6 w-6'
const layoutText: string = 'lg:opacity-100 lg:text-sm text-[0px] lg:w-fit w-0 opacity-0'
const layoutButton: string = `w-full h-full flex flex-row justify-center items-center rounded-md border aria-selected:bg-slate-200 md:hover:border-slate-600 text-sm aria-selected:text-slate-700 text-slate-500 border-transparent`

const NavigationBar = () => {
  const router = useRouter();
  const { chain } = useAccount()
  const { powers: addressPowers, chainId } = useParams<{ powers: string, chainId: string }>()  
  const path = usePathname()
  const { status: statusUpdate, fetchPowers } = usePowers()  
  const { switchChain } = useSwitchChain()

  useEffect(() => {
    // console.log("@navigationBar, useEffect chain: waypoint 1", {chainId, chain})
    if (chain?.id != Number(chainId) || chain == undefined) {
      switchChain({ chainId: Number(chainId) })
    }
  }, [chainId, switchChain, chain])

  useEffect(() => {
      if (addressPowers) {
        fetchPowers(addressPowers as `0x${string}`)
      }
    }, [addressPowers, fetchPowers]) // updateProposals 

  return (
    <div className="w-full h-full flex flex-row gap-2 justify-center items-center px-2 overflow-hidden"> 
            <button 
              onClick={() => router.push(`/${chainId}/${addressPowers}`)}
              aria-selected={path == `/${chainId}/${addressPowers}`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <HomeIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Home </p>
                </div> 
            </button>

            {/* <button 
              onClick={() => router.push(`/${chainId}/${addressPowers}/laws`)}
              aria-selected={path == `/${chainId}/${addressPowers}/laws`} 
              className={`${layoutButton} hidden md:flex`}
              >
                <div className={layoutIconBox}> 
                  <BookOpenIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Laws </p>      
                </div> 
            </button> */}

            <button 
              onClick={() => router.push(`/${chainId}/${addressPowers}/proposals`)}
              aria-selected={path == `/${chainId}/${addressPowers}/proposals`} 
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
              onClick={() => router.push(`/${chainId}/${addressPowers}/logs`)}
              aria-selected={path == `/${chainId}/${addressPowers}/logs`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <NewspaperIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Logs </p>
                </div> 
            </button>

            {/* <button 
              onClick={() => router.push(`/${chainId}/${addressPowers}/roles`)}
              aria-selected={path == `/${chainId}/${addressPowers}/roles`} 
              className={layoutButton}
              >
                <div className={layoutIconBox}> 
                  <IdentificationIcon
                  className={layoutIcons} 
                  />
                  <p className={layoutText}> Roles </p>
                </div> 
            </button> */}

            <button 
              onClick={() => router.push(`/${chainId}/${addressPowers}/treasury`)}
              aria-selected={path == `/${chainId}/${addressPowers}/treasury`} 
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
  const { powers: addressPowers } = useParams<{ powers: string }>()  
  const path = usePathname()

  return (
    <div className="absolute top-0 z-30 h-14 w-screen py-2 flex justify-around text-sm bg-slate-50 border-b border-slate-300 overflow-hidden">
    <section className="grow flex flex-row gap-1 justify-between pe-2">
      <div className="flex flex-row gap-2 items-center"> 
        <a href="/"  
            className="flex flex-row justify-center items-center rounded-md p-1 px-2"
            >  
          {/* <PowerIcon className="h-6 w-6 text-slate-70 font-extrabold" /> */}
          <Image 
            src='/logo1_notext.png' 
            width={40}
            height={40}
            alt="Logo Powers Protocol"
            >
          </Image>
        </a> 
        {path == `/` ? null : <BlockCounter /> }
      </div>
      
      <div className="flex flex-row gap-2 items-center">
        <div className="w-fit min-w-44 md:min-w-2xl flex flex-row opacity-0 md:opacity-100">
          {addressPowers != '' ? NavigationBar() : null }
        </div>
        
        {path == `/` ? null : <ConnectButton /> }
      </div>
    </section>
  </div>
  )
}

const Footer = () => {  
  return (
     <div className="absolute bottom-0 z-20 pt-1 bg-slate-100 flex justify-between border-t border-slate-300 h-12 items-center md:collapse w-full text-sm overflow-hidden">
        {NavigationBar()}  
    </div>
  )
}

export const NavBars = (props: PropsWithChildren<{}>) => {
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
        <main className="w-full h-full flex flex-col justify-start items-center">
          {props.children}   
        </main>
        <Footer /> 
      </div>
      }
    </>
  )
}

