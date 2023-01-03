package setup

import (
	"github.com/bjartek/overflow"
	"github.com/onflow/flow-cli/pkg/flowkit/config"

	_ "github.com/austinkline/flow-oracles/test"
)

var (
	builderOptions *overflow.OverflowBuilder
)

func GetFlowWithSetup() (flow *overflow.OverflowState, err error) {
	flow, err = builderOptions.StartE()
	if err != nil {
		panic(err)
	}

	res := flow.Tx("admin/enable_rng_oracle", overflow.WithSignerServiceAccount()).Print(overflow.WithoutEvents())
	if res.Err != nil {
		err = res.Err
		flow = nil
		return
	}
	return
}

func init() {
	options := []overflow.OverflowPrinterOption{overflow.WithoutEvents(), overflow.WithoutId(), overflow.WithoutMeter(0)}

	builderOptions = &overflow.OverflowBuilder{
		Network:                             "emulator",
		InMemory:                            true,
		DeployContracts:                     true,
		GasLimit:                            9999,
		Path:                                ".",
		TransactionFolderName:               "transactions",
		ScriptFolderName:                    "scripts",
		LogLevel:                            0,
		InitializeAccounts:                  true,
		PrependNetworkName:                  true,
		ServiceSuffix:                       "account",
		ConfigFiles:                         config.DefaultPaths(),
		FilterOutEmptyWithDrawDepositEvents: true,
		FilterOutFeeEvents:                  true,
		GlobalEventFilter:                   overflow.OverflowEventFilter{},
		StopOnError:                         false,
		PrintOptions:                        &options,
		NewAccountFlowAmount:                0.0,
		TransactionFees:                     false,
	}
}
