package com.my.deccanfinance

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
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
import coil.compose.AsyncImage
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BeneficiaryListScreen(
    apiService: ApiService,
    onBack: () -> Unit,
    onAddOtherBank: () -> Unit,
    onAddSameBank: () -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    var beneficiaries by remember { mutableStateOf<List<Beneficiary>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var showAddPopup by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState()

    LaunchedEffect(Unit) {
        try {
            val response = apiService.getBeneficiaries()
            if (response.isSuccessful) {
                beneficiaries = response.body()?.beneficiaries ?: emptyList()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            isLoading = false
        }
    }

    val filteredBeneficiaries = beneficiaries.filter {
        it.beneficiaryName.contains(searchQuery, ignoreCase = true) ||
        it.beneficiaryAccountNumber.contains(searchQuery) ||
        (it.nickname?.contains(searchQuery, ignoreCase = true) ?: false)
    }

    if (showAddPopup) {
        ModalBottomSheet(
            onDismissRequest = { showAddPopup = false },
            sheetState = sheetState,
            dragHandle = { BottomSheetDefaults.DragHandle() },
            containerColor = Color.White
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp)
                    .padding(bottom = 32.dp)
            ) {
                Text(
                    "Add New Beneficiary",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
                Text(
                    "Choose the type of account you want to add",
                    fontSize = 14.sp,
                    color = Color.Gray,
                    modifier = Modifier.padding(top = 4.dp, bottom = 24.dp)
                )

                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color(0xFFF5F6FF),
                    onClick = {
                        showAddPopup = false
                        onAddSameBank()
                    }
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
                                Icon(Icons.Default.AccountBalance, contentDescription = null, tint = DashPrimary)
                            }
                        }
                        Spacer(modifier = Modifier.width(16.dp))
                        Column {
                            Text("Deccan Finance", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            Text("Transfer within Deccan Finance accounts", fontSize = 12.sp, color = Color.Gray)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color(0xFFF0FDF4),
                    onClick = {
                        showAddPopup = false
                        onAddOtherBank()
                    }
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
                                Icon(Icons.Default.AccountBalanceWallet, contentDescription = null, tint = Color(0xFF16A34A))
                            }
                        }
                        Spacer(modifier = Modifier.width(16.dp))
                        Column {
                            Text("Other Bank Account", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            Text("HDFC, Axis, SBI, ICICI & others", fontSize = 12.sp, color = Color.Gray)
                        }
                    }
                }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(
                            "My Beneficiaries",
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
                    IconButton(onClick = { /* Help */ }) {
                        Icon(Icons.AutoMirrored.Outlined.HelpOutline, contentDescription = "Help", tint = DashPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        },
        containerColor = Color(0xFFF8F9FF),
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color.White)
                    .padding(horizontal = 24.dp, vertical = 16.dp)
            ) {
                Button(
                    onClick = { showAddPopup = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = DashPrimary)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.PersonAdd, contentDescription = null, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Add New Beneficiary", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.Lock, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Your transfers are safe and secure", fontSize = 12.sp, color = Color.Gray)
                }
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(horizontal = 20.dp)
        ) {
            item {
                Spacer(modifier = Modifier.height(16.dp))
                
                // Search and Filter Bar
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        modifier = Modifier.weight(1f).height(48.dp),
                        shape = RoundedCornerShape(12.dp),
                        color = Color.White,
                        border = BorderStroke(1.dp, Color(0xFFF0F0F0))
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.Search, contentDescription = null, tint = Color.LightGray, modifier = Modifier.size(20.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            BasicTextField(
                                value = searchQuery,
                                onValueChange = { searchQuery = it },
                                textStyle = TextStyle(fontSize = 14.sp, color = Color.Black),
                                modifier = Modifier.weight(1f),
                                decorationBox = { innerTextField ->
                                    if (searchQuery.isEmpty()) Text("Search by name, account number or bank", fontSize = 13.sp, color = Color.LightGray)
                                    innerTextField()
                                }
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Surface(
                        modifier = Modifier.height(48.dp),
                        shape = RoundedCornerShape(12.dp),
                        color = Color.White,
                        border = BorderStroke(1.dp, Color(0xFFF0F0F0)),
                        onClick = { /* Filter */ }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.FilterList, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Filter", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DashPrimary)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Info Banner
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color(0xFFF0F2FF)
                ) {
                    Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Surface(modifier = Modifier.size(40.dp), shape = CircleShape, color = Color.White.copy(alpha = 0.5f)) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Outlined.Shield, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                            }
                        }
                        Spacer(modifier = Modifier.width(16.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Secure & Verified", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            Text("All beneficiaries are verified before enabling money transfer.", fontSize = 11.sp, color = Color.Gray)
                        }
                        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.Gray)
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))
            }

            // Frequently used section (simulated with first 2 items)
            if (filteredBeneficiaries.isNotEmpty() && searchQuery.isEmpty()) {
                item {
                    SectionTitleRow("Frequently used", "Edit")
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        color = Color.White
                    ) {
                        Column {
                            filteredBeneficiaries.take(2).forEachIndexed { index, beneficiary ->
                                BeneficiaryItem(beneficiary, isFavorite = true)
                                if (index < 1 && filteredBeneficiaries.size > 1) {
                                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color(0xFFF8F9FF))
                                }
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(24.dp))
                }
            }

            // All Beneficiaries section
            item {
                SectionTitleRow("All Beneficiaries", "+ Add Beneficiary", onActionClick = { showAddPopup = true })
            }

            if (isLoading) {
                item {
                    Box(modifier = Modifier.fillMaxWidth().padding(40.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = DashPrimary)
                    }
                }
            } else if (filteredBeneficiaries.isEmpty()) {
                item {
                    Box(modifier = Modifier.fillMaxWidth().padding(40.dp), contentAlignment = Alignment.Center) {
                        Text("No beneficiaries found", color = Color.Gray)
                    }
                }
            } else {
                item {
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        color = Color.White
                    ) {
                        Column {
                            filteredBeneficiaries.forEachIndexed { index, beneficiary ->
                                BeneficiaryItem(beneficiary)
                                if (index < filteredBeneficiaries.size - 1) {
                                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), thickness = 0.5.dp, color = Color(0xFFF8F9FF))
                                }
                            }
                        }
                    }
                }
            }
            
            item {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
fun SectionTitleRow(title: String, actionText: String, onActionClick: () -> Unit = {}) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp, start = 4.dp, end = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(title, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Color.Black)
        Text(
            text = actionText,
            fontSize = 13.sp,
            fontWeight = FontWeight.Bold,
            color = DashPrimary,
            modifier = Modifier.clickable { onActionClick() }
        )
    }
}

