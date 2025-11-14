import { defineConfig } from 'vocs'

export default defineConfig({
  title: 'Powers',
  theme: {
    variables: {
      content: {
        horizontalPadding: '1.5rem',
        verticalPadding: '3rem'
      },
    },
  },
  sidebar: [
    {
      text: 'Welcome',
      link: '/welcome',
    },
    {
      text: 'Use Cases',
      link: '/use-cases',
    },
    {
      text: 'Development',
      link: '/development',
    },
    { 
      text: 'For Developers', 
      collapsed: false, 
      items: [ 
        {
          text: 'White Paper',
          link: '/for-developers/white-paper',
        },
        { 
          text: 'Architecture', 
          link: '/for-developers/architecture', 
        }, 
        { 
          text: 'Powers.sol', 
          link: '/for-developers/powers', 
        },
        { 
          text: 'Law.sol', 
          link: '/for-developers/law', 
        },
        { 
          text: 'Deploy your Powers', 
          link: '/for-developers/deploy-your-powers', 
        },
        { 
          text: 'Creating a law', 
          link: '/to-do', 
        },
      ], 
    }, 
    { 
      text: 'Laws', 
      collapsed: false, 
      items: [ 
        { 
          text: 'Async', 
          collapsed: true, 
          items: [ 
            { 
              text: 'CheckExternalState', 
              link: '/to-do', 
            },
            { 
              text: 'AssignRoleWithGitCommit', 
              link: '/to-do', 
            },
            { 
              text: 'ClaimRoleWithGitCommit', 
              link: '/to-do', 
            },
            { 
              text: 'Snapshot_CheckSnapExists', 
              link: '/laws/Snapshot_CheckSnapExists', 
            },
            { 
              text: 'Snapshot_CheckSnapPassed', 
              link: '/laws/Snapshot_CheckSnapPassed', 
            },
            { 
              text: 'ZKPassportSelect', 
              link: '/to-do', 
            },
          ], 
        },
        { 
          text: 'Electoral', 
          collapsed: true, 
          items: [ 
            { 
              text: 'ElectionSelect', 
              link: '/laws/ElectionSelect', 
            },
            { 
              text: 'NStrikesRevokesRoles', 
              link: '/laws/NStrikesRevokesRoles', 
            },
            { 
              text: 'PeerSelect', 
              link: '/laws/PeerSelect', 
            },
            { 
              text: 'RenounceRole', 
              link: '/laws/RenounceRole', 
            },
            { 
              text: 'RoleByRoles', 
              link: '/laws/RoleByRoles', 
            },
            { 
              text: 'SelfSelect', 
              link: '/laws/SelfSelect', 
            },
            { 
              text: 'TaxSelect', 
              link: '/laws/TaxSelect', 
            },
            { 
              text: 'VoteInOpenElection', 
              link: '/laws/VoteInOpenElection', 
            },
          ], 
        },
        { 
          text: 'Executive', 
          collapsed: true, 
          items: [ 
            { 
              text: 'AdoptLaws', 
              link: '/laws/AdoptLaws', 
            },
            { 
              text: 'BespokeActionAdvanced', 
              link: '/laws/BespokeActionAdvanced', 
            },
            { 
              text: 'BespokeActionSimple', 
              link: '/laws/BespokeActionSimple', 
            },
            { 
              text: 'OpenAction', 
              link: '/laws/OpenAction', 
            },
            { 
              text: 'PresetMultipleActions', 
              link: '/laws/PresetMultipleActions', 
            },
            { 
              text: 'PresetSingleAction', 
              link: '/laws/PresetSingleAction', 
            },
            { 
              text: 'StatementOfIntent', 
              link: '/laws/StatementOfIntent', 
            },
          ], 
        }, 
        { 
          text: 'Integrations', 
          collapsed: true, 
          items: [ 
            { 
              text: 'AlloCreateRPFGPool', 
              link: '/to-do', 
            },
            { 
              text: 'AlloDistribute', 
              link: '/to-do', 
            },
            { 
              text: 'AlloRPFGGovernance', 
              link: '/to-do', 
            },
            { 
              text: 'GovernorCreateProposal', 
              link: '/laws/GovernorCreateProposal', 
            },
            { 
              text: 'GovernorExecuteProposal', 
              link: '/laws/GovernorExecuteProposal', 
            },
            { 
              text: 'TreasuryPoolGovernance', 
              link: '/to-do', 
            },
            { 
              text: 'TreasuryPoolTransfer', 
              link: '/to-do', 
            },
            { 
              text: 'TreasuryRoleWithTransfer', 
              link: '/to-do', 
            },
          ], 
        },
      ], 
    }, 
    { 
      text: 'Organisations', 
      collapsed: false, 
      items: [ 
        {
          text: 'Power 101',
          link: '/organisations/powers101',
        },
        {
          text: 'Power 102',
          link: '/organisations/powers102',
        },
        { 
          text: 'Power Base', 
          link: '/organisations/powerBase', 
        }, 
        { 
          text: 'Powers To Nouns', 
          link: '/organisations/powers2Nouns', 
        },
        { 
          text: 'Bridged Powers', 
          link: '/organisations/bridgedPowers', 
        },
      ], 
    }, 
  ],
})
