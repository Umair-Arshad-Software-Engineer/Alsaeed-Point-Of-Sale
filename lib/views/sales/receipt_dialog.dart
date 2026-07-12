import 'package:flutter/material.dart';
import '../../models/sale_model.dart';

class ReceiptDialog extends StatelessWidget {
  final Sale sale;
  final List<ReceiptItem> cart;
  final String customerName;
  final String customerPhone;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final double total;
  final double amountGiven;

  const ReceiptDialog({
    Key? key,
    required this.sale,
    required this.cart,
    required this.customerName,
    required this.customerPhone,
    required this.subtotal,
    required this.taxAmount,
    required this.discount,
    required this.total,
    required this.amountGiven,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Icon(Icons.receipt_long, size: 48, color: Color(0xFF10B981)),
            const SizedBox(height: 12),
            const Text(
              'Receipt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '#${sale.id}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Customer info
            if (customerName.isNotEmpty) ...[
              _infoRow('Customer', customerName),
              const SizedBox(height: 4),
            ],
            if (customerPhone.isNotEmpty) ...[
              _infoRow('Phone', customerPhone),
              const SizedBox(height: 4),
            ],
            _infoRow('Date', _formatDate(sale.saleDate)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Items
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            ...cart.map((item) => _buildItemRow(item)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Totals
            _summaryRow('Subtotal', subtotal),
            if (taxAmount > 0) _summaryRow('Tax', taxAmount, color: const Color(0xFFF59E0B)),
            if (discount > 0) _summaryRow('Discount', -discount, color: const Color(0xFFE11D48)),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _summaryRow('Total', total, isBold: true),
            if (amountGiven > 0) ...[
              _summaryRow('Amount Given', amountGiven),
              _summaryRow('Change', amountGiven - total, color: const Color(0xFF10B981)),
            ],
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // TODO: Implement print functionality
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print, size: 16),
                        SizedBox(width: 6),
                        Text('Print'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item.quantity}× ${item.productName}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
              // If you have tax data, you can add it here
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false, Color color = const Color(0xFF64748B)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
          Text(
            amount >= 0 ? 'PKR ${amount.toStringAsFixed(2)}' : '- PKR ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
