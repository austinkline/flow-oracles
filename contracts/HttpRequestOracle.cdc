import FlowToken from "./standard/FlowToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"

import Oracle from "./Oracle.cdc"

pub contract HttpRequestOracle {

    pub struct HttpRequestDetails {
        pub let method: String // TODO: enum
        pub let url: String
        pub let payload: {String: AnyStruct}?

        init(_ details: {String: AnyStruct}) {
            self.method = details["method"]! as! String
            self.url = details["url"]! as! String
            self.payload = details["payload"] as? {String: AnyStruct}
        }
    }

    pub resource HttpRequest: Oracle.Request {
        access(contract) let callable: AnyStruct{Oracle.Callable}
        access(contract) let payment: @FlowToken.Vault
        access(contract) var deadline: UFix64
        access(contract) var transactionAttempts: [String]

        pub let details: {String: AnyStruct}

        init(callable: AnyStruct{Oracle.Callable}, payment: @FlowToken.Vault, deadline: UFix64, details: {String: AnyStruct}) {
            self.callable = callable
            self.payment <- payment
            self.deadline = deadline
            self.transactionAttempts = []

            self.details = details
        }

        pub fun getDetails(): AnyStruct? {
            return self.details
        }

        access(contract) fun execute(res: AnyStruct?) {
            self.callable.callback(res)
        }

        access(contract) fun recordAttempt(_ transactionID: String) {
            self.transactionAttempts.append(transactionID)
        }

        access(contract) fun withdrawPayment(): @FlowToken.Vault {
            let tokens <- self.payment.withdraw(amount: self.payment.balance) as! @FlowToken.Vault
            return <- tokens
        }

        destroy () {
            pre {
                self.payment.balance == 0.0: "payment is not empty"
            }

            destroy self.payment
        }
    }

    pub fun createHttpRequest(callable: AnyStruct{Oracle.Callable}, url: String, method: String, payload: {String: AnyStruct}?, payment: @FungibleToken.Vault, deadline: UFix64): @HttpRequest {
        let details: {String: AnyStruct} = {
            "method": method,
            "url": url,
            "payload": payload
        }

        let p <-payment as! @FlowToken.Vault
        let request <- create HttpRequest(callable: callable, payment: <-p, deadline: deadline, details: details)
        return <-request
    }
}