package com.jackwallner.sheepshead

import android.content.Context
import com.jackwallner.sheepshead.data.AlarmReminderScheduler
import com.jackwallner.sheepshead.data.AppClock
import com.jackwallner.sheepshead.data.AppSettings
import com.jackwallner.sheepshead.data.ConversionDiagnostics
import com.jackwallner.sheepshead.data.SheepsheadMinuteStore
import com.jackwallner.sheepshead.data.PracticeRecordStore
import com.jackwallner.sheepshead.data.ProgressStore
import com.jackwallner.sheepshead.data.ReviewPromptTracker
import com.jackwallner.sheepshead.data.SharedPreferencesStore
import com.jackwallner.sheepshead.data.SubscriptionService
import com.jackwallner.sheepshead.data.WhatsNewTracker
import kotlinx.coroutines.MainScope

/** Every long-lived object the screens share, built once per process. */
class AppGraph(context: Context) {
    val appContext: Context = context.applicationContext
    val scope = MainScope()
    val clock = AppClock()
    val defaults = SharedPreferencesStore(appContext)
    val settings = AppSettings(defaults, AlarmReminderScheduler(appContext))
    val progress = ProgressStore(defaults, clock)
    val records = PracticeRecordStore(defaults, clock)
    val minutes = SheepsheadMinuteStore(defaults, clock)
    val review = ReviewPromptTracker(defaults, clock)
    val diagnostics = ConversionDiagnostics(defaults, clock)
    val subscriptions = SubscriptionService(appContext, defaults, diagnostics)
    val whatsNew = WhatsNewTracker(defaults, BuildConfig.VERSION_NAME)

    /** Settings' Reset Progress: every practice stat, never onboarding or purchases. */
    fun resetProgress() {
        progress.resetAll()
        records.resetAll()
        minutes.resetAll()
    }
}
