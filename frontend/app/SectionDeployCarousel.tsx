"use client";

import { Button } from "@/components/Button"; 
import { ConnectButton } from "@/components/ConnectButton";
import { useCallback, useEffect, useState } from "react";
import { ChevronLeftIcon, ChevronRightIcon, ChevronUpIcon } from '@heroicons/react/24/outline';
import { useDeployContract, useTransactionReceipt, useSwitchChain, useAccount } from "wagmi";
import { useRouter } from "next/navigation";
import { bytecodePowers } from "@/context/bytecode";
import { powersAbi } from "@/context/abi";
import { Law, OrganizationType, Powers, Status } from "@/context/types";
import { wagmiConfig } from "@/context/wagmiConfig";
import { getConnectorClient, readContract, simulateContract, writeContract } from "@wagmi/core";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { 
  createPowers101LawInitData, 
  createCrossChainGovernanceLawInitData, 
  createGrantsManagerLawInitData,
  createSingleUpgradeLawInitData,
  createLawInitDataByType 
} from "@/public/createLawInitData";
import { TwoSeventyRingWithBg } from "react-svg-spinners";
import { deploymentForms, DeploymentForm } from "@/public/deploymentForms";

export function SectionDeployCarousel() {
  const [currentFormIndex, setCurrentFormIndex] = useState(0);
  const [formData, setFormData] = useState<Record<string, string>>({});
  const { deployContract, data: deployHash, reset } = useDeployContract()
  const { data: receipt } = useTransactionReceipt({
    hash: deployHash,
  })
  const [status, setStatus] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const [constituteCompleted, setConstituteCompleted] = useState(false)
  const { ready, authenticated } = usePrivy();
  const { wallets } = useWallets()
  const { chain } = useAccount()
  const { switchChain } = useSwitchChain()
  const router = useRouter()


  const isLocalhost = typeof window !== 'undefined' && window.location.hostname === 'localhost';
  
  const [isChainMenuOpen, setIsChainMenuOpen] = useState(false);
  const [selectedChain, setSelectedChain] = useState("Optimism Sepolia");

  // Filter deployment forms based on localhost condition
  const availableDeploymentForms = deploymentForms.filter(form => 
    !form.onlyLocalhost || (form.onlyLocalhost && isLocalhost)
  );

  const chains = [
    { name: "Ethereum Sepolia", id: 11155111 },
    { name: "Optimism Sepolia", id: 11155420 },
    { name: "Arbitrum Sepolia", id: 421614 },
    { name: "Mantle Sepolia", id: 5003 },
    ...(isLocalhost ? [{ name: "Foundry", id: 31337 }] : [])
  ];

  // Get the current selected chain ID
  const selectedChainId = chains.find(c => c.name === selectedChain)?.id

  // Switch chain when selected chain changes
  useEffect(() => {
    if (selectedChainId && chain?.id !== selectedChainId) {
      switchChain({ chainId: selectedChainId })
    }
  }, [selectedChainId, chain?.id, switchChain])

  // Reset current form index if it becomes invalid after filtering
  useEffect(() => {
    if (currentFormIndex >= availableDeploymentForms.length) {
      setCurrentFormIndex(0);
    }
  }, [currentFormIndex, availableDeploymentForms.length]);

  // console.log("deploy: ", {status, error, deployHash, receipt})

  const currentForm = availableDeploymentForms[currentFormIndex];

  // console.log("currentForm: ", {currentForm, currentFormIndex})

  const handleInputChange = (fieldName: string, value: string) => {
    setFormData(prev => ({
        ...prev,
        [fieldName]: value
      }));
  };

  // Function to create law initialization data based on current form
  const createLawInitDataForCurrentForm = (powersAddress: `0x${string}`) => {
    // console.log("form Title: ", currentForm.title)
    const chainId = selectedChainId || 11155111;
    // console.log("chainId: ", chainId)
    
    try {
      return createLawInitDataByType(currentForm.title as OrganizationType, powersAddress, formData, chainId);
    } catch (error) {
      console.error('Error creating law init data:', error);
      // Fallback to basic DAO if there's an error
      return createPowers101LawInitData(powersAddress, formData, chainId);
    }
  };

  // Function to check if all required fields are filled
  const areRequiredFieldsFilled = () => {
    // console.log("areRequiredFieldsFilled: ", {currentForm, formData})
    return currentForm.fields
      .filter(field => field.required)
      .every(field => formData[field.name] && formData[field.name].trim() !== '');
  };

  // Check if there are any required fields
  const hasRequiredFields = currentForm.fields.some(field => field.required);

  const callConstitute = useCallback( 
    async (
      powersAddress: `0x${string}`
    ) => {  
        // console.log("@execute: waypoint 0", {powersAddress})
        setError(null)
        setStatus("pending")
        try {
          // Create dynamic law initialization data based on current form
          const lawInitData = createLawInitDataForCurrentForm(powersAddress);
          // console.log("Calling constitute with dynamic law data:", lawInitData)
          
          const { request } = await simulateContract(wagmiConfig, {
            abi: powersAbi,
            address: powersAddress as `0x${string}`,
            functionName: 'constitute',
            args: [lawInitData]
          })

          // console.log("@execute: waypoint 1", {request})
          const client = await getConnectorClient(wagmiConfig)
          // console.log("@execute: waypoint 2", {client})
          
          if (request) {
            // console.log("@execute: waypoint 3", {request})
            const result = await writeContract(wagmiConfig, request)
            setTransactionHash(result)
            setConstituteCompleted(true)
            // console.log("@execute: waypoint 4", {result})
          }
        } catch (error) {
          setStatus("error") 
          setError(error)
          // console.log("@execute: waypoint 5", {error}) 
      }
  }, [currentFormIndex, formData] )

  useEffect(() => {
    if (receipt?.contractAddress) {
      callConstitute(receipt.contractAddress as `0x${string}`)
    }
  }, [receipt?.contractAddress, callConstitute])

  const handleSeeYourPowers = () => {
    if (receipt?.contractAddress && selectedChainId) {
      router.push(`/${selectedChainId}/${receipt.contractAddress}`)
    }
  }

  const resetFormData = () => {
    reset()
    setConstituteCompleted(false)
    setStatus("idle")
    setError(null)
    setTransactionHash(undefined)
  }

  const nextForm = () => {
    setCurrentFormIndex((prev) => (prev + 1) % availableDeploymentForms.length);
    resetFormData();
  };

  const prevForm = () => {
    setCurrentFormIndex((prev) => (prev - 1 + availableDeploymentForms.length) % availableDeploymentForms.length);
    resetFormData();
  };

  return (
    <section id="deploy" className="min-h-screen grow max-h-screen flex flex-col justify-start items-center pb-8 px-4 snap-start snap-always bg-gradient-to-b from-slate-100 to-slate-50 sm:pt-16 pt-4">
      <div className="w-full flex flex-col gap-4 justify-start items-center">
        <section className="flex flex-col justify-center items-center"> 
          <div className="w-full flex flex-row justify-center items-center md:text-4xl text-2xl text-slate-600 text-center max-w-4xl text-pretty font-bold px-4">
            Deploy Your Own Powers
          </div>
          <div className="w-full flex flex-row justify-center items-center md:text-2xl text-xl text-slate-400 max-w-3xl text-center text-pretty py-2 px-4">
            Choose a template to try out the Powers protocol
          </div>
        </section>

        <section className="w-full grow max-h-[80vh] flex flex-col justify-start items-center bg-white border border-slate-200 rounded-md overflow-hidden max-w-4xl shadow-sm ">
          {/* Carousel Header */}
          <div className="w-full flex flex-row justify-between items-center py-4 px-6 border-b border-slate-200 flex-shrink-0">
            <button
              onClick={prevForm}
              className="p-2 rounded-md hover:bg-slate-100 transition-colors"
            >
              <ChevronLeftIcon className="w-6 h-6 text-slate-600" />
            </button>
            
            <div className="flex flex-col items-center">
              <h3 className="text-xl font-semibold text-slate-800 text-center">{currentForm.title}</h3>
              <div className="flex gap-1 mt-2">
                {availableDeploymentForms.map((_, index) => (
                  <div
                    key={index}
                    className={`w-2 h-2 rounded-full ${
                      index === currentFormIndex ? 'bg-slate-600' : 'bg-slate-300'
                    }`}
                  />
                ))}
              </div>
            </div>

            <button
              onClick={nextForm}
              className="p-2 rounded-md hover:bg-slate-100 transition-colors"
            >
              <ChevronRightIcon className="w-6 h-6 text-slate-600" />
            </button>
          </div>

          {/* Form Content */}
          <div className="w-full p-6 flex flex-col overflow-y-auto flex-1">
            {/* Image Display */}
            {currentForm.banner && (
              <div className="mb-4 flex justify-center">
                <img 
                  src={currentForm.banner} 
                  alt={`${currentForm.title} template`}
                  className="max-w-full h-auto rounded-lg shadow-sm"
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                  }}
                />
              </div>
            )}
            
            <div className="mb-4">
              <p className="text-slate-600 text-sm leading-relaxed">
                {currentForm.description}
              </p>
            </div>

            <div className="space-y-3">
              {currentForm.fields.map((field) => (
                <div key={field.name} className="flex flex-col">
                  <label className="text-sm font-medium text-slate-700 mb-1">
                    {field.name.charAt(0).toUpperCase() + field.name.slice(1).replace(/([A-Z])/g, ' $1')}
                    {field.required && <span className="text-red-500 ml-1">*</span>}
                  </label>
                  <input
                    type={field.type}
                    name={field.name}
                    placeholder={field.placeholder}
                    className="w-full h-12 px-3 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                    value={formData[field.name] || ''}
                    onChange={(e) => handleInputChange(field.name, e.target.value)}
                    required={field.required}
                  />
                </div>
              ))}
            </div>

            {/* Required fields indicator */}
            {hasRequiredFields && (
              <div className="text-red-500 text-sm font-medium pt-2">
                * Required
              </div>
            )}

            <div className="mt-4 flex flex-col sm:flex-row justify-between items-center gap-4 flex-shrink-0">
                            {/* Deploy/See Your Powers button - positioned below on small screens, left on large screens */}
              <div className="w-full sm:w-fit h-12 order-2 sm:order-1">
                {constituteCompleted && receipt?.contractAddress ? (
                  <button 
                    className="w-full sm:w-fit h-12 px-6 bg-green-600 hover:bg-green-700 text-white font-medium rounded-md transition-colors duration-200 flex items-center justify-center"
                    onClick={handleSeeYourPowers}
                  > 
                    See Your New Powers
                  </button>
                ) : (
                  <button 
                    className={`w-full sm:w-fit h-12 px-6 font-medium rounded-md transition-colors duration-200 flex items-center justify-center ${
                      status === 'error'
                        ? 'bg-red-600 hover:bg-red-700 text-white border border-red-700'
                        : !ready || !authenticated || currentForm.disabled || !areRequiredFieldsFilled()
                          ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
                          : 'bg-indigo-600 hover:bg-indigo-700 text-white'
                    }`}
                    onClick={() => {
                      if (ready && authenticated && !currentForm.disabled && areRequiredFieldsFilled()) {
                        deployContract({
                          abi: powersAbi, 
                          args: [currentForm.title, currentForm.uri],
                          bytecode: bytecodePowers,
                        })
                      }
                    }}
                    disabled={!ready || !authenticated || currentForm.disabled || !areRequiredFieldsFilled() || status === 'error'}
                  > 
                    {status === 'error' ? (
                      'Error'
                    ) : currentForm.disabled ? (
                      'Coming soon!'
                    ) : deployHash && !constituteCompleted ? (
                      <div className="flex items-center gap-2">
                        <TwoSeventyRingWithBg className="w-5 h-5 animate-spin" color="text-slate-200" />
                        Deploying...
                      </div>
                    ) : (
                      `Deploy ${currentForm.title}`
                    )}
                  </button>
                )}
              </div>

              {/* Chain and Connect buttons - positioned above deploy button on small screens, right on large screens */}
              <div className="flex items-center gap-4 h-12 w-full sm:w-fit order-1 sm:order-2">
                {/* Chain Selection Button */}
                <div className="relative h-full w-full sm:w-fit">
                  <Button
                    size={1}
                    role={2}
                    onClick={() => setIsChainMenuOpen(!isChainMenuOpen)}
                  >
                    <div className="flex items-center gap-2 text-slate-600 font-medium">
                      {selectedChain}
                      <ChevronUpIcon 
                        className={`w-4 h-4 transition-transform duration-200 ${
                          isChainMenuOpen ? 'rotate-180' : ''
                        }`}
                      />
                    </div>
                  </Button>

                  {/* Drop-up Menu */}
                  {isChainMenuOpen && (
                    <div className="absolute bottom-full left-0 mb-2 bg-white border border-gray-200 rounded-lg shadow-lg z-10">
                      {chains.map((chain) => (
                        <button
                          key={chain.id}
                          className={`w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors ${
                            selectedChain === chain.name ? 'bg-blue-50 text-blue-600' : 'text-gray-700'
                          }`}
                          onClick={() => {
                            setSelectedChain(chain.name);
                            setIsChainMenuOpen(false);
                          }}
                        >
                          {chain.name}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {/* Connect Button */}
                <div className="sm:w-fit h-full">
                  <ConnectButton />
                </div>
              </div>
            </div>
          </div>
        </section>

        <div className="text-center">
          <p className="text-sm text-slate-500 max-w-2xl">
            <strong>Important:</strong> These deployments are for testing purposes only. 
            The Powers protocol has not been audited and should not be used for production environments. 
            Many of the examples lack basic security mechanisms and are for demo purposes only.
          </p>
        </div>
      </div>
    </section>
  );
} 