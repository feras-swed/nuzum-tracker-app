import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tracking_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobNumberController = TextEditingController();
  final _apiKeyController = TextEditingController(text: 'test_location_key_2025');
  bool _isLoading = false;

  Future<void> _startTracking() async {
    // التحقق من صحة المدخلات
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jobNumber', _jobNumberController.text);
      await prefs.setString('apiKey', _apiKeyController.text);

      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (!isRunning) {
         service.startService();
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TrackingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد التتبع'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pin_drop, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'مرحباً بك في نظام التتبع',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'يرجى إدخال بياناتك لبدء تتبع الموقع تلقائياً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _jobNumberController,
                  decoration: const InputDecoration(
                    labelText: 'الرقم الوظيفي',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الرقم الوظيفي';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'رمز المصادقة',
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  readOnly: true, // جعله غير قابل للتعديل مؤقتًا
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _startTracking,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text('بدء التتبع'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _jobNumberController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}