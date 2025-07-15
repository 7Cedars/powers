"use client";

import { Button } from "@/components/Button"; 
import { ConnectButton } from "@/components/ConnectButton";
import { useCallback, useEffect, useState } from "react";
import { ChevronLeftIcon, ChevronRightIcon, ChevronUpIcon } from '@heroicons/react/24/outline';
import { useDeployContract, useTransactionReceipt, useSwitchChain, useAccount } from "wagmi";
import { bytecodePowers } from "@/context/bytecode";
import { powersAbi } from "@/context/abi";
import { Law, Powers, Status } from "@/context/types";
import { wagmiConfig } from "@/context/wagmiConfig";
import { getConnectorClient, readContract, simulateContract, writeContract } from "@wagmi/core";
import { usePrivy } from "@privy-io/react-auth";
import { 
  createPowers101LawInitData, 
  createCrossChainGovernanceLawInitData, 
  createGrantsManagerLawInitData,
  createLawInitDataByType 
} from "@/utils/createLawInitData";

interface DeploymentForm {
  id: number;
  title: string;
  uri: string; 
  banner: string;
  description: string;
  disabled: boolean;
  fields: {
    name: string;
    placeholder: string;
    type: string;
    required: boolean;
  }[];
}

const deploymentForms: DeploymentForm[] = [
  {
    id: 1,
    title: "Powers 101",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreieioptfopmddgpiowg6duuzsd4n6koibutthev72dnmweczjybs4q",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeibbtfbr5t7ndfwrh2gp5xwleahnezkugqiwcfj5oktvt5heijoswq",
    description: "A simple DAO with a basic governance based on a separation of powers between delegates, an executive council and an admin. It is a good starting point for understanding the Powers protocol. The treasury address is optional, if left empty a mock treasury address is used.",
    disabled: false,
    fields: [
      { name: "treasuryAddress", placeholder: "Treasury address (0x...)", type: "text", required: false }
    ]
  },
  {
    id: 2,
    title: "Bridging Off-Chain Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiakcm5i4orree75muwzlezxyegyi2wjluyr2l657oprgfqlxllzoi",
    banner: "",
    description: "Deploy a DAO that bridges off-chain snapshot votes to on-chain governor.sol governance. The snapshot space and governor address are optional, if left empty a mock space and address are used.",
    disabled: true,
    fields: [
      { name: "snapshotSpace", placeholder: "Snapshot space address (0x...)", type: "text", required: false },
      { name: "governorAddress", placeholder: "Governor address (0x...)", type: "text", required: false }
    ]
  },
  {
    id: 3,
    title: "Grants Manager",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiduudrmyjwrv3krxl2kg6dfuofyag7u2d22beyu5os5kcitghtjbm",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeibglg2jk56676ugqtarjzseiq6mpptuapal6xlkt5avm3gtxcwgcy",
    description: "Deploy a DAO focused on grant management. This form allows you to deploy a Powers.sol instance with grant distribution laws. The grant manager contract is optional, if left empty a mock grant manager contract is used. Assessors can also be selected after the deployment.",
    disabled: true,
    fields: [
      { name: "parentDaoAddress", placeholder: "Parent DAO address (0x...)", type: "text", required: false },
      { name: "grantTokenAddress", placeholder: "Grant token address (0x...)", type: "text", required: false },
      { name: "assessors", placeholder: "Assessors addresses (0x...), comma separated", type: "text", required: false }
    ]
  }
];

