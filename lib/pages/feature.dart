// ============================================================
// feature.dart  (วางที่ lib/pages/feature.dart)
// หน้ารายละเอียดรองเท้า: รูป, ราคา, เลือกไซส์, เพิ่มลงตะกร้า, ซื้อเลย
// ============================================================

import 'package:flutter/material.dart';
import 'orders.dart'; // ใช้ CartAndCheckoutPage (ตะกร้า)

class ProductDetailPage extends StatefulWidget {
  // ข้อมูลที่ main.dart ส่งมาตอนกดรองเท้า
  final int? productId; // id จากฐานข้อมูล (ยังไม่ได้ใช้ แต่เก็บไว้ได้)
  final String name; // ชื่อรองเท้า
  final String price; // ราคาแบบข้อความ เช่น '฿14900'
  final String? imageUrl; // ลิงก์รูปหลัก (อาจเป็น null)

  const ProductDetailPage({
    super.key,
    this.productId,
    required this.name, // ต้องส่งมาเสมอ
    required this.price, // ต้องส่งมาเสมอ
    this.imageUrl,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String selectedSize = '9'; // ไซส์ที่เลือกอยู่ตอนนี้

  // ไซส์ทั้งหมดที่มีให้เลือก
  final List<String> sizes = ['8', '8.5', '9', '9.5', '10'];

  // ไซส์ที่หมด (กดไม่ได้)
  final List<String> disabledSizes = ['8', '9.5'];

  // รูปตัวอย่างด้านล่าง (ยังเป็นรูปตายตัวจาก Unsplash)
  final List<Map<String, String>> gallery = [
    {
      'label': 'ด้านข้าง',
      'url':
      'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800',
    },
    {
      'label': 'ด้านหลัง',
      'url':
      'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800',
    },
    {
      'label': 'พื้นรองเท้า',
      'url':
      'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800',
    },
  ];

  // ชื่อรองเท้า ใช้ค่าที่ส่งมาจากหน้าแรก
  String get productName => widget.name;

  // ราคาเป็นตัวเลข: ตัดทุกอย่างที่ไม่ใช่ตัวเลข/จุดทิ้ง (เช่น ฿) แล้วปัดเป็นจำนวนเต็ม
  int get productPrice =>
      double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), ''))
          ?.round() ??
          0;

  // รูปหลัก: ใช้รูปจาก API ถ้ามี ไม่งั้นใช้รูปแรกของ gallery
  String get mainImage {
    final url = widget.imageUrl;
    return (url != null && url.isNotEmpty) ? url : gallery[0]['url']!;
  }

  // กดปุ่ม "เพิ่มลงตะกร้า"
  void _addToCart() {
    // เก็บสินค้าลงรายการตะกร้า (static list อยู่ใน orders.dart)
    CartAndCheckoutPage.addProduct({
      'name': productName,
      'price': productPrice,
      'image': mainImage,
      'size': selectedSize,
      'quantity': 1,
    });

    // แสดงแถบแจ้งเตือนด้านล่าง
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เพิ่มสินค้าลงตะกร้าแล้ว'),
        backgroundColor: Color(0xFFFF5500),
      ),
    );
  }

  // กดปุ่ม "ซื้อเลย": ใส่ตะกร้าแล้วเปิดหน้าตะกร้าทันที
  void _buyNow() {
    CartAndCheckoutPage.addProduct({
      'name': productName,
      'price': productPrice,
      'image': mainImage,
      'size': selectedSize,
      'quantity': 1,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartAndCheckoutPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'รองเท้าและเรื่องราว',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // ไอคอนตะกร้ามุมขวาบน
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartAndCheckoutPage(),
                ),
              );
            },
          ),
        ],
      ),
      // LayoutBuilder ใช้ดูความกว้างหน้าจอ เพื่อเลือกเลย์เอาต์
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800; // กว้างกว่า 800 = จอใหญ่

          // จอใหญ่: แบ่งซ้าย (รูป) / ขวา (รายละเอียด)
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildImageGallery(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildProductDetails(),
                  ),
                ),
              ],
            );
          }

          // จอมือถือ: เรียงรูปไว้บน รายละเอียดไว้ล่าง
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageGallery(),
                const SizedBox(height: 24),
                _buildProductDetails(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- ส่วนรูปภาพ ----------------
  Widget _buildImageGallery() {
    return Column(
      children: [
        // รูปใหญ่ (รูปจาก API)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            mainImage,
            height: 320,
            width: double.infinity,
            fit: BoxFit.contain,
            // โหลดรูปไม่ได้ = กล่องเทาพร้อมไอคอน
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 320,
                color: Colors.grey.shade900,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.white54,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // รูปเล็กเรียงเป็นแถว (จาก gallery)
        Row(
          children: List.generate(gallery.length, (index) {
            return Expanded(
              child: Padding(
                // เว้นช่องไฟขวา ยกเว้นรูปสุดท้าย
                padding: EdgeInsets.only(
                  right: index == gallery.length - 1 ? 0 : 8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    gallery[index]['url']!,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 90,
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.image, color: Colors.white54),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---------------- ส่วนรายละเอียดสินค้า ----------------
  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อเล็ก (ยังเป็นข้อความตายตัว)
        const Text(
          'JORDAN / REIMAGINED COLLECTION',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        // ชื่อรองเท้าจาก API
        Text(
          productName,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chicago • เปิดตัวปี 2022 • สภาพใหม่',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        // ราคา (ตัวใหญ่สีส้ม)
        Text(
          '฿${productPrice.toString()}',
          style: const TextStyle(
            fontSize: 28,
            color: Color(0xFFFF5500),
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(height: 32, color: Colors.white24),
        const Text(
          'เลือกไซส์ (US Men)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // ปุ่มเลือกไซส์เรียงเป็นแถว
        Row(
          children: sizes.map((size) {
            final isSelected = selectedSize == size; // ไซส์นี้ถูกเลือกไหม
            final isDisabled = disabledSizes.contains(size); // ไซส์นี้หมดไหม

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  // ไซส์ที่หมดกดไม่ได้ (onTap เป็น null)
                  onTap: isDisabled
                      ? null
                      : () {
                    setState(() {
                      selectedSize = size;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      // ที่เลือก = พื้นส้ม
                      color: isSelected
                          ? const Color(0xFFFF5500)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF5500)
                            : Colors.grey.shade700,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isDisabled ? '$size ×' : size, // หมด = ใส่ ×
                        style: TextStyle(
                          color: isDisabled ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'ไซส์ที่เลือก: US $selectedSize',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        const Text(
          'เรื่องราวของคู่นี้',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // ข้อความเรื่องราว (ยังเป็นข้อความตัวอย่างตายตัว)
        const Text(
          'Air Jordan 1 สี Chicago เป็นหนึ่งในสีรองเท้าที่นักสะสมจดจำ '
              'รุ่น Lost & Found ถ่ายทอดกลิ่นอายวินเทจด้วยรายละเอียดที่ได้รับแรงบันดาลใจจากรองเท้ายุคเก่า',
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
        const SizedBox(height: 24),
        // ปุ่มด้านล่าง: เพิ่มลงตะกร้า + ซื้อเลย
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('เพิ่มลงตะกร้า'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5500),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('ซื้อเลย'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}