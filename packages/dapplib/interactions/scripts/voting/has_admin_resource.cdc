import RegistryService from Project.RegistryService
import RegistryVotingContract from Project.RegistryVotingContract

// Checks to see if an account has an Admin resource and therefore a Tenant as well

pub fun main(account: Address): Bool {
    let tenantRef = getAccount(account).getCapability(RegistryVotingContract.TenantPublicPath)
                        .borrow<&RegistryVotingContract.Tenant{RegistryVotingContract.ITenantAdmin}>()

    if tenantRef == nil {
        return false
    }

    let adminRef = tenantRef.adminRef()

    if adminRef == nil {
        return false
    } else {
        return true
    }
    return false
} 