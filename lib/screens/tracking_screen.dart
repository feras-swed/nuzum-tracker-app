import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String _deviceStatus = 'جاري التحميل...';
  String _lastUpdate = 'لم يتم الإرسال بعد';
  String _jobNumber = '';

  @override
  void initState() {
    super.initState();
    _loadJobNumber();
    _listenToService();
  }

  void _loadJobNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jobNumber = prefs.getString('jobNumber') ?? 'غير معروف';
    });
  }

  void _listenToService() {
    final service = FlutterBackgroundService();
    service.on('update').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _deviceStatus = event['status'] ?? _deviceStatus;
          _lastUpdate = event['lastUpdate'] ?? _lastUpdate;
        });
      }
    });
  }
  
  Future<void> _stopTracking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إيقاف التتبع'),
        content: const Text('هل أنت متأكد من رغبتك في إيقاف خدمة التتبع وحذف البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SetupScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة التتبع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
            onPressed: _stopTracking,
            tooltip: 'إيقاف التتبع',
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 120, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'التتبع نشط',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'للموظف: $_jobNumber',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _buildInfoCard('حالة الخدمة', _deviceStatus, Icons.sync),
              const SizedBox(height: 16),
              _buildInfoCard('آخر تحديث', _lastUpdate, Icons.timer),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )
          ],
        ),
      ),
    );
  }
}