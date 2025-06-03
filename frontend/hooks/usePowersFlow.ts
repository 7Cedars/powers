import { useState, useEffect, useCallback } from 'react'
import { Powers, Law, Checks } from '@/context/types'
import { ConnectedWallet } from '@privy-io/react-auth'

interface UsePowersFlowProps {
  powers: Powers
  wallets: ConnectedWallet[]
}

export const usePowersFlow = ({ powers, wallets }: UsePowersFlowProps) => {
  const [lawChecks, setLawChecks] = useState<Map<string, Checks>>(new Map())
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const calculateBasicChecks = useCallback((law: Law): Checks => {
    if (!law.conditions) {
      return {
        delayPassed: true,
        throttlePassed: true,
        actionNotCompleted: true,
        lawCompleted: true,
        lawNotCompleted: true,
        allPassed: true,
      }
    }

    // Calculate basic checks based on law conditions
    const checks: Checks = {
      delayPassed: law.conditions.delayExecution === 0n,
      throttlePassed: law.conditions.throttleExecution === 0n,
      actionNotCompleted: true, // Default assumption for visualization
      lawCompleted: law.conditions.needCompleted === 0n,
      lawNotCompleted: law.conditions.needNotCompleted === 0n,
      allPassed: false, // Will be calculated
    }

    // Calculate allPassed
    checks.allPassed = Boolean(
      checks.delayPassed &&
      checks.throttlePassed &&
      checks.actionNotCompleted &&
      checks.lawCompleted &&
      checks.lawNotCompleted
    )

    return checks
  }, [])

  const fetchAllLawChecks = useCallback(async () => {
    if (!powers.activeLaws || !wallets.length) {
      // If no wallets, still show basic checks based on law conditions
      if (powers.activeLaws) {
        const checksMap = new Map<string, Checks>()
        powers.activeLaws.forEach(law => {
          const basicChecks = calculateBasicChecks(law)
          checksMap.set(String(law.index), basicChecks)
        })
        setLawChecks(checksMap)
      }
      return
    }

    setIsLoading(true)
    setError(null)
    
    const checksMap = new Map<string, Checks>()

    try {
      // For each active law, calculate basic checks
      for (const law of powers.activeLaws) {
        if (!law.conditions) continue

        try {
          const checks = calculateBasicChecks(law)
          checksMap.set(String(law.index), checks)
        } catch (lawError) {
          console.warn(`Failed to calculate checks for law ${law.index}:`, lawError)
          // Still add basic checks even if calculation fails
          const basicChecks = calculateBasicChecks(law)
          checksMap.set(String(law.index), basicChecks)
        }
      }

      setLawChecks(checksMap)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch law checks')
    } finally {
      setIsLoading(false)
    }
  }, [powers.activeLaws, wallets, calculateBasicChecks])

  // Fetch checks when powers or wallets change
  useEffect(() => {
    fetchAllLawChecks()
  }, [fetchAllLawChecks])

  const refreshChecks = useCallback(() => {
    fetchAllLawChecks()
  }, [fetchAllLawChecks])

  return {
    lawChecks,
    isLoading,
    error,
    refreshChecks,
  }
} 