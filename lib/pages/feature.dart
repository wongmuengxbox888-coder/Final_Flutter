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
      home: const ProductDetailPage(),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int selectedImageIndex = 0;
  String selectedSize = '9';

  final List<String> sizes = ['8', '8.5', '9', '9.5', '10'];
  final List<String> disabledSizes = ['8', '9.5'];

  final List<Map<String, String>> gallery = [
    {
      'label': 'ด้านข้าง',
      'url': 'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800'
    },
    {
      'label': 'ด้านหลัง',
      'url': 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800'
    },
    {
      'label': 'พื้นรองเท้า',
      'url': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800'
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
          'รองเท้าและเรื่องราว',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // ถ้าความกว้างหน้าจอมากกว่า 800px (คอมพิวเตอร์/แท็บเล็ต) ให้แยกเป็น 2 คอลัมน์
          bool isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildImageGallery(),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductInfo(),
                        const Divider(color: Colors.white24, height: 32),
                        _buildSizeSelector(),
                        const SizedBox(height: 24),
                        _buildStorySection(),
                        const SizedBox(height: 24),
                        _buildBottomActionBar(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // หน้าจอมือถือ
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageGallery(),
                const SizedBox(height: 20),
                _buildProductInfo(),
                const Divider(color: Colors.white24, height: 32),
                _buildSizeSelector(),
                const SizedBox(height: 24),
                _buildStorySection(),
                const SizedBox(height: 24),
                _buildBottomActionBar(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFFFF5500),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'ตะกร้า'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'คอลเลกชัน'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  // 1. ส่วนรูปภาพหลัก และ Thumbnails
  Widget _buildImageGallery() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(gallery[selectedImageIndex]['url']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '0${selectedImageIndex + 1} / 0${gallery.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(gallery.length, (index) {
            bool isSelected = selectedImageIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedImageIndex = index),
                child: Container(
                  margin: EdgeInsets.only(right: index == gallery.length - 1 ? 0 : 8),
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF5500) : Colors.transparent,
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(gallery[index]['url']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        gallery[index]['label']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 2. ส่วนข้อมูลสินค้า ชื่อ และราคา
  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JORDAN / REIMAGINED COLLECTION',
          style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        const Text(
          "Air Jordan 1 High OG 'Lost & Found'",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Chicago • เปิดตัวปี 2022 รหัสรุ่น DZ5485-612 • สภาพใหม่ / Deadstock',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '฿14,900',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Row(
              children: const [
                Icon(Icons.circle, color: Color(0xFFFF5500), size: 8),
                SizedBox(width: 6),
                Text('มีสินค้า • เหลือ 3 คู่', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ],
    );
  }

  // 3. ส่วนเลือกไซส์
  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('เลือกไซส์ (US Men)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            TextButton(
              onPressed: () {},
              child: const Text('ตารางไซส์ ↗', style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: sizes.map((size) {
            bool isSelected = selectedSize == size;
            bool isDisabled = disabledSizes.contains(size);

            return Expanded(
              child: GestureDetector(
                onTap: isDisabled ? null : () => setState(() => selectedSize = size),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF5500)
                        : (isDisabled ? Colors.grey[900] : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF5500) : Colors.grey[800]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isDisabled ? '$size ×' : size,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey[600] : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'เลือกแล้ว: US $selectedSize / EU 42.5 / 27 ซม. มี 1 คู่ในไซส์นี้ • × = สินค้าหมด',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  // 4. ส่วนเรื่องราวสินค้าและรายละเอียดเพิ่มเติม
  Widget _buildStorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('เรื่องราวของคู่นี้', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('1985 → 2022 • ตำนานที่ถูกค้นพบอีกครั้ง',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 10),
        Text(
          'สี Chicago ถือกำเนิดบน Air Jordan 1 ในปี 1985 และกลายเป็นหนึ่งในสีที่นักสะสมจดจำมากที่สุด รุ่น Lost & Found ปี 2022 ถ่ายทอดบรรยากาศการพบรองเท้าคู่เก่าในห้องเก็บของ ผ่านหนังแตกสาย กล่องสไตล์วินเทจ และใบเสร็จจำลองจากร้านรองเท้ายุค 80s',
          style: TextStyle(color: Colors.grey[300], fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('แบรนด์ Jordan • คอลเลกชัน Reimagined',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(height: 4),
              Text(
                'นำรุ่นไอคอนิกกลับมาตีความใหม่ โดยเก็บเสน่ห์ดั้งเดิมและรายละเอียดแบบ aged finish ไว้ให้สายสะสม',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.verified_outlined, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'ตรวจสอบความแท้ทุกคู่ • พร้อมกล่องเดิม\nจัดส่งแบบติดตามพัสดุได้ภายในประเทศไทย',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            )
          ],
        )
      ],
    );
  }

  // 5. ปุ่มเพิ่มลงตะกร้าและสั่งซื้อ
  Widget _buildBottomActionBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('US $selectedSize • จำนวน 1 คู่', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Text('฿14,900', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                label: const Text('เพิ่มลงตะกร้า', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5500),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('ซื้อเลย',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}