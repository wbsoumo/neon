package com.my.deccanfinance

import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.FactCheck
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.automirrored.outlined.Label
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddBeneficiaryScreen(
    apiService: ApiService,
    ifscService: IfscService,
    onBack: () -> Unit
) {
    var currentStep by remember { mutableStateOf(1) }
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    // Form Data
    var fullName by remember { mutableStateOf("") }
    var accountNumber by remember { mutableStateOf("") }
    var confirmAccountNumber by remember { mutableStateOf("") }
    var bankName by remember { mutableStateOf("") }
    var ifscCode by remember { mutableStateOf("") }
    var branchName by remember { mutableStateOf("") }
    var accountType by remember { mutableStateOf("Savings Account") }
    
    // Additional Info
    var nickname by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var purpose by remember { mutableStateOf("Salary") }
    var isPrimary by remember { mutableStateOf(false) }

    var isLoading by remember { mutableStateOf(false) }
    var isFetchingIfsc by remember { mutableStateOf(false) }

    // Auto-fetch bank details when IFSC code is valid (11 characters)
    LaunchedEffect(ifscCode) {
        val cleanIfsc = ifscCode.trim().uppercase()
        if (cleanIfsc.length == 11) {
            isFetchingIfsc = true
            try {
                val response = ifscService.getBankDetails(cleanIfsc)
                if (response.isSuccessful) {
                    response.body()?.let {
                        bankName = it.bank
                        branchName = it.branch
                        if (nickname.isEmpty()) nickname = it.bank
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isFetchingIfsc = false
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
                            "Add Beneficiary",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF1A1C1E)
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = { if (currentStep > 1 && currentStep < 5) currentStep-- else onBack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = DashPrimary)
                    }
                },
                actions = {
                    IconButton(onClick = { /* Help */ }) {
                        Icon(Icons.AutoMirrored.Outlined.HelpOutline, contentDescription = "Help", tint = DashPrimary)
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
        ) {
            if (currentStep < 5) {
                StepperHeader(currentStep)
            }

            Box(modifier = Modifier.weight(1f)) {
                when (currentStep) {
                    1 -> BankDetailsStep(
                        fullName, { fullName = it },
                        accountNumber, { accountNumber = it },
                        confirmAccountNumber, { confirmAccountNumber = it },
                        bankName, { bankName = it },
                        ifscCode, { ifscCode = it },
                        branchName, { branchName = it },
                        accountType, { accountType = it },
                        isFetchingIfsc = isFetchingIfsc,
                        onContinue = { currentStep = 2 },
                        onCancel = onBack
                    )
                    2 -> VerifyDetailsStep(
                        fullName, accountNumber, bankName, ifscCode, branchName, accountType,
                        onConfirm = { currentStep = 3 },
                        onEdit = { currentStep = 1 }
                    )
                    3 -> AdditionalInfoStep(
                        nickname, { nickname = it },
                        email, { email = it },
                        phone, { phone = it },
                        purpose, { purpose = it },
                        isPrimary, { isPrimary = it },
                        onContinue = { currentStep = 4 }
                    )
                    4 -> ReviewAndSaveStep(
                        fullName, accountNumber, bankName, ifscCode, branchName, accountType,
                        nickname, email, phone, purpose, isPrimary,
                        isLoading = isLoading,
                        onAdd = {
                            isLoading = true
                            scope.launch {
                                try {
                                    val request = AddBeneficiaryRequest(
                                        type = "OTHER_BANK",
                                        beneficiaryAccountNumber = accountNumber,
                                        beneficiaryName = fullName,
                                        ifscCode = ifscCode.uppercase(),
                                        dailyLimit = 50000.0,
                                        nickname = if (nickname.isBlank()) fullName else nickname
                                    )
                                    val response = apiService.addBeneficiary(request)
                                    if (response.isSuccessful && response.body()?.success == true) {
                                        currentStep = 5
                                    } else {
                                        val errorMsg = response.body()?.message ?: response.message() ?: "Failed to add beneficiary"
                                        snackbarHostState.showSnackbar(errorMsg)
                                    }
                                } catch (e: Exception) {
                                    e.printStackTrace()
                                    snackbarHostState.showSnackbar("Error: ${e.message}")
                                } finally {
                                    isLoading = false
                                }
                            }
                        }
                    )
                    5 -> SuccessStep(
                        fullName, accountNumber, bankName,
                        onDone = onBack,
                        onViewBeneficiaries = onBack
                    )
                }
            }
        }
    }
}

@Composable
fun StepperHeader(currentStep: Int) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        StepItem(1, "Bank Details", currentStep >= 1)
        Box(modifier = Modifier.weight(1f).height(1.dp).background(Color.LightGray).padding(horizontal = 8.dp))
        StepItem(2, "Verify Details", currentStep >= 2)
        Box(modifier = Modifier.weight(1f).height(1.dp).background(Color.LightGray).padding(horizontal = 8.dp))
        StepItem(3, "Additional Info", currentStep >= 3)
        Box(modifier = Modifier.weight(1f).height(1.dp).background(Color.LightGray).padding(horizontal = 8.dp))
        StepItem(4, "Review & Save", currentStep >= 4)
    }
}

