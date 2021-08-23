import RegistryInterface from Project.RegistryInterface
import RegistryService from Project.RegistryService

pub contract RegistryVotingContract: RegistryInterface {

    // Questions:
    // 1) The tenant registers with the Registry Service and receives an AuthNFT in return. They are then able to use that AuthNFT to access any 
    // contract in the RS. The question is: Is the Registry Service one huge repo that devs send their Registry Contracts to, or does each 
    // developer have their own Registry Service?

    // Maps an address (of the customer/DappContract) to the amount
    // of tenants they have for a specific RegistryContract.
    access(contract) var clientTenants: {Address: UInt64}

    pub resource interface ITenantAdmin {
        access(contract) var totalProposals: UInt64
        access(contract) fun incrementTotalProposals():UInt64
    }
   
    // Tenant
    //
    // Requirement that all conforming multitenant smart contracts have
    // to define a resource called Tenant to store all data and things
    // that would normally be saved to account storage in the contract's
    // init() function
    // 
    pub resource Tenant: ITenantAdmin {

        pub var totalProposals: UInt64

        access(contract) fun incrementTotalProposals(): UInt64 {
            self.totalProposals = self.totalProposals + 1
            return self.totalProposals
        }

        init() {
            self.totalProposals = 0
        }
    }

    // instance
    // instance returns an Tenant resource.
    //
    pub fun instance(authNFT: &RegistryService.AuthNFT): @Tenant {
        let clientTenant = authNFT.owner!.address
        if let count = self.clientTenants[clientTenant] {
            self.clientTenants[clientTenant] = self.clientTenants[clientTenant]! + (1 as UInt64)
        } else {
            self.clientTenants[clientTenant] = (1 as UInt64)
        }

        return <-create Tenant()
    }

    // getTenants
    // getTenants returns clientTenants.
    //
    pub fun getTenants(): {Address: UInt64} {
        return self.clientTenants
    }

    // Named Paths
    //
    pub let TenantStoragePath: StoragePath
    pub let TenantPublicPath: PublicPath

    pub struct Proposal {
        // proposalId is incremented each time a Proposal is created
        pub let proposalId: UInt64
        pub let proposalDescription: String
        pub let proposalStatus: Bool
        // votePool: Pool of voters allowed to vote
        pub let totalVotes: Int32
        // voteCount: Sum of all votes. If positive, majority in favour, if negative, majority against.
        pub let voteSum: Int32
        // votedOnBy: Addresses that have voted
        pub let votedOnBy: [Address]
        // pub let expiry: UInt256?



        init(_proposalId: UInt64,  _proposalDescription: String) {
            self.proposalId = _proposalId
            self.proposalDescription = _proposalDescription
            self.proposalStatus = true
            self.totalVotes = 0
            self.voteSum= 0
            self.votedOnBy = []

        }
    }

    // Admin resource is what the owner uses to control the proposals and the voting.
    pub resource Admin {
        pub fun createProposal(_tenantRef: &Tenant{ITenantAdmin}, proposalDes: String) {
            let proposalId = _tenantRef.incrementTotalProposals()
            
            let proposal = Proposal(_proposalId: proposalId, _proposalDescription: proposalDes)

        }
    }

    // These are issued by the Admin to addresses and allows those addresses to vote on proposals.
    pub resource Ballots {

    }


    init() {
        // Initialize clientTenants
        self.clientTenants = {}

        // Set Named paths
        self.TenantStoragePath = /storage/RegistryVotingContractTenant
        self.TenantPublicPath = /public/RegistryVotingContractTenant
    }
}