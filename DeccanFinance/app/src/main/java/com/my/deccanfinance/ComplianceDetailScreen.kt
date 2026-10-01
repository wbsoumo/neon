package com.my.deccanfinance

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ComplianceDetailScreen(
    title: String,
    type: String,
    apiService: ApiService,
    onBack: () -> Unit
) {
    var complianceData by remember { mutableStateOf<ComplianceResponse?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(type) {
        scope.launch {
            try {
                val response = when (type) {
                    "SOF" -> apiService.getSOF()
                    "FDI" -> apiService.getFDI()
                    "FEMA" -> apiService.getFEMA()
                    "AML" -> apiService.getAML()
                    else -> null
                }

                if (response != null && response.isSuccessful) {
                    complianceData = response.body()
                } else if (response?.code() == 401) {
                    error = "Unauthorized. Please log in again."
                } else {
                    error = "Failed to load compliance details."
                }
            } catch (e: Exception) {
                error = "An error occurred: ${e.message}"
            } finally {
                isLoading = false
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(title, fontWeight = FontWeight.Bold, color = Color.Black) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack, 
                            contentDescription = "Back",
                            tint = Color.Black
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                    titleContentColor = Color.Black,
                    navigationIconContentColor = Color.Black
                )
            )
        },
        containerColor = Color(0xFFF8F9FF)
    ) { padding ->
        Box(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
        ) {
            if (isLoading) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (error != null) {
                Column(
                    modifier = Modifier.align(Alignment.Center).padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(error!!, color = Color.Red, textAlign = TextAlign.Center)
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(onClick = { 
                        isLoading = true
                        error = null
                    }) {
                        Text("Retry")
                    }
                }
            } else if (complianceData != null) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(24.dp)
                ) {
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(24.dp),
                        color = Color.White,
                        shadowElevation = 2.dp
                    ) {
                        Column(modifier = Modifier.padding(24.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Outlined.Description,
                                    contentDescription = null,
                                    tint = DashPrimary,
                                    modifier = Modifier.size(24.dp)
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    "Compliance Notice",
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.Black
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            Text(
                                text = if (complianceData?.text.isNullOrEmpty()) "No description available." else complianceData!!.text!!,
                                fontSize = 14.sp,
                                color = Color(0xFF374151),
                                lineHeight = 20.sp
                            )
                            
                            if (!complianceData?.imageUrl.isNullOrEmpty()) {
                                Spacer(modifier = Modifier.height(24.dp))
                                Text("Attached Image", fontSize = 14.sp, fontWeight = FontWeight.Bold)
                                Spacer(modifier = Modifier.height(12.dp))
                                AsyncImage(
                                    model = complianceData!!.imageUrl,
                                    contentDescription = "Compliance Image",
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(200.dp)
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(Color.LightGray.copy(alpha = 0.3f)),
                                    contentScale = ContentScale.Crop
                                )
                            }
                            
                            if (!complianceData?.pdfUrl.isNullOrEmpty()) {
                                Spacer(modifier = Modifier.height(24.dp))
                                Button(
                                    onClick = { /* Handle PDF view/download */ },
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(12.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = DashPrimary)
                                ) {
                                    Icon(Icons.Outlined.FileDownload, contentDescription = null)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("Download PDF Document", fontWeight = FontWeight.Bold)
                                }
                            }

                            Spacer(modifier = Modifier.height(24.dp))
                            HorizontalDivider(thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.5f))
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column {
                                    Text("Created At", fontSize = 10.sp, color = Color(0xFF6B7280))
                                    Text(complianceData?.createdAt ?: "N/A", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                                }
                                Column(horizontalAlignment = Alignment.End) {
                                    Text("App ID", fontSize = 10.sp, color = Color(0xFF6B7280))
                                    Text(complianceData?.appId ?: "N/A", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                                }
                            }
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(32.dp))
                    
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        color = Color(0xFFE8F5E9)
                    ) {
                        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF2E7D32))
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                "This is an official regulatory compliance document issued for your account.",
                                fontSize = 12.sp,
                                color = Color(0xFF2E7D32),
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
            } else {
                Text("No data found.", modifier = Modifier.align(Alignment.Center))
            }
        }
    }
}
