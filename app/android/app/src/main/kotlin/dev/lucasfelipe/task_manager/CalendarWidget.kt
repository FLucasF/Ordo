package dev.lucasfelipe.task_manager

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.TemporalAdjusters

/**
 * The home-screen calendar: a day, a week or a month, picked on the widget itself (each widget keeps
 * its own), with ‹ › to move and "+" to create. The app writes what it shows to
 * files/calendar_widget.json (lib/platform/calendar_home_widget.dart); a tap opens the app on that day.
 */
class CalendarWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) draw(context, manager, id)
        scheduleMidnight(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        draw(context, manager, id)
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        val prefs = prefs(context).edit()
        for (id in ids) prefs.remove("mode_$id").remove("offset_$id")
        prefs.apply()
    }

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        when (intent.action) {
            ACTION_MODE -> {
                prefs(context).edit().putString("mode_$id", intent.getStringExtra(EXTRA_MODE)).putInt("offset_$id", 0).apply()
                draw(context, AppWidgetManager.getInstance(context), id)
            }
            ACTION_SHIFT -> {
                val delta = intent.getIntExtra(EXTRA_DELTA, 0)
                val prefs = prefs(context)
                val offset = if (delta == 0) 0 else prefs.getInt("offset_$id", 0) + delta
                prefs.edit().putInt("offset_$id", offset).apply()
                draw(context, AppWidgetManager.getInstance(context), id)
            }
            ACTION_MIDNIGHT -> updateAll(context)
            else -> super.onReceive(context, intent)
        }
    }

    companion object {
        private const val ACTION_MODE = "dev.lucasfelipe.task_manager.widget.MODE"
        private const val ACTION_SHIFT = "dev.lucasfelipe.task_manager.widget.SHIFT"
        private const val ACTION_MIDNIGHT = "dev.lucasfelipe.task_manager.widget.MIDNIGHT"
        private const val EXTRA_MODE = "mode"
        private const val EXTRA_DELTA = "delta"

        /** Extra of the app's launch intent: "open|2026-10-05|d" or "create|2026-10-05|d". */
        const val EXTRA_ACTION = "tarefas.widget.action"

        private fun prefs(context: Context) = context.getSharedPreferences("calendar_widget", Context.MODE_PRIVATE)

        /** Redraws every calendar widget on the home screen (the app calls it after writing the data). */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for (id in manager.getAppWidgetIds(ComponentName(context, CalendarWidget::class.java))) draw(context, manager, id)
            scheduleMidnight(context)
        }

        /** "Today" moves at midnight: a broadcast then (inexact is fine, no permission needed). */
        private fun scheduleMidnight(context: Context) {
            val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val next = LocalDate.now().plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli() + 60_000
            val intent = Intent(context, CalendarWidget::class.java).setAction(ACTION_MIDNIGHT)
            val pending = PendingIntent.getBroadcast(context, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            alarm.set(AlarmManager.RTC, next, pending)
        }

        private class Data(json: JSONObject?) {
            val labels: JSONObject = json?.optJSONObject("labels") ?: JSONObject()
            val days: JSONObject = json?.optJSONObject("days") ?: JSONObject()
            val firstWeekday: Int = json?.optInt("firstWeekday", 7) ?: 7

            fun label(key: String, fallback: String) = labels.optString(key, fallback)
            fun month(m: Int) = (labels.optJSONArray("months")?.optString(m - 1) ?: m.toString()).replaceFirstChar { it.uppercase() }
            fun weekday(d: DayOfWeek) = labels.optJSONArray("weekdays")?.optString(d.value - 1) ?: d.name.take(3)
            fun entries(day: LocalDate): JSONArray = days.optJSONArray(day.toString()) ?: JSONArray()
        }

        private fun read(context: Context): Data = try {
            Data(JSONObject(File(context.filesDir, "calendar_widget.json").readText()))
        } catch (e: Exception) {
            Data(null)
        }

        private fun draw(context: Context, manager: AppWidgetManager, id: Int) {
            val data = read(context)
            val prefs = prefs(context)
            val mode = prefs.getString("mode_$id", "m") ?: "m"
            val offset = prefs.getInt("offset_$id", 0)
            val today = LocalDate.now()
            val options = manager.getAppWidgetOptions(id)
            // Portrait height, in dp, as the launcher gives it.
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 300).coerceAtLeast(110)

            val views = RemoteViews(context.packageName, R.layout.widget_calendar)
            views.removeAllViews(R.id.widget_body)
            views.removeAllViews(R.id.widget_weekdays)

            // Dia, Semana, Mês: the chosen one on a soft blue pill.
            for ((key, viewId, label) in listOf(
                Triple("d", R.id.widget_mode_d, data.label("day", "Dia")),
                Triple("w", R.id.widget_mode_w, data.label("week", "Semana")),
                Triple("m", R.id.widget_mode_m, data.label("month", "Mês")),
            )) {
                views.setTextViewText(viewId, label)
                views.setInt(viewId, "setBackgroundResource", if (key == mode) R.drawable.widget_pill_on else 0)
                views.setOnClickPendingIntent(viewId, broadcast(context, id, ACTION_MODE, key.hashCode()) { it.putExtra(EXTRA_MODE, key) })
            }
            views.setOnClickPendingIntent(R.id.widget_prev, broadcast(context, id, ACTION_SHIFT, 1) { it.putExtra(EXTRA_DELTA, -1) })
            views.setOnClickPendingIntent(R.id.widget_next, broadcast(context, id, ACTION_SHIFT, 2) { it.putExtra(EXTRA_DELTA, 1) })
            // The title brings it back to today.
            views.setOnClickPendingIntent(R.id.widget_title, broadcast(context, id, ACTION_SHIFT, 3) { it.putExtra(EXTRA_DELTA, 0) })

            // Room left for the days: the header and the mode pills take about 80dp.
            val body = height - 92
            when (mode) {
                "d" -> drawDay(context, views, data, today.plusDays(offset.toLong()), today, id, body)
                "w" -> drawWeek(context, views, data, weekStart(today, data).plusWeeks(offset.toLong()), today, id, body)
                else -> drawMonth(context, views, data, today.withDayOfMonth(1).plusMonths(offset.toLong()), today, id, body)
            }
            manager.updateAppWidget(id, views)
        }

        private fun weekStart(day: LocalDate, data: Data): LocalDate =
            day.with(TemporalAdjusters.previousOrSame(DayOfWeek.of(data.firstWeekday)))

        private fun weekdayHeader(context: Context, views: RemoteViews, data: Data, start: LocalDate) {
            for (i in 0 until 7) {
                val cell = RemoteViews(context.packageName, R.layout.widget_weekday)
                cell.setTextViewText(R.id.widget_weekday, data.weekday(start.plusDays(i.toLong()).dayOfWeek))
                views.addView(R.id.widget_weekdays, cell)
            }
        }

        private fun drawMonth(context: Context, views: RemoteViews, data: Data, month: LocalDate, today: LocalDate, id: Int, body: Int) {
            views.setTextViewText(R.id.widget_title, "${data.month(month.monthValue)} ${month.year}")
            val first = weekStart(month, data)
            weekdayHeader(context, views, data, first)
            val weeks = if (first.plusWeeks(5).month == month.month) 6 else 5
            // Each row: the day's number (22dp) and chips of about 14dp.
            val chips = (((body - 16) / weeks - 24) / 14).coerceIn(0, 6)
            for (w in 0 until weeks) {
                val row = RemoteViews(context.packageName, R.layout.widget_row)
                for (d in 0 until 7) {
                    val day = first.plusDays((w * 7 + d).toLong())
                    row.addView(R.id.widget_row, cell(context, data, day, today, day.month == month.month, chips, id, "d"))
                }
                views.addView(R.id.widget_body, row)
            }
            views.setOnClickPendingIntent(R.id.widget_add, openApp(context, id, 9_999, "create", if (month.month == today.month && month.year == today.year) today else month, "m"))
        }

        private fun drawWeek(context: Context, views: RemoteViews, data: Data, start: LocalDate, today: LocalDate, id: Int, body: Int) {
            val end = start.plusDays(6)
            views.setTextViewText(
                R.id.widget_title,
                if (start.month == end.month) "${start.dayOfMonth}–${end.dayOfMonth} ${data.month(end.monthValue).take(3).lowercase()}"
                else "${start.dayOfMonth} ${data.month(start.monthValue).take(3).lowercase()} – ${end.dayOfMonth} ${data.month(end.monthValue).take(3).lowercase()}",
            )
            weekdayHeader(context, views, data, start)
            val chips = ((body - 40) / 15).coerceIn(1, 14)
            val row = RemoteViews(context.packageName, R.layout.widget_row)
            for (d in 0 until 7) {
                val day = start.plusDays(d.toLong())
                row.addView(R.id.widget_row, cell(context, data, day, today, true, chips, id, "d"))
            }
            views.addView(R.id.widget_body, row)
            views.setOnClickPendingIntent(R.id.widget_add, openApp(context, id, 9_999, "create", if (!today.isBefore(start) && !today.isAfter(end)) today else start, "w"))
        }

        /**
         * The day as a timeline: the all-day entries, then the timed ones in order. Each entry's line has
         * its fixed height; under it, room that grows with the widget in proportion to how long it lasts
         * (and a little for a free hour between two entries). So a small widget is a plain list and a
         * bigger one makes the entries taller, never leaving an empty space below. Only whole lines;
         * what doesn't fit becomes "+N".
         */
        private fun drawDay(context: Context, views: RemoteViews, data: Data, day: LocalDate, today: LocalDate, id: Int, body: Int) {
            views.setTextViewText(R.id.widget_title, "${data.weekday(day.dayOfWeek)}, ${day.dayOfMonth} ${data.month(day.monthValue).lowercase()}")
            views.setOnClickPendingIntent(R.id.widget_body, openApp(context, id, 9_998, "open", day, "d"))
            views.setOnClickPendingIntent(R.id.widget_add, openApp(context, id, 9_999, "create", day, "d"))
            val entries = data.entries(day)
            if (entries.length() == 0) {
                val empty = RemoteViews(context.packageName, R.layout.widget_note)
                empty.setTextViewText(R.id.widget_note, data.label("empty", "Nada neste dia"))
                views.addView(R.id.widget_body, empty)
                return
            }

            // Half hours an entry lasts (1 for all-day ones), up to four hours.
            fun halfHours(e: JSONObject): Int {
                val start = e.optInt("s", -1)
                val end = e.optInt("e", -1)
                return if (start < 0 || end <= start) 1 else ((end - start + 15) / 30).coerceIn(1, 8)
            }
            fun time(minute: Int) = "%02d:%02d".format(minute / 60, minute % 60)

            // Heights in dp of a line, the end line of an entry of an hour or more, and a "+N".
            val lineHeight = 32
            val endHeight = 16
            val moreHeight = 18
            fun height(i: Int) = if (halfHours(entries.getJSONObject(i)) > 1) lineHeight + endHeight else lineHeight
            var room = body
            var shown = 0
            while (shown < entries.length() && room >= height(shown)) room -= height(shown++)
            if (shown < entries.length()) {
                while (shown > 0 && room < moreHeight) room += height(--shown)
            }

            // The minute the timed entries so far end (-1 before the first).
            var cursor = -1
            for (i in 0 until shown) {
                val e = entries.getJSONObject(i)
                val start = e.optInt("s", -1)
                val end = e.optInt("e", -1)
                val open = openApp(context, id, i, "open", day, "d")
                // A free hour or more before it: a little room (a bit more from three hours).
                if (start >= 0 && cursor >= 0 && start - cursor >= 60) {
                    repeat(if (start - cursor >= 180) 2 else 1) {
                        views.addView(R.id.widget_body, RemoteViews(context.packageName, R.layout.widget_gap))
                    }
                }
                val halves = halfHours(e)
                val top = RemoteViews(context.packageName, R.layout.widget_block_top)
                top.setTextViewText(R.id.widget_block_time, if (start < 0) data.label("allDay", "Dia todo") else time(start))
                top.setTextViewText(R.id.widget_block_title, e.optString("t"))
                tint(top, R.id.widget_block_title, color(e))
                if (e.optBoolean("d")) top.setFloat(R.id.widget_block_title, "setAlpha", 0.5f)
                top.setOnClickPendingIntent(R.id.widget_block_top, open)
                views.addView(R.id.widget_body, top)
                // Below the line: half an hour of room each (the last one with the end, from an hour on).
                for (h in 1..halves) {
                    val layout = when {
                        halves == 1 -> R.layout.widget_block_last
                        h < halves -> R.layout.widget_block_mid
                        else -> R.layout.widget_block_end
                    }
                    val row = RemoteViews(context.packageName, layout)
                    if (layout == R.layout.widget_block_end) row.setTextViewText(R.id.widget_block_end_time, time(end))
                    tint(row, R.id.widget_block_box, color(e))
                    if (e.optBoolean("d")) row.setFloat(R.id.widget_block_box, "setAlpha", 0.5f)
                    row.setOnClickPendingIntent(R.id.widget_block_row, open)
                    views.addView(R.id.widget_body, row)
                }
                if (start >= 0) cursor = maxOf(cursor, if (end > start) end else start + 30)
            }
            if (shown < entries.length()) {
                val more = RemoteViews(context.packageName, R.layout.widget_more)
                more.setTextViewText(R.id.widget_more, "+${entries.length() - shown}")
                views.addView(R.id.widget_body, more)
            }
        }

        /** A day of the month or the week: its number (today on a blue circle) and its first entries. */
        private fun cell(context: Context, data: Data, day: LocalDate, today: LocalDate, inMonth: Boolean, chips: Int, id: Int, opens: String): RemoteViews {
            val cell = RemoteViews(context.packageName, R.layout.widget_cell)
            cell.setTextViewText(R.id.widget_cell_day, day.dayOfMonth.toString())
            if (day == today) cell.setInt(R.id.widget_cell_day, "setBackgroundResource", R.drawable.widget_today)
            cell.setTextColor(R.id.widget_cell_day, if (inMonth) Color.WHITE else Color.argb(90, 255, 255, 255))
            val entries = data.entries(day)
            val shown = if (entries.length() > chips) (chips - 1).coerceAtLeast(0) else entries.length()
            for (i in 0 until shown) {
                val e = entries.getJSONObject(i)
                val chip = RemoteViews(context.packageName, R.layout.widget_chip)
                chip.setTextViewText(R.id.widget_chip, e.optString("t"))
                tint(chip, R.id.widget_chip, color(e))
                if (e.optBoolean("d") || !inMonth) chip.setFloat(R.id.widget_chip, "setAlpha", 0.5f)
                cell.addView(R.id.widget_cell_chips, chip)
            }
            if (shown < entries.length()) {
                val more = RemoteViews(context.packageName, R.layout.widget_more)
                more.setTextViewText(R.id.widget_more, "+${entries.length() - shown}")
                cell.addView(R.id.widget_cell_chips, more)
            }
            cell.setOnClickPendingIntent(R.id.widget_cell, openApp(context, id, day.dayOfYear + day.year % 10 * 400, "open", day, opens))
            return cell
        }

        private fun color(e: JSONObject): Int = try {
            Color.parseColor(e.optString("c", "#4772FA"))
        } catch (ex: IllegalArgumentException) {
            Color.parseColor("#4772FA")
        }

        /** The chip's rounded white background in the entry's color (a plain color before Android 12). */
        private fun tint(views: RemoteViews, viewId: Int, color: Int) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColorStateList(viewId, "setBackgroundTintList", ColorStateList.valueOf(color))
            } else {
                views.setInt(viewId, "setBackgroundColor", color)
            }
        }

        private fun broadcast(context: Context, id: Int, action: String, code: Int, extras: (Intent) -> Unit): PendingIntent {
            val intent = Intent(context, CalendarWidget::class.java).setAction(action).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
            extras(intent)
            return PendingIntent.getBroadcast(context, id * 100 + (code and 0x3F), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        /** Opens the app on [day] in [mode] (the Calendar's "d", "w" or "m"); "create" also opens the quick add. */
        private fun openApp(context: Context, id: Int, code: Int, action: String, day: LocalDate, mode: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
                .setAction("dev.lucasfelipe.task_manager.widget.OPEN.$code")
                .putExtra(EXTRA_ACTION, "$action|$day|$mode")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(context, id * 10_000 + code, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
    }
}
