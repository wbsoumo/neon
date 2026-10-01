package com.my.deccanfinance

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.outlined.Help
import androidx.compose.material.icons.outlined.HelpOutline
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import android.annotation.SuppressLint
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withStyle
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import com.my.deccanfinance.ui.theme.DashPrimary
import java.util.concurrent.Executors

@Composable
fun BakingScreen(onBack: () -> Unit = {}, bakingViewModel: BakingViewModel = viewModel()) {
    val context = LocalContext.current
    val apiService = remember { ApiService.create(context) }
    val dataManager = remember { DataManager(context) }
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    
    val scanPayState by bakingViewModel.scanPayState.collectAsStateWithLifecycle()

    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
        )
    }
    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { granted ->
            hasCameraPermission = granted
        }
    )

    LaunchedEffect(key1 = true) {
        if (!hasCameraPermission) {
            launcher.launch(Manifest.permission.CAMERA)
        }
    }

    var torchEnabled by remember { mutableStateOf(false) }
    var camera: Camera? by remember { mutableStateOf(null) }
    var selectedTab by remember { mutableIntStateOf(0) } // 0 for Scan, 1 for My QR

    var showMpinDialog by remember { mutableStateOf(false) }
    var paymentAmount by remember { mutableStateOf("") }
    var paymentNote by remember { mutableStateOf("") }
    var recipientToPay by remember { mutableStateOf<ScannedUser?>(null) }
    var successfulPaymentResponse by remember { mutableStateOf<TransferPayoutResponse?>(null) }

    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent(),
        onResult = { uri: Uri? ->
            uri?.let {
                scanImageFromGallery(context, it) { data ->
                    handleScannedData(data, bakingViewModel, apiService, context)
                }
            }
        }
    )

    // Handle scanPayState changes
    LaunchedEffect(scanPayState) {
        when (val state = scanPayState) {
            is ScanPayState.UserDetailsLoaded -> {
                recipientToPay = state.user
            }
            is ScanPayState.PaymentSuccess -> {
                successfulPaymentResponse = TransferPayoutResponse(
                    success = true,
                    message = state.message,
                    transactionId = state.transactionId,
                    utrId = state.transactionId?.let { "UTR-$it" } ?: "N/A",
                    provider = "Scan & Pay",
                    beneficiary = BeneficiaryInfo(
                        name = recipientToPay?.fullName ?: "Unknown",
                        account = recipientToPay?.accountNumber ?: "",
                        ifsc = "DECCAN001"
                    ),
                    amount = paymentAmount.toDoubleOrNull() ?: 0.0,
                    status = "SUCCESS",
                    remarks = state.remarks ?: paymentNote,
                    newBalance = null
                )
                bakingViewModel.resetState()
                showMpinDialog = false
            }
            is ScanPayState.Error -> {
                Toast.makeText(context, state.message, Toast.LENGTH_LONG).show()
                bakingViewModel.resetState()
            }
            else -> {}
        }
    }

    // Handle torch changes
    LaunchedEffect(torchEnabled) {
        camera?.cameraControl?.enableTorch(torchEnabled)
    }

    if (successfulPaymentResponse != null) {
        PayoutTransactionDetailsScreen(
            response = successfulPaymentResponse!!,
            dataManager = dataManager,
            onBack = {
                successfulPaymentResponse = null
                recipientToPay = null
                paymentAmount = ""
                onBack()
            }
        )
    } else if (recipientToPay != null) {
        PaymentAmountScreen(
            recipient = recipientToPay!!,
            amount = paymentAmount,
            note = paymentNote,
            onAmountChange = { paymentAmount = it },
            onNoteChange = { paymentNote = it },
            onBack = { recipientToPay = null },
            onPay = { showMpinDialog = true }
        )
    } else {
        Scaffold(
            topBar = {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp)
                        .statusBarsPadding(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color(0xFF6366F1))
                    }
                    Text(
                        text = "Scan & Pay",
                        color = Color(0xFF1A1C3D),
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                    IconButton(onClick = { }) {
                        Icon(Icons.Outlined.HelpOutline, contentDescription = "Help", tint = Color(0xFF6366F1))
                    }
                }
            },
            containerColor = Color(0xFFF8F9FF)
        ) { paddingValues ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Tab Switcher
                Surface(
                    modifier = Modifier
                        .width(220.dp)
                        .height(48.dp),
                    shape = RoundedCornerShape(24.dp),
                    color = Color.White,
                    shadowElevation = 2.dp
                ) {
                    Row(
                        modifier = Modifier.fillMaxSize().padding(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight()
                                .clip(RoundedCornerShape(20.dp))
                                .background(if (selectedTab == 0) Color(0xFF6366F1).copy(alpha = 0.1f) else Color.Transparent)
                                .clickable { selectedTab = 0 },
                            contentAlignment = Alignment.Center
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.QrCodeScanner,
                                    contentDescription = null,
                                    tint = if (selectedTab == 0) Color(0xFF6366F1) else Color.Gray,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    "Scan",
                                    color = if (selectedTab == 0) Color(0xFF6366F1) else Color.Gray,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )
                            }
                        }
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight()
                                .clip(RoundedCornerShape(20.dp))
                                .background(if (selectedTab == 1) Color(0xFF6366F1).copy(alpha = 0.1f) else Color.Transparent)
                                .clickable { selectedTab = 1 },
                            contentAlignment = Alignment.Center
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.QrCode,
                                    contentDescription = null,
                                    tint = if (selectedTab == 1) Color(0xFF6366F1) else Color.Gray,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    "My QR",
                                    color = if (selectedTab == 1) Color(0xFF6366F1) else Color.Gray,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                if (selectedTab == 0) {
                    ScanSection(
                        hasPermission = hasCameraPermission,
                        onCameraReady = { camera = it },
                        torchEnabled = torchEnabled,
                        onQrScanned = { data -> handleScannedData(data, bakingViewModel, apiService, context) },
                        onTorchClick = { torchEnabled = !torchEnabled },
                        onGalleryClick = { galleryLauncher.launch("image/*") }
                    )

                    Spacer(modifier = Modifier.height(24.dp))

                    ManualEntryAndOptions(
                        manualInput = "",
                        onManualInputChange = { /* Not used here since it's local in component */ },
                        onManualSubmit = { bakingViewModel.getUserByAccount(apiService, it) },
                        apiService = apiService,
                        bakingViewModel = bakingViewModel
                    )
                } else {
                    MyQrSection(
                        accountNumber = userData["account_number"] as? String ?: "",
                        fullName = userData["full_name"] as? String ?: "",
                        phone = userData["phone"] as? String ?: ""
                    )
                }

                Spacer(modifier = Modifier.height(32.dp))
                
                // Bottom Banner
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp),
                    shape = RoundedCornerShape(16.dp),
                    color = Color(0xFFF5F6FF)
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            modifier = Modifier.size(48.dp),
                            shape = CircleShape,
                            color = Color.White
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.Shield, contentDescription = null, tint = Color(0xFF6366F1))
                            }
                        }
                        Spacer(modifier = Modifier.width(16.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Fast. Secure. Effortless.", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color(0xFF1A1C3D))
                            Text("Make payments in seconds using UPI - anytime, anywhere.", fontSize = 11.sp, color = Color.Gray)
                        }
                        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color(0xFF6366F1))
                    }
                }
                
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }

    if (showMpinDialog && recipientToPay != null) {
        MpinVerificationDialog(
            onDismiss = { showMpinDialog = false },
            onConfirm = { mpin ->
                bakingViewModel.sendMoney(
                    apiService,
                    recipientToPay!!.accountNumber,
                    paymentAmount.toDoubleOrNull() ?: 0.0,
                    mpin,
                    paymentNote
                )
            }
        )
    }

    if (scanPayState is ScanPayState.Loading) {
        Box(modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.5f)), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = Color.White)
        }
    }
}

