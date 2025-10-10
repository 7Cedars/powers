"use client";

import { useState, useEffect, useRef } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';
import { onboardingSteps, smallScreenOnboardingSteps } from './onboarding';
import { useRouter, useParams } from 'next/navigation';

interface OnboardingModalProps {
  isOpen: boolean;
  onClose: () => void;
  onRequestOpen?: () => void; // New prop to request opening the modal
}

export const OnboardingModal = ({ isOpen, onClose, onRequestOpen }: OnboardingModalProps) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [highlightElement, setHighlightElement] = useState<Element | null>(null);
  const [isElementLoading, setIsElementLoading] = useState(false);
  const [isSmallScreen, setIsSmallScreen] = useState(false);
  const router = useRouter();
  const { chainId, powers: addressPowers } = useParams<{ chainId: string, powers: string }>();
  
  // Determine which onboarding steps to use based on screen size
  const stepsToUse = isSmallScreen ? smallScreenOnboardingSteps : onboardingSteps;
  const totalSteps = stepsToUse.length;
  const currentStepData = stepsToUse[currentStep];
  const elementPollingRef = useRef<NodeJS.Timeout | null>(null);

  // Check if this is the first time and auto-show onboarding
  useEffect(() => {
    const hasSeenOnboarding = localStorage.getItem('powers-onboarding-completed');
    
    if (!hasSeenOnboarding && !isOpen && onRequestOpen) {
      // Small delay to ensure the page is fully loaded
      const timer = setTimeout(() => {
        // For first-time users, request the parent to open the modal
        onRequestOpen();
      }, 1000);
      
      return () => clearTimeout(timer);
    }
  }, [isOpen, onRequestOpen]);

  // Detect screen size changes
  useEffect(() => {
    const checkScreenSize = () => {
      setIsSmallScreen(window.innerWidth < 768); // 768px is typical tablet/desktop breakpoint
    };

    // Check initially
    checkScreenSize();

    // Add resize listener
    window.addEventListener('resize', checkScreenSize);
    
    return () => window.removeEventListener('resize', checkScreenSize);
  }, []);

  // Reset to first step when switching between small/large screen modes
  useEffect(() => {
    setCurrentStep(0);
  }, [isSmallScreen]);

  // Function to get element position for highlighting
  const getHighlightPosition = () => {
    if (!highlightElement) return null;
    
    const rect = highlightElement.getBoundingClientRect();
    
    // console.log('Highlight element rect:', rect);

    return {
      top: rect.top,
      left: rect.left,
      width: rect.width,
      height: rect.height
    };
  };

  // Function to find element with retry logic
  const findElementWithRetry = (selector: string, maxAttempts: number = 20, interval: number = 100) => {
    return new Promise<Element | null>((resolve) => {
      let attempts = 0;
      
      const tryFindElement = () => {
        attempts++;
        const element = document.querySelector(selector);
        
        if (element) {
          resolve(element);
          return;
        }
        
        if (attempts >= maxAttempts) {
          console.warn(`Element not found after ${maxAttempts} attempts: ${selector}`);
          resolve(null);
          return;
        }
        
        // Try again after interval
        setTimeout(tryFindElement, interval);
      };
      
      tryFindElement();
    });
  };

  // Find and track the target element with retry logic
  useEffect(() => {
    if (!currentStepData.highlight.target) {
      setHighlightElement(null);
      setIsElementLoading(false);
      return;
    }

    setIsElementLoading(true);
    
    // Clear any existing polling
    if (elementPollingRef.current) {
      clearTimeout(elementPollingRef.current);
    }

    const findElement = async () => {
      const element = await findElementWithRetry(currentStepData.highlight.target);
      setHighlightElement(element);
      setIsElementLoading(false);
    };

    findElement();

    // Update on resize
    const handleResize = () => {
      if (highlightElement) {
        const updatedElement = document.querySelector(currentStepData.highlight.target);
        setHighlightElement(updatedElement);
      }
    };

    window.addEventListener('resize', handleResize);
    return () => {
      window.removeEventListener('resize', handleResize);
      if (elementPollingRef.current) {
        clearTimeout(elementPollingRef.current);
      }
    };
  }, [currentStepData.highlight.target]);

  // Navigate to the appropriate page when step changes
  useEffect(() => {
    if (currentStepData.url && currentStepData.url !== '') {
      const fullUrl = `/protocol/${chainId}/${addressPowers}${currentStepData.url}`;
      router.push(fullUrl);
    }
  }, [currentStep, currentStepData.url, chainId, addressPowers, router]);

  const handleNext = () => {
    if (currentStep < totalSteps - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      handleClose();
    }
  };

  const handlePrevious = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleClose = () => {
    onClose();
    // Mark onboarding as completed
    localStorage.setItem('powers-onboarding-completed', 'true');
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-75 flex items-center justify-center">
      {/* Backdrop with black overlay and highlight cutout */}
      <div 
        className="absolute inset-0 bg-black opacity-10" // was opacity-20  
        onClick={handleClose}
      />
      
      {/* Element-based highlight overlay */}
      <div className="absolute inset-0 pointer-events-none">
        {currentStepData.highlight.target && highlightElement && getHighlightPosition() && (
          <>
            {/* Top overlay */}
            <div 
              className="absolute bg-black opacity-20"
              style={{
                top: 0,
                left: 0,
                right: 0,
                height: getHighlightPosition()?.top
              }}
            />
            {/* Left overlay */}
            <div 
              className="absolute bg-black opacity-20"
              style={{
                top: getHighlightPosition()?.top,
                left: 0,
                width: getHighlightPosition()?.left,
                height: getHighlightPosition()?.height
              }}
            />
            {/* Right overlay */}
            <div 
              className="absolute bg-black opacity-20"
              style={{
                top: getHighlightPosition()?.top,
                left: (getHighlightPosition()?.left || 0) + (getHighlightPosition()?.width || 0),
                right: 0,
                height: getHighlightPosition()?.height
              }}
            />
            {/* Bottom overlay */}
            <div 
              className="absolute bg-black opacity-20"
              style={{
                top: (getHighlightPosition()?.top || 0) + (getHighlightPosition()?.height || 0),
                left: 0,
                right: 0,
                bottom: 0
              }}
            />
          </>
        )}
        
        {/* Loading indicator when element is not found yet */}
        {currentStepData.highlight.target && isElementLoading && (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="bg-white rounded-lg shadow-lg p-4">
              <div className="flex items-center space-x-2">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-slate-600"></div>
                <span className="text-slate-600 text-sm">Loading element...</span>
              </div>
            </div>
          </div>
        )}
      </div>
      
      {/* Modal card */}
      <div className="relative bg-slate-50 rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-hidden">
        {/* Close button */}
        <button
          onClick={handleClose}
          className="absolute top-4 right-4 z-10 p-2 rounded-full hover:bg-slate-200 transition-colors"
        >
          <XMarkIcon className="h-6 w-6 text-slate-600" />
        </button>

        {/* Content area */}
        <div className="p-8 pt-12">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-slate-800 mb-2">
              {currentStepData.title}
            </h2>
            <p className="text-slate-600 mb-4">
              {currentStepData.subtitle}
            </p>
            
            {/* Step content */}
            <div className="min-h-[200px] flex flex-col items-center justify-center space-y-4">
              <p className="text-slate-600 leading-relaxed max-w-lg">
                {currentStepData.upperText}
              </p>
              {currentStepData.image && (
                <div className="mb-2">
                  <img 
                    src={currentStepData.image} 
                    alt={currentStepData.title}
                    className="mx-auto max-w-full h-auto rounded-lg border border-slate-300"
                  />
                </div>
              )}
              {currentStepData.bottomText && (
                <p className="text-slate-600 leading-relaxed max-w-lg">
                  {currentStepData.bottomText}
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Navigation buttons */}
        <div className="flex justify-between items-center p-6 border-t border-slate-200">
          <button
            onClick={handlePrevious}
            disabled={currentStep === 0}
            className={`px-4 py-2 rounded-md transition-colors ${
              currentStep === 0
                ? 'text-slate-400 cursor-not-allowed'
                : 'text-slate-600 hover:bg-slate-200'
            }`}
          >
            Previous
          </button>

          <div className="flex space-x-2">
            {Array.from({ length: totalSteps }, (_, index) => (
              <div
                key={index}
                className={`w-2 h-2 rounded-full ${
                  index === currentStep ? 'bg-slate-600' : 'bg-slate-300'
                }`}
              />
            ))}
          </div>

          <button
            onClick={handleNext}
            className="px-4 py-2 bg-slate-600 text-white rounded-md hover:bg-slate-700 transition-colors"
          >
            {currentStep === totalSteps - 1 ? 'Finish' : 'Next'}
          </button>
        </div>
      </div>
    </div>
  );
};
