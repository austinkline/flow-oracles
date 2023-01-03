package rng

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"

	"github.com/austinkline/flow-oracles/test"
	"github.com/austinkline/flow-oracles/test/helper/setup"
)

const (
	randIntMaxArg = 1000
)

var (
	randomIntArgs = overflow.WithArgsMap(map[string]interface{}{"max": randIntMaxArg, "expiresAfter": 100.0})
)

func TestCreateRandomIntRequest(t *testing.T) {
	flow, err := setup.GetFlowWithSetup()
	assert.Nil(t, err)

	res := flow.Tx("rng/create_random_int_request", overflow.WithSignerServiceAccount(), randomIntArgs).Print()
	assert.Nil(t, res.Err)

	flowTokensWithdrawn := res.Events[test.FlowTokensWithdrawn][0]
	amount := flowTokensWithdrawn.Fields["amount"].(float64)
	assert.Equal(t, amount, 0.1)

	requestCreated := res.Events[test.RequestCreatedEvent][0]
	assert.Equal(t, requestCreated.Fields["type"].(string), test.RandomNumberRequest)
}

func TestFillRandomIntRequest(t *testing.T) {
	flow, _ := setup.GetFlowWithSetup()

	res := flow.Tx("rng/create_random_int_request", overflow.WithSignerServiceAccount(), randomIntArgs).Print()
	assert.Nil(t, res.Err)

	requestCreated := res.Events[test.RequestCreatedEvent][0]
	requestID := requestCreated.Fields["uuid"].(uint64)
	args := overflow.WithArgsMap(map[string]interface{}{"requestID": requestID})

	scriptRes := flow.Script("get_request_details", args)
	assert.Nil(t, scriptRes.Err)
	m := scriptRes.Output.(map[string]interface{})
	requestType := m["type"].(string)
	details := m["details"].(map[string]interface{})

	assert.Equal(t, test.RandomNumberRequest, requestType)
	assert.Equal(t, details["max"].(int), randIntMaxArg)

	responseNum := 5
	executeRequestArgs := overflow.WithArgsMap(map[string]interface{}{"requestID": requestID, "res": responseNum})
	er := flow.Tx("rng/execute_random_int_request", executeRequestArgs, overflow.WithSignerServiceAccount()).Print()
	assert.Nil(t, er.Err)

	callbackEvent := er.Events[test.RandomIntHandlerExecutedCallback][0]
	callbackVal := callbackEvent.Fields["val"].(int)
	assert.Equal(t, responseNum, callbackVal)

	requestFilledEvent := er.Events[test.RequestFilledEvent][0]
	filledUuid := requestFilledEvent.Fields["uuid"].(uint64)
	assert.Equal(t, requestID, filledUuid)

	filledType := requestFilledEvent.Fields["type"].(string)
	assert.Equal(t, test.RandomNumberRequest, filledType)

	tokensDepositedEvent := er.Events[test.FlowTokensDeposited][0]
	depAmount := tokensDepositedEvent.Fields["amount"].(float64)
	assert.Equal(t, 0.1, depAmount)
	depositedTo := tokensDepositedEvent.Fields["to"].(string)
	assert.Equal(t, fmt.Sprintf("0x%s", test.ServiceAddress), depositedTo)
}
