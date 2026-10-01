package com.my.deccanfinance

import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch
import java.text.DecimalFormat
import java.util.concurrent.Executors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountDetailsScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onSetLoginPin: () -> Unit,
    onTransferClick: () -> Unit,
    onReceiveClick: () -> Unit,
    onSettingsClick: () -> Unit,
    onRequestStatement: () -> Unit,
    onBack: () -> Unit
) {
    var userDetails by remember { mutableStateOf<UserDetails?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var isBalanceVisible by remember { mutableStateOf(false) }
    
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    val isBiometricEnabled = userData["biometric_enabled"] as? Boolean ?: false
    val isLoginPinEnabled = userData["login_pin_enabled"] as? Boolean ?: false

    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current
    val snackbarHostState = remember { SnackbarHostState() }

    fun copyToClipboard(text: String, label: String) {
        clipboardManager.setText(AnnotatedString(text))
        scope.launch {
            snackbarHostState.showSnackbar("$label copied to clipboard")
        }
    }

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
        try {
            val response = apiService.getUserDetails()
            if (response.isSuccessful && response.body()?.success == true) {
                userDetails = response.body()?.user
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            isLoading = false
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(
                            "Account Details",
                            fontSize = 18.sp,
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
                actions = {
                    IconButton(onClick = { /* More options */ }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "More", tint = Color.LightGray)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DashBg)
            )
        },
        containerColor = DashBg
    ) { padding ->
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DashPrimary)
            }
        } else {
            Column(
                modifier = Modifier
                    .padding(padding)
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
            ) {
                // Indigo Gradient Card
                AccountHeaderCard(
                    userDetails = userDetails,
                    isBalanceVisible = isBalanceVisible,
                    onToggleBalance = { isBalanceVisible = !isBalanceVisible },
                    onCopyAccount = {
                        userDetails?.accountNumber?.let { copyToClipboard(it, "Account Number") }
                    },
                    onRequestStatement = onRequestStatement
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Quick Action Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    QuickActionItem(Icons.Outlined.FileUpload, "Transfer", "Money", onClick = onTransferClick)
                    QuickActionItem(Icons.Outlined.FileDownload, "Receive", "Money", onClick = onReceiveClick)
                    QuickActionItem(Icons.Outlined.QrCodeScanner, "Scan & Pay", "From this account", onClick = { /* Navigate to scan */ })
                    QuickActionItem(Icons.Outlined.Settings, "Manage", "Account", onClick = onSettingsClick)
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Account Information
                Text("Account Information", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                Spacer(modifier = Modifier.height(16.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, Color(0xFFF0F0F0))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        InfoRow(Icons.Default.CreditCard, "Account Type", userDetails?.accountType ?: "Savings Account")
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        InfoRow(Icons.Default.AccountBalance, "Bank Name", "NBFC")
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        InfoRow(Icons.Default.Person, "Account Holder Name", userDetails?.fullName ?: "—")
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        InfoRowWithCopy(Icons.Default.CreditCard, "Account Number", userDetails?.accountNumber ?: "—") {
                            userDetails?.accountNumber?.let { copyToClipboard(it, "Account Number") }
                        }
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        InfoRowWithCopy(Icons.Default.TableChart, "IFSC Code", "NBFC0001234") {
                            copyToClipboard("NBFC0001234", "IFSC Code")
                        }
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        InfoRow(Icons.Default.LocationOn, "Branch Name", "Chennai, Tamil Nadu")
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        InfoRow(Icons.Default.CalendarToday, "Account Opened On", formatCreatedAt(userDetails?.createdAt))
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        InfoRow(Icons.Default.Phone, "Contact Number", "1800 123 4567", valueColor = DashPrimary)
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Account Limits
                Text("Account Limits", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                Spacer(modifier = Modifier.height(16.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, Color(0xFFF0F0F0))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        LimitRow(Icons.AutoMirrored.Filled.Send, "Daily Transfer Limit", "₹ 2,00,000.00")
                        HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        LimitRow(Icons.AutoMirrored.Filled.Send, "Daily Remaining Limit", "₹ 2,00,000.00")
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Security Settings
                Text("Security Settings", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                Spacer(modifier = Modifier.height(16.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, Color(0xFFF0F0F0))
                ) {
                    Column {
                        SecurityToggleRow(
                            Icons.Outlined.VerifiedUser, 
                            "Login PIN", 
                            isLoginPinEnabled, 
                            onCheckedChange = { toggleLoginPin(it) }
                        )
                        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color(0xFFF0F0F0))
                        SecurityToggleRow(
                            Icons.Outlined.Fingerprint, 
                            "Biometric Login", 
                            isBiometricEnabled, 
                            onCheckedChange = { toggleBiometric() }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Security Footer
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    color = Color(0xFFF8F9FF)
                ) {
                    Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Outlined.Shield, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(24.dp))
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text("Your account is secure", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            Text("We use industry-standard security to protect your account and transactions.", fontSize = 11.sp, color = Color.Gray)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
fun SecurityToggleRow(
    icon: ImageVector,
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
        Spacer(modifier = Modifier.width(12.dp))
        Text(label, fontSize = 13.sp, color = Color.Gray, modifier = Modifier.weight(1f))
        Switch(
            checked = checked, 
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(checkedTrackColor = DashPrimary)
        )
    }
}

@Composable
fun AccountHeaderCard(
    userDetails: UserDetails?,
    isBalanceVisible: Boolean,
    onToggleBalance: () -> Unit,
    onCopyAccount: () -> Unit,
    onRequestStatement: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp),
        shape = RoundedCornerShape(24.dp),
        color = Color.Transparent // Background handled by Modifier
    ) {
        Box(modifier = Modifier.fillMaxSize().background(CardGradient)) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    // Currency Chip
                    Surface(
                        color = Color.White.copy(alpha = 0.2f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("\uD83C\uDDEE\uD83C\uDDF3 ", fontSize = 14.sp)
                            Text(
                                "Indian Rupee",
                                color = Color.White,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }

                    Column(horizontalAlignment = Alignment.End) {
                        Text("NBFC", color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                        Text(
                            userDetails?.accountType ?: "Savings Account",
                            color = Color.White.copy(alpha = 0.8f),
                            fontSize = 12.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Available Balance", color = Color.White.copy(alpha = 0.8f), fontSize = 12.sp)
                    Spacer(modifier = Modifier.width(8.dp))
                    Icon(
                        imageVector = if (isBalanceVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier
                            .size(16.dp)
                            .clickable { onToggleBalance() }
                    )
                }

                Text(
                    text = if (isBalanceVisible) "₹ ${
                        DecimalFormat("#,##,##0.00").format(
                            userDetails?.balance ?: 0.0
                        )
                    }" else "₹ ••••••••",
                    color = Color.White,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Bottom
                ) {
                    Column {
                        Text(
                            "Account Number",
                            color = Color.White.copy(alpha = 0.8f),
                            fontSize = 10.sp
                        )
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                userDetails?.accountNumber ?: "—",
                                color = Color.White,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Icon(
                                Icons.Default.ContentCopy,
                                contentDescription = "Copy",
                                tint = Color.White,
                                modifier = Modifier
                                    .size(14.dp)
                                    .clickable { onCopyAccount() }
                            )
                        }
                    }

                    Surface(
                        onClick = onRequestStatement,
                        color = Color.White.copy(alpha = 0.2f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Description,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                "Request Statement",
                                color = Color.White,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(
                                Icons.Default.ChevronRight,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(14.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun QuickActionItem(icon: ImageVector, title: String, subtitle: String, onClick: () -> Unit = {}) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally, 
        modifier = Modifier.width(80.dp).clickable { onClick() }
    ) {
        Surface(
            modifier = Modifier.size(48.dp),
            shape = RoundedCornerShape(14.dp),
            color = Color(0xFFF5F6FF)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = title, tint = DashPrimary, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(title, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Text(subtitle, fontSize = 10.sp, color = Color.Gray, textAlign = TextAlign.Center)
    }
}

@Composable
fun InfoRow(icon: ImageVector, label: String, value: String, valueColor: Color = Color.Black) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
        Spacer(modifier = Modifier.width(12.dp))
        Text(label, fontSize = 13.sp, color = Color.Gray, modifier = Modifier.weight(1f))
        Text(value, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = valueColor)
    }
}

@Composable
fun InfoRowWithCopy(icon: ImageVector, label: String, value: String, onCopy: () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
        Spacer(modifier = Modifier.width(12.dp))
        Text(label, fontSize = 13.sp, color = Color.Gray, modifier = Modifier.weight(1f))
        Text(value, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Spacer(modifier = Modifier.width(8.dp))
        Icon(
            Icons.Default.ContentCopy,
            contentDescription = "Copy",
            tint = DashPrimary,
            modifier = Modifier
                .size(16.dp)
                .clickable { onCopy() }
        )
    }
}

@Composable
fun LimitRow(icon: ImageVector, label: String, value: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Surface(modifier = Modifier.size(32.dp), shape = CircleShape, color = Color(0xFFF5F6FF)) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(16.dp))
            }
        }
        Spacer(modifier = Modifier.width(12.dp))
        Text(label, fontSize = 13.sp, color = Color.Gray, modifier = Modifier.weight(1f))
        Text(value, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
    }
}

fun formatCreatedAt(createdAt: String?): String {
    if (createdAt == null) return "—"
    return try {
        // Assuming format like "2023-05-12 10:00:00"
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
        val date = sdf.parse(createdAt)
        java.text.SimpleDateFormat("dd MMM yyyy", java.util.Locale.getDefault()).format(date!!)
    } catch (e: Exception) {
        createdAt
    }
}
