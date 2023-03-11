//
//  ButtonController.swift
//  AdvancedCoordinators
//
//  Created by pronebird on 11/03/2023.
//

import UIKit

class ViewController: UIViewController {

    var identifier: String?

    override var title: String? {
        didSet {
            textLabel.text = title
        }
    }

    var buttonTitle: String? {
        didSet {
            button.setTitle(buttonTitle, for: .normal)
            addButton()
        }
    }

    var buttonAction: (() -> Void)?

    let textLabel = UILabel()
    let button = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        addTextLabel()
        addButton()
    }

    private func addTextLabel() {
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textColor = .darkText

        view.addSubview(textLabel)
        view.backgroundColor = .systemBackground

        NSLayoutConstraint.activate([
            textLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func addButton() {
        guard isViewLoaded && button.superview == nil && buttonTitle != nil else { return }

        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.buttonAction?()
        }), for: .touchUpInside)

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
        ])
    }
}

