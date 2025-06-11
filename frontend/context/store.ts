import { create } from 'zustand';
import { Action, Roles, Checks, Status } from '../context/types'

type ActionStore = Action;
const initialStateAction: ActionStore = {
  actionId: "0",
  lawId: 0n,
  caller: `0x0`,
  description: "",
  dataTypes: [],
  paramValues: [],
  nonce: "0",
  callData: `0x0`, 
  upToDate: false
}

type ErrorStore = {
  error: Error | string | null
}

const initialStateError: ErrorStore = {
  error: null
}

type RoleStore = {
  deselectedRoles: bigint[]
}
const initialStateRole: RoleStore = {
  deselectedRoles: []
} 

type ChecksStore = {
  chainChecks: Map<string, Checks>
}

const initialStateChecks: ChecksStore = {
  chainChecks: new Map()
}

type ActionDataStore = {
  actionData: Map<string, Action>
}

const initialStateActionData: ActionDataStore = {
  actionData: new Map()
}

type ChecksStatusStore = {
  status: Status
  chains: string[]
}

const initialStateChecksStatus: ChecksStatusStore = {
  status: 'idle',
  chains: []
}

// Action Store
export const useActionStore = create<ActionStore>()(() => initialStateAction);

export const setAction: typeof useActionStore.setState = (action) => {
  useActionStore.setState(action)
}
export const deleteAction: typeof useActionStore.setState = () => {
      useActionStore.setState(initialStateAction)
}
 

// Error Store
export const useErrorStore = create<ErrorStore>()(() => initialStateError);

export const setError: typeof useErrorStore.setState = (error) => {
  useErrorStore.setState(error)
}
export const deleteError: typeof useErrorStore.setState = () => {
  useErrorStore.setState(initialStateError)
}

// Role store 
export const useRoleStore = create<RoleStore>()(() => initialStateRole);

export const setRole: typeof useRoleStore.setState = (role) => {
  useRoleStore.setState(role)
    }
export const deleteRole: typeof useRoleStore.setState = () => {
  useRoleStore.setState(initialStateRole)
    }

// Checks Store
export const useChecksStore = create<ChecksStore>()(() => initialStateChecks);

export const setChainChecks = (chainChecks: Map<string, Checks>) => {
  useChecksStore.setState({ chainChecks })
}

export const updateLawChecks = (lawId: string, checks: Checks) => {
  const currentState = useChecksStore.getState()
  const newChainChecks = new Map(currentState.chainChecks)
  newChainChecks.set(lawId, checks)
  useChecksStore.setState({ chainChecks: newChainChecks })
}

export const clearChainChecks = () => {
  useChecksStore.setState(initialStateChecks)
}

// Action Data Store
export const useActionDataStore = create<ActionDataStore>()(() => initialStateActionData);

export const setActionData = (actionData: Map<string, Action>) => {
  useActionDataStore.setState({ actionData })
}

// Checks Status Store
export const useChecksStatusStore = create<ChecksStatusStore>()(() => initialStateChecksStatus);

export const setChecksStatus: typeof useChecksStatusStore.setState = (status) => {
  useChecksStatusStore.setState(status)
}
export const deleteChecksStatus: typeof useChecksStatusStore.setState = () => {
  useChecksStatusStore.setState(initialStateChecksStatus)
}