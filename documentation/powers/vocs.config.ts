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
              text: 'AIAnalysis', 
              link: '/laws/async/AIAnalysis', 
            },
            { 
              text: 'AiCcipProxy', 
              link: '/laws/async/AiCcipProxy', 
            },
            { 
              text: 'RoleByGitCommit', 
              link: '/laws/async/RoleByGitCommit', 
            },
            { 
              text: 'Snapshot_CheckSnapExists', 
              link: '/laws/async/Snapshot_CheckSnapExists', 
            },
            { 
              text: 'Snapshot_CheckSnapPassed', 
              link: '/laws/async/Snapshot_CheckSnapPassed', 
            },
            { 
              text: 'ZKPassportSelect', 
              link: '/laws/async/ZKPassportSelect', 
            },
          ], 
        },
        { 
          text: 'Electoral', 
          collapsed: true, 
          items: [ 
            { 
              text: 'BuyAccess', 
              link: '/laws/electoral/BuyAccess', 
            },
            { 
              text: 'ElectionSelect', 
              link: '/laws/electoral/ElectionSelect', 
            },
            { 
              text: 'NStrikesRevokesRoles', 
              link: '/laws/electoral/NStrikesRevokesRoles', 
            },
            { 
              text: 'PeerSelect', 
              link: '/laws/electoral/PeerSelect', 
            },
            { 
              text: 'RenounceRole', 
              link: '/laws/electoral/RenounceRole', 
            },
            { 
              text: 'RoleByRoles', 
              link: '/laws/electoral/RoleByRoles', 
            },
            { 
              text: 'SelfSelect', 
              link: '/laws/electoral/SelfSelect', 
            },
            { 
              text: 'TaxSelect', 
              link: '/laws/electoral/TaxSelect', 
            },
            { 
              text: 'VoteInOpenElection', 
              link: '/laws/electoral/VoteInOpenElection', 
            },
          ], 
        },
        { 
          text: 'Executive', 
          collapsed: true, 
          items: [ 
            { 
              text: 'AdoptLaws', 
              link: '/laws/executive/AdoptLaws', 
            },
            { 
              text: 'GovernorCreateProposal', 
              link: '/laws/executive/GovernorCreateProposal', 
            },
            { 
              text: 'GovernorExecuteProposal', 
              link: '/laws/executive/GovernorExecuteProposal', 
            },
          ], 
        }, 
        { 
          text: 'Multi', 
          collapsed: true, 
          items: [ 
            { 
              text: 'BespokeActionAdvanced', 
              link: '/laws/multi/BespokeActionAdvanced', 
            },
            { 
              text: 'BespokeActionSimple', 
              link: '/laws/multi/BespokeActionSimple', 
            },
            { 
              text: 'OpenAction', 
              link: '/laws/multi/OpenAction', 
            },
            { 
              text: 'PresetMultipleActions', 
              link: '/laws/multi/PresetMultipleActions', 
            },
            { 
              text: 'PresetSingleAction', 
              link: '/laws/multi/PresetSingleAction', 
            },
            { 
              text: 'StatementOfIntent', 
              link: '/laws/multi/StatementOfIntent', 
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
