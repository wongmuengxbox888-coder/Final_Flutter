import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pages/login.dart';
import 'pages/profile.dart';


const String kApiBaseUrl = 'http://127.0.0.1:8000';
const String kProductsPath = '/products';



// color mom
class AppColors {
  static const bg = Color(0xFF0B0B0B);
  static const surface = Color(0xFF1D1D1D);
  static const imageBg = Color(0xFFE7E7E7);
  static const ink = Color(0xFFFFFFFF);
  static const inkSoft = Color(0xFFAAAAAA);
  static const line = Color(0xFF383838);
  static const accent = Color(0xFFFF5500);
  static const accentSoft = Color(0xFF302016);
  static const gold = Color(0xFFAAAAAA);
  static const placeholder = Color(0xFF888888);
  static const placeholderActive = Color(0xFFFF5500);
}

///api
class Shoe {
  final String name;
  final String? price;
  final String? imageUrl;
  const Shoe(this.name, [this.price, this.imageUrl]);
}

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

        // อ่านค่าจาก main.py (FastAPI) ตามชื่อ column ในตาราง products
        if (name == null) continue;
        final p = item['price'];
        final raw = item['image_url'];
        final img = (raw != null && raw.toString().isNotEmpty)
            ? raw.toString()
            : null;

        shoes.add(Shoe(name, p == null ? null : '฿$p', img));
      }
    }
    return shoes;
  }
}

///app
void main() => runApp(const RarePairApp());

class RarePairApp extends StatelessWidget {
  const RarePairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'brabrabra',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.bg,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final int? userId;

  const HomePage({
    super.key,
    this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<Shoe> _all = []; // รองเท้าทั้งหมดจาก /products
  List<Shoe> _results = []; // ผลหลังกรองด้วยคำค้น
  bool _loading = false;
  String? _error;
  int _selectedChip = 0;
  int _navIndex = 0;

  static const _chips = ['ทั้งหมด', 'Vintage', 'Limited Edition', 'Collaboration'];

  // อยู่ในโหมดค้นหา = มีข้อความอยู่ในช่องค้นหา
  bool get _searching => _controller.text.trim().isNotEmpty;
  Shoe? get _heroShoe {
    if (_all.isEmpty) return null;
    return _all.firstWhere(
          (s) =>
      s.imageUrl != null &&
          s.imageUrl!.trim().isNotEmpty &&
          s.name != 'product-card__link-overlay' &&
          s.price != '฿product-price',
      orElse: () => _all.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _loadAll(); // โหลดรองเท้าทั้งหมดตั้งแต่เปิดหน้า
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// เรียก GET /products ครั้งเดียว เก็บไว้ใน _all
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ShoeApi.fetchAll();
      for (final shoe in data) {
        debugPrint(
          'ชื่อ: ${shoe.name} | ราคา: ${shoe.price} | รูป: ${shoe.imageUrl}',
        );
      }
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
      _filter(_controller.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้\n$e';
        _loading = false;
      });
    }
  }

  /// กรองรายการที่โหลดมาแล้วตามคำค้น
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

  void _clear() {
    _controller.clear();
    _filter('');
  }

  void _closeSearch() {
    _controller.clear();
    _filter('');
    _focus.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_controller.text.isEmpty) _focus.unfocus();
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _searchBar(),
                    const SizedBox(height: 12),
                    if (_searching)
                      _resultsPanel()
                    else ...[
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
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  // head
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
          TextButton(
             onPressed: () {
               Navigator.push(
                context,
                 MaterialPageRoute(
                 builder: (context) => const LoginPage(),
                ),
            );
         },
          child: Transform.translate(
              offset: const Offset(-14, 0), ///margin right
              child: const Text(
                  'Login',
                style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ),
          const Icon(Icons.notifications_none_rounded,
              size: 26, color: AppColors.ink),
        ],
      ),
    );
  }