@Composable
fun ScanSection(
    hasPermission: Boolean,
    onCameraReady: (Camera) -> Unit,
    torchEnabled: Boolean,
    onQrScanned: (String) -> Unit,
    onTorchClick: () -> Unit,
    onGalleryClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(400.dp)
            .padding(horizontal = 24.dp),
        shape = RoundedCornerShape(32.dp),
        color = Color.Black
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            if (hasPermission) {
                CameraPreview(
                    onCameraReady = onCameraReady,
                    torchEnabled = torchEnabled,
                    onQrScanned = onQrScanned
                )
            }
            
            // Card Content Overlay
            Column(
                modifier = Modifier.fillMaxSize().padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    "Scan any QR code to pay",
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    "Align QR code within the frame",
                    color = Color.White.copy(alpha = 0.7f),
                    fontSize = 12.sp
                )
                
                Spacer(modifier = Modifier.weight(1f))
                
                // Scanner Frame Overlay
                Box(
                    modifier = Modifier
                        .size(200.dp)
                        .border(2.dp, Color(0xFF6366F1).copy(alpha = 0.3f), RoundedCornerShape(24.dp))
                ) {
                    val color = Color(0xFF6366F1)
                    val thickness = 4.dp
                    val length = 32.dp
                    
                    // Corners
                    Box(modifier = Modifier.align(Alignment.TopStart).size(length, thickness).background(color, RoundedCornerShape(2.dp)))
                    Box(modifier = Modifier.align(Alignment.TopStart).size(thickness, length).background(color, RoundedCornerShape(2.dp)))
                    
                    Box(modifier = Modifier.align(Alignment.TopEnd).size(length, thickness).background(color, RoundedCornerShape(2.dp)))
                    Box(modifier = Modifier.align(Alignment.TopEnd).size(thickness, length).background(color, RoundedCornerShape(2.dp)))
                    
                    Box(modifier = Modifier.align(Alignment.BottomStart).size(length, thickness).background(color, RoundedCornerShape(2.dp)))
                    Box(modifier = Modifier.align(Alignment.BottomStart).size(thickness, length).background(color, RoundedCornerShape(2.dp)))
                    
                    Box(modifier = Modifier.align(Alignment.BottomEnd).size(length, thickness).background(color, RoundedCornerShape(2.dp)))
                    Box(modifier = Modifier.align(Alignment.BottomEnd).size(thickness, length).background(color, RoundedCornerShape(2.dp)))
                    
                    // Scanning line animation could be added here
                }
                
                Spacer(modifier = Modifier.weight(1f))

                // Action Buttons inside the black box
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceAround,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.clickable { onTorchClick() }) {
                        Surface(
                            modifier = Modifier.size(48.dp),
                            shape = CircleShape,
                            color = Color.White.copy(alpha = 0.15f)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(if (torchEnabled) Icons.Default.FlashOn else Icons.Default.FlashOff, contentDescription = "Torch", tint = Color.White)
                            }
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text("Torch", color = Color.White, fontSize = 11.sp)
                    }

                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.clickable { onGalleryClick() }) {
                        Surface(
                            modifier = Modifier.size(48.dp),
                            shape = CircleShape,
                            color = Color.White.copy(alpha = 0.15f)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.Image, contentDescription = "Gallery", tint = Color.White)
                            }
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text("Gallery", color = Color.White, fontSize = 11.sp)
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Security Banner
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = Color.White.copy(alpha = 0.1f),
                    modifier = Modifier.fillMaxWidth(0.9f)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(Icons.Default.VerifiedUser, contentDescription = null, tint = Color(0xFF6366F1), modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Column {
                            Text("100% Safe & Secure Payments", color = Color.White, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                            Text("Your payment details are protected", color = Color.White.copy(alpha = 0.7f), fontSize = 9.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ManualEntryAndOptions(
    manualInput: String,
    onManualInputChange: (String) -> Unit,
    onManualSubmit: (String) -> Unit,
    apiService: ApiService,
    bakingViewModel: BakingViewModel
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
    ) {
        Text(
            "Or pay using",
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF1A1C3D)
        )
        Spacer(modifier = Modifier.height(16.dp))
        
        var input by remember { mutableStateOf(manualInput) }
        OutlinedTextField(
            value = input,
            onValueChange = { input = it },
            placeholder = { Text("Enter Account Number", fontSize = 14.sp, color = Color.Gray) },
            textStyle = TextStyle(color = Color.Black, fontSize = 14.sp),
            leadingIcon = { Icon(Icons.Default.AccountBalance, contentDescription = null, tint = Color(0xFF6366F1)) },
            trailingIcon = { 
                IconButton(onClick = {
                    if (input.length >= 11) {
                        onManualSubmit(input)
                    } else {
                        // Show error
                    }
                }) {
                    Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color(0xFF6366F1))
                }
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            colors = OutlinedTextFieldDefaults.colors(
                focusedTextColor = Color.Black,
                unfocusedTextColor = Color.Black,
                focusedBorderColor = Color(0xFF6366F1),
                unfocusedBorderColor = Color.LightGray.copy(alpha = 0.5f),
                focusedContainerColor = Color.White,
                unfocusedContainerColor = Color.White
            )
        )

        Spacer(modifier = Modifier.height(20.dp))

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OptionCard(Icons.Default.AccountBalance, "Bank Transfer", "Account no. & IFSC", modifier = Modifier.weight(1f))
            OptionCard(Icons.Default.QrCode, "UPI ID", "Pay using UPI ID", modifier = Modifier.weight(1f))
            OptionCard(Icons.Default.Smartphone, "Mobile Number", "Pay using mobile no.", modifier = Modifier.weight(1f))
        }
    }
}

@Composable
fun OptionCard(icon: ImageVector, title: String, sub: String, modifier: Modifier) {
    Surface(
        modifier = modifier.height(100.dp),
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 1.dp
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(icon, contentDescription = null, tint = Color(0xFF6366F1), modifier = Modifier.size(24.dp))
            Spacer(modifier = Modifier.height(8.dp))
            Text(title, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1A1C3D), textAlign = TextAlign.Center)
            Text(sub, fontSize = 9.sp, color = Color.Gray, textAlign = TextAlign.Center)
        }
    }
}

