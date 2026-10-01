package com.my.deccanfinance

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlinx.coroutines.launch

// High-fidelity colors matching the provided design
val PrimaryBlue = Color(0xFF5E5CE6) 
val BgLight = Color(0xFFF8F9FF)
val InputFieldBg = Color(0xFFF9FAFB)
val IconBoxBg = Color(0xFFEEF2FF)
val TextGray = Color(0xFF6B7280)
val BorderColor = Color(0xFFF3F4F6)

@Composable
fun LoginScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onLoginSuccess: () -> Unit,
    onRegisterClick: () -> Unit,
    onForgotPasswordClick: () -> Unit
) {
    var identity by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var rememberMe by remember { mutableStateOf(false) }

    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    
    val passwordFocusRequester = remember { FocusRequester() }

    Box(modifier = Modifier.fillMaxSize().background(Color.White)) {
        // Background Image - City Silhouette
        AsyncImage(
            model = "file:///android_asset/loginbg.png",
            contentDescription = null,
            modifier = Modifier
                .fillMaxWidth()
                .height(400.dp)
                .align(Alignment.TopCenter),
            contentScale = ContentScale.FillWidth
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(40.dp))
            
            // App Title & Slogan
            Text(
                "Deccan Finance",
                fontSize = 34.sp,
                fontWeight = FontWeight.ExtraBold,
                color = PrimaryBlue,
                letterSpacing = (-0.5).sp
            )
            
            Text(
                "Banking that's simple, secure\nand built for you.",
                fontSize = 14.sp,
                color = TextGray,
                textAlign = TextAlign.Center,
                lineHeight = 20.sp,
                modifier = Modifier.padding(top = 8.dp)
            )

            Spacer(modifier = Modifier.height(160.dp))

            // Main Login Card
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(16.dp, RoundedCornerShape(32.dp)),
                shape = RoundedCornerShape(32.dp),
                color = Color.White
            ) {
                Column(
                    modifier = Modifier.padding(24.dp)
                ) {
                    Text(
                        "Welcome back!",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                    
                    Text(
                        "Login to continue to your account",
                        fontSize = 14.sp,
                        color = TextGray,
                        modifier = Modifier.padding(top = 4.dp)
                    )

                    Spacer(modifier = Modifier.height(32.dp))

                    // Email or Mobile Number Input
                    LoginInputField(
                        label = "Email or Mobile Number",
                        value = identity,
                        onValueChange = { identity = it },
                        placeholder = "example@mail.com or 9876543210",
                        icon = Icons.Outlined.Person
                    )

                    Spacer(modifier = Modifier.height(20.dp))

                    // Password Input
                    LoginInputField(
                        label = "Password",
                        value = password,
                        onValueChange = { password = it },
                        placeholder = ".........",
                        icon = Icons.Outlined.Lock,
                        isPassword = true,
                        passwordVisible = passwordVisible,
                        onVisibilityToggle = { passwordVisible = !passwordVisible },
                        modifier = Modifier.focusRequester(passwordFocusRequester)
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    if (errorMessage != null) {
                        Text(
                            errorMessage!!,
                            color = Color.Red,
                            fontSize = 12.sp,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                    }

                    // Remember Me & Forgot Password
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable { rememberMe = !rememberMe }) {
                            Surface(
                                modifier = Modifier.size(20.dp),
                                shape = RoundedCornerShape(4.dp),
                                color = if (rememberMe) PrimaryBlue else Color.White,
                                border = BorderStroke(1.dp, if (rememberMe) PrimaryBlue else Color.LightGray)
                            ) {
                                if (rememberMe) {
                                    Icon(Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.padding(2.dp))
                                }
                            }
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Remember me", fontSize = 13.sp, color = TextGray)
                        }
                        Text(
                            "Forgot password?",
                            fontSize = 13.sp,
                            color = PrimaryBlue,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.clickable { onForgotPasswordClick() }
                        )
                    }

                    Spacer(modifier = Modifier.height(32.dp))

                    // Login Securely Button
                    Button(
                        onClick = {
                            isLoading = true
                            errorMessage = null
                            scope.launch {
                                try {
                                    val fcmToken = FcmUtils.getFcmToken()
                                    val response = apiService.login(LoginRequest(identity, password, fcmToken))
                                    if (response.isSuccessful && response.body()?.success == true) {
                                        response.body()?.user?.let { dataManager.saveUserFromLogin(it) }
                                        onLoginSuccess()
                                    } else {
                                        errorMessage = response.body()?.message ?: "Login failed"
                                    }
                                } catch (e: Exception) {
                                    errorMessage = "An error occurred: ${e.message}"
                                } finally {
                                    isLoading = false
                                }
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp),
                        enabled = !isLoading && identity.isNotEmpty() && password.isNotEmpty(),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = PrimaryBlue,
                            contentColor = Color.White,
                            disabledContainerColor = PrimaryBlue.copy(alpha = 0.6f),
                            disabledContentColor = Color.White
                        )
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                        } else {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Fingerprint, contentDescription = null, modifier = Modifier.size(20.dp))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Login Securely", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Divider
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        HorizontalDivider(modifier = Modifier.weight(1f), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                        Text("Or", modifier = Modifier.padding(horizontal = 16.dp), fontSize = 12.sp, color = TextGray)
                        HorizontalDivider(modifier = Modifier.weight(1f), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Open New Account Button
                    OutlinedButton(
                        onClick = onRegisterClick,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp),
                        shape = RoundedCornerShape(12.dp),
                        border = BorderStroke(1.dp, PrimaryBlue),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = PrimaryBlue)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.PersonAdd, contentDescription = null, modifier = Modifier.size(20.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Open New Account", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(40.dp))

            // Footer Feature Items
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                FeatureItem("Secure Banking", "256-bit encryption\nto protect you", Icons.Outlined.Shield)
                FeatureItem("Instant Access", "Quick login to your\naccount", Icons.Outlined.Bolt)
                FeatureItem("24/7 Support", "We're here to\nhelp you", Icons.Outlined.HeadsetMic)
            }
            
            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}

@Composable
fun LoginInputField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    isPassword: Boolean = false,
    passwordVisible: Boolean = false,
    onVisibilityToggle: () -> Unit = {}
) {
    Column {
        Text(label, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Spacer(modifier = Modifier.height(8.dp))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(InputFieldBg)
                .border(1.dp, BorderColor, RoundedCornerShape(12.dp))
        ) {
            // Icon Prefix Box
            Surface(
                modifier = Modifier
                    .padding(start = 1.dp)
                    .size(54.dp),
                shape = RoundedCornerShape(11.dp),
                color = IconBoxBg.copy(alpha = 0.8f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = PrimaryBlue, modifier = Modifier.size(20.dp))
                }
            }
            
            TextField(
                value = value,
                onValueChange = onValueChange,
                placeholder = { Text(placeholder, color = Color.LightGray, fontSize = 15.sp) },
                visualTransformation = if (isPassword && !passwordVisible) PasswordVisualTransformation() else VisualTransformation.None,
                trailingIcon = if (isPassword) {
                    {
                        IconButton(onClick = onVisibilityToggle) {
                            Icon(
                                if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                contentDescription = null,
                                tint = Color.Gray,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                } else null,
                modifier = modifier.weight(1f),
                keyboardOptions = if (!isPassword) KeyboardOptions(keyboardType = KeyboardType.Email) else KeyboardOptions.Default,
                colors = TextFieldDefaults.colors(
                    focusedTextColor = Color.Black,
                    unfocusedTextColor = Color.Black,
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    disabledIndicatorColor = Color.Transparent,
                    cursorColor = PrimaryBlue
                ),
                singleLine = true
            )
        }
    }
}

@Composable
fun FeatureItem(title: String, sub: String, icon: ImageVector) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Surface(
            modifier = Modifier.size(40.dp),
            shape = CircleShape,
            color = IconBoxBg
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = PrimaryBlue, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(title, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = PrimaryBlue)
        Text(sub, fontSize = 9.sp, color = TextGray, textAlign = TextAlign.Center, lineHeight = 12.sp)
    }
}