  //  Search bar (เชื่อม API)
  Widget _searchBar() {
    final focused = _focus.hasFocus;
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: focused ? AppColors.accent : AppColors.line,
                width: focused ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search,
                    size: 24,
                    color: focused ? AppColors.accent : AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: _filter,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _filter,
                    cursorColor: AppColors.accent,
                    style: const TextStyle(fontSize: 15, color: AppColors.ink),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'ค้นหารุ่น แบรนด์ หรือเรื่องราว',
                      // สี placeholder เปลี่ยนตอนกำลังจะค้นหา
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: focused
                            ? AppColors.placeholderActive.withOpacity(0.6)
                            : AppColors.placeholder,
                      ),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clear,
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.inkSoft),
                  )
                else
                  const Icon(Icons.tune_rounded,
                      size: 22, color: AppColors.inkSoft),
              ],
            ),
          ),
        ),
        if (_searching) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _closeSearch,
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  // ผลค้นหา
  Widget _resultsPanel() {
    if (_loading && _results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2.5),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.ink, fontSize: 13)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadAll,
              child: const Text('ลองอีกครั้ง',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text('ไม่พบรองเท้าที่ค้นหา',
              style: TextStyle(color: AppColors.inkSoft)),
        ),
      );
    }

    final q = _controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'พบ ${_results.length} รายการ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkSoft,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _results.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.line),
            itemBuilder: (_, i) => _resultTile(_results[i], q),
          ),
        ),
      ],
    );
  }

  Widget _resultTile(Shoe shoe, String query) {
    return InkWell(
      onTap: () {
        // TODO: เปิดหน้ารายละเอียดรองเท้า
        _focus.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                color: AppColors.imageBg,
                child: shoe.imageUrl == null
                    ? const Icon(Icons.directions_run_rounded,
                    color: AppColors.inkSoft, size: 22)
                    : Image.network(
                  shoe.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.directions_run_rounded,
                      color: AppColors.inkSoft,
                      size: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _highlight(shoe.name, query)),
            if (shoe.price != null) ...[
              Text(shoe.price!,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.north_west_rounded,
                size: 16, color: AppColors.placeholder),
          ],
        ),
      ),
    );
  }

  /// ไฮไลต์ตัวอักษรที่ตรงกับคำค้นเป็นสีส้ม
  Widget _highlight(String text, String query) {
    const base = TextStyle(
        fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink);
    if (query.isEmpty) return Text(text, style: base);
    final i = text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) return Text(text, style: base);
    return Text.rich(TextSpan(style: base, children: [
      TextSpan(text: text.substring(0, i)),
      TextSpan(
        text: text.substring(i, i + query.length),
        style: const TextStyle(
            color: AppColors.accent, fontWeight: FontWeight.w700),
      ),
      TextSpan(text: text.substring(i + query.length)),
    ]));
  }

  // บา แรก
  Widget _chipRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_chips.length, (i) {
        final sel = i == _selectedChip;
        return GestureDetector(
          onTap: () => setState(() => _selectedChip = i),
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

  // รูปรองเท้า (ใช้ซ้ำทุกการ์ด) ถ้าไม่มีลิงก์/โหลดไม่ได้ จะแสดงไอคอนแทน
  Widget _shoeImage(String? url,
      {double? height, double iconSize = 40, BoxFit fit = BoxFit.cover}) {
    final fallback = Center(
      child: Icon(Icons.directions_run_rounded,
          size: iconSize, color: AppColors.placeholder),
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: url == null
          ? fallback
          : Image.network(
        url,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) =>
        progress == null ? child : fallback,
      ),
    );
  }

  // การ์ด แรกสุด (ใช้รองเท้าคู่แรกจากฐานข้อมูล)
  Widget _heroCard() {
    final shoe = _heroShoe;
    debugPrint('hero: ${shoe?.name} / ${shoe?.imageUrl}');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('RARE PICK ประจำสัปดาห์',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
              Text('18–24 ต.ค. 2026',
                  style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 12),  ///กล่องใน
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: AppColors.imageBg,
              child: _shoeImage(shoe?.imageUrl,
                  height: 320, iconSize: 60, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            shoe?.name ?? 'กำลังโหลด...',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(shoe?.price ?? '',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
              const Row(
                children: [
                  Text('ดูรองเท้าและเรื่องราว',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18, color: AppColors.ink),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Section title ----------------
  Widget _sectionTitle(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        Text(action,
            style: const TextStyle(fontSize: 12, color: AppColors.accent)),
      ],
    );
  }


  Widget _shoeGrid() {
    final shoes = _all.skip(1).take(10).toList(); //หยิบ รองเท้ามาแดสง
    if (shoes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('กำลังโหลด...',
              style: TextStyle(color: AppColors.inkSoft)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shoes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final shoe = shoes[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.imageBg,
                  child: _shoeImage(shoe.imageUrl,
                      iconSize: 46, fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shoe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(height: 6),
                    Text(shoe.price ?? '',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- Story card (รูปจากฐานข้อมูล ข้อความยังเป็นตัวอย่าง) ----------------
  Widget _storyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 100,
              height: 110,
              color: AppColors.imageBg,
              child: _shoeImage(
                _all.length > 5
                    ? _all[5].imageUrl
                    : (_all.isNotEmpty ? _all.first.imageUrl : null),
                height: 110,
                iconSize: 40,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HERITAGE / อ่าน 3 นาที',
                    style: TextStyle(fontSize: 11, color: AppColors.gold)),
                SizedBox(height: 4),
                Text('จากสนามบาส สู่ต้นตำนาน Air Jordan 1',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                SizedBox(height: 4),
                Text('ทำไมสี Chicago ถึงเป็นจุดเริ่มต้นของนักสะสม',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                SizedBox(height: 8),
                Text('อ่านเรื่องราว →',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // tab bar
  Widget _bottomNav() {
    const tabs = [
      [Icons.home_outlined, Icons.home_rounded, 'หน้าแรก'],
      [Icons.shopping_bag_outlined, Icons.shopping_bag, 'ตะกร้า'],
      [Icons.collections_bookmark_outlined, Icons.collections_bookmark, 'คอลเลกชัน'],
      [Icons.person_outline, Icons.person, 'โปรไฟล์'],
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (i) {
          final sel = i == _navIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _navIndex = i);

              if (i == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(

                    ),
                  ),
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    (sel ? tabs[i][1] : tabs[i][0]) as IconData,
                    size: 26,
                    color: sel ? AppColors.accent : AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tabs[i][2] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? AppColors.accent : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}