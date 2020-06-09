// Copyright © 2018 Stormbird PTE. LTD.

import UIKit

protocol SettingsViewControllerDelegate: class, CanOpenURL {
    func settingsViewControllerAdvancedSettingsSelected(in controller: SettingsViewController)
    func settingsViewControllerChangeWalletSelected(in controller: SettingsViewController)
    func settingsViewControllerMyWalletAddressSelected(in controller: SettingsViewController)
    func settingsViewControllerBackupWalletSelected(in controller: SettingsViewController)
    func settingsViewControllerActiveNetworksSelected(in controller: SettingsViewController)
    func settingsViewControllerHelpSelected(in controller: SettingsViewController)
}

class SettingsViewController: UIViewController {
    private let lock = Lock()
    private let keystore: Keystore
    private let account: Wallet
    private let analyticsCoordinator: AnalyticsCoordinator?
    private let promptBackupWalletViewHolder = UIView()
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.register(SettingViewHeader.self, forHeaderFooterViewReuseIdentifier: SettingViewHeader.reuseIdentifier)
        tableView.register(SettingTableViewCell.self, forCellReuseIdentifier: SettingTableViewCell.reuseIdentifier)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.reuseIdentifier)
        tableView.separatorStyle = .singleLine

        return tableView
    }()
    private lazy var viewModel: SettingsViewModel = SettingsViewModel(account: account)

    weak var delegate: SettingsViewControllerDelegate?
    var promptBackupWalletView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let promptBackupWalletView = promptBackupWalletView {
                promptBackupWalletView.translatesAutoresizingMaskIntoConstraints = false
                promptBackupWalletViewHolder.addSubview(promptBackupWalletView)
                NSLayoutConstraint.activate([
                    promptBackupWalletView.leadingAnchor.constraint(equalTo: promptBackupWalletViewHolder.leadingAnchor, constant: 7),
                    promptBackupWalletView.trailingAnchor.constraint(equalTo: promptBackupWalletViewHolder.trailingAnchor, constant: -7),
                    promptBackupWalletView.topAnchor.constraint(equalTo: promptBackupWalletViewHolder.topAnchor, constant: 7),
                    promptBackupWalletView.bottomAnchor.constraint(equalTo: promptBackupWalletViewHolder.bottomAnchor, constant: 0),
                ])
                tabBarItem.badgeValue = "1"
                showPromptBackupWalletViewAsTableHeaderView()
            } else {
                hidePromptBackupWalletView()
                tabBarItem.badgeValue = nil
            }
        }
    }

    override func loadView() {
        view = tableView
    }

    init(keystore: Keystore, account: Wallet, analyticsCoordinator: AnalyticsCoordinator?) {
        self.keystore = keystore
        self.account = account
        self.analyticsCoordinator = analyticsCoordinator
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = R.string.localizable.aSettingsNavigationTitle()
        view.backgroundColor = Screen.Setting.Color.background
        navigationItem.largeTitleDisplayMode = .automatic
        tableView.backgroundColor = GroupedTable.Color.background

        if promptBackupWalletView == nil {
            hidePromptBackupWalletView()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reflectCurrentWalletSecurityLevel()
    }

    private func showPromptBackupWalletViewAsTableHeaderView() {
        let size = promptBackupWalletViewHolder.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        promptBackupWalletViewHolder.bounds.size.height = size.height

        tableView.tableHeaderView = promptBackupWalletViewHolder
    }

    private func hidePromptBackupWalletView() {
        tableView.tableHeaderView = nil
    }

    private func reflectCurrentWalletSecurityLevel() {
        tableView.reloadData()
    }

    private func setPasscode(completion: ((Bool) -> Void)? = .none) {
        guard let navigationController = navigationController else { return }
        let viewModel = LockCreatePasscodeViewModel()
        let lock = LockCreatePasscodeCoordinator(navigationController: navigationController, model: viewModel)
        lock.start()
        lock.lockViewController.willFinishWithResult = { result in
            completion?(result)
            lock.stop()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SettingsViewController: CanOpenURL {

    func didPressViewContractWebPage(forContract contract: AlphaWallet.Address, server: RPCServer, in viewController: UIViewController) {
        delegate?.didPressViewContractWebPage(forContract: contract, server: server, in: viewController)
    }

    func didPressViewContractWebPage(_ url: URL, in viewController: UIViewController) {
        delegate?.didPressViewContractWebPage(url, in: viewController)
    }

    func didPressOpenWebPage(_ url: URL, in viewController: UIViewController) {
        delegate?.didPressOpenWebPage(url, in: viewController)
    }
}

extension SettingsViewController: SwitchTableViewCellDelegate {

    func cell(_ cell: SwitchTableViewCell, switchStateChanged isOn: Bool) {
        if isOn {
            self.setPasscode { result in
                cell.isOn = result
            }
        } else {
            self.lock.deletePasscode()
        }
    }
}

extension SettingsViewController: UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfSections(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.sections[indexPath.section] {
        case .system(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .passcode:
                let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.reuseIdentifier, for: indexPath) as! SwitchTableViewCell
                cell.delegate = self
                cell.configure(viewModel: .init(
                    titleText: viewModel.passcodeTitle,
                    icon: R.image.biometrics()!,
                    value: lock.isPasscodeSet)
                )

                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.reuseIdentifier, for: indexPath) as! SettingTableViewCell
                cell.configure(viewModel: .init(settingsSystemRow: row))

                return cell
            }
        case .help:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.reuseIdentifier, for: indexPath) as! SettingTableViewCell
            cell.configure(viewModel: .init(titleText: R.string.localizable.settingsSupportTitle(), icon: R.image.support()!))

            return cell
        case .wallet(let rows):
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingTableViewCell.reuseIdentifier, for: indexPath) as! SettingTableViewCell
            let row = rows[indexPath.row]
            switch row {
            case .changeWallet:
                let viewModel: SettingTableViewCellViewModel = .init(
                    titleText: row.title,
                    subTitleText: account.address.eip55String,
                    icon: row.icon
                )
                cell.configure(viewModel: viewModel)
            case .backup:
                cell.configure(viewModel: .init(settingsWalletRow: row))
                let walletSecurityLevel = PromptBackupCoordinator(keystore: self.keystore, wallet: self.account, config: .init(), analyticsCoordinator: analyticsCoordinator).securityLevel
                cell.accessoryView = walletSecurityLevel.flatMap { WalletSecurityLevelIndicator(level: $0) }
                cell.accessoryType = .disclosureIndicator
            default:
                cell.configure(viewModel: .init(settingsWalletRow: row))
            }

            return cell
        case .tokenStandard, .version:
            return UITableViewCell()
        }
    }
}

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SettingViewHeader.reuseIdentifier) as! SettingViewHeader
        let section = viewModel.sections[section]
        let viewModel = SettingViewHeaderViewModel(section: section)
        headerView.configure(viewModel: viewModel)

        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.sections[indexPath.section] {
        case .wallet(let rows):
            switch rows[indexPath.row] {
            case .backup:
                delegate?.settingsViewControllerBackupWalletSelected(in: self)
            case .changeWallet:
                delegate?.settingsViewControllerChangeWalletSelected(in: self)
            case .showMyWallet:
                delegate?.settingsViewControllerMyWalletAddressSelected(in: self)
            }
        case .system(let rows):
            switch rows[indexPath.row] {
            case .advanced:
                delegate?.settingsViewControllerAdvancedSettingsSelected(in: self)
            case .notifications:
                break
            case .passcode:
                break
            case .selectActiveNetworks:
                delegate?.settingsViewControllerActiveNetworksSelected(in: self)
            }
        case .help:
            delegate?.settingsViewControllerHelpSelected(in: self)
        case .tokenStandard:
            self.delegate?.didPressOpenWebPage(TokenScript.tokenScriptSite, in: self)
        case .version:
            break
        }
    }
}