@Composable
fun StepItem(step: Int, label: String, isActive: Boolean) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Surface(
            modifier = Modifier.size(28.dp),
            shape = CircleShape,
            color = if (isActive) DashPrimary else Color.White,
            border = if (isActive) null else BorderStroke(1.dp, Color.LightGray)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text(
                    step.toString(),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = if (isActive) Color.White else Color.Gray
                )
            }
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(label, fontSize = 8.sp, color = if (isActive) DashPrimary else Color.Gray, fontWeight = if (isActive) FontWeight.Bold else FontWeight.Normal)
    }
}

@Composable
fun BankDetailsStep(
    fullName: String, onFullNameChange: (String) -> Unit,
    accountNumber: String, onAccountNumberChange: (String) -> Unit,
    confirmAccountNumber: String, onConfirmChange: (String) -> Unit,
    bankName: String, onBankNameChange: (String) -> Unit,
    ifscCode: String, onIfscChange: (String) -> Unit,
    branchName: String, onBranchChange: (String) -> Unit,
    accountType: String, onAccountTypeChange: (String) -> Unit,
    isFetchingIfsc: Boolean,
    onContinue: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        // Transfer Type Header
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            color = Color.White,
            shadowElevation = 2.dp
        ) {
            Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Transfer to", fontSize = 12.sp, color = Color.Black.copy(alpha = 0.7f), fontWeight = FontWeight.Medium)
                    Text("Other Bank Account", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                    Text("Add a beneficiary for NEFT/IMPS/RTGS transfers", fontSize = 11.sp, color = Color.Gray)
                }
                Surface(modifier = Modifier.size(44.dp), shape = RoundedCornerShape(12.dp), color = Color(0xFFF0F2FF)) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.AccountBalance, contentDescription = null, tint = DashPrimary)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
        BeneficiarySectionHeader("Beneficiary Details")
        
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            BeneficiaryInputField(Icons.Outlined.Person, "Full Name", "Enter beneficiary full name", fullName, onFullNameChange)
            BeneficiaryInputField(Icons.Outlined.CreditCard, "Account Number", "Enter account number", accountNumber, onAccountNumberChange, trailingIcon = Icons.Default.QrCodeScanner)
            BeneficiaryInputField(Icons.Outlined.Shield, "Confirm Account Number", "Re-enter account number", confirmAccountNumber, onConfirmChange)
            
            Box {
                BeneficiaryInputField(Icons.Outlined.Hub, "IFSC Code", "Enter 11-digit IFSC code", ifscCode, onIfscChange, trailingIcon = if (isFetchingIfsc) null else Icons.Outlined.Info)
                if (isFetchingIfsc) {
                    CircularProgressIndicator(
                        modifier = Modifier
                            .align(Alignment.CenterEnd)
                            .padding(end = 12.dp)
                            .size(20.dp),
                        strokeWidth = 2.dp,
                        color = DashPrimary
                    )
                }
            }

            BeneficiaryInputField(Icons.Outlined.AccountBalance, "Bank Name", "Select bank name", bankName, onBankNameChange, trailingIcon = Icons.Default.KeyboardArrowDown)
            BeneficiaryInputField(Icons.Outlined.LocationOn, "Branch Name", "Enter branch name", branchName, onBranchChange)
        }

        Spacer(modifier = Modifier.height(24.dp))
        BeneficiarySectionHeader("Account Type")
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            AccountTypeCard("Savings Account", "Select if beneficiary has a savings account", accountType == "Savings Account", { onAccountTypeChange("Savings Account") }, Modifier.weight(1f))
            AccountTypeCard("Current Account", "Select if beneficiary has a current account", accountType == "Current Account", { onAccountTypeChange("Current Account") }, Modifier.weight(1f))
        }

        Spacer(modifier = Modifier.height(24.dp))
        Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp), color = Color(0xFFF8F9FF)) {
            Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.Shield, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text("Please ensure the details are correct.", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                    Text("Incorrect details may lead to failed transactions.", fontSize = 11.sp, color = Color.Gray)
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))
        Button(
            onClick = onContinue,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = DashPrimary,
                disabledContainerColor = DashPrimary.copy(alpha = 0.3f),
                disabledContentColor = Color.White.copy(alpha = 0.5f)
            ),
            enabled = fullName.isNotBlank() && accountNumber.isNotBlank() && accountNumber == confirmAccountNumber && ifscCode.length == 11
        ) {
            Text("Continue", fontSize = 16.sp, fontWeight = FontWeight.Bold)
        }
        TextButton(onClick = onCancel, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
            Text("Cancel", color = DashPrimary, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun BeneficiarySectionHeader(title: String) {
    Text(
        text = title,
        fontSize = 15.sp,
        fontWeight = FontWeight.Bold,
        color = Color(0xFF1A1C1E),
        modifier = Modifier.padding(bottom = 12.dp, start = 4.dp)
    )
}

@Composable
fun BeneficiaryInputField(icon: ImageVector, label: String, placeholder: String, value: String, onValueChange: (String) -> Unit, trailingIcon: ImageVector? = null) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.1f))
    ) {
        Row(modifier = Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(modifier = Modifier.size(40.dp), shape = RoundedCornerShape(10.dp), color = Color(0xFFF3F4FF)) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                }
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(label, fontSize = 12.sp, color = Color.Black.copy(alpha = 0.7f), fontWeight = FontWeight.Medium)
                BasicTextField(
                    value = value,
                    onValueChange = onValueChange,
                    textStyle = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color(0xFF111827)),
                    decorationBox = { innerTextField ->
                        if (value.isEmpty()) Text(placeholder, fontSize = 16.sp, color = Color.Gray.copy(alpha = 0.4f))
                        innerTextField()
                    }
                )
            }
            if (trailingIcon != null) {
                Icon(trailingIcon, contentDescription = null, tint = Color(0xFF9CA3AF), modifier = Modifier.size(22.dp))
            }
        }
    }
}

