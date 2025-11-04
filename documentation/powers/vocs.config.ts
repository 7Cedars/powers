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
          link: '/to-do', 
        },
        { 
          text: 'Law.sol', 
          link: '/to-do', 
        },
        { 
          text: 'Deploy your Powers', 
          link: '/to-do', 
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
              link: '/to-do', 
            },
            { 
              text: 'AiCcipProxy', 
              link:'/to-do', 
            },
            { 
              text: 'RoleByGitCommit', 
              link: '/to-do', 
            },
            { 
              text: 'Snapshot_CheckSnapExists', 
              link: '/to-do', 
            },
            { 
              text: 'Snapshot_CheckSnapPassed', 
              link: '/to-do', 
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
              text: 'BuyAccess', 
              link: '/to-do', 
            },
            { 
              text: 'ElectionSelect', 
              link: '/to-do', 
            },
            { 
              text: 'NStrikesRevokesRoles', 
              link: '/to-do', 
            },
            { 
              text: 'PeerSelect', 
              link: '/to-do', 
            },
            { 
              text: 'RenounceRole', 
              link: '/to-do', 
            },
            { 
              text: 'RoleByRoles', 
              link: '/to-do', 
            },
            { 
              text: 'SelfSelect', 
              link: '/to-do', 
            },
            { 
              text: 'TaxSelect', 
              link: '/to-do', 
            },
            { 
              text: 'VoteInOpenElection', 
              link: '/to-do', 
            },
          ], 
        }, 
        { 
          text: 'Executive', 
          collapsed: true, 
          items: [ 
            { 
              text: 'AdoptLaws', 
              link: '/to-do', 
            },
            { 
              text: 'RevokeLaws', 
              link: '/to-do', 
            },
            { 
              text: 'BespokeActionAdvanced', 
              link: '/to-do', 
            },
            { 
              text: 'BespokeActionSimple', 
              link: '/to-do', 
            },
            { 
              text: 'OpenAction', 
              link: '/to-do', 
            },
            { 
              text: 'PresetMultipleActions', 
              link: '/to-do', 
            },
            { 
              text: 'PresetSingleAction', 
              link: '/to-do', 
            },
            { 
              text: 'StatementOfIntent', 
              link: '/to-do', 
            },
          ], 
        }, 
        { 
          text: 'Integrations', 
          collapsed: true, 
          items: [ 

            { 
              text: 'GovernorCreateProposal', 
              link: '/to-do', 
            },
            { 
              text: 'GovernorExecuteProposal', 
              link: '/to-do', 
            },
            { 
              text: 'AlloRPFGGovernance', 
              link: '/to-do', 
            },
            { 
              text: 'AlloDistribute', 
              link: '/to-do', 
            },
            { 
              text: 'AlloCreateRPGFPool', 
              link: '/to-do', 
            },
            { 
              text: 'RoleByGitCommit', 
              link: '/to-do', 
            },
            { 
              text: 'Snapshot_CheckSnapExists', 
              link: '/to-do', 
            },
            { 
              text: 'Snapshot_CheckSnapPassed', 
              link: '/to-do', 
            },
            { 
              text: 'ZKPassportSelect', 
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
