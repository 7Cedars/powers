import { create } from 'zustand';
import { Action, CommunicationChannels, Powers, Status } from '../context/types'

// Action Store
type PowersStore = Powers;
const initialStatePowers: PowersStore = {
  contractAddress: `0x0`,
  chainId: 0n,
  name: "",
  uri: "",
  metadatas: {
    icon: "",
    banner: "",
    description: "",
    website: "",
    codeOfConduct: "",
    disputeResolution: "",
    communicationChannels: {} as CommunicationChannels,
    attributes: []
  },
  lawCount: 0n,
  laws: [],
  roles: [],
  layout: {}
}

export const usePowersStore = create<PowersStore>()(() => initialStatePowers);

export const setPowers: typeof usePowersStore.setState = (powers) => {
  usePowersStore.setState(powers)
}
export const deletePowers: typeof usePowersStore.setState = () => {
      usePowersStore.setState(initialStatePowers)
}

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


// Error Store
type StatusStore = {
  status: Status
}

const initialStateStatus: StatusStore = {
  status: "idle"
}

export const useStatusStore = create<StatusStore>()(() => initialStateStatus);

export const setStatus: typeof useStatusStore.setState = (status) => {
  useStatusStore.setState(status)
}
export const deleteStatus: typeof useStatusStore.setState = () => {
  useStatusStore.setState(initialStateStatus)
}