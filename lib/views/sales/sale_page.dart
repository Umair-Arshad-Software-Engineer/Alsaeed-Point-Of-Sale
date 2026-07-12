import 'package:alsaeed_pizza/views/sales/receipt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/sale_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/sale_model.dart';
import '../../services/print_service.dart';
import 'add_edit_sale_page.dart';

class SalePage extends StatefulWidget {
  const SalePage({Key? key}) : super(key: key);

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  static const _navy          = Color(0xFF0F1729);
  static const _navyLight     = Color(0xFF1A2744);
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

  final _searchController = TextEditingController();
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    // Add this to fetch sales when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleController>().fetchSales();
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  child: Consumer<SaleController>(
                    builder: (context, sc, _) {
                      if (sc.isLoading && sc.sales.isEmpty) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: _emerald));
                      }
                      if (sc.sales.isEmpty) {
                        return _EmptyState(
                            onRefresh: () => sc.fetchSales());
                      }

                      final filtered = sc.sales
                          .where((s) => s.productName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                          s.customerName
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();

                      return _buildContent(
                          context, sc, filtered, isSuperAdmin);
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

  // ── Sidebar ─────────────────────────────────────────────────────────────────

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
          _navItem(Icons.shopping_cart_outlined, 'New Sale',
              active: true),
          _navItem(Icons.inventory_2_outlined, 'Products'),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 11),
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
          const Text('Sales',
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
              style:
              const TextStyle(fontSize: 13, color: _textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search sales…',
                hintStyle:
                TextStyle(fontSize: 13, color: _textSecondary),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 16, color: _textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Print All button (available to all users)
          GestureDetector(
            onTap: () => _printAllSales(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _canvas,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.print_outlined,
                  size: 16, color: _textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          // Refresh
          GestureDetector(
            onTap: () => context.read<SaleController>().fetchSales(),
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
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEditSalePage()),
            ).then((_) =>
                context.read<SaleController>().fetchSales()),
            icon: const Icon(Icons.add, size: 16),
            label:
            const Text('New Sale', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: _emerald,
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

  // ── Content ──────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, SaleController sc,
      List<Sale> sales, bool isSuperAdmin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _statCard(
                label: 'Total Revenue',
                value:
                '₱${sc.getTotalRevenue().toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
                iconColor: _emerald,
                iconBg: _emeraldLight,
              ),
              const SizedBox(width: 14),
              _statCard(
                label: 'Items Sold',
                value: '${sc.getTotalItemsSold()}',
                icon: Icons.shopping_bag_outlined,
                iconColor: _sky,
                iconBg: _skyLight,
              ),
              const SizedBox(width: 14),
              _statCard(
                label: 'Total Transactions',
                value: '${sc.sales.length}',
                icon: Icons.receipt_long_outlined,
                iconColor: _amber,
                iconBg: _amberLight,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section label
          Row(
            children: [
              const Text('TRANSACTIONS',
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
                child: Text('${sales.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _emerald)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table
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
                    child: _buildHeaderRow(isSuperAdmin),

                  ),
                  // Rows
                  Expanded(
                    child: sales.isEmpty
                        ? const Center(
                        child: Text(
                            'No sales match your search.',
                            style: TextStyle(
                                fontSize: 13,
                                color: _textSecondary)))
                        : ListView.builder(
                      itemCount: sales.length,
                      itemBuilder: (ctx, i) =>
                          _buildSaleRow(context, sales[i],
                              isSuperAdmin, sc),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: _canvas,
                      border:
                      Border(top: BorderSide(color: _border)),
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11)),
                    ),
                    child: Text(
                      'Showing ${sales.length} transaction${sales.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 12, color: _textSecondary),
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

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: _textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Pass isSuperAdmin down and conditionally render
  Widget _buildHeaderRow(bool isSuperAdmin) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: _textSecondary,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 38),
          const Expanded(flex: 4, child: Text('PRODUCT', style: headerStyle)),
          const Expanded(flex: 2, child: Text('QTY × PRICE', style: headerStyle)),
          const Expanded(flex: 2, child: Text('TOTAL', style: headerStyle)),
          const Expanded(flex: 3, child: Text('CUSTOMER', style: headerStyle)),
          if (isSuperAdmin)
            const Expanded(flex: 3, child: Text('SOLD BY', style: headerStyle)),
          const Expanded(flex: 2, child: Text('DATE', style: headerStyle)),
          SizedBox(width: isSuperAdmin ? 104 : 36),
        ],
      ),
    );
  }


  Widget _buildSaleRow(BuildContext context, Sale sale,
      bool isSuperAdmin, SaleController sc) {
    final initials = sale.soldByName.isNotEmpty
        ? sale.soldByName
        .split(' ')
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join()
        : '?';

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
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
                      color: _amberLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.receipt_long_outlined,
                      size: 15, color: _amber),
                ),

                // Product name
                Expanded(
                  flex: 4,
                  child: Text(sale.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary)),
                ),

                // Qty × price
                Expanded(
                  flex: 2,
                  child: Text(
                    '${sale.quantity} × ₱${sale.productPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, color: _textSecondary),
                  ),
                ),

                // Total
                Expanded(
                  flex: 2,
                  child: Text(
                    '₱${sale.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _emerald),
                  ),
                ),

                // Customer
                Expanded(
                  flex: 3,
                  child: sale.customerName.isNotEmpty
                      ? Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(sale.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: _textPrimary)),
                      if (sale.customerPhone.isNotEmpty)
                        Text(sale.customerPhone,
                            style: const TextStyle(
                                fontSize: 11,
                                color: _textSecondary)),
                    ],
                  )
                      : const Text('—',
                      style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary)),
                ),

                // Sold by — only for admin/super_admin
                if (isSuperAdmin)
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
                          child: Text(sale.soldByName,
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
                    _formatDate(sale.saleDate),
                    style: const TextStyle(
                        fontSize: 12, color: _textSecondary),
                  ),
                ),

                // Actions - Print button for ALL users
                SizedBox(
                  width: isSuperAdmin ? 104 : 36, // Adjust width based on role
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Print button (available to all users)
                      _actionButton(
                        icon: Icons.print_outlined,
                        color: _sky,
                        onTap: () => _showPrintDialog(context, sale),
                      ),
                      // Edit and Delete buttons (only for super admin)
                      if (isSuperAdmin) ...[
                        const SizedBox(width: 4),
                        _actionButton(
                          icon: Icons.edit_outlined,
                          color: _sky,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AddEditSalePage(sale: sale)),
                          ).then((_) => sc.fetchSales()),
                        ),
                        const SizedBox(width: 4),
                        _actionButton(
                          icon: Icons.delete_outline_rounded,
                          color: _rose,
                          onTap: () => _confirmDelete(
                              context, sale, sc),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ════════════════════════════════════════════════════════════════════════════
  //  _showPrintDialog  — single receipt from the sales history row
  // ════════════════════════════════════════════════════════════════════════════
  void _showPrintDialog(BuildContext context, Sale sale) {
    final cashier =
        context.read<AuthController>().currentUser?.name ?? 'Admin';

    try {
      PrintService.printReceipt(
        sale: sale,
        cart: sale.items
            .map((item) => ReceiptItem(
          productName: item.productName,
          productPrice: item.unitPrice,
          quantity: item.quantity,
        ))
            .toList(),
        customerName: sale.customerName,
        customerPhone: sale.customerPhone,
        cashierName: cashier,
        invoiceNo: sale.id.toString(),
        fbrInvoiceNumber: '',   // add sale.fbrInvoiceNumber when field exists
        subtotal: sale.subtotal,
        taxAmount: 0.0,
        discount: sale.discount,
        total: sale.totalPrice,
        amountGiven: 0.0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt printed successfully'),
          backgroundColor: _emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to print receipt: $e'),
          backgroundColor: _rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  _printAllSales  — bulk print from top-bar button
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _printAllSales(BuildContext context) async {
    final sc      = context.read<SaleController>();
    final cashier =
        context.read<AuthController>().currentUser?.name ?? 'Admin';

    final filtered = sc.sales
        .where((s) =>
    s.productName
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()) ||
        s.customerName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sales to print'),
          backgroundColor: _amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Print All Sales?'),
        content: Text(
          'You are about to print ${filtered.length} sale receipt'
              '${filtered.length == 1 ? '' : 's'}. Continue?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _emerald),
            child: const Text('Print All'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing receipts for printing...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        for (int i = 0; i < filtered.length; i++) {
          final sale = filtered[i];

          await PrintService.printReceipt(
            sale: sale,
            cart: sale.items
                .map((item) => ReceiptItem(
              productName: item.productName,
              productPrice: item.unitPrice,
              quantity: item.quantity,
            ))
                .toList(),
            customerName: sale.customerName,
            customerPhone: sale.customerPhone,
            cashierName: cashier,
            invoiceNo: sale.id.toString(),
            fbrInvoiceNumber: '',   // add sale.fbrInvoiceNumber when field exists
            subtotal: sale.subtotal,
            taxAmount: 0.0,
            discount: sale.discount,
            total: sale.totalPrice,
            amountGiven: 0.0,
          );

          if (i < filtered.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        if (mounted) {
          Navigator.pop(context); // close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Printed ${filtered.length} receipt'
                      '${filtered.length == 1 ? '' : 's'}'),
              backgroundColor: _emerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to print receipts: $e'),
              backgroundColor: _rose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }



  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  })
  {
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
      BuildContext context, Sale sale, SaleController sc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(productName: sale.productName),
    );
    if (confirm == true) {
      final ok = await sc.deleteSale(sale.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Sale deleted'),
          backgroundColor: _emerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ));
      }
    }
  }
}

// ── Delete dialog ─────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final String productName;
  const _DeleteDialog({required this.productName});

  static const _rose        = Color(0xFFE11D48);
  static const _roseLight   = Color(0xFFFFE4E6);
  static const _border      = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
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
            const Text('Delete sale?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text(
              'The sale record for "$productName" will be permanently removed.',
              style: const TextStyle(
                  fontSize: 13.5,
                  color: _textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: const BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _rose,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  static const _emerald       = Color(0xFF10B981);
  static const _canvas        = Color(0xFFF7F8FC);
  static const _border        = Color(0xFFE2E8F0);
  static const _textPrimary   = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

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
            child: const Icon(Icons.receipt_long_outlined,
                size: 28, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No sales yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          const Text('Record your first sale to get started.',
              style: TextStyle(
                  fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('Refresh',
                style: TextStyle(fontSize: 13)),
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

// class _PrintCartItem {
//   final _PrintProduct product;
//   final int quantity;
//
//   _PrintCartItem({
//     required String productName,
//     required double productPrice,
//     required this.quantity,
//   }) : product = _PrintProduct(name: productName, price: productPrice);
// }

class _PrintProduct {
  final String name;
  final double price;
  const _PrintProduct({required this.name, required this.price});
}

// Helper class for print items
class _PrintCartItem {
  final String productName;
  final double productPrice;
  final int quantity;

  _PrintCartItem({
    required this.productName,
    required this.productPrice,
    required this.quantity,
  });
}