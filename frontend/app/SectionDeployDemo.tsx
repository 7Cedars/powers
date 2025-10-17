"use client";

import { Button } from "@/components/Button"; 
import { ConnectButton } from "@/components/ConnectButton";
import { useCallback, useEffect, useState } from "react";
import { ChevronLeftIcon, ChevronRightIcon, ChevronUpIcon } from '@heroicons/react/24/outline';
import { useSwitchChain, useAccount } from "wagmi";
import { useRouter } from "next/navigation";
import { powersAbi } from "@/context/abi";
import { Status } from "@/context/types";
import { wagmiConfig } from "@/context/wagmiConfig";
import { deployContract as wagmiDeployContract, multicall, waitForTransactionReceipt, writeContract } from "@wagmi/core";
import { usePrivy } from "@privy-io/react-auth";
import { TwoSeventyRingWithBg } from "react-svg-spinners";
import { getEnabledOrganizations } from "@/organisations";
import Image from "next/image";

type DeployStatus = {
  powersCreate: Status;
  mocksDeploy: { name: string; status: Status }[];
  multicall: Status;
}

export function SectionDeployDemo() {
  const [deployStatus, setDeployStatus] = useState<DeployStatus>({
    powersCreate: "idle",
    mocksDeploy: [],
    multicall: "idle"
  });
  const [currentOrgIndex, setCurrentOrgIndex] = useState(0);
  const [formData, setFormData] = useState<Record<string, string>>({});
  const [status, setStatus] = useState<Status>("idle");
  const [error, setError] = useState<Error | null>(null);
  const [deployedDependencies, setDeployedMocks] = useState<Record<string, `0x${string}`>>({});
  const [deployedPowersAddress, setDeployedPowersAddress] = useState<`0x${string}` | undefined>();
  const [constituteCompleted, setConstituteCompleted] = useState(false);
  const [bytecodePowers, setBytecodePowers] = useState<`0x${string}` | undefined>();
  const [deployedLaws, setDeployedLaws] = useState<Record<string, `0x${string}`>>({});
  const { ready, authenticated } = usePrivy();
  const { chain } = useAccount();
  const { switchChain } = useSwitchChain();
  const router = useRouter();

  const isLocalhost = typeof window !== 'undefined' && window.location.hostname === 'localhost';
  
  const [isChainMenuOpen, setIsChainMenuOpen] = useState(false);
  const [selectedChain, setSelectedChain] = useState("Optimism Sepolia");

  // Get available organizations based on localhost condition
  const availableOrganizations = getEnabledOrganizations(isLocalhost);

  const chains = [
    { name: "Ethereum Sepolia", id: 11155111 },
    { name: "Optimism Sepolia", id: 11155420 },
    { name: "Arbitrum Sepolia", id: 421614 },
    ...(isLocalhost ? [{ name: "Foundry", id: 31337 }] : [])
  ];

  // Get the current selected chain ID
  const selectedChainId = chains.find(c => c.name === selectedChain)?.id;

  const getPowered = useCallback(async (chainId: number) => {
    const { default: data } = await import(`../../solidity/powered/${chainId}.json`, { assert: { type: "json" } });
    setBytecodePowers(data.powers as `0x${string}`);
    setDeployedLaws(data.laws as Record<string, `0x${string}`>);
  }, []);

  // Switch chain when selected chain changes
  useEffect(() => {
    if (selectedChainId && chain?.id !== selectedChainId) {
      switchChain({ chainId: selectedChainId });
    }
    if (selectedChainId) {
      getPowered(selectedChainId);
    }
  }, [selectedChainId, chain?.id, switchChain]);

  const currentOrg = availableOrganizations[currentOrgIndex];

  const handleInputChange = (fieldName: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [fieldName]: value
    }));
  };

  // Function to check if all required fields are filled
  const areRequiredFieldsFilled = () => {
    return currentOrg.fields
      .filter(field => field.required)
      .every(field => formData[field.name] && formData[field.name].trim() !== '');
  };

  // Check if there are any required fields
  const hasRequiredFields = currentOrg.fields.some(field => field.required);

  // Main deploy sequence handler
  const handleDeploySequence = useCallback(async () => {
    if (!bytecodePowers || !selectedChainId) return;

    try {
      setStatus("pending");
      setError(null);
      setConstituteCompleted(false);

      // Helper function to add delay for Anvil
      const isAnvil = selectedChainId === 31337;
      const delayIfNeeded = async () => {
        if (isAnvil) {
          await new Promise(resolve => setTimeout(resolve, 500)); // 500ms delay for Anvil
        }
      };

      // STEP 1: Deploy Powers contract
      console.log("Step 1: Deploying Powers contract...");
      setDeployStatus(prev => ({ ...prev, powersCreate: "pending" }));
      
      const powersTxHash = await wagmiDeployContract(wagmiConfig, {
        abi: powersAbi,
        bytecode: bytecodePowers,
        args: [currentOrg.metadata.title, currentOrg.metadata.uri, 10_000n, 25n]
      });

      console.log("Powers deployment tx:", powersTxHash);
      
      const powersReceipt = await waitForTransactionReceipt(wagmiConfig, {
        hash: powersTxHash,
        confirmations: isAnvil ? 1 : 2
      });

      const powersAddress = powersReceipt.contractAddress;
      if (!powersAddress) {
        throw new Error("Failed to get Powers contract address from receipt");
      }

      console.log("Powers deployed at:", powersAddress);
      setDeployedPowersAddress(powersAddress);
      setDeployStatus(prev => ({ ...prev, powersCreate: "success" }));
      
      await delayIfNeeded();

      // STEP 2: Deploy dependencies (mock contracts)
      console.log("Step 2: Deploying dependencies...");
      const dependencies = currentOrg.dependencies || [];
      const mockDeployStatuses = dependencies.map(dep => ({ name: dep.name, status: "pending" as Status }));
      setDeployStatus(prev => ({ ...prev, mocksDeploy: mockDeployStatuses }));

      const deployedDependenciesMap: Record<string, `0x${string}`> = {};

      for (let i = 0; i < dependencies.length; i++) {
        const dep = dependencies[i];
        console.log(`Deploying ${dep.name}...`);
        
        setDeployStatus(prev => ({
          ...prev,
          mocksDeploy: prev.mocksDeploy.map((m, idx) => 
            idx === i ? { ...m, status: "pending" } : m
          )
        }));

        const mockTxHash = await wagmiDeployContract(wagmiConfig, {
          abi: dep.abi,
          bytecode: dep.bytecode,
          args: dep.args || []
        });

        console.log(`${dep.name} deployment tx:`, mockTxHash);

        const mockReceipt = await waitForTransactionReceipt(wagmiConfig, {
          hash: mockTxHash,
          confirmations: isAnvil ? 1 : 2
        });

        const mockAddress = mockReceipt.contractAddress;
        if (!mockAddress) {
          throw new Error(`Failed to get ${dep.name} contract address from receipt`);
        }

        deployedDependenciesMap[dep.name] = mockAddress;
        console.log(`${dep.name} deployed at:`, mockAddress);

        setDeployStatus(prev => ({
          ...prev,
          mocksDeploy: prev.mocksDeploy.map((m, idx) => 
            idx === i ? { ...m, status: "success" } : m
          )
        }));

        await delayIfNeeded();
      }

      setDeployedMocks(deployedDependenciesMap);

      // STEP 3: Create law init data with deployed addresses
      console.log("Step 3: Creating law init data...");
      const lawInitData = currentOrg.createLawInitData(
        powersAddress,
        deployedLaws,
        deployedDependenciesMap
      );
      console.log("Law init data created:", lawInitData);

      // STEP 4: Execute constitute + transfer ownership
      // Use sequential execution for Anvil/Foundry, multicall for other chains
      console.log(`Step 4: Executing ${isAnvil ? 'sequential' : 'multicall'} transactions...`);
      setDeployStatus(prev => ({ ...prev, multicall: "pending" }));

      await delayIfNeeded();

      if (isAnvil) {
        // Sequential execution for Anvil
        console.log("Using sequential execution for Anvil chain...");
        
        // 4a: Execute constitute
        console.log("Calling constitute...");
        const constituteTxHash = await writeContract(wagmiConfig, {
          address: powersAddress,
          abi: powersAbi,
          functionName: 'constitute',
          args: [lawInitData]
        });
        
        console.log("Waiting for constitute transaction:", constituteTxHash);
        await waitForTransactionReceipt(wagmiConfig, { 
          hash: constituteTxHash,
          confirmations: 1
        });
        console.log("Constitute completed:", constituteTxHash);

        await delayIfNeeded();

        // 4b: Execute transferOwnership for ownable contracts
        for (const dep of dependencies) {
          if (dep.ownable && deployedDependenciesMap[dep.name]) {
            console.log(`Transferring ownership of ${dep.name} to Powers...`);
            const transferTxHash = await writeContract(wagmiConfig, {
              address: deployedDependenciesMap[dep.name],
              abi: dep.abi,
              functionName: 'transferOwnership',
              args: [powersAddress]
            });
            
            console.log(`Waiting for ${dep.name} ownership transfer:`, transferTxHash);
            await waitForTransactionReceipt(wagmiConfig, { 
              hash: transferTxHash,
              confirmations: 1
            });
            console.log(`${dep.name} ownership transferred:`, transferTxHash);

            await delayIfNeeded();
          }
        }
      } else {
        // Multicall execution for other chains
        console.log("Using multicall for non-Anvil chain...");
        const multicallContracts: any[] = [];

        // 4a: Add constitute call
        multicallContracts.push({
          address: powersAddress,
          abi: powersAbi,
          functionName: 'constitute',
          args: [lawInitData]
        });

        // 4b: Add transferOwnership calls for ownable contracts
        for (const dep of dependencies) {
          if (dep.ownable && deployedDependenciesMap[dep.name]) {
            console.log(`Adding transferOwnership for ${dep.name} to Powers`);
            multicallContracts.push({
              address: deployedDependenciesMap[dep.name],
              abi: dep.abi,
              functionName: 'transferOwnership',
              args: [powersAddress]
            });
          }
        }

        console.log("Executing multicall with contracts:", multicallContracts);
        const multicallResults = await multicall(wagmiConfig, {
          contracts: multicallContracts
        });
        console.log("Multicall results:", multicallResults);
      }

      setDeployStatus(prev => ({ ...prev, multicall: "success" }));

      // All done!
      setStatus("success");
      setConstituteCompleted(true);
      console.log("Deploy sequence completed successfully!");

    } catch (error) {
      console.error("Deploy sequence error:", error);
      setStatus("error");
      setError(error as Error);
      
      // Update failed status for current step
      setDeployStatus(prev => {
        if (prev.powersCreate === "pending") {
          return { ...prev, powersCreate: "error" };
        } else if (prev.mocksDeploy.some(m => m.status === "pending")) {
          return {
            ...prev,
            mocksDeploy: prev.mocksDeploy.map(m => 
              m.status === "pending" ? { ...m, status: "error" } : m
            )
          };
        } else if (prev.multicall === "pending") {
          return { ...prev, multicall: "error" };
        }
        return prev;
      });
    }
  }, [bytecodePowers, selectedChainId, currentOrg, deployedLaws]);

  const handleSeeYourPowers = () => {
    if (deployedPowersAddress && selectedChainId) {
      router.push(`/protocol/${selectedChainId}/${deployedPowersAddress}`);
    }
  };

  const resetFormData = () => {
    setConstituteCompleted(false);
    setStatus("idle");
    setError(null);
    setDeployedPowersAddress(undefined);
    setDeployedMocks({});
    setFormData({});
    setDeployStatus({
      powersCreate: "idle",
      mocksDeploy: [],
      multicall: "idle"
    });
  };

  const nextOrg = () => {
    setCurrentOrgIndex((prev) => (prev + 1) % availableOrganizations.length);
    resetFormData();
  };

  const prevOrg = () => {
    setCurrentOrgIndex((prev) => (prev - 1 + availableOrganizations.length) % availableOrganizations.length);
    resetFormData();
  };

  return (
    <section id="deploy" className="min-h-screen grow max-h-screen flex flex-col justify-start items-center pb-8 px-4 snap-start snap-always bg-gradient-to-b from-slate-100 to-slate-50 sm:pt-16 pt-4">
      <div className="w-full flex flex-col gap-4 justify-start items-center">
        <section className="flex flex-col justify-center items-center"> 
          <div className="w-full flex flex-row justify-center items-center md:text-4xl text-2xl text-slate-600 text-center max-w-4xl text-pretty font-bold px-4">
            Deploy a Demo
          </div>
          <div className="w-full flex flex-row justify-center items-center md:text-2xl text-xl text-slate-400 max-w-3xl text-center text-pretty py-2 px-4">
            Choose a template to try out the Powers protocol
          </div>
        </section>

        <section className="w-full grow max-h-[80vh] flex flex-col justify-start items-center bg-white border border-slate-200 rounded-md overflow-hidden max-w-4xl shadow-sm">
          {/* Carousel Header */}
          <div className="w-full flex flex-row justify-between items-center py-4 px-6 border-b border-slate-200 flex-shrink-0">
            <button
              onClick={prevOrg}
              className="p-2 rounded-md hover:bg-slate-100 transition-colors"
            >
              <ChevronLeftIcon className="w-6 h-6 text-slate-600" />
            </button>
            
            <div className="flex flex-col items-center">
              <h3 className="text-xl font-semibold text-slate-800 text-center">{currentOrg.metadata.title}</h3>
              <div className="flex gap-1 mt-2">
                {availableOrganizations.map((_, index) => (
                  <div
                    key={index}
                    className={`w-2 h-2 rounded-full ${
                      index === currentOrgIndex ? 'bg-slate-600' : 'bg-slate-300'
                    }`}
                  />
                ))}
              </div>
            </div>

            <button
              onClick={nextOrg}
              className="p-2 rounded-md hover:bg-slate-100 transition-colors"
            >
              <ChevronRightIcon className="w-6 h-6 text-slate-600" />
            </button>
          </div>

          {/* Form Content */}
          <div className="w-full py-6 px-6 flex flex-col overflow-y-auto flex-1">
            {/* Image Display */}
            {currentOrg.metadata.banner && (
              <div className="mb-4 flex justify-center">
                <div className="relative w-full h-48 sm:h-64">
                  <Image
                    src={currentOrg.metadata.banner} 
                    alt={`${currentOrg.metadata.title} template`}
                    fill
                    className="rounded-lg"
                    style={{objectFit: "contain"}}
                    onError={(e) => {
                      e.currentTarget.style.display = 'none';
                    }}
                  />
                </div>
              </div>
            )}
            
            <div className="mb-4">
              <p className="text-slate-600 text-sm leading-relaxed">
                {currentOrg.metadata.description}
              </p>
            </div>

            <div className="space-y-3">
              {currentOrg.fields.map((field) => (
                <div key={field.name} className="flex flex-col">
                  <label className="text-sm font-medium text-slate-700 mb-1">
                    {field.name.charAt(0).toUpperCase() + field.name.slice(1).replace(/([A-Z])/g, ' $1')}
                    {field.required && <span className="text-red-500 ml-1">*</span>}
                  </label>
                  <input
                    type={field.type}
                    name={field.name}
                    placeholder={field.placeholder}
                    className="w-full h-12 px-3 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
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
                {constituteCompleted && deployedPowersAddress ? (
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
                        : !ready || !authenticated || currentOrg.metadata.disabled || !areRequiredFieldsFilled()
                          ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
                          : 'bg-indigo-600 hover:bg-indigo-700 text-white'
                    }`}
                    onClick={() => {
                      if (ready && authenticated && !currentOrg.metadata.disabled && areRequiredFieldsFilled() && bytecodePowers) {
                        handleDeploySequence();
                      }
                    }}
                    disabled={!ready || !authenticated || currentOrg.metadata.disabled || !areRequiredFieldsFilled() || status === 'pending'}
                  > 
                    {status === 'error' ? (
                      'Error - Try Again'
                    ) : currentOrg.metadata.disabled ? (
                      'Coming soon!'
                    ) : status === 'pending' ? (
                      <div className="flex items-center gap-2">
                        <TwoSeventyRingWithBg className="w-5 h-5 animate-spin" color="text-slate-200" />
                        Deploying...
                      </div>
                    ) : (
                      `Deploy ${currentOrg.metadata.title}`
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

        {/* Deployment Status Display */}
        {(status === 'pending' || status === 'error' || status === 'success') && (
          <section className="w-full flex flex-col justify-start items-start bg-white border border-slate-200 rounded-md max-w-4xl shadow-sm p-6">
            <h4 className="text-lg font-semibold text-slate-800 mb-4">Deployment Status</h4>
            
            <div className="w-full space-y-3">
              {/* Step 1: Powers Contract */}
              <div className="flex items-center gap-3">
                {deployStatus.powersCreate === 'success' ? (
                  <div className="w-6 h-6 rounded-full bg-green-500 flex items-center justify-center flex-shrink-0">
                    <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                ) : deployStatus.powersCreate === 'pending' ? (
                  <div className="w-6 h-6 flex-shrink-0">
                    <TwoSeventyRingWithBg className="w-6 h-6" />
                  </div>
                ) : deployStatus.powersCreate === 'error' ? (
                  <div className="w-6 h-6 rounded-full bg-red-500 flex items-center justify-center flex-shrink-0">
                    <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </div>
                ) : (
                  <div className="w-6 h-6 rounded-full bg-slate-300 flex-shrink-0" />
                )}
                <span className={`text-sm ${deployStatus.powersCreate === 'success' ? 'text-green-600 font-medium' : deployStatus.powersCreate === 'error' ? 'text-red-600' : 'text-slate-600'}`}>
                  Deploy Powers Contract
                </span>
              </div>

              {/* Step 2: Dependencies - show all from the start */}
              {currentOrg.dependencies.map((dep, idx) => {
                const mockStatus = deployStatus.mocksDeploy.find(m => m.name === dep.name)?.status || 'idle';
                return (
                  <div key={idx} className="flex items-center gap-3">
                    {mockStatus === 'success' ? (
                      <div className="w-6 h-6 rounded-full bg-green-500 flex items-center justify-center flex-shrink-0">
                        <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                      </div>
                    ) : mockStatus === 'pending' ? (
                      <div className="w-6 h-6 flex-shrink-0">
                        <TwoSeventyRingWithBg className="w-6 h-6" />
                      </div>
                    ) : mockStatus === 'error' ? (
                      <div className="w-6 h-6 rounded-full bg-red-500 flex items-center justify-center flex-shrink-0">
                        <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </div>
                    ) : (
                      <div className="w-6 h-6 rounded-full bg-slate-300 flex-shrink-0" />
                    )}
                    <span className={`text-sm ${mockStatus === 'success' ? 'text-green-600 font-medium' : mockStatus === 'error' ? 'text-red-600' : 'text-slate-600'}`}>
                      Deploy {dep.name}
                    </span>
                  </div>
                );
              })}

              {/* Step 3: Multicall */}
              <div className="flex items-center gap-3">
                {deployStatus.multicall === 'success' ? (
                  <div className="w-6 h-6 rounded-full bg-green-500 flex items-center justify-center flex-shrink-0">
                    <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                ) : deployStatus.multicall === 'pending' ? (
                  <div className="w-6 h-6 flex-shrink-0">
                    <TwoSeventyRingWithBg className="w-6 h-6" />
                  </div>
                ) : deployStatus.multicall === 'error' ? (
                  <div className="w-6 h-6 rounded-full bg-red-500 flex items-center justify-center flex-shrink-0">
                    <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </div>
                ) : (
                  <div className="w-6 h-6 rounded-full bg-slate-300 flex-shrink-0" />
                )}
                <span className={`text-sm ${deployStatus.multicall === 'success' ? 'text-green-600 font-medium' : deployStatus.multicall === 'error' ? 'text-red-600' : 'text-slate-600'}`}>
                  Constitute & Transfer Ownership
                </span>
              </div>
            </div>

            {error && (
              <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md max-h-64 overflow-y-auto">
                <p className="text-sm text-red-600 break-words break-all whitespace-pre-wrap">
                  <strong>Error:</strong> {error.message}
                </p>
              </div>
            )}
          </section>
        )}

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

