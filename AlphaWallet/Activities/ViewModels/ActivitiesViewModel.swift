// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import UIKit

//hhh look for transaction
struct ActivitiesViewModel {
    private var formatter: DateFormatter {
        return Date.formatter(with: "dd MMM yyyy")
    }
    private var items: [(date: String, activities: [Activity])] = []

    init(activities: [Activity] = []) {
        var newItems: [String: [Activity]] = [:]

        //hhh remove
        //hhhh How do we get a date for each event?
        items = [(date: "12 dec 2019", activities: activities)]

        //hhhh implement
        //for transaction in transactions {
        //    let date = formatter.string(from: transaction.date)

        //    var currentItems = newItems[date] ?? []
        //    currentItems.append(transaction)
        //    newItems[date] = currentItems
        //}
        ////TODO. IMPROVE perfomance
        //let tuple = newItems.map { (key, values) in return (date: key, transactions: values.sorted { $0.date > $1.date }) }
        //items = tuple.sorted { (object1, object2) -> Bool in
        //    return formatter.date(from: object1.date)! > formatter.date(from: object2.date)!
        //}
    }

    var backgroundColor: UIColor {
        Colors.appWhite
    }

    var headerBackgroundColor: UIColor {
        GroupedTable.Color.background
    }

    var headerTitleTextColor: UIColor {
        GroupedTable.Color.title
    }

    var headerTitleFont: UIFont {
        Fonts.tableHeader
    }

    var numberOfSections: Int {
        items.count
    }

    func numberOfItems(for section: Int) -> Int {
        items[section].activities.count
    }

    func item(for row: Int, section: Int) -> Activity {
        items[section].activities[row]
    }

    func titleForHeader(in section: Int) -> String {
        let value = items[section].date
        //hhh implement
        //let date = formatter.date(from: value)!
        //if NSCalendar.current.isDateInToday(date) {
        //    return R.string.localizable.today().localizedUppercase
        //}
        //if NSCalendar.current.isDateInYesterday(date) {
        //    return R.string.localizable.yesterday().localizedUppercase
        //}
        return value.localizedUppercase
    }
}

