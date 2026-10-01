package com.my.deccanfinance

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Backspace
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SetLoginPinScreen(
    apiService: ApiService,
    dataManager: DataManager,
    onSuccess: () -> Unit,
    onBack: () -> Unit
) {
    var pin by remember { mutableStateOf("") }
    var confirmPin by remember { mutableStateOf("") }
    var isConfirming by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    fun handleKeyPress(key: String) {
        if (key == "delete") {
            if (isConfirming) {
                if (confirmPin.isNotEmpty()) confirmPin = confirmPin.dropLast(1)
                else isConfirming = false
            } else {
                if (pin.isNotEmpty()) pin = pin.dropLast(1)
            }
        } else {
            if (!isConfirming) {
                if (pin.length < 4) pin += key
                if (pin.length == 4) isConfirming = true
            } else {
                if (confirmPin.length < 4) confirmPin += key
                if (confirmPin.length == 4) {
                    if (pin == confirmPin) {
                        isLoading = true
                        scope.launch {
                            try {
                                val response = apiService.setLoginPin(SetLoginPinRequest(pin))
                                if (response.isSuccessful && response.body()?.success == true) {
                                    dataManager.setLoginPinEnabled(true)
                                    apiService.toggleLoginSettings(ToggleLoginSettingsRequest(pinLoginEnabled = true))
                                    onSuccess()
                                } else {
                                    snackbarHostState.showSnackbar(response.body()?.message ?: "Failed to set PIN")
                                    pin = ""
                                    confirmPin = ""
                                    isConfirming = false
                                }
                            } catch (e: Exception) {
                                snackbarHostState.showSnackbar("Error: ${e.message}")
                            } finally {
                                isLoading = false
                            }
                        }
                    } else {
                        scope.launch {
                            snackbarHostState.showSnackbar("PINs do not match. Try again.")
                        }
                        confirmPin = ""
                    }
                }
            }
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text(if (isConfirming) "Confirm PIN" else "Set Login PIN", fontWeight = FontWeight.Bold) },
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
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(40.dp))
            
            Surface(
                modifier = Modifier.size(80.dp),
                shape = CircleShape,
                color = DashPrimary.copy(alpha = 0.1f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Default.Backspace, 
                        contentDescription = null, 
                        tint = DashPrimary, 
                        modifier = Modifier.size(32.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Text(
                if (isConfirming) "Re-enter your 4-digit PIN" else "Create a secure 4-digit PIN for quick login",
                fontSize = 16.sp,
                color = Color.Gray,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(40.dp))
            
            // PIN Indicators
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                val displayPin = if (isConfirming) confirmPin else pin
                repeat(4) { index ->
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 8.dp)
                            .size(16.dp)
                            .clip(CircleShape)
                            .background(if (index < displayPin.length) DashPrimary else Color.LightGray.copy(alpha = 0.5f))
                    )
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            if (isLoading) {
                CircularProgressIndicator(color = DashPrimary)
                Spacer(modifier = Modifier.weight(1f))
            } else {
                // Keypad
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    val keys = listOf(
                        listOf("1", "2", "3"),
                        listOf("4", "5", "6"),
                        listOf("7", "8", "9"),
                        listOf("", "0", "delete")
                    )
                    
                    keys.forEach { row ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            row.forEach { key ->
                                if (key.isEmpty()) {
                                    Spacer(modifier = Modifier.size(72.dp))
                                } else {
                                    Surface(
                                        onClick = { handleKeyPress(key) },
                                        modifier = Modifier.size(72.dp),
                                        shape = CircleShape,
                                        color = Color.White,
                                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFF0F0F0))
                                    ) {
                                        Box(contentAlignment = Alignment.Center) {
                                            if (key == "delete") {
                                                Icon(Icons.Default.Backspace, contentDescription = "Delete", tint = DashPrimary)
                                            } else {
                                                Text(key, fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}
