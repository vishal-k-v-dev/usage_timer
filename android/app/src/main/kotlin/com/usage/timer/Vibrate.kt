package com.usage.timer

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator

fun vibrateDevice(context: Context, duration: Long) {
    val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE))
    } else {
        vibrator.vibrate(duration)
    }
}
