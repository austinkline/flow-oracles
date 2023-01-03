import FlowToken from "./standard/FlowToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"

import Oracle from "./Oracle.cdc"

pub contract RandomNumberOracle {

    pub struct RandomNumberRequestDetails {
        pub let max: Int?

        init(_ details: {String: AnyStruct}) {
            self.max = details["max"] as! Int?
        }
    }

    pub resource RandomNumberRequest: Oracle.Request {
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

    pub fun createRandomIntRequest(callable: AnyStruct{Oracle.Callable}, max: Int?, payment: @FungibleToken.Vault, deadline: UFix64): @RandomNumberRequest {
        let details: {String: AnyStruct} = {
            "max": max
        }

        let p <-payment as! @FlowToken.Vault
        let request <- create RandomNumberRequest(callable: callable, payment: <-p, deadline: deadline, details: details)
        return <-request
    }
}