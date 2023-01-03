import Oracle from "../Oracle.cdc"

pub contract RandomIntHandler {
    pub event ExecutedCallback(val: Int)

    pub struct Callable: Oracle.Callable {
        pub fun callback(_ res: AnyStruct?) {
            let num = res! as! Int
            emit ExecutedCallback(val: num)
        }

        pub init() {}
    }
}