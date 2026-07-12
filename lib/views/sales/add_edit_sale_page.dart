// lib/views/sales/add_edit_sale_page.dart
import 'package:alsaeed_pizza/views/sales/receipt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/sale_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../services/print_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Cart item model
// ─────────────────────────────────────────────────────────────────────────────
class _CartItem {
  final Product product;
  int quantity;
  _CartItem({required this.product, this.quantity = 1});

  double get taxAmount => (product.saleRate * product.taxPercentage / 100) * quantity;
  double get subtotal => product.saleRate * quantity;
  double get totalWithTax => subtotal + taxAmount;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────────────────────
class AddEditSalePage extends StatefulWidget {
  final Sale? sale;
  const AddEditSalePage({Key? key, this.sale}) : super(key: key);

  @override
  State<AddEditSalePage> createState() => _AddEditSalePageState();
}

class _AddEditSalePageState extends State<AddEditSalePage> {
  // ── Modern Color Palette ──────────────────────────────────────────────────
  static const _primaryColor = Color(0xFF1A237E);
  static const _primaryLight = Color(0xFF3949AB);
  static const _accentColor = Color(0xFF00BFA5);
  static const _surfaceColor = Color(0xFFF5F7FA);
  static const _cardColor = Colors.white;
  static const _rowEven = Color(0xFFF8F9FA);
  static const _rowOdd = Color(0xFFE8ECF1);
  static const _rowSelected = Color(0xFF1A237E);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _textWhite = Colors.white;
  static const _borderColor = Color(0xFFE5E7EB);
  static const _successColor = Color(0xFF10B981);
  static const _dangerColor = Color(0xFFEF4444);
  static const _warningColor = Color(0xFFF59E0B);

  // ── State ───────────────────────────────────────────────────────────────────
  final List<_CartItem> _cart = [];
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _searchController = TextEditingController();
  final _amountGivenController = TextEditingController(text: '0');
  final _fbrInvoiceController = TextEditingController();
  final _invoiceNoController = TextEditingController();
  final _dateController = TextEditingController();

  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isCreditSale = false;
  String _searchQuery = '';
  int? _selectedRow;
  bool _isEditingQuantity = false;  // Track if we're editing quantity
  bool _isEditingPayment = false;   // Track if we're editing payment

  // Focus nodes for navigation
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _paymentFocusNode = FocusNode();
  final FocusNode _rawKeyboardFocusNode = FocusNode(); // ← NAYA ADD KARO

  final TextEditingController _barcodeInputController = TextEditingController();
  final TextEditingController _tempQuantityController = TextEditingController();

  // ── Computed ─────────────────────────────────────────────────────────────────
  double get _subtotal => _cart.fold(0, (s, i) => s + i.subtotal);
  double get _totalTax => _cart.fold(0, (s, i) => s + i.taxAmount);
  double get _subtotalWithTax => _subtotal + _totalTax;
  double get _discountValue {
    final raw = double.tryParse(_discountController.text) ?? 0;
    return raw.clamp(0, _subtotalWithTax);
  }
  double get _total => _subtotalWithTax - _discountValue;
  double get _amountGiven => double.tryParse(_amountGivenController.text) ?? 0;
  double get _balance => _total - _amountGiven;
  int get _totalQty => _cart.fold(0, (s, i) => s + i.quantity);
  bool get _isEditing => widget.sale != null;

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(DateTime.now());
    _searchController.addListener(
            () => setState(() => _searchQuery = _searchController.text.toLowerCase()));

    // Add listener for barcode input with Enter key handling
    _barcodeInputController.addListener(_onBarcodeInputChanged);

    // Set up quantity focus node listener
    _quantityFocusNode.addListener(() {
      if (_quantityFocusNode.hasFocus) {
        setState(() => _isEditingQuantity = true);
        _tempQuantityController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _tempQuantityController.text.length,
        );
      } else {
        _applyQuantityChange();
      }
    });

