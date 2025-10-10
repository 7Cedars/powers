Powers 101 SpecificationOverviewPowers 101 is an introductory governance template designed as an ideal starting point for users new to the Powers protocol. It provides a lightweight, foundational structure for communities seeking a simple and accessible governance model. The model establishes a basic two-role structure—a Guardian with administrative capabilities and a Member role that is open for anyone to join. This minimalist setup is deliberately chosen to lower the barrier to entry, allowing for straightforward community engagement and basic governance actions without the complexity of more advanced systems. It's perfect for projects in their early stages, enabling them to grow their community first and evolve their governance model later.Governance OverviewThis diagram illustrates the relationship between the roles (Actors) and the actions they are permitted to perform (Laws).graph TD
    subgraph Actors
        A[Guardian]
        B[Member]
        C[Public]
    end

    subgraph "Electoral Laws"
        D[Join the Organisation (SelfSelect)]
        E[Renounce a Role (RenounceRole)]
        F[Assign/Revoke Membership (RoleByRoles)]
    end

    subgraph "Executive Laws"
        G[Adopt Laws (AdoptLaws)]
    end

    subgraph "Multi-purpose Laws"
        H[Statement of Intent (StatementOfIntent)]
    end

    C -- can execute --> D
    A -- can execute --> E
    B -- can execute --> E
    A -- can execute --> F
    A -- can execute --> G
    B -- can execute --> H
Actors (Roles)The Powers 101 organisation defines two primary roles, creating a clear distinction between administrative control and community participation.RoleDescriptionGuardianThe primary administrative role for the organisation. The address that deploys the contract is automatically assigned this role. The Guardian is responsible for high-level actions like adopting new laws and acts as a moderator by managing the membership of the DAO, with the power to both assign and revoke the Member role.MemberA standard participant in the organisation. This role is open and can be acquired via a public-facing law, allowing for permissionless entry. The primary function of a Member is to make their voice heard through on-chain statements of intent, allowing them to signal views and propose ideas in a transparent and verifiable manner without complex voting mechanisms.Powers (Laws)The Powers 101 organisation includes five foundational laws to facilitate its simple yet effective governance structure. These laws provide the core functionalities for administration, membership, and participation.LawDescriptionPermissionsAdopt Laws (AdoptLaws)Provides a mechanism for proposing and integrating new laws, which enables the evolution of the organisation's governance framework over time. For example, the Guardian could use this to adopt new laws for managing a treasury.GuardianAssign/Revoke Membership (RoleByRoles)Grants the Guardian the direct authority to manage the roster of Members. This provides a basic moderation tool to onboard contributors or remove bad actors.GuardianStatement of Intent (StatementOfIntent)Enables members to create formal, non-binding on-chain proposals. It serves as a powerful tool for community signalling, informal polls, or making a public statement that is permanently recorded without triggering any executable actions.MemberJoin the Organisation (SelfSelect)Makes the organisation open by allowing any external user to voluntarily assign themselves the Member role. This permissionless entry is key to fostering organic community growth.Public (Any Address)Renounce a Role (RenounceRole)Provides an essential exit mechanism, permitting any user holding a role (Guardian or Member) to voluntarily renounce it at any time. This respects user autonomy, allowing individuals to leave the community or step down from a position cleanly.Guardian, MemberInitialisation ParametersUpon deployment, the Powers 101 organisation is configured with a clear and simple initial state designed for ease of use and immediate functionality.ParameterValueInitial GuardianThe address of the deployer is programmatically assigned the Guardian role, placing initial trust and responsibility on the founding entity.Initial MembersThe organisation is intentionally deployed with no members assigned. This reinforces the opt-in nature of the community, ensuring all participants have actively chosen to join via the SelfSelect law.Deployment SummaryThis sequence diagram illustrates the on-chain actions performed to construct the complete governance structure during deployment.sequenceDiagram
    participant D as Deployer
    participant P as Powers Contract

    D->>P: 1. Deploy new Powers contract instance
    D->>P: 2. Create "Guardian" & "Member" roles
    D->>P: 3. Assign "Guardian" role to Deployer
    D->>P: 4. Adopt 5 foundational laws
    D->>P: 5. Configure law permissions
A new, independent Powers contract is deployed to the blockchain, serving as the core of the new organisation.The "Guardian" and "Member" roles are formally created and registered within the Powers contract.The deployer's address is immediately assigned the "Guardian" role, granting initial administrative authority.Finally, the five foundational laws are adopted and their permissions are configured, linking each law's functionality to the appropriate roles and making the organisation fully operational.