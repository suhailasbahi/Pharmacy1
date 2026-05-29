// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datasources/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User not found');
    
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
    required String licenseNumber,
    required String regionId,
    String? address,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    
    final newUser = UserModel(
      id: uid,
      email: email,
      name: name,
      phone: phone,
      userType: userType,
      parentCompanyId: null,
      branchId: null,
      roleId: userType == 'company' ? 'role_owner' : 'role_pharmacy_owner',
      customPermissions: [],
      isActive: true,
      createdAt: DateTime.now(),
      licenseNumber: licenseNumber,
      isApproved: userType == 'pharmacy' ? false : true,
      address: address ?? '',
      companyId: userType == 'company' ? uid : null,
      pharmacyId: userType == 'pharmacy' ? uid : null,
      regionId: regionId,
      assignedRegions: userType == 'company' ? Region.allRegions.map((r) => r.id).toList() : [],
    );
    
    await _firestore.collection('users').doc(uid).set(newUser.toMap());
    return newUser;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}