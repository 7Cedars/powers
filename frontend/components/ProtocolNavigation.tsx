"use client";

import { useParams, usePathname } from 'next/navigation';
import { useRouter } from 'next/navigation'
import { useState } from "react";
import Image from 'next/image'
import { 
  HomeIcon, 
  BoltIcon,
  UserGroupIcon,
  ScaleIcon,
  BuildingLibraryIcon
} from '@heroicons/react/24/outline';
import { ConnectButton } from './ConnectButton'
import { BlockCounter } from './BlockCounter';
import { OnboardingModal } from './OnboardingModal';

// Navigation styling constants
const layoutIconBox = 'flex flex-row md:gap-1 gap-0 md:px-4 md:py-1 py-0 px-0 align-middle items-center'
const layoutIcons = 'h-6 w-6'
const layoutText = 'lg:opacity-100 lg:text-sm text-[0px] lg:w-fit w-0 opacity-0'
const layoutButton = `w-full h-full flex flex-row justify-center items-center rounded-md border aria-selected:bg-slate-200 md:hover:border-slate-600 text-sm aria-selected:text-slate-700 text-slate-500 border-transparent`

// Navigation item interface
interface NavigationItem {
  id: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  path: string; 
  hidden?: boolean;
  hideLabel?: boolean;
  helpNavItem?: string;
}

// Default navigation configuration for protocol pages
const protocolNavigationConfig: NavigationItem[] = [
  {
    id: 'home',
    label: 'Home',
    icon: HomeIcon,
    path: '',
    helpNavItem: 'home'
  },
  {
    id: 'actions',
    label: 'Actions',
    icon: BoltIcon,
    path: '/actions',
    helpNavItem: 'actions'
  },
  {
    id: 'roles',
    label: 'Roles',
    icon: UserGroupIcon,
    path: '/roles',
    helpNavItem: 'roles'
  },
  {
    id: 'laws',
    label: 'Laws',
    icon: ScaleIcon,
    path: '/laws',
    helpNavItem: 'laws'
  },
  {
    id: 'treasury',
    label: 'Treasury',
    icon: BuildingLibraryIcon,
    path: '/treasury',
    helpNavItem: 'treasury'
  }
  // {
  //   id: 'help',
  //   label: 'Help',
  //   icon: QuestionMarkCircleIcon,
  //   path: '#',
  //   hidden: true, // Hidden by default on mobile
  //   hideLabel: true, // Only show icon, no text
  //   helpNavItem: undefined
  // }
];

const NavigationBar = () => {
  const router = useRouter();
  const chainId = useParams().chainId;
  const powers = useParams().powers;
  const legacyPath = usePathname();
  const [isOnboardingOpen, setIsOnboardingOpen] = useState(false);

  const handleNavigation = (item: NavigationItem) => {
    if (item.id === 'help') {
      setIsOnboardingOpen(true);
      return;
    }
    
    const fullPath = `/protocol/${chainId}/${powers}${item.path}`;
    router.push(fullPath);
  };

  const isSelected = (item: NavigationItem) => {
    const fullPath = `/protocol/${chainId}/${powers}${item.path}`;
    return legacyPath === fullPath;
  };

  return (
    <>
      <div className="w-full h-full flex flex-row gap-2 justify-center items-center px-2 overflow-hidden navigation-bar" help-nav-item="navigation-pages"> 
        {protocolNavigationConfig.map((item) => (
          <button 
            key={item.id}
            onClick={() => handleNavigation(item)}
            aria-selected={isSelected(item)} 
            className={`${layoutButton} ${item.hidden ? 'hidden md:flex' : ''}`}
            help-nav-item={item.helpNavItem}
          >
            <div className={layoutIconBox}> 
              <item.icon className={layoutIcons} />
              {!item.hideLabel && <p className={layoutText}> {item.label} </p>}
            </div> 
          </button>
        ))}
      </div>
      
      <OnboardingModal 
        isOpen={isOnboardingOpen}
        onClose={() => setIsOnboardingOpen(false)}
        onRequestOpen={() => setIsOnboardingOpen(true)}
      />
    </>
  )
} 

const Header = () => {
  const path = usePathname()
  
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
        {path == `/` ? null : <BlockCounter /> }
      </div>
      
      <div className="flex flex-row gap-2 items-center">
        <div className="w-fit min-w-44 md:min-w-2xl flex flex-row opacity-0 md:opacity-100">
          <NavigationBar />
        </div>
        
        {path == `/` ? null : <ConnectButton /> }
      </div>
    </section>
  </div>
  )
}

const Footer = () => {  
  return (
     <div className="absolute bottom-0 left-0 z-20 pt-1 bg-slate-100 flex justify-between border-t border-slate-300 h-12 items-center md:collapse w-full text-sm overflow-hidden">
        <NavigationBar />  
    </div>
  )
}

export const ProtocolNavigation = ({ children }: { children: React.ReactNode }) => {
  const path = usePathname()

  return (
    <>
      {
      path == '/' ? 
      <div className="w-full h-full grid grid-cols-1 overflow-y-scroll" id="navigation-bar">
        <main className="w-full h-full grid grid-cols-1 overflow-y-scroll">
          {children}
        </main>
      </div>
      : 
      <div className="w-full h-full flex flex-col justify-start items-center">
        <Header /> 
        <main className="w-full h-full flex flex-col justify-start items-center">
          {children}   
        </main>
        <Footer /> 
      </div>
      }
    </>
  )
}