export function SectionDeployCarousel() {
  const [currentFormIndex, setCurrentFormIndex] = useState(0);
  const [formData, setFormData] = useState<Record<string, string>>({});
  const { deployContract, data } = useDeployContract()
  const { data: receipt } = useTransactionReceipt({
    hash: data,
  })
  const [status, setStatus] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [transactionHash, setTransactionHash ] = useState<`0x${string}` | undefined>()
  const { ready, authenticated } = usePrivy();
  const { chain } = useAccount()
  const { switchChain } = useSwitchChain()

  const [isChainMenuOpen, setIsChainMenuOpen] = useState(false);
  const [selectedChain, setSelectedChain] = useState("Ethereum Sepolia");

  const chains = [
    { name: "Ethereum Sepolia", id: 11155111 },
    { name: "Optimism Sepolia", id: 11155420 },
    { name: "Arbitrum Sepolia", id: 421614 }
  ];

  // Get the current selected chain ID
  const selectedChainId = chains.find(c => c.name === selectedChain)?.id

  // Switch chain when selected chain changes
  useEffect(() => {
    if (selectedChainId && chain?.id !== selectedChainId) {
      switchChain({ chainId: selectedChainId })
    }
  }, [selectedChainId, chain?.id, switchChain])

  console.log("deploy: ", {status, error, data, receipt})

  const currentForm = deploymentForms[currentFormIndex];

  const handleInputChange = (fieldName: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [fieldName]: value
    }));
  };

  // Function to get the current form type
  const getCurrentFormType = () => {
    switch (currentForm.title) {
      case "Powers 101":
        return 'Powers101';
      case "Cross Chain Governance":
        return 'CrossChainGovernance';
      case "Grants Manager":
        return 'GrantsManager';
      default:
        return 'Powers101';
    }
  };

  // Function to create law initialization data based on current form
  const createLawInitDataForCurrentForm = () => {
    const formType = getCurrentFormType();
    const chainId = selectedChainId || 11155111;
    
    try {
      return createLawInitDataByType(formType, formData, chainId);
    } catch (error) {
      console.error('Error creating law init data:', error);
      // Fallback to basic DAO if there's an error
      return createPowers101LawInitData(formData, chainId);
    }
  };

  const callConstitute = useCallback( 
    async (
      powersAddress: `0x${string}`
    ) => {  
        // console.log("@execute: waypoint 1", {law, lawCalldata, nonce, description})
        setError(null)
        setStatus("pending")
        try {
          // Create dynamic law initialization data based on current form
          const lawInitData = createLawInitDataForCurrentForm();
          console.log("Calling constitute with dynamic law data:", lawInitData)
          
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
  }, [receipt?.contractAddress])

  const nextForm = () => {
    setCurrentFormIndex((prev) => (prev + 1) % deploymentForms.length);
  };

  const prevForm = () => {
    setCurrentFormIndex((prev) => (prev - 1 + deploymentForms.length) % deploymentForms.length);
  };

  return (
    <section className="min-h-screen grow flex flex-col justify-start items-center pb-8 px-4 snap-start snap-always bg-gradient-to-b from-slate-100 to-slate-50 pt-16">
      <div className="w-full flex flex-col gap-12 justify-start items-center">
        <section className="flex flex-col justify-center items-center"> 
          <div className="w-full flex flex-row justify-center items-center md:text-4xl text-2xl text-slate-600 text-center max-w-4xl text-pretty font-bold px-4">
            Deploy Your Own Powers
          </div>
          <div className="w-full flex flex-row justify-center items-center md:text-2xl text-xl text-slate-400 max-w-3xl text-center text-pretty py-2 px-4">
            Choose a template to try out the Powers protocol
          </div>
        </section>

        <section className="w-full h-full flex flex-col justify-start items-center bg-white border border-slate-200 rounded-md overflow-hidden max-w-4xl shadow-sm ">
          {/* Carousel Header */}
          <div className="w-full flex flex-row justify-between items-center py-4 px-6 border-b border-slate-200">
            <button
              onClick={prevForm}
              className="p-2 rounded-md hover:bg-slate-100 transition-colors"
            >
              <ChevronLeftIcon className="w-6 h-6 text-slate-600" />
            </button>
            
            <div className="flex flex-col items-center">
              <h3 className="text-xl font-semibold text-slate-800">{currentForm.title}</h3>
              <div className="flex gap-1 mt-2">
                {deploymentForms.map((_, index) => (
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
          <div className="w-full p-6 flex flex-col min-h-[600px] overflow-y-auto">
            {/* Image Display */}
            {currentForm.banner && (
              <div className="mb-6 flex justify-center">
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
            
            <div className="mb-6">
              <p className="text-slate-600 text-sm leading-relaxed">
                {currentForm.description}
              </p>
            </div>

            <div className="space-y-4 flex-grow">
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
                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                    value={formData[field.name] || ''}
                    onChange={(e) => handleInputChange(field.name, e.target.value)}
                    required={field.required}
                  />
                </div>
              ))}
            </div>

            <div className="mt-8 flex flex-col sm:flex-row justify-between items-center gap-4 flex-shrink-0">
              {/* Deploy button - positioned below on small screens, left on large screens */}
              <div className="w-full sm:w-fit h-12 order-2 sm:order-1">
                <Button 
                  size={1} 
                  role={6} 
                  statusButton={!ready || !authenticated || currentForm.disabled ? 'disabled' : 'idle'}
                  onClick={() =>
                    deployContract({
                      abi: powersAbi, 
                      args: [currentForm.title, currentForm.uri],
                      bytecode: bytecodePowers,
                    })
                  }
                > 
                  <div className="text-slate-600 font-medium">
                    {currentForm.disabled ? 'Coming soon!' : `Deploy ${currentForm.title}`}
                  </div>    
                </Button>
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
          </p>
        </div>
      </div>
    </section>
  );
} 