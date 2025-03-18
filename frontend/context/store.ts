import { create } from 'zustand';
import { Config, Proposal, Law, Organisation, Action, Role, Roles } from '../context/types'

type OrgStore = Organisation; 
const initialStateOrg: OrgStore = {
  name: '',
  contractAddress: `0x0`,
  colourScheme: 0,
  laws: [],
  proposals: [],
  roles: [],
  roleLabels: [], 
  deselectedRoles: []
}

type LawStore = Law;
const initialStateLaw: LawStore = {
  name: '',
  description: '',
  config: {
    delayExecution: 0n, 
    needCompleted: `0x0`,
    needNotCompleted: `0x0`,
    readStateFrom: `0x0`,
    quorum: 0n, 
    succeedAt: 0n, 
    throttleExecution: 0n,
    votingPeriod: 0n
  },
  law: `0x0`,
  params: [],
  allowedRole: 0n
}

type ProposalStore = Proposal;
const initialStateProposal: ProposalStore = {
  actionId: 0,
  targetLaw: `0x`,
  voteStart: 0n,
  voteDuration: 0n,
  voteEnd: 0n,
  cancelled: false,
  completed: false,
  caller: `0x`,
  againstVotes: 0n,
  forVotes: 0n,
  abstainVotes: 0n,
  description: "",
  executeCalldata: `0x`,
  state: 5,
  blockNumber: 0n,
  blockHash: `0x`
}

type ActionStore = Action;
const initialStateAction: ActionStore = {
  dataTypes: [],
  paramValues: [],
  description: '',
  callData: `0x0`, 
  upToDate: false
}

type RoleStore = Roles;
const initialStateRole: RoleStore = {
  roleId: 999n, 
  holders: 0,
  laws: [],
  proposals: [], 
  roles: [],
}

// Organisation Store
export const useOrgStore = create<OrgStore>()(() => initialStateOrg); 

export const assignOrg: typeof useOrgStore.setState = (organisation) => {
      useOrgStore.setState(organisation)
    }
export const deleteOrg: typeof useOrgStore.setState = () => {
      useOrgStore.setState(initialStateOrg)
    }

// Law Store 
export const useLawStore = create<LawStore>()(() => initialStateLaw); 

export const setLaw: typeof useLawStore.setState = (law) => {
  useLawStore.setState(law)
    }
export const deleteLaw: typeof useLawStore.setState = () => {
      useLawStore.setState(initialStateLaw)
    }

// Proposal Store
export const useProposalStore = create<ProposalStore>()(() => initialStateProposal); 

export const setProposal: typeof useProposalStore.setState = (proposal) => {
    useProposalStore.setState(proposal)
      }
export const deleteProposal: typeof useProposalStore.setState = () => {
    useProposalStore.setState(initialStateProposal)
    }

// Action Store
export const useActionStore = create<ActionStore>()(() => initialStateAction);

export const setAction: typeof useActionStore.setState = (action) => {
  useActionStore.setState(action)
    }
export const deleteAction: typeof useActionStore.setState = () => {
      useActionStore.setState(initialStateAction)
    }

export const notUpToDate: typeof useActionStore.setState = () => {
  useActionStore.setState({...initialStateAction, upToDate: false})
}
  
  
// Role store 
export const useRoleStore = create<RoleStore>()(() => initialStateRole);

export const setRole: typeof useRoleStore.setState = (role) => {
  useRoleStore.setState(role)
    }
export const deleteRole: typeof useRoleStore.setState = () => {
  useRoleStore.setState(initialStateRole)
    }

