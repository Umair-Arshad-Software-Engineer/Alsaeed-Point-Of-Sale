import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/sale_controller.dart';
import '../controllers/product_controller.dart';
import 'brand_management_page.dart';
import 'branch_management_page.dart';
import 'category_management_page.dart';
import 'products/product_list_page.dart';
import 'sales/sale_page.dart';
import 'reports/reports_page.dart';
import 'unit_management_page.dart';
import 'user_management_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const _navy         = Color(0xFF0F1729);
  static const _navyLight    = Color(0xFF1A2744);
  static const _emerald      = Color(0xFF10B981);
  static const _emeraldLight = Color(0xFFD1FAE5);
  static const _amber        = Color(0xFFF59E0B);
  static const _amberLight   = Color(0xFFFEF3C7);
  static const _violet       = Color(0xFF7C3AED);
  static const _violetLight  = Color(0xFFEDE9FE);
  static const _sky          = Color(0xFF0EA5E9);
  static const _skyLight     = Color(0xFFE0F2FE);
  static const _rose         = Color(0xFFE11D48);
  static const _canvas       = Color(0xFFF7F8FC);
  static const _surface      = Color(0xFFFFFFFF);
  static const _border       = Color(0xFFE2E8F0);
  static const _textPrimary  = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleController>().fetchSales();
      context.read<ProductController>().fetchProducts();
    });

    return Scaffold(
      backgroundColor: _canvas,
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(user: user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Overview'),
                        const SizedBox(height: 12),
                        const _StatsRow(),
                        const SizedBox(height: 32),
                        if (isWide) const _WideBody() else const _NarrowBody(),
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
}

// ── Sidebar ────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  static Route _route(Widget page) => MaterialPageRoute(builder: (_) => page);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final isSuperAdmin = user?.isSuperAdmin == true;

    return Container(
      width: 220,
      color: HomePage._navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: HomePage._emerald,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.point_of_sale, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('POSify',
                  style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w700, letterSpacing: -0.3,
                  )),
            ]),
          ),

          // Main nav
          const _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard', active: true),
          _NavItem(
            icon: Icons.shopping_cart_outlined, label: 'New Sale',
            onTap: () => Navigator.push(context, _route(const SalePage())),
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined, label: 'Products',
            onTap: () => Navigator.push(context, _route(const ProductListPage())),
          ),

          // Super Admin settings section
          if (isSuperAdmin) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('SETTINGS',
                  style: TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1.0,
                  )),
            ),
            _NavItem(
              icon: Icons.storefront_rounded, label: 'Branches',
              onTap: () => Navigator.push(context, _route(const BranchManagementPage())),
            ),
            _NavItem(
              icon: Icons.category_outlined, label: 'Categories',
              onTap: () => Navigator.push(context, _route(const CategoryManagementPage())),
            ),
            _NavItem(
              icon: Icons.branding_watermark_outlined, label: 'Brands',
              onTap: () => Navigator.push(context, _route(const BrandManagementPage())),
            ),
            _NavItem(
              icon: Icons.scale_outlined, label: 'Units',
              onTap: () => Navigator.push(context, _route(const UnitManagementPage())),
            ),
            _NavItem(
              icon: Icons.people_outline, label: 'Users',
              onTap: () => Navigator.push(context, _route(const UserManagementPage())),
            ),
          ],

          _NavItem(
            icon: Icons.bar_chart_rounded, label: 'Reports',
            onTap: () => Navigator.push(context, _route(const ReportsPage())),
          ),

          const Spacer(),

          // Logout
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
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? HomePage._navyLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: HomePage._navyLight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Icon(icon, size: 18,
                  color: active ? HomePage._emerald : const Color(0xFF94A3B8)),
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
                  width: 4, height: 4,
                  decoration: const BoxDecoration(
                      color: HomePage._emerald, shape: BoxShape.circle),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final dynamic user;
  const _TopBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months   = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr  = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: HomePage._surface,
        border: Border(bottom: BorderSide(color: HomePage._border)),
      ),
      child: Row(children: [
        Text(dateStr,
            style: const TextStyle(color: HomePage._textSecondary, fontSize: 13)),
        const Spacer(),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: HomePage._canvas,
            border: Border.all(color: HomePage._border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 18, color: HomePage._textSecondary),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: HomePage._canvas,
            border: Border.all(color: HomePage._border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: HomePage._navy,
              child: Text(
                user?.name[0].toUpperCase() ?? 'U',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'User',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: HomePage._textPrimary)),
                Text(user?.role?.toUpperCase() ?? 'USER',
                    style: const TextStyle(fontSize: 10, color: HomePage._textSecondary)),
              ],
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: HomePage._textSecondary, letterSpacing: 1.1,
        ));
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  DateTime _getStartOfWeek(DateTime date) {
    final daysToSubtract = (date.weekday - DateTime.monday).abs() % 7;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  @override
  Widget build(BuildContext context) {
    final saleCtrl    = context.watch<SaleController>();
    final productCtrl = context.watch<ProductController>();
    final sales       = saleCtrl.sales;
    final today       = DateTime.now();

    final todaySales = sales.where((s) =>
    s.saleDate.year == today.year &&
        s.saleDate.month == today.month &&
        s.saleDate.day == today.day).toList();

    final todayRevenue = todaySales.fold<double>(0, (sum, s) => sum + s.totalPrice);
    final totalRevenue = saleCtrl.getTotalRevenue();
    final totalItems   = saleCtrl.getTotalItemsSold();
    final productCount = productCtrl.products.length;

    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final yesterdayRevenue = sales
        .where((s) => s.saleDate.year == yesterday.year &&
        s.saleDate.month == yesterday.month &&
        s.saleDate.day == yesterday.day)
        .fold<double>(0, (sum, s) => sum + s.totalPrice);

    final revenueChange = yesterdayRevenue > 0
        ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue * 100).round()
        : (todayRevenue > 0 ? 100 : 0);

    final startOfThisWeek = _getStartOfWeek(today);
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    final thisWeekItems = sales
        .where((s) => s.saleDate.isAfter(startOfThisWeek.subtract(const Duration(days: 1))))
        .fold<int>(0, (sum, s) => sum + s.quantity);

    final lastWeekItems = sales
        .where((s) => s.saleDate.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) &&
        s.saleDate.isBefore(startOfThisWeek))
        .fold<int>(0, (sum, s) => sum + s.quantity);

    final itemsChange = lastWeekItems > 0
        ? ((thisWeekItems - lastWeekItems) / lastWeekItems * 100).round()
        : (thisWeekItems > 0 ? 100 : 0);

    final stats = [
      _StatData('Total Products', productCount.toString(),
          Icons.inventory_2_outlined, HomePage._sky, HomePage._skyLight, '+0 this week'),
      _StatData("Today's Sales", todaySales.length.toString(),
          Icons.receipt_long_outlined, HomePage._emerald, HomePage._emeraldLight,
          '${revenueChange >= 0 ? '+' : ''}$revenueChange% vs yesterday'),
      _StatData('Revenue', totalRevenue.toStringAsFixed(2),
          Icons.trending_up_rounded, HomePage._amber, HomePage._amberLight,
          '${todayRevenue.toStringAsFixed(2)} today'),
      _StatData('Items Sold', totalItems.toString(),
          Icons.shopping_bag_outlined, HomePage._violet, HomePage._violetLight,
          '${itemsChange >= 0 ? '+' : ''}$itemsChange% this week'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 16,
        mainAxisSpacing: 16, childAspectRatio: 1.7,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _StatCard(data: stats[i]),
    );
  }
}

