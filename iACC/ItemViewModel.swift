//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

struct ItemViewModel {
    let title: String
    let subtitle: String
    let select: () -> Void
    
    init(_ item: Any, longDateStyle: Bool, selection: @escaping () -> Void) {
        if let friend = item as? Friend {
            self.init(friend: friend, selection: selection)
        } else if let card = item as? Card {
            self.init(card: card, selection: selection)
        } else if let transfer = item as? Transfer {
            self.init(transfer: transfer, longDateStyle: longDateStyle, selection: selection)
        } else {
            fatalError()
        }
    }
}

extension ItemViewModel {
    init(friend: Friend, selection: @escaping () -> Void) {
        title = friend.name
        subtitle = friend.phone
        select = selection
    }
}
extension ItemViewModel {
    init(card: Card, selection: @escaping () -> Void) {
        title = card.number
        subtitle = card.holder
        select = selection
    }
}

extension ItemViewModel {
    init(transfer: Transfer, longDateStyle: Bool, selection: @escaping () -> Void) {
        let numberFormatter = Formatters.number
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = transfer.currencyCode
        
        let amount = numberFormatter.string(from: transfer.amount as NSNumber)!
        title = "\(amount) • \(transfer.description)"
        
        let dateFormatter = Formatters.date
        if longDateStyle {
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            subtitle = "Sent to: \(transfer.recipient) on \(dateFormatter.string(from: transfer.date))"
        } else {
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            subtitle = "Received from: \(transfer.sender) on \(dateFormatter.string(from: transfer.date))"
        }
        select = selection
    }
}
