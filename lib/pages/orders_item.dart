import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5500),
        ),
      ),
      home: const ShoeRackAndOrdersPage(),
    );
  }
}

class ShoeRackAndOrdersPage extends StatefulWidget {
  const ShoeRackAndOrdersPage({super.key});

  @override
  State<ShoeRackAndOrdersPage> createState() => _ShoeRackAndOrdersPageState();
}

class _ShoeRackAndOrdersPageState extends State<ShoeRackAndOrdersPage> {
  // ข้อมูลชั้นรองเท้า (คอลเลกชันที่ครอบครอง)
  final List<Map<String, String>> shoeRackList = [
    {
      'name': "Dunk Low 'Panda'",
      'details': 'US 9 • รับเมื่อ 12 ต.ค. 2026',
      'image': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800',
    },
    {
      'name': "AJ1 'Bred' (2001)",
      'details': 'US 9 • รับเมื่อ 20 ก.ย. 2026',
      'image': 'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800',
    },
    {
      'name': "Air Max 90 'Infrared'",
      'details': 'US 9 • รับเมื่อ 8 ส.ค. 2026',
      'image': 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800',
    },
    {
      'name': "SB Dunk 'Purple Lobster'",
      'details': 'US 9 • รับเมื่อ 14 มิ.ย. 2026',
      'image': 'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=800',
    },
    {
      'name': "990v3 'Grey' (2012)",
      'details': 'US 9 • รับเมื่อ 3 ก.พ. 2026',
      'image': 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=800',
    },
    {
      'name': "350 'Turtle Dove'",
      'details': 'US 9 • รับเมื่อ 18 ธ.ค. 2025',
      'image': 'https://images.unsplash.com/photo-1582588678413-dbf45f4823e9?w=800',
    },
  ];

  // ข้อมูลคำสั่งซื้อ
  final List<Map<String, dynamic>> ordersList = [
    {
      'id': '#RP-261018-024',
      'date': 'สั่งซื้อ 18 ต.ค. 2026',
      'status': 'Pending',
      'statusText': 'รอชำระเงินภายใน 10:11 น. วันนี้',
      'name': 'New Balance 550 • Aimé Leon Dore',
      'sizeQty': 'US 9 • 1 คู่',
      'price': '฿13,000',
      'image': 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=800',
      'step': 1, // 1: Pending, 2: Shipped, 3: Delivered
    },
    {
      'id': '#RP-261016-018',
      'date': 'สั่งซื้อ 16 ต.ค. 2026',
      'status': 'Shipped',
      'statusText': 'TH Post: TH0123456789 • คาดถึง 20 ต.ค.',
      'name': 'Air Max 1/97 • Sean Wotherspoon',
      'sizeQty': 'US 9 • 1 คู่',
      'price': '฿33,000',
      'image': 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800',
      'step': 2,
    },
    {
      'id': '#RP-261008-011',
      'date': 'สั่งซื้อ 8 ต.ค. 2026',
      'status': 'Delivered',
      'statusText': 'รับสำเร็จ 12 ต.ค. 2026 • เพิ่มในชั้นรองเท้าแล้ว',
      'name': 'Dunk Low • Panda',
      'sizeQty': 'US 9 • 1 คู่',
      'price': '฿8,000',
      'image': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800',
      'step': 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
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
        currentIndex: 2, // เลือกหน้าคอลเลกชัน / ชั้นรองเท้า
        type: BottomNavigationBarType.fixed,
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
          const Text(
            '6',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'MY VIRTUAL SHOE RACK',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'สะสมแล้ว 6 คู่',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'รับสินค้าแล้วเท่านั้น',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. หัวข้อคอลเลกชัน
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

  // 3. Grid แสดงรองเท้าที่ครอบครอง
  Widget _buildShoeGrid({required int crossAxisCount}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shoeRackList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final shoe = shoeRackList[index];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    shoe['image']!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoe['name']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shoe['details']!,
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
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

  // 4. หัวข้อคำสั่งซื้อและการจัดส่ง
  Widget _buildOrdersHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'คำสั่งซื้อและการจัดส่ง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '3 คำสั่งซื้อ',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'กำลังดำเนินการ 2 รายการ • สำเร็จล่าสุด 1 รายการ\nยอดแต่ละคำสั่งซื้อรวมค่าจัดส่ง ฿100 แล้ว',
          style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  // 5. รายการคำสั่งซื้อ
  Widget _buildOrdersList() {
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
          // Header ของการ์ดคำสั่งซื้อ
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

          // รายละเอียดสินค้า
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  order['image'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
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

          // Progress Bar สถานะการจัดส่ง
          _buildStatusProgressBar(order['step']),
          const SizedBox(height: 8),

          Text(
            order['statusText'],
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          const SizedBox(height: 16),

          // ปุ่ม Action ตามสถานะ
          _buildOrderActionButton(order['status']),
        ],
      ),
    );
  }

  // Widget แสดง Badge สถานะ
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

  // Widget แสดง เส้น Progress สถานะ
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

  // Widget แสดงปุ่มตามสถานะ
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