@Composable
fun BeneficiaryItem(beneficiary: Beneficiary, isFavorite: Boolean = false) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Initials Avatar
        Surface(
            modifier = Modifier.size(48.dp),
            shape = CircleShape,
            color = if (beneficiary.type == "SELF_BANK") Color.White else Color(0xFFF3F4FF)
        ) {
            if (beneficiary.type == "SELF_BANK") {
                AsyncImage(
                    model = "file:///android_asset/icon.jpeg",
                    contentDescription = "Logo",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = androidx.compose.ui.layout.ContentScale.Crop
                )
            } else {
                val initials = beneficiary.beneficiaryName.split(" ").take(2).map { it.firstOrNull() ?: "" }.joinToString("")
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = initials,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = DashPrimary
                    )
                }
            }
        }

        Spacer(modifier = Modifier.width(16.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(beneficiary.beneficiaryName, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Text(
                text = "${if (beneficiary.type == "SELF_BANK") "Deccan Finance" else (beneficiary.nickname ?: "Bank")} • ${beneficiary.beneficiaryAccountNumber}",
                fontSize = 12.sp,
                color = Color.Gray
            )
            Spacer(modifier = Modifier.height(4.dp))
            
            // Status Badge
            Surface(
                color = if (beneficiary.status == "APPROVED") Color(0xFFE8FDF5) else Color(0xFFFFF7ED),
                shape = RoundedCornerShape(4.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = if (beneficiary.status == "APPROVED") Icons.Default.CheckCircle else Icons.Default.AccessTime,
                        contentDescription = null,
                        tint = if (beneficiary.status == "APPROVED") Color(0xFF10B981) else Color(0xFFF59E0B),
                        modifier = Modifier.size(12.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = if (beneficiary.status == "APPROVED") "Verified" else "Pending Verification",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (beneficiary.status == "APPROVED") Color(0xFF10B981) else Color(0xFFF59E0B)
                    )
                }
            }
        }

        IconButton(onClick = { /* Toggle Favorite */ }) {
            Icon(
                imageVector = if (isFavorite) Icons.Default.Star else Icons.Default.StarOutline,
                contentDescription = null,
                tint = if (isFavorite) DashPrimary else Color.LightGray,
                modifier = Modifier.size(20.dp)
            )
        }
        
        IconButton(onClick = { /* More options */ }) {
            Icon(Icons.Default.MoreVert, contentDescription = null, tint = Color.LightGray, modifier = Modifier.size(20.dp))
        }
    }
}
