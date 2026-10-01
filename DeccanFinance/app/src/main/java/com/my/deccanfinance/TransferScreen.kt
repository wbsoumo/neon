package com.my.deccanfinance

import android.view.HapticFeedbackConstants
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import org.json.JSONObject
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransferScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onBack: () -> Unit,
    onAddNewBeneficiary: (String) -> Unit,
    onPayoutSuccess: (TransferPayoutResponse) -> Unit
) {
    var transferType by remember { mutableStateOf("DECCAN") } // DECCAN or OTHER
    var amount by remember { mutableStateOf("") }
    var remarks by remember { mutableStateOf("") }
    var method by remember { mutableStateOf("IMPS") }
    var whenToTransfer by remember { mutableStateOf("Now") }

    var beneficiaries by remember { mutableStateOf<List<Beneficiary>>(emptyList()) }
    var selectedBeneficiary by remember { mutableStateOf<Beneficiary?>(null) }
    var showBeneficiaryDropdown by remember { mutableStateOf(false) }

    var showMpinDialog by remember { mutableStateOf(false) }
    var showP2PMpinDialog by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var isProcessing by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val view = LocalView.current

    LaunchedEffect(transferType) {
        scope.launch {
            try {
                val response = if (transferType == "DECCAN") {
                    apiService.getSameBankBeneficiaries()
                } else {
                    apiService.getBeneficiaries()
                }
                
                if (response.isSuccessful && response.body()?.success == true) {
                    beneficiaries = response.body()?.beneficiaries ?: emptyList()
                    if (selectedBeneficiary == null || !beneficiaries.any { it.id == selectedBeneficiary?.id }) {
                        selectedBeneficiary = beneficiaries.firstOrNull()
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    if (showMpinDialog) {
        MpinVerificationDialog(
            onDismiss = { showMpinDialog = false },
            onConfirm = { mpin ->
                showMpinDialog = false
                isLoading = true
                scope.launch {
                    try {
                        val checkResponse = apiService.checkTxStatus(
                            CheckTxStatusRequest(
                                amount = amount.toDoubleOrNull() ?: 0.0,
                                recipientAccount = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                                type = "PAYOUT",
                                recipientName = selectedBeneficiary?.beneficiaryName
                            )
                        )
                        
                        var isTxAllowed = true
                        var failedResponse: TransferPayoutResponse? = null

                        if (checkResponse.isSuccessful) {
                            if (checkResponse.body()?.allowed == false) {
                                isTxAllowed = false
                                val checkBody = checkResponse.body()!!
                                failedResponse = TransferPayoutResponse(
                                    success = false,
                                    message = checkBody.message,
                                    transactionId = checkBody.transactionId,
                                    utrId = null,
                                    provider = "Deccan Finance",
                                    beneficiary = BeneficiaryInfo(
                                        name = selectedBeneficiary?.beneficiaryName ?: "Unknown",
                                        account = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                                        ifsc = selectedBeneficiary?.ifscCode ?: ""
                                    ),
                                    amount = amount.toDoubleOrNull() ?: 0.0,
                                    remarks = checkBody.message,
                                    status = "FAILED",
                                    newBalance = null
                                )
                            }
                        } else if (checkResponse.code() == 400 || checkResponse.code() == 401) {
                            val errorBody = checkResponse.errorBody()?.string()
                            if (errorBody != null) {
                                val jsonObj = org.json.JSONObject(errorBody)
                                if (jsonObj.has("allowed") && !jsonObj.getBoolean("allowed")) {
                                    isTxAllowed = false
                                    failedResponse = TransferPayoutResponse(
                                        success = false,
                                        message = jsonObj.getString("message"),
                                        transactionId = if (jsonObj.has("transaction_id")) jsonObj.getString("transaction_id") else null,
                                        utrId = null,
                                        provider = "Deccan Finance",
                                        beneficiary = BeneficiaryInfo(
                                            name = selectedBeneficiary?.beneficiaryName ?: "Unknown",
                                            account = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                                            ifsc = selectedBeneficiary?.ifscCode ?: ""
                                        ),
                                        amount = amount.toDoubleOrNull() ?: 0.0,
                                        remarks = jsonObj.getString("message"),
                                        status = "FAILED",
                                        newBalance = null
                                    )
                                }
                            }
                        }

                        if (!isTxAllowed && failedResponse != null) {
                            onPayoutSuccess(failedResponse)
                            return@launch
                        }

                        val request = TransferPayoutRequest(
                            provider = "bharat4u",
                            beneficiaryName = selectedBeneficiary?.beneficiaryName ?: "Unknown",
                            beneficiaryAccount = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                            ifscCode = selectedBeneficiary?.ifscCode ?: "",
                            amount = amount.toDoubleOrNull() ?: 0.0,
                            mpin = mpin,
                            remarks = remarks
                        )
                        val response = apiService.transferPayout(request)
                        if (response.isSuccessful && response.body()?.success == true) {
                            response.body()?.let { onPayoutSuccess(it) }
                        } else {
                            errorMessage = response.body()?.message ?: "Transfer failed"
                        }
                    } catch (e: Exception) {
                        errorMessage = "Error: ${e.message}"
                    } finally {
                        isLoading = false
                    }
                }
            }
        )
    }

    if (showP2PMpinDialog) {
        MpinVerificationDialog(
            onDismiss = { showP2PMpinDialog = false },
            onConfirm = { mpin ->
                showP2PMpinDialog = false
                isLoading = true
                scope.launch {
                    try {
                        val checkResponse = apiService.checkTxStatus(
                            CheckTxStatusRequest(
                                amount = amount.toDoubleOrNull() ?: 0.0,
                                recipientAccount = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                                type = "P2P",
                                recipientName = selectedBeneficiary?.beneficiaryName
                            )
                        )

                        var isTxAllowed = true
                        var mappedResponse: TransferPayoutResponse? = null

                        if (checkResponse.isSuccessful) {
                            if (checkResponse.body()?.allowed == false) {
                                isTxAllowed = false
                                val checkBody = checkResponse.body()!!
                                mappedResponse = TransferPayoutResponse(
                                    success = false,
                                    message = checkBody.message,
                                    transactionId = checkBody.transactionId,
                                    utrId = "P2P-${checkBody.transactionId?.takeLast(8)}",
                                    provider = "Deccan Finance",
                                    beneficiary = BeneficiaryInfo(
                                        name = selectedBeneficiary?.beneficiaryName ?: selectedBeneficiary?.beneficiaryAccountNumber ?: "Recipient",
                                        account = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                                        ifsc = selectedBeneficiary?.ifscCode ?: "DECCAN001"
                                    ),
                                    amount = amount.toDoubleOrNull() ?: 0.0,
                                    status = "FAILED",
                                    remarks = checkBody.message,
                                    newBalance = null
                                )
                            }
                        } else if (checkResponse.code() == 400 || checkResponse.code() == 401) {
                            val errorBody = checkResponse.errorBody()?.string()
                            if (errorBody != null) {
                                val jsonObj = org.json.JSONObject(errorBody)
                                if (jsonObj.has("allowed") && !jsonObj.getBoolean("allowed")) {
                                    isTxAllowed = false
                                    mappedResponse = TransferPayoutResponse(
                                        success = false,
                                        message = jsonObj.getString("message"),
                                        transactionId = if (jsonObj.has("transaction_id")) jsonObj.getString("transaction_id") else null,
                                        utrId = "P2P-FAILED",
                                        provider = "Deccan Finance",
                                        beneficiary = BeneficiaryInfo(
                                            name = selectedBeneficiary?.beneficiaryName ?: selectedBeneficiary?.beneficiaryAccountNumber ?: "Recipient",
                                            account = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                                            ifsc = selectedBeneficiary?.ifscCode ?: "DECCAN001"
                                        ),
                                        amount = amount.toDoubleOrNull() ?: 0.0,
                                        status = "FAILED",
                                        remarks = jsonObj.getString("message"),
                                        newBalance = null
                                    )
                                }
                            }
                        }

                        if (!isTxAllowed && mappedResponse != null) {
                            onPayoutSuccess(mappedResponse)
                            return@launch
                        }

                        val request = TransferP2PRequest(
                            recipientAccountNumber = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                            amount = amount.toDoubleOrNull() ?: 0.0,
                            mpin = mpin,
                            remarks = remarks
                        )
                        val response = apiService.transferP2P(request)
                        if (response.isSuccessful && response.body()?.success == true) {
                            val p2pResp = response.body()!!
                            val mappedResponse = TransferPayoutResponse(
                                success = true,
                                message = p2pResp.message,
                                transactionId = p2pResp.transactionId,
                                utrId = "P2P-${p2pResp.transactionId?.takeLast(8)}",
                                provider = "Deccan Finance",
                                beneficiary = BeneficiaryInfo(
                                    name = selectedBeneficiary?.beneficiaryName ?: selectedBeneficiary?.beneficiaryAccountNumber ?: "Recipient",
                                    account = selectedBeneficiary?.beneficiaryAccountNumber ?: "",
                                    ifsc = selectedBeneficiary?.ifscCode ?: "DECCAN001"
                                ),
                                amount = amount.toDoubleOrNull() ?: 0.0,
                                status = "SUCCESS",
                                remarks = p2pResp.remarks ?: remarks,
                                newBalance = p2pResp.newBalance
                            )
                            onPayoutSuccess(mappedResponse)
                        } else {
                            errorMessage = response.body()?.message ?: "P2P Transfer failed"
                        }
                    } catch (e: Exception) {
                        errorMessage = "Error: ${e.message}"
                    } finally {
                        isLoading = false
                    }
                }
            }
        )
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Scaffold(
            modifier = Modifier.blur(if (isProcessing) 10.dp else 0.dp),
            topBar = {
                TopAppBar(
                    title = {
                        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                            Text(
                                "Transfer",
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
                        IconButton(onClick = { /* TODO: History */ }) {
                            Icon(Icons.Outlined.History, contentDescription = "History", tint = DashPrimary)
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
                // Choose Transfer Type
                Text("Choose Transfer Type", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Gray, modifier = Modifier.padding(bottom = 12.dp))
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    TransferTypeCard(
                        title = "Deccan Finance Bank Account",
                        subtitle = "Transfer within Deccan Finance Bank instantly",
                        icon = Icons.Outlined.AccountBalance,
                        isSelected = transferType == "DECCAN",
                        onClick = { 
                            transferType = "DECCAN"
                            selectedBeneficiary = null // Clear to trigger fetch
                        },
                        modifier = Modifier.weight(1f)
                    )
                    TransferTypeCard(
                        title = "Other Bank Account",
                        subtitle = "Transfer to any other bank using NEFT / IMPS",
                        icon = Icons.Outlined.AccountBalance,
                        isSelected = transferType == "OTHER",
                        onClick = { 
                            transferType = "OTHER"
                            selectedBeneficiary = null // Clear to trigger fetch
                        },
                        modifier = Modifier.weight(1f)
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Beneficiary
                Text("Beneficiary", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Gray, modifier = Modifier.padding(bottom = 12.dp))
                Box {
                    Surface(
                        modifier = Modifier.fillMaxWidth().clickable { showBeneficiaryDropdown = true },
                        shape = RoundedCornerShape(12.dp),
                        color = Color.White,
                        border = BorderStroke(1.dp, Color(0xFFF0F0F0))
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Surface(
                                modifier = Modifier.size(48.dp),
                                shape = CircleShape,
                                color = Color(0xFFF5F6FF)
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Text(
                                        selectedBeneficiary?.beneficiaryName?.take(2)?.uppercase() ?: "??",
                                        color = DashPrimary,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 16.sp
                                    )
                                }
                            }
                            Spacer(modifier = Modifier.width(16.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        selectedBeneficiary?.beneficiaryName ?: "Select Beneficiary",
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (selectedBeneficiary != null) Color.Black else Color.Gray
                                    )
                                    Text(
                                        "+ Add New",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = DashPrimary,
                                        modifier = Modifier.clickable { onAddNewBeneficiary(transferType) }
                                    )
                                }
                                Text(
                                    if (selectedBeneficiary?.type == "SELF_BANK") "Deccan Finance Bank" else if (selectedBeneficiary?.type == "OTHER_BANK") "Other Bank" else "N/A",
                                    fontSize = 11.sp,
                                    color = Color.Black.copy(alpha = 0.7f),
                                    fontWeight = FontWeight.Medium
                                )
                                Text(
                                    "A/c No. ${selectedBeneficiary?.beneficiaryAccountNumber ?: "XXXX XXXX XXXX"}",
                                    fontSize = 11.sp,
                                    color = Color.Black.copy(alpha = 0.7f),
                                    fontWeight = FontWeight.Medium
                                )
                            }
                            Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = Color.Gray)
                        }
                    }

                    DropdownMenu(
                        expanded = showBeneficiaryDropdown,
                        onDismissRequest = { showBeneficiaryDropdown = false },
                        modifier = Modifier.fillMaxWidth(0.9f).background(Color.White)
                    ) {
                        if (beneficiaries.isEmpty()) {
                            DropdownMenuItem(
                                text = { Text("No beneficiaries found", fontSize = 14.sp, color = Color.Gray) },
                                onClick = { showBeneficiaryDropdown = false }
                            )
                        } else {
                            beneficiaries.forEach { beneficiary ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(beneficiary.beneficiaryName, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                                            Text(beneficiary.beneficiaryAccountNumber, fontSize = 12.sp, color = Color.Gray)
                                        }
                                    },
                                    onClick = {
                                        selectedBeneficiary = beneficiary
                                        showBeneficiaryDropdown = false
                                    }
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Transfer Details
                Text("Transfer Details", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Gray, modifier = Modifier.padding(bottom = 12.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, Color(0xFFF0F0F0))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Enter Amount", fontSize = 11.sp, color = Color.Black.copy(alpha = 0.7f), fontWeight = FontWeight.Medium)
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("₹ ", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            BasicTextField(
                                value = amount,
                                onValueChange = { amount = it },
                                textStyle = TextStyle(fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.Black),
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                                modifier = Modifier.fillMaxWidth(),
                                decorationBox = { innerTextField ->
                                    if (amount.isEmpty()) Text("0.00", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.Gray.copy(alpha = 0.5f))
                                    innerTextField()
                                }
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Surface(
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, Color(0xFFF0F0F0)),
                                color = Color.White
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Text("Transfer Method", fontSize = 10.sp, color = Color.Black.copy(alpha = 0.7f), fontWeight = FontWeight.Medium)
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                        Text(method, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                                        Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color.Gray)
                                    }
                                }
                            }
                            Surface(
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, Color(0xFFF0F0F0)),
                                color = Color.White
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Text("When to transfer", fontSize = 10.sp, color = Color.Black.copy(alpha = 0.7f), fontWeight = FontWeight.Medium)
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                        Text(whenToTransfer, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color.Gray)
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Icon(Icons.Default.CalendarMonth, contentDescription = null, modifier = Modifier.size(16.dp), tint = DashPrimary)
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(8.dp),
                            border = BorderStroke(1.dp, Color(0xFFF0F0F0)),
                            color = Color.White
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text("Remarks (Optional)", fontSize = 10.sp, color = Color.Black.copy(alpha = 0.7f), fontWeight = FontWeight.Medium)
                                BasicTextField(
                                    value = remarks,
                                    onValueChange = { remarks = it },
                                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
                                    textStyle = TextStyle(fontSize = 13.sp, color = Color.Black),
                                    decorationBox = { innerTextField ->
                                        if (remarks.isEmpty()) Text("e.g. Payment for services", fontSize = 13.sp, color = Color.LightGray)
                                        innerTextField()
                                    }
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Review & Confirm
                Text("Review & Confirm", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Gray, modifier = Modifier.padding(bottom = 12.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    color = Color(0xFFF8F9FF)
                ) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        ReviewRow("Transfer Type", if (transferType == "DECCAN") "Deccan Finance Bank Account" else "Other Bank Account")
                        ReviewRow("Beneficiary", selectedBeneficiary?.beneficiaryName ?: "N/A")
                        ReviewRow("Account Number", selectedBeneficiary?.beneficiaryAccountNumber ?: "N/A")
                        ReviewRow("Amount", "₹ ${amount.ifEmpty { "0.00" }}")
                        if (remarks.isNotEmpty()) {
                            ReviewRow("Remarks", remarks)
                        }
                        ReviewRow("Transfer Method", method)
                        
                        HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp), thickness = 0.5.dp, color = DashPrimary.copy(alpha = 0.1f))
                        
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Total Debit Amount", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            Text("₹ ${amount.ifEmpty { "0.00" }}", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DashPrimary)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.Security, contentDescription = null, modifier = Modifier.size(14.dp), tint = DashPrimary)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("IMPS transfers are instant and available 24x7.", fontSize = 11.sp, color = Color.Gray)
                }

                if (errorMessage != null) {
                    Text(errorMessage!!, color = Color.Red, fontSize = 12.sp, modifier = Modifier.padding(top = 8.dp))
                }

                Spacer(modifier = Modifier.height(32.dp))

                Button(
                    onClick = { 
                        if (selectedBeneficiary != null && amount.isNotEmpty()) {
                            view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                            isProcessing = true
                            scope.launch {
                                delay(1500) // Simulated processing
                                isProcessing = false
                                if (transferType == "OTHER") showMpinDialog = true else showP2PMpinDialog = true
                            }
                        }
                    },
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = DashPrimary,
                        disabledContainerColor = DashPrimary.copy(alpha = 0.3f),
                        disabledContentColor = Color.White.copy(alpha = 0.5f)
                    ),
                    enabled = !isLoading && !isProcessing && selectedBeneficiary != null && amount.isNotEmpty()
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                    } else {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Confirm & Transfer", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(20.dp))
            }
        }

        if (isProcessing) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = Color.Black.copy(alpha = 0.3f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = Color.White,
                        modifier = Modifier.padding(32.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            CircularProgressIndicator(color = DashPrimary)
                            Spacer(modifier = Modifier.height(16.dp))
                            Text("Processing...", fontWeight = FontWeight.Bold, color = Color.Black)
                            Text("Verifying transfer details", fontSize = 12.sp, color = Color.Gray)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ReviewRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, fontSize = 12.sp, color = Color.Gray)
        Text(value, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Black)
    }
}

@Composable
fun TransferTypeCard(title: String, subtitle: String, icon: ImageVector, isSelected: Boolean, onClick: () -> Unit, modifier: Modifier) {
    Surface(
        modifier = modifier
            .height(150.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        border = BorderStroke(1.5.dp, if (isSelected) DashPrimary else Color(0xFFE5E7EB)),
        color = Color.White
    ) {
        Box(modifier = Modifier.padding(16.dp)) {
            Column {
                Surface(
                    modifier = Modifier.size(44.dp),
                    shape = RoundedCornerShape(12.dp),
                    color = if (isSelected) Color(0xFFF5F6FF) else Color(0xFFF9FAFB)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(icon, contentDescription = null, tint = if (isSelected) DashPrimary else Color.Gray, modifier = Modifier.size(24.dp))
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
                Text(title, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.Black, lineHeight = 16.sp)
                Spacer(modifier = Modifier.height(4.dp))
                Text(subtitle, fontSize = 10.sp, color = Color.Gray, lineHeight = 13.sp)
            }
            Box(modifier = Modifier.align(Alignment.TopEnd)) {
                if (isSelected) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(22.dp))
                } else {
                    Box(modifier = Modifier.size(22.dp).border(1.5.dp, Color(0xFFD1D5DB), CircleShape))
                }
            }
        }
    }
}
