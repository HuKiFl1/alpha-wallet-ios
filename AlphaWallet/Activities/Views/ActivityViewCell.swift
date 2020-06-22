// Copyright © 2020 Stormbird PTE. LTD.

import UIKit

class ActivityViewCell: UITableViewCell {
    private let background = UIView()
    private let titleLabel = UILabel()
    private let blockchainLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(background)
        background.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        blockchainLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        blockchainLabel.setContentHuggingPriority(.required, for: .vertical)

        let stackView = [titleLabel, blockchainLabel].asStackView(spacing: 15)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .horizontal)

        stackView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)

        background.addSubview(stackView)

        NSLayoutConstraint.activate([
            blockchainLabel.heightAnchor.constraint(equalToConstant: Screen.TokenCard.Metric.blockChainTagHeight),

            stackView.anchorsConstraint(to: background, edgeInsets: .init(top: 14, left: StyleLayout.sideMargin, bottom: 14, right: StyleLayout.sideMargin)),

            background.anchorsConstraint(to: contentView),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: ActivityCellViewModel) {
        selectionStyle = .none
        background.backgroundColor = viewModel.contentsBackgroundColor
        background.layer.cornerRadius = viewModel.contentsCornerRadius

        titleLabel.textColor = viewModel.titleTextColor
        titleLabel.text = viewModel.title
        titleLabel.font = viewModel.titleFont

        blockchainLabel.textAlignment = viewModel.blockChainNameTextAlignment
        blockchainLabel.cornerRadius = viewModel.blockChainNameCornerRadius
        blockchainLabel.backgroundColor = viewModel.blockChainNameBackgroundColor
        blockchainLabel.textColor = viewModel.blockChainNameColor
        blockchainLabel.font = viewModel.blockChainNameFont
        blockchainLabel.text = viewModel.blockChainName

        backgroundColor = viewModel.backgroundColor
    }
}
