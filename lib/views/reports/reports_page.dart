import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/auth_controller.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // ── Design tokens (mirrors SalePage) ────────────────────────────────────────
  static const _navy          = Color(0xFF0F1729);
  static const _navyLight     = Color(0xFF1A2744);
  static const _emerald       = Color(0xFF10B981);
  static const _emeraldLight  = Color(0xFFD1FAE5);
  static const _sky           = Color(0xFF0EA5E9);
  static const _skyLight      = Color(0xFFE0F2FE);
  static const _amber         = Color(0xFFF59E0B);
  static const _amberLight    = Color(0xFFFEF3C7);
  static const _violet        = Color(0xFF8B5CF6);
  static const _violetLight   = Color(0xFFEDE9FE);
  static const _canvas        = Color(0xFFF7F8FC);
  static const _surface       = Color(0xFFFFFFFF);
  static const _border        = Color(0xFFE2E8F0);
  static const _textPrimary   = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Future<void> _loadReport() async {
    await context.read<ReportController>().fetchReport(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _emerald),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadReport();
    }
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
                  child: Consumer<ReportController>(
                    builder: (context, rc, _) {
                      if (rc.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: _emerald),
                        );
                      }

                      final report = rc.reportData;

                      if (report.isEmpty) {
                        return _EmptyState(onRefresh: _loadReport);
                      }

                      return _buildContent(context, report);
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

  Widget _buildSidebar(BuildContext context) {
    final isSuperAdmin =
        context.watch<AuthController>().currentUser?.isSuperAdmin ?? false;

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
          _navItem(Icons.inventory_2_outlined, 'Products'),
          _navItem(Icons.bar_chart_rounded, 'Reports', active: true),
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
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
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
                    color: active ? _emerald : const Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 13.5,
                      fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
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
            onTap: () => Navigator.pop(context),
            child: const Text('Dashboard',
                style: TextStyle(fontSize: 13, color: _textSecondary)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_right, size: 14, color: _textSecondary),
          ),
          const Text('Reports',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const Spacer(),
          // Date range picker
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _canvas,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: _textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _startDate != null && _endDate != null
                        ? '${_fmt(_startDate!)} – ${_fmt(_endDate!)}'
                        : 'Select range',
                    style: const TextStyle(
                        fontSize: 13, color: _textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Refresh
          GestureDetector(
            onTap: _loadReport,
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
        ],
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, List<dynamic> report) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat cards ───────────────────────────────────────────────────────
          Row(
            children: [
              _statCard(
                label: 'Total Revenue',
                value: '₱${_totalRevenue(report).toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
                iconColor: _emerald,
                iconBg: _emeraldLight,
              ),
              const SizedBox(width: 14),
              _statCard(
                label: 'Total Transactions',
                value: '${_totalSales(report)}',
                icon: Icons.receipt_long_outlined,
                iconColor: _amber,
                iconBg: _amberLight,
              ),
              const SizedBox(width: 14),
              _statCard(
                label: 'Items Sold',
                value: '${_totalItems(report)}',
                icon: Icons.shopping_bag_outlined,
                iconColor: _sky,
                iconBg: _skyLight,
              ),
              const SizedBox(width: 14),
              _statCard(
                label: 'Avg. Sale Value',
                value: '₱${_avgSale(report).toStringAsFixed(2)}',
                icon: Icons.trending_up_rounded,
                iconColor: _violet,
                iconBg: _violetLight,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Section label ────────────────────────────────────────────────────
          Row(
            children: [
              const Text('DAILY BREAKDOWN',
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
                child: Text('${report.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _emerald)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Table ────────────────────────────────────────────────────────────
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
                  // Header
                  Container(
                    decoration: const BoxDecoration(
                      color: _canvas,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11)),
                      border:
                      Border(bottom: BorderSide(color: _border)),
                    ),
                    child: _buildHeaderRow(),
                  ),
                  // Rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: report.length,
                      itemBuilder: (ctx, i) =>
                          _buildReportRow(report[i] as Map<String, dynamic>),
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
                    child: Text(
                      'Showing ${report.length} day${report.length == 1 ? '' : 's'}',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
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

  Widget _buildHeaderRow() {
    const style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
        letterSpacing: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 38),
          Expanded(flex: 3, child: Text('DATE', style: style)),
          Expanded(flex: 2, child: Text('TRANSACTIONS', style: style)),
          Expanded(flex: 2, child: Text('ITEMS SOLD', style: style)),
          Expanded(flex: 3, child: Text('REVENUE', style: style)),
          Expanded(flex: 3, child: Text('AVG. SALE', style: style)),
        ],
      ),
    );
  }

  Widget _buildReportRow(Map<String, dynamic> day) {
    final dateStr = day['date']?.toString() ?? '';
    final dayNum  = _getDayFromDate(dateStr);
    final revenue = _parseDouble(day['total_revenue']);
    final avg     = _parseDouble(day['average_sale_value']);
    final sales   = day['total_sales']?.toString() ?? '0';
    final items   = day['total_items_sold']?.toString() ?? '0';

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
                // Day badge
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: _emeraldLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(dayNum,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _emerald)),
                  ),
                ),

                // Date
                Expanded(
                  flex: 3,
                  child: Text(dateStr,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary)),
                ),

                // Transactions
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _amberLight,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(sales,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _amber)),
                      ),
                    ],
                  ),
                ),

                // Items sold
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _skyLight,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(items,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _sky)),
                      ),
                    ],
                  ),
                ),

                // Revenue
                Expanded(
                  flex: 3,
                  child: Text(
                    '₱${revenue.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _emerald),
                  ),
                ),

                // Avg sale
                Expanded(
                  flex: 3,
                  child: Text(
                    '₱${avg.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, color: _textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _getDayFromDate(String date) {
    final parts = date.split('-');
    return parts.length >= 3 ? parts[2] : '';
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double _totalRevenue(List<dynamic> report) {
    return report.fold(0.0,
            (sum, d) => sum + _parseDouble((d as Map)['total_revenue']));
  }

  int _totalSales(List<dynamic> report) {
    return report.fold(0,
            (sum, d) => sum + int.tryParse((d as Map)['total_sales']?.toString() ?? '0')!);
  }

  int _totalItems(List<dynamic> report) {
    return report.fold(0,
            (sum, d) => sum + int.tryParse((d as Map)['total_items_sold']?.toString() ?? '0')!);
  }

  double _avgSale(List<dynamic> report) {
    final sales = _totalSales(report);
    return sales == 0 ? 0 : _totalRevenue(report) / sales;
  }

  String _fmt(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
            child: const Icon(Icons.assessment_outlined,
                size: 28, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No data for selected period',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          const Text('Try a different date range to see results.',
              style: TextStyle(fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('Refresh', style: TextStyle(fontSize: 13)),
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