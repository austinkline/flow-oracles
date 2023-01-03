import Oracle from "../contracts/Oracle.cdc"

pub struct RequestDetails {
    pub let type: String
    pub let details: AnyStruct?

    init(type: String, details: AnyStruct?) {
        self.type = type
        self.details = details
    }
}

pub fun main(requestID: UInt64): RequestDetails {
    let executor = Oracle.getExecutorPublic()
    let request = executor.borrowRequest(requestID) ?? panic("request not found")

    let details = RequestDetails(type: request.getType().identifier, details: request.getDetails())
    return details
}
 