package com.my.deccanfinance

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ForgotPasswordScreen(
    apiService: ApiService,
    onSuccess: () -> Unit,
    onBack: () -> Unit
) {
    var step by remember { mutableIntStateOf(1) }
    var identity by remember { mutableStateOf("") }
    var otp by remember { mutableStateOf("") }
    var sessionId by remember { mutableStateOf("") }
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    
    var isLoading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    fun requestOtp() {
        if (identity.isEmpty()) return
        isLoading = true
        scope.launch {
            try {
                val response = apiService.forgotPassword(
                    ForgotPasswordRequest(action = "request_otp", identity = identity)
                )
                if (response.isSuccessful && response.body()?.success == true) {
                    sessionId = response.body()?.sessionId ?: ""
                    step = 2
                    snackbarHostState.showSnackbar(response.body()?.message ?: "OTP sent")
                } else {
                    snackbarHostState.showSnackbar(response.body()?.message ?: "Failed to send OTP")
                }
            } catch (e: Exception) {
                snackbarHostState.showSnackbar("Error: ${e.message}")
            } finally {
                isLoading = false
            }
        }
    }

    fun verifyOtp() {
        if (otp.length < 6) return
        isLoading = true
        scope.launch {
            try {
                val response = apiService.forgotPassword(
                    ForgotPasswordRequest(action = "verify_otp", sessionId = sessionId, otp = otp)
                )
                if (response.isSuccessful && response.body()?.success == true) {
                    step = 3
                    snackbarHostState.showSnackbar("OTP verified")
                } else {
                    snackbarHostState.showSnackbar(response.body()?.message ?: "Invalid OTP")
                }
            } catch (e: Exception) {
                snackbarHostState.showSnackbar("Error: ${e.message}")
            } finally {
                isLoading = false
            }
        }
    }

    fun resetPassword() {
        if (newPassword.length < 6) {
            scope.launch { snackbarHostState.showSnackbar("Password too short") }
            return
        }
        if (newPassword != confirmPassword) {
            scope.launch { snackbarHostState.showSnackbar("Passwords do not match") }
            return
        }
        isLoading = true
        scope.launch {
            try {
                val response = apiService.forgotPassword(
                    ForgotPasswordRequest(action = "reset_password", sessionId = sessionId, newPassword = newPassword)
                )
                if (response.isSuccessful && response.body()?.success == true) {
                    snackbarHostState.showSnackbar("Password reset successfully")
                    onSuccess()
                } else {
                    snackbarHostState.showSnackbar(response.body()?.message ?: "Failed to reset password")
                }
            } catch (e: Exception) {
                snackbarHostState.showSnackbar("Error: ${e.message}")
            } finally {
                isLoading = false
            }
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text("Reset Password", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1A1C1E)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = DashPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DashBg)
            )
        },
        containerColor = DashBg
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            when (step) {
                1 -> RequestOtpStep(identity, onIdentityChange = { identity = it }, isLoading, onRequest = { requestOtp() })
                2 -> VerifyOtpStep(otp, onOtpChange = { otp = it }, isLoading, onVerify = { verifyOtp() })
                3 -> ResetPasswordStep(newPassword, confirmPassword, onPasswordChange = { newPassword = it }, onConfirmChange = { confirmPassword = it }, isLoading, onReset = { resetPassword() })
            }
        }
    }
}

