import Oracle from "../../contracts/Oracle.cdc"

transaction(requestID: UInt64, res: Int) {
    let executor: &Oracle.Executor

    prepare(acct: AuthAccount) {
        self.executor = acct.borrow<&Oracle.Executor>(from: Oracle.StoragePath) ?? panic("executor not found")
    }

    execute {
        self.executor.executeRequest(requestID, res: res)
    }
}