    // Set up payment focus node listener
    _paymentFocusNode.addListener(() {
      if (_paymentFocusNode.hasFocus) {
        _isEditingPayment = true;
        // Select all text when payment field gets focus
        _amountGivenController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _amountGivenController.text.length,
        );
      } else {
        _isEditingPayment = false;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProductController>().fetchProducts();
      if (_isEditing) _populateFromSale();
      if (mounted) setState(() => _isInitializing = false);

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            FocusScope.of(context).requestFocus(_barcodeFocusNode);
          }
        });
      }
    });
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _populateFromSale() {
    final sale = widget.sale!;
    _customerNameController.text = sale.customerName;
    _customerPhoneController.text = sale.customerPhone;
    _discountController.text = sale.discount > 0 ? sale.discount.toStringAsFixed(2) : '0';

    final products = context.read<ProductController>().products;
    _cart.clear();
    for (final item in sale.items) {
      final product = products.firstWhere(
            (p) => p.id == item.productId,
        orElse: () => Product(
          id: item.productId,
          name: item.productName,
          saleRate: item.unitPrice,
          purchaseRate: item.unitPrice,
          taxPercentage: 0,
          netRate: item.unitPrice,
          openingQty: 0,
          itemCode: '',
          barcodeAutoGenerated: true,
          description: '',
          createdByName: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _cart.add(_CartItem(product: product, quantity: item.quantity));
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _searchController.dispose();
    _amountGivenController.dispose();
    _fbrInvoiceController.dispose();
    _invoiceNoController.dispose();
    _dateController.dispose();
    _barcodeInputController.dispose();
    _barcodeFocusNode.dispose();
    _quantityFocusNode.dispose();
    _paymentFocusNode.dispose();
    _rawKeyboardFocusNode.dispose(); // ← NAYA ADD KARO
    _tempQuantityController.dispose();
    super.dispose();
  }

  // ── Barcode Input Handler ────────────────────────────────────────────────────
  void _onBarcodeInputChanged() {
    // Handle Enter key press on barcode field
    // The actual processing happens in onSubmitted callback
  }

  void _processBarcode(String input) {
    if (input.isEmpty) return;

    final productController = context.read<ProductController>();
    Product? product;

    // Try to find by barcode (exact match)
    try {
      product = productController.products.firstWhere(
            (p) => p.barcode == input,
      );
    } catch (e) {
      // Try by itemCode (exact match)
      try {
        product = productController.products.firstWhere(
              (p) => p.itemCode == input,
        );
      } catch (e) {
        // Try by ID (if input is numeric)
        try {
          final id = int.parse(input);
          product = productController.products.firstWhere(
                (p) => p.id == id,
          );
        } catch (e) {
          product = null;
        }
      }
    }

    // Clear the barcode input field
    _barcodeInputController.clear();

    if (product != null) {
      _addToCart(product);

      // After adding, set focus to barcode again (ready for next scan)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_barcodeFocusNode);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found: "$input"'),
          backgroundColor: _warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_barcodeFocusNode);
        }
      });
    }
  }

  // ── Cart helpers ─────────────────────────────────────────────────────────────
  void _addToCart(Product p) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.product.id == p.id);
      if (idx >= 0) {
        _cart[idx].quantity++;
        _selectedRow = idx;
      } else {
        _cart.add(_CartItem(product: p));
        _selectedRow = _cart.length - 1;
      }
    });
  }

  void _updateQty(int idx, int newQty) {
    setState(() {
      if (newQty <= 0) {
        _cart.removeAt(idx);
        _selectedRow = null;
      } else {
        _cart[idx].quantity = newQty;
      }
    });
  }

  void _deleteSelected() {
    if (_selectedRow != null && _selectedRow! < _cart.length) {
      setState(() {
        _cart.removeAt(_selectedRow!);
        _selectedRow = null;
      });
    }
  }

  // ── Keyboard Shortcut Handlers ──────────────────────────────────────────────

  void _handleKeyboardShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Use F2 or Insert key to edit quantity instead of numpadDecimal
      if ((event.logicalKey == LogicalKeyboardKey.f2 ||
          event.logicalKey == LogicalKeyboardKey.insert) &&
          _barcodeFocusNode.hasFocus && _cart.isNotEmpty) {
        setState(() => _selectedRow = _cart.length - 1);
        _editQuantityForSelectedRow();
      }

      // Enter key handling
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_paymentFocusNode.hasFocus) {
          _saveSale();
        } else if (_barcodeFocusNode.hasFocus) {
          final barcode = _barcodeInputController.text.trim();
          if (barcode.isNotEmpty) {
            _processBarcode(barcode);
          } else {
            // If barcode field is empty, move to payment field
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                FocusScope.of(context).requestFocus(_paymentFocusNode);
              }
            });
          }
        }
      }
    }
  }
  // void _handleKeyboardShortcuts(KeyEvent event) {
  //   if (event is KeyDownEvent) {
  //     // Use F2 or Insert key to edit quantity instead of numpadDecimal
  //     if ((event.logicalKey == LogicalKeyboardKey.f2 ||
  //         event.logicalKey == LogicalKeyboardKey.insert) &&
  //         _barcodeFocusNode.hasFocus && _cart.isNotEmpty) {
  //       setState(() => _selectedRow = _cart.length - 1);
  //       _editQuantityForSelectedRow();
  //     }
  //
  //     // Enter key handling
  //     if (event.logicalKey == LogicalKeyboardKey.enter) {
  //       if (_paymentFocusNode.hasFocus) {
  //         _saveSale();
  //       } else if (_barcodeFocusNode.hasFocus) {
  //         final barcode = _barcodeInputController.text.trim();
  //         if (barcode.isNotEmpty) {
  //           _processBarcode(barcode);
  //         }
  //       }
  //     }
  //   }
  // }

  void _editQuantityForSelectedRow() {
    if (_selectedRow == null || _selectedRow! >= _cart.length) return;

    final item = _cart[_selectedRow!];

    setState(() {
      _tempQuantityController.text = item.quantity.toString();
      _isEditingQuantity = true;
    });

    // TextField build hone ke baad focus dein
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_quantityFocusNode);
      }
    });
  }

  void _applyQuantityChange() {
    if (_selectedRow != null && _selectedRow! < _cart.length) {
      final newQty = int.tryParse(_tempQuantityController.text);
      if (newQty != null) {
        _updateQty(_selectedRow!, newQty);
      }
    }
    _isEditingQuantity = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_barcodeFocusNode);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: _surfaceColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading POS System...',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return KeyboardListener(
      focusNode: _rawKeyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyboardShortcuts,
      child: Scaffold(
        backgroundColor: _surfaceColor,
        body: Column(
          children: [
            _buildTitleBar(),
            _buildHeaderRow(),
            _buildColumnHeaders(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildInvoiceGrid()),
                  _buildRightSidebar(),
                ],
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  Title Bar - Modern with gradient
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildTitleBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.receipt_long, color: _textWhite, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Cash Sale Invoice',
            style: TextStyle(
              color: _textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isEditing ? 'Editing Sale' : 'New Sale',
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close, color: _textWhite, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  Header Row - Clean and organized
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHeaderRow() {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildHeaderField('FBR Invoice', _fbrInvoiceController, width: 140),
          const SizedBox(width: 12),
          _buildHeaderField('Invoice #', _invoiceNoController, width: 100),
          const SizedBox(width: 12),
          _buildHeaderField('Date', _dateController, width: 100, enabled: false),
          const SizedBox(width: 12),
          _buildCreditCheckbox(),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primaryColor.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 16, color: _primaryColor),
                const SizedBox(width: 6),
                Text(
                  _customerNameController.text.isEmpty ? 'Walk-in Customer' : _customerNameController.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderField(String label, TextEditingController controller,
      {double width = 120, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: _textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: width,
          height: 32,
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              fontSize: 13,
              color: _textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              filled: true,
              fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCheckbox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _isCreditSale,
          onChanged: (v) => setState(() => _isCreditSale = v ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          activeColor: _warningColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Text(
          'Credit Sale',
          style: TextStyle(
            fontSize: 12,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  Column Headers - Modern table header
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildColumnHeaders() {
    return Container(
      color: _primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          _colHeader('SR#', width: 45),
          _colHeader('', width: 30),
          _colHeader('Barcode', width: 150),
          _colHeader('Item Name', flex: 3),
          _colHeader('Qty', width: 70),
          _colHeader('Rate', width: 90),
          _colHeader('GST', width: 80),
          _colHeader('Amount', width: 100),
          const SizedBox(width: 200),
        ],
      ),
    );
  }

  Widget _colHeader(String label, {double? width, int flex = 0}) {
    Widget text = Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _textWhite,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
    if (width != null) {
      return SizedBox(width: width, child: Center(child: text));
    }
    return Expanded(flex: flex, child: Center(child: text));
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  Invoice Grid - Enhanced with animations and 30 rows
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildInvoiceGrid() {
    return Consumer<ProductController>(
      builder: (context, pc, _) {
        final filtered = _searchQuery.isNotEmpty
            ? pc.products
            .where((p) => p.name.toLowerCase().contains(_searchQuery) ||
            p.itemCode.toLowerCase().contains(_searchQuery))
            .toList()
            : <Product>[];

        final totalRows = (_cart.length + 1) > 30 ? _cart.length + 1 : 30;


        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
            border: Border.all(color: _borderColor),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
          ),
          child: Stack(
            children: [
              ListView.builder(
                itemCount: totalRows,
                padding: EdgeInsets.zero,
                itemBuilder: (_, i) {
                  if (i < _cart.length) {
                    return _buildCartRow(i);
                  } else {
                    return _buildEmptyRow(i);
                  }
                },
              ),
              if (filtered.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _primaryColor.withOpacity(0.2)),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          return InkWell(
                            onTap: () {
                              _addToCart(p);
                              _searchController.clear();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 16,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _textPrimary,
                                          ),
                                        ),
                                        Text(
                                          p.itemCode,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'PKR ${p.saleRate.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: _primaryColor,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyRow(int idx) {
    final isEven = idx % 2 == 0;
    final isFirstEmptyRow = idx == _cart.length;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isEven ? _rowEven : _rowOdd,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Center(
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '×',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: isFirstEmptyRow
                  ? Container(
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _barcodeFocusNode.hasFocus
                        ? _primaryColor
                        : _primaryColor.withOpacity(0.3),
                    width: _barcodeFocusNode.hasFocus ? 1.5 : 1,
                  ),
                ),
                child: // Replace the onSubmitted with this approach
                TextField(
                  controller: _barcodeInputController,
                  focusNode: _barcodeFocusNode,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Scan barcode...',
                    hintStyle: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  // Remove onSubmitted - let the global handler manage it
                  onTap: () {
                    FocusScope.of(context).requestFocus(_barcodeFocusNode);
                  },
                ),
              )
                  : Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Center(
              child: Container(
                width: 50,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductBrowser() {
    final productController = context.read<ProductController>();

    String search = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 600,
              height: 550,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select Product',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              FocusScope.of(context).requestFocus(_barcodeFocusNode);
                            }
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by Name or Code',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        search = value.toLowerCase().trim();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer<ProductController>(
                      builder: (context, pc, _) {
                        final products = pc.products.where((p) {
                          if (search.isEmpty) return true;
                          return p.name.toLowerCase().contains(search) ||
                              p.itemCode.toLowerCase().contains(search);
                        }).toList();

                        if (products.isEmpty) {
                          return const Center(
                            child: Text('No products found'),
                          );
                        }

                        return ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (_, index) {
                            final p = products[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Code: ${p.barcode}',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'PKR ${p.saleRate.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              onTap: () {
                                _addToCart(p);
                                Navigator.pop(context);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    FocusScope.of(context).requestFocus(_barcodeFocusNode);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartRow(int idx) {
    final item = _cart[idx];
    final isSelected = _selectedRow == idx;
    final isEven = idx % 2 == 0;
    // final isQuantityFocused = isSelected && _isEditingQuantity && _quantityFocusNode.hasFocus;
    final isQuantityFocused = isSelected && _isEditingQuantity;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 36,
      color: isSelected
          ? _rowSelected
          : (isEven ? _rowEven : _rowOdd),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Center(
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? _textWhite : _textSecondary,
                ),
              ),
            ),
          ),
          _rowDeleteBtn(idx, isSelected),
          GestureDetector(
            onTap: () => setState(() => _selectedRow = idx),
            child: SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.product.barcode ?? item.product.itemCode,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? _textWhite : _textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => setState(() => _selectedRow = idx),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.product.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? _textWhite : _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Center(
              child: isQuantityFocused
                  ? SizedBox(
                width: 50,
                height: 28,
                child: TextField(
                  controller: _tempQuantityController,
                  focusNode: _quantityFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textWhite,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    // Apply quantity and return to barcode
                    final newQty = int.tryParse(value);
                    if (newQty != null) {
                      _updateQty(idx, newQty);
                    }
                    _isEditingQuantity = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        FocusScope.of(context).requestFocus(_barcodeFocusNode);
                      }
                    });
                  },
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              )
                  : GestureDetector(
                onTap: () {
                  setState(() => _selectedRow = idx);
                  // On tap, immediately allow quantity editing
                  _editQuantityForSelectedRow();
                },
                child: Container(
                  width: 50,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.white24 : Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.quantity.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? _textWhite : _textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.product.saleRate.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? _textWhite : _textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.taxAmount.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? _textWhite : _textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.totalWithTax.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _textWhite : _primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDeleteBtn(int idx, bool isSelected) {
    return GestureDetector(
      onTap: () => _updateQty(idx, 0),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.white24 : Colors.grey[400]!,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            '×',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? _textWhite : _dangerColor,
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  Right Sidebar - Modern card design
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRightSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          left: BorderSide(color: _borderColor),
          top: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                _buildModernSearchField(),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showProductBrowser,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_view, size: 16, color: _textWhite),
                        const SizedBox(width: 8),
                        const Text(
                          'Browse All Products',
                          style: TextStyle(
                            color: _textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: _textWhite),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _customerNameController.text.isEmpty
                              ? 'Walk-in Customer'
                              : _customerNameController.text,
                          style: const TextStyle(
                            color: _textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showCustomerDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              color: _textWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _buildModernSidebarBtn('Hold', Icons.pause_circle_outline),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildModernSidebarBtn('Customer', Icons.person_add_alt_1),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 6,
              itemBuilder: (_, i) => _buildModernDelGetRow(i),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                _buildModernSidebarBtn('Expense Voucher', Icons.receipt_outlined),
                const SizedBox(height: 4),
                _buildModernSidebarBtn('New Advance', Icons.attach_money),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Checkbox(
                  value: false,
                  onChanged: (_) {},
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: _primaryColor,
                ),
                const Text(
                  'Print on A4',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CTRL+P',
                    style: TextStyle(
                      fontSize: 9,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildModernTotalsSection(),
        ],
      ),
    );
  }

  Widget _buildModernSearchField() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 12, color: _textWhite),
        decoration: InputDecoration(
          hintText: '🔍 Search products...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
            onTap: () => _searchController.clear(),
            child: Icon(Icons.close, size: 16, color: Colors.white.withOpacity(0.6)),
          )
              : null,
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            final productController = context.read<ProductController>();
            final matches = productController.products.where(
                    (p) => p.name.toLowerCase().contains(value.toLowerCase()) ||
                    p.itemCode.toLowerCase().contains(value.toLowerCase())
            ).toList();
            if (matches.length == 1) {
              _addToCart(matches.first);
              _searchController.clear();
              if (mounted) {
                FocusScope.of(context).requestFocus(_barcodeFocusNode);
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildModernSidebarBtn(String label, IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: _primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDelGetRow(int i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          _buildSmallBtn('Del', Icons.delete_outline),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '',
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildSmallBtn('Get', Icons.download_outlined),
        ],
      ),
    );
  }

  Widget _buildSmallBtn(String label, IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 32,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, size: 12, color: _textSecondary),
      ),
    );
  }

  Widget _buildModernTotalsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TOTALS',
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildModernTotalsRow('Qty', _totalQty.toString(), highlight: true),
          _buildModernTotalsRow('Amt', _subtotal.toStringAsFixed(2)),
          _buildModernTotalsRow('Tax', _totalTax.toStringAsFixed(2), highlight: true),
          _buildModernTotalsRow('Adv.', '0.00'),
          _buildModernTotalsRow('Disc.', _discountValue.toStringAsFixed(2),
              editable: true, controller: _discountController),
          _buildModernPaymentRow(),
          _buildModernTotalsRow('Card.', '0.00'),
          Divider(color: Colors.white.withOpacity(0.2), height: 8),
          _buildModernTotalsRow(
            'Balance',
            _balance.toStringAsFixed(2),
            bold: true,
            valueColor: _balance < 0 ? _dangerColor : _successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentRow() {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: _paymentFocusNode.hasFocus ? Colors.white.withOpacity(0.2) : null,
        borderRadius: BorderRadius.circular(4),
        border: _paymentFocusNode.hasFocus
            ? Border.all(color: Colors.white, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 45,
            child: Text(
              'Rec.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: _textWhite,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 22,
              child: TextField(
                controller: _amountGivenController,
                focusNode: _paymentFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: _textWhite,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) {
                  // When Enter is pressed on payment field, save and print
                  _saveSale();
                },
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: _textWhite, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTotalsRow(
      String label,
      String value, {
        bool highlight = false,
        bool editable = false,
        bool bold = false,
        TextEditingController? controller,
        Color? valueColor,
      }) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: highlight ? Colors.white.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: highlight ? _textWhite : _textWhite.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: editable && controller != null
                ? SizedBox(
              height: 22,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: _textWhite,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: _textWhite, width: 1),
                  ),
                ),
              ),
            )
                : Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: valueColor ?? _textWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  Bottom Action Bar - Modern with icons
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBottomActionBar() {
    final actions = [
      ('Print', Icons.print, _saveSale, true),
      ('New', Icons.add, _clearAll, true),
      ('Edit', Icons.edit, null, false),
      ('Delete', Icons.delete, _deleteSelected, true),
      ('Preview', Icons.visibility, null, false),
      ('Previous', Icons.chevron_left, null, false),
      ('Next', Icons.chevron_right, null, false),
      ('Exit', Icons.exit_to_app, () => Navigator.pop(context), true),
    ];

    return Container(
      height: 48,
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: actions.map((a) {
          final label = a.$1;
          final icon = a.$2;
          final fn = a.$3;
          final isActive = a.$4;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: fn != null
                    ? () {
                  if (_isLoading) return;
                  fn();
                }
                    : null,
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: fn != null
                        ? (label == 'Print' ? _accentColor : Colors.grey[100])
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: fn != null
                          ? (label == 'Print' ? _accentColor : Colors.grey[300]!)
                          : Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                  child: _isLoading && label == 'Print'
                      ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: fn != null
                            ? (label == 'Print' ? _textWhite : _textSecondary)
                            : Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: fn != null
                              ? (label == 'Print' ? _textWhite : _textPrimary)
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  Helpers
  // ════════════════════════════════════════════════════════════════════════════
  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Clear Cart?'),
        content: const Text('This will remove all items from the cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _cart.clear();
                _selectedRow = null;
                _customerNameController.clear();
                _customerPhoneController.clear();
                _discountController.text = '0';
                _amountGivenController.text = '0';
                _fbrInvoiceController.clear();
                _barcodeInputController.clear();
                _tempQuantityController.clear();
                _isEditingQuantity = false;
                _isEditingPayment = false;
              });
              Navigator.pop(context);
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusScope.of(context).requestFocus(_barcodeFocusNode);
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: _dangerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: _primaryColor, size: 24),
            const SizedBox(width: 8),
            const Text('Customer Details', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: Icon(Icons.person_outline, size: 20, color: _primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerPhoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined, size: 20, color: _primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
              if (mounted) {
                FocusScope.of(context).requestFocus(_barcodeFocusNode);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  Save / Print - Automatic print after save without dialog
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _saveSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add items to the cart'),
          backgroundColor: _warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final sc = context.read<SaleController>();
    final auth = context.read<AuthController>();

    final items = _cart
        .map((c) => {'product_id': c.product.id, 'quantity': c.quantity})
        .toList();

    bool ok;
    if (_isEditing) {
      ok = await sc.updateSale(
        id: widget.sale!.id,
        items: items,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        discount: _discountValue,
      );
    } else {
      ok = await sc.createSale(
        items: items,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        discount: _discountValue,
      );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      final sale = sc.sales.isNotEmpty ? sc.sales.first : null;
      if (sale != null && !_isEditing) {
        try {
          // Print automatically without showing dialog
          await PrintService.printReceipt(
            sale: sale,
            cart: _cart
                .map((c) => ReceiptItem(
              productName: c.product.name,
              productPrice: c.product.saleRate,
              quantity: c.quantity,
            ))
                .toList(),
            customerName: _customerNameController.text.trim(),
            customerPhone: _customerPhoneController.text.trim(),
            cashierName: auth.currentUser?.name ?? 'Admin',
            invoiceNo: sale.id.toString(),
            fbrInvoiceNumber: _fbrInvoiceController.text.trim(),
            subtotal: _subtotal,
            taxAmount: _totalTax,
            discount: _discountValue,
            total: _total,
            amountGiven: _amountGiven,
          );

          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Sale saved & receipt printed'),
                  ],
                ),
                backgroundColor: _successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 2),
              ),
            );

            // Clear the cart but keep the page open for new sale
            // This way user can continue with next sale
            _cart.clear();
            _selectedRow = null;
            _barcodeInputController.clear();
            _amountGivenController.text = '0';
            _discountController.text = '0';
            _customerNameController.clear();
            _customerPhoneController.clear();

            // Focus back on barcode for next sale
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                FocusScope.of(context).requestFocus(_barcodeFocusNode);
              }
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sale saved but print failed: $e'),
                backgroundColor: _warningColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      } else {
        // Editing existing sale - just show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sale updated successfully'),
              backgroundColor: _successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.pop(context);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save sale. Please try again.'),
          backgroundColor: _dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}