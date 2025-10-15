import { create } from 'zustand';
import { Action } from '../context/types'

// Action Store
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


export const useActionStore = create<ActionStore>()(() => initialStateAction);

export const setAction: typeof useActionStore.setState = (action) => {
  useActionStore.setState(action)
}
export const deleteAction: typeof useActionStore.setState = () => {
      useActionStore.setState(initialStateAction)
}

// Error Store
type ErrorStore = {
  error: Error | string | null
}

const initialStateError: ErrorStore = {
  error: null
}

export const useErrorStore = create<ErrorStore>()(() => initialStateError);

export const setError: typeof useErrorStore.setState = (error) => {
  useErrorStore.setState(error)
}
export const deleteError: typeof useErrorStore.setState = () => {
  useErrorStore.setState(initialStateError)
}
