package com.my.deccanfinance

import android.app.Activity
import android.media.MediaPlayer
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dotlottie.dlplayer.Mode
import com.lottiefiles.dotlottie.core.compose.ui.DotLottieAnimation
import com.lottiefiles.dotlottie.core.util.DotLottieSource
import com.my.deccanfinance.ui.theme.NavyDark
import kotlinx.coroutines.launch

@Composable
fun SetMpinScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onSuccess: () -> Unit,
    onBack: () -> Unit
) {
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    var step by remember { mutableIntStateOf(0) } // 0: Aadhaar, 1: Enter PIN, 2: Confirm PIN, 3: Success
    var aadhaarLast6 by remember { mutableStateOf("") }
    var isAadhaarVerified by remember { mutableStateOf(value = false) }
    var mpin by remember { mutableStateOf("") }
    var confirmMpin by remember { mutableStateOf("") }
    
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val successLottieSource = remember { 
        DotLottieSource.Url("https://lottie.host/b89928b9-d256-4e0f-9ba0-0dabae2c1f3b/4qnwwTuZRI.lottie") 
    }

    val view = LocalView.current
    // Global theme handles status bar appearance

    Surface(modifier = Modifier.fillMaxSize(), color = Color(0xFFF5F5F5)) {
        Box(modifier = Modifier.fillMaxSize().statusBarsPadding()) {
            // Preload Lottie Animation
            if (step < 3) {
                Box(modifier = Modifier.size(1.dp).alpha(0f)) {
                    DotLottieAnimation(
                        source = successLottieSource,
                        autoplay = false
                    )
                }
            }

            Column(modifier = Modifier.fillMaxSize()) {
            if (step < 3) {
                // Header (White)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.White)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.Black)
                    }
                    Text(
                        text = "Deccan Finance",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.Black,
                        modifier = Modifier.padding(start = 8.dp)
                    )
                    Spacer(modifier = Modifier.weight(1f))
                }

                // Sub-header (Blue Bar)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color(0xFF2E3B8E)) // Deep blue
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = (userData["full_name"] as? String) ?: "User",
                        color = Color.White,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "AC ID: ${(userData["app_id"] as? String) ?: "****"}",
                        color = Color.White.copy(alpha = 0.9f),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            AnimatedContent(
                targetState = step,
                transitionSpec = { fadeIn() togetherWith fadeOut() },
                label = "step_transition",
                modifier = Modifier.weight(1f)
            ) { currentStep ->
                when (currentStep) {
                    0 -> AadhaarStep(
                        apiService = apiService,
                        value = aadhaarLast6,
                        isVerified = isAadhaarVerified,
                        onVerified = { isAadhaarVerified = true },
                        onValueChange = { if (it.length <= 6) {
                            aadhaarLast6 = it
                            isAadhaarVerified = false 
                        } },
                        onNext = { step = 1 }
                    )
                    1 -> MpinEntryStep(
                        title = "ENTER PIN",
                        value = mpin,
                        onValueChange = { if (it.length <= 6) mpin = it },
                        onNext = { if (mpin.length == 6) step = 2 }
                    )
                    2 -> MpinEntryStep(
                        title = "CONFIRM PIN",
                        value = confirmMpin,
                        onValueChange = { if (it.length <= 6) confirmMpin = it },
                        isConfirm = true,
                        errorMessage = errorMessage,
                        onNext = {
                            if (confirmMpin == mpin) {
                                isLoading = true
                                errorMessage = null
                                scope.launch {
                                    try {
                                        val response = apiService.createMpin(CreateMpinRequest(mpin, aadhaarLast6))
                                        if (response.isSuccessful && response.body()?.success == true) {
                                            step = 3
                                        } else {
                                            errorMessage = response.body()?.message ?: "Failed to set MPIN"
                                        }
                                    } catch (e: Exception) {
                                        errorMessage = "Network error: ${e.message}"
                                    } finally {
                                        isLoading = false
                                    }
                                }
                            } else {
                                errorMessage = "PINs do not match"
                            }
                        }
                    )
                    3 -> SuccessStep(
                        lottieSource = successLottieSource,
                        onFinish = onSuccess
                    )
                }
            }

            if (isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.3f)),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = PrimaryBlue)
                }
            }

            if (step < 3) {
                // Footer
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "powered by Deccan Finance",
                        color = Color.Gray,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
}

