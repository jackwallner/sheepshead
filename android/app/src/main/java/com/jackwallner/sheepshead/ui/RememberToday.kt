package com.jackwallner.sheepshead.ui

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.activity.ComponentActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.jackwallner.sheepshead.data.AppClock
import java.time.LocalDate

/**
 * The calendar day Home is drawn for. Nothing else redraws Home across a day
 * boundary, so a player returning the next morning (a reminder tap) was told
 * yesterday's Get Started was done and shown a streak they had lost. It
 * refreshes when the app comes back to the foreground and when the date, the
 * time or the time zone changes while it is open.
 */
@Composable
fun rememberToday(clock: AppClock): LocalDate {
    val context = LocalContext.current
    var today by remember { mutableStateOf(clock.today()) }
    DisposableEffect(context, clock) {
        today = clock.today()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                today = clock.today()
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_DATE_CHANGED)
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
        }
        ContextCompat.registerReceiver(context, receiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
        val lifecycle = (context.findActivity() as? ComponentActivity)?.lifecycle
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) today = clock.today()
        }
        lifecycle?.addObserver(observer)
        onDispose {
            context.unregisterReceiver(receiver)
            lifecycle?.removeObserver(observer)
        }
    }
    return today
}
