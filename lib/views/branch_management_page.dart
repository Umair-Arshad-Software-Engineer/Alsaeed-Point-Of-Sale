import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/branch_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/branch_model.dart';
import '../models/user_model.dart';

class BranchManagementPage extends StatefulWidget {
  const BranchManagementPage({Key? key}) : super(key: key);

  @override
  State<BranchManagementPage> createState() => _BranchManagementPageState();
}

class _BranchManagementPageState extends State<BranchManagementPage> {
  // ── Brand tokens ─────────────────────────────────────────────────────────────
  static const _navy          = Color(0xFF0F1729);
  static const _emerald       = Color(0xFF10B981);
  static const _emeraldLight  = Color(0xFFD1FAE5);
  static const _rose          = Color(0xFFE11D48);
  static const _roseLight     = Color(0xFFFFE4E6);
  static const _sky           = Color(0xFF0EA5E9);
  static const _skyLight      = Color(0xFFE0F2FE);
  static const _amber         = Color(0xFFF59E0B);
  static const _amberLight    = Color(0xFFFEF3C7);
  static const _canvas        = Color(0xFFF7F8FC);
  static const _surface       = Color(0xFFFFFFFF);
  static const _border        = Color(0xFFE2E8F0);
  static const _textPrimary   = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchController>().fetchBranches();
      context.read<AuthController>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Branch Management'),
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showBranchDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Branch'),
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<BranchController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading && ctrl.branches.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: _emerald));
          }
          if (ctrl.branches.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildBranchList(context, ctrl.branches);
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _canvas,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront_rounded, size: 30, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No branches yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 6),
          const Text('Create your first branch to get started.',
              style: TextStyle(fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _showBranchDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Branch'),
            style: FilledButton.styleFrom(
              backgroundColor: _emerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Branch list ───────────────────────────────────────────────────────────────
  Widget _buildBranchList(BuildContext context, List<Branch> branches) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => Consumer<BranchController>(
        builder: (context, ctrl, _) => _BranchCard(
          branch: branches[i],
          assignedUsers: ctrl.getUsersForBranch(branches[i].id),
          onEdit: () => _showBranchDialog(context, branch: branches[i]),
          onDelete: () => _confirmDelete(context, branches[i]),
          onAssign: () => _showAssignUsersDialog(context, branches[i]),
        ),
      ),
    );
  }

  // ── Create / Edit dialog ──────────────────────────────────────────────────────
  void _showBranchDialog(BuildContext context, {Branch? branch}) {
    final isEditing   = branch != null;
    final nameCtrl    = TextEditingController(text: branch?.name ?? '');
    final addressCtrl = TextEditingController(text: branch?.address ?? '');
    final phoneCtrl   = TextEditingController(text: branch?.phone ?? '');
    bool isActive     = branch?.isActive ?? true;
    final formKey     = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(28),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _emeraldLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 18, color: _emerald),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Branch' : 'New Branch',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 18, color: _textSecondary),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _DialogField(
                    label: 'Branch Name', hint: 'e.g., Main Branch',
                    controller: nameCtrl,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    label: 'Address', hint: 'Street, City, State',
                    controller: addressCtrl, maxLines: 2,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    label: 'Phone', hint: '+92 300 1234567',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(v!)) return 'Invalid phone';
                      return null;
                    },
                  ),

                  if (isEditing) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _canvas,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Text('Branch active',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w500, color: _textPrimary)),
                        const Spacer(),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setState(() => isActive = v),
                          activeColor: _emerald,
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSecondary,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<BranchController>(
                        builder: (context, ctrl, _) => FilledButton(
                          onPressed: ctrl.isLoading ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            bool ok;
                            if (isEditing) {
                              ok = await ctrl.updateBranch(
                                branchId: branch!.id,
                                name: nameCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                isActive: isActive,
                              );
                            } else {
                              ok = await ctrl.createBranch(
                                name: nameCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                              );
                            }
                            if (ok) {
                              Navigator.pop(context);
                              _snack(context,
                                  isEditing ? 'Branch updated' : 'Branch created', _emerald);
                            } else {
                              _snack(context, ctrl.errorMessage ?? 'Failed', _rose);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _emerald,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: ctrl.isLoading
                              ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : Text(isEditing ? 'Update' : 'Create'),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Assign users dialog ───────────────────────────────────────────────────────
  void _showAssignUsersDialog(BuildContext context, Branch branch) async {
    final ctrl     = context.read<BranchController>();
    final authCtrl = context.read<AuthController>();

    // Fetch current assignments then open dialog
    await ctrl.fetchBranchUsers(branch.id);

    if (!mounted) return;

    final allUsers       = authCtrl.allUsers;
    final alreadyAssigned = ctrl.getUsersForBranch(branch.id);
    final Set<int> selectedIds = alreadyAssigned.map((u) => u.id).toSet();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 460,
            constraints: const BoxConstraints(maxHeight: 580),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: _skyLight, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.people_outline_rounded, size: 18, color: _sky),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Assign Users',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
                      Text(branch.name,
                          style: const TextStyle(fontSize: 12, color: _textSecondary)),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 18, color: _textSecondary),
                  ),
                ]),
                const SizedBox(height: 14),

                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _amberLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _amber.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, size: 14, color: _amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This replaces all current assignments for this branch.',
                        style: TextStyle(fontSize: 11.5, color: _amber),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // User list
                Flexible(
                  child: allUsers.isEmpty
                      ? const Center(
                      child: Text('No users available',
                          style: TextStyle(color: _textSecondary)))
                      : ListView.separated(
                    shrinkWrap: true,
                    itemCount: allUsers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                    itemBuilder: (context, i) {
                      final user    = allUsers[i];
                      final checked = selectedIds.contains(user.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) => setState(() {
                          if (v == true) selectedIds.add(user.id);
                          else selectedIds.remove(user.id);
                        }),
                        activeColor: _emerald,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(user.name,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary)),
                        subtitle: Text(user.email,
                            style: const TextStyle(fontSize: 12, color: _textSecondary)),
                        secondary: _RoleBadge(role: user.role),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Selected count
                Text('${selectedIds.length} user(s) selected',
                    style: const TextStyle(fontSize: 12, color: _textSecondary)),
                const SizedBox(height: 12),

                // Buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<BranchController>(
                      builder: (context, ctrl, _) => FilledButton(
                        onPressed: ctrl.isLoading ? null : () async {
                          final ok = await ctrl.assignUsersToBranch(
                            branchId: branch.id,
                            userIds: selectedIds.toList(),
                          );
                          if (ok) {
                            Navigator.pop(context);
                            _snack(context, 'Users assigned to ${branch.name}', _emerald);
                          } else {
                            _snack(context, ctrl.errorMessage ?? 'Failed', _rose);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _emerald,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: ctrl.isLoading
                            ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : const Text('Assign'),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, Branch branch) {
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
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _roseLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_outline_rounded, size: 22, color: _rose),
              ),
              const SizedBox(height: 16),
              const Text('Delete branch?',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 8),
              Text(
                '"${branch.name}" will be permanently removed. Make sure no users are assigned to it first.',
                style: const TextStyle(
                    fontSize: 13.5, color: _textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: const BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<BranchController>(
                    builder: (context, ctrl, _) => FilledButton(
                      onPressed: ctrl.isLoading ? null : () async {
                        final ok = await ctrl.deleteBranch(branch.id);
                        Navigator.pop(context);
                        _snack(
                          context,
                          ok ? '${branch.name} deleted' : (ctrl.errorMessage ?? 'Failed'),
                          ok ? _emerald : _rose,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _rose,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: ctrl.isLoading
                          ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Text('Delete'),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}

// ── Branch card ───────────────────────────────────────────────────────────────

class _BranchCard extends StatelessWidget {
  final Branch branch;
  final List<User> assignedUsers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssign;

  static const _emerald       = Color(0xFF10B981);
  static const _emeraldLight  = Color(0xFFD1FAE5);
  static const _rose          = Color(0xFFE11D48);
  static const _roseLight     = Color(0xFFFFE4E6);
  static const _sky           = Color(0xFF0EA5E9);
  static const _skyLight      = Color(0xFFE0F2FE);
  static const _surface       = Color(0xFFFFFFFF);
  static const _border        = Color(0xFFE2E8F0);
  static const _textPrimary   = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  const _BranchCard({
    required this.branch,
    required this.assignedUsers,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + name/status + action buttons ──────────────────
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: branch.isActive ? _emeraldLight : _roseLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.storefront_rounded,
                    size: 20, color: branch.isActive ? _emerald : _rose),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(branch.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: branch.isActive ? _emerald : _rose,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      branch.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w500,
                        color: branch.isActive ? _emerald : _rose,
                      ),
                    ),
                  ]),
                ]),
              ),

              Row(children: [
                _IconBtn(
                    icon: Icons.people_alt_outlined,
                    color: _sky, tooltip: 'Assign Users', onTap: onAssign),
                const SizedBox(width: 6),
                _IconBtn(
                    icon: Icons.edit_outlined,
                    color: _sky, tooltip: 'Edit', onTap: onEdit),
                const SizedBox(width: 6),
                _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: _rose, tooltip: 'Delete', onTap: onDelete),
              ]),
            ]),

            const SizedBox(height: 14),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 14),

            // ── Info rows ─────────────────────────────────────────────────────
            _InfoRow(icon: Icons.location_on_outlined, text: branch.address),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone_outlined, text: branch.phone),
            if (branch.creator != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                  icon: Icons.person_outline,
                  text: 'Created by ${branch.creator!.name}'),
            ],

            // ── Assigned users section ────────────────────────────────────────
            const SizedBox(height: 14),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.people_alt_outlined, size: 14, color: _textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: assignedUsers.isEmpty
                      ? const Text(
                    'No users assigned',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Count label
                      Text(
                        '${assignedUsers.length} user${assignedUsers.length == 1 ? '' : 's'} assigned',
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary),
                      ),
                      const SizedBox(height: 8),
                      // User chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: assignedUsers.map((user) => _UserChip(user: user)).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── User chip ──────────────────────────────────────────────────────────────────