@Composable
fun PaymentAmountScreen(
    recipient: ScannedUser,
    amount: String,
    note: String,
    onAmountChange: (String) -> Unit,
    onNoteChange: (String) -> Unit,
    onBack: () -> Unit,
    onPay: () -> Unit
) {
    val context = LocalContext.current
    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            Surface(color = Color.White, shadowElevation = 2.dp) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp)
                        .statusBarsPadding(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = DashPrimary)
                    }
                    Text(
                        text = "Pay",
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                    Spacer(modifier = Modifier.width(48.dp))
                }
            }
        },
        containerColor = Color.White,
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp)
                    .navigationBarsPadding(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Button(
                    onClick = {
                        if ((amount.toDoubleOrNull() ?: 0.0) > 0) onPay()
                        else Toast.makeText(context, "Please enter an amount", Toast.LENGTH_SHORT).show()
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = DashPrimary)
                ) {
                    Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Pay Securely", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(12.dp), tint = Color.Gray)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = buildAnnotatedString {
                            append("Your payment is safe and secure by ")
                            withStyle(style = SpanStyle(fontWeight = FontWeight.Bold)) {
                                append("Jio Pay")
                            }
                        },
                        fontSize = 11.sp,
                        color = Color.Gray
                    )
                }
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(scrollState)
                .padding(horizontal = 24.dp)
        ) {
            // Payee Card
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                shape = RoundedCornerShape(16.dp),
                color = Color(0xFFF9FAFF)
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        modifier = Modifier.size(56.dp),
                        shape = CircleShape,
                        color = Color(0xFFEEF2FF)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = recipient.fullName.split(" ").map { it.take(1) }.joinToString("").uppercase(),
                                fontSize = 20.sp,
                                fontWeight = FontWeight.Bold,
                                color = DashPrimary
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Payee", fontSize = 12.sp, color = Color.Gray)
                        Text(recipient.fullName, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        Text("UPI ID: ${recipient.accountNumber}@deccan", fontSize = 13.sp, color = Color.Gray)
                    }
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Surface(
                            modifier = Modifier.size(32.dp),
                            shape = CircleShape,
                            color = Color(0xFFDCFCE7)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.Verified, contentDescription = null, tint = Color(0xFF22C55E), modifier = Modifier.size(18.dp))
                            }
                        }
                        Text("Verified", fontSize = 10.sp, color = Color(0xFF22C55E), fontWeight = FontWeight.Bold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text("Enter Amount", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Gray)
            
            Spacer(modifier = Modifier.height(12.dp))

            // Amount Input Field
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(80.dp)
                    .border(1.dp, DashPrimary.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 16.dp),
                contentAlignment = Alignment.CenterStart
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("₹", fontSize = 32.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                    Spacer(modifier = Modifier.width(8.dp))
                    BasicTextField(
                        value = amount,
                        onValueChange = { if (it.isEmpty() || (it.all { char -> char.isDigit() || char == '.' } && it.count { c -> c == '.' } <= 1)) onAmountChange(it) },
                        textStyle = TextStyle(fontSize = 40.sp, fontWeight = FontWeight.Bold, color = Color.Black),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        cursorBrush = SolidColor(DashPrimary),
                        modifier = Modifier.fillMaxWidth(),
                        decorationBox = { innerTextField ->
                            if (amount.isEmpty()) {
                                Text("0.00", fontSize = 40.sp, fontWeight = FontWeight.Bold, color = Color.LightGray)
                            }
                            innerTextField()
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Amount in Words
            val amountInt = amount.toDoubleOrNull()?.toInt() ?: 0
            val words = if (amountInt > 0) "Rupees ${numberToWords(amountInt)} Only" else "Rupees Zero Only"
            Surface(
                color = Color(0xFFF0F2FF),
                shape = RoundedCornerShape(20.dp)
            ) {
                Text(
                    text = words,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp),
                    fontSize = 12.sp,
                    color = DashPrimary,
                    fontWeight = FontWeight.Medium
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text("Quick Amounts", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            
            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                listOf("100", "500", "1000", "2000").forEach { qAmount ->
                    Surface(
                        modifier = Modifier
                            .weight(1f)
                            .clickable { onAmountChange(qAmount) },
                        shape = RoundedCornerShape(8.dp),
                        border = borderStroke(1.dp, Color.LightGray.copy(alpha = 0.5f)),
                        color = Color.White
                    ) {
                        Text(
                            text = "₹$qAmount",
                            modifier = Modifier.padding(vertical = 12.dp),
                            textAlign = TextAlign.Center,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = DashPrimary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Add Note
            OutlinedTextField(
                value = note,
                onValueChange = onNoteChange,
                placeholder = { Text("Add a note (optional)", fontSize = 14.sp) },
                leadingIcon = { Icon(Icons.Default.ChatBubbleOutline, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp)) },
                trailingIcon = { Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = Color.Gray) },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    unfocusedBorderColor = Color.LightGray.copy(alpha = 0.5f),
                    focusedBorderColor = DashPrimary,
                    focusedTextColor = Color.Black,
                    unfocusedTextColor = Color.Black
                )
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Security Info
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                SecurityItem(Icons.Default.Shield, "Secure Payment", "Your payment is protected with 256-bit encryption")
                SecurityItem(Icons.Default.ElectricBolt, "Instant Transfer", "Money will be sent instantly to the recipient")
                SecurityItem(Icons.Default.AccountBalance, "Trusted by Millions", "Secure payments through UPI")
            }
            
            Spacer(modifier = Modifier.height(100.dp)) // Added space for bottom bar
        }
    }
}

@Composable
fun SecurityItem(icon: ImageVector, title: String, sub: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(40.dp),
            shape = CircleShape,
            color = Color(0xFFF5F6FF)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Text(sub, fontSize = 12.sp, color = Color.Gray)
        }
        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF22C55E), modifier = Modifier.size(20.dp))
    }
}

