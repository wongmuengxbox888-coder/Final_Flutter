import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pages/login.dart'; // หน้า Login
import 'pages/profile.dart'; // หน้าโปรไฟล์ (ตอนนี้ยังไม่ได้ใช้ในไฟล์นี้)
import 'pages/orders.dart'; // หน้าตะกร้า (CartAndCheckoutPage)
import 'pages/feature.dart'; // หน้ารายละเอียดสินค้า
import 'pages/collection.dart'; // หน้าคอลเลกชัน
import 'widgets/app_bottom_navigation_bar.dart';

const String kApiBaseUrl = 'http://127.0.0.1:8000'; ///เรียกจาก พอร์ต python
const String kProductsPath = '/products';

// สีแอป
class AppColors {
  static const bg = Color(0xFF0B0B0B); // พื้นหลังหลัก (ดำ)
  static const surface = Color(0xFF1D1D1D); // พื้นการ์ด
  static const imageBg = Color(0xFFE7E7E7); // พื้นหลังหลังรูปรองเท้า
  static const ink = Color(0xFFFFFFFF); // สีตัวหนังสือหลัก (ขาว)
  static const inkSoft = Color(0xFFAAAAAA); // ตัวหนังสือรอง (เทา)
  static const line = Color(0xFF383838); // สีเส้นขอบ
  static const accent = Color(0xFFFF5500); // สีส้มเน้น
  static const accentSoft = Color(0xFF302016); // ส้มอ่อน (พื้นปุ่มที่เลือก)
  static const gold = Color(0xFFAAAAAA); // สีหัวข้อเล็ก
  static const placeholder = Color(0xFF888888); // สี hint ในช่องค้นหา
  static const placeholderActive = Color(0xFFFF5500); // สี hint ตอนโฟกัส
}

// ข้อมูลรองเท้า
class Shoe {
  final int? id; // id จากฐานข้อมูล
  final String name; // ชื่อรองเท้า
  final String? price; // ราคา
  final String? imageUrl; // ลิงก์รูป

  // ลำดับ: ชื่อ, ราคา, รูป, id (ตัวที่ 2-4 ใส่หรือไม่ใส่ก็ได้)
  const Shoe(this.name, [this.price, this.imageUrl, this.id]);
}

// api
class ShoeApi {
  static const _nameKeys = ['name', 'product_name', 'shoe_name', 'title'];

  static Future<List<Shoe>> fetchAll() async {
    final uri = Uri.parse('$kApiBaseUrl$kProductsPath');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }

    dynamic body = jsonDecode(utf8.decode(res.bodyBytes));

    if (body is Map) {
      body = body['data'] ?? body['products'] ?? body['results'] ?? [];
    }
    if (body is! List) return [];

    final shoes = <Shoe>[];

    for (final item in body) {
      if (item is String) {
        shoes.add(Shoe(item));
      } else if (item is Map) {
        String? name;
        for (final k in _nameKeys) {
          if (item[k] != null) {
            name = item[k].toString();
            break;
          }
        }

        // ไม่มีชื่อ = ข้ามแถวนี้
        if (name == null) continue;

        final p = item['price']; // ราคา
        final raw = item['image_url']; // ลิงก์รูป
        // ถ้ามีลิงก์รูปและไม่ว่าง ใช้ค่านั้น ไม่งั้นเป็น null
        final img = (raw != null && raw.toString().isNotEmpty)
            ? raw.toString()
            : null;

        final id = item['id'] is int
            ? item['id'] as int
            : int.tryParse('${item['id']}');

        shoes.add(Shoe(name, p == null ? null : '฿$p', img, id));
      }
    }

    return shoes;
  }
}

/// start app
void main() => runApp(const RarePairApp());

class RarePairApp extends StatelessWidget {
  const RarePairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ซ่อนป้าย DEBUG
      title: 'brabrabra',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg, // พื้นหลังทุกหน้า
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness
              .dark, // ธีมมืด ทำให้ตัวหนังสือหน้าอื่นเป็นสีขาวอัตโนมัติ
          surface: AppColors.bg,
        ),
      ),
      home: const HomePage(),
    );
  }
}

void navigateToAppTab(
  BuildContext context,
  int index, {
  int? userId,
  int? currentIndex,
}) {
  if (index == currentIndex) return;

  final activeUserId = userId ?? CartAndCheckoutPage.currentUserId;
  final Widget page;
  switch (index) {
    case 0:
      page = HomePage(userId: activeUserId);
    case 1:
      page = const CartAndCheckoutPage();
    case 2:
      page = const ShoeRackAndOrdersPage();
    case 3:
      page = activeUserId == null
          ? const LoginPage()
          : ProfilePage(userId: activeUserId);
    default:
      throw RangeError.index(index, const [0, 1, 2, 3], 'index');
  }

  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
}

