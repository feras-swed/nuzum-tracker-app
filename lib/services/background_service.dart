import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart'; // <<<--- المكتبة الجديدة
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nuzum_tracker/services/api_service.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- أضف هذا الاستيراد
import 'dart:io'; // <-- استيراد ضروري لتجاوز HTTP

// -----------------------------------------------------------------------------
// تهيئة الخدمة
// -----------------------------------------------------------------------------
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'nuzum_tracker_foreground',
      initialNotificationTitle: 'Nuzum Tracker',
      initialNotificationContent: 'خدمة التتبع نشطة',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// -----------------------------------------------------------------------------
// نقطة الدخول الخاصة بأنظمة iOS
// -----------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// -----------------------------------------------------------------------------
// نقطة الدخول الرئيسية ومنطق الخدمة الخلفية
// -----------------------------------------------------------------------------
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  await initializeDateFormatting('ar', null);
  HttpOverrides.global = MyHttpOverrides();
  
  Timer? timer;

  Future<void> performLocationUpdate() async {
    try {
        // --- ⬇️⬇️ بداية الكود الجديد باستخدام Geolocator ⬇️⬇️ ---
        
        // 1. التحقق من أن خدمة الموقع (GPS) مفعلة على الجهاز
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
            print("❌ [BG Service] Location services are disabled.");
            service.invoke('update', {'lastUpdate': 'خطأ: الرجاء تفعيل خدمة الموقع (GPS)'});
            return;
        }

        // 2. التحقق من أذونات الموقع
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
            print("❌ [BG Service] Location permissions are denied.");
            service.invoke('update', {'lastUpdate': 'خطأ: إذن الوصول للموقع مرفوض'});
            // ملاحظة: لا يمكننا طلب الإذن من الخلفية. يجب على المستخدم منحه يدويًا.
            return;
        }
        
        if (permission == LocationPermission.deniedForever) {
            print("❌ [BG Service] Location permissions are permanently denied.");
            service.invoke('update', {'lastUpdate': 'خطأ: تم رفض إذن الموقع بشكل دائم'});
            return;
        } 

        // 3. إذا كانت الأذونات ممنوحة والخدمة تعمل، احصل على الموقع الحالي
        print("🌍 [BG Service] Permissions are OK. Getting current position...");
        final Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium
        );
        
        // --- ⬆️⬆️ نهاية الكود الجديد باستخدام Geolocator ⬆️⬆️ ---

        final prefs = await SharedPreferences.getInstance();
        final jobNumber = prefs.getString('jobNumber');
        final apiKey = prefs.getString('apiKey');
        
        if (jobNumber == null || apiKey == null) {
          timer?.cancel();
          service.stopSelf();
          return;
        }
        
        print('🛰️ [BG Service] Got location: Lat ${position.latitude}, Lng ${position.longitude}');
        
        // 4. إرسال الموقع إلى السيرفر
        final bool success = await ApiService.sendLocation(
            apiKey: apiKey,
            jobNumber: jobNumber,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
        );
        
        final now = DateFormat('hh:mm a', 'ar').format(DateTime.now());
        if (success) {
            service.invoke('update', {'lastUpdate': 'آخر إرسال ناجح: $now'});
        } else {
            service.invoke('update', {'lastUpdate': 'فشل الإرسال الأخير: $now'});
        }

    } catch(e) {
        print('🔥 [BG Service] An unexpected error occurred: $e');
        service.invoke('update', {'lastUpdate': 'حدث خطأ غير متوقع'});
    }
  }

  // ضبط المؤقت للعمل كل دقيقة واحدة (لأغراض الاختبار)
  timer = Timer.periodic(const Duration(minutes: 1), (timerInstance) async {
      print("---------------------[ Timer Tick ]---------------------");
      await performLocationUpdate();
  });

  // تشغيل فوري عند بدء الخدمة لأول مرة
  print("------------------[ Service Started ]------------------");
  await performLocationUpdate();
  
  service.on('stopService').listen((event) {
    print("------------------[ Stopping Service ]-----------------");
    timer?.cancel(); 
    service.stopSelf(); 
  });

  service.invoke('update', {'status': 'الخدمة تعمل في الخلفية'});
}