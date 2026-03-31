//
//  FirebaseService.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/27/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct AppUserProfile {
    let fullName: String
    let nickname: String
    let email: String
    let phone: String
    let profileImageURL: String
    let selectedAvatarIndex: Int
    let monthlyLimit: Double
    let themeMode: String

    init(data: [String: Any]) {
        self.fullName = data["fullName"] as? String ?? ""
        self.nickname = data["nickname"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.phone = data["phone"] as? String ?? ""
        self.profileImageURL = data["profileImageURL"] as? String ?? ""
        self.selectedAvatarIndex = data["selectedAvatarIndex"] as? Int ?? 0
        self.monthlyLimit = data["monthlyLimit"] as? Double ?? 0
        self.themeMode = data["themeMode"] as? String ?? "auto"
    }
}

struct FirestoreFriendRecord {
    let documentId: String
    let friendName: String
    let friendContact: String
    let balanceAmount: Double
    let balanceDirection: String
    let isBlocked: Bool

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.friendName = data["friendName"] as? String ?? ""
        self.friendContact = data["friendContact"] as? String ?? ""
        self.balanceAmount = data["balanceAmount"] as? Double ?? 0
        self.balanceDirection = data["balanceDirection"] as? String ?? "owesYou"
        self.isBlocked = data["isBlocked"] as? Bool ?? false
    }
}

struct FirestoreGroupRecord {
    let documentId: String
    let name: String
    let type: String
    let memberNames: [String]
    let participantCount: Int
    let balanceAmount: Double
    let balanceDirection: String

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.name = data["name"] as? String ?? ""
        self.type = data["type"] as? String ?? ""
        self.memberNames = data["memberNames"] as? [String] ?? []
        self.participantCount = data["participantCount"] as? Int ?? 1
        self.balanceAmount = data["balanceAmount"] as? Double ?? 0
        self.balanceDirection = data["balanceDirection"] as? String ?? "owesYou"
    }
}

struct FirestoreActivityRecord {
    let documentId: String
    let title: String
    let subtitle: String
    let amount: Double
    let date: String
    let monthKey: String
    let category: String
    let entryType: String

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.title = data["title"] as? String ?? ""
        self.subtitle = data["subtitle"] as? String ?? ""
        self.amount = data["amount"] as? Double ?? 0
        self.date = data["date"] as? String ?? ""
        self.monthKey = data["monthKey"] as? String ?? ""
        self.category = data["category"] as? String ?? "Other"

        if let storedType = data["entryType"] as? String, !storedType.isEmpty {
            self.entryType = storedType
        } else {
            let normalizedTitle = self.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.entryType = normalizedTitle.hasPrefix("settle up with") ? "settlement" : "expense"
        }
    }
}

struct FirestoreNotificationRecord {
    let documentId: String
    let title: String
    let message: String
    let timeText: String

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.title = data["title"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.timeText = data["timeText"] as? String ?? "Now"
    }
}

struct FirestoreExpenseHistoryRecord {
    let documentId: String
    let description: String
    let amount: Double
    let dateText: String
    let receiptURL: String

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.description = data["description"] as? String ?? ""
        self.amount = data["amount"] as? Double ?? 0
        self.dateText = data["dateText"] as? String ?? ""
        self.receiptURL = data["receiptURL"] as? String ?? ""
    }
}

struct FirestoreExpensePayload {
    let targetType: String
    let targetDocumentId: String
    let description: String
    let amount: Double
    let direction: BalanceDirection
    let category: String
    let dateText: String
    let monthKey: String
    let activitySubtitle: String
    let groupDraft: GroupExpenseDraft?
    let receiptURL: String?
}

final class FirebaseService {
    static let shared = FirebaseService()

    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()

    private init() {}

    var currentUserId: String? {
        auth.currentUser?.uid
    }

    var currentUserEmail: String? {
        auth.currentUser?.email
    }

