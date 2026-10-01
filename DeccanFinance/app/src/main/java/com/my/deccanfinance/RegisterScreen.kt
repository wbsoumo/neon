package com.my.deccanfinance

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.GenericShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import coil.compose.AsyncImage
import java.io.ByteArrayOutputStream
import java.io.InputStream
import android.graphics.Canvas as AndroidCanvas
import android.graphics.Paint as AndroidPaint
import androidx.compose.ui.graphics.asAndroidPath
import androidx.core.content.ContextCompat
import com.my.deccanfinance.ui.theme.NavyDark
import kotlinx.coroutines.launch

// Colors defined in LoginScreen or here for consistency
val TextSecondary = Color(0xFF6B7280)
val InputBg = Color(0xFFF9FAFB)

@Composable
fun RegisterScreen(apiService: ApiService, dataManager: DataManager, onRegisterSuccess: () -> Unit, onBack: () -> Unit) {
    val context = LocalContext.current
    var currentStep by remember { mutableIntStateOf(0) }
    var accountType by remember { mutableStateOf("") }

    // Form Data
    var fullName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var mobile by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var panNumber by remember { mutableStateOf("") }
    var aadhaarNumber by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    
    // Savings Specific
    var dob by remember { mutableStateOf("") }
    var gender by remember { mutableStateOf("") }
    var initialDeposit by remember { mutableStateOf("") }
    
    // Current Specific
    var businessName by remember { mutableStateOf("") }
    var gstNo by remember { mutableStateOf("") }
    var monthlyTurnover by remember { mutableStateOf("") }

    // Media Data (Base64)
    var portraitBase64 by remember { mutableStateOf("") }
    var panBase64 by remember { mutableStateOf("") }
    var aadhaarBase64 by remember { mutableStateOf("") }
    var signatureBase64 by remember { mutableStateOf("") }

    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BgLight)
    ) {
        // Background Illustration
        if (currentStep == 0) {
            AsyncImage(
                model = "file:///android_asset/loginbg.png",
                contentDescription = null,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(280.dp),
                contentScale = ContentScale.FillWidth
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            // Top Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp, start = 12.dp, end = 12.dp, bottom = 16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onBack) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = NavyDark)
                }
                Text(
                    "Open Account",
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = NavyDark
                )
                Spacer(modifier = Modifier.width(48.dp))
            }

            if (currentStep > 0) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 20.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(0.8f),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        StepCircle(1, currentStep >= 1)
                        StepCircle(2, currentStep >= 2)
                        StepCircle(3, currentStep >= 3)
                    }
                }
            } else {
                Spacer(modifier = Modifier.height(80.dp))
            }

            Card(
                modifier = Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(topStart = 40.dp, topEnd = 40.dp)),
                shape = RoundedCornerShape(topStart = 40.dp, topEnd = 40.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 24.dp, vertical = 32.dp)
                ) {
                    if (errorMessage != null) {
                        Text(
                            errorMessage!!,
                            color = Color.Red,
                            fontSize = 12.sp,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                    }
                    when (currentStep) {
                        0 -> AccountTypeSelection(onSelected = { 
                            accountType = it
                            currentStep = 1
                        })
                        1 -> CommonDetailsStep(
                            fullName, { fullName = it },
                            email, { email = it },
                            mobile, { mobile = it },
                            address, { address = it },
                            password, { password = it },
                            onNext = { currentStep = 2 }
                        )
                        2 -> if (accountType == "SAVINGS") {
                            SavingsDetailsStep(
                                dob, { dob = it },
                                gender, { gender = it },
                                initialDeposit, { initialDeposit = it },
                                onNext = { currentStep = 3 },
                                onBack = { currentStep = 1 }
                            )
                        } else {
                            CurrentDetailsStep(
                                businessName, { businessName = it },
                                gstNo, { gstNo = it },
                                monthlyTurnover, { monthlyTurnover = it },
                                onNext = { currentStep = 3 },
                                onBack = { currentStep = 1 }
                            )
                        }
                        3 -> VerificationFlow(
                            panNumber, { panNumber = it },
                            aadhaarNumber, { aadhaarNumber = it },
                            onPhotoCaptured = { portraitBase64 = it },
                            onPanCaptured = { panBase64 = it },
                            onAadhaarCaptured = { aadhaarBase64 = it },
                            onSignatureCaptured = { signatureBase64 = it },
                            onComplete = {
                                isLoading = true
                                errorMessage = null
                                scope.launch {
                                    try {
                                        val request = RegisterRequest(
                                            accountType = accountType,
                                            fullName = fullName,
                                            email = email,
                                            phone = mobile,
                                            address = address,
                                            nationalId = panNumber,
                                            aadhaarNumber = aadhaarNumber,
                                            password = password,
                                            dob = if (accountType == "SAVINGS") dob else null,
                                            gender = if (accountType == "SAVINGS") gender else null,
                                            initialDeposit = if (accountType == "SAVINGS") initialDeposit.toDoubleOrNull() else null,
                                            businessName = if (accountType == "CURRENT") businessName else null,
                                            businessRegNo = if (accountType == "CURRENT") gstNo else null,
                                            expectedTurnover = if (accountType == "CURRENT") monthlyTurnover.toDoubleOrNull() else null,
                                            signatureData = "data:image/jpeg;base64,$signatureBase64",
                                            portraitData = "data:image/jpeg;base64,$portraitBase64",
                                            docPanData = "data:image/jpeg;base64,$panBase64",
                                            docAadhaarData = "data:image/jpeg;base64,$aadhaarBase64"
                                        )
                                        val response = apiService.register(request)
                                        if (response.isSuccessful && response.body()?.success == true) {
                                            // Save basic data locally so Dashboard shows Review screen
                                            dataManager.saveStatusDirectly("PENDING")
                                            val appId = response.body()?.appId
                                            if (appId != null) {
                                                dataManager.saveAppIdDirectly(appId)
                                            }
                                            
                                            // Clear session so next launch asks for login
                                            dataManager.clearSession(context)

                                            onRegisterSuccess()
                                        } else {
                                            errorMessage = response.body()?.message ?: "Registration failed"
                                        }
                                    } catch (e: Exception) {
                                        errorMessage = "Error: ${e.message}"
                                    } finally {
                                        isLoading = false
                                    }
                                }
                            },
                            onBack = { currentStep = 2 }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun AccountTypeSelection(onSelected: (String) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Choose Account Type", fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, color = Color.Black)
        Spacer(modifier = Modifier.height(8.dp))
        Text("Select the type of account you want to open", fontSize = 14.sp, color = TextSecondary, textAlign = TextAlign.Center)

        Spacer(modifier = Modifier.height(32.dp))

        AccountTypeLargeButton(
            title = "Savings Account",
            description = "For personal use, daily transactions,\nand savings.",
            icon = Icons.Default.Person,
            features = listOf("Zero balance account", "Higher interest rates", "Easy & secure banking"),
            gradient = Brush.linearGradient(listOf(Color(0xFF9F5AFE), Color(0xFF5E5CE6))),
            arrowBgColor = Color(0xFFF5EEFF),
            arrowIconColor = Color(0xFF9F5AFE),
            onClick = { onSelected("SAVINGS") }
        )

        Spacer(modifier = Modifier.height(20.dp))

        AccountTypeLargeButton(
            title = "Current Account",
            description = "For business owners, firms, and\nhigh-volume transactions.",
            icon = Icons.Default.Business,
            features = listOf("Unlimited transactions", "Dedicated relationship manager", "Business banking benefits"),
            gradient = Brush.linearGradient(listOf(Color(0xFF3B82F6), Color(0xFF2563EB))),
            arrowBgColor = Color(0xFFEEF2FF),
            arrowIconColor = Color(0xFF3B82F6),
            onClick = { onSelected("CURRENT") }
        )

        Spacer(modifier = Modifier.height(32.dp))
        
        // Security Footer
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            color = Color(0xFFF8FAFC),
            border = BorderStroke(1.dp, Color(0xFFE2E8F0))
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
                        Icon(Icons.Default.Shield, contentDescription = null, tint = PrimaryBlue, modifier = Modifier.size(24.dp))
                    }
                }
                Spacer(modifier = Modifier.width(16.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text("100% Secure & Trusted", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                    Text("Your information is safe with us and protected by bank-grade security.", fontSize = 11.sp, color = TextSecondary)
                }
                Icon(Icons.Default.Verified, contentDescription = null, tint = Color(0xFF9F5AFE), modifier = Modifier.size(24.dp))
            }
        }
        
        Spacer(modifier = Modifier.height(40.dp))
    }
}

@Composable
fun AccountTypeLargeButton(
    title: String, 
    description: String, 
    icon: ImageVector, 
    features: List<String>,
    gradient: Brush,
    arrowBgColor: Color,
    arrowIconColor: Color,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(24.dp),
        color = Color.White,
        shadowElevation = 2.dp,
        border = BorderStroke(1.dp, Color(0xFFF1F5F9))
    ) {
        Row(
            modifier = Modifier.padding(20.dp),
            verticalAlignment = Alignment.Top
        ) {
            // Gradient Icon
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .background(gradient, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(28.dp))
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(title, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, color = Color.Black)
                Text(description, fontSize = 13.sp, color = TextSecondary, lineHeight = 18.sp)
                
                Spacer(modifier = Modifier.height(12.dp))
                
                features.forEach { feature ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 2.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(18.dp)
                                .background(gradient, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Text(feature, fontSize = 12.sp, color = Color.Black.copy(alpha = 0.8f))
                    }
                }
            }
            
            // Arrow Button
            Surface(
                modifier = Modifier
                    .padding(top = 80.dp)
                    .size(40.dp),
                shape = CircleShape,
                color = arrowBgColor
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowForward, 
                        contentDescription = null, 
                        tint = arrowIconColor, 
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun CommonDetailsStep(
    name: String, onNameChange: (String) -> Unit,
    email: String, onEmailChange: (String) -> Unit,
    mobile: String, onMobileChange: (String) -> Unit,
    address: String, onAddressChange: (String) -> Unit,
    pass: String, onPassChange: (String) -> Unit,
    onNext: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        Text("Required Information", fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, color = Color.Black)
        Text("Mandatory fields for all account types", fontSize = 14.sp, color = TextSecondary)

        Spacer(modifier = Modifier.height(32.dp))

        RegisterInput("Full Name", name, "Legal name as per ID") { onNameChange(it) }
        Spacer(modifier = Modifier.height(20.dp))
        RegisterInput("Email Address", email, "Registered email address") { onEmailChange(it) }
        Spacer(modifier = Modifier.height(20.dp))
        RegisterInput("Mobile Number", mobile, "10-digit mobile number") { onMobileChange(it) }
        Spacer(modifier = Modifier.height(20.dp))
        RegisterInput("Residential Address", address, "Full mailing address", singleLine = false) { onAddressChange(it) }
        Spacer(modifier = Modifier.height(20.dp))
        RegisterInput("Password", pass, "Secure your login", isPassword = true) { onPassChange(it) }

        Spacer(modifier = Modifier.height(40.dp))

        Button(
            onClick = onNext,
            modifier = Modifier.fillMaxWidth().height(60.dp),
            shape = RoundedCornerShape(20.dp),
            colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
        ) {
            Text("Continue", fontSize = 18.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun SavingsDetailsStep(
    dob: String, onDobChange: (String) -> Unit,
    gender: String, onGenderChange: (String) -> Unit,
    deposit: String, onDepositChange: (String) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        Text("Savings Account", fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, color = Color.Black)
        Text("Additional details for personal account", fontSize = 14.sp, color = TextSecondary)

        Spacer(modifier = Modifier.height(32.dp))

        RegisterInput("Date of Birth", dob, "YYYY-MM-DD") { onDobChange(it) }
        Spacer(modifier = Modifier.height(24.dp))

        Text("Gender", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Spacer(modifier = Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            listOf("Male", "Female", "Other").forEach {
                AccountTypeChip(it, gender == it, Modifier.weight(1f)) { onGenderChange(it) }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
        RegisterInput("Initial Deposit (₹)", deposit, "Minimum required amount") { onDepositChange(it) }

        Spacer(modifier = Modifier.weight(1f))
        Spacer(modifier = Modifier.height(40.dp))

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(
                onClick = onBack,
                modifier = Modifier.weight(1f).height(60.dp),
                shape = RoundedCornerShape(20.dp),
                border = BorderStroke(1.dp, PrimaryBlue)
            ) {
                Text("Back", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = PrimaryBlue)
            }
            Button(
                onClick = onNext,
                modifier = Modifier.weight(1f).height(60.dp),
                shape = RoundedCornerShape(20.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
            ) {
                Text("Next", fontSize = 18.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun CurrentDetailsStep(
    bizName: String, onBizNameChange: (String) -> Unit,
    gst: String, onGstChange: (String) -> Unit,
    turnover: String, onTurnoverChange: (String) -> Unit,
    onNext: () -> Unit,
    onBack: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        Text("Current Account", fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, color = Color.Black)
        Text("Business registration details", fontSize = 14.sp, color = TextSecondary)

        Spacer(modifier = Modifier.height(32.dp))

        RegisterInput("Business Name", bizName, "Registered name of firm") { onBizNameChange(it) }
        Spacer(modifier = Modifier.height(20.dp))
        RegisterInput("Business Reg No (GSTIN)", gst, "Official GSTIN number") { onGstChange(it) }
        Spacer(modifier = Modifier.height(20.dp))
        RegisterInput("Expected Monthly Turnover (₹)", turnover, "Estimated amount") { onTurnoverChange(it) }

        Spacer(modifier = Modifier.weight(1f))
        Spacer(modifier = Modifier.height(40.dp))

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(
                onClick = onBack,
                modifier = Modifier.weight(1f).height(60.dp),
                shape = RoundedCornerShape(20.dp),
                border = BorderStroke(1.dp, PrimaryBlue)
            ) {
                Text("Back", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = PrimaryBlue)
            }
            Button(
                onClick = onNext,
                modifier = Modifier.weight(1f).height(60.dp),
                shape = RoundedCornerShape(20.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
            ) {
                Text("Next", fontSize = 18.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun VerificationFlow(
    pan: String, onPanChange: (String) -> Unit,
    aadhaar: String, onAadhaarChange: (String) -> Unit,
    onPhotoCaptured: (String) -> Unit,
    onPanCaptured: (String) -> Unit,
    onAadhaarCaptured: (String) -> Unit,
    onSignatureCaptured: (String) -> Unit,
    onComplete: () -> Unit,
    onBack: () -> Unit
) {
    var subStep by remember { mutableIntStateOf(0) } // 0: Photo, 1: PAN Card, 2: Aadhaar Card, 3: Sign & Submit

    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        Text("KYC Verification", fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, color = Color.Black)
        Text("Step ${subStep + 1} of 4", fontSize = 14.sp, color = TextSecondary)

        Spacer(modifier = Modifier.height(32.dp))

        when (subStep) {
            0 -> {
                Text("Portrait Photo (Live)", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                Text("Align your face within the oval", fontSize = 12.sp, color = TextSecondary)
                Spacer(modifier = Modifier.height(16.dp))
                CameraSection(isOval = true) { base64 ->
                    onPhotoCaptured(base64)
                    subStep = 1
                }
            }
            1 -> {
                Text("PAN Card Photo", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                Text("Capture a clear photo of your PAN Card", fontSize = 12.sp, color = TextSecondary)
                Spacer(modifier = Modifier.height(16.dp))
                CameraSection(isOval = false) { base64 ->
                    onPanCaptured(base64)
                }
                Spacer(modifier = Modifier.height(24.dp))
                RegisterInput("PAN Card Number", pan, "ABCDE1234F") { onPanChange(it.uppercase()) }

                val isPanValid = remember(pan) {
                    val regex = Regex("^[A-Z]{3}[PCHTFABGJL][A-Z][0-9]{4}[A-Z]$")
                    regex.matches(pan)
                }
                if (pan.isNotEmpty() && !isPanValid) {
                    Text("Invalid PAN format", color = Color.Red, fontSize = 12.dp.value.sp)
                }

                Spacer(modifier = Modifier.weight(1f))
                Button(
                    onClick = { subStep = 2 },
                    enabled = isPanValid,
                    modifier = Modifier.fillMaxWidth().height(60.dp),
                    shape = RoundedCornerShape(20.dp)
                ) { Text("Confirm PAN") }
            }
            2 -> {
                Text("Aadhaar Card Photo", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                Text("Capture a clear photo of your Aadhaar Card", fontSize = 12.sp, color = TextSecondary)
                Spacer(modifier = Modifier.height(16.dp))
                CameraSection(isOval = false) { base64 ->
                    onAadhaarCaptured(base64)
                }
                Spacer(modifier = Modifier.height(24.dp))
                RegisterInput("Aadhaar Number", aadhaar, "1234 5678 9012") {
                    if (it.length <= 12 && it.all { char -> char.isDigit() }) onAadhaarChange(it)
                }

                val isAadhaarValid = aadhaar.length == 12

                Spacer(modifier = Modifier.weight(1f))
                Button(
                    onClick = { subStep = 3 },
                    enabled = isAadhaarValid,
                    modifier = Modifier.fillMaxWidth().height(60.dp),
                    shape = RoundedCornerShape(20.dp)
                ) { Text("Confirm Aadhaar") }
            }
            3 -> {
                Text("Digital Signature", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                Text("Draw or upload your signature below", fontSize = 12.sp, color = TextSecondary)
                Spacer(modifier = Modifier.height(16.dp))
                
                var signatureMode by remember { mutableStateOf("DRAW") } // "DRAW" or "UPLOAD"

                Row(
                    modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    AccountTypeChip("Draw", signatureMode == "DRAW", Modifier.weight(1f)) { signatureMode = "DRAW" }
                    AccountTypeChip("Upload", signatureMode == "UPLOAD", Modifier.weight(1f)) { signatureMode = "UPLOAD" }
                }

                if (signatureMode == "DRAW") {
                    SignaturePad { base64 ->
                        onSignatureCaptured(base64)
                    }
                } else {
                    SignatureUpload { base64 ->
                        onSignatureCaptured(base64)
                    }
                }
                
                Spacer(modifier = Modifier.weight(1f))
                Row(modifier = Modifier.fillMaxWidth().padding(top = 24.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(
                        onClick = onBack,
                        modifier = Modifier.weight(1f).height(60.dp),
                        shape = RoundedCornerShape(20.dp)
                    ) { Text("Back") }
                    Button(
                        onClick = onComplete,
                        modifier = Modifier.weight(1f).height(60.dp),
                        shape = RoundedCornerShape(20.dp)
                    ) { Text("Submit") }
                }
            }
        }
    }
}

@Composable
fun SignaturePad(onCaptured: (String) -> Unit) {
    val paths = remember { mutableStateListOf<Path>() }
    var currentPath by remember { mutableStateOf<Path?>(null) }

    // For converting to Base64
    val canvasBitmap = remember { Bitmap.createBitmap(800, 400, Bitmap.Config.ARGB_8888) }
    val androidCanvas = remember { AndroidCanvas(canvasBitmap) }
    val paint = remember { 
        AndroidPaint().apply {
            color = android.graphics.Color.BLACK
            strokeWidth = 10f
            style = AndroidPaint.Style.STROKE
            strokeCap = AndroidPaint.Cap.ROUND
        }
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(InputBg)
            .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp))
            .pointerInput(Unit) {
                detectDragGestures(
                    onDragStart = { offset ->
                        val path = Path().apply { moveTo(offset.x, offset.y) }
                        currentPath = path
                        paths.add(path)
                    },
                    onDrag = { change, _ ->
                        currentPath?.lineTo(change.position.x, change.position.y)
                        // Trigger recomposition
                        val last = paths.last()
                        paths.removeAt(paths.size - 1)
                        paths.add(last)
                    },
                    onDragEnd = {
                        currentPath = null
                        // Draw all paths to the bitmap for capture
                        androidCanvas.drawColor(android.graphics.Color.WHITE)
                        paths.forEach { p ->
                            androidCanvas.drawPath(p.asAndroidPath(), paint)
                        }
                        val stream = ByteArrayOutputStream()
                        canvasBitmap.compress(Bitmap.CompressFormat.JPEG, 70, stream)
                        onCaptured(Base64.encodeToString(stream.toByteArray(), Base64.DEFAULT))
                    }
                )
            }
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            paths.forEach { path ->
                drawPath(
                    path = path,
                    color = Color.Black,
                    style = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round)
                )
            }
        }

        IconButton(
            onClick = { paths.clear() },
            modifier = Modifier.align(Alignment.TopEnd).padding(8.dp)
        ) {
            Icon(Icons.Default.Clear, contentDescription = "Clear", tint = TextSecondary)
        }
    }
}

@Composable
fun SignatureUpload(onCaptured: (String) -> Unit) {
    val context = LocalContext.current
    var selectedImageUri by remember { mutableStateOf<Uri?>(null) }
    
    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            selectedImageUri = it
            try {
                context.contentResolver.openInputStream(it)?.use { inputStream ->
                    val bitmap = BitmapFactory.decodeStream(inputStream)
                    bitmap?.let { b ->
                        val stream = ByteArrayOutputStream()
                        b.compress(Bitmap.CompressFormat.JPEG, 70, stream)
                        val base64 = Base64.encodeToString(stream.toByteArray(), Base64.DEFAULT)
                        onCaptured(base64)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(InputBg)
            .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(20.dp))
            .clickable { galleryLauncher.launch("image/*") },
        color = Color.White
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            if (selectedImageUri != null) {
                AsyncImage(
                    model = selectedImageUri,
                    contentDescription = "Selected Signature",
                    modifier = Modifier.fillMaxSize().padding(12.dp),
                    contentScale = ContentScale.Fit
                )
            } else {
                Icon(
                    Icons.Default.CloudUpload,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = PrimaryBlue
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text("Tap to upload signature image", fontSize = 14.sp, color = TextSecondary)
            }
        }
    }
}

@Composable
fun CameraSection(isOval: Boolean, onCaptured: (String) -> Unit) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraExecutor = remember { java.util.concurrent.Executors.newSingleThreadExecutor() }
    val imageCapture: ImageCapture = remember { ImageCapture.Builder().build() }
    
    var capturedBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var isConfirmed by remember { mutableStateOf(false) }
    
    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == android.content.pm.PackageManager.PERMISSION_GRANTED
        )
    }
    
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        hasCameraPermission = isGranted
    }

    if (hasCameraPermission) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(250.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(Color.Black),
                contentAlignment = Alignment.Center
            ) {
                if (capturedBitmap != null) {
                    Box(modifier = Modifier.fillMaxSize()) {
                        androidx.compose.foundation.Image(
                            bitmap = capturedBitmap!!.asImageBitmap(),
                            contentDescription = "Captured Photo",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = androidx.compose.ui.layout.ContentScale.Crop
                        )
                        
                        if (isConfirmed) {
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .background(Color.Black.copy(alpha = 0.4f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Surface(
                                    color = Color.White,
                                    shape = CircleShape,
                                    shadowElevation = 8.dp
                                ) {
                                    Icon(
                                        Icons.Default.CheckCircle,
                                        contentDescription = "Confirmed",
                                        tint = Color(0xFF22C55E),
                                        modifier = Modifier.size(48.dp).padding(4.dp)
                                    )
                                }
                            }
                        }
                    }
                } else {
                    AndroidView(
                        factory = { ctx ->
                            val previewView = PreviewView(ctx)
                            val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                            cameraProviderFuture.addListener({
                                val cameraProvider = cameraProviderFuture.get()
                                val preview = Preview.Builder().build().also {
                                    it.setSurfaceProvider(previewView.surfaceProvider)
                                }
                                val cameraSelector = if (isOval) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
                                try {
                                    cameraProvider.unbindAll()
                                    cameraProvider.bindToLifecycle(lifecycleOwner, cameraSelector, preview, imageCapture)
                                } catch (e: Exception) {
                                    e.printStackTrace()
                                }
                            }, ContextCompat.getMainExecutor(ctx))
                            previewView
                        },
                        modifier = Modifier.fillMaxSize()
                    )

                    if (isOval) {
                        Canvas(modifier = Modifier.fillMaxSize()) {
                            drawOval(
                                color = Color.White.copy(alpha = 0.5f),
                                style = Stroke(width = 2.dp.toPx()),
                                topLeft = Offset(size.width * 0.15f, size.height * 0.05f),
                                size = androidx.compose.ui.geometry.Size(size.width * 0.7f, size.height * 0.9f)
                            )
                        }
                    } else {
                        Box(
                            modifier = Modifier
                                .fillMaxSize(0.8f)
                                .border(2.dp, Color.White.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                        )
                    }
                }
            }
            
            if (capturedBitmap == null) {
                Button(
                    onClick = {
                        val file = java.io.File(context.cacheDir, "temp_kyc_${System.currentTimeMillis()}.jpg")
                        val outputOptions = ImageCapture.OutputFileOptions.Builder(file).build()
                        imageCapture.takePicture(outputOptions, cameraExecutor, object : ImageCapture.OnImageSavedCallback {
                            override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                                val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                                capturedBitmap = bitmap
                                isConfirmed = false
                                file.delete()
                            }
                            override fun onError(exc: ImageCaptureException) {
                                exc.printStackTrace()
                            }
                        })
                    },
                    modifier = Modifier.padding(top = 12.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
                ) {
                    Icon(Icons.Default.CameraAlt, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Capture Photo")
                }
            } else if (!isConfirmed) {
                Row(
                    modifier = Modifier.padding(top = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    OutlinedButton(
                        onClick = { capturedBitmap = null },
                        shape = RoundedCornerShape(12.dp),
                        border = BorderStroke(1.dp, PrimaryBlue)
                    ) {
                        Icon(Icons.Default.Refresh, contentDescription = null, tint = PrimaryBlue)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Retry", color = PrimaryBlue)
                    }
                    
                    Button(
                        onClick = {
                            isConfirmed = true
                            val stream = ByteArrayOutputStream()
                            capturedBitmap!!.compress(Bitmap.CompressFormat.JPEG, 70, stream)
                            val base64 = Base64.encodeToString(stream.toByteArray(), Base64.DEFAULT)
                            onCaptured(base64)
                        },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
                    ) {
                        Icon(Icons.Default.Check, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Use Photo")
                    }
                }
            } else {
                // Showing confirmation state
                Row(
                    modifier = Modifier.padding(top = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF22C55E), modifier = Modifier.size(24.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Photo Saved", color = Color(0xFF22C55E), fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.width(16.dp))
                    TextButton(onClick = { 
                        capturedBitmap = null
                        isConfirmed = false
                    }) {
                        Text("Change", color = PrimaryBlue)
                    }
                }
            }
        }
    } else {
        Surface(
            modifier = Modifier.fillMaxWidth().height(200.dp),
            shape = RoundedCornerShape(24.dp),
            color = InputBg
        ) {
            Column(
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                IconButton(
                    onClick = { permissionLauncher.launch(Manifest.permission.CAMERA) },
                    modifier = Modifier.size(64.dp).background(Color.White, CircleShape)
                ) {
                    Icon(Icons.Default.CameraAlt, contentDescription = null, tint = PrimaryBlue)
                }
                Spacer(modifier = Modifier.height(12.dp))
                Text("Allow Camera Permission", fontSize = 14.sp, color = TextSecondary)
            }
        }
    }
}

@Composable
fun StepCircle(step: Int, isActive: Boolean) {
    Surface(
        modifier = Modifier.size(36.dp),
        shape = CircleShape,
        color = if (isActive) PrimaryBlue else Color(0xFFF1F5F9),
        border = if (isActive) null else BorderStroke(2.dp, Color(0xFFE2E8F0))
    ) {
        Box(contentAlignment = Alignment.Center) {
            if (isActive && step < 3) {
                 Text(step.toString(), color = Color.White, fontWeight = FontWeight.Bold)
            } else if (isActive && step == 3) {
                Icon(Icons.Default.Done, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
            } else {
                Text(step.toString(), color = Color(0xFF94A3B8), fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun AccountTypeChip(label: String, isSelected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Surface(
        modifier = modifier
            .height(56.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        color = if (isSelected) PrimaryBlue else InputBg,
        border = if (isSelected) null else BorderStroke(1.dp, Color(0xFFE2E8F0))
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                label,
                color = if (isSelected) Color.White else TextSecondary,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp
            )
        }
    }
}

@Composable
fun RegisterInput(
    label: String,
    value: String,
    placeholder: String,
    singleLine: Boolean = true,
    isPassword: Boolean = false,
    onValueChange: (String) -> Unit
) {
    var passwordVisible by remember { mutableStateOf(false) }
    Column {
        Text(label, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Spacer(modifier = Modifier.height(8.dp))
        TextField(
            value = value,
            onValueChange = onValueChange,
            placeholder = { Text(placeholder, color = TextSecondary) },
            visualTransformation = if (isPassword && !passwordVisible) PasswordVisualTransformation() else VisualTransformation.None,
            trailingIcon = if (isPassword) {
                {
                    IconButton(onClick = { passwordVisible = !passwordVisible }) {
                        Icon(if (passwordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff, contentDescription = null, tint = TextSecondary)
                    }
                }
            } else null,
            modifier = Modifier.fillMaxWidth(),
            colors = TextFieldDefaults.colors(
                focusedTextColor = Color.Black,
                unfocusedTextColor = Color.Black,
                focusedContainerColor = InputBg,
                unfocusedContainerColor = InputBg,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                cursorColor = PrimaryBlue
            ),
            shape = RoundedCornerShape(16.dp),
            singleLine = singleLine,
            minLines = if (singleLine) 1 else 3
        )
    }
}
