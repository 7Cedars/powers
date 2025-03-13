<a name="readme-top"></a>

[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/7Cedars/powers"> 
    <img src="public/logo.png" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">Powers</h3>
  <p align="center">
    A role restricted governance protocol for DAOs
    <br />
    <!--NB: TO DO -->  
    <a href="/solidity">Solidity protocol</a> ·
    <a href="https://sepolia.arbiscan.io/address/0x001a6a16d2fc45248e00351314bce898b7d8578f">Proof of Concept (Arbiscan)</a> ·
    <a href="https://powers.vercel.app/">Proof of Concept (dApp)</a>
  </p>
</div>

<div align="center">
  For an introduction into the protocol, see
  
   <a href="https://www.tella.tv/video/powers-1-aijc"><b> the 2 minute project pitch</b> </a> or <a href="https://www.tella.tv/video/powers-solving-dao-governance-challenges-bis6"><b> the 15 minute explanation</b></a>.

</div>

<!-- TABLE OF CONTENTS --> 
<!-- NB! Still needs to be adapted --> 
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about">About</a></li>
    <li><a href="#advantages">Advantages</a></li>
    <li><a href="#protocol-architecture">Protocol Architecture</a></li>
    <li><a href="#important-files-and-folders">Important files and folders</a></li>
    <li><a href="#built-with">Built With</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About
Powers restricts governance processes along access roles.

## Advantages
In comparison to existing governance protocols, Powers improves the scalability, security and decentralisation of on-chain governance.
- _Scalability._ Powers creates a governance process where DAO members only vote on proposals that concern their roles. Role specification is a battle tested approach to enable the seamless scaling of small DAOs into larger ones.  
- _Security._ Powers allows for the creation of checks and balances between roles. The more checks and balances a DAO implements in its governance structure, the better it will be protected against hostile governance take overs. 
- _Decentralisation._  Powers enables DAOs to divide their community in groups (such as builders, token holders, users) and give each groups different, restricted, governance powers. Using roles to separate powers in governance is a tried and true approach to safeguarding decentralisation of (social, political and economic) assets in light of their tendency to centralise around informal elites.
- _Multipliers._ Above all else, Powers creates multipliers between decentralisation, efficiency and security. In Powers, increased decentralisation leads to more efficiency and more security. A focus on security will also increase decentralisation of DAO governance, etc.     

## Protocol Architecture 
For now, the protocol does not have extensive documentation. Instead, you can do the following 
- Watch the <a href="www.tella.tv/video/powers-solving-dao-governance-challenges-bis6"><b> 15 minute explanation</b></a>.
- Read <a href="/solidity"> `/solidity/README.md`</a>. 
- Then read through the code of `solidity/src/Powers.sol`, `solidity/src/IPowers.sol` and `solidity/src/Law.sol` and read through their code and natspecs.  

More extensive documentation will be created asap. 

## Important files and folders

```
.
├── frontend          # App workspace
|    ├── README.md    # All information needed to run the dApp locally. 
│    └── ...
│
├── public            # Images
|
├── solidity          # Contains all the contracts, interfaces and tests. 
│    ├── README.md    # All information needed to run contracts locally, test and deploy contracts. It also gives more detailed information on the protocol itself. 
│    └── ...                     
| 
├── LICENSE
└── README.md         # This file
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With
<!-- See for a list of badges: https://github.com/Envoy-VC/awesome-badges -->
<!-- * [![React][React.js]][React-url]  -->
* Solidity 0.8.26
* Foundry 0.2.0
* OpenZeppelin 5.0.2
* React 18
* NextJS 14
* Tailwind css
* Wagmi / viem
* Privy.io

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
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
