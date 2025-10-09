I am building a blockchain protocol for institutional governance called Powers. For the most up-to-date White Paper please see ./whitePaper.md in this folder.  

The task is to create specs for an organisation build using the Powers protocol. You will receive a general description of what the organisation should do and what existing contracts it should interact with. Your task is to develop the specs and governance system of this organisation. 

The following sources are available to you:   
- the available laws, located at the ../solidity/src/laws folder   
- mock external contracts that can be used, in the ...solidity/test/mocks folder
- example implementations at ../solidity/test/testConstitutions. For a simple organisation, see the powers101Constitution function in this file.   
- A template for an organisational spec, located at ./organisationalSpecBase.md 

In the  `Governance Flow Diagram` section, please create a mermaid digram following the examples below as strictly as possible. Please also use subheadings

```mermaid
flowchart LR
    RM(( Members )):::user0
    RF(( Funders )):::user1
    RAdmin(( Admin )):::user5

    A[#2 Propose Budget]
    B[#3 Veto Budget]
    C[#4 Set Budget]

    RM -- Vote 51% success 33% quorum --> A
    RF -- Veto 66% success 50% quorum --> B
    RAdmin -- Execute --> C

    A -- enables --> B
    A -- enables --> C
    B -- blocks --> C

    classDef user0 fill:#8dcfec
    classDef user1 fill:#f8d568
    classDef user5 fill:#ffcdd2
```

### Grant Process

```mermaid
flowchart LR
    RPublic(( Public )):::user7
    RM(( Members )):::user0
    RDoc(( Doc Contrib. )):::user2
    RFe(( Frontend Contrib. )):::user3
    RProto(( Protocol Contrib. )):::user4
    RGrantee(( Grantees )):::user6

    D[Propose Grant]
    E[Veto Grant]
    F[Allocate Grant]
    G[Request Payout]
    H[End Grant]

    RPublic -- Propose --> D
    RM -- Veto 66% success 25% quorum --> E
    RDoc -- Vote 51% success 50% quorum --> F
    RFe -- Vote 51% success 50% quorum --> F
    RProto -- Vote 51% success 50% quorum --> F
    RGrantee -- Request --> G
    RDoc -- Execute --> H
    RFe -- Execute --> H
    RProto -- Execute --> H

    D -- enables --> E
    D -- enables --> F
    E -- blocks --> F
    F -- enables --> G
    F -- enables --> H

    classDef user0 fill:#8dcfec
    classDef user2 fill:#b3e5fc
    classDef user3 fill:#c8e6c9
    classDef user4 fill:#d1c4e9
    classDef user6 fill:#f0f4c3
    classDef user7 fill:#e0e0e0
```

### Constitutional Process

```mermaid
flowchart LR
    RM(( Members )):::user0
    RF(( Funders )):::user1
    RAdmin(( Admin )):::user5

    I[Propose Law Package]
    J[Veto Law Package]
    K[Adopt Law Package]

    RM -- Vote 51% success 50% quorum --> I
    RF -- Veto 33% success 50% quorum --> J
    RAdmin -- Execute --> K

    I -- enables --> J
    I -- enables --> K
    J -- blocks --> K

    classDef user0 fill:#8dcfec
    classDef user1 fill:#f8d568
    classDef user5 fill:#ffcdd2
```

### Electoral Process

```mermaid
flowchart LR
    RPublic(( Public )):::user7
    RM(( Members )):::user0
    RAdmin(( Admin )):::user5

    L[Assign Contributor Roles]
    M[Assign Funder Role]
    N[Assign Member Role]
    O[Revoke Role]
    P[Veto Role Revocation]

    RPublic -- On-chain action --> L
    RPublic -- On-chain action --> M
    RPublic -- On-chain action --> N
    RM -- Vote 51% success 5% quorum --> O
    RAdmin -- Veto --> P

    P -- blocks --> O

    classDef user0 fill:#8dcfec
    classDef user5 fill:#ffcdd2
    classDef user7 fill:#e0e0e0
```

Thank you.   