'use client';

import { useState, useEffect } from 'react';
import { ArrowDownTrayIcon, XMarkIcon } from '@heroicons/react/24/outline';

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{outcome: 'accepted' | 'dismissed'}>;
}

declare global {
  interface WindowEventMap {
    beforeinstallprompt: BeforeInstallPromptEvent;
  }
}

export function PWAInstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [showInstallPrompt, setShowInstallPrompt] = useState(false);

  useEffect(() => {
    const handler = (e: BeforeInstallPromptEvent) => {
      // Prevent the mini-infobar from appearing on mobile
      e.preventDefault();
      // Stash the event so it can be triggered later
      setDeferredPrompt(e);
      setShowInstallPrompt(true);
    };

    window.addEventListener('beforeinstallprompt', handler);

    return () => window.removeEventListener('beforeinstallprompt', handler);
  }, []);

  const handleInstallClick = async () => {
    if (!deferredPrompt) return;

    // Show the install prompt
    deferredPrompt.prompt();
    
    // Wait for the user to respond to the prompt
    const { outcome } = await deferredPrompt.userChoice;
    
    // if (outcome === 'accepted') {
    //   console.log('User accepted the A2HS prompt');
    // } else {
    //   console.log('User dismissed the A2HS prompt');
    // }
    
    // Clear the deferredPrompt so it can be garbage collected
    setDeferredPrompt(null);
    setShowInstallPrompt(false);
  };

  const handleDismiss = () => {
    setShowInstallPrompt(false);
  };

  if (!showInstallPrompt) {
    return null;
  }

  return (
    <div className="fixed bottom-4 left-4 right-4 z-50 md:left-auto md:right-4 md:w-80">
      <div className="bg-white border border-slate-200 rounded-lg shadow-lg p-4">
        <div className="flex items-start justify-between">
          <div className="flex items-center space-x-3">
            <div className="flex-shrink-0">
              <ArrowDownTrayIcon className="h-6 w-6 text-slate-600" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm font-medium text-slate-900">
                Install Powers Protocol
              </h3>
              <p className="text-xs text-slate-600 mt-1">
                Add to your home screen for quick access
              </p>
            </div>
          </div>
          <button
            onClick={handleDismiss}
            className="flex-shrink-0 text-slate-400 hover:text-slate-600"
          >
            <XMarkIcon className="h-5 w-5" />
          </button>
        </div>
        <div className="mt-4 flex space-x-2">
          <button
            onClick={handleInstallClick}
            className="flex-1 bg-slate-900 text-white text-sm font-medium px-3 py-2 rounded-md hover:bg-slate-800 transition-colors"
          >
            Install
          </button>
          <button
            onClick={handleDismiss}
            className="flex-1 bg-slate-100 text-slate-700 text-sm font-medium px-3 py-2 rounded-md hover:bg-slate-200 transition-colors"
          >
            Not now
          </button>
        </div>
      </div>
    </div>
  );
} 