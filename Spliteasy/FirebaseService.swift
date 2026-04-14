
//
// Firebase helper file. All Firestore/Auth/Storage calls are grouped here
// so the view files stay cleaner.
//
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
    let createdAt: Date

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.title = data["title"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.timeText = data["timeText"] as? String ?? "Now"

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = .distantPast
        }
    }
}

struct FirestoreExpenseHistoryRecord {
    let documentId: String
    let description: String
    let amount: Double
    let dateText: String
    let receiptURL: String

    let locationName: String
    let locationAddress: String
    let latitude: Double?
    let longitude: Double?

    let targetType: String
    let targetDocumentId: String

    let paidBy: [String]
    let splitWith: [String]
    let paidAmounts: [String: Double]
    let yourNetAmount: Double

    let isGroupMirror: Bool
    let parentGroupExpenseId: String
    let groupName: String
    let groupMemberNames: [String]

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.description = data["description"] as? String ?? ""
        self.amount = data["amount"] as? Double ?? 0
        self.dateText = data["dateText"] as? String ?? ""
        self.receiptURL = data["receiptURL"] as? String ?? ""

        self.locationName = data["locationName"] as? String ?? ""
        self.locationAddress = data["locationAddress"] as? String ?? ""
        self.latitude = data["latitude"] as? Double
        self.longitude = data["longitude"] as? Double

        self.targetType = data["targetType"] as? String ?? ""
        self.targetDocumentId = data["targetDocumentId"] as? String ?? ""

        self.paidBy = data["paidBy"] as? [String] ?? []
        self.splitWith = data["splitWith"] as? [String] ?? []

        if let map = data["paidAmounts"] as? [String: Double] {
            self.paidAmounts = map
        } else if let map = data["paidAmounts"] as? [String: Any] {
            self.paidAmounts = map.reduce(into: [String: Double]()) { result, item in
                if let value = item.value as? Double {
                    result[item.key] = value
                } else if let number = item.value as? NSNumber {
                    result[item.key] = number.doubleValue
                }
            }
        } else {
            self.paidAmounts = [:]
        }

        self.yourNetAmount = data["yourNetAmount"] as? Double ?? 0
        self.isGroupMirror = data["isGroupMirror"] as? Bool ?? false
        self.parentGroupExpenseId = data["parentGroupExpenseId"] as? String ?? ""
        self.groupName = data["groupName"] as? String ?? ""
        self.groupMemberNames = data["groupMemberNames"] as? [String] ?? []
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

    let locationName: String
    let locationAddress: String
    let latitude: Double?
    let longitude: Double?
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
    
