import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../models/prayer_models.dart';
import 'notification_service.dart';
import 'prayer_display.dart';
import 'prayer_service.dart';
import 'settings_service.dart';

/// Wires [PrayerTimesResult] + user settings + localized strings into
/// scheduled OS notifications. Kept separate from [NotificationService]
/// (which knows nothing about prayers or locales) and from
/// [PrayerService] (which knows nothing about notifications) so each
/// piece stays independently testable.
class PrayerNotificationScheduler {
  PrayerNotificationScheduler._();

  /// Stable per-prayer-per-day notification ID. Bounded well within
  /// 32-bit range: days since 2020-01-01 (~29,000 for the next ~80
  /// years) * 10 + prayer index (0-4).
  static int _idFor(DateTime date, int prayerIndex) {
    final epoch = DateTime(2020, 1, 1);
    final days = DateTime(date.year, date.month, date.day).difference(epoch).inDays;
    return days * 10 + prayerIndex;
  }

  /// Schedules reminders for every remaining prayer today, plus all of
  /// tomorrow's (fetched opportunistically so reminders keep firing even
  /// if the app isn't reopened tomorrow morning specifically — though
  /// see [NotificationService]'s docs for the reboot caveat). Does
  /// nothing (and clears any previously-scheduled reminders) if the
  /// user has reminders turned off in Settings.
  static Future<void> rescheduleFromResult(BuildContext context, PrayerTimesResult result) async {
    if (!appSettings.prayerReminderEnabled || appSettings.prayerReminderMode == 'off') {
      await NotificationService.cancelAllScheduled();
      return;
    }

    final l10n = AppLocalizations.of(context);
    final minutesBefore = appSettings.prayerReminderMinutesBefore;
    final notifications = <ScheduledPrayerNotification>[];

    void addFor(List<PrayerItem> prayers, DateTime date) {
      for (var i = 0; i < prayers.length; i++) {
        final prayer = prayers[i];
        final fireAt = prayer.dateTime.subtract(Duration(minutes: minutesBefore));
        final displayName = prayerDisplayName(l10n, prayer.name);
        notifications.add(ScheduledPrayerNotification(
          id: _idFor(date, i),
          fireAt: fireAt,
          title: l10n.appTitle,
          body: l10n.prayerReminderApproaching(displayName, minutesBefore),
        ));
      }
    }

    final today = DateTime.now();
    addFor(result.prayers, today);

    final tomorrowPrayers = await PrayerService.fetchTomorrowPrayers();
    if (tomorrowPrayers != null) {
      addFor(tomorrowPrayers, today.add(const Duration(days: 1)));
    }

    await NotificationService.scheduleAll(notifications);
  }
}
