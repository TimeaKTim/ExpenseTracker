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
                    print("Found \(snapshot.documents.count) categories.")
                    
                    self.categories = snapshot.documents.compactMap { document in
                        print("Document data for \(document.documentID): \(document.data())")
                        
                        do {
                            let category = try document.data(as: ShopCategory.self)
                            print("Successfully decoded category: \(category)")
                            return category
                        } catch {
                            print("Error parsing category for document \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                    
                    print("Categories loaded: \(self.categories)")
                }
            }
    }
}