// homepage
class HomePage extends StatefulWidget {
  final int? userId;

  const HomePage({super.key, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<Shoe> _all = []; // รองเท้าทั้งหมดจาก /products
  List<Shoe> _results = []; // ผลลัพธ์หลังกรองด้วยคำค้น
  bool _loading = false;
  String? _error;
  int _selectedChip = 0;
  static const _chips = [
    'ทั้งหมด',
    'Vintage',
    'Limited Edition',
    'Collaboration',
  ];

  // อยู่ในโหมดค้นหา = มีข้อความในช่องค้นหา
  bool get _searching => _controller.text.trim().isNotEmpty;

  // รองเท้าที่โชว์ใน hero card ใหญ่
  Shoe? get _heroShoe {
    if (_all.isEmpty) return null;
    return _all.length > 6 ? _all[6] : _all.first;
  }

  @override  ///api load homepage
  void initState() {
    super.initState();

    if (widget.userId != null) {
      CartAndCheckoutPage.currentUserId = widget.userId;
    }
    _focus.addListener(() => setState(() {})); // โฟกัสเปลี่ยน = วาดหน้าใหม่
    _loadAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // โหลดข้อมูลจาก API ครั้งเดียว เก็บไว้ใน _all
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ShoeApi.fetchAll(); ///เรียก api มาเก้บใต้นี้ _all

      for (var i = 0; i < data.length; i++) {
        final shoe = data[i];
        debugPrint(
          '[$i] ชื่อ: ${shoe.name} | ราคา: ${shoe.price} | รูป: ${shoe.imageUrl}',
        );
      }

      if (!mounted) return; // ถ้าหน้าถูกปิดไปแล้ว ไม่ต้องอัปเดต

      setState(() {
        _all = data;
        _loading = false;
      });

      _filter(_controller.text); // กรองใหม่เผื่อมีคำค้นอยู่แล้ว
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้\n$e';
        _loading = false;
      });
    }
  }

  // กรองรองเท้าตามคำค้น (แสดงสูงสุด 8 รายการ)
  void _filter(String text) {
    final q = text.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _results = [];
      } else {
        _results = _all
            .where((shoe) => shoe.name.toLowerCase().contains(q))
            .take(8)
            .toList();
      }
    });
  }

  // ล้างข้อความค้นหา
  void _clear() {
    _controller.clear();
    _filter('');
  }

  // ปิดโหมดค้นหา (ปุ่ม "ยกเลิก")
  void _closeSearch() {
    _controller.clear();
    _filter('');
    _focus.unfocus();
    setState(() {});
  }

  // เปิดหน้ารายละเอียดรองเท้า พร้อมส่งข้อมูลของคู่ที่กด
  void _openFeature(Shoe shoe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          productId: shoe.id,
          name: shoe.name,
          price: shoe.price ?? '฿0',
          imageUrl: shoe.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(), // แถบหัวข้อ + ปุ่ม Login
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                // แตะพื้นที่ว่างตอนไม่มีคำค้น = เก็บคีย์บอร์ด
                onTap: () {
                  if (_controller.text.isEmpty) _focus.unfocus();
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _searchBar(), // ช่องค้นหา
                    const SizedBox(height: 12),
                    if (_searching)
                      _resultsPanel() // กำลังค้นหา: โชว์ผลลัพธ์
                    else ...[
                      // ไม่ได้ค้นหา: โชว์หน้าปกติ
                      _chipRow(),
                      const SizedBox(height: 20),
                      _heroCard(),
                      const SizedBox(height: 28),
                      _sectionTitle('คู่หายากที่น่าจับตา', 'ดูทั้งหมด'),
                      const SizedBox(height: 12),
                      _shoeGrid(),
                      const SizedBox(height: 28),
                      _sectionTitle('รองเท้าที่มีเรื่องราว', 'อ่านทั้งหมด'),
                      const SizedBox(height: 12),
                      _storyCard(),
                    ],
                  ],
                ),
              ),
            ),
            AppBottomNavigationBar(
              currentIndex: 0,
              onTap: (index) => navigateToAppTab(
                context,
                index,
                userId: widget.userId,
                currentIndex: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // บนสุด
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2),
                Text(
                  'ค้นพบคู่ที่มีเรื่องราว',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          // ปุ่ม Login กดแล้วไปหน้า LoginPage
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: Transform.translate(
              offset: const Offset(-14, 0), // ขยับข้อความไปทางซ้าย 14px
              child: const Text(
                'Login',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // ไอคอนกระดิ่ง (ยังไม่มีฟังก์ชัน)
          const Icon(
            Icons.notifications_none_rounded,
            size: 26,
            color: AppColors.ink,
          ),
        ],
      ),
    );
  }

  // ค้นหา
  Widget _searchBar() {
    final focused = _focus.hasFocus; // ตอนนี้โฟกัสอยู่ไหม

    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ), // แอนิเมชันเปลี่ยนสีขอบ
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                // โฟกัส = ขอบส้มหนาขึ้น
                color: focused ? AppColors.accent : AppColors.line,
                width: focused ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 24,
                  color: focused ? AppColors.accent : AppColors.ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: _filter, // พิมพ์แล้วกรองทันที
                    textInputAction: TextInputAction.search,
                    onSubmitted: _filter,
                    cursorColor: AppColors.accent,
                    style: const TextStyle(fontSize: 15, color: AppColors.ink),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'ค้นหารุ่น แบรนด์ หรือเรื่องราว',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: focused
                            ? AppColors.placeholderActive.withOpacity(0.6)
                            : AppColors.placeholder,
                      ),
                    ),
                  ),
                ),
                // มีข้อความ = โชว์ปุ่ม X ล้างข้อความ, ไม่มี = โชว์ไอคอนตัวกรอง
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clear,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.inkSoft,
                    ),
                  )
                else
                  const Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: AppColors.inkSoft,
                  ),
              ],
            ),
          ),
        ),
        // ปุ่ม "ยกเลิก" โผล่เฉพาะตอนกำลังค้นหา
        if (_searching) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _closeSearch,
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ผลค้นหา
  Widget _resultsPanel() {
    /// error state
    if (_loading && _results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // โหลดไม่สำเร็จ: โชว์ข้อความ error และปุ่มลองใหม่
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadAll, // กดแล้วโหลดใหม่
              child: const Text(
                'ลองอีกครั้ง',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
    }

    // ไม่เจอรองเท้าที่ตรงกับคำค้น
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'ไม่พบรองเท้าที่ค้นหา',
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ),
      );
    }

    final q = _controller.text.trim(); // คำค้นสำหรับไฮไลต์

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // บอกจำนวนรายการที่พบ
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'พบ ${_results.length} รายการ',
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ),
        // กล่องรายการผลลัพธ์
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: ListView.separated(
            shrinkWrap: true, // ให้สูงเท่าเนื้อหา
            physics:
                const NeverScrollableScrollPhysics(), // ใช้การเลื่อนของ ListView ด้านนอก
            itemCount: _results.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.line),
            itemBuilder: (_, i) => _resultTile(_results[i], q),
          ),
        ),
      ],
    );
  }

  // แถวผลลัพธ์ 1 แถว
  Widget _resultTile(Shoe shoe, String query) {
    return InkWell(
      // กดแล้วเก็บคีย์บอร์ดและเปิดหน้ารายละเอียด
      onTap: () {
        _focus.unfocus();
        _openFeature(shoe);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // รูปเล็ก 44x44 (ไม่มีรูปหรือโหลดไม่ได้ = ไอคอนคนวิ่ง)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                color: AppColors.imageBg,
                child: shoe.imageUrl == null
                    ? const Icon(
                        Icons.directions_run_rounded,
                        color: AppColors.inkSoft,
                        size: 22,
                      )
                    : Image.network(
                        shoe.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.directions_run_rounded,
                          color: AppColors.inkSoft,
                          size: 22,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // ชื่อรองเท้า พร้อมไฮไลต์คำที่ค้น
            Expanded(child: _highlight(shoe.name, query)),
            // ราคา (ถ้ามี)
            if (shoe.price != null) ...[
              Text(
                shoe.price!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.north_west_rounded,
              size: 16,
              color: AppColors.placeholder,
            ),
          ],
        ),
      ),
    );
  }

  // ทำให้ตัวอักษรที่ตรงกับคำค้นเป็นสีส้มตัวหนา
  Widget _highlight(String text, String query) {
    const base = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
    );

    if (query.isEmpty) return Text(text, style: base);

    // หาตำแหน่งที่คำค้นปรากฏในชื่อ (ไม่สนตัวพิมพ์เล็กใหญ่)
    final i = text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) return Text(text, style: base);

    final end = (i + query.length).clamp(0, text.length);

    // แบ่งข้อความเป็น 3 ท่อน: ก่อนคำค้น / คำค้น (ส้ม) / หลังคำค้น
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, end),
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }

  // แถว ชิปด้านบน ติ๊กถูก
  Widget _chipRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_chips.length, (i) {
        final sel = i == _selectedChip; // chip นี้ถูกเลือกไหม

        return GestureDetector(
          onTap: () => setState(() => _selectedChip = i), // กด = เลือก chip นี้
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? Colors.black : AppColors.inkSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? AppColors.ink : AppColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // chip ที่เลือกมีเครื่องหมายถูก
                if (sel) ...[
                  const Icon(Icons.check, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  _chips[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // แสดงรองเท้า ใช้ซ้ำทุกการ์ด
  // ไม่มีลิงก์หรือโหลดรูปไม่ได้ จะโชว์ไอคอนคนวิ่งแทน
  Widget _shoeImage(
    String? url, {
    double? height,
    double iconSize = 40,
    BoxFit fit = BoxFit.cover,
  }) {
    // widget สำรองที่ใช้เมื่อไม่มีรูป
    final fallback = Center(
      child: Icon(
        Icons.directions_run_rounded,
        size: iconSize,
        color: AppColors.placeholder,
      ),
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: url == null || url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: fit,
              errorBuilder: (_, __, ___) => fallback, // โหลดพลาด = ไอคอน
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback, // ระหว่างโหลด = ไอคอน
            ),
    );
  }

  // การ์ฺดแรกของเว้บ
  Widget _heroCard() {
    final shoe = _heroShoe; // รองเท้าที่เลือกไว้ใน getter _heroShoe

    debugPrint('hero: ${shoe?.name} / ${shoe?.imageUrl}');

    return InkWell(
      // กดการ์ด = เปิดรายละเอียด (ถ้ายังไม่มีข้อมูลจะกดไม่ได้)
      onTap: shoe == null ? null : () => _openFeature(shoe),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวหัวการ์ด: ป้าย RARE PICK + ช่วงวันที่
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'RARE PICK ประจำสัปดาห์',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  '18–24 ต.ค. 2026',
                  style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // รูปรองเท้าขนาดใหญ่ (สูง 320)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: AppColors.imageBg,
                child: _shoeImage(
                  shoe?.imageUrl,
                  height: 320,
                  iconSize: 60,
                  fit: BoxFit.contain, // แสดงรูปทั้งใบไม่ถูกตัด
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ชื่อรองเท้า (สูงสุด 2 บรรทัด)
            Text(
              shoe?.name ?? 'กำลังโหลด...',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            // แถวล่าง: ราคา (ซ้าย) + ข้อความ "ดูรองเท้าและเรื่องราว" (ขวา)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shoe?.price ?? '',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'ดูรองเท้าและเรื่องราว',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 18, color: AppColors.ink),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // หัวข้อแต่ละส่วน
  Widget _sectionTitle(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        // ข้อความด้านขวา (เช่น "ดูทั้งหมด") กดแล้วเปิดรองเท้าคู่แรก
        GestureDetector(
          onTap: _all.isEmpty ? null : () => _openFeature(_all.first),
          child: Text(
            action,
            style: const TextStyle(fontSize: 12, color: AppColors.accent),
          ),
        ),
      ],
    );
  }

  // ตารางรองเท้า เลือกได้ให้แสดงเท่าไหร่
  Widget _shoeGrid() {
    final shoes = _all.skip(1).take(10).toList();
    if (shoes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'กำลังโหลด...',
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true, // สูงเท่าเนื้อหา
      physics: const NeverScrollableScrollPhysics(), // ไม่เลื่อนซ้อน
      itemCount: shoes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 คอลัมน์
        mainAxisSpacing: 12, // ระยะห่างแนวตั้ง
        crossAxisSpacing: 12, // ระยะห่างแนวนอน
        childAspectRatio: 0.85, // สัดส่วน กว้าง/สูง ของการ์ด
      ),
      itemBuilder: (_, i) {
        final shoe = shoes[i];

        return InkWell(
          onTap: () => _openFeature(shoe), // กดการ์ด = เปิดรายละเอียด
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias, // ตัดเนื้อหาให้โค้งตามขอบ
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนรูป (กินพื้นที่ที่เหลือ)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: AppColors.imageBg,
                    child: _shoeImage(
                      shoe.imageUrl,
                      iconSize: 46,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // ส่วนชื่อ + ราคา
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shoe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shoe.price ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // story card bottom web
  Widget _storyCard() {
    final shoe = _all.length > 10
        ? _all[10]
        : (_all.isNotEmpty ? _all.first : null);

    return InkWell(
      onTap: shoe == null ? null : () => _openFeature(shoe),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            // รูปด้านซ้าย 100x100
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 100,
                height: 100,
                color: AppColors.imageBg,
                child: _shoeImage(
                  shoe?.imageUrl,
                  height: 100,
                  iconSize: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // ข้อความด้านขวา
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HERITAGE / อ่าน 3 นาที',
                    style: TextStyle(fontSize: 11, color: AppColors.gold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shoe?.name ?? 'รองเท้าที่มีเรื่องราว',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ทำไมรองเท้าคู่นี้ถึงน่าสนใจ',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'อ่านเรื่องราว →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
