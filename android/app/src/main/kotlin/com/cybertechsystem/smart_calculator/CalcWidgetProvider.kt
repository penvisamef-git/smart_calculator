package com.cybertechsystem.smart_calculator

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget: shows the last saved calculation.
 * Tapping it opens the app. Data is written from Dart (WidgetService).
 */
class CalcWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.calc_widget).apply {
                val title = widgetData.getString("title", null) ?: "Calculator"
                val expr = widgetData.getString("expr", null) ?: ""
                val result = widgetData.getString("result", null) ?: "0"
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_expr, expr)
                setTextViewText(R.id.widget_result, result)
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
