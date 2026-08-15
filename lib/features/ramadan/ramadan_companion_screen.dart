import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/prayer_models.dart';
import '../../core/services/hijri_date.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';

/// Ramadan companion: suhoor (pre-dawn meal) end / iftar (fast-breaking)
/// countdown built from the same real prayer-time data already used
/// elsewhere (Fajr = suhoor cutoff, Maghrib = iftar), plus a simple
/// daily fasting tracker. Works for voluntary fasting outside Ramadan
/// too — it just tracks whichever day the user marks.
class RamadanCompanionScreen extends StatefulWidget {
  const RamadanCompanionScreen({super.key});

  @override
  State<RamadanCompanionScreen> createState() => _RamadanCompanionScreenState();
}

class _RamadanCompanionScreenState extends State<RamadanCompanionScreen> {
  PrayerTimesResult? _prayer;
  bool _loading = true;
  bool _error = false;
  Timer? _timer;
  String _countdownLabel = '';
  String _countdown = '--:--:--';
  bool _fastingToday = false;
  int _ramadanDaysLogged = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadFastingState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await PrayerService.fetchUsingSavedPreference();
      setState(() {
        _prayer = result;
        _loading = false;
      });
      _startCountdown();
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _loadFastingState() async {
    final fasted = await UserProgressService.isFastingToday();
    final now = DateTime.now();
    final hijri = HijriDate.fromGregorian(now);
    int loggedCount = 0;
    if (hijri.isRamadan) {
      // Count fasting days from the 1st of this Hijri month to today, by
      // walking back through the Gregorian calendar until the Hijri
      // month/day no longer matches — avoids needing a full Hijri-to-
      // Gregorian range converter for just this display purpose.
      var cursor = now;
      var daysBack = 0;
      while (daysBack < 30) {
        final h = HijriDate.fromGregorian(cursor);
        if (!h.isRamadan) break;
        cursor = cursor.subtract(const Duration(days: 1));
        daysBack++;
      }
      final startOfMonth = now.subtract(Duration(days: daysBack - 1));
      loggedCount = await UserProgressService.fastingDaysInRange(startOfMonth, now);
    }
    if (mounted) {
      setState(() {
        _fastingToday = fasted;
        _ramadanDaysLogged = loggedCount;
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    final result = _prayer;
    if (result == null) return;

    final now = DateTime.now();
    final fajr = result.prayers.firstWhere((p) => p.name == 'الفجر');
    final maghrib = result.prayers.firstWhere((p) => p.name == 'المغرب');

    DateTime target;
    String label;

    if (now.isBefore(fajr.dateTime)) {
      target = fajr.dateTime;
      label = 'الوقت المتبقي على السحور (أذان الفجر)';
    } else if (now.isBefore(maghrib.dateTime)) {
      target = maghrib.dateTime;
      label = 'الوقت المتبقي على الإفطار (أذان المغرب)';
    } else {
      target = fajr.dateTime.add(const Duration(days: 1));
      label = 'الوقت المتبقي على السحور غدًا';
    }

    final diff = target.difference(now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');

    if (mounted) {
      setState(() {
        _countdown = '$h:$m:$s';
        _countdownLabel = label;
      });
    }
  }

  Future<void> _toggleFasting() async {
    final next = !_fastingToday;
    setState(() => _fastingToday = next);
    await UserProgressService.setFastingToday(next);
    _loadFastingState();
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriDate.fromGregorian(DateTime.now());
    final isRamadan = hijri.isRamadan;

    return Scaffold(
      appBar: AppBar(title: const Text('رفيق رمضان'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل مواقيت الصلاة اللازمة للسحور والإفطار.', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      isRamadan ? 'اليوم ${hijri.day} من رمضان' : hijri.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primaryEmerald, Color(0xFF115E56)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Text(_countdownLabel, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 10),
                          Text(_countdown, style: const TextStyle(color: AppColors.goldAccent, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: SwitchListTile(
                        title: const Text('صائم اليوم'),
                        subtitle: const Text('سجّل صيامك اليوم لمتابعة تقدمك'),
                        value: _fastingToday,
                        activeTrackColor: AppColors.primaryEmerald,
                        onChanged: (_) => _toggleFasting(),
                      ),
                    ),
                    if (isRamadan) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_month, color: AppColors.primaryEmerald),
                          title: const Text('أيام الصيام المسجّلة هذا الشهر'),
                          trailing: Text('$_ramadanDaysLogged', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'ملاحظة: التاريخ الهجري هنا تقديري حسابي وقد يختلف يومًا واحدًا عن الإعلان الرسمي لبداية الشهر في بلدك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                    ),
                  ],
                ),
    );
  }
}
