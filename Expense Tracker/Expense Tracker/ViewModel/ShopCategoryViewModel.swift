//
//  ShopCategoryViewModel.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 31.03.2025.
//

import FirebaseFirestore
import Combine

class ShopCategoryViewModel: ObservableObject {
    @Published var categories: [ShopCategory] = []
    private var db = Firestore.firestore()
    
    func fetchCategories() {
        db.collection("Category")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting categories: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot {
                    self.categories = snapshot.documents.compactMap { document in
                        do {
                            let category = try document.data(as: ShopCategory.self)
                            return category
                        } catch {
                            print("Error parsing category for document \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                }
            }
    }
    
    func addCategoryToDatabase(_ category: ShopCategory) {
        do {
            let _ = try db.collection("Category").addDocument(from: category) { error in
                if let error = error {
                    print("Error adding category: \(error.localizedDescription)")
                } else {
                    print("Category successfully added!")
                    
                    DispatchQueue.main.async {
                        self.categories.append(category)
                    }
                }
            }
        } catch {
            print("Error encoding category: \(error.localizedDescription)")
        }
    }
}

