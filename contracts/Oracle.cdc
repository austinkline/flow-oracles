import FlowToken from "./standard/FlowToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"

pub contract Oracle {
    pub event RequestCreated(uuid: UInt64, type: String, deadline: UFix64, blockHeight: UInt64)
    pub event RequestFilled(uuid: UInt64, type: String, executedOn: UFix64, blockHeight: UInt64)
    pub event RejectRequest(uuid: UInt64, type: String, attempts: [String], rejectedOn: UFix64, blockHeight: UInt64)

    pub var StoragePath: StoragePath
    pub var PublicPath: PublicPath

    pub var executionFee: UFix64
    pub var failedRequestRetries: Int

    pub struct interface Callable {
        pub fun callback(_ res: AnyStruct?)
    }

    pub resource interface Request {
        // The top-level resource to manage oracle requests. the execute command is 
        access(contract) let callable: AnyStruct{Callable}
        access(contract) let payment: @FlowToken.Vault
        access(contract) var deadline: UFix64
        access(contract) var transactionAttempts: [String]

        access(contract) fun execute(res: AnyStruct?)

        access(contract) fun recordAttempt(_ transactionID: String)
        access(contract) fun withdrawPayment(): @FlowToken.Vault

        pub fun getDetails(): AnyStruct?
    }

    pub resource interface ExecutorPublic {
        pub fun addRequest(r: @{Request})
        pub fun borrowRequest(_ id: UInt64): &AnyResource{Request}?
    }

    pub resource Executor: ExecutorPublic {
        pub let requests: @{UInt64: AnyResource{Request}}
        pub let supportedTypes: {Type: Bool}

        init() {
            self.requests <- {}
            self.supportedTypes = {}
        }

        pub fun getRequestIDs(): [UInt64] {
            return self.requests.keys
        }

        pub fun enableRequestType(_ type: Type) {
            self.supportedTypes[type] = true
        }

        pub fun revokeRequestType(_ type: Type) {
            if self.supportedTypes[type] != nil {
                self.supportedTypes.remove(key: type)
            }
        }

        pub fun addRequest(r: @{Request}) {
            pre {
                self.supportedTypes.containsKey(r.getType()): "unsupported request type"
                r.payment.balance == Oracle.executionFee: "incorrect payment balance"
            }

            emit RequestCreated(uuid: r.uuid, type: r.getType().identifier, deadline: r.deadline, blockHeight: getCurrentBlock().height)
            
            let old <- self.requests[r.uuid] <- r
            destroy old            
        }

        pub fun recordAttempt(id: UInt64, transactionID: String) {
            let req = self.borrowRequest(id) ?? panic("request not found")
            req.recordAttempt(transactionID)
        }

        pub fun executeRequest(_ id: UInt64, res: AnyStruct?) {
            let r <- self.requests.remove(key: id) ?? panic("request does not exist")
            r.execute(res: res)

            let block = getCurrentBlock()
            emit RequestFilled(uuid: r.uuid, type: r.getType().identifier, executedOn: block.timestamp, blockHeight: block.height)

            let payment <- r.withdrawPayment()
            let paymentReceiver = Oracle.account.borrow<&{FungibleToken.Receiver}>(from: /storage/flowTokenVault) ?? panic("missing flow token vault")
            paymentReceiver.deposit(from: <-payment)

            destroy r
        }

        pub fun rejectRequest(_ id: UInt64) {
            let r <- self.requests.remove(key: id) ?? panic("request does not exist")
            assert(r.transactionAttempts.length >= Oracle.failedRequestRetries)

            let payment <- r.withdrawPayment()

            let block = getCurrentBlock()
            emit RejectRequest(uuid: r.uuid, type: r.getType().identifier, attempts: r.transactionAttempts, rejectedOn: block.timestamp, blockHeight: block.height)

            let paymentReceiver = Oracle.account.borrow<&{FungibleToken.Receiver}>(from: /storage/flowTokenVault) ?? panic("missing flow token vault")
            paymentReceiver.deposit(from: <-payment)

            destroy r
        }

        pub fun borrowRequest(_ id: UInt64): &AnyResource{Request}? {
            return &self.requests[id] as &AnyResource{Request}?
        }

        destroy () {
            destroy self.requests
        }
    }

    pub fun getExecutorPublic(): &Executor{ExecutorPublic} {
        return self.account.borrow<&Executor{ExecutorPublic}>(from: Oracle.StoragePath) ?? panic("could not find executor")
    }

    pub fun addRequest(r: @AnyResource{Request}) {
        let executor = Oracle.getExecutorPublic()
        executor.addRequest(r: <-r)
    }

    init() {
        self.executionFee = 0.1
        self.failedRequestRetries = 5

        self.StoragePath = /storage/OracleExecutor
        self.PublicPath = /public/OracleExecutor

        let e <- create Executor()
        self.account.save(<-e, to: Oracle.StoragePath)
    }
 }