import 'package:flutter/material.dart';

void main() {
  runApp(const ClinicApp());
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctors Appointment',
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
      home: const MainNavigationPage(),
    );
  }
}

/// Dynamic Data Models
class Doctor {
  final String name;
  final String specialty;
  final String rating;
  final String fee;
  final String imageUrl;
  final List<String> availableSlots;

  Doctor({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.fee,
    required this.imageUrl,
    required this.availableSlots,
  });
}

class Appointment {
  final String id;
  final Doctor doctor;
  final String patientName;
  final String date;
  final String time;
  String status; // 'Pending', 'Completed', 'Cancelled'

  Appointment({
    required this.id,
    required this.doctor,
    required this.patientName,
    required this.date,
    required this.time,
    this.status = 'Pending',
  });
}

/// Global In-Memory Database / State Manager
class AppDatabase {
  static final List<Doctor> doctors = [
    Doctor(
      name: 'Dr. Sarah Connor',
      specialty: 'Cardiologist',
      rating: '4.9',
      fee: '\$150',
      imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=200',
      availableSlots: ['09:00 AM', '10:30 AM', '02:00 PM', '04:30 PM'],
    ),
    Doctor(
      name: 'Dr. Marcus Aurelius',
      specialty: 'Neurologist',
      rating: '4.8',
      fee: '\$180',
      imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=200',
      availableSlots: ['08:30 AM', '11:00 AM', '01:30 PM', '03:00 PM'],
    ),
    Doctor(
      name: 'Dr. Elizabeth Blackwell',
      specialty: 'Pediatrician',
      rating: '5.0',
      fee: '\$120',
      imageUrl: 'https://images.unsplash.com/photo-1594824813573-246434de83fb?auto=format&fit=crop&q=80&w=200',
      availableSlots: ['09:30 AM', '10:00 AM', '11:30 AM', '03:30 PM'],
    ),
    Doctor(
      name: 'Dr. Albert Schweitzer',
      specialty: 'General Physician',
      rating: '4.7',
      fee: '\$90',
      imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=200',
      availableSlots: ['10:00 AM', '12:00 PM', '02:30 PM', '04:00 PM'],
    ),
  ];

  static final List<Appointment> appointments = _initAppointments();

  static List<Appointment> _initAppointments() {
    return [
      Appointment(
        id: 'APT-1001',
        doctor: doctors[0],
        patientName: 'John Doe',
        date: '2026-08-15',
        time: '10:30 AM',
        status: 'Pending',
      ),
      Appointment(
        id: 'APT-1002',
        doctor: doctors[2],
        patientName: 'Jane Watson',
        date: '2026-08-16',
        time: '11:30 AM',
        status: 'Completed',
      ),
    ];
  }
}

/// Navigation Hub controlling active screens and logged in users
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  bool _isLoggedIn = false;
  String _userRole = 'Patient'; // 'Patient' or 'Doctor'
  String _loggedInName = 'Guest';

  void _login(String email, String role) {
    setState(() {
      _isLoggedIn = true;
      _userRole = role;
      _loggedInName = role == 'Doctor' ? 'Dr. Sarah Connor' : email.split('@')[0];
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginPage(onLogin: _login);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userRole == 'Doctor' ? 'Doctor Dashboard' : 'Clinic Appointment Scheduler',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F52BA),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                'Hi, $_loggedInName',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _userRole == 'Doctor'
          ? const DoctorDashboardPage()
          : PatientDashboardPage(patientName: _loggedInName),
    );
  }
}

/// Completely Functional Login Form utilizing CustomPainter Medical Logo
class LoginPage extends StatefulWidget {
  final Function(String email, String role) onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String _selectedRole = 'Patient'; // Default Role Selection

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
      backgroundColor: const Color(0xFFF5F8FC),
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
                    color: Colors.black.withAlpha(15),
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
                      // Medical Stethoscope, Calendar & Cross Logo using native CustomPainter
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withAlpha(13),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: CustomPaint(
                          size: const Size(100, 100),
                          painter: MedicalLogoPainter(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Doctors Appointment',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B2C5F),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to book or manage appointments',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // User Role Selector segment
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Patient')),
                                selected: _selectedRole == 'Patient',
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedRole = 'Patient');
                                },
                                backgroundColor: Colors.transparent,
                                selectedColor: Colors.white,
                                showCheckmark: false,
                                side: BorderSide.none,
                              ),
                            ),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Doctor')),
                                selected: _selectedRole == 'Doctor',
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedRole = 'Doctor');
                                },
                                backgroundColor: Colors.transparent,
                                selectedColor: Colors.white,
                                showCheckmark: false,
                                side: BorderSide.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Login Hint Boxes to ease evaluation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _emailController.text = 'patient@clinic.com';
                              _passwordController.text = 'password123';
                              setState(() => _selectedRole = 'Patient');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Patient Demo', style: TextStyle(fontSize: 11, color: Color(0xFF0F52BA))),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _emailController.text = 'doctor@clinic.com';
                              _passwordController.text = 'doctor123';
                              setState(() => _selectedRole = 'Doctor');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Doctor Demo', style: TextStyle(fontSize: 11, color: Color(0xFF0A2540))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

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
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

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
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
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
                      const SizedBox(height: 24),

                      // Sign In Button (Fully Functional Navigation Trigger)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F52BA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onLogin(_emailController.text, _selectedRole);
                            }
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
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

