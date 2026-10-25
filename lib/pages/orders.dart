import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'collection.dart'; // เพิ่ม: หน้าคอลเลกชัน (เก็บคำสั่งซื้อที่ยืนยันแล้ว)

const String apiUrl = 'http://127.0.0.1:8000';

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
      home: const CartAndCheckoutPage(),
    );
  }
}

class CartAndCheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const CartAndCheckoutPage({
    super.key,
    this.product,
  });

  // ===== เพิ่ม: รายการสินค้าในตะกร้า (static = ใช้ร่วมกันทุกหน้า) =====
  static final List<Map<String, dynamic>> cartItems = [];

  // เพิ่ม: id ผู้ใช้ที่ล็อกอิน (main.dart เป็นคนตั้งค่าให้) ใช้ตอนบันทึกคำสั่งซื้อ
  static int? currentUserId;

  // เพิ่ม: ตัวนับ id ให้สินค้าแต่ละรายการ (ใช้ตอนกดลบ)
  static int _nextId = 1;

  // ===== เพิ่ม: ฟังก์ชันที่หน้า feature.dart เรียกตอนกด "เพิ่มลงตะกร้า" / "ซื้อเลย" =====
  static void addProduct(Map<String, dynamic> product) {
    // แปลงไซส์ให้ตรงกับ dropdown ในหน้านี้ เช่น '9' -> 'US 9'
    final rawSize = (product['size'] ?? '9').toString();
    final size = rawSize.startsWith('US') ? rawSize : 'US $rawSize';

    // ถ้ามีรองเท้าชื่อเดียวกัน + ไซส์เดียวกันอยู่แล้ว ให้บวกจำนวนเพิ่ม
    final index = cartItems.indexWhere(
          (item) => item['name'] == product['name'] && item['size'] == size,
    );

    if (index != -1) {
      cartItems[index]['quantity'] =
          (cartItems[index]['quantity'] as int) +
              ((product['quantity'] ?? 1) as int);
    } else {
      // ถ้ายังไม่มี ให้เพิ่มเป็นรายการใหม่ (ใส่ field ที่หน้านี้ต้องใช้ให้ครบ)
      cartItems.add({
        'id': _nextId++,
        'product_id': product['product_id'], // id ในตาราง products
        'name': product['name'],
        'subtitle': '',
        'price': product['price'],
        'size': size,
        'quantity': product['quantity'] ?? 1,
        'image': product['image'] ?? '',
      });
    }
  }

  @override
  State<CartAndCheckoutPage> createState() => _CartAndCheckoutPageState();
}

class _CartAndCheckoutPageState extends State<CartAndCheckoutPage> {
  // เพิ่ม: ทางลัดเรียกรายการตะกร้า (โค้ดเดิมด้านล่างใช้ชื่อ cartItems ได้เหมือนเดิม)
  List<Map<String, dynamic>> get cartItems => CartAndCheckoutPage.cartItems;

  bool _submitting = false; // เพิ่ม: กันกดยืนยันซ้ำระหว่างรอเซิร์ฟเวอร์

  @override
  void initState() {
    super.initState();
    // เพิ่ม: ถ้ามีสินค้าส่งมาตอนเปิดหน้านี้ ให้ใส่ตะกร้า
    if (widget.product != null) {
      CartAndCheckoutPage.addProduct(widget.product!);
    }
  }

  // ข้อมูลรายการสินค้าในตะกร้า
  void addToCart({
    required int id,
    required String name,
    required int price,
    required String? imageUrl,
  }) {
    setState(() {
      final index = cartItems.indexWhere(
            (item) => item['id'] == id,
      );

      if (index != -1) {
        cartItems[index]['quantity']++;
      } else {
        cartItems.add({
          'id': id,
          'name': name,
          'subtitle': '',
          'price': price,
          'size': 'US 9',
          'quantity': 1,
          'image': imageUrl ?? '',
        });
      }
    });
  }

  // Controllers สำหรับที่อยู่จัดส่ง
  final TextEditingController _nameController =
  TextEditingController(text: 'ธนกฤต วัฒนกุล');
  final TextEditingController _phoneController =
  TextEditingController(text: '081 234 5678');
  final TextEditingController _addressController =
  TextEditingController(text: '88/12 ซอยสุขุมวิท 55 ถนนสุขุมวิท');
  final TextEditingController _subDistrictController =
  TextEditingController(text: 'คลองตันเหนือ');
  final TextEditingController _districtController =
  TextEditingController(text: 'วัฒนา');
  final TextEditingController _provinceController =
  TextEditingController(text: 'กรุงเทพมหานคร');
  final TextEditingController _zipController =
  TextEditingController(text: '10110');

