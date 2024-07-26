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
	
	var retryCount = 0
	var maxRetryCount = 0
	var shouldRetry = false
	
	var longDateStyle = false
	
	var fromReceivedTransfersScreen = false
	var fromSentTransfersScreen = false
	var fromCardsScreen = false
	var fromFriendsScreen = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
        if fromCardsScreen {
			shouldRetry = false
			
			title = "Cards"
			
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCard))
			
		} else if fromSentTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = true

			navigationItem.title = "Sent"
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendMoney))

		} else if fromReceivedTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = false
			
			navigationItem.title = "Received"
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Request", style: .done, target: self, action: #selector(requestMoney))
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if tableView.numberOfRows(inSection: 0) == 0 {
			refresh()
		}
	}
	
	@objc private func refresh() {
        refreshControl?.beginRefreshing()
        if fromFriendsScreen {
            service?.loadItems(completion: handleAPIResult)
            
        } else if fromCardsScreen {
            CardAPI.shared.loadCards { [weak self] result in
                DispatchQueue.mainAsyncIfNeeded {
                    self?.handleAPIResult(result.map { items in
                        items.map { item in
                            ItemViewModel(card: item, selection: {
                                self?.select(card: item)
                            })
                        }
                    })
				}
			}
		} else if fromSentTransfersScreen || fromReceivedTransfersScreen {
            TransfersAPI.shared.loadTransfers { [weak self, longDateStyle, fromSentTransfersScreen] result in
                DispatchQueue.mainAsyncIfNeeded {
                    self?.handleAPIResult(result.map { items in
                        items
                            .filter { fromSentTransfersScreen ? $0.isSender : !$0.isSender}
                            .map { item in
                                ItemViewModel(
                                    transfer: item,
                                    longDateStyle: longDateStyle,
                                    selection: {
                                        self?.select(transfer: item)
                                    })
                            }
                    })
                }
            }
        } else {
			fatalError("unknown context")
		}
	}
	
	private func handleAPIResult(_ result: Result<[ItemViewModel], Error>) {
		switch result {
		case let .success(items):
			self.retryCount = 0
            self.items = items
			self.refreshControl?.endRefreshing()
			self.tableView.reloadData()
			
		case let .failure(error):
			if shouldRetry && retryCount < maxRetryCount {
				retryCount += 1
				
				refresh()
				return
			}
			
			retryCount = 0
			
			if fromFriendsScreen && User.shared?.isPremium == true {
				(UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.loadFriends { [weak self] result in
					DispatchQueue.mainAsyncIfNeeded {
						switch result {
						case let .success(items):
                            self?.items = items.map { item in
                                ItemViewModel(friend: item, selection: { [weak self] in
                                    self?.select(friend: item)
                                })
                            }
							self?.tableView.reloadData()
							
						case let .failure(error):
                            self?.show(error: error)
						}
						self?.refreshControl?.endRefreshing()
					}
				}
			} else {
				show(error: error)
                refreshControl?.endRefreshing()
			}
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