class _StatData {
  final String label, value, hint;
  final IconData icon;
  final Color accent, accentLight;
  const _StatData(this.label, this.value, this.icon,
      this.accent, this.accentLight, this.hint);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomePage._surface,
        border: Border(left: BorderSide(color: data.accent, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12), bottomRight: Radius.circular(12),
          topLeft: Radius.circular(2),  bottomLeft: Radius.circular(2),
        ),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: HomePage._textSecondary)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: data.accentLight, borderRadius: BorderRadius.circular(7)),
                child: Icon(data.icon, size: 14, color: data.accent),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                      color: HomePage._textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(data.hint,
                  style: const TextStyle(fontSize: 11, color: HomePage._textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Wide / Narrow layouts ──────────────────────────────────────────────────────

class _WideBody extends StatelessWidget {
  const _WideBody();
  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _RecentSalesPanel()),
        SizedBox(width: 24),
        Expanded(flex: 2, child: _QuickActionsPanel()),
      ],
    );
  }
}

class _NarrowBody extends StatelessWidget {
  const _NarrowBody();
  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      _QuickActionsPanel(),
      SizedBox(height: 24),
      _RecentSalesPanel(),
    ]);
  }
}

// ── Quick actions ──────────────────────────────────────────────────────────────

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    final user         = context.watch<AuthController>().currentUser;
    final isSuperAdmin = user?.isSuperAdmin == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Quick Actions'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: HomePage._surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomePage._border),
          ),
          child: Column(children: [
            _ActionRow(
              icon: Icons.shopping_cart_outlined, label: 'New Sale',
              description: 'Start a transaction', color: HomePage._emerald,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalePage())),
              showDivider: true,
            ),
            _ActionRow(
              icon: Icons.inventory_2_outlined, label: 'Products',
              description: 'Manage inventory', color: HomePage._sky,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage())),
              showDivider: true,
            ),
            if (isSuperAdmin) ...[
              _ActionRow(
                icon: Icons.storefront_rounded, label: 'Branches',
                description: 'Manage store branches', color: HomePage._emerald,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BranchManagementPage())),
                showDivider: true,
              ),
              _ActionRow(
                icon: Icons.category_outlined, label: 'Categories',
                description: 'Manage product categories', color: HomePage._amber,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementPage())),
                showDivider: true,
              ),
              _ActionRow(
                icon: Icons.branding_watermark_outlined, label: 'Brands',
                description: 'Manage product brands', color: HomePage._violet,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandManagementPage())),
                showDivider: true,
              ),
              _ActionRow(
                icon: Icons.scale_outlined, label: 'Units',
                description: 'Manage product units', color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitManagementPage())),
                showDivider: true,
              ),
            ],
            _ActionRow(
              icon: Icons.bar_chart_rounded, label: 'Reports',
              description: 'View analytics', color: HomePage._amber,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage())),
              showDivider: isSuperAdmin,
            ),
            if (isSuperAdmin)
              _ActionRow(
                icon: Icons.people_outline_rounded, label: 'Users',
                description: 'Manage team access', color: HomePage._violet,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage())),
                showDivider: false,
              ),
          ]),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label, description;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _ActionRow({
    required this.icon, required this.label, required this.description,
    required this.color, required this.onTap, required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: HomePage._textPrimary)),
                Text(description, style: const TextStyle(
                    fontSize: 11.5, color: HomePage._textSecondary)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: HomePage._textSecondary),
          ]),
        ),
      ),
      if (showDivider)
        const Divider(height: 1, indent: 16, endIndent: 16, color: HomePage._border),
    ]);
  }
}

