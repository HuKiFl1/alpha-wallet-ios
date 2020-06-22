// Copyright © 2020 Stormbird PTE. LTD.

import UIKit
import StatefulViewController

//hhhhhh rename
protocol ActivitiesViewControllerDelegate: class {
    func didPressActivity(activity: Activity, in viewController: ActivitiesViewController)
}

class ActivitiesViewController: UIViewController {
    private var viewModel: ActivitiesViewModel
    private let tableView = UITableView(frame: .zero, style: .grouped)

    var paymentType: PaymentFlow?
    weak var delegate: ActivitiesViewControllerDelegate?

    init(viewModel: ActivitiesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        title = R.string.localizable.activityTabbarItemTitle()

        view.backgroundColor = self.viewModel.backgroundColor

        tableView.register(ActivityViewCell.self)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = viewModel.backgroundColor
        tableView.estimatedRowHeight = TokensCardViewController.anArbitaryRowHeightSoAutoSizingCellsWorkIniOS10
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.anchorsConstraint(to: view),
        ])

        errorView = ErrorView(onRetry: { [weak self] in
            self?.startLoading()
        })
        loadingView = LoadingView()
        //TODO move into StateViewModel once this change is global
        if let loadingView = loadingView as? LoadingView {
            loadingView.backgroundColor = Colors.appGrayLabel
            loadingView.label.textColor = Colors.appWhite
            loadingView.loadingIndicator.color = Colors.appWhite
            loadingView.label.font = Fonts.regular(size: 18)
        }
        emptyView = {
            //hhh replace?
            let view = TransactionsEmptyView()
            return view
        }()
    }

    func configure(viewModel: ActivitiesViewModel) {
        self.viewModel = viewModel
        tableView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    fileprivate func headerView(for section: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = viewModel.headerBackgroundColor
        let title = UILabel()
        title.text = viewModel.titleForHeader(in: section)
        title.sizeToFit()
        title.textColor = viewModel.headerTitleTextColor
        title.font = viewModel.headerTitleFont
        container.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        if section == 0 {
            NSLayoutConstraint.activate([
                title.anchorsConstraint(to: container, edgeInsets: .init(top: 18, left: 20, bottom: 16, right: 0))
            ])
        } else {
            NSLayoutConstraint.activate([
                title.anchorsConstraint(to: container, edgeInsets: .init(top: 4, left: 20, bottom: 16, right: 0))
            ])
        }
        return container
    }
}

extension ActivitiesViewController: StatefulViewController {
    func hasContent() -> Bool {
        return viewModel.numberOfSections > 0
    }
}

extension ActivitiesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true )
        delegate?.didPressActivity(activity: viewModel.item(for: indexPath.row, section: indexPath.section), in: self)
    }
}

extension ActivitiesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let activity = viewModel.item(for: indexPath.row, section: indexPath.section)
        let cell: ActivityViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(viewModel: .init(activity: activity, server: activity.server))
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(for: section)
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView(for: section)
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }
}
