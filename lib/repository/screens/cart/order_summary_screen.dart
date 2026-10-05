import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:blinkit_series/domain/cart/cart_controller.dart';
import 'package:blinkit_series/repository/screens/cart/cartscreen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderSummaryScreen({
    super.key,
    required this.orderData,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  int _userRating = 0;
  bool _hasRated = false;
  String _ratingFeedback = "";

  Future<void> _generateAndSavePdfInvoice(
    BuildContext context, {
    required String orderNumber,
    required String createdAt,
    required String status,
    required String paymentMethod,
    required String address,
    required List itemsList,
    required double calculatedMrp,
    required double discount,
    required double subtotal,
    required double handlingFee,
    required double deliveryFee,
    required double grandTotal,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "SB MART QUICK",
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                        ),
                        pw.Text("Superfast Grocery & Essentials", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.Text("Date: $createdAt", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 12),

                // Order Meta Details Container
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Order ID: #$orderNumber", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.SizedBox(height: 4),
                          pw.Text("Payment Method: $paymentMethod", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Status: $status", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.green800)),
                          pw.SizedBox(height: 4),
                          pw.Text("Address: $address", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Items Table
                pw.Text("ORDERED ITEMS", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                  cellHeight: 24,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headers: ['#', 'Item Description', 'Unit', 'Qty', 'Price', 'Total'],
                  data: List<List<dynamic>>.generate(itemsList.length, (index) {
                    final item = itemsList[index];
                    final String name = item['product_name']?.toString() ?? item['name']?.toString() ?? 'Item';
                    final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                    final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                    final String unit = item['unit']?.toString() ?? '1 unit';
                    return [
                      (index + 1).toString(),
                      name,
                      unit,
                      qty.toString(),
                      "RS. ${price.toStringAsFixed(2)}",
                      "RS. ${(price * qty).toStringAsFixed(2)}"
                    ];
                  }),
                ),

                pw.SizedBox(height: 20),

                // Calculation Table / Bill Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 240,
                      child: pw.Column(
                        children: [
                          if (calculatedMrp > 0)
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.Text("Total MRP:", style: const pw.TextStyle(fontSize: 10)),
                              pw.Text("RS. ${calculatedMrp.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                            ]),
                          if (discount > 0)
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.Text("Product Discount:", style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
                              pw.Text("-RS. ${discount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700)),
                            ]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text("RS. ${subtotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                          ]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text("Handling Charge:", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text("+RS. ${handlingFee.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                          ]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text("Delivery Charges:", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(deliveryFee == 0 ? "FREE" : "RS. ${deliveryFee.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                          ]),
                          pw.Divider(thickness: 1),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text("RS. ${grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text("Thank you for shopping with SB Mart Quick! Support: support@sbmartquick.com", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF in Mobile Downloads/SB Mart folder: {order_id.pdf}
      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download/SB Mart');
        if (!targetDir.existsSync()) {
          try {
            targetDir.createSync(recursive: true);
          } catch (_) {
            targetDir = await getExternalStorageDirectory();
          }
        }
      } else {
        final docs = await getApplicationDocumentsDirectory();
        targetDir = Directory('${docs.path}/SB Mart');
        if (!targetDir.existsSync()) targetDir.createSync(recursive: true);
      }

      final String fileName = "${orderNumber}.pdf";
      final File pdfFile = File("${targetDir!.path}/$fileName");
      await pdfFile.writeAsBytes(await pdf.save());

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 8),
                Text("PDF Invoice Saved!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your official PDF invoice has been saved to your Downloads/SB Mart folder:",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0XFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: SelectableText(
                    pdfFile.path,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0XFF0C831F)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Close"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0XFF0C831F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Share.shareXFiles([XFile(pdfFile.path)], text: "Official PDF Invoice for Order #$orderNumber - SB Mart Quick");
                },
                icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                label: const Text("Share PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error generating PDF invoice: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating PDF invoice: $e")),
        );
      }
    }
  }

  void _showRatingModal(BuildContext context) {
    int selectedStars = _userRating > 0 ? _userRating : 5;
    final TextEditingController commentController = TextEditingController(text: _ratingFeedback);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Rate Your Order Experience",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "How satisfied were you with the items and delivery?",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // 5 Interactive Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        iconSize: 38,
                        icon: Icon(
                          starIndex <= selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0XFFF57F17),
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedStars = starIndex;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedStars == 5
                        ? "Excellent! 🌟🌟🌟🌟🌟"
                        : selectedStars == 4
                            ? "Very Good! 👍"
                            : selectedStars == 3
                                ? "Good 👌"
                                : selectedStars == 2
                                    ? "Fair 😐"
                                    : "Needs Improvement 👎",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0XFFF57F17)),
                  ),
                  const SizedBox(height: 16),

                  // Optional Comment Input
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Add optional feedback comments...",
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                      filled: true,
                      fillColor: const Color(0XFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFF0C831F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _userRating = selectedStars;
                          _hasRated = true;
                          _ratingFeedback = commentController.text.trim();
                        });
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("⭐ Thanks for your feedback! Your rating has been recorded."),
                            backgroundColor: Color(0XFF0C831F),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      child: const Text(
                        "Submit Feedback",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductThumbnail(Map<String, dynamic> item) {
    final String img = (item['product_image']?.toString() ??
            item['image']?.toString() ??
            item['img']?.toString() ??
            '')
        .trim();

    if (img.isEmpty) {
      return const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 28);
    }

    if (img.startsWith('http://') || img.startsWith('https://')) {
      return Image.network(
        img,
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 28),
      );
    }

    if (img.startsWith('uploads/')) {
      final String fullUrl = "https://admin.sbmartquick.com/$img";
      return Image.network(
        fullUrl,
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 28),
      );
    }

    final String cleanName = img.replaceAll('assets/images/', '').replaceAll('assets/', '');
    final String assetPath = 'assets/images/$cleanName';

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (c, o, s) {
        final String serverUrl = "https://admin.sbmartquick.com/uploads/products/$cleanName";
        return Image.network(
          serverUrl,
          fit: BoxFit.contain,
          errorBuilder: (c2, o2, s2) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 28),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> orderData = widget.orderData;
    final String orderNumber = orderData['order_number']?.toString() ?? 'ORD';
    final String status = orderData['status']?.toString() ?? 'Delivered';
    final String createdAt = orderData['created_at']?.toString() ?? 'Recently';
    final String address = orderData['delivery_address']?.toString() ?? 'Default Address';
    final String paymentMethod = orderData['payment_method']?.toString() ?? 'Cash on Delivery';
    final double grandTotal = double.tryParse(orderData['grand_total']?.toString() ?? '0') ?? 0.0;
    final double subtotal = double.tryParse(orderData['subtotal']?.toString() ?? '0') ?? grandTotal;
    final double deliveryFee = double.tryParse(orderData['delivery_fee']?.toString() ?? '0') ?? 0.0;
    final double handlingFee = double.tryParse(orderData['handling_fee']?.toString() ?? '2') ?? 2.0;

    final List itemsList = orderData['items'] as List? ?? [];
    final int itemTotalCount = itemsList.fold(0, (sum, it) => sum + (int.tryParse(it['quantity']?.toString() ?? '1') ?? 1));

    // Calculate MRP & Discount values
    final double calculatedMrp = itemsList.fold(0.0, (sum, it) {
      final double price = double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
      final double mrp = double.tryParse(it['mrp']?.toString() ?? '') ?? (price * 1.15);
      final int qty = int.tryParse(it['quantity']?.toString() ?? '1') ?? 1;
      return sum + (mrp * qty);
    });
    final double discount = (calculatedMrp - subtotal) > 0 ? (calculatedMrp - subtotal) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0XFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [], // Trash delete icon removed
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Order Summary Header Block
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order summary",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status == 'Delivered'
                              ? "Arrived at ${createdAt.contains(',') ? createdAt.split(',').last.trim() : createdAt}"
                              : "Order Status: $status",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _generateAndSavePdfInvoice(
                            context,
                            orderNumber: orderNumber,
                            createdAt: createdAt,
                            status: status,
                            paymentMethod: paymentMethod,
                            address: address,
                            itemsList: itemsList,
                            calculatedMrp: calculatedMrp,
                            discount: discount,
                            subtotal: subtotal,
                            handlingFee: handlingFee,
                            deliveryFee: deliveryFee,
                            grandTotal: grandTotal,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Download Invoice",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0XFF0C831F),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.download_rounded, size: 16, color: Color(0XFF0C831F)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 2. Items List Section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$itemTotalCount ${itemTotalCount == 1 ? 'item' : 'items'} in this order",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (itemsList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("No items detail available", style: TextStyle(color: Colors.black54)),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itemsList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final item = Map<String, dynamic>.from(itemsList[index]);
                              final String name = item['product_name']?.toString() ?? item['name']?.toString() ?? 'Item';
                              final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                              final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                              final String unit = item['unit']?.toString() ?? '1 unit';
                              final double mrp = double.tryParse(item['mrp']?.toString() ?? '') ?? (price * 1.15);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Product Thumbnail Container
                                  Container(
                                    width: 60,
                                    height: 60,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0XFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                                    ),
                                    child: _buildProductThumbnail(item),
                                  ),
                                  const SizedBox(width: 14),

                                  // Product Name & Quantity
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$unit x $qty",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Prices: Struck-through MRP and Final Price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (mrp > price)
                                        Text(
                                          "₹${(mrp * qty).toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black38,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        "₹${(price * qty).toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Rate Your Order Section Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _hasRated ? const Color(0XFFE8F5E9) : const Color(0XFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _hasRated ? Icons.stars_rounded : Icons.star_rounded,
                              color: _hasRated ? const Color(0XFF0C831F) : const Color(0XFFF57F17),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasRated ? "⭐ Thanks for your feedback!" : "How were your ordered items?",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _hasRated ? const Color(0XFF0C831F) : Colors.black87,
                                  ),
                                ),
                                if (_hasRated)
                                  Text(
                                    "You rated this order ${_userRating} star${_userRating > 1 ? 's' : ''}",
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showRatingModal(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasRated ? const Color(0XFFE8F5E9) : const Color(0XFF0C831F),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              _hasRated ? "Edit Rating" : "Rate now",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _hasRated ? const Color(0XFF0C831F) : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Bill Details Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bill details",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (calculatedMrp > 0) ...[
                            _buildBillRow("MRP", "₹${calculatedMrp.toStringAsFixed(0)}"),
                            const SizedBox(height: 8),
                          ],
                          if (discount > 0) ...[
                            _buildBillRow("Product discount", "-₹${discount.toStringAsFixed(0)}", valueColor: const Color(0XFF0C831F)),
                            const SizedBox(height: 8),
                          ],
                          _buildBillRow("Item total", "₹${subtotal.toStringAsFixed(0)}"),
                          const SizedBox(height: 8),
                          _buildBillRow("Handling charge", "+₹${handlingFee.toStringAsFixed(0)}"),
                          const SizedBox(height: 8),
                          _buildBillRow(
                            "Delivery charges",
                            deliveryFee == 0 ? "FREE" : "₹${deliveryFee.toStringAsFixed(0)}",
                            valueColor: deliveryFee == 0 ? const Color(0XFF0C831F) : Colors.black,
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Bill total",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "₹${grandTotal.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Order Details Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order details",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text("Order ID: #$orderNumber", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text("Payment Method: $paymentMethod", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text("Delivery Address: $address", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar for "Repeat Order"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    int addedCount = 0;
                    for (var item in itemsList) {
                      final String id = item['product_id']?.toString() ?? item['id']?.toString() ?? '1';
                      final String name = item['product_name']?.toString() ?? item['name']?.toString() ?? 'Item';
                      final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                      final String img = item['product_image']?.toString() ?? item['image']?.toString() ?? item['img']?.toString() ?? '';
                      final String unit = item['unit']?.toString() ?? '1 unit';
                      final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

                      for (int i = 0; i < qty; i++) {
                        CartController.instance.addItem(
                          id: id,
                          name: name,
                          img: img,
                          price: price,
                          unit: unit,
                        );
                        addedCount++;
                      }
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("🛒 Added $addedCount item(s) from Order #$orderNumber to cart!"),
                        backgroundColor: const Color(0XFF0C831F),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFF0C831F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Repeat Order",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "VIEW CART ON NEXT STEP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBillRow(String label, String value, {Color valueColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}