    private func normalizedNames(_ values: [String]) -> [String] {
        values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func parseDoubleMap(_ value: Any?) -> [String: Double] {
        if let map = value as? [String: Double] {
            return map
        }
        
        if let map = value as? [String: Any] {
            return map.reduce(into: [String: Double]()) { result, item in
                if let doubleValue = item.value as? Double {
                    result[item.key] = doubleValue
                } else if let numberValue = item.value as? NSNumber {
                    result[item.key] = numberValue.doubleValue
                }
            }
        }
        
        return [:]
    }
    
    private func saveGroupFriendMirrorExpense(
        transaction: Transaction,
        ownerUserId: String,
        parentGroupExpenseId: String,
        friendDocumentId: String,
        friendName: String,
        groupDocumentId: String,
        groupName: String,
        description: String,
        amount: Double,
        direction: String,
        category: String,
        dateText: String,
        monthKey: String,
        receiptURL: String,
        locationName: String,
        locationAddress: String,
        latitude: Double?,
        longitude: Double?,
    ) {
        let mirrorRef = db.collection("expenses").document()
        
        let mirrorData: [String: Any] = [
            "ownerUserId": ownerUserId,
            "targetType": "friend",
            "targetDocumentId": friendDocumentId,
            "description": description,
            "amount": amount,
            "direction": direction,
            "category": category,
            "dateText": dateText,
            "monthKey": monthKey,
            "createdAt": FieldValue.serverTimestamp(),
            "receiptURL": receiptURL,
            "isGroupMirror": true,
            "parentGroupExpenseId": parentGroupExpenseId,
            "groupDocumentId": groupDocumentId,
            "groupName": groupName,
            "friendName": friendName,
            "locationName": locationName,
            "locationAddress": locationAddress,
            "latitude": latitude as Any,
            "longitude": longitude as Any,
        ]
        
        transaction.setData(mirrorData, forDocument: mirrorRef)
    }
    
    private func fetchGroupMirrorExpenseDocs(
        parentGroupExpenseId: String,
        completion: @escaping (Result<[QueryDocumentSnapshot], Error>) -> Void
    ) {
        db.collection("expenses")
            .whereField("isGroupMirror", isEqualTo: true)
            .whereField("parentGroupExpenseId", isEqualTo: parentGroupExpenseId)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(snapshot?.documents ?? []))
                }
            }
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
        db.collection("friendships").document(friendDocumentId).delete { error in
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
    
    func updateGroupMembers(
        groupDocumentId: String,
        memberNames: [String],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let cleanedMembers = Array(
            Set(
                memberNames
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        ).sorted()
        
        db.collection("groups").document(groupDocumentId).setData([
            "memberNames": cleanedMembers,
            "participantCount": cleanedMembers.count + 1,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteGroup(
        groupDocumentId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("groups").document(groupDocumentId).delete { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
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
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let records = (snapshot?.documents.map {
                    FirestoreNotificationRecord(documentId: $0.documentID, data: $0.data())
                } ?? [])
                .sorted { $0.createdAt > $1.createdAt }

                completion(.success(records))
            }
    }

    func saveNotification(
        title: String,
        message: String,
        timeText: String? = nil,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        guard let uid = currentUserId else {
            completion?(.success(()))
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"

        let readableTime = timeText ?? formatter.string(from: Date())

        let payload: [String: Any] = [
            "userId": uid,
            "title": title,
            "message": message,
            "timeText": readableTime,
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
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                
                let sortedDocs = (snapshot?.documents ?? []).sorted { lhs, rhs in
                    let leftDate = (lhs.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    let rightDate = (rhs.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return leftDate > rightDate
                }
                
                let records = sortedDocs.map {
                    FirestoreExpenseHistoryRecord(documentId: $0.documentID, data: $0.data())
                }
                
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
                    "receiptURL": payload.receiptURL ?? "",
                    "locationName": payload.locationName,
                    "locationAddress": payload.locationAddress,
                    "latitude": payload.latitude as Any,
                    "longitude": payload.longitude as Any,
                ]
                
                let activityData: [String: Any] = [
                    "title": payload.description,
                    "subtitle": payload.activitySubtitle,
                    "amount": payload.amount,
                    "date": payload.dateText,
                    "monthKey": payload.monthKey,
                    "category": payload.category,
                    "entryType": "expense",
                    "activityExpenseId": expenseRef.documentID,
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
    
    func saveGroupExpenseAndUpdateFriends(
        groupDocumentId: String,
        groupName: String,
        groupMemberNames: [String],
        description: String,
        totalAmount: Double,
        category: String,
        dateText: String,
        monthKey: String,
        groupDraft: GroupExpenseDraft,
        receiptURL: String?,
        locationName: String,
        locationAddress: String,
        latitude: Double?,
        longitude: Double?,
        completion: @escaping (Result<Void, Error>) -> Void
    ){
        guard let uid = currentUserId else {
            completion(.success(()))
            return
        }
        
        let groupRef = db.collection("groups").document(groupDocumentId)
        let expenseRef = db.collection("expenses").document()
        let activityRef = db.collection("users").document(uid).collection("activity").document()
        
        db.collection("friendships")
            .whereField("ownerUserId", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                
                guard let self = self else { return }
                
                let friendshipDocs = snapshot?.documents ?? []
                let friendshipByName: [String: QueryDocumentSnapshot] = Dictionary(
                    uniqueKeysWithValues: friendshipDocs.map {
                        (
                            ($0.data()["friendName"] as? String ?? "")
                                .trimmingCharacters(in: .whitespacesAndNewlines),
                            $0
                        )
                    }
                )
                
                self.db.runTransaction({ transaction, errorPointer in
                    let groupSnapshot: DocumentSnapshot
                    do {
                        groupSnapshot = try transaction.getDocument(groupRef)
                    } catch let error as NSError {
                        errorPointer?.pointee = error
                        return nil
                    }
                    
                    let currentAmount = groupSnapshot.data()?["balanceAmount"] as? Double ?? 0
                    let currentDirection = groupSnapshot.data()?["balanceDirection"] as? String ?? "owesYou"
                    let signedCurrent = currentDirection == "owesYou" ? currentAmount : -currentAmount
                    
                    let signedChange = groupDraft.yourNetAmount
                    let signedUpdated = signedCurrent + signedChange
                    
                    let updatedAmount = abs(signedUpdated)
                    let updatedDirection = signedUpdated >= 0 ? "owesYou" : "youOwe"
                    
                    let actualTotalFromPaidAmounts = groupDraft.paidAmounts.values.reduce(0, +)
                    let finalTotalAmount = actualTotalFromPaidAmounts > 0 ? actualTotalFromPaidAmounts : totalAmount
                    
                    let splitParticipants = self.normalizedNames(groupDraft.splitWith)
                    let splitCount = max(splitParticipants.count, 1)
                    let perPersonShare = finalTotalAmount / Double(splitCount)
                    let yourOwnShare = splitParticipants.contains(where: { $0.uppercased() == "YOU" })
                    ? perPersonShare
                    : 0
                    
                    let expenseData: [String: Any] = [
                        "ownerUserId": uid,
                        "targetType": "group",
                        "targetDocumentId": groupDocumentId,
                        "description": description,
                        "amount": finalTotalAmount,
                        "category": category,
                        "dateText": dateText,
                        "monthKey": monthKey,
                        "createdAt": FieldValue.serverTimestamp(),
                        "paidBy": groupDraft.paidBy,
                        "splitWith": groupDraft.splitWith,
                        "yourNetAmount": groupDraft.yourNetAmount,
                        "paidAmounts": groupDraft.paidAmounts,
                        "yourOwnShare": yourOwnShare,
                        "receiptURL": receiptURL ?? "",
                        "groupName": groupName,
                        "locationName": locationName,
                        "locationAddress": locationAddress,
                        "latitude": latitude as Any,
                        "longitude": longitude as Any,
                        
                    ]
                    
                    transaction.setData(expenseData, forDocument: expenseRef)
                    
                    transaction.setData([
                        "balanceAmount": updatedAmount,
                        "balanceDirection": updatedDirection,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], forDocument: groupRef, merge: true)
                    
                    let normalizedFriendNames = Set(
                        (groupMemberNames + groupDraft.paidBy + groupDraft.splitWith)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty && $0.uppercased() != "YOU" }
                    )
                    
                    for friendName in normalizedFriendNames {
                        guard let friendDoc = friendshipByName[friendName] else { continue }
                        
                        let friendRef = friendDoc.reference
                        let friendData = friendDoc.data()
                        
                        let friendAmount = friendData["balanceAmount"] as? Double ?? 0
                        let friendDirection = friendData["balanceDirection"] as? String ?? "owesYou"
                        let signedFriend = friendDirection == "owesYou" ? friendAmount : -friendAmount
                        
                        let friendPaidAmount = groupDraft.paidAmounts[friendName] ?? 0
                        let friendSplitShare = splitParticipants.contains(friendName) ? perPersonShare : 0
                        let signedFriendChange = friendSplitShare - friendPaidAmount
                        let updatedFriendSigned = signedFriend + signedFriendChange
                        
                        let finalFriendAmount = abs(updatedFriendSigned)
                        let finalFriendDirection = updatedFriendSigned >= 0 ? "owesYou" : "youOwe"
                        
                        transaction.setData([
                            "balanceAmount": finalFriendAmount,
                            "balanceDirection": finalFriendDirection,
                            "updatedAt": FieldValue.serverTimestamp()
                        ], forDocument: friendRef, merge: true)
                        
                        let mirrorAmount = abs(signedFriendChange)
                        if mirrorAmount > 0.0001 {
                            self.saveGroupFriendMirrorExpense(
                                transaction: transaction,
                                ownerUserId: uid,
                                parentGroupExpenseId: expenseRef.documentID,
                                friendDocumentId: friendDoc.documentID,
                                friendName: friendName,
                                groupDocumentId: groupDocumentId,
                                groupName: groupName,
                                description: description,
                                amount: mirrorAmount,
                                direction: signedFriendChange >= 0 ? "owesYou" : "youOwe",
                                category: category,
                                dateText: dateText,
                                monthKey: monthKey,
                                receiptURL: receiptURL ?? "",
                                locationName: locationName,
                                locationAddress: locationAddress,
                                latitude: latitude,
                                longitude: longitude
                            )
                        }
                    }
                    
                    let activityData: [String: Any] = [
                        "title": description,
                        "subtitle": "Group · \(groupName)",
                        "amount": yourOwnShare,
                        "date": dateText,
                        "monthKey": monthKey,
                        "category": category,
                        "entryType": "expense",
                        "activityExpenseId": expenseRef.documentID,
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    
                    transaction.setData(activityData, forDocument: activityRef)
                    
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
    
    private func locateActivityDocumentIdForExpense(
        ownerUserId: String,
        expenseDocumentId: String,
        oldTitle: String,
        dateText: String,
        monthKey: String,
        completion: @escaping (String?) -> Void
    ) {
        let activityRef = db.collection("users").document(ownerUserId).collection("activity")
        
        activityRef
            .whereField("activityExpenseId", isEqualTo: expenseDocumentId)
            .limit(to: 1)
            .getDocuments { [weak self] linkedSnapshot, _ in
                if let linkedId = linkedSnapshot?.documents.first?.documentID {
                    completion(linkedId)
                    return
                }
                
                self?.db.collection("users")
                    .document(ownerUserId)
                    .collection("activity")
                    .whereField("entryType", isEqualTo: "expense")
                    .whereField("monthKey", isEqualTo: monthKey)
                    .getDocuments { snapshot, _ in
                        let fallback = snapshot?.documents.first(where: {
                            let data = $0.data()
                            let title = data["title"] as? String ?? ""
                            let date = data["date"] as? String ?? ""
                            return title == oldTitle && date == dateText
                        })?.documentID
                        
                        completion(fallback)
                    }
            }
    }
    
    func updateExpense(
        expenseDocumentId: String,
        newDescription: String,
        newTotalAmount: Double,
        newCategory: String,
        newLocationName: String,
        newLocationAddress: String,
        newLatitude: Double?,
        newLongitude: Double?,
        groupDraft: GroupExpenseDraft? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ){
        let expenseRef = db.collection("expenses").document(expenseDocumentId)

        expenseRef.getDocument { [weak self] snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let self, let data = snapshot?.data() else {
                completion(.success(()))
                return
            }

            let ownerUserId = data["ownerUserId"] as? String ?? self.currentUserId ?? ""
            let oldTitle = data["description"] as? String ?? ""
            let dateText = data["dateText"] as? String ?? ""
            let monthKey = data["monthKey"] as? String ?? ""
            let isGroupMirror = data["isGroupMirror"] as? Bool ?? false
            let parentGroupExpenseId = data["parentGroupExpenseId"] as? String ?? ""
            let targetType = data["targetType"] as? String ?? "friend"
            let targetDocumentId = data["targetDocumentId"] as? String ?? ""

            // If editing a friend-side mirror, edit the real parent group expense instead.
            if isGroupMirror, !parentGroupExpenseId.isEmpty, targetType == "friend" {
                self.updateExpense(
                    expenseDocumentId: parentGroupExpenseId,
                    newDescription: newDescription,
                    newTotalAmount: newTotalAmount,
                    newCategory: newCategory,
                    newLocationName: newLocationName,
                    newLocationAddress: newLocationAddress,
                    newLatitude: newLatitude,
                    newLongitude: newLongitude,
                    groupDraft: groupDraft,
                    completion: completion
                )
                return
            }

            self.locateActivityDocumentIdForExpense(
                ownerUserId: ownerUserId,
                expenseDocumentId: expenseDocumentId,
                oldTitle: oldTitle,
                dateText: dateText,
                monthKey: monthKey
            ) { activityDocumentId in

                // -----------------------------
                // Friend expense update
                // -----------------------------
                if targetType == "friend" {
                    let targetRef = self.db.collection("friendships").document(targetDocumentId)
                    let oldAmount = data["amount"] as? Double ?? 0
                    let oldDirection = data["direction"] as? String ?? "owesYou"
                    let friendName = data["friendName"] as? String ?? ""

                    targetRef.getDocument { targetSnapshot, targetError in
                        if let targetError {
                            completion(.failure(targetError))
                            return
                        }

                        let currentAmount = targetSnapshot?.data()?["balanceAmount"] as? Double ?? 0
                        let currentDirection = targetSnapshot?.data()?["balanceDirection"] as? String ?? "owesYou"

                        let signedCurrent = currentDirection == "owesYou" ? currentAmount : -currentAmount
                        let oldSignedChange = oldDirection == "owesYou" ? oldAmount : -oldAmount
                        let newSignedChange = oldDirection == "owesYou" ? newTotalAmount : -newTotalAmount
                        let signedUpdated = signedCurrent - oldSignedChange + newSignedChange

                        let batch = self.db.batch()

                        batch.setData([
                            "description": newDescription,
                            "amount": newTotalAmount,
                            "category": newCategory,
                            "locationName": newLocationName,
                            "locationAddress": newLocationAddress,
                            "latitude": newLatitude as Any,
                            "longitude": newLongitude as Any,
                            "updatedAt": FieldValue.serverTimestamp()
                        ], forDocument: expenseRef, merge: true)
                        
                        batch.setData([
                            "balanceAmount": abs(signedUpdated),
                            "balanceDirection": signedUpdated >= 0 ? "owesYou" : "youOwe",
                            "updatedAt": FieldValue.serverTimestamp()
                        ], forDocument: targetRef, merge: true)

                        if let activityDocumentId {
                            let resolvedFriendName = friendName.isEmpty
                                ? (targetSnapshot?.data()?["friendName"] as? String ?? "")
                                : friendName

                            let subtitle = oldDirection == "owesYou"
                                ? "You paid · \(resolvedFriendName)"
                                : "\(resolvedFriendName) paid"

                            let activityRef = self.db.collection("users")
                                .document(ownerUserId)
                                .collection("activity")
                                .document(activityDocumentId)

                            batch.setData([
                                "title": newDescription,
                                "subtitle": subtitle,
                                "amount": newTotalAmount,
                                "category": newCategory,
                                "activityExpenseId": expenseDocumentId
                            ], forDocument: activityRef, merge: true)
                        }

                        batch.commit { batchError in
                            if let batchError {
                                completion(.failure(batchError))
                            } else {
                                completion(.success(()))
                            }
                        }
                    }

                    return
                }

                // -----------------------------
                // Group expense update
                // -----------------------------
                let groupRef = self.db.collection("groups").document(targetDocumentId)

                self.fetchGroupMirrorExpenseDocs(parentGroupExpenseId: expenseDocumentId) { mirrorResult in
                    switch mirrorResult {
                    case .failure(let error):
                        completion(.failure(error))

                    case .success(let mirrorDocs):
                        groupRef.getDocument { groupSnapshot, groupError in
                            if let groupError {
                                completion(.failure(groupError))
                                return
                            }

                            let oldPaidBy = self.normalizedNames(data["paidBy"] as? [String] ?? [])
                            let oldSplitWith = self.normalizedNames(data["splitWith"] as? [String] ?? [])
                            let oldPaidAmounts = self.parseDoubleMap(data["paidAmounts"])
                            let oldAmount = data["amount"] as? Double ?? 0
                            let storedGroupName = data["groupName"] as? String ?? ""
                            let resolvedGroupName = storedGroupName.isEmpty
                                ? (groupSnapshot?.data()?["name"] as? String ?? "")
                                : storedGroupName

                            let resolvedPaidBy = self.normalizedNames(groupDraft?.paidBy ?? oldPaidBy)
                            let resolvedSplitWith = self.normalizedNames(groupDraft?.splitWith ?? oldSplitWith)

                            let finalPaidBy = resolvedPaidBy.isEmpty ? ["YOU"] : resolvedPaidBy
                            let finalSplitWith = resolvedSplitWith.isEmpty ? ["YOU"] : resolvedSplitWith

                            let newPaidAmounts: [String: Double]
                            if let draft = groupDraft, !draft.paidAmounts.isEmpty {
                                newPaidAmounts = draft.paidAmounts
                            } else if !oldPaidAmounts.isEmpty {
                                let ratio = oldAmount > 0 ? newTotalAmount / oldAmount : 1
                                var scaled: [String: Double] = [:]
                                for (key, value) in oldPaidAmounts {
                                    scaled[key] = value * ratio
                                }
                                newPaidAmounts = scaled
                            } else {
                                let evenShare = newTotalAmount / Double(max(finalPaidBy.count, 1))
                                var evenlySplit: [String: Double] = [:]
                                for payer in finalPaidBy {
                                    evenlySplit[payer] = evenShare
                                }
                                newPaidAmounts = evenlySplit
                            }

                            let oldSplitCount = max(oldSplitWith.count, 1)
                            let oldPerPersonShare = oldAmount / Double(oldSplitCount)
                            let oldYourPaid = oldPaidAmounts["YOU"] ?? 0
                            let oldYourOwnShare = oldSplitWith.contains("YOU") ? oldPerPersonShare : 0
                            let oldYourNetAmount = oldYourPaid - oldYourOwnShare

                            let newSplitCount = max(finalSplitWith.count, 1)
                            let newPerPersonShare = newTotalAmount / Double(newSplitCount)
                            let newYourPaid = newPaidAmounts["YOU"] ?? 0
                            let newYourOwnShare = finalSplitWith.contains("YOU") ? newPerPersonShare : 0
                            let newYourNetAmount = newYourPaid - newYourOwnShare

                            let currentGroupAmount = groupSnapshot?.data()?["balanceAmount"] as? Double ?? 0
                            let currentGroupDirection = groupSnapshot?.data()?["balanceDirection"] as? String ?? "owesYou"
                            let signedCurrentGroup = currentGroupDirection == "owesYou" ? currentGroupAmount : -currentGroupAmount
                            let signedUpdatedGroup = signedCurrentGroup - oldYourNetAmount + newYourNetAmount

                            let batch = self.db.batch()

                            batch.setData([
                                "description": newDescription,
                                "amount": newTotalAmount,
                                "category": newCategory,
                                "locationName": newLocationName,
                                "locationAddress": newLocationAddress,
                                "latitude": newLatitude as Any,
                                "longitude": newLongitude as Any,
                                "paidBy": finalPaidBy,
                                "splitWith": finalSplitWith,
                                "paidAmounts": newPaidAmounts,
                                "yourNetAmount": newYourNetAmount,
                                "yourOwnShare": newYourOwnShare,
                                "groupName": resolvedGroupName,
                                "updatedAt": FieldValue.serverTimestamp()
                            ], forDocument: expenseRef, merge: true)
                            
                            batch.setData([
                                "balanceAmount": abs(signedUpdatedGroup),
                                "balanceDirection": signedUpdatedGroup >= 0 ? "owesYou" : "youOwe",
                                "updatedAt": FieldValue.serverTimestamp()
                            ], forDocument: groupRef, merge: true)

                            if let activityDocumentId {
                                let activityRef = self.db.collection("users")
                                    .document(ownerUserId)
                                    .collection("activity")
                                    .document(activityDocumentId)

                                batch.setData([
                                    "title": newDescription,
                                    "subtitle": "Group · \(resolvedGroupName)",
                                    "amount": newYourOwnShare,
                                    "category": newCategory,
                                    "activityExpenseId": expenseDocumentId
                                ], forDocument: activityRef, merge: true)
                            }

                            let affectedFriendNames = Set(
                                (oldPaidBy + oldSplitWith + finalPaidBy + finalSplitWith)
                                    .filter { $0.uppercased() != "YOU" }
                            )

                            let mirrorByFriendDocId: [String: QueryDocumentSnapshot] = Dictionary(
                                uniqueKeysWithValues: mirrorDocs.compactMap { doc in
                                    guard let friendDocId = doc.data()["targetDocumentId"] as? String else { return nil }
                                    return (friendDocId, doc)
                                }
                            )

                            self.db.collection("friendships")
                                .whereField("ownerUserId", isEqualTo: ownerUserId)
                                .getDocuments { friendshipsSnapshot, friendshipsError in
                                    if let friendshipsError {
                                        completion(.failure(friendshipsError))
                                        return
                                    }

                                    let friendshipDocs = friendshipsSnapshot?.documents ?? []
                                    let friendshipByName: [String: QueryDocumentSnapshot] = Dictionary(
                                        uniqueKeysWithValues: friendshipDocs.map {
                                            (
                                                ($0.data()["friendName"] as? String ?? "")
                                                    .trimmingCharacters(in: .whitespacesAndNewlines),
                                                $0
                                            )
                                        }
                                    )

                                    for friendName in affectedFriendNames {
                                        guard let friendDoc = friendshipByName[friendName] else { continue }

                                        let friendRef = friendDoc.reference
                                        let friendData = friendDoc.data()

                                        let currentFriendAmount = friendData["balanceAmount"] as? Double ?? 0
                                        let currentFriendDirection = friendData["balanceDirection"] as? String ?? "owesYou"
                                        let signedCurrentFriend = currentFriendDirection == "owesYou" ? currentFriendAmount : -currentFriendAmount

                                        let oldFriendPaid = oldPaidAmounts[friendName] ?? 0
                                        let oldFriendSplitShare = oldSplitWith.contains(friendName) ? oldPerPersonShare : 0
                                        let oldFriendChange = oldFriendSplitShare - oldFriendPaid

                                        let newFriendPaid = newPaidAmounts[friendName] ?? 0
                                        let newFriendSplitShare = finalSplitWith.contains(friendName) ? newPerPersonShare : 0
                                        let newFriendChange = newFriendSplitShare - newFriendPaid

                                        let signedUpdatedFriend = signedCurrentFriend - oldFriendChange + newFriendChange

                                        batch.setData([
                                            "balanceAmount": abs(signedUpdatedFriend),
                                            "balanceDirection": signedUpdatedFriend >= 0 ? "owesYou" : "youOwe",
                                            "updatedAt": FieldValue.serverTimestamp()
                                        ], forDocument: friendRef, merge: true)

                                        let mirrorAmount = abs(newFriendChange)
                                        let existingMirrorDoc = mirrorByFriendDocId[friendDoc.documentID]

                                        if mirrorAmount <= 0.0001 {
                                            if let existingMirrorDoc {
                                                batch.deleteDocument(existingMirrorDoc.reference)
                                            }
                                            continue
                                        }

                                        if let existingMirrorDoc {
                                            batch.setData([
                                                "description": newDescription,
                                                "amount": mirrorAmount,
                                                "direction": newFriendChange >= 0 ? "owesYou" : "youOwe",
                                                "category": newCategory,
                                                "dateText": dateText,
                                                "monthKey": monthKey,
                                                "receiptURL": data["receiptURL"] as? String ?? "",
                                                "groupName": resolvedGroupName,
                                                "updatedAt": FieldValue.serverTimestamp()
                                            ], forDocument: existingMirrorDoc.reference, merge: true)
                                        } else {
                                            let mirrorRef = self.db.collection("expenses").document()
                                            batch.setData([
                                                "ownerUserId": ownerUserId,
                                                "targetType": "friend",
                                                "targetDocumentId": friendDoc.documentID,
                                                "description": newDescription,
                                                "amount": mirrorAmount,
                                                "direction": newFriendChange >= 0 ? "owesYou" : "youOwe",
                                                "category": newCategory,
                                                "dateText": dateText,
                                                "monthKey": monthKey,
                                                "createdAt": FieldValue.serverTimestamp(),
                                                "receiptURL": data["receiptURL"] as? String ?? "",
                                                "isGroupMirror": true,
                                                "parentGroupExpenseId": expenseDocumentId,
                                                "groupDocumentId": targetDocumentId,
                                                "groupName": resolvedGroupName,
                                                "friendName": friendName
                                            ], forDocument: mirrorRef)
                                        }
                                    }

                                    batch.commit { batchError in
                                        if let batchError {
                                            completion(.failure(batchError))
                                        } else {
                                            completion(.success(()))
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
    func deleteExpense(
        expenseDocumentId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let expenseRef = db.collection("expenses").document(expenseDocumentId)

        expenseRef.getDocument { [weak self] snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let self, let data = snapshot?.data() else {
                completion(.success(()))
                return
            }

            let ownerUserId = data["ownerUserId"] as? String ?? self.currentUserId ?? ""
            let oldTitle = data["description"] as? String ?? ""
            let dateText = data["dateText"] as? String ?? ""
            let monthKey = data["monthKey"] as? String ?? ""
            let isGroupMirror = data["isGroupMirror"] as? Bool ?? false
            let parentGroupExpenseId = data["parentGroupExpenseId"] as? String ?? ""
            let targetType = data["targetType"] as? String ?? "friend"
            let targetDocumentId = data["targetDocumentId"] as? String ?? ""

            // If user tries to delete a friend-side mirror, delete the real parent group expense instead.
            if isGroupMirror, !parentGroupExpenseId.isEmpty, targetType == "friend" {
                self.deleteExpense(
                    expenseDocumentId: parentGroupExpenseId,
                    completion: completion
                )
                return
            }

            self.locateActivityDocumentIdForExpense(
                ownerUserId: ownerUserId,
                expenseDocumentId: expenseDocumentId,
                oldTitle: oldTitle,
                dateText: dateText,
                monthKey: monthKey
            ) { activityDocumentId in

                // -----------------------------
                // Friend expense delete
                // -----------------------------
                if targetType == "friend" {
                    let targetRef = self.db.collection("friendships").document(targetDocumentId)
                    let oldAmount = data["amount"] as? Double ?? 0
                    let oldDirection = data["direction"] as? String ?? "owesYou"

                    targetRef.getDocument { targetSnapshot, targetError in
                        if let targetError {
                            completion(.failure(targetError))
                            return
                        }

                        let currentAmount = targetSnapshot?.data()?["balanceAmount"] as? Double ?? 0
                        let currentDirection = targetSnapshot?.data()?["balanceDirection"] as? String ?? "owesYou"
                        let signedCurrent = currentDirection == "owesYou" ? currentAmount : -currentAmount
                        let oldSignedChange = oldDirection == "owesYou" ? oldAmount : -oldAmount
                        let signedUpdated = signedCurrent - oldSignedChange

                        let batch = self.db.batch()
                        batch.deleteDocument(expenseRef)
                        batch.setData([
                            "balanceAmount": abs(signedUpdated),
                            "balanceDirection": signedUpdated >= 0 ? "owesYou" : "youOwe",
                            "updatedAt": FieldValue.serverTimestamp()
                        ], forDocument: targetRef, merge: true)

                        if let activityDocumentId {
                            let activityRef = self.db.collection("users")
                                .document(ownerUserId)
                                .collection("activity")
                                .document(activityDocumentId)
                            batch.deleteDocument(activityRef)
                        }

                        batch.commit { batchError in
                            if let batchError {
                                completion(.failure(batchError))
                            } else {
                                completion(.success(()))
                            }
                        }
                    }

                    return
                }

                // -----------------------------
                // Group expense delete
                // -----------------------------
                let groupRef = self.db.collection("groups").document(targetDocumentId)

                self.fetchGroupMirrorExpenseDocs(parentGroupExpenseId: expenseDocumentId) { mirrorResult in
                    switch mirrorResult {
                    case .failure(let error):
                        completion(.failure(error))

                    case .success(let mirrorDocs):
                        groupRef.getDocument { groupSnapshot, groupError in
                            if let groupError {
                                completion(.failure(groupError))
                                return
                            }

                            let currentGroupAmount = groupSnapshot?.data()?["balanceAmount"] as? Double ?? 0
                            let currentGroupDirection = groupSnapshot?.data()?["balanceDirection"] as? String ?? "owesYou"
                            let signedCurrentGroup = currentGroupDirection == "owesYou" ? currentGroupAmount : -currentGroupAmount
                            let oldYourNetAmount = data["yourNetAmount"] as? Double ?? 0
                            let signedUpdatedGroup = signedCurrentGroup - oldYourNetAmount

                            let batch = self.db.batch()

                            // Delete main group expense
                            batch.deleteDocument(expenseRef)

                            // Delete activity row
                            if let activityDocumentId {
                                let activityRef = self.db.collection("users")
                                    .document(ownerUserId)
                                    .collection("activity")
                                    .document(activityDocumentId)
                                batch.deleteDocument(activityRef)
                            }

                            // Update group balance
                            batch.setData([
                                "balanceAmount": abs(signedUpdatedGroup),
                                "balanceDirection": signedUpdatedGroup >= 0 ? "owesYou" : "youOwe",
                                "updatedAt": FieldValue.serverTimestamp()
                            ], forDocument: groupRef, merge: true)

                            // Reverse each friend using mirror docs and delete mirror docs
                            let dispatchGroup = DispatchGroup()
                            var friendSnapshots: [(DocumentReference, Double, String, [String: Any])] = []
                            var firstError: Error?

                            for mirrorDoc in mirrorDocs {
                                let mirrorData = mirrorDoc.data()
                                let friendDocumentId = mirrorData["targetDocumentId"] as? String ?? ""
                                if friendDocumentId.isEmpty { continue }

                                let mirrorAmount = mirrorData["amount"] as? Double ?? 0
                                let mirrorDirection = mirrorData["direction"] as? String ?? "owesYou"
                                let friendRef = self.db.collection("friendships").document(friendDocumentId)

                                dispatchGroup.enter()
                                friendRef.getDocument { friendSnapshot, friendError in
                                    if let friendError, firstError == nil {
                                        firstError = friendError
                                    } else {
                                        friendSnapshots.append((
                                            friendRef,
                                            mirrorAmount,
                                            mirrorDirection,
                                            friendSnapshot?.data() ?? [:]
                                        ))
                                    }
                                    dispatchGroup.leave()
                                }
                            }

                            dispatchGroup.notify(queue: .main) {
                                if let firstError {
                                    completion(.failure(firstError))
                                    return
                                }

                                for (friendRef, mirrorAmount, mirrorDirection, friendData) in friendSnapshots {
                                    let currentFriendAmount = friendData["balanceAmount"] as? Double ?? 0
                                    let currentFriendDirection = friendData["balanceDirection"] as? String ?? "owesYou"
                                    let signedCurrentFriend = currentFriendDirection == "owesYou" ? currentFriendAmount : -currentFriendAmount
                                    let signedMirrorChange = mirrorDirection == "owesYou" ? mirrorAmount : -mirrorAmount
                                    let signedUpdatedFriend = signedCurrentFriend - signedMirrorChange

                                    batch.setData([
                                        "balanceAmount": abs(signedUpdatedFriend),
                                        "balanceDirection": signedUpdatedFriend >= 0 ? "owesYou" : "youOwe",
                                        "updatedAt": FieldValue.serverTimestamp()
                                    ], forDocument: friendRef, merge: true)
                                }

                                for mirrorDoc in mirrorDocs {
                                    batch.deleteDocument(mirrorDoc.reference)
                                }

                                batch.commit { batchError in
                                    if let batchError {
                                        completion(.failure(batchError))
                                    } else {
                                        completion(.success(()))
                                    }
                                }
                            }
                        }
                    }
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
        
        func updateGroupBalanceAfterSettlement(
            groupDocumentId: String,
            amount: Double,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            let groupRef = db.collection("groups").document(groupDocumentId)
            
            groupRef.getDocument { [weak self] snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                
                guard let self else {
                    completion(.success(()))
                    return
                }
                
                self.db.runTransaction({ transaction, errorPointer in
                    let groupSnapshot: DocumentSnapshot
                    do {
                        groupSnapshot = try transaction.getDocument(groupRef)
                    } catch let error as NSError {
                        errorPointer?.pointee = error
                        return nil
                    }
                    
                    let currentAmount = groupSnapshot.data()?["balanceAmount"] as? Double ?? 0
                    let currentDirection = groupSnapshot.data()?["balanceDirection"] as? String ?? "owesYou"
                    let signedCurrent = currentDirection == "owesYou" ? currentAmount : -currentAmount
                    
                    let signedUpdated: Double
                    if signedCurrent > 0 {
                        signedUpdated = signedCurrent - amount
                    } else {
                        signedUpdated = signedCurrent + amount
                    }
                    
                    let updatedAmount = abs(signedUpdated)
                    let updatedDirection = signedUpdated >= 0 ? "owesYou" : "youOwe"
                    
                    transaction.setData([
                        "balanceAmount": updatedAmount,
                        "balanceDirection": updatedDirection,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], forDocument: groupRef, merge: true)
                    
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
        
        func saveGroupSettlement(
            groupDocumentId: String,
            groupName: String,
            amount: Double,
            method: String,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            let groupRef = db.collection("groups").document(groupDocumentId)
            
            groupRef.getDocument { [weak self] snapshot, error in
                if let error {
                    completion(.failure(error))
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
                        targetSnapshot = try transaction.getDocument(groupRef)
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
                        "targetType": "group",
                        "groupDocumentId": groupDocumentId,
                        "groupName": groupName,
                        "amount": amount,
                        "method": method,
                        "dateText": dayText,
                        "monthKey": monthKey,
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    
                    let activityData: [String: Any] = [
                        "title": "Settle up in \(groupName)",
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
                    ], forDocument: groupRef, merge: true)
                    
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

