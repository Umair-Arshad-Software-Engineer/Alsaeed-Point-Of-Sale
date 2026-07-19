import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'add_edit_user_page.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // ── Brand tokens (mirrors HomePage) ────────────────────────────────────────
  static const _navy = Color(0xFF0F1729);
  static const _navyLight = Color(0xFF1A2744);
  static const _emerald = Color(0xFF10B981);
  static const _emeraldLight = Color(0xFFD1FAE5);
  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFEF3C7);
  static const _rose = Color(0xFFE11D48);
  static const _roseLight = Color(0xFFFFE4E6);
  static const _sky = Color(0xFF0EA5E9);
  static const _skyLight = Color(0xFFE0F2FE);
  static const _violet = Color(0xFF7C3AED);
  static const _violetLight = Color(0xFFEDE9FE);
  static const _canvas = Color(0xFFF7F8FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Load users when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    final auth = context.read<AuthController>();

    // Only load if user is super admin
    if (auth.currentUser?.isSuperAdmin == true) {
      print('📋 Loading users on page load');
      await auth.fetchAllUsers();
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: Row(
        children: [
          _Sidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: Consumer<AuthController>(
                    builder: (context, auth, _) {
                      // Check if user is super admin
                      if (auth.currentUser != null && !auth.currentUser!.isSuperAdmin) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 48,
                                color: _textSecondary,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Access Denied',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Only super admins can manage users',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _emerald,
                                  side: const BorderSide(color: _emerald),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Go Back'),
                              ),
                            ],
                          ),
                        );
                      }

                      // Show loading indicator during initial load or when auth is loading
                      if (_isInitialLoad || auth.isLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: _emerald),
                              SizedBox(height: 16),
                              Text(
                                'Loading users...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // If users list is empty, show empty state with refresh
                      if (auth.allUsers.isEmpty) {
                        return _EmptyState(
                          onRefresh: () => auth.fetchAllUsers(),
                        );
                      }

                      return _UserTable(users: auth.allUsers, auth: auth);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: _UserManagementPageState._navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _UserManagementPageState._emerald,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.point_of_sale,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'POSify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          _NavItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          _NavItem(icon: Icons.shopping_cart_outlined, label: 'New Sale'),
          _NavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
          _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
          _NavItem(
              icon: Icons.people_outline_rounded,
              label: 'Users',
              active: true),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
            child: TextButton.icon(
              onPressed: () async {
                await context.read<AuthController>().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout,
                  size: 16, color: Color(0xFF94A3B8)),
              label: const Text('Sign out',
                  style:
                  TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem(
      {required this.icon,
        required this.label,
        this.active = false,
        this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active
            ? _UserManagementPageState._navyLight
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: _UserManagementPageState._navyLight,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: active
                        ? _UserManagementPageState._emerald
                        : const Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                      fontSize: 13.5,
                      fontWeight: active
                          ? FontWeight.w600
                          : FontWeight.w400,
                    )),
                if (active) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: _UserManagementPageState._emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: _UserManagementPageState._surface,
        border: Border(
            bottom: BorderSide(color: _UserManagementPageState._border)),
      ),
      child: Row(
        children: [
          // Breadcrumb
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Dashboard',
                style: TextStyle(
                    fontSize: 13,
                    color: _UserManagementPageState._textSecondary)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_right,
                size: 14, color: _UserManagementPageState._textSecondary),
          ),
          const Text('Users',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _UserManagementPageState._textPrimary)),
          const Spacer(),
          // Refresh
          _TopBarButton(
            icon: Icons.refresh_rounded,
            onTap: () =>
                context.read<AuthController>().fetchAllUsers(),
          ),
          const SizedBox(width: 10),
          // Add user
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditUserPage()),
              ).then((_) =>
                  context.read<AuthController>().fetchAllUsers());
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add User',
                style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: _UserManagementPageState._emerald,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _UserManagementPageState._canvas,
          border: Border.all(color: _UserManagementPageState._border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16, color: _UserManagementPageState._textSecondary),
      ),
    );
  }
}

// ── User table ─────────────────────────────────────────────────────────────────

