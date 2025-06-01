import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan user ID atau device ID
  String get _userId {
    final user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    }
    // Jika tidak ada user yang login, gunakan anonymous ID
    // Anda bisa menggunakan device ID atau anonymous auth
    return 'anonymous_user'; // Sementara, sebaiknya gunakan device ID yang unik
  }

  // Collection reference untuk favorit user
  CollectionReference get _favoritesCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites');
  }

  // Mendapatkan semua laporan favorit
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final QuerySnapshot snapshot = await _favoritesCollection
          .orderBy('addedAt', descending: true)
          .get();
      
      print('Getting favorites - Found: ${snapshot.docs.length} items');
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Menambahkan document ID
        return data;
      }).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  // Menambahkan laporan ke favorit
  Future<void> addFavorite(String reportId, Map<String, dynamic> reportData) async {
    try {
      // Menambahkan timestamp untuk tracking
      reportData['addedAt'] = FieldValue.serverTimestamp();
      
      await _favoritesCollection.doc(reportId).set(reportData);
      
      print('Adding favorite - ID: $reportId, Success: true');
    } catch (e) {
      print('Error adding favorite: $e');
      throw Exception('Gagal menambahkan ke favorit: $e');
    }
  }

  // Menghapus laporan dari favorit
  Future<void> removeFavorite(String reportId) async {
    try {
      await _favoritesCollection.doc(reportId).delete();
      print('Removing favorite - ID: $reportId, Success: true');
    } catch (e) {
      print('Error removing favorite: $e');
      throw Exception('Gagal menghapus dari favorit: $e');
    }
  }

  // Mengecek apakah laporan sudah difavoritkan
  Future<bool> isFavorite(String reportId) async {
    try {
      final DocumentSnapshot doc = await _favoritesCollection.doc(reportId).get();
      final isFav = doc.exists;
      print('Checking favorite - ID: $reportId, Is favorite: $isFav');
      return isFav;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Menghapus semua favorit
  Future<void> clearAllFavorites() async {
    try {
      final QuerySnapshot snapshot = await _favoritesCollection.get();
      
      // Batch delete untuk efisiensi
      final WriteBatch batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Cleared all favorites - Count: ${snapshot.docs.length}');
    } catch (e) {
      print('Error clearing favorites: $e');
      throw Exception('Gagal menghapus semua favorit: $e');
    }
  }

  // Stream untuk real-time updates
  Stream<List<Map<String, dynamic>>> getFavoritesStream() {
    return _favoritesCollection
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Mengecek status favorit secara real-time
  Stream<bool> isFavoriteStream(String reportId) {
    return _favoritesCollection
        .doc(reportId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}