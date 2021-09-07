import RegistryInterface from Project.RegistryInterface
import RegistryService from Project.RegistryService

pub contract RegistryVotingContract: RegistryInterface {

    // ToDo:
    // 1) Add more events where appropriate

    // Events
    //
    pub event ContractInitialized()
    pub event VoteCast(voter: Address, proposalId: UInt64)
    pub event ProposalCreated(proposalId: UInt64, proposalDesc: String)
    pub event VotingClosed(proposalId: UInt64)

    // Maps an address (of the customer/DappContract) to the amount
    // of tenants they have for a specific RegistryContract.
    access(contract) var clientTenants: {Address: UInt64}

    pub resource interface ITenantAdmin {
        pub var totalProposals: UInt64
        access(contract) fun incrementTotalProposals():UInt64
        access(contract) fun addProposal(proposal: Proposal)
        access(contract) fun endVotingFor(proposalId: UInt64) 
        access(contract) fun listAllProposals(): [Proposal]
        pub fun adminRef(): &Admin
    }

    pub resource interface ITenantBallot {
        pub var totalProposals: UInt64
        access(contract) fun updateProposalWithVote(proposalId: UInt64, vote: Int32, voter: Address)

    }
   
    // Tenant
    //
    // Requirement that all conforming multitenant smart contracts have
    // to define a resource called Tenant to store all data and things
    // that would normally be saved to account storage in the contract's
    // init() function
    // 
    pub resource Tenant: ITenantAdmin, ITenantBallot {
        pub var totalProposals: UInt64
        access(self) var proposals: [Proposal]
        access(self) var finishedProposals: [Proposal]
        access(self) let voteAdmin: @Admin

        access(contract) fun listAllProposals(): [Proposal] {
            return self.proposals
        }

        access(contract) fun incrementTotalProposals(): UInt64 {
            self.totalProposals = self.totalProposals + 1
            return self.totalProposals
        }

        access(contract) fun addProposal(proposal: Proposal) {
            self.proposals.append(proposal)
            emit ProposalCreated(proposalId: proposal.proposalId, proposalDesc: proposal.proposalDescription)
        }

        access(contract) fun updateProposalWithVote(proposalId: UInt64, vote: Int32, voter: Address) {
            for prop in self.proposals {
                if (prop.proposalId == proposalId) {
                    prop.totalVotes = prop.totalVotes + 1
                    prop.voteSum = prop.voteSum + vote
                    prop.votedOnBy.append(voter)
                    emit VoteCast(voter: voter, proposalId: proposalId)
                    break
                }
            }
        }

        access(contract) fun endVotingFor(proposalId: UInt64) {
            var index = 0
            for prop in self.proposals {
                if (prop.proposalId == proposalId) {
                    prop.proposalStatus = false
                    self.finishedProposals.append(self.proposals.remove(at: index))
                    emit VotingClosed(proposalId: prop.proposalId)
                    break
                }
                index = index + 1
            }
        }

        pub fun adminRef(): &Admin {
            return &self.voteAdmin as &Admin
        }

        init() {
            self.totalProposals = 0
            self.proposals = []
            self.finishedProposals = []

            self.voteAdmin <- create Admin()
        }

        destroy() {
            destroy self.voteAdmin
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
    pub let AdminStoragePath: StoragePath
    pub let AdminPublicPath: PublicPath
    pub let BallotStoragePath: StoragePath
    pub let BallotPublicPath: PublicPath

    pub struct Proposal {
        // proposalId is incremented each time a Proposal is created
        pub let proposalId: UInt64
        pub let proposalDescription: String
        pub(set) var proposalStatus: Bool
        // votePool: Pool of voters allowed to vote
        pub(set) var totalVotes: Int32
        // voteCount: Sum of all votes. If positive, majority in favour, if negative, majority against.
        pub(set) var voteSum: Int32
        // votedOnBy: Addresses that have voted
        pub(set) var votedOnBy: [Address]
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

            _tenantRef.addProposal(proposal: proposal)
        }

        pub fun issueBallot( proposalId: UInt64, voter: Address): @Ballot {
            return <- create Ballot(_proposalId: proposalId, _voter: voter) 
        }

        pub fun closeVotingFor(proposalId: UInt64, _tenantRef: &Tenant{ITenantAdmin}) {
            _tenantRef.endVotingFor(proposalId: proposalId)
        }

        pub fun listProposals(_tenantRef: &Tenant{ITenantAdmin}): [Proposal] {
            let proposals = _tenantRef.listAllProposals()
            return proposals
        }

        pub fun createNewAdmin(): @Admin {
            return <- create Admin()
        }

    }

    // These are issued by the Admin to addresses and allows those addresses to vote on proposals.
    pub resource Ballot {
        pub let proposalId: UInt64
        pub let voter: Address

        // decision must be 1 (for) or -1 (against)
        access(account) fun vote(decision: Int32, tenantRef: &Tenant{ITenantBallot}) {
            pre {
                decision == 1 || decision == -1: "Decision must be 1 (for) or -1 (against)"
            }
            // Update proposal in tenant
            tenantRef.updateProposalWithVote(proposalId: self.proposalId, vote: decision, voter: self.voter)

            // Can the Ballot resource destroy itself after voting?

        }

        init(_proposalId: UInt64, _voter: Address) {
            self.proposalId = _proposalId
            self.voter = _voter
        }

    }

    init() {
        // Initialize clientTenants
        self.clientTenants = {}

        // Set Named paths
        self.TenantStoragePath = /storage/RegistryVotingContractTenant
        self.TenantPublicPath = /public/RegistryVotingContractTenant
        self.AdminStoragePath = /storage/VotingAdmin
        self.AdminPublicPath = /public/VotingAdmin
        self.BallotStoragePath = /storage/VotingBallot
        self.BallotPublicPath = /public/VotingBallot

        emit ContractInitialized() 
    }
}