@Composable
fun AccountTypeCard(title: String, subtitle: String, isSelected: Boolean, onClick: () -> Unit, modifier: Modifier) {
    Surface(
        modifier = modifier.clickable { onClick() },
        shape = RoundedCornerShape(12.dp),
        border = BorderStroke(1.5.dp, if (isSelected) DashPrimary else Color(0xFFE5E7EB)),
        color = Color.White
    ) {
        Row(modifier = Modifier.padding(14.dp), verticalAlignment = Alignment.Top) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = if (isSelected) DashPrimary else Color(0xFF111827))
                Text(subtitle, fontSize = 11.sp, color = Color(0xFF6B7280), lineHeight = 14.sp)
            }
            RadioButton(selected = isSelected, onClick = onClick, colors = RadioButtonDefaults.colors(selectedColor = DashPrimary))
        }
    }
}

@Composable
fun VerifyDetailsStep(
    fullName: String, accountNumber: String, bankName: String, ifscCode: String, branchName: String, accountType: String,
    onConfirm: () -> Unit,
    onEdit: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(modifier = Modifier.size(120.dp), contentAlignment = Alignment.Center) {
            Surface(modifier = Modifier.size(80.dp), shape = RoundedCornerShape(20.dp), color = Color(0xFFF3F4FF)) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.AutoMirrored.Filled.FactCheck, contentDescription = null, modifier = Modifier.size(40.dp), tint = DashPrimary)
                }
            }
            Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(32.dp).align(Alignment.BottomCenter).offset(y = (0).dp), tint = Color(0xFF10B981))
        }
        Spacer(modifier = Modifier.height(16.dp))
        Text("Verify Beneficiary Details", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color(0xFF111827))
        Text("Please confirm that the details below are correct", fontSize = 14.sp, color = Color(0xFF6B7280))
        
        Spacer(modifier = Modifier.height(24.dp))
        Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), color = Color.White, border = BorderStroke(1.dp, Color(0xFFE5E7EB)), shadowElevation = 1.dp) {
            Column(modifier = Modifier.padding(16.dp)) {
                VerifyRowLarge(Icons.Default.Person, "Full Name", fullName, onEdit)
                HorizontalDivider(thickness = 1.dp, color = Color(0xFFF3F4F6))
                VerifyRowLarge(Icons.Default.CreditCard, "Account Number", accountNumber, onEdit)
                HorizontalDivider(thickness = 1.dp, color = Color(0xFFF3F4F6))
                VerifyRowLarge(Icons.Default.AccountBalance, "Bank Name", bankName, onEdit)
                HorizontalDivider(thickness = 1.dp, color = Color(0xFFF3F4F6))
                VerifyRowLarge(Icons.Default.Hub, "IFSC Code", ifscCode.uppercase(), onEdit)
                HorizontalDivider(thickness = 1.dp, color = Color(0xFFF3F4F6))
                VerifyRowLarge(Icons.Default.LocationOn, "Branch Name", branchName, onEdit)
                HorizontalDivider(thickness = 1.dp, color = Color(0xFFF3F4F6))
                VerifyRowLarge(Icons.Default.Badge, "Account Type", accountType, onEdit)
            }
        }
        
        Spacer(modifier = Modifier.height(32.dp))
        Button(
            onClick = onConfirm,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DashPrimary)
        ) {
            Text("Confirm & Continue", fontSize = 16.sp, fontWeight = FontWeight.Bold)
        }
        TextButton(onClick = onEdit, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
            Text("Back to Edit", color = DashPrimary, fontWeight = FontWeight.Bold)
        }
        Spacer(modifier = Modifier.height(20.dp))
    }
}

