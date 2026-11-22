package com.jackwallner.sheepshead.ui

import androidx.activity.ComponentActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver

/** Runs `action` when the screen appears and each time the app returns to the foreground (for example from system settings). */
@Composable
fun OnResume(action: () -> Unit) {
    val context = LocalContext.current
    val latest = rememberUpdatedState(action)
    DisposableEffect(context) {
        val lifecycle = (context.findActivity() as? ComponentActivity)?.lifecycle
        // Added while resumed, so the observer's first ON_RESUME is the appearance itself.
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) latest.value()
        }
        lifecycle?.addObserver(observer)
        onDispose { lifecycle?.removeObserver(observer) }
    }
}
