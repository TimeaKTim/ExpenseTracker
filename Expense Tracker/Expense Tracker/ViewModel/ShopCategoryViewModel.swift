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
    @Published var shops: [Shop] = []
    private var db = Firestore.firestore()
    
    func fetchCategories() {
        db.collection("Category")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting categories: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot {
                    DispatchQueue.main.async {
                        self.categories = snapshot.documents.compactMap { document in
                            do {
                                return try document.data(as: ShopCategory.self)
                            } catch {
                                print("Error parsing category for document \(document.documentID): \(error.localizedDescription)")
                                return nil
                            }
                        }
                    }
                }
            }
    }
    
    func fetchStoreByTitle(title: String) async -> Shop? {
        do {
            let snapshot = try await db.collection("Shops")
                .whereField("title", isEqualTo: title)
                .limit(to: 1)
                .getDocuments()
            
            if let document = snapshot.documents.first {
                return try document.data(as: Shop.self)
            } else {
                return nil
            }
        } catch {
            print("❌ Error fetching store: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchAllStores() async -> [Shop] {
        do {
            let snapshot = try await db.collection("Shops").getDocuments()
            let shops = try snapshot.documents.map { try $0.data(as: Shop.self) }
            return shops
        } catch {
            print("❌ Error fetching all stores: \(error.localizedDescription)")
            return []
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

    @MainActor
    func saveShopsToDatabase(_ shops: Set<Shop>) async {
        for shop in shops {
            do {
                let existingShop = await fetchStoreByTitle(title: shop.title.lowercased())

                if existingShop == nil {
                    try db.collection("Shops").addDocument(from: shop)
                    print("✅ Shop added to database: \(shop.title)")
                } else {
                    print("⚠️ Shop already exists: \(shop.title) - Skipping insertion")
                }
            } catch {
                print("❌ Error saving shop: \(error.localizedDescription)")
            }
        }
    }
}

