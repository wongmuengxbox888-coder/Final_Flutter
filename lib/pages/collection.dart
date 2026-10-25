import 'package:flutter/material.dart';
import '../main.dart';
import 'orders.dart';
///สำหรับ api
class ShoeModel {
  final String id;
  final String name;
  final String details;
  final String imageUrl;

  ShoeModel({
    required this.id,
    required this.name,
    required this.details,
    required this.imageUrl,
  });

  // ฟังก์ชันแปลงข้อมูลจาก API
  factory ShoeModel.fromJson(Map<String, dynamic> json) {
    return ShoeModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      details: json['details'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class ShoeRackAndOrdersPage extends StatefulWidget {
  const ShoeRackAndOrdersPage({super.key});

  // รายการลองเท้าใน คอลเล้กชั่น
  static final List<ShoeModel> shoeList = [];

  // จะมีข้อมูลตอนกดยืนยัน
  static final List<Map<String, dynamic>> orders = [];

  // ตัวนับเลขคำสั่งซื้อ
  static int _orderCounter = 0;

  // ใส่ comma คั่นหลักพัน เช่น 13000 -> 13,000
  static String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');


  static void addConfirmedOrder({
    required List<Map<String, dynamic>> items,
    required int total,
    int? orderNumber, // เลข order_id จากฐานข้อมูล ใส่ไว้ก่อน ไม่มีนะอันนี้
  }) {
    if (items.isEmpty) return;

    final now = DateTime.now();
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final dateText = '${now.day} ${months[now.month - 1]} ${now.year}';

    // สร้างเลขคำสั่งซื้อ เช่น #RP-261025-025
    final number = orderNumber ?? ++_orderCounter;
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final orderId = '#RP-$yy$mm$dd-${number.toString().padLeft(3, '0')}';

    // 1) เพิ่มรองเท้าเข้าคอลเลกชัน 1 การ์ดต่อ 1 คู่ ไว้บนสุด
    var pairs = 0;
    for (final item in items) {
      final qty = (item['quantity'] as int?) ?? 1;
      for (var i = 0; i < qty; i++) {
        pairs++;
        shoeList.insert(
          0,
          ShoeModel(
            id: '${now.millisecondsSinceEpoch}-$pairs',
            name: item['name'].toString(),
            details: '${item['size']} • สั่งซื้อ $dateText',
            imageUrl: item['image']?.toString() ?? '',
          ),
        );
      }
    }

    // เพิ่มคำสั่งซื้อเข้ารายการคำสั่งซื้อ (สถานะ Pending) ไว้บนสุด
    final first = items.first;
    final name = items.length == 1
        ? first['name'].toString()
        : '${first['name']} และอีก ${items.length - 1} รายการ';
    final sizeQty = items.length == 1
        ? '${first['size']} • ${first['quantity']} คู่'
        : '$pairs คู่';

    orders.insert(0, {
      'id': orderId,
      'date': 'สั่งซื้อ $dateText',
      'status': 'Pending',
      'statusText': 'รอชำระเงินภายใน 30 นาที',
      'name': name,
      'sizeQty': sizeQty,
      'price': '฿${_fmt(total)}',
      'image': first['image']?.toString() ?? '',
      'step': 1,
    });
  }

  @override
  State<ShoeRackAndOrdersPage> createState() => _ShoeRackAndOrdersPageState();
}

class _ShoeRackAndOrdersPageState extends State<ShoeRackAndOrdersPage> {
  // ใช้ข้อมูลจาก static list (โค้ดเดิมด้านล่างเรียกชื่อเดิมได้เหมือนเดิม)
  List<ShoeModel> get shoeListFromApi => ShoeRackAndOrdersPage.shoeList;
  List<Map<String, dynamic>> get ordersList => ShoeRackAndOrdersPage.orders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.maybePop(context); // เพิ่ม: กดย้อนกลับได้
          },
        ),
        title: const Text(
          'ชั้นรองเท้าของฉัน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 900;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 24),
                        _buildCollectionHeader(),
                        const SizedBox(height: 16),
                        _buildShoeGrid(crossAxisCount: 3),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrdersHeader(),
                        const SizedBox(height: 16),
                        _buildOrdersList(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildCollectionHeader(),
                const SizedBox(height: 16),
                _buildShoeGrid(crossAxisCount: 2),
                const SizedBox(height: 32),
                _buildOrdersHeader(),
                const SizedBox(height: 16),
                _buildOrdersList(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFFFF5500),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        // เพิ่ม: กดเมนูล่างเพื่อไปหน้าแรก / ตะกร้า
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CartAndCheckoutPage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'ตะกร้า'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'คอลเลกชัน'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  // 1. การ์ดแสดงจำนวนสะสม
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(
            '${shoeListFromApi.length}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MY VIRTUAL SHOE RACK',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'สะสมแล้ว ${shoeListFromApi.length} คู่',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const Text(
                'รับสินค้าแล้วเท่านั้น',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //  หัวข้อคอลเลกชัน
  Widget _buildCollectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'คอลเลกชันที่ครอบครอง',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'ล่าสุดก่อน ↓',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Grid แสดงรองเท้า
  Widget _buildShoeGrid({required int crossAxisCount}) {
    // ยังไม่มีรองเท้า = โชว์ข้อความว่าง
    if (shoeListFromApi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'ยังไม่มีรองเท้าในคอลเลกชัน',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shoeListFromApi.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final shoe = shoeListFromApi[index];

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- กรอบรูปภาพ ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A), // กรอบสีเทา
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: shoe.imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: Image.network(
                      shoe.imageUrl,
                      fit: BoxFit.cover,
                      // เพิ่ม: โหลดรูปไม่ได้ให้โชว์ไอคอนแทน
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                          size: 36,
                        ),
                      ),
                    ),
                  )
                      : const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey,
                      size: 36,
                    ),
                  ),
                ),
              ),

              // --- ส่วนข้อมูลใต้รูปภาพ ---
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoe.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shoe.details,
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Text(
                          'รับสินค้าแล้ว',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.check, size: 12, color: Colors.grey),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  //  หัวข้อคำสั่งซื้อและการจัดส่ง
  Widget _buildOrdersHeader() {
    // นับจำนวนตามรายการจริง แทนตัวเลขที่เคยเขียนตายตัว
    final done = ordersList.where((o) => o['status'] == 'Delivered').length;
    final active = ordersList.length - done;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'คำสั่งซื้อและการจัดส่ง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${ordersList.length} คำสั่งซื้อ',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'กำลังดำเนินการ $active รายการ • สำเร็จล่าสุด $done รายการ\nยอดแต่ละคำสั่งซื้อรวมค่าจัดส่ง ฿100 แล้ว',
          style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  // 5. รายการคำสั่งซื้อ
  Widget _buildOrdersList() {

    if (ordersList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'ยังไม่มีคำสั่งซื้อ',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: ordersList.map((order) => _buildOrderCard(order)).toList(),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['id'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              _buildStatusBadge(order['status']),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order['date'],
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // กรอบรูปภาพสำหรับ Order
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: order['image'] != ''
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    order['image'],
                    fit: BoxFit.cover,
                    // เพิ่ม: โหลดรูปไม่ได้ให้โชว์ไอคอนแทน
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                        size: 28),
                  ),
                )
                    : const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['sizeQty'],
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                order['price'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildStatusProgressBar(order['step']),
          const SizedBox(height: 8),

          Text(
            order['statusText'],
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          const SizedBox(height: 16),

          _buildOrderActionButton(order['status']),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'Pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5500),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Pending',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    } else if (status == 'Shipped') {
      return const Text(
        'Shipped',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    } else {
      return Row(
        children: const [
          Icon(Icons.check, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Delivered',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      );
    }
  }

  Widget _buildStatusProgressBar(int step) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                color: step >= 1 ? const Color(0xFFFF5500) : Colors.grey[800],
              ),
              const SizedBox(height: 4),
              const Text('Pending',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                color: step >= 2 ? const Color(0xFFFF5500) : Colors.grey[800],
              ),
              const SizedBox(height: 4),
              const Text('Shipped',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                color: step >= 3 ? const Color(0xFFFF5500) : Colors.grey[800],
              ),
              const SizedBox(height: 4),
              const Text('Delivered',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderActionButton(String status) {
    if (status == 'Pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5500),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
          label: const Text(
            'ดู QR ชำระเงิน',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else if (status == 'Shipped') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.white24),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.local_shipping_outlined,
              color: Colors.white, size: 18),
          label: const Text(
            'ติดตามพัสดุ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.white24),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.north_east, color: Colors.white, size: 16),
          label: const Text(
            'ดูรายละเอียดคำสั่งซื้อ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }
}