import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

import Oracle from  "../../contracts/Oracle.cdc"
import RandomNumberOracle from "../../contracts/RandomNumberOracle.cdc"

import RandomIntHandler from "../../contracts/testing/RandomIntHandler.cdc"

transaction(max: Int, expiresAfter: UFix64) {
    let paymentVault: @FungibleToken.Vault

    prepare(acct: AuthAccount) {
        let paymentProvider = acct.borrow<&{FungibleToken.Provider, FungibleToken.Balance}>(from: /storage/flowTokenVault) 
            ?? panic("could not borrow payment vault")
        self.paymentVault <- paymentProvider.withdraw(amount: Oracle.executionFee)
    }

    execute {
        let block = getCurrentBlock()
        let c: {Oracle.Callable} = RandomIntHandler.Callable()
        let req <- RandomNumberOracle.createRandomIntRequest(callable: c, max: max, payment: <-self.paymentVault, deadline: block.timestamp + 100000000.0)

        Oracle.addRequest(r: <-req)
    }
}