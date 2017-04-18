//
//  MessageViewController.swift
//  StudyBuddy
//
//  Created by Nick Pellegrino on 3/5/17.
//  Copyright © 2017 Nick Pellegrino. All rights reserved.
//

import UIKit

protocol MessageViewControllerDelegate {
    func messageSelected(_ message: Message)
}

class MessageViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: MessageViewControllerDelegate?
    
    var messages: Array<Message>!
    
    struct TableView {
        struct CellIdentifiers {
            static let MessageCell = "MessageCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()
    }
    
}

extension MessageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMessage = messages[indexPath.row]
        delegate?.messageSelected(selectedMessage)
    }
}

// MARK: Table View Data Source

extension MessageViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.MessageCell, for: indexPath) as! MessageCell
        cell.configureForMessage(messages[indexPath.row])
        return cell
    }
    
}

class MessageCell: UITableViewCell{
    
    @IBOutlet weak var buddyName: UILabel!
    @IBOutlet weak var buddyMessage: UILabel!
    
    func configureForMessage(_ message: Message){
        buddyName.text = message.buddyName
        buddyMessage.text = message.message
    }
}
