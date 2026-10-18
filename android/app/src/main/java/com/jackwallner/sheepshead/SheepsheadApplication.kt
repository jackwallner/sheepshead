package com.jackwallner.sheepshead

import android.app.Application

class SheepsheadApplication : Application() {
    lateinit var graph: AppGraph
        private set

    override fun onCreate() {
        super.onCreate()
        graph = AppGraph(this)
    }
}
