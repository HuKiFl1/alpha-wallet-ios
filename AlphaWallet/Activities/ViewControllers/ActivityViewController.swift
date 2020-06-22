// Copyright © 2020 Stormbird PTE. LTD.

import UIKit

//hhhhhh implement webview support too
class ActivityViewController: UIViewController {
    //hhhhhh clean up
    private var viewModel: ActivityViewModel
    private let roundedBackground = RoundedBackground()
    //hhhhhh remove
    private let label = UILabel()

    init(viewModel: ActivityViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        title = viewModel.title
        view.backgroundColor = viewModel.backgroundColor

        roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedBackground)

        //hhhhhh add things
        label.translatesAutoresizingMaskIntoConstraints = false
        roundedBackground.addSubview(label)

        NSLayoutConstraint.activate([
            //hhhhhh
            label.leadingAnchor.constraint(equalTo: roundedBackground.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: roundedBackground.trailingAnchor),
            label.topAnchor.constraint(equalTo: roundedBackground.topAnchor),
            //label.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ] + roundedBackground.createConstraintsWithContainer(view: view))

        configure(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(viewModel: ActivityViewModel) {
        self.viewModel = viewModel

        //hhhhhh display
        label.text = viewModel.text
    }
}
