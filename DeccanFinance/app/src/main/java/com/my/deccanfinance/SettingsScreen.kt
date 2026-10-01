package com.my.deccanfinance

import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch
import java.util.concurrent.Executors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onBack: () -> Unit,
    onSetLoginPin: () -> Unit,
    onSetMpin: () -> Unit,
    onRequestStatement: () -> Unit,
    onLogout: () -> Unit
) {
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    val fullName = userData["full_name"] as? String ?: "User"
    val accountNumber = userData["account_number"] as? String ?: "—"
    val isBiometricEnabled = userData["biometric_enabled"] as? Boolean ?: false
    val isLoginPinEnabled = userData["login_pin_enabled"] as? Boolean ?: false

    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }

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
                            snackbarHostState.showSnackbar("Error toggling biometrics: ${e.localizedMessage}")
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

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(
                            "Settings",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF1A1C1E)
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = DashPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DashBg)
            )
        },
        containerColor = DashBg,
        bottomBar = {
            ModernBottomNavForMore(onBack)
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
        ) {
            // Profile Header Section
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                shape = RoundedCornerShape(20.dp),
                color = Color.White.copy(alpha = 0.5f),
                border = BorderStroke(1.dp, Color(0xFFF0F0F0))
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        modifier = Modifier.size(60.dp),
                        shape = CircleShape,
                        color = DashPrimary.copy(alpha = 0.1f)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Default.Person, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(36.dp))
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(fullName, fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        Text(accountNumber, fontSize = 14.sp, color = Color.Gray)
                    }
                    Icon(Icons.Default.ChevronRight, contentDescription = null, tint = DashPrimary)
                }
            }

            // Security Section
            SettingsCategoryTitle("Security")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color.White
            ) {
                Column {
                    SettingsItemWithSwitch(
                        Icons.Outlined.VerifiedUser, 
                        "Login PIN", 
                        "Enable secure 4 digit PIN login",
                        checked = isLoginPinEnabled,
                        onCheckedChange = { toggleLoginPin(it) }
                    )
                    SettingsDivider()
                    SettingsItem(
                        icon = Icons.Outlined.Lock, 
                        title = "Transaction PIN", 
                        subtitle = "Change your 4 digit transaction PIN",
                        onClick = onSetMpin
                    )
                    SettingsDivider()
                    SettingsItemWithSwitch(
                        Icons.Outlined.Fingerprint, 
                        "Biometric Login", 
                        "Use fingerprint for login",
                        checked = isBiometricEnabled,
                        onCheckedChange = { toggleBiometric() }
                    )
                    SettingsDivider()
                    SettingsItem(Icons.Outlined.PhonelinkSetup, "Manage Devices", "View and manage devices logged in")
                    SettingsDivider()
                    SettingsItem(Icons.Outlined.Shield, "Security Center", "Tips and tools to keep your account secure")
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Preferences Section
            SettingsCategoryTitle("Preferences")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color.White
            ) {
                Column {
                    SettingsItem(Icons.Outlined.Notifications, "Notifications", "Manage alerts and notifications")
                    SettingsDivider()
                    SettingsItem(Icons.Outlined.Visibility, "Display Preferences", "Set language, currency & more")
                    SettingsDivider()
                    SettingsItem(Icons.Outlined.CurrencyRupee, "Account Preferences", "Manage account display name & other settings")
                    SettingsDivider()
                    SettingsItem(
                        icon = Icons.Outlined.FileDownload,
                        title = "Statement & Documents",
                        subtitle = "Manage e-statements and document preferences",
                        onClick = onRequestStatement
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Others Section
            SettingsCategoryTitle("Others")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color.White
            ) {
                Column {
                    SettingsItem(Icons.AutoMirrored.Outlined.HelpOutline, "Help & Support", "Get help, raise a request or view FAQs")
                    SettingsDivider()
                    SettingsItem(Icons.Outlined.Info, "About the App", "Version, terms & conditions and more")
                    SettingsDivider()
                    SettingsItem(
                        Icons.AutoMirrored.Outlined.Logout, 
                        "Logout", 
                        "Securely logout from your account",
                        iconTint = Color.Red,
                        onClick = onLogout
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
fun SettingsCategoryTitle(title: String) {
    Text(
        text = title,
        fontSize = 14.sp,
        fontWeight = FontWeight.Bold,
        color = Color.Gray,
        modifier = Modifier.padding(start = 4.dp, bottom = 8.dp, top = 8.dp)
    )
}

@Composable
fun SettingsItemWithSwitch(
    icon: ImageVector,
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    iconTint: Color = DashPrimary
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(40.dp),
            shape = RoundedCornerShape(10.dp),
            color = iconTint.copy(alpha = 0.1f)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Text(subtitle, fontSize = 12.sp, color = Color.Gray)
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

@Composable
fun SettingsItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    statusText: String? = null,
    iconTint: Color = DashPrimary,
    onClick: () -> Unit = {}
) {
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
            color = iconTint.copy(alpha = 0.1f)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Text(subtitle, fontSize = 12.sp, color = Color.Gray)
        }
        if (statusText != null) {
            Text(statusText, fontSize = 12.sp, color = Color(0xFF10B981), fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 8.dp))
        }
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.LightGray, modifier = Modifier.size(20.dp))
    }
}

@Composable
fun SettingsDivider() {
    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color(0xFFF3F4F6))
}

@Composable
fun ModernBottomNavForMore(onHomeClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(90.dp),
        color = Color.White,
        shadowElevation = 16.dp
    ) {
        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            NavItemForMore(Icons.Default.Home, "Home", isSelected = false, onClick = onHomeClick)
            NavItemForMore(Icons.Default.AccountBalanceWallet, "Accounts", isSelected = false)
            
            Box(contentAlignment = Alignment.Center, modifier = Modifier.offset(y = (-15).dp)) {
                Surface(
                    onClick = { /* Already in settings */ },
                    modifier = Modifier.size(60.dp),
                    shape = CircleShape,
                    color = DashPrimary,
                    shadowElevation = 8.dp
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.QrCodeScanner, contentDescription = null, tint = Color.White, modifier = Modifier.size(28.dp))
                    }
                }
            }
            
            NavItemForMore(Icons.Default.Timeline, "Activity", isSelected = false)
            NavItemForMore(Icons.Default.GridView, "More", isSelected = true)
        }
    }
}

@Composable
fun NavItemForMore(icon: ImageVector, label: String, isSelected: Boolean, onClick: () -> Unit = {}) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.clickable { onClick() }) {
        Icon(
            icon,
            contentDescription = label,
            tint = if (isSelected) DashPrimary else Color.LightGray,
            modifier = Modifier.size(24.dp)
        )
        Text(label, fontSize = 10.sp, color = if (isSelected) DashPrimary else Color.LightGray, fontWeight = FontWeight.Bold)
    }
}
