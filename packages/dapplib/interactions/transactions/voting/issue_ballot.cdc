import RegistryVotingContract from Project.RegistryVotingContract

// Allows an account with an Admin resource to issue a Ballot to another user.

transaction(proposalId: UInt64, recipient: Address) {
    let tenantRef: &RegistryVotingContract.Tenant{RegistryVotingContract.ITenantAdmin}
    let adminRef: &RegistryVotingContract.Admin
    prepare(signer: AuthAccount) {
        self.tenantRef = signer.borrow<&RegistryVotingContract.Tenant{RegistryVotingContract.ITenantAdmin}>
            (from: RegistryVotingContract.TenantStoragePath) ?? panic("Couldn't get tenant ref")
        self.adminRef = self.tenantRef.adminRef()
    }

    execute {
        let ballot <- self.adminRef.issueBallot(_tenantRef: self.tenantRef, proposalId: proposalId, voter: recipient)
        getAccount(recipient).save(<- ballot, to: RegistryVotingContract.BallotStoragePath)

        log("saved ballot to storage")
    }

}