import Oracle from "../../contracts/Oracle.cdc"
import RandomNumberOracle from "../../contracts/RandomNumberOracle.cdc"

transaction {
    let admin: &Oracle.Executor
    prepare(acct: AuthAccount) {
        self.admin = acct.borrow<&Oracle.Executor>(from: Oracle.StoragePath) ?? panic("oracle not found")
    }

    execute {
        let oracleType = Type<@RandomNumberOracle.RandomNumberRequest>()
        self.admin.enableRequestType(oracleType)
    }
}