class _UserTable extends StatelessWidget {
  final List<User> users;
  final AuthController auth;
  const _UserTable({required this.users, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with count
          Row(
            children: [
              const _SectionLabel('Team Members'),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _UserManagementPageState._emeraldLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${users.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _UserManagementPageState._emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _UserManagementPageState._surface,
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: _UserManagementPageState._border),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 11),
                    decoration: const BoxDecoration(
                      color: _UserManagementPageState._canvas,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(11),
                        topRight: Radius.circular(11),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: _ColHeader('User')),
                        Expanded(
                            flex: 2,
                            child: _ColHeader('Role')),
                        Expanded(
                            flex: 2,
                            child: _ColHeader('Joined')),
                        Expanded(
                            flex: 1,
                            child: _ColHeader('Status')),
                        SizedBox(width: 80),
                      ],
                    ),
                  ),
                  const Divider(
                      height: 1,
                      color: _UserManagementPageState._border),
                  Expanded(
                    child: ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: _UserManagementPageState._border),
                      itemBuilder: (context, i) {
                        final user = users[i];
                        final isCurrentUser =
                            user.id == auth.currentUser?.id;
                        return _UserRow(
                          user: user,
                          isCurrentUser: isCurrentUser,
                          auth: auth,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: _UserManagementPageState._textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final User user;
  final bool isCurrentUser;
  final AuthController auth;
  const _UserRow(
      {required this.user,
        required this.isCurrentUser,
        required this.auth});

  @override
  Widget build(BuildContext context) {
    final role = _roleData(user.role);
    final joinDate = user.createdAt.toString().split(' ')[0];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // User column
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: role.color.withOpacity(0.12),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: role.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _UserManagementPageState._textPrimary,
                              )),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _UserManagementPageState._skyLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('You',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _UserManagementPageState._sky,
                                  )),
                            ),
                          ],
                        ],
                      ),
                      Text(user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _UserManagementPageState._textSecondary,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Role column
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: role.bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                role.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: role.color,
                ),
              ),
            ),
          ),

          // Joined column
          Expanded(
            flex: 2,
            child: Text(joinDate,
                style: const TextStyle(
                  fontSize: 13,
                  color: _UserManagementPageState._textSecondary,
                )),
          ),

          // Status column
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? _UserManagementPageState._emerald
                        : _UserManagementPageState._rose,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: user.isActive
                        ? _UserManagementPageState._emerald
                        : _UserManagementPageState._rose,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          SizedBox(
            width: 116,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RowIconButton(
                  icon: Icons.lock_reset_rounded,
                  color: _UserManagementPageState._violet,
                  tooltip: 'Change Password',
                  onTap: () => _showPasswordDialog(context, auth, user),
                ),
                if (!isCurrentUser && user.role != 'super_admin') ...[
                  const SizedBox(width: 4),
                  _RowIconButton(
                    icon: Icons.edit_outlined,
                    color: _UserManagementPageState._sky,
                    tooltip: 'Edit',
                    onTap: () => _showEditDialog(context, auth, user),
                  ),
                  const SizedBox(width: 4),
                  _RowIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: _UserManagementPageState._rose,
                    tooltip: 'Delete',
                    onTap: () => _confirmDelete(context, auth, user),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, AuthController auth, User user) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;
    String? error;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _UserManagementPageState._violetLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          size: 18, color: _UserManagementPageState._violet),
                    ),
                    const SizedBox(width: 12),
                    Text('Change Password',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _UserManagementPageState._textPrimary,
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          size: 18, color: _UserManagementPageState._textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('For ${user.name} (${user.email})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _UserManagementPageState._textSecondary,
                    )),
                const SizedBox(height: 20),

                _FieldLabel('New Password'),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: passCtrl,
                  hint: 'Minimum 6 characters',
                ),
                const SizedBox(height: 16),

                _FieldLabel('Confirm Password'),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: confirmCtrl,
                  hint: 'Re-enter password',
                ),

                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!,
                      style: const TextStyle(
                          fontSize: 12.5, color: _UserManagementPageState._rose)),
                ],

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _UserManagementPageState._textSecondary,
                          side: const BorderSide(color: _UserManagementPageState._border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (passCtrl.text.length < 6) {
                            setState(() => error = 'Password must be at least 6 characters');
                            return;
                          }
                          if (passCtrl.text != confirmCtrl.text) {
                            setState(() => error = 'Passwords do not match');
                            return;
                          }
                          final ok = await auth.changeUserPassword(
                            userId: user.id,
                            newPassword: passCtrl.text,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Password updated for ${user.name}'
                                  : (auth.errorMessage ?? 'Failed to update password')),
                              backgroundColor: ok
                                  ? _UserManagementPageState._emerald
                                  : _UserManagementPageState._rose,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _UserManagementPageState._violet,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Update Password'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _RoleData _roleData(String role) {
    switch (role) {
      case 'super_admin':
        return _RoleData(
            label: 'Super Admin',
            color: _UserManagementPageState._rose,
            bgColor: _UserManagementPageState._roseLight);
      case 'admin':
        return _RoleData(
            label: 'Admin',
            color: _UserManagementPageState._amber,
            bgColor: _UserManagementPageState._amberLight);
      default:
        return _RoleData(
            label: 'User',
            color: _UserManagementPageState._sky,
            bgColor: _UserManagementPageState._skyLight);
    }
  }

  void _showEditDialog(
      BuildContext context, AuthController auth, User user)
  {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    String selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _UserManagementPageState._skyLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          size: 18,
                          color: _UserManagementPageState._sky),
                    ),
                    const SizedBox(width: 12),
                    const Text('Edit User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _UserManagementPageState._textPrimary,
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          size: 18,
                          color: _UserManagementPageState._textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _FieldLabel('Name'),
                const SizedBox(height: 6),
                _StyledTextField(controller: nameCtrl, hint: 'Full name'),
                const SizedBox(height: 16),

                _FieldLabel('Email'),
                const SizedBox(height: 6),
                _StyledTextField(
                    controller: emailCtrl,
                    hint: 'email@example.com',
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),

                _FieldLabel('Role'),
                const SizedBox(height: 6),
                _StyledDropdown(
                  value: selectedRole,
                  items: const ['user', 'admin'],
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
                const SizedBox(height: 16),

                // Active toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _UserManagementPageState._canvas,
                    border: Border.all(
                        color: _UserManagementPageState._border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('Account active',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: _UserManagementPageState._textPrimary,
                          )),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        onChanged: (v) => setState(() => isActive = v),
                        activeColor: _UserManagementPageState._emerald,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                          _UserManagementPageState._textSecondary,
                          side: const BorderSide(
                              color: _UserManagementPageState._border),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final ok = await auth.updateUser(
                            userId: user.id,
                            name: nameCtrl.text,
                            email: emailCtrl.text,
                            role: selectedRole,
                            isActive: isActive,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'User updated'
                                  : (auth.errorMessage ??
                                  'Update failed')),
                              backgroundColor: ok
                                  ? _UserManagementPageState._emerald
                                  : _UserManagementPageState._rose,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(8)),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor:
                          _UserManagementPageState._emerald,
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AuthController auth, User user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _UserManagementPageState._roseLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 22, color: _UserManagementPageState._rose),
              ),
              const SizedBox(height: 16),
              const Text('Delete user?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _UserManagementPageState._textPrimary,
                  )),
              const SizedBox(height: 8),
              Text(
                '${user.name} will be permanently removed. This cannot be undone.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _UserManagementPageState._textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                        _UserManagementPageState._textSecondary,
                        side: const BorderSide(
                            color: _UserManagementPageState._border),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final ok = await auth.deleteUser(user.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? '${user.name} deleted'
                                : (auth.errorMessage ??
                                'Delete failed')),
                            backgroundColor: ok
                                ? _UserManagementPageState._emerald
                                : _UserManagementPageState._rose,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _UserManagementPageState._rose,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _UserManagementPageState._canvas,
              border: Border.all(color: _UserManagementPageState._border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 28,
                color: _UserManagementPageState._textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No users found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _UserManagementPageState._textPrimary,
              )),
          const SizedBox(height: 6),
          const Text('Add your first team member to get started.',
              style: TextStyle(
                fontSize: 13,
                color: _UserManagementPageState._textSecondary,
              )),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label:
            const Text('Refresh', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _UserManagementPageState._emerald,
              side: const BorderSide(
                  color: _UserManagementPageState._emerald),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small shared widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _UserManagementPageState._textSecondary,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _UserManagementPageState._textSecondary,
        ));
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _StyledTextField(
      {required this.controller, required this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
          fontSize: 13.5, color: _UserManagementPageState._textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: _UserManagementPageState._textSecondary, fontSize: 13.5),
        filled: true,
        fillColor: _UserManagementPageState._canvas,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: _UserManagementPageState._border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: _UserManagementPageState._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: _UserManagementPageState._emerald, width: 1.5),
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown(
      {required this.value,
        required this.items,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      style: const TextStyle(
          fontSize: 13.5, color: _UserManagementPageState._textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: _UserManagementPageState._canvas,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: _UserManagementPageState._border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: _UserManagementPageState._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: _UserManagementPageState._emerald, width: 1.5),
        ),
      ),
      items: items.map((r) {
        return DropdownMenuItem(
            value: r,
            child: Text(r[0].toUpperCase() + r.substring(1)));
      }).toList(),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _RowIconButton(
      {required this.icon,
        required this.color,
        required this.tooltip,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

class _RoleData {
  final String label;
  final Color color;
  final Color bgColor;
  const _RoleData(
      {required this.label,
        required this.color,
        required this.bgColor});
}