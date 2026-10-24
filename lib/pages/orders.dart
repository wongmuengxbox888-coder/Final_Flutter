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
      home: const CartAndCheckoutPage(),
    );
  }
}

class CartAndCheckoutPage extends StatefulWidget {
  const CartAndCheckoutPage({super.key});

  @override
  State<CartAndCheckoutPage> createState() => _CartAndCheckoutPageState();
}

class _CartAndCheckoutPageState extends State<CartAndCheckoutPage> {
  // ข้อมูลรายการสินค้าในตะกร้า
  List<Map<String, dynamic>> cartItems = [
    {
      'id': 1,
      'name': 'Air Jordan 1 High OG',
      'subtitle': 'Lost & Found • 2022',
      'price': 14900,
      'size': 'US 9',
      'quantity': 1,
      'image': 'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800',
    },
    {
      'id': 2,
      'name': 'Dunk Low SP',
      'subtitle': 'Syracuse • 2020',
      'price': 9900,
      'size': 'US 8.5',
      'quantity': 1,
      'image': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800',
    },
  ];

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
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        title: const Text(
          'ตะกร้าและชำระเงิน',
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'ตะกร้า'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'คอลเลกชัน'),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  // 2. ส่วนกรอกที่อยู่จัดส่ง
  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ที่อยู่จัดส่ง',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text('ที่อยู่ใหม่',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField('ชื่อ-นามสกุลผู้รับ *', _nameController),
        const SizedBox(height: 12),
        _buildTextField('เบอร์โทรศัพท์ *', _phoneController),
        const SizedBox(height: 12),
        _buildTextField('บ้านเลขที่ / อาคาร / ถนน *', _addressController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('แขวง / ตำบล *', _subDistrictController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('เขต / อำเภอ *', _districtController)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('จังหวัด *', _provinceController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('รหัสไปรษณีย์ *', _zipController)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: isDefaultAddress,
              activeColor: const Color(0xFFFF5500),
              onChanged: (val) {
                setState(() => isDefaultAddress = val ?? true);
              },
            ),
            const Text(
              'บันทึกเป็นที่อยู่เริ่มต้น • ประเทศไทย',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        )
      ],
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
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
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
        const Text('การจัดส่ง',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        const Text('วิธีชำระเงิน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            onPressed: () {},
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