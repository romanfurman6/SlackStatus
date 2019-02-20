//
//  StatusView.swift
//  SlackStatus
//
//  Created by Roman on 2/20/19.
//

import AppKit

class StatusView: NSView, NibInit {

    struct Model {
        let title: String
        let emoji: String
    }

    @IBOutlet private weak var statusTextLabel: NSTextField!

    func configure(with model: Model) {
        statusTextLabel.stringValue = model.emoji + " " + model.title
    }

}