    func registerUser(
        firstName: String,
        lastName: String,
        phone: String,
        email: String,
        password: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let cleanedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPhone = Self.normalizedPhoneDigits(phone)
        let formattedPhone = Self.formattedPhoneNumber(from: normalizedPhone)
        let fullName = [cleanedFirstName, cleanedLastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        auth.createUser(withEmail: cleanedEmail, password: password) { [weak self] result, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let self, let user = result?.user else { return }

            let userData: [String: Any] = [
                "firstName": cleanedFirstName,
                "lastName": cleanedLastName,
                "fullName": fullName,
                "nickname": cleanedFirstName,
                "email": cleanedEmail,
                "phone": formattedPhone,
                "phoneDigits": normalizedPhone,
                "profileImageURL": "",
                "selectedAvatarIndex": 0,
                "monthlyLimit": 0.0,
                "themeMode": "auto",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            self.db.collection("users").document(user.uid).setData(userData) { error in
                if let error {
                    completion(.failure(error))
                    return
                }

                do {
                    try self.auth.signOut()
                    completion(.success(user.uid))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func loginUser(
        identifier: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let cleanedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedIdentifier.contains("@") {
            loginWithEmail(email: cleanedIdentifier.lowercased(), password: password, completion: completion)
            return
        }

        let phoneDigits = Self.normalizedPhoneDigits(cleanedIdentifier)
        guard !phoneDigits.isEmpty else {
            loginWithEmail(email: cleanedIdentifier.lowercased(), password: password, completion: completion)
            return
        }

        db.collection("users")
            .whereField("phoneDigits", isEqualTo: phoneDigits)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard
                    let data = snapshot?.documents.first?.data(),
                    let email = data["email"] as? String,
                    !email.isEmpty
                else {
                    let fallbackEmail = self?.possibleEmailFallback(from: cleanedIdentifier) ?? cleanedIdentifier.lowercased()
                    self?.loginWithEmail(email: fallbackEmail, password: password, completion: completion)
                    return
                }

                self?.loginWithEmail(email: email.lowercased(), password: password, completion: completion)
            }
    }

    private func loginWithEmail(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        auth.signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error {
                completion(.failure(error))
                return
            }

            self?.ensureUserDocumentExists(completion: completion)
        }
    }

    private func possibleEmailFallback(from identifier: String) -> String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func ensureUserDocumentExists(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let user = auth.currentUser else {
            completion(.success(()))
            return
        }

        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            if snapshot?.exists == true {
                completion(.success(()))
                return
            }

            let userData: [String: Any] = [
                "firstName": "",
                "lastName": "",
                "fullName": "",
                "nickname": "",
                "email": user.email ?? "",
                "phone": "",
                "phoneDigits": "",
                "profileImageURL": "",
                "selectedAvatarIndex": 0,
                "monthlyLimit": 0.0,
                "themeMode": "auto",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            userRef.setData(userData) { error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    func fetchCurrentUserProfile(
        completion: @escaping (Result<AppUserProfile, Error>) -> Void
    ) {
        guard let uid = auth.currentUser?.uid else {
            completion(.success(AppUserProfile(data: [:])))
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            let data = snapshot?.data() ?? [:]
            completion(.success(AppUserProfile(data: data)))
        }
    }

    func updateCurrentUserProfile(
        fullName: String,
        nickname: String,
        email: String,
        phone: String,
        monthlyLimit: Double,
        selectedAvatarIndex: Int = 0,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = auth.currentUser?.uid else {
            completion(.success(()))
            return
        }

        let normalizedPhone = Self.normalizedPhoneDigits(phone)
        let formattedPhone = Self.formattedPhoneNumber(from: normalizedPhone)

        let payload: [String: Any] = [
            "fullName": fullName,
            "nickname": nickname,
            "email": email,
            "phone": formattedPhone,
            "phoneDigits": normalizedPhone,
            "monthlyLimit": monthlyLimit,
            "selectedAvatarIndex": selectedAvatarIndex,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(uid).setData(payload, merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func updateCurrentUserPassword(
        currentPassword: String,
        newPassword: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let user = auth.currentUser, let email = user.email, !email.isEmpty else {
            completion(.failure(NSError(
                domain: "SplitEasy",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Unable to verify the current user email."]
            )))
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        user.reauthenticate(with: credential) { _, error in
            if let error {
                completion(.failure(error))
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    func updateThemeMode(
        _ themeMode: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = auth.currentUser?.uid else {
            completion(.success(()))
            return
        }

        db.collection("users").document(uid).setData([
            "themeMode": themeMode,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func sendPasswordReset(
        email: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        auth.sendPasswordReset(withEmail: email) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func saveFeedback(
        rating: Int,
        message: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = auth.currentUser?.uid else {
            completion(.success(()))
            return
        }

        let data: [String: Any] = [
            "userId": uid,
            "rating": rating,
            "message": message,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("feedback").addDocument(data: data) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func saveSupportMessage(
        subject: String,
        message: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = auth.currentUser?.uid else {
            completion(.success(()))
            return
        }

        let data: [String: Any] = [
            "userId": uid,
            "subject": subject,
            "message": message,
            "status": "open",
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("support_messages").addDocument(data: data) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func addFriend(
        friendName: String,
        friendContact: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success(""))
            return
        }

        let payload: [String: Any] = [
            "ownerUserId": uid,
            "friendName": friendName,
            "friendContact": friendContact,
            "balanceAmount": 0.0,
            "balanceDirection": "owesYou",
            "isBlocked": false,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let ref = db.collection("friendships").document()
        ref.setData(payload) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(ref.documentID))
            }
        }
    }

    func fetchFriends(
        completion: @escaping (Result<[FirestoreFriendRecord], Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success([]))
            return
        }

        db.collection("friendships")
            .whereField("ownerUserId", isEqualTo: uid)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let records = snapshot?.documents.map {
                    FirestoreFriendRecord(documentId: $0.documentID, data: $0.data())
                } ?? []

                completion(.success(records))
            }
    }

    func setFriendBlocked(
        friendDocumentId: String,
        isBlocked: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("friendships").document(friendDocumentId).setData([
            "isBlocked": isBlocked,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func deleteFriend(
        friendDocumentId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let friendRef = db.collection("friendships").document(friendDocumentId)

        friendRef.delete { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func createGroup(
        name: String,
        type: String,
        memberNames: [String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success(""))
            return
        }

        let cleanedMembers = memberNames.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let payload: [String: Any] = [
            "ownerUserId": uid,
            "name": name,
            "type": type,
            "memberNames": cleanedMembers,
            "participantCount": cleanedMembers.count + 1,
            "balanceAmount": 0.0,
            "balanceDirection": "owesYou",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let ref = db.collection("groups").document()
        ref.setData(payload) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(ref.documentID))
            }
        }
    }

    func fetchGroups(
        completion: @escaping (Result<[FirestoreGroupRecord], Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success([]))
            return
        }

        db.collection("groups")
            .whereField("ownerUserId", isEqualTo: uid)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let records = snapshot?.documents.map {
                    FirestoreGroupRecord(documentId: $0.documentID, data: $0.data())
                } ?? []

                completion(.success(records))
            }
    }

    func fetchActivity(
        completion: @escaping (Result<[FirestoreActivityRecord], Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success([]))
            return
        }

        db.collection("users")
            .document(uid)
            .collection("activity")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let records = snapshot?.documents.map {
                    FirestoreActivityRecord(documentId: $0.documentID, data: $0.data())
                } ?? []

                completion(.success(records))
            }
    }

    func fetchNotifications(
        completion: @escaping (Result<[FirestoreNotificationRecord], Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success([]))
            return
        }

        db.collection("notifications")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let records = snapshot?.documents.map {
                    FirestoreNotificationRecord(documentId: $0.documentID, data: $0.data())
                } ?? []

                completion(.success(records))
            }
    }

    func saveNotification(
        title: String,
        message: String,
        timeText: String = "Now",
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        guard let uid = currentUserId else {
            completion?(.success(()))
            return
        }

        let payload: [String: Any] = [
            "userId": uid,
            "title": title,
            "message": message,
            "timeText": timeText,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("notifications").addDocument(data: payload) { error in
            if let error {
                completion?(.failure(error))
            } else {
                completion?(.success(()))
            }
        }
    }

    func fetchExpenseHistory(
        targetType: String,
        targetDocumentId: String,
        completion: @escaping (Result<[FirestoreExpenseHistoryRecord], Error>) -> Void
    ) {
        guard currentUserId != nil else {
            completion(.success([]))
            return
        }

        db.collection("expenses")
            .whereField("targetType", isEqualTo: targetType)
            .whereField("targetDocumentId", isEqualTo: targetDocumentId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let records = snapshot?.documents.map {
                    FirestoreExpenseHistoryRecord(documentId: $0.documentID, data: $0.data())
                } ?? []

                completion(.success(records))
            }
    }

    func uploadCurrentUserProfileImage(
        data: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success(""))
            return
        }

        let ref = storage.reference().child("profile_images/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        ref.putData(data, metadata: metadata) { _, error in
            if let error {
                completion(.failure(error))
                return
            }

            ref.downloadURL { url, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(url?.absoluteString ?? ""))
                }
            }
        }
    }

    func updateCurrentUserProfileImageURL(
        _ url: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success(()))
            return
        }

        db.collection("users").document(uid).setData([
            "profileImageURL": url,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func uploadReceiptImage(
        expenseId: String,
        data: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let ref = storage.reference().child("receipt_images/\(expenseId)/receipt.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        ref.putData(data, metadata: metadata) { _, error in
            if let error {
                completion(.failure(error))
                return
            }

            ref.downloadURL { url, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(url?.absoluteString ?? ""))
                }
            }
        }
    }

    func saveExpense(
        payload: FirestoreExpensePayload,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = currentUserId else {
            completion(.success(()))
            return
        }

        let targetCollection = payload.targetType == "friend" ? "friendships" : "groups"
        let targetRef = db.collection(targetCollection).document(payload.targetDocumentId)

        targetRef.getDocument { [weak self] snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            if payload.targetType == "friend" {
                let isBlocked = snapshot?.data()?["isBlocked"] as? Bool ?? false
                if isBlocked {
                    completion(.failure(NSError(
                        domain: "SplitEasy",
                        code: 403,
                        userInfo: [NSLocalizedDescriptionKey: "This user is blocked. Unblock to add expenses."]
                    )))
                    return
                }
            }

            guard let self else { return }

            let expenseRef = self.db.collection("expenses").document()
            let activityRef = self.db.collection("users").document(uid).collection("activity").document()

            self.db.runTransaction({ transaction, errorPointer in
                let targetSnapshot: DocumentSnapshot
                do {
                    targetSnapshot = try transaction.getDocument(targetRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                let currentAmount = targetSnapshot.data()?["balanceAmount"] as? Double ?? 0
                let currentDirection = targetSnapshot.data()?["balanceDirection"] as? String ?? "owesYou"

                let signedCurrent = currentDirection == "owesYou" ? currentAmount : -currentAmount
                let signedChange = payload.direction == .owesYou ? payload.amount : -payload.amount
                let signedUpdated = signedCurrent + signedChange

                let updatedAmount = abs(signedUpdated)
                let updatedDirection = signedUpdated >= 0 ? "owesYou" : "youOwe"

                let expenseData: [String: Any] = [
                    "ownerUserId": uid,
                    "targetType": payload.targetType,
                    "targetDocumentId": payload.targetDocumentId,
                    "description": payload.description,
                    "amount": payload.amount,
                    "direction": payload.direction == .owesYou ? "owesYou" : "youOwe",
                    "category": payload.category,
                    "dateText": payload.dateText,
                    "monthKey": payload.monthKey,
                    "createdAt": FieldValue.serverTimestamp(),
                    "paidBy": payload.groupDraft?.paidBy ?? [],
                    "splitWith": payload.groupDraft?.splitWith ?? [],
                    "yourNetAmount": payload.groupDraft?.yourNetAmount ?? 0,
                    "paidAmounts": payload.groupDraft?.paidAmounts ?? [:],
                    "receiptURL": payload.receiptURL ?? ""
                ]

                let activityData: [String: Any] = [
                    "title": payload.description,
                    "subtitle": payload.activitySubtitle,
                    "amount": payload.amount,
                    "date": payload.dateText,
                    "monthKey": payload.monthKey,
                    "category": payload.category,
                    "entryType": "expense",
                    "createdAt": FieldValue.serverTimestamp()
                ]

                transaction.setData(expenseData, forDocument: expenseRef)
                transaction.setData(activityData, forDocument: activityRef)
                transaction.setData([
                    "balanceAmount": updatedAmount,
                    "balanceDirection": updatedDirection,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: targetRef, merge: true)

                return nil
            }) { _, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    func saveSettlement(
        friendDocumentId: String,
        friendName: String,
        amount: Double,
        method: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let friendRef = db.collection("friendships").document(friendDocumentId)

        friendRef.getDocument { [weak self] snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            let isBlocked = snapshot?.data()?["isBlocked"] as? Bool ?? false
            if isBlocked {
                completion(.failure(NSError(
                    domain: "SplitEasy",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "This user is blocked. Unblock to settle up."]
                )))
                return
            }

            guard let self, let uid = self.currentUserId else {
                completion(.success(()))
                return
            }

            let settlementRef = self.db.collection("settlements").document()
            let activityRef = self.db.collection("users").document(uid).collection("activity").document()

            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "MMM d"
            let dayText = dayFormatter.string(from: Date())

            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "yyyy-MM"
            let monthKey = monthFormatter.string(from: Date())

            self.db.runTransaction({ transaction, errorPointer in
                let targetSnapshot: DocumentSnapshot
                do {
                    targetSnapshot = try transaction.getDocument(friendRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                let currentAmount = targetSnapshot.data()?["balanceAmount"] as? Double ?? 0
                let currentDirection = targetSnapshot.data()?["balanceDirection"] as? String ?? "owesYou"
                let signedCurrent = currentDirection == "owesYou" ? currentAmount : -currentAmount

                let signedUpdated: Double
                if signedCurrent > 0 {
                    signedUpdated = signedCurrent - amount
                } else {
                    signedUpdated = signedCurrent + amount
                }

                let updatedAmount = abs(signedUpdated)
                let updatedDirection = signedUpdated >= 0 ? "owesYou" : "youOwe"

                let settlementData: [String: Any] = [
                    "ownerUserId": uid,
                    "friendDocumentId": friendDocumentId,
                    "friendName": friendName,
                    "amount": amount,
                    "method": method,
                    "dateText": dayText,
                    "monthKey": monthKey,
                    "createdAt": FieldValue.serverTimestamp()
                ]

                let activityData: [String: Any] = [
                    "title": "Settle up with \(friendName)",
                    "subtitle": method,
                    "amount": amount,
                    "date": dayText,
                    "monthKey": monthKey,
                    "category": "Other",
                    "entryType": "settlement",
                    "createdAt": FieldValue.serverTimestamp()
                ]

                transaction.setData(settlementData, forDocument: settlementRef)
                transaction.setData(activityData, forDocument: activityRef)
                transaction.setData([
                    "balanceAmount": updatedAmount,
                    "balanceDirection": updatedDirection,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: friendRef, merge: true)

                return nil
            }) { _, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    func signOut() throws {
        try auth.signOut()
    }

    static func normalizedPhoneDigits(_ input: String) -> String {
        String(input.filter(\.isNumber))
    }

    static func formattedPhoneNumber(from digits: String) -> String {
        let limited = String(digits.prefix(10))

        if limited.isEmpty { return "" }
        if limited.count < 4 { return limited }

        if limited.count < 7 {
            let area = limited.prefix(3)
            let rest = limited.dropFirst(3)
            return "(\(area)) \(rest)"
        }

        let area = limited.prefix(3)
        let middle = limited.dropFirst(3).prefix(3)
        let last = limited.dropFirst(6)
        return "(\(area)) \(middle)-\(last)"
    }
}
