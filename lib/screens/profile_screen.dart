import 'package:beritain/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beritain/screens/add_post_screen.dart';
import 'package:beritain/screens/home_screen.dart';
import 'package:beritain/screens/sign_in_screen.dart';
import 'package:beritain/screens/favorite_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userData = userDoc.data() as Map<String, dynamic>?;
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
  body: SafeArea(
    child: Column(
      children: [
        // Top section with edit button and settings
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol edit di sebelah kiri
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.black54,
                  size: 20,
                ),
              ),
              // Tombol pengaturan di sebelah kanan
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),

            const Spacer(flex: 2),

            // Profile section
            Column(
              children: [
                // Profile avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E5266),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 60,
                  ),
                ),

                const SizedBox(height: 24),

                // Name section
                const Text(
                  'Nama Pengguna',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _userData?['fullName'] ?? 'Nama tidak tersedia',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  user?.email ?? 'Email tidak tersedia',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 32),

                // Logout button
                Container(
                  width: 200,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => _showLogoutDialog(context),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 3),

            // Bottom Navigation
            Container(
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFF2E5266),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E5266),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const AddPostScreen()),
                        );
                      },
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}