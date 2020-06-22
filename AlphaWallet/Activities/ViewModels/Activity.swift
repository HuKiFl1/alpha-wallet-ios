// Copyright © 2020 Stormbird PTE. LTD.

import Foundation

//hhh note: TokenInstanceAction (which is an "action card") is very similar to this
struct Activity {
    let id: Int
    let server: RPCServer
    let name: String
    let eventName: String
    let blockNumber: Int
    let values: (token: [AttributeId: AssetInternalValue], card: [AttributeId: AssetInternalValue])
}

//hhh remove
extension Constants {
    static let erc20ActivitiesContract: (address: AlphaWallet.Address, server: RPCServer) = (AlphaWallet.Address(string: "0x7f1511708E51A3088e4e8505F16523300668476E")!, .rinkeby)
}