  bool isDefaultAddress = true;
  int shippingFee = 100;

  // คำนวณราคารวม
  int get subtotal => cartItems.fold(
      0, (sum, item) => sum + ((item['price'] as int) * (item['quantity'] as int)));
  int get total => subtotal + shippingFee;
  int get totalPairs => cartItems.fold(
      0, (sum, item) => sum + (item['quantity'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFFF5500),
          ),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: const Text(
          'ตะกร้าและชำระเงิน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFFFF5500),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 800;

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
                        _buildCartSection(),
                        const SizedBox(height: 32),
                        _buildAddressSection(),
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
                        _buildShippingSection(),
                        const SizedBox(height: 24),
                        _buildPaymentSection(),
                        const SizedBox(height: 24),
                        _buildOrderSummarySection(),
                        const SizedBox(height: 24),
                        _buildCheckoutButton(),
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
                _buildCartSection(),
                const SizedBox(height: 28),
                _buildAddressSection(),
                const SizedBox(height: 28),
                _buildShippingSection(),
                const SizedBox(height: 28),
                _buildPaymentSection(),
                const SizedBox(height: 28),
                _buildOrderSummarySection(),
                const SizedBox(height: 24),
                _buildCheckoutButton(),
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
        currentIndex: 1, // เลือกหน้าตะกร้า
        type: BottomNavigationBarType.fixed, //]lock bar
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          } else if (index == 2) {
            // เพิ่ม: กดคอลเลกชัน -> ไปหน้าคอลเลกชัน
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ShoeRackAndOrdersPage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'ตะกร้า'),
          BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: 'คอลเลกชัน'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
  // 1. ส่วนรายการรองเท้าที่เลือกไว้
  Widget _buildCartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'รองเท้าที่เลือกไว้',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF5500),
              ),
            ),
            Text(
              '${cartItems.length} รายการ / $totalPairs คู่',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...cartItems.map((item) => _buildCartItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image'],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.grey, size: 20),
                          onPressed: () {
                            setState(() {
                              cartItems.removeWhere((i) => i['id'] == item['id']);
                            });
                          },
                        ),
                      ],
                    ),
                    Text(
                      item['subtitle'],
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '฿${item['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ปุ่มเลือกไซส์ Dropdown
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: item['size'],
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: ['US 8', 'US 8.5', 'US 9', 'US 9.5', 'US 10']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => item['size'] = val);
                      }
                    },
                  ),
                ),
              ),
              // ปุ่มกด เพิ่ม-ลด จำนวน
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () {
                        if (item['quantity'] > 1) {
                          setState(() => item['quantity']--);
                        }
                      },
                    ),
                    Text('${item['quantity']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () {
                        setState(() => item['quantity']++);
                      },
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }


  // เพิ่ม: กด "ยืนยันคำสั่งซื้อ"
  Future<void> _confirmOrder() async {
    if (_submitting) return;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มสินค้าลงตะกร้าก่อน')),
      );
      return;
    }

    setState(() => _submitting = true);

    final items = cartItems.map((e) => Map<String, dynamic>.from(e)).toList();
    final orderTotal = total;

    int? orderId;
    String? warning;

    try {
      final response = await http
          .post(
        Uri.parse('$apiUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': CartAndCheckoutPage.currentUserId,
          'total': orderTotal,
          'items': items
              .map((e) => {
            'product_id': e['product_id'],
            'name': e['name'],
            'quantity': e['quantity'],
            'price': e['price'],
          })
              .toList(),
        }),
      )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        orderId = (data['order_id'] as num?)?.toInt();
      } else {
        warning = data['detail']?.toString() ?? 'บันทึกคำสั่งซื้อไม่สำเร็จ';
      }
    } catch (e) {
      debugPrint('CONFIRM ORDER ERROR: $e');
      warning = 'เชื่อมต่อ FastAPI ไม่ได้';
    }

    if (!mounted) return;

    // เพิ่มเข้าคอลเลกชัน + ล้างตะกร้า (ทำเสมอ)
    ShoeRackAndOrdersPage.addConfirmedOrder(
      items: items,
      total: orderTotal,
      orderNumber: orderId,
    );

    setState(() {
      cartItems.clear();
      _submitting = false;
    });

    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เพิ่มในคอลเลกชันแล้ว แต่ฐานข้อมูล: $warning'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 6),
        ),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ShoeRackAndOrdersPage()),
    );
  }

  Future<void> _saveAddress() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _subDistrictController.text.trim().isEmpty ||
        _districtController.text.trim().isEmpty ||
        _provinceController.text.trim().isEmpty ||
        _zipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบ'),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/addresses'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name_lastname': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'subdistrict': _subDistrictController.text.trim(),
          'amphoe': _districtController.text.trim(),
          'province': _provinceController.text.trim(),
          'messenger_number': _zipController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Address status: ${response.statusCode}');
      debugPrint('Address response: ${response.body}');

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกที่อยู่สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['detail']?.toString() ??
                  data['message']?.toString() ??
                  'บันทึกข้อมูลไม่สำเร็จ',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('SAVE ADDRESS ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เชื่อมต่อ FastAPI ไม่ได้'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 2. ส่วนกรอกที่อยู่จัดส่ง
  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ที่อยู่จัดส่ง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5500),
            ),
          ),


          const SizedBox(height: 16),

          _buildTextField('ชื่อ-นามสกุล', _nameController),
          const SizedBox(height: 12),

          _buildTextField('เบอร์โทรศัพท์', _phoneController),
          const SizedBox(height: 12),

          _buildTextField('ที่อยู่', _addressController),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'ตำบล/แขวง',
                  _subDistrictController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  'อำเภอ/เขต',
                  _districtController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'จังหวัด',
                  _provinceController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  'รหัสไปรษณีย์',
                  _zipController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Checkbox(
                value: isDefaultAddress,
                activeColor: const Color(0xFFFF5500),
                onChanged: (value) {
                  setState(() {
                    isDefaultAddress = value ?? false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'บันทึกเป็นที่อยู่เริ่มต้น • ประเทศไทย',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // ปุ่มบันทึกข้อมูลที่เพิ่มเข้ามา
          const SizedBox(height: 16),


          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveAddress,
              icon: const Icon(Icons.save),
              label: const Text('บันทึกข้อมูล'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,

          // สีข้อความที่พิมพ์ในช่อง
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),

          cursorColor: const Color(0xFFFF5500),

          decoration: InputDecoration(
            // สี Placeholder ตอนช่องว่าง
            hintStyle: const TextStyle(
              color: Colors.white70,
            ),

            filled: true,

            // ปรับพื้นหลังให้สว่างขึ้นเล็กน้อย
            fillColor: const Color(0xFF252525),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF5500)),
            ),
          ),
        ),
      ],
    );
  }

  // 3. ส่วนการจัดส่ง
  Widget _buildShippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การจัดส่ง',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF5500),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF5500), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.radio_button_checked,
                  color: Color(0xFFFF5500), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('จัดส่งมาตรฐาน',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('2–4 วันทำการ • มีเลขติดตามพัสดุ',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Text('฿100',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  // 4. ส่วนวิธีชำระเงิน
  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'วิธีชำระเงิน',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF5500),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF5500), width: 1.5),
          ),
          child: Row(
            children: const [
              Icon(Icons.radio_button_checked,
                  color: Color(0xFFFF5500), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('QR พร้อมเพย์ / PromptPay',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'รับ QR หลังยืนยันคำสั่งซื้อ กรุณาชำระภายใน 30 นาที สถานะคำสั่งซื้อจะเป็น Pending ระหว่างรอชำระเงิน',
          style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  // 5. ส่วนสรุปคำสั่งซื้อ
  Widget _buildOrderSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สรุปคำสั่งซื้อ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ราคารองเท้า ($totalPairs คู่)',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                  '฿${subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('ค่าจัดส่ง',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text('฿100', style: TextStyle(fontSize: 14)),
            ],
          ),
          const Divider(color: Colors.white12, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ยอดชำระทั้งหมด',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '฿${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('ราคารวมภาษีแล้ว • ไม่มีค่าธรรมเนียมเพิ่มเติม',
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }

  // 6. ปุ่มยืนยันคำสั่งซื้อ
  Widget _buildCheckoutButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _confirmOrder, // เพิ่ม: ยืนยันแล้วไปหน้าคอลเลกชัน
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5500),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            label: Text(
              'ยืนยันคำสั่งซื้อ • ฿${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'เมื่อยืนยัน คุณยินยอมรับเงื่อนไขการสั่งซื้อ ตรวจสอบไซส์และที่อยู่ก่อนดำเนินการ',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}