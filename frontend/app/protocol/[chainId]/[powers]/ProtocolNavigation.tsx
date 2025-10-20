"use client";

import { useParams, usePathname } from 'next/navigation';
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { 
  HomeIcon, 
  BoltIcon,
  UserGroupIcon,
  ScaleIcon,
  BuildingLibraryIcon,
  ChevronRightIcon,
  ArrowPathIcon
} from '@heroicons/react/24/outline';
import { ConnectButton } from '../../../../components/ConnectButton'
import { BlockCounter } from '../../../../components/BlockCounter';
import { PowersFlow } from '../../../../components/PowersFlow';
import { usePowers } from '@/hooks/usePowers';
import { useEffect, useState } from 'react';
import { useStatusStore, usePowersStore, useErrorStore, setStatus, setError, setAction, useActionStore } from '@/context/store';
import { usePublicClient } from 'wagmi';

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
];

const NavigationBar = () => {
  const router = useRouter();
  const path = usePathname(); 
  const { chainId, powers: powersAddress } = useParams<{ chainId: string, powers: string }>()


  const isSelected = (item: NavigationItem): boolean => {
    if (item.id === 'home') {
      return path === `/protocol/${chainId}/${powersAddress}` || path === `/protocol/${chainId}/${powersAddress}/`
    }
    return path.includes(item.path)
  };


  return (
    <>
      <div className="w-full h-full flex flex-row gap-2 justify-center items-center px-2 overflow-hidden navigation-bar" help-nav-item="navigation-pages"> 
        {protocolNavigationConfig.map((item) => (
          <button 
            key={item.id}
            onClick={() => router.push(`/protocol/${chainId}/${powersAddress}${item.path}`)}
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
    </>
  )
} 
  
const Header = () => {
  const { powers: powersAddress } = useParams<{ powers: string }>()
  const statusPowers = useStatusStore();
  const errorPowers = useErrorStore();
  const action = useActionStore();
  const powers = usePowersStore();
  const { fetchPowers } = usePowers(); 
  const publicClient = usePublicClient();
  const [blockNumber, setBlockNumber] = useState<bigint | null>(null);

  const fetchBlockNumber = async () => {
    if (!publicClient) return;
    
    try {
      const number = await publicClient.getBlockNumber();
      setBlockNumber(number);
    } catch (error) {
      console.error('Failed to fetch block number:', error);
      return null;
    }
  };

  console.log("@HEADER:", {powersAddress, status: statusPowers.status, error: errorPowers.error, action: action, powers: powers})

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
        <BlockCounter onRefresh={() => {
          fetchPowers(powersAddress as `0x${string}`);
          fetchBlockNumber();
        }} blockNumber={blockNumber} />
        {/* <button
          onClick={() => fetchPowers(powersAddress as `0x${string}`)}
          disabled={statusPowers.status == "pending"}
          className="flex items-center justify-center rounded-md p-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed border border-slate-400 hover:border-slate-600"
          title="Refresh Powers Data"
        >
          <ArrowPathIcon 
            className={`w-5 h-5 text-slate-600 ${statusPowers.status == "pending" ? 'animate-spin' : ''}`}
          />
        </button> */}
      </div>
      
      <div className="flex flex-row gap-2 items-center">
        <div className="w-fit min-w-44 md:min-w-2xl flex flex-row opacity-0 md:opacity-100">
          <NavigationBar />
        </div>
        
        <ConnectButton />
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

const SidePanel = ({ children }: { children: React.ReactNode }) => {
  const [isCollapsed, setIsCollapsed] = useState(false)
 
  return (
    <>
      {/* Side Panel with content - mid z-index */}
      <div 
        className="w-full h-full flex-1 flex-row justify-end transition-all duration-300 ease-in-out z-20 flex flex-row-reverse"
        style={{
          width: isCollapsed ? 'min(36px, 100vw)' : 'min(670px, 100vw)',
          height: '100vh',
        }}
        help-nav-item="left-panel"
      >
        {/* Collapse/Expand Button */}
        <button
            onClick={() => setIsCollapsed(!isCollapsed)}
            className={`h-full flex-shrink-0 bg-slate-100 border-r border-slate-300 transition-all duration-200 flex items-center justify-start`} 
            style={{
              width: '36px',  // Fixed width instead of grow
              minWidth: '36px',
              flexShrink: 0,  // Prevent it from shrinking
              borderTopRightRadius: '0',
              borderBottomRightRadius: '0',
            }}
          >
          
            <div className="flex flex-col items-center justify-center h-full">
              <div className={`transform transition-transform duration-300 text-slate-600 ${
                isCollapsed ? 'rotate-0' : 'rotate-180'
              }`}>
                <ChevronRightIcon className="w-6 h-6" />
              </div>
            </div>
          </button>

          {/* Panel Content */}
          <div 
            className={`w-full flex flex-col transition-opacity duration-200 bg-slate-100 overflow-hidden ${
              isCollapsed 
                ? 'opacity-100 delay-200' 
                : 'opacity-100 delay-0'
            }`}
            style={{
              width: isCollapsed ? '0px' : 'calc(min(670px, 100vw) - 36px)',
              height: '100vh'
            }}  
          > 
            <div className="w-full h-full overflow-y-auto">
              {children}
            </div>
          </div>
          </div>
      </>
  )
}

export const ProtocolNavigation: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { powers: powersAddress } = useParams<{ chainId: string, powers: string }>()
  const pathname = usePathname();
  const powers = usePowersStore();
  const { fetchPowers } = usePowers();


  useEffect(() => {
    if (powers.contractAddress == undefined || powers.contractAddress == `0x0` || powers.contractAddress != powersAddress) {
      fetchPowers(powersAddress as `0x${string}`)
    }
  }, [powersAddress, powers])

  // reset status and error when pathname changes
  useEffect(() => {
    setError({error: null})
    setStatus({status: "idle"})
  }, [pathname])

  return (
    <div className="w-full h-full flex flex-col justify-start items-center">
      <Header /> 
        {/* Background PowersFlow - lowest z-index */}
        <div className="absolute top-0 left-0 w-full h-full bg-slate-100 z-0" style={{ boxShadow: 'inset 8px 0 16px -8px rgba(0, 0, 0, 0.1)' }}>
            <PowersFlow 
              key={`powers-flow`} 
            />
        </div>
      <SidePanel >
        {children}
      </SidePanel>
      <Footer />
    </div>
  )
}

