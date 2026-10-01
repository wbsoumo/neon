package com.my.deccanfinance

import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import coil.compose.AsyncImage
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch
import java.util.concurrent.Executors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onBack: () -> Unit,
    onUpdateProfileClick: () -> Unit,
    onSetLoginPin: () -> Unit,
    onSetMpin: () -> Unit,
    onNotificationsClick: () -> Unit,
    onLogout: () -> Unit
) {
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    var userDetails by remember { mutableStateOf<UserDetails?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }

    val isBiometricEnabled = userData["biometric_enabled"] as? Boolean ?: false
    val isLoginPinEnabled = userData["login_pin_enabled"] as? Boolean ?: false

    val name = userDetails?.fullName ?: (userData["full_name"] as? String) ?: "Raju Rastogi"
    val phone = userDetails?.phone ?: (userData["phone"] as? String) ?: "9876543210"
    val email = userDetails?.email ?: (userData["email"] as? String) ?: "raju@rastogi.com"
    val appId = (userData["app_id"] as? String) ?: "50199977461"

    fun toggleLoginPin(enabled: Boolean) {
        if (!enabled) {
            scope.launch {
                try {
                    val response = apiService.toggleLoginSettings(
                        ToggleLoginSettingsRequest(pinLoginEnabled = false)
                    )
                    if (response.isSuccessful && response.body()?.success == true) {
                        dataManager.setLoginPinEnabled(false)
                        snackbarHostState.showSnackbar("Login PIN disabled")
                    }
                } catch (e: Exception) {
                    snackbarHostState.showSnackbar("Error disabling PIN")
                }
            }
        } else {
            onSetLoginPin()
        }
    }

    fun toggleBiometric() {
        val fragmentActivity = context as? FragmentActivity
        if (fragmentActivity == null) {
            scope.launch { snackbarHostState.showSnackbar("Biometric initialization failed") }
            return
        }

        val executor = ContextCompat.getMainExecutor(context)
        val biometricPrompt = BiometricPrompt(
            fragmentActivity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    scope.launch {
                        try {
                            val newStatus = !isBiometricEnabled
                            val response = apiService.toggleLoginSettings(
                                ToggleLoginSettingsRequest(biometricLoginEnabled = newStatus)
                            )
                            if (response.isSuccessful && response.body()?.success == true) {
                                dataManager.setBiometricEnabled(newStatus)
                                if (newStatus) {
                                    apiService.registerBiometric(RegisterBiometricRequest("token-99497551"))
                                }
                                snackbarHostState.showSnackbar("Biometric login ${if (newStatus) "enabled" else "disabled"}")
                            } else {
                                snackbarHostState.showSnackbar(response.body()?.message ?: "Failed to update biometric settings")
                            }
                        } catch (e: Exception) {
                            snackbarHostState.showSnackbar("Error toggling biometrics")
                        }
                    }
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    scope.launch {
                        if (errorCode != BiometricPrompt.ERROR_USER_CANCELED && errorCode != BiometricPrompt.ERROR_NEGATIVE_BUTTON) {
                            snackbarHostState.showSnackbar("Biometric error: $errString")
                        }
                    }
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Verification")
            .setSubtitle("Confirm your identity to toggle biometric login")
            .setNegativeButtonText("Cancel")
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    LaunchedEffect(Unit) {
        scope.launch {
            try {
                val response = apiService.getUserDetails()
                if (response.isSuccessful) {
                    val user = response.body()?.user
                    userDetails = user
                    user?.let { dataManager.saveUserData(it) }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isLoading = false
            }
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(
                            "My Account",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF1A1C1E)
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = DashPrimary
                        )
                    }
                },
                actions = {
                    Box(modifier = Modifier.padding(end = 8.dp)) {
                        IconButton(onClick = onNotificationsClick) {
                            Icon(
                                Icons.Outlined.Notifications,
                                contentDescription = "Notifications",
                                tint = Color.Black
                            )
                        }
                        Box(
                            modifier = Modifier
                                .size(16.dp)
                                .clip(CircleShape)
                                .background(Color.Red)
                                .align(Alignment.TopEnd)
                                .offset(x = (-8).dp, y = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("3", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                        }
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
                .padding(16.dp)
        ) {
            // Profile Header Card
            ProfileHeaderCard(
                name = name,
                appId = appId,
                onEditClick = onUpdateProfileClick
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Personal Information Section
            ProfileSectionHeader("Personal Information")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color.White
            ) {
                Column {
                    ProfileInfoItem(
                        icon = Icons.Outlined.Person,
                        label = "Full Name",
                        value = name,
                        onClick = onUpdateProfileClick
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    ProfileInfoItem(
                        icon = Icons.Outlined.Smartphone,
                        label = "Phone Number",
                        value = phone,
                        onClick = onUpdateProfileClick
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    ProfileInfoItem(
                        icon = Icons.Outlined.Email,
                        label = "Email Address",
                        value = email,
                        onClick = onUpdateProfileClick
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Account & Security Section
            ProfileSectionHeader("Account & Security")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color.White
            ) {
                Column {
                    ProfileToggleItem(
                        icon = Icons.Outlined.VerifiedUser,
                        iconBg = Color(0xFFE8F5E9),
                        iconTint = Color(0xFF4CAF50),
                        title = "Login PIN",
                        subtitle = "Enable secure 4 digit PIN login",
                        checked = isLoginPinEnabled,
                        onCheckedChange = { toggleLoginPin(it) }
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    ProfileActionItem(
                        icon = Icons.Outlined.Shield,
                        iconBg = Color(0xFFE8F5E9),
                        iconTint = Color(0xFF4CAF50),
                        title = "Change Login PIN",
                        subtitle = "Change your 4 digit login PIN",
                        onClick = onSetLoginPin
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    ProfileActionItem(
                        icon = Icons.Outlined.Lock,
                        iconBg = Color(0xFFE3F2FD),
                        iconTint = Color(0xFF2196F3),
                        title = "Change Transaction PIN",
                        subtitle = "Change your 4 digit transaction PIN",
                        onClick = onSetMpin
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    ProfileToggleItem(
                        icon = Icons.Outlined.Fingerprint,
                        iconBg = Color(0xFFE8EAF6),
                        iconTint = Color(0xFF3F51B5),
                        title = "Biometric Login",
                        subtitle = "Use fingerprint to login to the app",
                        checked = isBiometricEnabled,
                        onCheckedChange = { toggleBiometric() }
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    ProfileActionItem(
                        icon = Icons.Outlined.Smartphone,
                        iconBg = Color(0xFFFFF3E0),
                        iconTint = Color(0xFFFF9800),
                        title = "Manage Devices",
                        subtitle = "View and manage your devices"
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Preferences Section
            ProfileSectionHeader("Preferences")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color.White
            ) {
                Column {
                    ProfileActionItem(
                        icon = Icons.Outlined.MonetizationOn,
                        iconBg = Color(0xFFF3E5F5),
                        iconTint = Color(0xFF9C27B0),
                        title = "Display Preferences",
                        subtitle = "Manage how amounts are shown"
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    ProfileActionItem(
                        icon = Icons.Outlined.Notifications,
                        iconBg = Color(0xFFE8EAF6),
                        iconTint = Color(0xFF3F51B5),
                        title = "Notifications",
                        subtitle = "Manage account alerts and updates",
                        onClick = onNotificationsClick
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))

            // Logout Section
            Surface(
                modifier = Modifier.fillMaxWidth().clickable { onLogout() },
                shape = RoundedCornerShape(16.dp),
                color = Color.White
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        modifier = Modifier.size(40.dp),
                        shape = RoundedCornerShape(10.dp),
                        color = Color(0xFFFFEBEE)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.AutoMirrored.Outlined.Logout, contentDescription = null, tint = Color.Red, modifier = Modifier.size(20.dp))
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Logout", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Red)
                        Text("Securely logout from your account", fontSize = 11.sp, color = Color.Gray)
                    }
                    Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.Red, modifier = Modifier.size(20.dp))
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
fun ProfileHeaderCard(name: String, appId: String, onEditClick: () -> Unit) {
    val clipboardManager = LocalClipboardManager.current
    val context = LocalContext.current

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(180.dp),
        shape = RoundedCornerShape(24.dp),
        color = Color.Transparent
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Brush.linearGradient(listOf(Color(0xFF5E5CE6), Color(0xFF9F5AFE))))
        ) {
            // Background circles pattern
            Canvas(modifier = Modifier.fillMaxSize()) {
                drawCircle(
                    color = Color.White.copy(alpha = 0.1f),
                    radius = 100.dp.toPx(),
                    center = center.copy(x = size.width * 0.8f, y = size.height * 0.2f)
                )
                drawCircle(
                    color = Color.White.copy(alpha = 0.05f),
                    radius = 150.dp.toPx(),
                    center = center.copy(x = size.width * 0.9f, y = size.height * 0.8f)
                )
            }

            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Avatar
                Box {
                    Surface(
                        modifier = Modifier.size(90.dp),
                        shape = CircleShape,
                        color = Color.White,
                        border = BorderStroke(2.dp, Color.White.copy(alpha = 0.5f))
                    ) {
                        AsyncImage(
                            model = "file:///android_asset/icon.jpeg",
                            contentDescription = "Profile",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = androidx.compose.ui.layout.ContentScale.Crop
                        )
                    }
                    Surface(
                        modifier = Modifier
                            .size(28.dp)
                            .align(Alignment.BottomEnd)
                            .clickable { onEditClick() },
                        shape = CircleShape,
                        color = Color.White,
                        shadowElevation = 4.dp
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                Icons.Default.Edit,
                                contentDescription = "Edit",
                                modifier = Modifier.size(14.dp),
                                tint = Color.Black
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.width(20.dp))

                // Info
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            name,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(
                            Icons.Default.CheckCircle,
                            contentDescription = "Verified",
                            tint = Color.White,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            appId,
                            fontSize = 14.sp,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Icon(
                            Icons.Default.ContentCopy,
                            contentDescription = "Copy",
                            tint = Color.White.copy(alpha = 0.8f),
                            modifier = Modifier.size(14.dp).clickable { 
                                clipboardManager.setText(AnnotatedString(appId))
                                android.widget.Toast.makeText(context, "App ID copied", android.widget.Toast.LENGTH_SHORT).show()
                            }
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Surface(
                        color = Color.White.copy(alpha = 0.15f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Column(modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)) {
                            Text("Account Type", fontSize = 10.sp, color = Color.White.copy(alpha = 0.7f))
                            Text("NBFC Savings Account", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ProfileSectionHeader(title: String) {
    Text(
        text = title,
        fontSize = 14.sp,
        fontWeight = FontWeight.Bold,
        color = Color.Gray,
        modifier = Modifier.padding(bottom = 12.dp)
    )
}

@Composable
fun ProfileInfoItem(icon: ImageVector, label: String, value: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(40.dp),
            shape = RoundedCornerShape(10.dp),
            color = Color(0xFFF5F6FF)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(label, fontSize = 11.sp, color = Color.Gray)
            Text(value, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        }
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.Black, modifier = Modifier.size(20.dp))
    }
}

@Composable
fun ProfileActionItem(icon: ImageVector, iconBg: Color, iconTint: Color, title: String, subtitle: String, onClick: () -> Unit = {}) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(40.dp),
            shape = RoundedCornerShape(10.dp),
            color = iconBg
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Text(subtitle, fontSize = 11.sp, color = Color.Gray)
        }
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.Black, modifier = Modifier.size(20.dp))
    }
}

@Composable
fun ProfileToggleItem(icon: ImageVector, iconBg: Color, iconTint: Color, title: String, subtitle: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(40.dp),
            shape = RoundedCornerShape(10.dp),
            color = iconBg
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Text(subtitle, fontSize = 11.sp, color = Color.Gray)
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = DashPrimary,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = Color.Gray.copy(alpha = 0.5f)
            )
        )
    }
}
