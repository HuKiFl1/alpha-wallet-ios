// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import BigInt

struct ActivityCellViewModel {
    private let activity: Activity
    private let server: RPCServer

    init(activity: Activity, server: RPCServer) {
        self.activity = activity
        self.server = server
    }

    var titleTextColor: UIColor {
        return Colors.appText
    }

    var title: String {
        //hhhhh maybe move into the web view since it's its responsibility?
        let convertor = AssetAttributeToJavaScriptConvertor()
        var values: [AttributeId: String] = .init()
        for (name, value) in activity.values.token.merging(activity.values.card, uniquingKeysWith: { _, new in new }) {
            if let value = convertor.formatAsTokenScriptJavaScript(value: value) {
                values[name] = value
            }
        }

        //hhhhh implement as webview and corresponding native view
        //hhh forced unwrap (to get rid of Optional in the string generated)
        let amount = EtherNumberFormatter.plain.string(from: BigInt(values["amount"]!)!)
        //hhhhh values need to be split into token and card when tracking, so that we can inject with the JavaScript callback when we have a web view
        let to = values["to"]!
        let nameValue = values["name"]
        return "\(activity.name) \(nameValue). \(amount) to: \(to)"
    }

    var titleFont: UIFont {
        return Fonts.regular(size: 17)!
    }

    var contentsBackgroundColor: UIColor {
        .white
    }

    var contentsCornerRadius: CGFloat {
        return Metrics.CornerRadius.box
    }

    var backgroundColor: UIColor {
        return Colors.appBackground
    }

    var blockChainNameFont: UIFont {
        return Screen.TokenCard.Font.blockChainName
    }

    var blockChainNameColor: UIColor {
        return Screen.TokenCard.Color.blockChainName
    }

    var blockChainNameBackgroundColor: UIColor {
        return server.blockChainNameColor
    }

    var blockChainName: String {
        return "  \(server.name)     "
    }

    var blockChainNameTextAlignment: NSTextAlignment {
        return .center
    }

    var blockChainNameCornerRadius: CGFloat {
        return Screen.TokenCard.Metric.blockChainTagCornerRadius
    }
}
