package com.usage.timer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.*
import android.content.*
import android.os.*
import android.app.usage.*
import android.view.*
import android.widget.*
import android.graphics.*
import java.util.*
import java.util.concurrent.*
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationCompat


fun isForegroundServiceRunning(context: Context): Boolean {
    val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    val runningServices = manager.getRunningServices(Int.MAX_VALUE)

    for (service in runningServices) {
        if ("com.usage.timer.ForegroundAppService" == service.service.className) {
            if (service.foreground) {
                return true
            }
        }
    }
    return false
}

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.usage.timer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            
            val intent = Intent(context, ForegroundAppService::class.java)

            if(call.method == "start"){
                intent.putStringArrayListExtra("packages", ArrayList((call.arguments as Map<String, Any>)["packages"] as List<String>))
                intent.putIntegerArrayListExtra("goals", ArrayList((call.arguments as Map<String, Any>)["goals"] as List<Int>))
                this.startService(intent)
                result.success(null)
            }
            else if(call.method == "stop"){
                this.stopService(intent)
                result.success(null)
            }
            else if(call.method == "isRunning"){
                val isServiceRunning = isForegroundServiceRunning(this)
                result.success(isServiceRunning)
            }
            else if(call.method == "usage"){
                val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val calendar = Calendar.getInstance()
                val endTime = calendar.timeInMillis
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
                val startTime = calendar.timeInMillis
    
                val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
                var totalTime = 0L
                var lastForegroundTime = 0L
    
                while (usageEvents.hasNextEvent()) {
                    val event = UsageEvents.Event()
                    usageEvents.getNextEvent(event)
                    if (event.packageName == ((call.arguments as Map<String, Any>)["package"] as String)) {
                        when (event.eventType) {
                            UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                                lastForegroundTime = event.timeStamp
                            }
                            UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                                if (lastForegroundTime != 0L) {
                                    totalTime += event.timeStamp - lastForegroundTime
                                    lastForegroundTime = 0L
                                }
                            }
                        }
                    }
                }
    
                // If the app is currently in the foreground, add the time from the last foreground event to the current time
                if (lastForegroundTime != 0L) {
                    totalTime += endTime - lastForegroundTime
                }    
                result.success(totalTime.toString())
            }
        }
    }
}

class ForegroundAppService : Service() {
    private val executor = Executors.newSingleThreadScheduledExecutor()
    private val handler = Handler(Looper.getMainLooper())
    private val usageStatsManager by lazy {
        getSystemService(UsageStatsManager::class.java)
    }

    private lateinit var notificationManager: NotificationManager
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "ForegroundServiceChannel"

    private var currentRunningApp: String = ""

    private lateinit var windowManager: WindowManager

    private var isPopupVisible = false
    private lateinit var popupView: View
    private lateinit var chronometer : Chronometer
    private lateinit var total : Chronometer

    private lateinit var reminderView: View
    private var isReminderVisible = false

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f

    private var enabledApps : List<String> = emptyList()
    private var goals : List<Int> = mutableListOf()

    private val printRunnable = Runnable {

        checkForegroundApp()
        
        if (currentRunningApp in enabledApps) {
            
            if((goals[enabledApps.indexOf(currentRunningApp)]/1000) == (getUsage(this, currentRunningApp).toInt()/1000)){
                try{
                    handler.post{
                        Handler().postDelayed(
                            {   
                                if(!(isReminderVisible)){
                                    showReminder()          
                                    isReminderVisible = true
                                }
                            },
                            1
                        )
                    }
                } catch(e: Exception){}                    
            }
                        
            if (!(isPopupVisible)) {
                try{
                    handler.post{
                        Handler().postDelayed(
                            {   
                                vibrateDevice(this, 400)
                                showPopup()
                                if(goals[enabledApps.indexOf(currentRunningApp)] < getUsage(this, currentRunningApp).toInt()){
                                   showReminder() 
                                }
                            },
                            1
                        )
                    }
                } catch(e: Exception){}

                isPopupVisible = true
            }
        } 
        else {
            if (isPopupVisible) {
                try{
                    handler.post{
                        Handler().postDelayed(
                            {
                                hidePopup()
                            },
                            1
                        )
                    }
                } catch(e: Exception){}

                isPopupVisible = false
            }
        }
        
    }