private fun borderStroke(width: androidx.compose.ui.unit.Dp, color: Color) = androidx.compose.foundation.BorderStroke(width, color)

fun handleScannedData(data: String?, viewModel: BakingViewModel, apiService: ApiService, context: Context) {
    if (data == null) return
    val map = parseQrCode(data)
    val accountNumber = map?.get("accountno")
    if (accountNumber != null) {
        viewModel.getUserByAccount(apiService, accountNumber)
    } else {
        Toast.makeText(context, "Invalid QR Code format", Toast.LENGTH_SHORT).show()
    }
}

fun parseQrCode(data: String?): Map<String, String>? {
    if (data == null) return null
    try {
        val map = mutableMapOf<String, String>()
        val parts = data.split("&")
        for (part in parts) {
            val pair = part.split("=")
            if (pair.size == 2) {
                map[pair[0]] = pair[1]
            }
        }
        return if (map.containsKey("accountno")) map else null
    } catch (e: Exception) {
        return null
    }
}

@Composable
fun CameraPreview(
    onCameraReady: (Camera) -> Unit,
    torchEnabled: Boolean,
    onQrScanned: (String) -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    val previewView = remember { PreviewView(context) }
    val cameraExecutor = remember { Executors.newSingleThreadExecutor() }
    
    var lastScannedData by remember { mutableStateOf("") }

    AndroidView(
        factory = { previewView },
        modifier = Modifier.fillMaxSize()
    ) { view ->
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            val preview = Preview.Builder().build().also {
                it.surfaceProvider = view.surfaceProvider
            }

            val barcodeScanner = BarcodeScanning.getClient()
            val imageAnalysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .also { analysis ->
                    analysis.setAnalyzer(cameraExecutor) { imageProxy ->
                        @SuppressLint("UnsafeOptInUsageError")
                        val mediaImage = imageProxy.image
                        if (mediaImage != null) {
                            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                            barcodeScanner.process(image)
                                .addOnSuccessListener { barcodes ->
                                    for (barcode in barcodes) {
                                        val rawValue = barcode.rawValue
                                        if (rawValue != null && rawValue != lastScannedData) {
                                            lastScannedData = rawValue
                                            onQrScanned(rawValue)
                                        }
                                    }
                                }
                                .addOnCompleteListener {
                                    imageProxy.close()
                                }
                        } else {
                            imageProxy.close()
                        }
                    }
                }

            try {
                cameraProvider.unbindAll()
                val camera = cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    imageAnalysis
                )
                onCameraReady(camera)
                camera.cameraControl.enableTorch(torchEnabled)
            } catch (e: Exception) {
                Log.e("CameraPreview", "Binding failed", e)
            }
        }, ContextCompat.getMainExecutor(context))
    }
}