@Composable
fun RequestOtpStep(identity: String, onIdentityChange: (String) -> Unit, isLoading: Boolean, onRequest: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(Icons.Outlined.LockReset, contentDescription = null, modifier = Modifier.size(80.dp), tint = DashPrimary)
        Spacer(modifier = Modifier.height(24.dp))
        Text("Forgot Password?", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Text(
            "Enter your registered email or mobile number to receive a verification code.",
            fontSize = 14.sp,
            color = Color.Gray,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 8.dp)
        )
        Spacer(modifier = Modifier.height(32.dp))
        
        OutlinedTextField(
            value = identity,
            onValueChange = onIdentityChange,
            label = { Text("Email or Mobile Number") },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            singleLine = true,
            colors = TextFieldDefaults.colors(
                focusedTextColor = Color.Black,
                unfocusedTextColor = Color.Black,
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White
            )
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = onRequest,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DashPrimary),
            enabled = !isLoading && identity.isNotEmpty()
        ) {
            if (isLoading) CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
            else Text("Send Verification Code", fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun VerifyOtpStep(otp: String, onOtpChange: (String) -> Unit, isLoading: Boolean, onVerify: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(Icons.Outlined.MarkEmailRead, contentDescription = null, modifier = Modifier.size(80.dp), tint = DashPrimary)
        Spacer(modifier = Modifier.height(24.dp))
        Text("Verify Identity", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Text(
            "Please enter the 6-digit verification code sent to your registered identity.",
            fontSize = 14.sp,
            color = Color.Gray,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 8.dp)
        )
        Spacer(modifier = Modifier.height(32.dp))
        
        OtpInputBoxes(otp, onOtpChange)
        
        Spacer(modifier = Modifier.height(40.dp))
        
        Button(
            onClick = onVerify,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DashPrimary),
            enabled = !isLoading && otp.length == 6
        ) {
            if (isLoading) CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
            else Text("Verify OTP", fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun OtpInputBoxes(otp: String, onOtpChange: (String) -> Unit) {
    val focusRequester = remember { FocusRequester() }

    Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxWidth().height(60.dp)) {
        // Hidden TextField for input
        // Use alpha(0f) instead of size(0.dp) to keep it in the layout for focusing/scrolling logic
        TextField(
            value = otp,
            onValueChange = {
                if (it.length <= 6 && it.all { c -> c.isDigit() }) {
                    onOtpChange(it)
                }
            },
            modifier = Modifier
                .fillMaxSize() // Fill the box but be invisible
                .focusRequester(focusRequester)
                .alpha(0f),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
        )

        // Visual boxes
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(
                    interactionSource = remember { androidx.compose.foundation.interaction.MutableInteractionSource() },
                    indication = null
                ) { focusRequester.requestFocus() },
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            repeat(6) { index ->
                val char = otp.getOrNull(index)?.toString() ?: ""
                val isFocused = otp.length == index
                
                Surface(
                    modifier = Modifier
                        .size(52.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .border(
                            2.dp,
                            if (isFocused) DashPrimary else if (char.isNotEmpty()) DashPrimary.copy(alpha = 0.5f) else Color.LightGray.copy(alpha = 0.5f),
                            RoundedCornerShape(12.dp)
                        ),
                    color = Color.White,
                    shadowElevation = if (isFocused) 4.dp else 0.dp
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = char,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF1A1C1E)
                        )
                        if (isFocused) {
                            // Simple cursor indicator
                            Box(
                                modifier = Modifier
                                    .align(Alignment.BottomCenter)
                                    .padding(bottom = 8.dp)
                                    .width(12.dp)
                                    .height(2.dp)
                                    .background(DashPrimary)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Auto focus when the step loads with a small delay to prevent "bring into view" crash
    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(300)
        try {
            focusRequester.requestFocus()
        } catch (e: Exception) {
            // Ignore if it fails due to layout timing
        }
    }
}

@Composable
fun ResetPasswordStep(
    password: String, 
    confirm: String, 
    onPasswordChange: (String) -> Unit, 
    onConfirmChange: (String) -> Unit, 
    isLoading: Boolean, 
    onReset: () -> Unit
) {
    var passwordVisible by remember { mutableStateOf(false) }
    
    // Password Strength
    val strength = remember(password) { calculatePasswordStrength(password) }
    val strengthColor = when(strength) {
        0 -> Color.Gray
        1 -> Color.Red
        2 -> Color.Yellow
        3 -> Color.Green
        else -> DashPrimary
    }
    val strengthText = when(strength) {
        0 -> "Too short"
        1 -> "Weak"
        2 -> "Medium"
        3 -> "Strong"
        else -> "Very Strong"
    }

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(Icons.Outlined.VpnKey, contentDescription = null, modifier = Modifier.size(80.dp), tint = DashPrimary)
        Spacer(modifier = Modifier.height(24.dp))
        Text("Create New Password", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Text(
            "Choose a strong password with at least 6 characters.",
            fontSize = 14.sp,
            color = Color.Gray,
            modifier = Modifier.padding(top = 8.dp)
        )
        Spacer(modifier = Modifier.height(32.dp))
        
        OutlinedTextField(
            value = password,
            onValueChange = onPasswordChange,
            label = { Text("New Password") },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            trailingIcon = {
                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                    Icon(if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility, contentDescription = null)
                }
            },
            colors = TextFieldDefaults.colors(
                focusedTextColor = Color.Black,
                unfocusedTextColor = Color.Black,
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White
            )
        )
        
        // Strength Indicator
        if (password.isNotEmpty()) {
            Row(modifier = Modifier.fillMaxWidth().padding(top = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                LinearProgressIndicator(
                    progress = { strength.toFloat() / 4f },
                    modifier = Modifier.weight(1f).height(4.dp).clip(RoundedCornerShape(2.dp)),
                    color = strengthColor,
                    trackColor = Color.LightGray.copy(alpha = 0.3f)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(strengthText, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = strengthColor)
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        OutlinedTextField(
            value = confirm,
            onValueChange = onConfirmChange,
            label = { Text("Confirm New Password") },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            visualTransformation = PasswordVisualTransformation(),
            colors = TextFieldDefaults.colors(
                focusedTextColor = Color.Black,
                unfocusedTextColor = Color.Black,
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White
            )
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = onReset,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DashPrimary),
            enabled = !isLoading && password.length >= 6 && password == confirm
        ) {
            if (isLoading) CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
            else Text("Update Password", fontWeight = FontWeight.Bold)
        }
    }
}

fun calculatePasswordStrength(password: String): Int {
    if (password.length < 6) return 0
    var strength = 1
    if (password.any { it.isUpperCase() }) strength++
    if (password.any { it.isDigit() }) strength++
    if (password.any { !it.isLetterOrDigit() }) strength++
    return strength
}
