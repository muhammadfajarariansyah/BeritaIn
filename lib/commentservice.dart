import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/comment.dart';

class CommentService {
  static const String _commentsKey = 'comments';

  // Mengambil semua komentar untuk report tertentu
  Future<List<Comment>> getComments(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey);
      
      if (commentsJson == null) {
        return [];
      }

      final Map<String, dynamic> allComments = json.decode(commentsJson);
      final List<dynamic> reportComments = allComments[reportId] ?? [];

      return reportComments
          .map((commentJson) => Comment.fromJson(commentJson))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Urutkan dari terbaru
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Menambah komentar baru
  Future<void> addComment(String reportId, String userName, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey);
      
      Map<String, dynamic> allComments = {};
      if (commentsJson != null) {
        allComments = json.decode(commentsJson);
      }

      // Ambil komentar existing untuk report ini
      List<dynamic> reportComments = allComments[reportId] ?? [];

      // Buat komentar baru
      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reportId: reportId,
        userName: userName,
        message: message,
        createdAt: DateTime.now(),
      );

      // Tambahkan komentar baru
      reportComments.add(newComment.toJson());
      allComments[reportId] = reportComments;

      // Simpan kembali
      await prefs.setString(_commentsKey, json.encode(allComments));
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Gagal menambah komentar');
    }
  }

  // Menghitung jumlah komentar untuk report tertentu
  Future<int> getCommentCount(String reportId) async {
    try {
      final comments = await getComments(reportId);
      return comments.length;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

  // Menghapus komentar (opsional - untuk fitur masa depan)
  Future<void> deleteComment(String reportId, String commentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey);
      
      if (commentsJson == null) return;

      Map<String, dynamic> allComments = json.decode(commentsJson);
      List<dynamic> reportComments = allComments[reportId] ?? [];

      // Hapus komentar dengan ID tertentu
      reportComments.removeWhere((comment) => comment['id'] == commentId);
      allComments[reportId] = reportComments;

      // Simpan kembali
      await prefs.setString(_commentsKey, json.encode(allComments));
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Gagal menghapus komentar');
    }
  }

  // Menghapus semua komentar untuk report tertentu (opsional)
  Future<void> deleteAllCommentsForReport(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString(_commentsKey);
      
      if (commentsJson == null) return;

      Map<String, dynamic> allComments = json.decode(commentsJson);
      allComments.remove(reportId);

      // Simpan kembali
      await prefs.setString(_commentsKey, json.encode(allComments));
    } catch (e) {
      print('Error deleting all comments for report: $e');
      throw Exception('Gagal menghapus semua komentar');
    }
  }
}