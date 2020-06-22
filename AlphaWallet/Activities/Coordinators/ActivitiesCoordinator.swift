// Copyright © 2020 Stormbird PTE. LTD.

import UIKit

class ActivitiesCoordinator: Coordinator {
    private let keystore: Keystore
    private let sessions: ServerDictionary<WalletSession>
    private let tokensStorages: ServerDictionary<TokensDataStore>
    private let assetDefinitionStore: AssetDefinitionStore
    private let eventsActivityDataStore: EventsActivityDataStoreProtocol
    private let eventsDataStore: EventsDataStoreProtocol
    private var activities: [Activity] = .init()
    private var tokensAndTokenHolders: [AlphaWallet.Address: (tokenObject: TokenObject, tokenHolders: [TokenHolder])] = .init()

    private var contractsInDatabase: [AlphaWallet.Address] {
        var contracts = [AlphaWallet.Address]()
        for each in tokensStorages.values {
            contracts.append(contentsOf: each.enabledObject.filter {
                switch $0.type {
                case .erc20, .erc721, .erc875, .erc721ForTickets:
                    return true
                case .nativeCryptocurrency:
                    return false
                }
            }.map { $0.contractAddress })
        }
        return contracts
    }

    lazy var rootViewController: ActivitiesViewController = {
        makeActivitiesViewController()
    }()

    let navigationController: UINavigationController
    var coordinators: [Coordinator] = []