class _UserChip extends StatelessWidget {
  final User user;

  static const _sky        = Color(0xFF0EA5E9);
  static const _skyLight   = Color(0xFFE0F2FE);
  static const _rose       = Color(0xFFE11D48);
  static const _roseLight  = Color(0xFFFFE4E6);
  static const _amber      = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFEF3C7);
  static const _border     = Color(0xFFE2E8F0);

  const _UserChip({required this.user});

  Color get _bgColor => user.role == 'super_admin'
      ? _roseLight
      : user.role == 'admin'
      ? _amberLight
      : _skyLight;

  Color get _fgColor => user.role == 'super_admin'
      ? _rose
      : user.role == 'admin'
      ? _amber
      : _sky;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _fgColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Initials avatar
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(color: _fgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            user.name,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: _fgColor),
          ),
        ],
      ),
    );
  }
}

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;

  static const _sky        = Color(0xFF0EA5E9);
  static const _skyLight   = Color(0xFFE0F2FE);
  static const _rose       = Color(0xFFE11D48);
  static const _roseLight  = Color(0xFFFFE4E6);
  static const _amber      = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFEF3C7);

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final bg = role == 'super_admin' ? _roseLight
        : role == 'admin' ? _amberLight : _skyLight;
    final fg = role == 'super_admin' ? _rose
        : role == 'admin' ? _amber : _sky;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(role,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: _textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(fontSize: 12.5, color: _textSecondary)),
      ),
    ]);
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  static const _canvas        = Color(0xFFF7F8FC);
  static const _border        = Color(0xFFE2E8F0);
  static const _emerald       = Color(0xFF10B981);
  static const _textPrimary   = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  const _DialogField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: _textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        maxLines: maxLines ?? 1,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 13.5, color: _textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textSecondary, fontSize: 13.5),
          filled: true,
          fillColor: _canvas,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _emerald, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE11D48)),
          ),
        ),
      ),
    ]);
  }
}