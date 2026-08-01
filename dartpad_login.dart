import 'package:flutter/material.dart';

void main() {
  runApp(const ClinicApp());
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctors Appointment Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F52BA), // Beautiful Medical Sapphire/Blue
          primary: const Color(0xFF0F52BA),
          secondary: const Color(0xFF2A82E4),
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Controllers to access entered text
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC), // Cool professional light blue/grey background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Beautiful Native Custom Drawn Stethoscope, Calendar & Medical Cross Logo
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: MedicalLogoPainter(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Heading Style
                      const Text(
                        'Doctors Appointment',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B2C5F),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome Back! Please login to your account',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'name@example.com',
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0F52BA)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF0F52BA), width: 2),
                          ),
                          labelStyle: const TextStyle(color: Color(0xFF5E6E85)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          // Simple regex validation
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF0F52BA)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF5E6E85),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF0F52BA), width: 2),
                          ),
                          labelStyle: const TextStyle(color: Color(0xFF5E6E85)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: true,
                                  onChanged: (bool? val) {},
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5E6E85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Just UI decoration, no actual business logic/action
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F52BA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F52BA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            // Run UI validation without performing any actual backend login action/navigation
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Validation Successful (No functionality)!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF2E7D32),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5E6E85),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Just UI decoration
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F52BA),
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
          ),
        ),
      ),
    );
  }
}

/// A clean, high-performance, and lightweight vector CustomPainter
/// that renders the medical Doctors Appointment logo natively.
class MedicalLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paints
    final Paint darkBluePaint = Paint()
      ..color = const Color(0xFF0A2540)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final Paint darkBlueFill = Paint()
      ..color = const Color(0xFF0A2540)
      ..style = PaintingStyle.fill;

    final Paint lightBlueFill = Paint()
      ..color = const Color(0xFF2A82E4)
      ..style = PaintingStyle.fill;

    final Paint medicalCrossBlueFill = Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.fill;

    final Paint gridPointPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;

    // 1. Draw Calendar Body (at the center-top right)
    final RRect calendarCard = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.16, w * 0.48, h * 0.44),
      const Radius.circular(10),
    );

    // Draw outer calendar card stroke
    canvas.drawRRect(calendarCard, Paint()
      ..color = const Color(0xFF0F52BA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5);

    // Header of calendar
    final RRect calendarHeader = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.16, w * 0.48, h * 0.14),
      const Radius.circular(10),
    );
    canvas.drawRRect(calendarHeader, Paint()..color = const Color(0xFF0F52BA));

    // Calendar Rings/Holes
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.46, h * 0.10, w * 0.05, h * 0.11), const Radius.circular(3)),
      darkBlueFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.74, h * 0.10, w * 0.05, h * 0.11), const Radius.circular(3)),
      darkBlueFill,
    );

    // Calendar Grid Points
    final double gridY1 = h * 0.36;
    final double gridY2 = h * 0.44;
    final double gridY3 = h * 0.52;
    final double col1 = w * 0.44;
    final double col2 = w * 0.52;
    final double col3 = w * 0.60;
    final double col4 = w * 0.68;
    final double col5 = w * 0.76;

    final double dotSize = w * 0.05;

    // Row 1
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col1, gridY1, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col2, gridY1, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col3, gridY1, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col4, gridY1, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col5, gridY1, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);

    // Row 2
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col1, gridY2, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col2, gridY2, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    // Blue Checked date (matches original image checked blue box at the middle)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(col3, gridY2, dotSize, dotSize), const Radius.circular(2)),
      Paint()..color = const Color(0xFF0F52BA),
    );
    // Draw white checkmark inside the checked box
    final Paint checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final Path checkPath = Path()
      ..moveTo(col3 + dotSize * 0.25, gridY2 + dotSize * 0.5)
      ..lineTo(col3 + dotSize * 0.45, gridY2 + dotSize * 0.75)
      ..lineTo(col3 + dotSize * 0.8, gridY2 + dotSize * 0.25);
    canvas.drawPath(checkPath, checkPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col4, gridY2, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col5, gridY2, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);

    // Row 3
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col1, gridY3, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col2, gridY3, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col3, gridY3, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col4, gridY3, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(col5, gridY3, dotSize, dotSize), const Radius.circular(1.5)), gridPointPaint);

    // 2. Draw Stethoscope (wrapping calendar in a circular swoop)
    final Path stethoscopeSwoop = Path();
    // Starting on left side representing the binaural (headset)
    stethoscopeSwoop.moveTo(w * 0.20, h * 0.30);
    stethoscopeSwoop.cubicTo(
      w * 0.12, h * 0.46, // control point 1
      w * 0.16, h * 0.74, // control point 2
      w * 0.46, h * 0.76, // lowest base of swoop
    );
    // swoop right and up to the bell/diaphragm on the calendar's right
    stethoscopeSwoop.cubicTo(
      w * 0.70, h * 0.78,
      w * 0.82, h * 0.64,
      w * 0.78, h * 0.48,
    );
    canvas.drawPath(stethoscopeSwoop, darkBluePaint);

    // Stethoscope Ear Tubes (binaural arch)
    final Path earTubes = Path();
    earTubes.moveTo(w * 0.20, h * 0.30);
    earTubes.quadraticBezierTo(w * 0.22, h * 0.20, w * 0.28, h * 0.22);
    earTubes.moveTo(w * 0.20, h * 0.30);
    earTubes.quadraticBezierTo(w * 0.26, h * 0.40, w * 0.34, h * 0.36);
    canvas.drawPath(earTubes, Paint()
      ..color = const Color(0xFF0A2540)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5);

    // Earpieces (tips)
    canvas.drawCircle(Offset(w * 0.28, h * 0.22), 4, darkBlueFill);
    canvas.drawCircle(Offset(w * 0.34, h * 0.36), 4, darkBlueFill);

    // Stethoscope Chestpiece (Bell & Diaphragm)
    final Offset chestpieceCenter = Offset(w * 0.78, h * 0.46);
    canvas.drawCircle(chestpieceCenter, 10, darkBlueFill);
    canvas.drawCircle(chestpieceCenter, 6, lightBlueFill);
    canvas.drawCircle(chestpieceCenter, 3, Paint()..color = Colors.white);

    // 3. Draw Medical Cross Badge (at the center bottom overlap)
    final Offset crossCenter = Offset(w * 0.50, h * 0.74);
    canvas.drawCircle(crossCenter, 16, Paint()..color = Colors.white); // Outer shadow ring helper
    canvas.drawCircle(crossCenter, 14, medicalCrossBlueFill);

    // The white plus symbol in the center
    final Paint whiteCrossPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Vertical bar of the cross
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: crossCenter, width: 6, height: 16),
        const Radius.circular(1.5),
      ),
      whiteCrossPaint,
    );
    // Horizontal bar of the cross
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: crossCenter, width: 16, height: 6),
        const Radius.circular(1.5),
      ),
      whiteCrossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
