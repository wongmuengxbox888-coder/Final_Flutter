import 'dart:convert'; // ใช้แปลงข้อมูล JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ใช้ส่ง Request ไปยัง API
import 'profile.dart';

// URL ของ FastAPI ที่ทำงานบนเครื่องเดียวกับ Flutter Web
// ต้องแน่ใจว่า FastAPI เปิดอยู่ที่ port 8000
const String apiUrl = 'http://127.0.0.1:8000';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // เก็บข้อความที่ผู้ใช้กรอกในช่องอีเมลและรหัสผ่าน
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ใช้ควบคุมการแสดงรหัสผ่านและสถานะการโหลด
  bool hidePassword = true;
  bool isLoading = false;

  // สีส้มหลักของหน้า FOR SHOES
  final Color orange = const Color(0xFFFF5500);

  @override
  void dispose() {
    // คืนทรัพยากรเมื่อปิดหน้านี้
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันทำงานเมื่อผู้ใช้กดปุ่ม LOG IN
  Future<void> login() async {
    // อ่านค่าจากช่องกรอกข้อมูล
    final email = emailController.text.trim();
    final password = passwordController.text;

    // ตรวจสอบว่ากรอกข้อมูลครบหรือไม่
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกอีเมลและรหัสผ่าน'),
        ),
      );
      return;
    }

    // ตรวจสอบรูปแบบอีเมลเบื้องต้น
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกอีเมลให้ถูกต้อง'),
        ),
      );
      return;
    }

    // เปลี่ยนปุ่มเป็นสถานะกำลังโหลด
    setState(() {
      isLoading = true;
    });

    try {
      // ส่งอีเมลและรหัสผ่านไปให้ FastAPI ตรวจสอบ
      final response = await http
          .post(
        Uri.parse('$apiUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 15));

      // แสดงผลใน Debug Console เพื่อใช้ตรวจสอบปัญหา
      debugPrint('Login status: ${response.statusCode}');
      debugPrint('Login response: ${response.body}');

      // ตรวจสอบว่าหน้ายังเปิดอยู่หรือไม่
      if (!mounted) return;

      // HTTP 200 หมายถึง API ตอบกลับว่าสำเร็จ
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // อ่าน user_id ที่ FastAPI ส่งกลับมา
        final userId = int.tryParse(
          data['user_id'].toString(),
        );

        // ถ้า API ไม่ได้ส่ง user_id ที่ถูกต้อง ให้แจ้งข้อผิดพลาด
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบรหัสผู้ใช้จากเซิร์ฟเวอร์'),
            ),
          );
          return;
        }

        // แจ้งว่าการเข้าสู่ระบบสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เข้าสู่ระบบสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );

        // รอให้ผู้ใช้อ่านข้อความก่อนเปลี่ยนหน้า
        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) return;

        // เปิดหน้าโปรไฟล์และส่ง user_id ไปด้วย
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(userId: userId),
          ),
        );
      } else {
        // ถ้า API แจ้งข้อผิดพลาด เช่น รหัสผ่านไม่ถูกต้อง
        // พยายามอ่านข้อความ detail จาก FastAPI
        String message = 'เข้าสู่ระบบไม่สำเร็จ';

        try {
          final data = jsonDecode(response.body);
          message = data['detail']?.toString() ?? message;
        } catch (_) {
          // ใช้ข้อความเริ่มต้นหากคำตอบไม่ใช่ JSON
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // แสดงสาเหตุเมื่อเชื่อมต่อ API ไม่ได้หรือหมดเวลา
      debugPrint('LOGIN ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบ FastAPI',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // ไม่ว่าจะสำเร็จหรือผิดพลาด ให้หยุดสถานะโหลด
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. โลโก้ FOR SHOES
                Center(
                  child: Text(
                    'FOR SHOES',
                    style: TextStyle(
                      color: orange,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 55),

                // 2. หัวข้อหน้าเข้าสู่ระบบ
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Sign in to discover your next pair.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 35),

                // 3. ช่องกรอกอีเมล
                const Text(
                  'Email Address',
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                    hintText: 'Enter your email',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.white54,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 4. ช่องกรอกรหัสผ่าน
                const Text(
                  'Password',
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) {
                    // กด Enter เพื่อเข้าสู่ระบบได้
                    if (!isLoading) login();
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white54,
                    ),

                    // ปุ่มแสดงหรือซ่อนรหัสผ่าน
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),

                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 5. ลืมรหัสผ่าน (ยังไม่ได้เชื่อม API)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ระบบลืมรหัสผ่านยังไม่พร้อมใช้งาน',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: orange),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 6. ปุ่มเข้าสู่ระบบ
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    // ระหว่างโหลดจะปิดปุ่มไว้ ป้องกันส่งซ้ำ
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: orange.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    // แสดงวงกลมหมุนระหว่างรอ API
                    child: isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'LOG IN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 7. ลิงก์สมัครสมาชิก (ยังไม่ได้เชื่อม API)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.white54),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ระบบสมัครสมาชิกยังไม่พร้อมใช้งาน',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
