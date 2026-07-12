import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/product_model.dart';
import 'add_edit_product_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  static const _navy        = Color(0xFF0F1729);
  static const _navyLight   = Color(0xFF1A2744);
  static const _emerald     = Color(0xFF10B981);
  static const _emeraldLight= Color(0xFFD1FAE5);
  static const _rose        = Color(0xFFE11D48);
  static const _roseLight   = Color(0xFFFFE4E6);
  static const _sky         = Color(0xFF0EA5E9);
  static const _canvas      = Color(0xFFF7F8FC);
  static const _surface     = Color(0xFFFFFFFF);
  static const _border      = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  static const _palettes = [
    [Color(0xFF0EA5E9), Color(0xFFE0F2FE)],
    [Color(0xFF10B981), Color(0xFFECFDF5)],
    [Color(0xFF7C3AED), Color(0xFFEDE9FE)],
    [Color(0xFFF59E0B), Color(0xFFFEF3C7)],
    [Color(0xFFE11D48), Color(0xFFFFE4E6)],
  ];

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch products when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductController>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Color> _paletteFor(String name) {
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _palettes.length;
    return _palettes[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        context.watch<AuthController>().currentUser?.isSuperAdmin ?? false;

    return Scaffold(
      backgroundColor: _canvas,
      body: Row(
        children: [
          _buildSidebar(context, isSuperAdmin),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isSuperAdmin),
                Expanded(
                  child: Consumer<ProductController>(
                    builder: (context, pc, _) {
                      if (pc.isLoading && pc.products.isEmpty) {
                        return const Center(
                            child: CircularProgressIndicator(color: _emerald));
                      }

                      final filtered = pc.products
                          .where((p) => p.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                          .toList();

                      if (pc.products.isEmpty && !pc.isLoading) {
                        return _EmptyState(
                            onRefresh: () => pc.fetchProducts());
                      }

                      return _buildTableView(
                          context, filtered, isSuperAdmin, pc);
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

  // ── Sidebar ──────────────────────────────────────────────────────────────────

  Widget _buildSidebar(BuildContext context, bool isSuperAdmin) {
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
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.point_of_sale,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('POSify',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3)),
              ],
            ),
          ),
          _navItem(Icons.grid_view_rounded, 'Dashboard',
              onTap: () => Navigator.pop(context)),
          _navItem(Icons.shopping_cart_outlined, 'New Sale'),
          _navItem(Icons.inventory_2_outlined, 'Products', active: true),
          _navItem(Icons.bar_chart_rounded, 'Reports'),
          if (isSuperAdmin)
            _navItem(Icons.people_outline_rounded, 'Users'),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
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
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: active
                        ? _emerald
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
                          color: _emerald, shape: BoxShape.circle)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, bool isSuperAdmin) {
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
            onTap: () => Navigator.pop(context),
            child: const Text('Dashboard',
                style: TextStyle(fontSize: 13, color: _textSecondary)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_right,
                size: 14, color: _textSecondary),
          ),
          const Text('Products',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const Spacer(),
          // Search
          Container(
            width: 220,
            height: 36,
            decoration: BoxDecoration(
              color: _canvas,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13, color: _textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search products…',
                hintStyle:
                TextStyle(fontSize: 13, color: _textSecondary),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 16, color: _textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Refresh
          GestureDetector(
            onTap: () =>
                context.read<ProductController>().fetchProducts(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _canvas,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.refresh_rounded,
                  size: 16, color: _textSecondary),
            ),
          ),
          if (isSuperAdmin) ...[
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditProductPage()),
              ).then((_) =>
                  context.read<ProductController>().fetchProducts()),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Product',
                  style: TextStyle(fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Table view ───────────────────────────────────────────────────────────────

  Widget _buildTableView(BuildContext context, List<Product> products,
      bool isSuperAdmin, ProductController pc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text('INVENTORY',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                      letterSpacing: 1.1)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _emeraldLight,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${products.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _emerald)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  // Column headers
                  Container(
                    decoration: const BoxDecoration(
                      color: _canvas,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11)),
                      border: Border(
                          bottom: BorderSide(color: _border)),
                    ),
                    child: _buildHeaderRow(),
                  ),
                  // Rows
                  Expanded(
                    child: products.isEmpty
                        ? const Center(
                        child: Text('No products match your search.',
                            style: TextStyle(
                                fontSize: 13,
                                color: _textSecondary)))
                        : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (ctx, i) {
                        return _buildProductRow(
                            context,
                            products[i],
                            i,
                            isSuperAdmin,
                            pc);
                      },
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: _canvas,
                      border: Border(top: BorderSide(color: _border)),
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${products.length} product${products.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 12, color: _textSecondary),
                        ),
                      ],
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

  Widget _buildHeaderRow() {
    const style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
        letterSpacing: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 38), // icon
          const Expanded(flex: 4, child: Text('PRODUCT', style: style)),
          const Expanded(flex: 2, child: Text('PRICE', style: style)),
          const Expanded(flex: 3, child: Text('ADDED BY', style: style)),
          const Expanded(flex: 2, child: Text('DATE', style: style)),
          const SizedBox(width: 72), // actions
        ],
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, Product product, int index,
      bool isSuperAdmin, ProductController pc) {
    final palette = _paletteFor(product.name);
    final accent = palette[0];
    final accentBg = palette[1];

    // Initials from createdByName
    final nameParts = product.createdByName.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : product.createdByName.substring(0, 1).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: _border)),
        color: _surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: _canvas,
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.inventory_2_outlined,
                      size: 15, color: accent),
                ),

                // Name + description
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary)),
                      if (product.description.isNotEmpty)
                        Text(product.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: _textSecondary)),
                    ],
                  ),
                ),

                // Price
                Expanded(
                  flex: 2,
                  child: Text(
                    '₱${product.netRate.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _emerald),
                  ),
                ),

                // Creator
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D4ED8))),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(product.createdByName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: _textSecondary)),
                      ),
                    ],
                  ),
                ),

                // Date
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatDate(product.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: _textSecondary),
                  ),
                ),

                // Actions (super admin only)
                SizedBox(
                  width: 72,
                  child: isSuperAdmin
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _actionButton(
                        icon: Icons.edit_outlined,
                        color: _sky,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddEditProductPage(
                                  product: product)),
                        ).then((_) => pc.fetchProducts()),
                      ),
                      const SizedBox(width: 4),
                      _actionButton(
                        icon: Icons.delete_outline_rounded,
                        color: _rose,
                        onTap: () =>
                            _confirmDelete(context, product, pc),
                      ),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(6),
          color: _surface,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Future<void> _confirmDelete(
      BuildContext context, Product product, ProductController pc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(name: product.name),
    );
    if (confirm == true) {
      final ok = await pc.deleteProduct(product.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.name} deleted'),
          backgroundColor: _emerald,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    }
  }
}

// ── Delete dialog ──────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final String name;
  const _DeleteDialog({required this.name});

  static const _rose      = Color(0xFFE11D48);
  static const _roseLight = Color(0xFFFFE4E6);
  static const _border    = Color(0xFFE2E8F0);
  static const _textPrimary   = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _roseLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 22, color: _rose),
            ),
            const SizedBox(height: 16),
            const Text('Delete product?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text('$name will be permanently removed from your inventory.',
                style: const TextStyle(
                    fontSize: 13.5,
                    color: _textSecondary,
                    height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: const BorderSide(color: _border),
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
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _rose,
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
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  static const _emerald      = Color(0xFF10B981);
  static const _canvas       = Color(0xFFF7F8FC);
  static const _border       = Color(0xFFE2E8F0);
  static const _textPrimary  = Color(0xFF0F172A);
  static const _textSecondary= Color(0xFF64748B);

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
                color: _canvas,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.inventory_2_outlined,
                size: 28, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No products yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          const Text('Add your first product to start selling.',
              style: TextStyle(fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label:
            const Text('Refresh', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _emerald,
              side: const BorderSide(color: _emerald),
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