    private fun checkForegroundApp() {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val usageEvents = usm.queryEvents(time - 1000 * 10, time)
    
        var event: UsageEvents.Event? = UsageEvents.Event()
        var lastEvent: UsageEvents.Event? = null
        var currentApp: String = ""
    
        while (usageEvents.hasNextEvent()) {
            event = UsageEvents.Event()
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                lastEvent = event
                lastEvent?.let {
                    currentRunningApp = it.packageName                    
                }
            }
        }
    }
    

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        showNotification("Starting...")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        enabledApps = (intent?.getStringArrayListExtra("packages") as? List<String> ?: emptyList()).toMutableList()
        goals = intent?.getIntegerArrayListExtra("goals") as? List<Int> ?: mutableListOf()

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        popupView = LayoutInflater.from(this).inflate(R.layout.popup_layout, null)
        chronometer  = popupView.findViewById(R.id.popup_text)
        total = popupView.findViewById(R.id.total_text)
        
        reminderView = LayoutInflater.from(this).inflate(R.layout.phone_layout, null)
        
        executor.scheduleAtFixedRate(printRunnable, 0, 1000, TimeUnit.MILLISECONDS)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Notification",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(serviceChannel)
        }
    }

    private fun showNotification(packageName: String) {
        val notificationIntent = Intent() // Empty intent
        val pendingIntent = PendingIntent.getActivity(
            this,
            0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Usage timer")
            .setContentText("Usage timer is active")
            .setSmallIcon(R.drawable.icon_img)
            .setContentIntent(pendingIntent) // Providing empty intent
            .build()
    
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun getUsage(context: Context, targetPackageName: String): Long {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
    
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        var totalTime = 0L
        var lastForegroundTime = 0L
    
        while (usageEvents.hasNextEvent()) {
            val event = UsageEvents.Event()
            usageEvents.getNextEvent(event)
            if (event.packageName == targetPackageName) {
                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        lastForegroundTime = event.timeStamp
                    }
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        if (lastForegroundTime != 0L) {
                            totalTime += event.timeStamp - lastForegroundTime
                            lastForegroundTime = 0L
                        }
                    }
                }
            }
        }
    
        // If the app is currently in the foreground, add the time from the last foreground event to the current time
        if (lastForegroundTime != 0L) {
            totalTime += endTime - lastForegroundTime
        }
    
        return totalTime
    }
    
    private fun getTotalUsage(context: Context): Long{
        var totalTime = 0L
        enabledApps.forEach{
            packageName->
            totalTime = totalTime + getUsage(context, packageName)
        }
        return totalTime
    }

    private fun showReminder() {
        try{
            windowManager.removeView(reminderView)
        } catch(e: Exception){}

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        val button: Button = reminderView.findViewById(R.id.button)

        button.setOnClickListener{
            windowManager.removeView(reminderView)
            isReminderVisible = false
        }

        windowManager.addView(reminderView, layoutParams)
    }

    private fun showPopup() {
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        layoutParams.gravity = Gravity.TOP or Gravity.START
        layoutParams.x = 0
        layoutParams.y = 0

        popupView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = layoutParams.x
                    initialY = layoutParams.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    layoutParams.x = initialX + (event.rawX - initialTouchX).toInt()
                    layoutParams.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager.updateViewLayout(popupView, layoutParams)
                    true
                }
                else -> false
            }
        }

        windowManager.addView(popupView, layoutParams)

        chronometer.base = SystemClock.elapsedRealtime() - getUsage(this, currentRunningApp)
        chronometer.start()
        
        if(true){
            total.visibility = View.GONE
        }
    }

    private fun hidePopup() {
        chronometer.base = SystemClock.elapsedRealtime()
        chronometer.stop()
        windowManager.removeView(popupView)
    }
}