@Composable
fun MyQrSection(accountNumber: String, fullName: String, phone: String) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(40.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Surface(
            modifier = Modifier.size(260.dp),
            shape = RoundedCornerShape(24.dp),
            color = Color.White,
            shadowElevation = 4.dp
        ) {
            Box(contentAlignment = Alignment.Center) {
                val qrData = "accountno=$accountNumber&name=$fullName&mobilenumber=$phone"
                val qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${Uri.encode(qrData)}"
                AsyncImage(
                    model = qrUrl,
                    contentDescription = "My QR Code",
                    modifier = Modifier.size(200.dp)
                )
            }
        }
        Spacer(modifier = Modifier.height(24.dp))
        Text("Your Personal QR Code", color = Color(0xFF1A1C3D), fontSize = 16.sp, fontWeight = FontWeight.Bold)
        Text("Share this to receive payments", color = Color.Gray, fontSize = 14.sp)
        Spacer(modifier = Modifier.height(8.dp))
        Text("A/C: $accountNumber", color = Color(0xFF1A1C3D), fontSize = 14.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
fun RecentScanItem(name: String, upi: String, amount: String, date: String, initialBg: Color) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(44.dp),
            shape = CircleShape,
            color = initialBg
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text(
                    name.split(" ").map { it.take(1) }.joinToString("").uppercase(),
                    color = Color(0xFF4B5563),
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
            }
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(name, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color.Black)
            Text(upi, fontSize = 11.sp, color = Color.Gray)
        }
        Column(horizontalAlignment = Alignment.End) {
            Text(amount, fontWeight = FontWeight.ExtraBold, fontSize = 14.sp, color = Color.Black)
            Text(date, fontSize = 10.sp, color = Color.Gray)
        }
    }
}

fun scanImageFromGallery(context: Context, uri: Uri, onResult: (String?) -> Unit) {
    try {
        val image = InputImage.fromFilePath(context, uri)
        val scanner = BarcodeScanning.getClient()
        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                if (barcodes.isNotEmpty()) {
                    onResult(barcodes[0].rawValue)
                } else {
                    onResult(null)
                }
            }
            .addOnFailureListener {
                Log.e("QRCode", "Gallery scan failed", it)
                onResult(null)
            }
    } catch (e: Exception) {
        Log.e("QRCode", "Error loading image", e)
        onResult(null)
    }
}
