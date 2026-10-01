package com.my.deccanfinance

import android.net.Uri
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.SendAndArchive
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReceiveMoneyScreen(
    dataManager: DataManager,
    onBack: () -> Unit
) {
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    var selectedTab by remember { mutableIntStateOf(0) } // 0 for My QR, 1 for My Details
    
    val accountNumber = userData["account_number"] as? String ?: "—"
    val fullName = userData["full_name"] as? String ?: "User"
    val phone = userData["phone"] as? String ?: "—"

    val clipboardManager = LocalClipboardManager.current
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    fun copyToClipboard(text: String, label: String) {
        clipboardManager.setText(AnnotatedString(text))
        scope.launch {
            snackbarHostState.showSnackbar("$label copied to clipboard")
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(
                            "Receive Money",
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
                actions = {
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(end = 8.dp)) {
                        Icon(Icons.Outlined.VerifiedUser, contentDescription = "Secure", tint = DashPrimary, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Secure", color = DashPrimary, fontSize = 12.sp, fontWeight = FontWeight.Bold)
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
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                "Share your QR code or details to receive money instantly",
                fontSize = 14.sp,
                color = Color.Gray,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(bottom = 24.dp)
            )

            // Tab Switcher
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(28.dp),
                color = Color(0xFFF3F4FF),
            ) {
                Row(
                    modifier = Modifier.fillMaxSize().padding(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .clip(RoundedCornerShape(24.dp))
                            .background(if (selectedTab == 0) Color.White else Color.Transparent)
                            .clickable { selectedTab = 0 },
                        contentAlignment = Alignment.Center
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.QrCodeScanner, contentDescription = null, tint = if (selectedTab == 0) DashPrimary else Color.Gray, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("My QR Code", color = if (selectedTab == 0) DashPrimary else Color.Gray, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        }
                    }
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .clip(RoundedCornerShape(24.dp))
                            .background(if (selectedTab == 1) Color.White else Color.Transparent)
                            .clickable { selectedTab = 1 },
                        contentAlignment = Alignment.Center
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Person, contentDescription = null, tint = if (selectedTab == 1) DashPrimary else Color.Gray, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("My Details", color = if (selectedTab == 1) DashPrimary else Color.Gray, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            if (selectedTab == 0) {
                QrCard(fullName = fullName, accountNumber = accountNumber, phone = phone)
            } else {
                DetailsCard(fullName = fullName, accountNumber = accountNumber, phone = phone, onCopy = ::copyToClipboard)
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Unavailable Notice
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                color = Color(0xFFFFF9F2)
            ) {
                Row(
                    modifier = Modifier.padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        modifier = Modifier.size(48.dp),
                        shape = CircleShape,
                        color = Color(0xFFFFEBDD)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.AutoMirrored.Filled.SendAndArchive, contentDescription = null, tint = Color(0xFFF05A28))
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Request Money is Unavailable", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        Text("Request Money feature is temporarily disabled due to policy changes.", fontSize = 12.sp, color = Color.Gray)
                        Spacer(modifier = Modifier.height(8.dp))
                        Surface(color = Color(0xFFFFEBDD), shape = RoundedCornerShape(4.dp)) {
                            Text("Coming Soon", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color(0xFFF05A28), modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp))
                        }
                    }
                    // Banking Icon simulated
                    Icon(Icons.Default.AccountBalance, contentDescription = null, modifier = Modifier.size(40.dp).alpha(0.1f), tint = Color.Gray)
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Security Footer
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color(0xFFF5F6FF)
            ) {
                Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Surface(modifier = Modifier.size(40.dp), shape = CircleShape, color = Color.White) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Default.Shield, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text("100% Safe & Secure", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        Text("Your transactions are protected with industry standard security.", fontSize = 11.sp, color = Color.Gray)
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
fun QrCard(fullName: String, accountNumber: String, phone: String) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        color = Color.White,
        shadowElevation = 2.dp
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    modifier = Modifier.size(60.dp),
                    shape = CircleShape,
                    color = Color.White
                ) {
                    AsyncImage(
                        model = "file:///android_asset/icon.jpeg",
                        contentDescription = "Logo",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = androidx.compose.ui.layout.ContentScale.Crop
                    )
                }
                Spacer(modifier = Modifier.width(16.dp))
                Column {
                    Text("Deccan Finance", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = Color.Black)
                    Text("Scan this code to send money", fontSize = 12.sp, color = Color.Gray)
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
            HorizontalDivider(thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.5f), modifier = Modifier.padding(bottom = 24.dp))

            // QR Code
            Surface(
                modifier = Modifier.size(240.dp).padding(4.dp),
                shape = RoundedCornerShape(12.dp),
                border = BorderStroke(1.dp, DashPrimary.copy(alpha = 0.3f)),
                color = Color.White
            ) {
                Box(contentAlignment = Alignment.Center) {
                    val qrData = "accountno=$accountNumber&name=$fullName&mobilenumber=$phone"
                    val qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${Uri.encode(qrData)}"
                    AsyncImage(
                        model = qrUrl,
                        contentDescription = "QR Code",
                        modifier = Modifier.fillMaxSize(0.9f)
                    )
                    
                    // Center logo
                    Surface(
                        modifier = Modifier.size(48.dp),
                        shape = CircleShape,
                        color = Color.White,
                        shadowElevation = 4.dp
                    ) {
                        AsyncImage(
                            model = "file:///android_asset/icon.jpeg",
                            contentDescription = "Logo",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = androidx.compose.ui.layout.ContentScale.Crop
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(
                    onClick = { },
                    modifier = Modifier.weight(1f).height(48.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFF3F4FF))
                ) {
                    Icon(Icons.Default.Share, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Share QR", color = DashPrimary, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                }
                Button(
                    onClick = { },
                    modifier = Modifier.weight(1f).height(48.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFF3F4FF))
                ) {
                    Icon(Icons.Default.Download, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Download QR", color = DashPrimary, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
fun DetailsCard(fullName: String, accountNumber: String, phone: String, onCopy: (String, String) -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        color = Color.White,
        shadowElevation = 2.dp
    ) {
        Column(modifier = Modifier.padding(24.dp)) {
            Text("Account Details", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Spacer(modifier = Modifier.height(20.dp))
            
            DetailItem(label = "Account Holder", value = fullName)
            DetailItem(label = "Account Number", value = accountNumber, canCopy = true, onCopy = { onCopy(accountNumber, "Account Number") })
            DetailItem(label = "IFSC Code", value = "NBFC0001234", canCopy = true, onCopy = { onCopy("NBFC0001234", "IFSC Code") })
            DetailItem(label = "Bank Name", value = "Deccan Finance")
            DetailItem(label = "Mobile Number", value = phone)
        }
    }
}

@Composable
fun DetailItem(label: String, value: String, canCopy: Boolean = false, onCopy: () -> Unit = {}) {
    Column(modifier = Modifier.padding(bottom = 16.dp)) {
        Text(label, fontSize = 12.sp, color = Color.Gray)
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(value, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            if (canCopy) {
                Icon(
                    Icons.Default.ContentCopy, 
                    contentDescription = "Copy", 
                    tint = DashPrimary, 
                    modifier = Modifier.size(18.dp).clickable { onCopy() }
                )
            }
        }
        HorizontalDivider(modifier = Modifier.padding(top = 8.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
    }
}
