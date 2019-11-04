//
//  scrollToLastBug.swift
//  BoomerKeys
//
//  Created by Kenny on 11/4/19.
//  Copyright © 2019 Hazy Studios. All rights reserved.
//
extension UICollectionView {
    func scrollToLast() {
        guard numberOfSections > 0 else {
            print("number of sections < 0")
            return
        }
        let lastSection = numberOfSections - 1
        guard numberOfItems(inSection: lastSection) > 0 else {
            print("number of items < 0")
            return
        }
        let lastItemIndexPath = IndexPath(item: numberOfItems(inSection: lastSection) - 1,
                                          section: lastSection)
        self.scrollToItem(at: lastItemIndexPath, at: .bottom, animated: true)
        print("last Item (section, item #): \(lastItemIndexPath)")
    }
}

//returns a Message in the completion handler
typealias CompletionWithMessage = (_ result:Message) -> Void

//called every time a message is added to the room with the corresponding ID (called once per existing Message when called initially in viewDidAppear)
func messageListener(roomId: String, _ complete: @escaping CompletionWithMessage) {
    _ROOMS.child(roomId).child("messages").observe(.childAdded) { (snapshot) in
        let messageBody = snapshot.childSnapshot(forPath: "body")
        let username = snapshot.childSnapshot(forPath: "username")
        let uid = snapshot.childSnapshot(forPath: "uid")
        if let date = snapshot.childSnapshot(forPath: "date").value as? Double {
            let idValue = snapshot.key
            if let bodyValue = messageBody.value as? String {
                if let username = username.value as? String {
                    if let uid = uid.value as? String {
                        let message = Message(id: idValue, body: bodyValue, user: username, uid: uid)
                        message.setDate(date)
                        complete(message)
                    }
                }
            }
        }
    }
}

/******Room Controller******/
override func viewDidLoad() {
    super.viewDidLoad()
    collection.delegate = self
    collection.dataSource = self
    let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
    view.addGestureRecognizer(tap)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
}

//BUG: Doesn't scroll at all, or scrolls to top if collection is scrolled to bottom
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    //listen for new messages
    if let room = room {
        DataService.instance.messageListener(roomId: room.id, { (result) in
            self.messageArr.append(result)
            self.messageArr = self.messageArr.sorted(by: { $0.date < $1.date })
            self.collection.reloadData()
            self.collection.scrollToLast()
            self.messageTextArea.text = ""
        })
    }
}

//scrolls to the last item IF the collectionView is scrolled to the bottom manually first, otherwise it does nothing or scrolls to the top
@objc func keyboardWillShow(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        //31 from storyboard bottom constraint
        if self.adBottomConstraint.constant == 31 {
            self.adBottomConstraint.constant = keyboardSize.height
            collection.frame.size.height -= keyboardSize.height
        } else {
            print("bottom constraint isn't 31, its \(self.adBottomConstraint.constant)")
        }
        collection.scrollToLast()
    }
}

//scrolls to just above the last item
@objc func keyboardWillHide(notification: NSNotification) {
    self.adBottomConstraint.constant = 31 //match storyboard
    collection.scrollToLast()
}

