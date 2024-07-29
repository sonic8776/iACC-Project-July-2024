//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

protocol ItemsService {
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void)
}

class ListViewController: UITableViewController {
	var items = [ItemViewModel]()
    var service: ItemsService? // Can be mocked
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if tableView.numberOfRows(inSection: 0) == 0 {
			refresh()
		}
	}
	
	@objc private func refresh() {
        refreshControl?.beginRefreshing()
        service?.loadItems(completion: handleAPIResult)
	}
	
	private func handleAPIResult(_ result: Result<[ItemViewModel], Error>) {
		switch result {
		case let .success(items):
            self.items = items
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            
        case let .failure(error):
            show(error: error)
            refreshControl?.endRefreshing()
        }
    }
    
	override func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		items.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let viewModel = items[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
        cell.configure(viewModel)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let viewModel = items[indexPath.row]
        viewModel.select()
	}
}

extension UITableViewCell {
	func configure(_ viewModel: ItemViewModel) {
        textLabel?.text = viewModel.title
        detailTextLabel?.text = viewModel.subtitle
	}
}

// MARK: - UIViewController + show

// show & showDetailViewController
// You use this method to decouple the need to display a view controller from the process of actually presenting that view controller onscreen.

extension UIViewController {
    func select(friend: Friend) {
        let vc = FriendDetailsViewController()
        vc.friend = friend
        show(vc, sender: self) // Decouple the ViewController from the navigationController
    }
    
    func select(card: Card) {
        let vc = CardDetailsViewController()
        vc.card = card
        show(vc, sender: self) // Decouple the ViewController from the navigationController
    }
    
    func select(transfer: Transfer) {
        let vc = TransferDetailsViewController()
        vc.transfer = transfer
        show(vc, sender: self) // Decouple the ViewController from the navigationController
    }
    
    @objc func addCard() {
        show(AddCardViewController(), sender: self)
    }
    
    @objc func addFriend() {
        show(AddFriendViewController(), sender: self)
    }
    
    @objc func sendMoney() {
        show(SendMoneyViewController(), sender: self)
    }
    
    @objc func requestMoney() {
        show(RequestMoneyViewController(), sender: self)
    }
    
    func show(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        presenterVC.present(alert, animated: true)
        showDetailViewController(alert, sender: self) // Decouple the ViewController from the presentation (context)
    }
}
