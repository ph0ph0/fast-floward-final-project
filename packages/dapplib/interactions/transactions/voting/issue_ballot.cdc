import RegistryVotingContract from Project.RegistryVotingContract

// Allows an account with an Admin resource to issue a Ballot to another user.

transaction(_signer: Address, _recipient: Address, _proposalId: UInt64, ) {
    let tenantRef: &RegistryVotingContract.Tenant{RegistryVotingContract.ITenantAdmin}
    let adminRef: &RegistryVotingContract.Admin
    prepare(signer: AuthAccount, recipient: AuthAccount) {
        self.tenantRef = signer.borrow<&RegistryVotingContract.Tenant{RegistryVotingContract.ITenantAdmin}>
            (from: RegistryVotingContract.TenantStoragePath) ?? panic("Couldn't get tenant ref")
        self.adminRef = self.tenantRef.adminRef()

        let ballot <- self.adminRef.issueBallot(_tenantRef: self.tenantRef, proposalId: _proposalId, voter: recipient.address)
        recipient.save(<- ballot, to: RegistryVotingContract.BallotStoragePath)

        log("saved ballot to storage")
    }

    execute {

    }

}