@Composable
fun VerifyRowLarge(icon: ImageVector, label: String, value: String, onEdit: () -> Unit) {
    Row(modifier = Modifier.fillMaxWidth().padding(vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
        Surface(modifier = Modifier.size(36.dp), shape = CircleShape, color = Color(0xFFF9FAFB)) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = Color(0xFF6B7280), modifier = Modifier.size(18.dp))
            }
        }
        Spacer(modifier = Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(label, fontSize = 12.sp, color = Color.Black.copy(alpha = 0.7f), fontWeight = FontWeight.Medium)
            Text(value, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Color(0xFF111827))
        }
        Text("Edit", fontSize = 13.sp, color = DashPrimary, fontWeight = FontWeight.Bold, modifier = Modifier.clickable { onEdit() })
    }
}

@Composable
fun AdditionalInfoStep(
    nickname: String, onNicknameChange: (String) -> Unit,
    email: String, onEmailChange: (String) -> Unit,
    phone: String, onPhoneChange: (String) -> Unit,
    purpose: String, onPurposeChange: (String) -> Unit,
    isPrimary: Boolean, onIsPrimaryChange: (Boolean) -> Unit,
    onContinue: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp).verticalScroll(rememberScrollState())) {
        Text("Additional Information", fontSize = 20.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth(), color = Color(0xFF111827))
        Text("Provide a few more details about your beneficiary", fontSize = 14.sp, color = Color(0xFF6B7280), textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
        
        Spacer(modifier = Modifier.height(24.dp))
        BeneficiaryInputField(Icons.AutoMirrored.Outlined.Label, "Nickname (Required for API)", "e.g. Office Rent, Rahul Salary", nickname, onNicknameChange)
        Spacer(modifier = Modifier.height(12.dp))
        BeneficiaryInputField(Icons.Outlined.Email, "Email (Optional)", "Enter email address", email, onEmailChange)
        Spacer(modifier = Modifier.height(12.dp))
        BeneficiaryInputField(Icons.Outlined.Smartphone, "Mobile Number (Optional)", "Enter mobile number", phone, onPhoneChange)
        Spacer(modifier = Modifier.height(12.dp))
        
        // Purpose Dropdown (Simplified)
        Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp), color = Color.White, border = BorderStroke(1.dp, Color.Black.copy(alpha = 0.1f))) {
            Column(modifier = Modifier.padding(14.dp).clickable { /* Dropdown logic */ }) {
                Text("Purpose of Transfer", fontSize = 12.sp, color = Color.Black.copy(alpha = 0.7f), fontWeight = FontWeight.Medium)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(purpose, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f), color = Color(0xFF111827))
                    Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = Color(0xFF6B7280))
                }
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(horizontal = 4.dp)) {
            Column(modifier = Modifier.weight(1f)) {
                Text("Set as Primary Beneficiary", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Color(0xFF111827))
                Text("Mark this beneficiary as primary for faster payments", fontSize = 12.sp, color = Color(0xFF6B7280))
            }
            Switch(checked = isPrimary, onCheckedChange = onIsPrimaryChange, colors = SwitchDefaults.colors(checkedTrackColor = DashPrimary))
        }
        
        Spacer(modifier = Modifier.weight(1f))
        Button(
            onClick = onContinue,
            modifier = Modifier.fillMaxWidth().height(56.dp).padding(top = 24.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DashPrimary)
        ) {
            Text("Continue", fontSize = 16.sp, fontWeight = FontWeight.Bold)
        }
        TextButton(onClick = { /* Back handled by Scaffold logic */ }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
            Text("Back", color = DashPrimary, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun ReviewAndSaveStep(
    fullName: String, accountNumber: String, bankName: String, ifscCode: String, branchName: String, accountType: String,
    nickname: String, email: String, phone: String, purpose: String, isPrimary: Boolean,
    isLoading: Boolean,
    onAdd: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp).verticalScroll(rememberScrollState())) {
        Text("Review & Save", fontSize = 20.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth(), color = Color(0xFF111827))
        Text("Please review all details before adding beneficiary", fontSize = 14.sp, color = Color(0xFF6B7280), textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
        
        Spacer(modifier = Modifier.height(24.dp))
        BeneficiarySectionHeader("Beneficiary Details")
        Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), color = Color.White, border = BorderStroke(1.dp, Color(0xFFE5E7EB))) {
            Column(modifier = Modifier.padding(16.dp)) {
                ReviewRowTable("Full Name", fullName)
                ReviewRowTable("Account Number", accountNumber)
                ReviewRowTable("Bank Name", bankName)
                ReviewRowTable("IFSC Code", ifscCode.uppercase())
                ReviewRowTable("Branch Name", branchName)
                ReviewRowTable("Account Type", accountType)
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        BeneficiarySectionHeader("Additional Information")
        Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), color = Color.White, border = BorderStroke(1.dp, Color(0xFFE5E7EB))) {
            Column(modifier = Modifier.padding(16.dp)) {
                ReviewRowTable("Nickname", if (nickname.isBlank()) fullName else nickname)
                ReviewRowTable("Email", email.ifEmpty { "—" })
                ReviewRowTable("Mobile Number", phone.ifEmpty { "—" })
                ReviewRowTable("Purpose of Transfer", purpose)
                ReviewRowTable("Set as Primary", if (isPrimary) "Yes" else "No")
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp), color = Color(0xFFF0FDF4), border = BorderStroke(1.dp, Color(0xFFBBF7D0))) {
            Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.Shield, contentDescription = null, tint = Color(0xFF16A34A), modifier = Modifier.size(20.dp))
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text("Secure & Verified", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color(0xFF16A34A))
                    Text("We will verify the details and notify you once the beneficiary is ready.", fontSize = 11.sp, color = Color(0xFF15803D))
                }
            }
        }
        
        Spacer(modifier = Modifier.height(32.dp))
        Button(
            onClick = onAdd,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DashPrimary),
            enabled = !isLoading
        ) {
            if (isLoading) CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
            else Text("Add Beneficiary", fontSize = 16.sp, fontWeight = FontWeight.Bold)
        }
        TextButton(onClick = { /* Back handled by Scaffold logic */ }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
            Text("Back", color = DashPrimary, fontWeight = FontWeight.Bold)
        }
        Spacer(modifier = Modifier.height(20.dp))
    }
}

