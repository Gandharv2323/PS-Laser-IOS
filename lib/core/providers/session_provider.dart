import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/secure_auth_service.dart';

enum UserRole { worker, supervisor, manager, owner }

class UserSession {
  final String userId; // Firestore document ID (String)
  final String userName;
  final UserRole role;
  final String department;
  final String shift;
  final List<String> teamIds;
  final bool isLoggedIn;

  const UserSession({
    required this.userId,
    required this.userName,
    required this.role,
    required this.department,
    required this.shift,
    required this.teamIds,
    this.isLoggedIn = true,
  });

  static const UserSession empty = UserSession(
    userId: '',
    userName: '',
    role: UserRole.worker,
    department: '',
    shift: '',
    teamIds: [],
    isLoggedIn: false,
  );

  bool get canViewPayroll => role == UserRole.manager || role == UserRole.owner;
  bool get canViewClients => role == UserRole.manager || role == UserRole.owner;
  bool get canViewMachines => role != UserRole.worker;
  bool get canViewCylinders => role != UserRole.worker;
  bool get canViewInventory => role != UserRole.worker;
  bool get canCreateWorkOrder => role != UserRole.worker;
  bool get canApproveLeave => role != UserRole.worker;
  bool get canViewSystemSettings => role == UserRole.owner;
  bool get canViewIndividualPayroll => role == UserRole.owner;
  bool get isOwner => role == UserRole.owner;
  bool get isManager => role == UserRole.manager;
  bool get isSupervisor => role == UserRole.supervisor;
}

class SessionProvider extends ChangeNotifier {
  UserSession _session = UserSession.empty;

  UserSession get session => _session;
  bool get isLoggedIn => _session.isLoggedIn;

  Future<void> login({
    required String userId,
    required String userName,
    required UserRole role,
    required String department,
    required String shift,
    required List<String> teamIds,
  }) async {
    _session = UserSession(
      userId: userId,
      userName: userName,
      role: role,
      department: department,
      shift: shift,
      teamIds: teamIds,
      isLoggedIn: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_name', userName);
    await prefs.setString('user_role', role.name);
    await prefs.setString('department', department);
    await prefs.setString('shift', shift);
    notifyListeners();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? prefs.getInt('user_id')?.toString();
    if (userId == null || userId.isEmpty) return;

    // Check if secure session is still valid
    final isValid = await SecureAuthService.isSessionValid();
    if (!isValid) {
      await logout();
      return;
    }

    final roleName = prefs.getString('user_role') ?? 'worker';
    _session = UserSession(
      userId: userId,
      userName: prefs.getString('user_name') ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => UserRole.worker,
      ),
      department: prefs.getString('department') ?? '',
      shift: prefs.getString('shift') ?? '',
      teamIds: [],
      isLoggedIn: true,
    );
    notifyListeners();
  }

  /// Clears session data and signals GoRouter to redirect.
  /// Call [onLoggedOut] after awaiting to imperatively navigate to /login
  /// — this is more reliable on mobile than relying solely on refreshListenable.
  Future<void> logout({VoidCallback? onLoggedOut}) async {
    await SecureAuthService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _session = UserSession.empty;
    // Navigate first (before notifyListeners) so the route change
    // is already in flight when GoRouter re-evaluates the redirect guard.
    onLoggedOut?.call();
    notifyListeners();
  }
}
