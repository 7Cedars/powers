import { create } from 'zustand';
import { Action, Roles } from '../context/types'

type ActionStore = Action;
const initialStateAction: ActionStore = {
  actionId: "0",
  lawId: 0n,
  caller: `0x0`,
  description: "",
  dataTypes: [],
  paramValues: [],
  nonce: 0n,
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