@Composable
fun ReviewRowTable(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, fontSize = 14.sp, color = Color(0xFF6B7280))
        Text(value, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color(0xFF111827), textAlign = TextAlign.End, modifier = Modifier.weight(1f).padding(start = 16.dp))
    }
}

@Composable
fun SuccessStep(fullName: String, accountNumber: String, bankName: String, onDone: () -> Unit, onViewBeneficiaries: () -> Unit) {
    Column(modifier = Modifier.fillMaxSize().padding(24.dp).verticalScroll(rememberScrollState()), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(modifier = Modifier.height(48.dp))
        Box(modifier = Modifier.size(100.dp).clip(CircleShape).background(Color(0xFFDCFCE7)), contentAlignment = Alignment.Center) {
            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF16A34A), modifier = Modifier.size(64.dp))
        }
        Spacer(modifier = Modifier.height(24.dp))
        Text("Beneficiary Added Successfully!", fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center, color = Color(0xFF111827))
        
        Spacer(modifier = Modifier.height(24.dp))
        Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), color = Color(0xFFF0F9FF), border = BorderStroke(1.dp, Color(0xFFBAE6FD))) {
            Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.AccessTime, contentDescription = null, tint = Color(0xFF0284C7), modifier = Modifier.size(24.dp))
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text("Verification in Progress", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0284C7))
                    Text("We will verify the beneficiary details. You will be notified within 30 minutes. Once verified, you can start making transfers.", fontSize = 12.sp, color = Color(0xFF0369A1))
                }
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        Surface(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), color = Color.White, border = BorderStroke(1.dp, Color(0xFFE5E7EB))) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Beneficiary Summary", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color(0xFF6B7280))
                Spacer(modifier = Modifier.height(12.dp))
                ReviewRowTable("Name", fullName)
                ReviewRowTable("Account Number", accountNumber)
                ReviewRowTable("Bank Name", bankName)
                ReviewRowTable("Added On", SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()).format(Date()))
            }
        }
        
        Spacer(modifier = Modifier.height(40.dp))
        Button(
            onClick = onDone,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DashPrimary)
        ) {
            Text("Done", fontSize = 16.sp, fontWeight = FontWeight.Bold)
        }
        TextButton(onClick = onViewBeneficiaries, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
            Text("View Beneficiaries", color = DashPrimary, fontWeight = FontWeight.Bold)
        }
    }
}
