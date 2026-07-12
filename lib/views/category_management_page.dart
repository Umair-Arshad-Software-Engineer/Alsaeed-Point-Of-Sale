// lib/views/settings/category_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/category_model.dart';
 const _navy = Color(0xFF0F1729);
 const _navyLight = Color(0xFF1A2744);
 const _emerald = Color(0xFF10B981);
 const _emeraldLight = Color(0xFFD1FAE5);
 const _rose = Color(0xFFE11D48);
 const _roseLight = Color(0xFFFFE4E6);
 const _canvas = Color(0xFFF7F8FC);
 const _surface = Color(0xFFFFFFFF);
 const _border = Color(0xFFE2E8F0);
 const _textPrimary = Color(0xFF0F172A);
 const _textSecondary = Color(0xFF64748B);
class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({Key? key}) : super(key: key);

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {


  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Category? _editingCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryController>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildForm(),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildCategoryList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    return Container(
      width: 220,
      color: _navy,
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
                    color: _emerald,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.point_of_sale, color: Colors.white, size: 18),
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
          _navItem(Icons.grid_view_rounded, 'Dashboard',
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
          _navItem(Icons.shopping_cart_outlined, 'New Sale'),
          _navItem(Icons.inventory_2_outlined, 'Products'),
          _navItem(Icons.category_outlined, 'Categories', active: true),
          _navItem(Icons.branding_watermark_outlined, 'Brands'),
          _navItem(Icons.scale_outlined, 'Units'),
          _navItem(Icons.bar_chart_rounded, 'Reports'),
          if (user?.isSuperAdmin == true)
            _navItem(Icons.people_outline_rounded, 'Users'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
            child: TextButton.icon(
              onPressed: () async {
                await context.read<AuthController>().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, size: 16, color: Color(0xFF94A3B8)),
              label: const Text('Sign out',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
      {bool active = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? _navyLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: _navyLight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 18,
                    color: active ? _emerald : const Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    )),
                if (active) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                        color: _emerald, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('Dashboard',
                style: TextStyle(fontSize: 13, color: _textSecondary)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_right, size: 14, color: _textSecondary),
          ),
          const Text('Settings',
              style: TextStyle(fontSize: 13, color: _textSecondary)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_right, size: 14, color: _textSecondary),
          ),
          const Text('Categories',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                )),
            SizedBox(height: 4),
            Text('Manage product categories',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                )),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _emeraldLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${context.watch<CategoryController>().categories.length} categories',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _emerald,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Category name',
                  prefixIcon: const Icon(Icons.category_outlined,
                      size: 18, color: _textSecondary),
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
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Name is required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  prefixIcon: const Icon(Icons.description_outlined,
                      size: 18, color: _textSecondary),
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
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _isLoading ? null : _saveCategory,
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : Row(
                children: [
                  Icon(_editingCategory == null
                      ? Icons.add
                      : Icons.save),
                  const SizedBox(width: 8),
                  Text(_editingCategory == null
                      ? 'Add Category'
                      : 'Update'),
                ],
              ),
            ),
            if (_editingCategory != null) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _cancelEdit,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Consumer<CategoryController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.categories.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined,
                      size: 48, color: _textSecondary),
                  SizedBox(height: 12),
                  Text('No categories yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary)),
                  SizedBox(height: 4),
                  Text('Add your first category above',
                      style: TextStyle(fontSize: 14, color: _textSecondary)),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _canvas,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 1, child: _TableHeader('ID')),
                    Expanded(flex: 3, child: _TableHeader('Name')),
                    Expanded(flex: 4, child: _TableHeader('Description')),
                    Expanded(flex: 1, child: _TableHeader('Actions')),
                  ],
                ),
              ),
              const Divider(height: 1, color: _border),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.categories.length,
                  itemBuilder: (_, i) {
                    final category = controller.categories[i];
                    return _CategoryRow(
                      category: category,
                      onEdit: () => _editCategory(category),
                      onDelete: () => _deleteCategory(category.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final controller = context.read<CategoryController>();

    final success = _editingCategory == null
        ? await controller.createCategory(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    )
        : await controller.updateCategory(
      id: _editingCategory!.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_editingCategory == null
            ? 'Category added successfully'
            : 'Category updated successfully'),
        backgroundColor: _emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(controller.errorMessage ?? 'Failed to save'),
        backgroundColor: _rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  void _editCategory(Category category) {
    setState(() {
      _editingCategory = category;
      _nameController.text = category.name;
      _descriptionController.text = category.description;
    });
  }

  void _cancelEdit() {
    _clearForm();
  }

  void _clearForm() {
    setState(() {
      _editingCategory = null;
      _nameController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _rose),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final controller = context.read<CategoryController>();
    final success = await controller.deleteCategory(id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Category deleted successfully'),
        backgroundColor: _emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(controller.errorMessage ?? 'Failed to delete'),
        backgroundColor: _rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  '#${category.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  category.description.isEmpty ? '-' : category.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: _textSecondary),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outlined,
                          size: 16, color: _rose),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _border),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: _textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}