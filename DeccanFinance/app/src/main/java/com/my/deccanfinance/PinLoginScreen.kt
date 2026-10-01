package com.my.deccanfinance

import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Backspace
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.fragment.app.FragmentActivity
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch
import java.util.concurrent.Executors

@Composable
fun PinLoginScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onLoginSuccess: () -> Unit,
    onForgotPin: () -> Unit
) {
    val context = LocalContext.current
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    val fullName = userData["full_name"] as? String ?: "User"
    val mobile = userData["phone"] as? String ?: ""
    val isBiometricEnabled = userData["biometric_enabled"] as? Boolean ?: false
    
    var pin by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    fun login(enteredPin: String) {
        isLoading = true
        scope.launch {
            try {
                val fcmToken = FcmUtils.getFcmToken()
                val response = apiService.loginWithPin(LoginWithPinRequest(mobile, enteredPin, fcmToken))
                if (response.isSuccessful && response.body()?.success == true) {
                    onLoginSuccess()
                } else {
                    snackbarHostState.showSnackbar(response.body()?.message ?: "Login failed")
                    pin = ""
                }
            } catch (e: Exception) {
                snackbarHostState.showSnackbar("Error: ${e.message}")
                pin = ""
            } finally {
                isLoading = false
            }
        }
    }

    fun showBiometricPrompt() {
        val executor = Executors.newSingleThreadExecutor()
        val biometricPrompt = BiometricPrompt(
            context as FragmentActivity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    scope.launch {
                        try {
                            val fcmToken = FcmUtils.getFcmToken()
                            // In a real app, you'd use a saved token. 
                            // For this demo, we'll assume the presence of a token or use a placeholder.
                            val response = apiService.loginWithBiometric(
                                LoginWithBiometricRequest("token-99497551", fcmToken)
                            )
                            if (response.isSuccessful && response.body()?.success == true) {
                                onLoginSuccess()
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Login")
            .setSubtitle("Log in using your biometric credential")
            .setNegativeButtonText("Use PIN")
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    LaunchedEffect(isBiometricEnabled) {
        if (isBiometricEnabled) {
            showBiometricPrompt()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = Color.White
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(40.dp))
            
            // Bank Logo Icon
            Surface(
                modifier = Modifier.size(64.dp),
                shape = RoundedCornerShape(16.dp),
                color = Color(0xFFF0F2FF)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Default.AccountBalance, 
                        contentDescription = null, 
                        tint = DashPrimary, 
                        modifier = Modifier.size(36.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            Text(
                "Welcome back, $fullName 👋",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color.Black
            )
            
            Text(
                "Enter your 4 digit login PIN to continue",
                fontSize = 14.sp,
                color = Color.Gray,
                modifier = Modifier.padding(top = 8.dp)
            )
            
            Spacer(modifier = Modifier.height(40.dp))
            
            // PIN Indicators
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                repeat(4) { index ->
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 12.dp)
                            .size(16.dp)
                            .clip(CircleShape)
                            .background(if (index < pin.length) DashPrimary else Color(0xFFF0F0F0))
                            .border(1.dp, if (index < pin.length) DashPrimary else Color(0xFFE0E0E0), CircleShape)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(40.dp))
            
            // Biometric Login Button
            if (isBiometricEnabled) {
                Surface(
                    onClick = { showBiometricPrompt() },
                    modifier = Modifier.fillMaxWidth().height(64.dp),
                    shape = RoundedCornerShape(32.dp),
                    color = Color(0xFFF8F9FF),
                    border = BorderStroke(1.dp, Color(0xFFF0F0F0))
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 24.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Fingerprint, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(28.dp))
                        Spacer(modifier = Modifier.width(16.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Login with Biometrics", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            Text("Use fingerprint / Face ID to login", fontSize = 11.sp, color = Color.Gray)
                        }
                        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                    }
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            if (isLoading) {
                CircularProgressIndicator(color = DashPrimary)
                Spacer(modifier = Modifier.weight(1f))
            } else {
                // Keypad
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    val keys = listOf(
                        listOf("1", "2", "3"),
                        listOf("4", "5", "6"),
                        listOf("7", "8", "9"),
                        listOf("Forgot PIN?", "0", "delete")
                    )
                    
                    keys.forEach { row ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            row.forEach { key ->
                                Box(
                                    modifier = Modifier.weight(1f),
                                    contentAlignment = Alignment.Center
                                ) {
                                    when (key) {
                                        "" -> Spacer(modifier = Modifier.size(72.dp))
                                        "Forgot PIN?" -> {
                                            TextButton(
                                                onClick = onForgotPin,
                                                modifier = Modifier.height(72.dp)
                                            ) {
                                                Text(
                                                    "Forgot PIN?", 
                                                    color = DashPrimary, 
                                                    fontWeight = FontWeight.Bold, 
                                                    fontSize = 12.sp,
                                                    textAlign = TextAlign.Center
                                                )
                                            }
                                        }
                                        else -> {
                                            Surface(
                                                onClick = { 
                                                    if (key == "delete") {
                                                        if (pin.isNotEmpty()) pin = pin.dropLast(1)
                                                    } else {
                                                        if (pin.length < 4) {
                                                            pin += key
                                                            if (pin.length == 4) login(pin)
                                                        }
                                                    }
                                                },
                                                modifier = Modifier.size(72.dp),
                                                shape = CircleShape,
                                                color = Color.White,
                                                border = BorderStroke(1.dp, Color(0xFFF8F9FF))
                                            ) {
                                                Box(contentAlignment = Alignment.Center) {
                                                    if (key == "delete") {
                                                        Icon(Icons.AutoMirrored.Filled.Backspace, contentDescription = "Delete", tint = DashPrimary)
                                                    } else {
                                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                                            Text(key, fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                                                            val subtext = getSubtext(key)
                                                            if (subtext.isNotEmpty()) {
                                                                Text(subtext, fontSize = 10.sp, color = Color.Gray, fontWeight = FontWeight.Bold)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Security Footer
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color(0xFFF8F9FF)
            ) {
                Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Shield, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(24.dp))
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text("Your security is our priority", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        Text("Never share your PIN with anyone", fontSize = 11.sp, color = Color.Gray)
                    }
                }
            }
        }
    }
}

fun getSubtext(key: String): String {
    return when (key) {
        "2" -> "ABC"
        "3" -> "DEF"
        "4" -> "GHI"
        "5" -> "JKL"
        "6" -> "MNO"
        "7" -> "PQRS"
        "8" -> "TUV"
        "9" -> "WXYZ"
        else -> ""
    }
}
