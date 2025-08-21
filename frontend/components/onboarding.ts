export interface OnboardingStep {
  title: string;
  subtitle: string;
  highlight: {
    target: string; // CSS selector or element ID
  };
  upperText: string;
  bottomText?: string;
  image: string;
  url?: string; // Optional URL to navigate to during onboarding
}

export const smallScreenOnboardingSteps: OnboardingStep[] = [
  {
    title: "Welcome to Powers Protocol",
    subtitle: "Please consider using a desktop",
    highlight: {
      target: ""
    },
    upperText: "This dApp is usable on mobile devices, but we recommend using a desktop for the best experience.",
    bottomText: "Also, the desktop version has a much better onboarding experience!",
    image: "",
    url: "/"
  }
]

export const onboardingSteps: OnboardingStep[] = [
  {
    title: "Welcome to Powers Protocol",
    subtitle: "Your governance journey starts here",
    highlight: {
      target: ""
    },
    upperText: "This introduction will help you get started with governance through the Powers dApp. You can close this window at any time. You can restart the onboarding by clicking the help button in the top right corner.",
    bottomText: "This dApp provides an interactive overview of a deployed Powers protocol. A user portal with a better user UX is coming soon!",
    image: "",
    url: "/"
  },
  {
    title: "Left Panel",
    subtitle: "Manage actions, proposals, logs and treasury",
    highlight: {
      target: "[help-nav-item='left-panel']"
    },
    upperText: "The left panel is where you handle anything to do with actions in your community.",
    image: "",
    url: "/"
  },
  {
    title: "Navigation",
    subtitle: "Navigate pages and connect to network.",
    highlight: {
      target: "[help-nav-item='navigation']"
    },
    upperText: "The navigation bar shows the latest block number, allows to connect to the network and navigate to different pages in the left panel.",
    bottomText: "The dApp automatically connects to the network where the protocol is deployed.",
    image: "",
    url: "/"
  },
  {
    title: "Governance Flow",
    subtitle: "See all your organization's laws and their relationships",
    highlight: {
      target: "[help-nav-item='']"
    },
    upperText: "The interactive flow chart behind this card shows all your organization's laws and their relationships. Each node represents a law, and the connections show dependencies between them.",
    bottomText: "It also shows where a specific action is in a governance path.",
    image: "",
    url: "/"
  },
  {
    title: "Home Screen",
    subtitle: "Latest executed actions, active proposals, assets and the roles",
    highlight: {
      target: "[help-nav-item='home-screen']"
    },
    upperText: "The home screen is the first thing you see when you log in. It shows the latest executed actions, active proposals, assets and the roles your wallet has.",
    image: "",
    url: "/"
  },
  {
    title: "Actions",
    subtitle: "Manage a Law's action",
    highlight: {
      target: "[help-nav-item='law-input']"
    },
    upperText: "When you click on a law, you can see the action that is associated with it. Each law needs a unique nonce and description as input for an action. Any additional input parameters will appear above the nonce field.",
    bottomText: "This (or similar) error messages can show very quickly. Don't be discouraged, just try again.",
    image: "/onboarding/error2.png",
    url: "/laws/1"
  },
  {
    title: "Load previous action",
    subtitle: "See previous actions executed for a law",
    highlight: {
      target: "[help-nav-item='latest-executions']"
    },
    upperText: "You can click on the date to load this action and see details of its path to execution.",
    image: "",
    url: "/laws/1"
  },
  {
    title: "Run Checks",
    subtitle: "Check if conditions are met",
    highlight: {
      target: "[help-nav-item='run-checks']"
    },
    upperText: "This button will run the checks for the action. It will also show the status of the action in the flow chart behind this card.",
    image: "/onboarding/statusAction.png",
    url: "/laws/1"
  },
  {
    title: "Propose or vote",
    subtitle: "Propose or vote on a proposed action (optional)",
    highlight: {
      target: "[help-nav-item='propose-or-vote']"
    },
    upperText: "If execution is conditional on a passed vote, a button will appear to either propose or vote on a proposed action.",
    image: "/onboarding/optionalProposalButtons.png",
    url: "/laws/1"
  },
  {
    title: "Voting",
    subtitle: "Vote on a proposal",
    highlight: {
      target: "[help-nav-item='propose-or-vote']"
    },
    upperText: "The view proposal button will take you to the proposal voting page. You will be able to vote on an action and see the status of the vote.",
    image: "/onboarding/voting.png",
    url: "/laws/1"
  },
  {
    title: "Execute an action",
    subtitle: "When all conditions are met, execute an action",
    highlight: {
      target: "[help-nav-item='execute-action']"
    },
    upperText: "This button will execute the action. It is only enabled if all law conditions are met. When disabled, the button will give you a reason why the action cannot be executed.",
    image: "",
    url: "/laws/1"
  }, 
  {
    title: "Proposals",
    subtitle: "Fetch all proposals",
    highlight: {
      target: "[help-nav-item='navigation-pages']"
    },
    upperText: "This page shows all proposals for the organization.",
    image: "",
    url: "/proposals"
  },
  {
    title: "Logs",
    subtitle: "Fetch all logs",
    highlight: {
      target: "[help-nav-item='navigation-pages']"
    },
    upperText: "This page shows all execution logs for the organization.",
    image: "",
    url: "/logs"
  },
  {
    title: "Treasury",
    subtitle: "Manage your assets",
    highlight: {
      target: "[help-nav-item='navigation-pages']"
    },
    upperText: "This page shows the organization's assets and financial resources.",
    image: "",
    url: "/treasury"
  },
  {
    title: "That's it",
    subtitle: "Play around and discover your Powers",
    highlight: {
      target: ""
    },
    upperText: "Now its your turn to play around and discover the Powers protocol.",
    bottomText: " Want to try your own organisation and get the admin role? Visit powers-protocol.vercel.app/#deploy and deploy your own organisation.",
    image: "",
    url: "/"
  },
];
