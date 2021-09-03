import RegistryVotingContract from Project.RegistryVotingContract

// Allows an Admin to create a new proposal.

transaction(proposalDesc: String) {

    let tenantRef: &RegistryVotingContract.Tenant{ITenantAdmin}
    let adminRef: &RegistryVotingContract.Admin

    prepare(acct: AuthAccount){

        // If this is our first proposal, then we need to move our

        self.tenantRef = acct.borrow<&RegistryVotingContract.Tenant{ITenantAdmin}>(from: RegistryVotingContract.TenantStoragePath) 
            ?? panic("Couldn't borrow the tenant resource")

        self.adminRef = acct.borrow<&RegistryVotingContract.Admin>(from: RegistryVotingContract.AdminStoragePath)
            ?? panic("Couldn't borrow the admin resource")
    }

    execute{
        self.tenantRef.createProposal(_tenantRef: tenantRef, proposalDes: proposalDesc)
    }

    post{}
}