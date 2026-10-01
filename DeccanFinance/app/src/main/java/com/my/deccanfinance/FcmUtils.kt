package com.my.deccanfinance

import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await
import android.util.Log

object FcmUtils {
    suspend fun getFcmToken(): String? {
        return try {
            val token = FirebaseMessaging.getInstance().token.await()
            Log.d("FcmUtils", "FCM Token: $token")
            token
        } catch (e: Exception) {
            Log.e("FcmUtils", "Failed to fetch FCM token", e)
            null
        }
    }
}
