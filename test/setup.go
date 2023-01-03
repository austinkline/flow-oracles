package test

import (
	"fmt"
	"os"
)

var (
	flowRoot string
)

const (
	Service   = "account"
	Requester = "requester"

	ServiceAddress   = "f8d6e0586b0a20c7"
	RequesterAddress = "179b6b1cb6755e31"
)

var (
	RequestCreatedEvent              = fmt.Sprintf("A.%s.Oracle.RequestCreated", ServiceAddress)
	RequestFilledEvent               = fmt.Sprintf("A.%s.Oracle.RequestFilled", ServiceAddress)
	RandomNumberRequest              = fmt.Sprintf("A.%s.RandomNumberOracle.RandomNumberRequest", ServiceAddress)
	RandomIntHandlerExecutedCallback = fmt.Sprintf("A.%s.RandomIntHandler.ExecutedCallback", ServiceAddress)
	FlowTokensWithdrawn              = "A.0ae53cb6e3f42a79.FlowToken.TokensWithdrawn"
	FlowTokensDeposited              = "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited"
)

func init() {
	flowRoot = os.Getenv("FLOW_ROOT")
	err := os.Chdir(flowRoot)
	if err != nil {
		panic(err)
	}
}
