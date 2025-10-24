package com.example.tactical_launcher

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class QuickActionWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.quick_action_widget)

            // Setup terminal button
            val terminalIntent = Intent(context, MainActivity::class.java).apply {
                putExtra("command", "")
            }
            val terminalPendingIntent = PendingIntent.getActivity(
                context, 0, terminalIntent, PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_terminal, terminalPendingIntent)

            // Setup apps button
            val appsIntent = Intent(context, MainActivity::class.java).apply {
                putExtra("command", "apps")
            }
            val appsPendingIntent = PendingIntent.getActivity(
                context, 1, appsIntent, PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_apps, appsPendingIntent)

            // Setup status button
            val statusIntent = Intent(context, MainActivity::class.java).apply {
                putExtra("command", "status")
            }
            val statusPendingIntent = PendingIntent.getActivity(
                context, 2, statusIntent, PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_status, statusPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}