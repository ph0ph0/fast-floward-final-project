import RegistryVotingContract from Project.RegistryVotingContract

// Allows an account with an Admin resource to issue a Ballot to another user.

transaction(proposalId: UInt64, recipient: Address) {
    let tenantRef: RegistryVotingContract.Tenant{ITenantAdmin}
    prepare(signer: AuthAccount) {
        self.tenantRef = signer.borrow<&RegistryVotingContract.Tenant{RegistryVotingContract.ITenantAdmin}>(from: RegistryVotingContract.TenantStoragePath)
    }

    execute {
        self.tenantRef.issueBallot(proposalId: proposalId, voter: recipient)
    }

}