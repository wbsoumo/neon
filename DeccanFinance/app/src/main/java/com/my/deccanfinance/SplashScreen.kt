package com.my.deccanfinance

import android.media.MediaPlayer
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first

@Composable
fun SplashScreen(apiService: ApiService, dataManager: DataManager, onSplashFinished: (Boolean) -> Unit) {
    val context = LocalContext.current

    LaunchedEffect(key1 = true) {
        // Force login if status was PENDING
        val userData = dataManager.userData.first()
        val forceLogin = userData["status"] == "PENDING"

        // Start checking session while video is playing
        val checkSessionDeferred = async {
            if (forceLogin) return@async false

            try {
                val response = apiService.autoLogin()
                if (response.isSuccessful && response.body()?.success == true) {
                    val detailsResponse = apiService.getUserDetails()
                    if (detailsResponse.isSuccessful && detailsResponse.body()?.success == true) {
                        detailsResponse.body()?.user?.let { dataManager.saveUserData(it) }
                    }
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                false
            }
        }

        // Wait for 3 seconds (video duration)
        delay(3200)
        
        val isLoggedIn = checkSessionDeferred.await()
        onSplashFinished(isLoggedIn)
    }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        AndroidView(
            factory = { ctx ->
                val frameLayout = FrameLayout(ctx).apply {
                    layoutParams = ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                }
                val surfaceView = SurfaceView(ctx)
                frameLayout.addView(surfaceView)

                val mediaPlayer = MediaPlayer()
                surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
                    override fun surfaceCreated(holder: SurfaceHolder) {
                        try {
                            mediaPlayer.setDisplay(holder)
                            val afd = ctx.assets.openFd("flashscreenvideo-new.mp4")
                            mediaPlayer.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                            mediaPlayer.prepare()
                            mediaPlayer.start()
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }

                    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}
                    override fun surfaceDestroyed(holder: SurfaceHolder) {
                        mediaPlayer.release()
                    }
                })
                frameLayout
            },
            modifier = Modifier.fillMaxSize()
        )
    }
}
