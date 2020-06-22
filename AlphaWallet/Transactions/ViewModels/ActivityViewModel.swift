// Copyright © 2020 Stormbird PTE. LTD.

import UIKit
import BigInt

struct ActivityViewModel {
    let activity: Activity

    var title: String {
        R.string.localizable.activityTabbarItemTitle()
    }

    var backgroundColor: UIColor {
        Screen.TokenCard.Color.background
    }

    //hhhhhh remove?
    var text: String {
        let convertor = AssetAttributeToJavaScriptConvertor()
        var values: [AttributeId: String] = .init()
        for (name, value) in activity.values.token.merging(activity.values.card, uniquingKeysWith: { _, new in new }) {
            if let value = convertor.formatAsTokenScriptJavaScript(value: value) {
                values[name] = value
            }
        }

        let amount = EtherNumberFormatter.plain.string(from: BigInt(values["amount"]!)!)
        let to = values["to"]!
        let nameValue = values["name"]
        return "\(activity.name) \(nameValue). \(amount) to: \(to)"
    }
}