    init(
        sessions: ServerDictionary<WalletSession>,
        navigationController: UINavigationController = NavigationController(),
        keystore: Keystore,
        tokensStorages: ServerDictionary<TokensDataStore>,
        assetDefinitionStore: AssetDefinitionStore,
        eventsActivityDataStore: EventsActivityDataStoreProtocol,
        eventsDataStore: EventsDataStoreProtocol
    ) {
        self.sessions = sessions
        self.keystore = keystore
        self.navigationController = navigationController
        self.tokensStorages = tokensStorages
        self.assetDefinitionStore = assetDefinitionStore
        self.eventsDataStore = eventsDataStore
        self.eventsActivityDataStore = eventsActivityDataStore

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    func start() {
        navigationController.viewControllers = [rootViewController]
    }

    private func makeActivitiesViewController() -> ActivitiesViewController {
        let viewModel = ActivitiesViewModel()
        let controller = ActivitiesViewController(viewModel: viewModel)
        controller.delegate = self
        return controller
    }

    func showActivity(_ activity: Activity) {
        let controller = ActivityViewController(viewModel: .init(activity: activity))
        if UIDevice.current.userInterfaceIdiom == .pad {
            let nav = UINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .formSheet
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: R.string.localizable.cancel(), style: .plain, target: self, action: #selector(dismiss))
            nav.makePresentationFullScreenForiOS13Migration()
            navigationController.present(nav, animated: true, completion: nil)
        } else {
            controller.hidesBottomBarWhenPushed = true
            controller.navigationItem.largeTitleDisplayMode = .never
            navigationController.pushViewController(controller, animated: true)
        }
    }

    @objc func didEnterForeground() {
        //hhh should refresh/fetch self, coordinator instead
        //rootViewController.fetch()
    }

    @objc func dismiss() {
        navigationController.dismiss(animated: true, completion: nil)
    }

    func stop() {
        //TODO seems not good to stop here because others call stop too
        for each in sessions.values {
            each.stop()
        }
    }

    func reload() {
        var activitiesAndTokens: [(Activity, TokenObject, TokenHolder)] = .init()
        for eachContract in contractsInDatabase {
            let xmlHandler = XMLHandler(contract: eachContract, assetDefinitionStore: assetDefinitionStore)
            guard xmlHandler.hasAssetDefinition else { continue }
            for card in xmlHandler.activityCards {
                let (filterName, filterValue) = card.eventOrigin.eventFilter
                let interpolatedFilter: String
                if let implicitAttribute = EventSourceCoordinatorForActivities.convertToImplicitAttribute(string: filterValue) {
                    switch implicitAttribute {
                    case .tokenId:
                        continue
                    case .ownerAddress:
                        let wallet = sessions.anyValue.account.address
                        interpolatedFilter = "\(filterName)=\(wallet.eip55String)"
                    case .label, .contractAddress, .symbol:
                        //hhh support more
                        continue
                    }
                } else {
                    //TODO support things like "$prefix-{tokenId}"
                    continue
                }

                guard let server = xmlHandler.server else { continue }
                let events = eventsActivityDataStore.getEvents(forEventName: card.eventOrigin.eventName, filter: interpolatedFilter, server: server)
                let activitiesForThisCard: [(Activity, TokenObject, TokenHolder)] = events.compactMap { eachEvent in
                    let implicitAttributes = generateImplicitAttributes(forContract: eachEvent.tokenContractAddress, server: server)
                    let tokenAttributes = implicitAttributes
                    var cardAttributes = eachEvent.data
                    for parameter in card.eventOrigin.parameters {
                        guard let originalValue = cardAttributes[parameter.name] else { continue }
                        guard let type = SolidityType(rawValue: parameter.type) else { continue }
                        let translatedValue = type.coerce(value: originalValue)
                        cardAttributes[parameter.name] = translatedValue
                    }
                    let tokenObject: TokenObject
                    let tokenHolders: [TokenHolder]
                    if let (o, h) = tokensAndTokenHolders[eachContract] {
                        tokenObject = o
                        tokenHolders = h
                    } else {
                        let tokensDatastore = tokensStorages[server]
                        guard let token = tokensDatastore.token(forContract: eachContract) else { return nil }
                        tokenObject = token
                        tokenHolders = TokenAdaptor(token: tokenObject, assetDefinitionStore: assetDefinitionStore, eventsDataStore: eventsDataStore).getTokenHolders(forWallet: sessions.anyValue.account)
                        tokensAndTokenHolders[eachContract] = (tokenObject: tokenObject, tokenHolders: tokenHolders)
                    }
                    //TODO support ERC721 for activities: have to be careful for ERC721, there are more than one TokenHolder. Skip for demo?
                    return (.init(id: Int.random(in: 0..<Int.max),server: eachEvent.server, name: card.name, eventName: eachEvent.eventName, blockNumber: eachEvent.blockNumber, values: (token: tokenAttributes, card: cardAttributes)), tokenObject, tokenHolders[0])
                }
                activitiesAndTokens.append(contentsOf: activitiesForThisCard)
            }
        }
        activities = activitiesAndTokens.map { $0.0 }
        activities.sort { $0.blockNumber > $1.blockNumber }
        rootViewController.configure(viewModel: .init(activities: activities))

        for (activity, tokenObject, tokenHolder) in activitiesAndTokens {
            refreshActivity(tokenObject: tokenObject, tokenHolder: tokenHolder, activity: activity)
        }
    }

    //Important to pass in the `TokenHolder` instance and not re-create so that we don't override the subscribable values for the token with ones that are not resolved yet
    private func refreshActivity(tokenObject: TokenObject, tokenHolder: TokenHolder, activity: Activity, isFirstUpdate: Bool = true) {
        let attributeValues = AssetAttributeValues(attributeValues: tokenHolder.values)
        NSLog("xxx start resolve for contract: \(tokenObject.contractAddress)")
        let resolvedAttributeNameValues = attributeValues.resolve { [weak self] values in
            guard let strongSelf = self else { return }
            guard isFirstUpdate else { return }
            NSLog("xxx resolve \(tokenObject.contractAddress) \(values)")
            strongSelf.refreshActivity(tokenObject: tokenObject, tokenHolder: tokenHolder, activity: activity, isFirstUpdate: false)
        }
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            let oldActivity = activities[index]
            let updatedValues = (token: oldActivity.values.token.merging(resolvedAttributeNameValues) { _, new in new }, card: oldActivity.values.card)
            let updatedActivity: Activity = .init(id: oldActivity.id, server: oldActivity.server, name: oldActivity.name, eventName: oldActivity.eventName, blockNumber: oldActivity.blockNumber, values: updatedValues)
            activities[index] = updatedActivity
            rootViewController.configure(viewModel: .init(activities: activities))
        } else {
            //no-op. We should be able to find it unless the list of activities has changed
        }
    }

    private func generateImplicitAttributes(forContract contract: AlphaWallet.Address, server: RPCServer) -> [String: AssetInternalValue] {
        let tokensDatastore = tokensStorages[server]
        let symbol: String
        if let existingToken = tokensDatastore.token(forContract: contract) {
            symbol = existingToken.symbol
        } else {
            symbol = ""
        }

        //TODO support ERC721 for activities: hardcoded. ERC20 now. But we do ERC721 too
        let isFungible = true
        var results = [String: AssetInternalValue]()
        for each in AssetImplicitAttributes.allCases {
            guard each.shouldInclude(forAddress: contract, isFungible: isFungible) else { continue }
            switch each {
            case .ownerAddress:
                results[each.javaScriptName] = .address(sessions[server].account.address)
            case .tokenId:
                //TODO support ERC721 for activities: hardcoded. ERC20 now. But we do ERC721 too
                break
            case .label:
                break
            case .symbol:
                results[each.javaScriptName] = .string(symbol)
            case .contractAddress:
                results[each.javaScriptName] = .address(contract)
            }
        }
        return results
    }
}

extension ActivitiesCoordinator: ActivitiesViewControllerDelegate {
    func didPressActivity(activity: Activity, in viewController: ActivitiesViewController) {
        showActivity(activity)
    }
}
