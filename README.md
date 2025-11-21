<a name="readme-top"></a>

<!--
*** Attribution: thanks to @othneildrew for the Readme template!)
-->

[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/7Cedars/powers"> 
    <img src="./powers_icon_notext.svg" alt="Powers Logo" width="300" height="300">
  </a>

<h3 align="center">Powers v0.4</h3>
  <p align="center">
    Institutional governance for on-chain organisations  
    <br />
    <!--TO DO: UPDATE LINKS AFTERUPDATING ORGS -->  
    <a href=" ">6 min intro clip</a> ·
    <a href=" ">Litepaper</a> ·
    <a href="/solidity">Solidity protocol</a> ·
    <a href="https://powers-protocol.vercel.app/11155420/0x1c1ebea2840980ec3b45785c4b5672857b0dfdb9">Demo</a> ·
    <a href="https://powers-docs.vercel.app/welcome">Documentation</a>
  </p>
</div>

<!-- <div align="center">
  For an introduction into the protocol, see
   <a href="https://youtu.be/O7GGQrnQpcs"><b> the 6 minute </b> </a>
   intro.  
</div>  -->

<!-- TABLE OF CONTENTS --> 
<!-- NB! Still needs to be adapted --> 
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about">About</a></li>
    <li><a href="#use-cases">Use Cases</a></li>
    <li><a href="#deploy">Deploy</a></li>
    <li><a href="#important-files-and-folders">Important files and folders</a></li>
    <li><a href="#built-with">Built With</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About
Powers v0.4 provides institutional governance for on-chain organisations by restricting governance processes along access roles. It allows a single decision to travel along multiple stakeholders through modular, asynchronous and trustless governance paths before it is executed.

## Use Cases 

Powers v0.4 enables three key governance patterns that solve common on-chain organisation challenges:

**🔐 Devolved Responsibilities**: Create accountable governance structures where different roles can manage specific domains like working groups, grants, councils, and specialized governance bodies. Decisions are logged and can be challenged, with all funds remaining in the community treasury and programs revocable if they don't achieve intended impact.

**⚖️ Separated Powers**: Distribute decision-making across multiple roles to prevent centralization. One role can propose actions, another can veto, and a third can execute - creating checks and balances similar to legislative, judicial, and executive branches.

**🔄 On-chain Organisation Upgrades**: Upgrade existing on-chain organisations gradually without abandoning established governance. Start with minimal assets in Powers, add new roles and tasks, and transition completely when confidence grows - all while maintaining the existing organisation as a role holder.     

## Deploy locally

### Prerequisites

1. **Install Foundry** - Required for smart contract development
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Install Node.js dependencies**
   ```bash
   yarn install
   cd frontend && yarn install
   ```

### Setup and Deployment

1. **Clone and setup the repository**
   ```bash
   git clone https://github.com/7Cedars/powers.git
   cd powers
   ```

2. **Start Anvil chain** (local Ethereum development chain)
   ```bash
   anvil
   ```
   > **Note**: For detailed Anvil configuration and usage, see the [Foundry documentation](https://getfoundry.sh/introduction/getting-started#anvil)

3. **Deploy contracts and mocks**
   ```bash
   cd solidity
   make initialise-anvil
   ```
   This deploys all law contracts to your local Anvil chain.

4. **Start the frontend application**
   ```bash
   cd frontend
   yarn dev
   ```

5. **Access the application**
   - Open your browser and navigate to `http://localhost:3000`
   - Scroll down to the 'Deploy a Demo' section
   - Select a demo organisation and the "Anvil" from the chain dropdown
   - When deployment is succesful you will be able to navigate to your organisation. 

### Building Custom Laws and Organizations

For detailed information on creating your own organization, please refer to the [documentation](https://powers-docs.vercel.app/welcome):
- [Powers Protocol Guide](https://powers-docs.vercel.app/for-developers/powers)
- [Law Guide](https://powers-docs.vercel.app/for-developers/law)
- [Setting up your own organisation](https://powers-docs.vercel.app/for-developers/deploy-your-powers)

## Important files and folders

```
.
├── documentation/powers/  # Vocs Documentation
│   ... 
│   ├── for-developers/    # Developer documentation
│   ├── laws/              # Example law implementations
│   ├── organisations/     # Example organisations  
│   ├── integrations/      # Integration guides
│   └── welcome.mdx        # Welcome page documentation
│
├── frontend/         # Next.js dApp workspace
│   ├── app/          # Next.js app router pages and components
│   ├── components/   # Reusable React components
│   ├── context/      # React context providers and contract ABIs
│   ├── hooks/        # Custom React hooks
│   ├── organisation/ # Organisation deploy scripts 
│   ├── public/       # Static assets for the dApp
│   ├── utils/        # Utility functions
│   └── README.md     # Frontend setup and development guide
│
├── solidity/         # Smart contract development
│   ├── src/          # Solidity contracts and interfaces
│   ├── test/         # Foundry test files
│   ├── script/       # Deployment scripts
│   ├── broadcast/    # Deployment artifacts
│   └── README.md     # Solidity development guide
│
├── public/           # Project images and assets
│
├── package.json      # Root package configuration
└── README.md         # This file
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With
<!-- See for a list of badges: https://github.com/Envoy-VC/awesome-badges -->
<!-- * [![React][React.js]][React-url]  -->
* Powers Protocol v0.4
* Solidity 0.8.26
* Foundry 0.2.0
* OpenZeppelin 5.0.2
* React 18
* NextJS 14
* Tailwind css
* Wagmi / viem
* Privy.io

### Acknowledgements
* Invcbull Audit Group
* Arnold Almeida
* James M 
* Paulo Fonseca
* Andrei V  
* Arbitrum DAO 
* RnDAO

Powers v0.4 represents a significant evolution in institutional governance for on-chain organisations, building upon the foundational work of the community and contributors. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contributing

We welcome contributions from the community! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on how to:

- Report bugs
- Request features
- Submit pull requests
- Follow our coding standards

### Quick Start for Contributors

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Commit your changes: `git commit -m 'feat: add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

For more detailed information, please read our [Contributing Guidelines](CONTRIBUTING.md).

## Contact
Seven Cedars - [Github profile](https://github.com/7Cedars) - cedars7@proton.me

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
[issues-shield]: https://img.shields.io/github/issues/7Cedars/powers.svg?style=for-the-badge
[issues-url]: https://github.com/7Cedars/powers/issues/
[license-shield]: https://img.shields.io/github/license/7Cedars/powers.svg?style=for-the-badge
[license-url]: https://github.com/7Cedars/powers/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/linkedin_username
[product-screenshot]: images/screenshot.png
<!-- See list of icons here: https://hendrasob.github.io/badges/ -->
[Next.js]: https://img.shields.io/badge/next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white
[Next-url]: https://nextjs.org/
[React.js]: https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB
[React-url]: https://reactjs.org/
[Tailwind-css]: https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white
[Tailwind-url]: https://tailwindcss.com/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Redux]: https://img.shields.io/badge/Redux-593D88?style=for-the-badge&logo=redux&logoColor=white
[Redux-url]: https://redux.js.org/
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com 