// ── Recent sales ───────────────────────────────────────────────────────────────

class _RecentSalesPanel extends StatelessWidget {
  const _RecentSalesPanel();

  @override
  Widget build(BuildContext context) {
    final sales       = context.watch<SaleController>().sales;
    final recentSales = sales.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Recent Sales'),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SalePage())),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View all',
                  style: TextStyle(fontSize: 12, color: HomePage._emerald, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: HomePage._surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomePage._border),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: HomePage._canvas,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(11), topRight: Radius.circular(11)),
              ),
              child: const Row(children: [
                Expanded(flex: 3, child: _TableHeader('Product')),
                Expanded(flex: 2, child: _TableHeader('Customer')),
                Expanded(flex: 2, child: _TableHeader('Amount')),
                Expanded(flex: 1, child: _TableHeader('Date')),
              ]),
            ),
            const Divider(height: 1, color: HomePage._border),
            if (recentSales.isNotEmpty)
              ...recentSales.map((sale) => _RecentSaleRow(sale: sale))
            else
              const _EmptyRecentSales(),
          ]),
        ),
      ],
    );
  }
}

class _RecentSaleRow extends StatelessWidget {
  final dynamic sale;
  const _RecentSaleRow({required this.sale});

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(flex: 3, child: Text(sale.productName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: HomePage._textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(
              sale.customerName.isNotEmpty ? sale.customerName : 'Guest',
              style: const TextStyle(fontSize: 12, color: HomePage._textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('\$${sale.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HomePage._emerald))),
          Expanded(flex: 1, child: Text(_formatDate(sale.saleDate),
              style: const TextStyle(fontSize: 11, color: HomePage._textSecondary))),
        ]),
      ),
      const Divider(height: 1, color: HomePage._border),
    ]);
  }
}

class _EmptyRecentSales extends StatelessWidget {
  const _EmptyRecentSales();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: HomePage._canvas,
            border: Border.all(color: HomePage._border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long_outlined, size: 24, color: HomePage._textSecondary),
        ),
        const SizedBox(height: 12),
        const Text('No sales yet',
            style: TextStyle(fontWeight: FontWeight.w600, color: HomePage._textPrimary, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Completed transactions will appear here.',
            style: TextStyle(fontSize: 12, color: HomePage._textSecondary)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalePage())),
          icon: const Icon(Icons.add, size: 14),
          label: const Text('New Sale', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: HomePage._emerald,
            side: const BorderSide(color: HomePage._emerald),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w700,
          color: HomePage._textSecondary, letterSpacing: 0.6,
        ));
  }
}