/// Patients Interface: Interactive Search, Detailed view, and Dynamic Slot Booking
class PatientDashboardPage extends StatefulWidget {
  final String patientName;
  const PatientDashboardPage({super.key, required this.patientName});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  List<Doctor> _filteredDoctors = AppDatabase.doctors;

  void _filterDoctors(String query) {
    setState(() {
      _filteredDoctors = AppDatabase.doctors
          .where((doc) =>
              doc.name.toLowerCase().contains(query.toLowerCase()) ||
              doc.specialty.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _bookAppointment(Doctor doctor, String date, String slot) {
    setState(() {
      AppDatabase.appointments.add(
        Appointment(
          id: 'APT-${1000 + AppDatabase.appointments.length + 1}',
          doctor: doctor,
          patientName: widget.patientName,
          date: date,
          time: slot,
          status: 'Pending',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully Booked Appointment with ${doctor.name}!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelAppointment(String id) {
    setState(() {
      AppDatabase.appointments.firstWhere((apt) => apt.id == id).status = 'Cancelled';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment Cancelled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Scheduled Appointments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2C5F)),
          ),
          const SizedBox(height: 8),
          AppDatabase.appointments.where((apt) => apt.patientName == widget.patientName).isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No active appointments booked yet.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: AppDatabase.appointments.where((apt) => apt.patientName == widget.patientName).length,
                  itemBuilder: (context, index) {
                    final apt = AppDatabase.appointments
                        .where((a) => a.patientName == widget.patientName)
                        .toList()[index];
                    Color statusColor = Colors.orange;
                    if (apt.status == 'Completed') statusColor = Colors.green;
                    if (apt.status == 'Cancelled') statusColor = Colors.red;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(apt.doctor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${apt.doctor.specialty} • ${apt.date} at ${apt.time}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                apt.status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            if (apt.status == 'Pending') ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _cancelAppointment(apt.id),
                                tooltip: 'Cancel Booking',
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),
          const Text(
            'Find and Book a Doctor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2C5F)),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: _filterDoctors,
            decoration: InputDecoration(
              hintText: 'Search by Doctor name or specialty...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredDoctors.length,
            itemBuilder: (context, index) {
              final doc = _filteredDoctors[index];
              return Card(
                elevation: 1.5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(doc.imageUrl),
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(doc.specialty, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(doc.rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 12),
                                Text('Fee: ${doc.fee}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F52BA))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F52BA),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _showBookingSheet(context, doc);
                        },
                        child: const Text('Book'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(BuildContext context, Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String selectedDate = '2026-08-15';
        String selectedSlot = doctor.availableSlots[0];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book appointment with ${doctor.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedDate,
                    items: ['2026-08-15', '2026-08-16', '2026-08-17', '2026-08-18'].map((date) {
                      return DropdownMenuItem(value: date, child: Text(date));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedDate = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Available Time Slot', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: doctor.availableSlots.map((slot) {
                      final isSelected = selectedSlot == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setModalState(() => selectedSlot = slot);
                        },
                        selectedColor: const Color(0xFF0F52BA),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F52BA),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _bookAppointment(doctor, selectedDate, selectedSlot);
                        Navigator.pop(context);
                      },
                      child: const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Doctor Dashboard: View, complete, or cancel appointments
class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  void _changeStatus(String id, String newStatus) {
    setState(() {
      AppDatabase.appointments.firstWhere((apt) => apt.id == id).status = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment updated to $newStatus.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = AppDatabase.appointments.where((a) => a.status == 'Pending').length;
    final completedCount = AppDatabase.appointments.where((a) => a.status == 'Completed').length;
    final cancelledCount = AppDatabase.appointments.where((a) => a.status == 'Cancelled').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Pending', pendingCount.toString(), Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Completed', completedCount.toString(), Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Cancelled', cancelledCount.toString(), Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Patient Bookings List',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2C5F)),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppDatabase.appointments.length,
            itemBuilder: (context, index) {
              final apt = AppDatabase.appointments[index];
              Color statusColor = Colors.orange;
              if (apt.status == 'Completed') statusColor = Colors.green;
              if (apt.status == 'Cancelled') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            apt.patientName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              apt.status,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Schedule: ${apt.date} at ${apt.time}'),
                      Text('Assigned Doctor: ${apt.doctor.name}'),
                      if (apt.status == 'Pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _changeStatus(apt.id, 'Cancelled'),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _changeStatus(apt.id, 'Completed'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              icon: const Icon(Icons.check),
                              label: const Text('Complete'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
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