@Composable
fun AadhaarStep(
    apiService: ApiService,
    value: String,
    isVerified: Boolean,
    onVerified: () -> Unit,
    onValueChange: (String) -> Unit,
    onNext: () -> Unit
) {
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(value) {
        if (value.length == 6 && !isVerified) {
            isLoading = true
            errorMessage = null
            try {
                val response = apiService.verifyAadhaar(VerifyAadhaarRequest(value))
                if (response.isSuccessful && response.body()?.success == true) {
                    onVerified()
                } else {
                    errorMessage = response.body()?.message ?: "Verification failed"
                }
            } catch (e: Exception) {
                errorMessage = "Error: ${e.message}"
            } finally {
                isLoading = false
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            "Verify Aadhaar",
            fontSize = 24.sp,
            fontWeight = FontWeight.ExtraBold,
            color = NavyDark
        )
        Text(
            "Enter the last 6 digits of your Aadhaar card to proceed.",
            fontSize = 14.sp,
            color = Color.Gray,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(vertical = 12.dp)
        )

        Spacer(modifier = Modifier.height(32.dp))

        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
            OutlinedTextField(
                value = value,
                onValueChange = { if (it.all { char -> char.isDigit() } && it.length <= 6) onValueChange(it) },
                label = { Text("Last 6 Digits", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = if (!isVerified) Color.Black else Color.Gray) },
                placeholder = { Text("XXXXXX", color = Color.LightGray) },
                prefix = { 
                    Text(
                        text = "XXXX -XX ",
                        color = Color.Gray, 
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    ) 
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = !isVerified,
                textStyle = LocalTextStyle.current.copy(
                    color = Color.Black,
                    fontSize = 18.sp, 
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp
                ),
                shape = RoundedCornerShape(16.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.Black,
                    unfocusedTextColor = Color.Black,
                    disabledTextColor = Color.Black.copy(alpha = 0.6f),
                    focusedBorderColor = PrimaryBlue,
                    unfocusedBorderColor = Color.Gray,
                    disabledBorderColor = Color.Gray.copy(alpha = 0.5f),
                    focusedContainerColor = Color(0xFFF8FAFC),
                    unfocusedContainerColor = Color(0xFFF8FAFC),
                    disabledContainerColor = Color(0xFFF1F5F9).copy(alpha = 0.5f),
                    focusedLabelColor = PrimaryBlue,
                    unfocusedLabelColor = Color.Gray,
                    cursorColor = PrimaryBlue
                ),
                singleLine = true
            )

            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier
                        .padding(top = 24.dp, end = 16.dp)
                        .size(24.dp),
                    strokeWidth = 2.dp,
                    color = PrimaryBlue
                )
            }

            this@Column.AnimatedVisibility(
                visible = isVerified,
                enter = scaleIn() + fadeIn(),
                modifier = Modifier.padding(top = 24.dp, end = 16.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Verified",
                    tint = Color(0xFF10B981),
                    modifier = Modifier
                        .size(28.dp)
                        .background(Color(0xFFD1FAE5), CircleShape)
                        .padding(4.dp)
                )
            }
        }

        if (errorMessage != null) {
            Text(
                errorMessage!!,
                color = Color.Red,
                fontSize = 12.sp,
                modifier = Modifier.padding(top = 8.dp)
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        this@Column.AnimatedVisibility(visible = isVerified) {
            Button(
                onClick = onNext,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(60.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
            ) {
                Text("CONTINUE", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun MpinEntryStep(
    title: String,
    value: String,
    onValueChange: (String) -> Unit,
    @Suppress("UNUSED_PARAMETER") isConfirm: Boolean = false,
    errorMessage: String? = null,
    onNext: () -> Unit
) {
    var pinVisible by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(top = 60.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = title,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF666666),
                letterSpacing = 1.sp
            )
            Spacer(modifier = Modifier.width(32.dp))
            Row(
                modifier = Modifier.clickable { pinVisible = !pinVisible },
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    if (pinVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Color(0xFF2E3B8E)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    if (pinVisible) "HIDE" else "SHOW", 
                    fontSize = 13.sp, 
                    fontWeight = FontWeight.Bold, 
                    color = Color(0xFF2E3B8E)
                )
            }
        }

        Spacer(modifier = Modifier.height(50.dp))

        // Large PIN Dots
        Row(
            horizontalArrangement = Arrangement.spacedBy(30.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            repeat(6) { index ->
                val isActive = index < value.length
                val char = if (isActive && pinVisible) value[index].toString() else null
                
                if (char != null) {
                    Text(char, fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                } else {
                    Box(
                        modifier = Modifier
                            .size(14.dp)
                            .clip(CircleShape)
                            .background(if (isActive) Color.Black else Color.LightGray.copy(alpha = 0.5f))
                    )
                }
            }
        }

        if (errorMessage != null) {
            Text(
                errorMessage,
                color = Color.Red,
                fontSize = 14.sp,
                modifier = Modifier.padding(top = 32.dp)
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        // Custom Keypad (UPI Style)
        val keys = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "back", "0", "check")
        
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color(0xFFEEEEEE).copy(alpha = 0.3f))
                .padding(bottom = 8.dp)
        ) {
            for (i in 0 until 4) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceAround
                ) {
                    for (j in 0 until 3) {
                        val key = keys[i * 3 + j]
                        KeypadButton(key = key) {
                            when (key) {
                                "back" -> if (value.isNotEmpty()) onValueChange(value.dropLast(1))
                                "check" -> if (value.length == 6) onNext()
                                else -> if (value.length < 6) onValueChange(value + key)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun KeypadButton(key: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(width = 100.dp, height = 70.dp)
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        when (key) {
            "back" -> Icon(Icons.Default.Clear, contentDescription = "Delete", tint = Color(0xFF2E3B8E), modifier = Modifier.size(28.dp))
            "check" -> Surface(
                modifier = Modifier.size(64.dp),
                shape = CircleShape,
                color = Color(0xFF2E3B8E)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.Default.Check, contentDescription = "Done", tint = Color.White, modifier = Modifier.size(32.dp))
                }
            }
            else -> Text(key, fontSize = 28.sp, fontWeight = FontWeight.Normal, color = Color(0xFF2E3B8E))
        }
    }
}

@Composable
fun SuccessStep(lottieSource: DotLottieSource, onFinish: () -> Unit) {
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        try {
            val mediaPlayer = MediaPlayer()
            val afd = context.assets.openFd("success.mp3")
            mediaPlayer.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            mediaPlayer.prepare()
            mediaPlayer.start()
            mediaPlayer.setOnCompletionListener { it.release() }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(modifier = Modifier.size(220.dp)) {
            DotLottieAnimation(
                source = lottieSource,
                autoplay = true,
                loop = true,
                speed = 3f,
                useFrameInterpolation = false,
                playMode = Mode.FORWARD,
                modifier = Modifier.fillMaxSize()
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            "MPIN Created Successfully!",
            fontSize = 24.sp,
            fontWeight = FontWeight.ExtraBold,
            color = Color.Black,
            textAlign = TextAlign.Center
        )

        Text(
            "Your account is now fully secured. Use this MPIN for all future transactions.",
            fontSize = 15.sp,
            color = Color.Gray,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 12.dp, bottom = 40.dp)
        )

        Button(
            onClick = onFinish,
            modifier = Modifier
                .fillMaxWidth()
                .height(60.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF10B981))
        ) {
            Text("GO TO DASHBOARD", fontWeight = FontWeight.Bold)
        }
    }
}
