package com.my.deccanfinance

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UpdateProfileScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onBack: () -> Unit
) {
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    val scope = rememberCoroutineScope()

    var fullName by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var nationalId by remember { mutableStateOf("") }
    var dob by remember { mutableStateOf("") }
    var gender by remember { mutableStateOf("") }

    var isLoading by remember { mutableStateOf(false) }
    var showSuccessDialog by remember { mutableStateOf(false) }
    var showErrorDialog by remember { mutableStateOf(false) }
    var alertMessage by remember { mutableStateOf("") }

    var showDatePicker by remember { mutableStateOf(false) }
    val datePickerState = rememberDatePickerState()

    LaunchedEffect(Unit) {
        val response = apiService.getUserDetails()
        if (response.isSuccessful) {
            response.body()?.user?.let { user ->
                fullName = user.fullName
                address = user.address
                nationalId = user.nationalId
                dob = user.dob ?: ""
                gender = user.gender ?: ""
            }
        }
    }

    if (showDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        val date = Date(millis)
                        val formatter = SimpleDateFormat("dd MMMM yyyy", Locale.getDefault())
                        dob = formatter.format(date)
                    }
                    showDatePicker = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) {
                    Text("Cancel")
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                        Text("Update Profile", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1A1C1E))
                        Text("Keep your information up to date", fontSize = 12.sp, color = Color.Gray)
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = DashPrimary)
                    }
                },
                actions = { Spacer(modifier = Modifier.width(48.dp)) },
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
            // Profile Header
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                color = Color(0xFFF0F2FF)
            ) {
                Row(
                    modifier = Modifier.padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box {
                        Surface(
                            modifier = Modifier.size(80.dp),
                            shape = CircleShape,
                            color = Color.White
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.Person, contentDescription = null, modifier = Modifier.size(50.dp), tint = Color.LightGray)
                            }
                        }
                        Surface(
                            modifier = Modifier
                                .size(28.dp)
                                .align(Alignment.BottomEnd)
                                .offset(x = 4.dp, y = 4.dp),
                            shape = CircleShape,
                            color = Color.White,
                            shadowElevation = 2.dp,
                            border = BorderStroke(1.dp, Color(0xFFE0E0E0))
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.PhotoCamera, contentDescription = "Edit", modifier = Modifier.size(14.dp), tint = DashPrimary)
                            }
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text(fullName, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.VerifiedUser, contentDescription = null, modifier = Modifier.size(14.dp), tint = DashPrimary)
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Profile last updated on 15 May 2024", fontSize = 11.sp, color = Color.Gray)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Contact Information
            ProfileSectionHeader("Contact Information")
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color.White
            ) {
                Column {
                    ReadOnlyItem(
                        icon = Icons.Outlined.Smartphone,
                        label = "Mobile Number",
                        value = (userData["phone"] as? String) ?: "9876543210"
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    ReadOnlyItem(
                        icon = Icons.Outlined.Email,
                        label = "Email Address",
                        value = (userData["email"] as? String) ?: "raju@rastogi.com"
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Personal Information
            ProfileSectionHeader("Personal Information")
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                UpdateFieldItem(
                    icon = Icons.Outlined.Person,
                    label = "Full Name",
                    value = fullName,
                    onValueChange = { fullName = it }
                )
                UpdateFieldItem(
                    icon = Icons.Outlined.Home,
                    label = "Residential Address",
                    value = address,
                    onValueChange = { address = it },
                    singleLine = false
                )
                UpdateFieldItem(
                    icon = Icons.Outlined.Badge,
                    label = "National ID / PAN",
                    value = nationalId,
                    onValueChange = { nationalId = it }
                )
                UpdateFieldItem(
                    icon = Icons.Outlined.CalendarToday,
                    label = "Date of Birth",
                    value = dob,
                    onValueChange = { },
                    trailingIcon = Icons.Outlined.CalendarMonth,
                    isClickable = true,
                    onClick = { showDatePicker = true }
                )
                UpdateFieldItem(
                    icon = Icons.Outlined.Group,
                    label = "Gender",
                    value = gender,
                    onValueChange = { },
                    trailingIcon = Icons.Default.KeyboardArrowDown,
                    isClickable = true,
                    onClick = { /* TODO: Dropdown */ }
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Security Notice
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color(0xFFF8F9FF)
            ) {
                Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.Shield, contentDescription = null, tint = DashPrimary)
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text("Your information is safe with us", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        Text("We use industry-standard security to protect your personal data.", fontSize = 11.sp, color = Color.Gray)
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Buttons
            Button(
                onClick = {
                    isLoading = true
                    scope.launch {
                        try {
                            val request = UpdateProfileRequest(
                                fullName = fullName,
                                address = address,
                                nationalId = nationalId,
                                dob = dob,
                                gender = gender
                            )
                            val response = apiService.updateProfile(request)
                            if (response.isSuccessful && response.body()?.success == true) {
                                val detailsResp = apiService.getUserDetails()
                                if (detailsResp.isSuccessful) {
                                    detailsResp.body()?.user?.let { dataManager.saveUserData(it) }
                                }
                                alertMessage = "Profile updated successfully!"
                                showSuccessDialog = true
                            } else {
                                alertMessage = response.body()?.message ?: "Update failed"
                                showErrorDialog = true
                            }
                        } catch (e: Exception) {
                            alertMessage = "Error: ${e.message}"
                            showErrorDialog = true
                        } finally {
                            isLoading = false
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = DashPrimary),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text("Save Changes", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }

            TextButton(
                onClick = onBack,
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp)
            ) {
                Text("Cancel", color = DashPrimary, fontWeight = FontWeight.Bold)
            }
        }
    }

    if (showSuccessDialog) {
        SweetAlert(
            title = "Success",
            message = alertMessage,
            isSuccess = true,
            onDismiss = {
                showSuccessDialog = false
                onBack()
            }
        )
    }

    if (showErrorDialog) {
        SweetAlert(
            title = "Oops...",
            message = alertMessage,
            isSuccess = false,
            onDismiss = { showErrorDialog = false }
        )
    }
}

@Composable
fun ReadOnlyItem(icon: ImageVector, label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(16.dp),
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
        Surface(
            color = Color(0xFFF5F6FF),
            shape = RoundedCornerShape(4.dp)
        ) {
            Text(
                "Read-only",
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                fontSize = 10.sp,
                color = DashPrimary,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun UpdateFieldItem(
    icon: ImageVector,
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    singleLine: Boolean = true,
    trailingIcon: ImageVector? = null,
    isClickable: Boolean = false,
    onClick: () -> Unit = {}
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (isClickable) Modifier.clickable { onClick() } else Modifier),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, Color(0xFFF0F0F0))
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(36.dp),
                shape = RoundedCornerShape(8.dp),
                color = Color(0xFFF5F6FF)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                }
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(label, fontSize = 11.sp, color = Color.Gray)
                if (isClickable) {
                    Text(if (value.isEmpty()) "Select $label" else value, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = if (value.isEmpty()) Color.LightGray else Color.Black)
                } else {
                    BasicTextField(
                        value = value,
                        onValueChange = onValueChange,
                        textStyle = androidx.compose.ui.text.TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black),
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = singleLine
                    )
                }
            }
            if (trailingIcon != null) {
                Icon(trailingIcon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
            }
        }
    }
}

@Composable
fun SweetAlert(
    title: String,
    message: String,
    isSuccess: Boolean,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = Color.White,
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = if (isSuccess) Icons.Default.CheckCircle else Icons.Default.Error,
                    contentDescription = null,
                    tint = if (isSuccess) Color(0xFF10B981) else Color(0xFFEF4444),
                    modifier = Modifier.size(80.dp)
                )
                
                Spacer(modifier = Modifier.height(20.dp))
                
                Text(title, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, color = Color.Black)
                
                Spacer(modifier = Modifier.height(12.dp))
                
                Text(
                    message,
                    fontSize = 16.sp,
                    color = Color.Gray,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(32.dp))
                
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth().height(50.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (isSuccess) Color(0xFF10B981) else Color(0xFFEF4444)
                    )
                ) {
                    Text("OK", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
