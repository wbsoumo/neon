package com.my.deccanfinance

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import coil.compose.AsyncImage
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import com.my.deccanfinance.ui.theme.DashSecondary
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.Locale

val CardGradient = Brush.linearGradient(listOf(DashPrimary, DashSecondary))

@Composable
fun DashboardScreen(
    apiService: ApiService, 
    dataManager: DataManager, 
    onBakingClick: () -> Unit, 
    onProfileClick: () -> Unit,
    onNotificationClick: () -> Unit,
    onTransferClick: () -> Unit,
    onReceiveClick: () -> Unit,
    onBeneficiariesClick: () -> Unit,
    onAccountDetailsClick: () -> Unit,
    onSettingsClick: () -> Unit,
    onSetMpinClick: () -> Unit,
    onPassbookClick: () -> Unit,
    onSofClick: () -> Unit,
    onFdiClick: () -> Unit,
    onFemaClick: () -> Unit,
    onAmlClick: () -> Unit,
    onLoanProductClick: () -> Unit,
    onTransactionClick: (TransferPayoutResponse) -> Unit,
    onCloseApp: () -> Unit
) {
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    var balance by remember { mutableStateOf("0.00") }
    var isBalanceVisible by remember { mutableStateOf(false) }
    var recentTransactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    val scope = rememberCoroutineScope()
    
    val userStatus = userData["status"] as? String ?: ""
    val hasMpin = userData["has_mpin"] as? Boolean ?: false
    val accountNumber = userData["account_number"] as? String ?: ""

    LaunchedEffect(Unit) {
        scope.launch {
            try {
                // Fetch user details for balance
                val userResponse = apiService.getUserDetails()
                if (userResponse.isSuccessful && userResponse.body()?.success == true) {
                    val user = userResponse.body()?.user
                    user?.let {
                        val formatter = DecimalFormat("#,##,##0.00")
                        balance = formatter.format(it.balance)
                        dataManager.saveUserData(it)
                    }
                }

                // Fetch transactions for recent list
                val txnResponse = apiService.getTransactions()
                if (txnResponse.isSuccessful && txnResponse.body()?.success == true) {
                    recentTransactions = txnResponse.body()?.transactions?.take(3) ?: emptyList()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    if (userStatus == "PENDING") {
        PendingReviewScreen(onContinue = onCloseApp)
        return@DashboardScreen
    }

    Scaffold(
        bottomBar = { ModernBottomNav(onBakingClick, onTransferClick, onPassbookClick, onSettingsClick) },
        containerColor = DashBg
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .statusBarsPadding()
                .verticalScroll(rememberScrollState())
        ) {
            HeaderSection(
                name = (userData["full_name"] as? String) ?: "User",
                onProfileClick = onProfileClick,
                onNotificationClick = onNotificationClick,
                onSettingsClick = onSettingsClick
            )

            Spacer(modifier = Modifier.height(24.dp))

            AccountCard(
                balance = balance,
                isBalanceVisible = isBalanceVisible,
                onToggleVisibility = { isBalanceVisible = !isBalanceVisible },
                accountNumber = if (accountNumber.isNotEmpty()) accountNumber else (userData["app_id"] as? String ?: "****"),
                onViewDetails = onAccountDetailsClick
            )

            if (!hasMpin) {
                Spacer(modifier = Modifier.height(16.dp))
                MpinPrompt(onSetClick = onSetMpinClick)
            }

            Spacer(modifier = Modifier.height(24.dp))
            
            MainActionsGrid(onTransferClick, onPassbookClick, onReceiveClick, onBeneficiariesClick)

            Spacer(modifier = Modifier.height(16.dp))

            ComplianceActionsGrid(onSofClick, onFdiClick, onFemaClick, onAmlClick)

            Spacer(modifier = Modifier.height(24.dp))
            
            QuickShortcutsSection(onBeneficiariesClick, onPassbookClick, onBakingClick)

            Spacer(modifier = Modifier.height(24.dp))

            LoanBannerSlider()

            Spacer(modifier = Modifier.height(32.dp))

            LoanProductsSection(onLoanProductClick)

            Spacer(modifier = Modifier.height(32.dp))

            RecentTransactionsSection(recentTransactions, onPassbookClick, onTransactionClick)
            
            Spacer(modifier = Modifier.height(20.dp))
        }
    }
}

@Composable
fun LoanBannerSlider() {
    val banners = listOf(
        "file:///android_asset/loan1.png",
        "file:///android_asset/loan2.png"
    )
    val pagerState = rememberPagerState(pageCount = { banners.size })

    // Auto-scroll logic
    LaunchedEffect(Unit) {
        while (true) {
            delay(3000) // Slide every 3 seconds
            val nextPage = (pagerState.currentPage + 1) % banners.size
            pagerState.animateScrollToPage(nextPage)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
    ) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .clip(RoundedCornerShape(20.dp))
        ) { page ->
            AsyncImage(
                model = banners[page],
                contentDescription = "Loan Banner",
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.FillBounds
            )
        }
        
        Spacer(modifier = Modifier.height(12.dp))
        
        // Pager Indicators
        Row(
            Modifier
                .height(8.dp)
                .fillMaxWidth(),
            horizontalArrangement = Arrangement.Center
        ) {
            repeat(banners.size) { iteration ->
                val color = if (pagerState.currentPage == iteration) DashPrimary else Color.LightGray
                Box(
                    modifier = Modifier
                        .padding(horizontal = 4.dp)
                        .clip(CircleShape)
                        .background(color)
                        .size(if (pagerState.currentPage == iteration) 12.dp else 8.dp, 8.dp)
                )
            }
        }
    }
}

@Composable
fun HeaderSection(name: String, onProfileClick: () -> Unit, onNotificationClick: () -> Unit, onSettingsClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Surface(
                modifier = Modifier.size(50.dp).clickable { onProfileClick() },
                shape = CircleShape,
                color = Color.White,
                shadowElevation = 2.dp
            ) {
                AsyncImage(
                    model = "file:///android_asset/icon.jpeg",
                    contentDescription = "Profile",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text("Welcome back,", fontSize = 13.sp, color = Color.Gray)
                Text(name, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            }
        }
        
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(modifier = Modifier.clickable { onNotificationClick() }) {
                Surface(
                    modifier = Modifier.size(44.dp),
                    shape = CircleShape,
                    color = Color.White,
                    shadowElevation = 2.dp
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Outlined.Notifications, contentDescription = null, tint = Color.Black)
                    }
                }
                Box(
                    modifier = Modifier
                        .size(16.dp)
                        .clip(CircleShape)
                        .background(Color.Red)
                        .align(Alignment.TopEnd)
                        .offset(x = (-2).dp, y = 2.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("3", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(modifier = Modifier.width(12.dp))
            Surface(
                modifier = Modifier.size(44.dp).clickable { onSettingsClick() },
                shape = CircleShape,
                color = Color.White,
                shadowElevation = 2.dp
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.Outlined.Settings, contentDescription = null, tint = Color.Black)
                }
            }
        }
    }
}

@Composable
fun AccountCard(
    balance: String, 
    isBalanceVisible: Boolean,
    onToggleVisibility: () -> Unit,
    accountNumber: String, 
    onViewDetails: () -> Unit
) {
    val clipboardManager = androidx.compose.ui.platform.LocalClipboardManager.current
    val scope = rememberCoroutineScope()
    val context = androidx.compose.ui.platform.LocalContext.current

    Box(modifier = Modifier.padding(horizontal = 24.dp)) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 210.dp)
                .shadow(16.dp, RoundedCornerShape(32.dp)),
            shape = RoundedCornerShape(32.dp)
        ) {
            Box(modifier = Modifier.fillMaxSize().background(CardGradient)) {
                Box(
                    modifier = Modifier
                        .size(200.dp)
                        .offset(x = 180.dp, y = (-80).dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.05f))
                )

                Column(modifier = Modifier.padding(24.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            color = Color.White.copy(alpha = 0.15f),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("\uD83C\uDDEE\uD83C\uDDF3", fontSize = 16.sp)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Indian Rupee", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                Spacer(modifier = Modifier.width(4.dp))
                                Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                            }
                        }
                        Text("NBFC", fontWeight = FontWeight.ExtraBold, fontSize = 20.sp, color = Color.White)
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.clickable { onToggleVisibility() }
                    ) {
                        Text("Total Balance", fontSize = 12.sp, color = Color.White.copy(alpha = 0.8f))
                        Spacer(modifier = Modifier.width(8.dp))
                        Icon(
                            if (isBalanceVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility, 
                            contentDescription = null, 
                            tint = Color.White.copy(alpha = 0.8f), 
                            modifier = Modifier.size(16.dp)
                        )
                    }

                    Text(
                        text = if (isBalanceVisible) "₹ $balance" else "₹ ••••••••",
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Bottom
                    ) {
                        Column {
                            Text("Account Number", fontSize = 10.sp, color = Color.White.copy(alpha = 0.7f))
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.clickable {
                                    clipboardManager.setText(AnnotatedString(accountNumber))
                                    android.widget.Toast.makeText(context, "Account Number copied", android.widget.Toast.LENGTH_SHORT).show()
                                }
                            ) {
                                Text(accountNumber, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.White)
                                Spacer(modifier = Modifier.width(8.dp))
                                Icon(Icons.Default.ContentCopy, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                            }
                        }
                        
                        Surface(
                            color = Color.White.copy(alpha = 0.2f),
                            shape = RoundedCornerShape(16.dp),
                            modifier = Modifier.clickable { onViewDetails() }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("View Account Details", color = Color.White, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MainActionsGrid(
    onTransferClick: () -> Unit,
    onPassbookClick: () -> Unit,
    onReceiveClick: () -> Unit,
    onBeneficiariesClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp),
        shape = RoundedCornerShape(28.dp),
        color = Color.White,
        shadowElevation = 1.dp
    ) {
        Row(
            modifier = Modifier.padding(vertical = 20.dp, horizontal = 4.dp), 
            horizontalArrangement = Arrangement.SpaceAround
        ) {
            MainActionItem(Icons.AutoMirrored.Filled.Send, "Send Money", "Transfer to anyone", Color(0xFFEEF2FF), Color(0xFF6366F1), Modifier.weight(1f).clickable { onTransferClick() })
            MainActionItem(Icons.Outlined.FileDownload, "Request Money", "Receive from anyone", Color(0xFFF0FDF4), Color(0xFF22C55E), Modifier.weight(1f).clickable { onReceiveClick() })
            MainActionItem(Icons.Outlined.AccountBalance, "My Recipients", "View all beneficiaries", Color(0xFFFFF7ED), Color(0xFFF59E0B), Modifier.weight(1f).clickable { onBeneficiariesClick() })
            MainActionItem(Icons.AutoMirrored.Filled.ReceiptLong, "Passbook", "View transactions", Color(0xFFF5F3FF), Color(0xFF8B5CF6), Modifier.weight(1f).clickable { onPassbookClick() })
        }
    }
}

@Composable
fun ComplianceActionsGrid(onSofClick: () -> Unit, onFdiClick: () -> Unit, onFemaClick: () -> Unit, onAmlClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp),
        shape = RoundedCornerShape(28.dp),
        color = Color.White,
        shadowElevation = 1.dp
    ) {
        Column(modifier = Modifier.padding(vertical = 20.dp, horizontal = 4.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                MainActionItem(
                    icon = Icons.Outlined.AccountBalanceWallet,
                    title = "SOF",
                    sub = "Sources of Fund",
                    bg = Color(0xFFF0FDF4),
                    tint = Color(0xFF22C55E),
                    modifier = Modifier.weight(1f).clickable { onSofClick() }
                )
                MainActionItem(
                    icon = Icons.Outlined.Public,
                    title = "FDI",
                    sub = "Foreign Direct Inv.",
                    bg = Color(0xFFEFF6FF),
                    tint = Color(0xFF3B82F6),
                    modifier = Modifier.weight(1f).clickable { onFdiClick() }
                )
                MainActionItem(
                    icon = Icons.Outlined.GppGood,
                    title = "FEMA",
                    sub = "Foreign Exch. Act",
                    bg = Color(0xFFF5F3FF),
                    tint = Color(0xFF8B5CF6),
                    modifier = Modifier.weight(1f).clickable { onFemaClick() }
                )
                MainActionItem(
                    icon = Icons.Outlined.Shield,
                    title = "AML",
                    sub = "Anti-Money Laund.",
                    bg = Color(0xFFFFF1F2),
                    tint = Color(0xFFF43F5E),
                    modifier = Modifier.weight(1f).clickable { onAmlClick() }
                )
            }
        }
    }
}

@Composable
fun MainActionItem(icon: ImageVector, title: String, sub: String, bg: Color, tint: Color, modifier: Modifier = Modifier) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        Surface(
            modifier = Modifier.size(48.dp),
            shape = RoundedCornerShape(12.dp),
            color = bg
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(24.dp))
            }
        }
        Spacer(modifier = Modifier.height(10.dp))
        Text(
            text = title, 
            fontSize = 11.sp, 
            fontWeight = FontWeight.ExtraBold, 
            color = Color.Black, 
            textAlign = TextAlign.Center,
            lineHeight = 12.sp,
            modifier = Modifier.padding(horizontal = 2.dp)
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = sub, 
            fontSize = 8.sp, 
            color = Color(0xFF6B7280), 
            textAlign = TextAlign.Center, 
            lineHeight = 10.sp,
            modifier = Modifier.padding(horizontal = 2.dp)
        )
    }
}

@Composable
fun QuickShortcutsSection(
    onBeneficiariesClick: () -> Unit,
    onPassbookClick: () -> Unit,
    onBakingClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Quick Shortcuts", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable { }) {
                Text("Edit", fontSize = 13.sp, color = DashPrimary, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.width(4.dp))
                Icon(Icons.Default.Edit, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(14.dp))
            }
        }
        Spacer(modifier = Modifier.height(24.dp))
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            ShortcutItem(Icons.Default.Group, "My Beneficiaries", modifier = Modifier.clickable { onBeneficiariesClick() })
            ShortcutItem(Icons.Default.History, "Transaction History", modifier = Modifier.clickable { onPassbookClick() })
            ShortcutItem(Icons.AutoMirrored.Filled.ReceiptLong, "Bill Payments")
            ShortcutItem(Icons.Default.QrCodeScanner, "Scan & Pay", modifier = Modifier.clickable { onBakingClick() })
        }
    }
}

@Composable
fun ShortcutItem(icon: ImageVector, label: String, modifier: Modifier = Modifier) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = modifier) {
        Surface(
            modifier = Modifier.size(52.dp),
            shape = CircleShape,
            color = Color.White,
            shadowElevation = 2.dp
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(22.dp))
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = label, 
            fontSize = 9.sp, 
            fontWeight = FontWeight.Bold, 
            color = Color(0xFF374151),
            textAlign = TextAlign.Center, 
            lineHeight = 11.sp,
            modifier = Modifier.padding(horizontal = 2.dp)
        )
    }
}

@Composable
fun RecentTransactionsSection(
    transactions: List<Transaction>, 
    onPassbookClick: () -> Unit,
    onTransactionClick: (TransferPayoutResponse) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .clip(RoundedCornerShape(24.dp))
            .background(Color.White)
            .padding(20.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Recent Transactions", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable { onPassbookClick() }) {
                Text("View all", fontSize = 12.sp, color = DashPrimary, fontWeight = FontWeight.Bold)
                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(16.dp))
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        Text("TODAY", fontSize = 10.sp, color = Color.Gray, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(12.dp))
        
        if (transactions.isEmpty()) {
            Box(modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp), contentAlignment = Alignment.Center) {
                Text("No recent transactions", fontSize = 13.sp, color = Color.Gray)
            }
        } else {
            transactions.forEach { txn ->
                val isNegative = txn.flowType == "DEBIT"
                val amountText = "${if (isNegative) "-" else "+"} ₹ ${DecimalFormat("#,##,##0.00").format(txn.amount)}"
                
                val timeText = try {
                    val inputFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                    val outputFormat = SimpleDateFormat("hh:mm a", Locale.getDefault())
                    val date = inputFormat.parse(txn.createdAt)
                    outputFormat.format(date!!)
                } catch (e: Exception) {
                    "00:00 AM"
                }

                TransactionItem(
                    icon = if (isNegative) Icons.AutoMirrored.Filled.Send else Icons.Default.FileDownload,
                    title = if (isNegative) "Transfer to ${txn.recipientName ?: txn.recipientAccount}" else "Money Received from ${txn.senderName}",
                    time = timeText,
                    status = txn.status ?: "PENDING",
                    amount = amountText,
                    isNegative = isNegative,
                    modifier = Modifier.clickable { 
                        onTransactionClick(txn.toTransferPayoutResponse())
                    }
                )
            }
        }
    }
}

@Composable
fun TransactionItem(
    icon: ImageVector, 
    title: String, 
    time: String, 
    status: String, 
    amount: String, 
    isNegative: Boolean,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(44.dp),
            shape = RoundedCornerShape(12.dp),
            color = if (isNegative) Color(0xFFFFEBEE) else Color(0xFFE8F5E9)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = if (isNegative) Color.Red else Color(0xFF2E7D32), modifier = Modifier.size(20.dp))
            }
        }
        Spacer(modifier = Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title, 
                fontSize = 13.sp, 
                fontWeight = FontWeight.Bold, 
                color = Color.Black,
                lineHeight = 16.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(time, fontSize = 11.sp, color = Color.Gray)
                Spacer(modifier = Modifier.width(6.dp))
                Box(
                    modifier = Modifier
                        .size(4.dp)
                        .clip(CircleShape)
                        .background(
                            when(status.uppercase()) {
                                "SUCCESS", "SUCCESSFUL" -> Color(0xFF22C55E)
                                "PENDING" -> Color(0xFFF59E0B)
                                "FAILED", "FAILURE" -> Color.Red
                                else -> Color(0xFF22C55E)
                            }
                        )
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = status.lowercase().replaceFirstChar { it.uppercase() }, 
                    fontSize = 11.sp, 
                    color = when(status.uppercase()) {
                        "SUCCESS", "SUCCESSFUL" -> Color(0xFF22C55E)
                        "PENDING" -> Color(0xFFF59E0B)
                        "FAILED", "FAILURE" -> Color.Red
                        else -> Color(0xFF22C55E)
                    },
                    fontWeight = FontWeight.Bold
                )
            }
        }
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = amount, 
            fontSize = 14.sp, 
            fontWeight = FontWeight.ExtraBold, 
            color = if (isNegative) Color.Red else Color(0xFF2E7D32),
            textAlign = TextAlign.End
        )
        Spacer(modifier = Modifier.width(4.dp))
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.LightGray, modifier = Modifier.size(18.dp))
    }
}

@Composable
fun ModernBottomNav(onBakingClick: () -> Unit, onTransferClick: () -> Unit, onPassbookClick: () -> Unit, onSettingsClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(90.dp),
        color = Color.White,
        shadowElevation = 16.dp
    ) {
        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            NavItem(Icons.Default.Home, "Home", isSelected = true)
            NavItem(Icons.AutoMirrored.Filled.Send, "Transfer", isSelected = false, onClick = onTransferClick)
            
            Box(contentAlignment = Alignment.Center, modifier = Modifier.offset(y = (-15).dp)) {
                Surface(
                    onClick = onBakingClick,
                    modifier = Modifier.size(60.dp),
                    shape = CircleShape,
                    color = DashPrimary,
                    shadowElevation = 8.dp
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.QrCodeScanner, contentDescription = null, tint = Color.White, modifier = Modifier.size(28.dp))
                    }
                }
            }
            
            NavItem(Icons.AutoMirrored.Filled.ReceiptLong, "Passbook", isSelected = false, onClick = onPassbookClick)
            NavItem(Icons.Default.GridView, "More", isSelected = false, onClick = onSettingsClick)
        }
    }
}

@Composable
fun NavItem(icon: ImageVector, label: String, isSelected: Boolean, onClick: () -> Unit = {}) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.clickable { onClick() }) {
        Icon(
            icon,
            contentDescription = label,
            tint = if (isSelected) DashPrimary else Color.LightGray,
            modifier = Modifier.size(24.dp)
        )
        Text(label, fontSize = 10.sp, color = if (isSelected) DashPrimary else Color.LightGray, fontWeight = FontWeight.Bold)
    }
}

@Composable
fun MpinPrompt(onSetClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .clickable { onSetClick() },
        shape = RoundedCornerShape(16.dp),
        color = Color(0xFFFEF3C7)
    ) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Security, contentDescription = null, tint = Color(0xFFD97706))
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text("Secure Your Account", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color(0xFF92400E))
                Text("Set up your 6-digit MPIN now.", fontSize = 11.sp, color = Color(0xFFB45309))
            }
        }
    }
}

@Composable
fun LoanProductsSection(onItemClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
    ) {
        Text(
            text = "Loan Products",
            fontSize = 28.sp,
            fontWeight = FontWeight.ExtraBold,
            color = Color.Black,
            modifier = Modifier.padding(bottom = 24.dp)
        )

        val items = listOf(
            Triple(Icons.Outlined.VolunteerActivism, "Offer for Existing", "Customers"),
            Triple(Icons.Outlined.HomeWork, "Buy New", "Home"),
            Triple(Icons.Outlined.Construction, "Home", "Construction"),
            Triple(Icons.Outlined.EnergySavingsLeaf, "Business", "Loan"),
            Triple(Icons.Outlined.Savings, "Personal", "Loan"),
            Triple(Icons.Outlined.Domain, "Loan Against", "Property"),
            Triple(Icons.Outlined.Shield, "Secured Business", "Loan"),
            Triple(Icons.Outlined.DirectionsCar, "Used Car", "Loan"),
            Triple(Icons.Default.ShowChart, "Loan Against", "Securities"),
            Triple(Icons.Outlined.SettingsSuggest, "Insurance", "Services")
        )

        items.chunked(3).forEach { rowItems ->
            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                rowItems.forEach { (icon, line1, line2) ->
                    LoanProductItem(icon, line1, line2, modifier = Modifier.weight(1f).clickable { onItemClick() })
                }
                if (rowItems.size < 3) {
                    repeat(3 - rowItems.size) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

@Composable
fun LoanProductItem(icon: ImageVector, line1: String, line2: String, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier.aspectRatio(0.9f),
        shape = RoundedCornerShape(24.dp),
        color = Color.White,
        shadowElevation = 4.dp
    ) {
        Column(
            modifier = Modifier.padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(42.dp)
                    .background(Color(0xFFFFEEE8), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = Color(0xFFF05A28),
                    modifier = Modifier.size(20.dp)
                )
            }
            Spacer(modifier = Modifier.height(10.dp))
            Text(
                text = line1,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = Color.Black,
                textAlign = TextAlign.Center,
                lineHeight = 13.sp
            )
            Text(
                text = line2,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = Color.Black,
                textAlign = TextAlign.Center,
                lineHeight = 13.sp
            )
        }
    }
}

@Composable
fun LoanServiceUnavailableScreen(onBack: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .statusBarsPadding(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Surface(
                modifier = Modifier.size(120.dp),
                shape = CircleShape,
                color = Color(0xFFFFF3F1)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.Default.Info,
                        contentDescription = null,
                        tint = Color(0xFFF05A28),
                        modifier = Modifier.size(64.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            Text(
                "Service Unavailable",
                fontSize = 24.sp,
                fontWeight = FontWeight.ExtraBold,
                color = Color.Black,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                "Loan services are not available right now for you. Please contact your nearest branch or contact your account POC for further assistance.",
                fontSize = 16.sp,
                color = Color.Gray,
                textAlign = TextAlign.Center,
                lineHeight = 24.sp
            )
            
            Spacer(modifier = Modifier.height(48.dp))
            
            Button(
                onClick = onBack,
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = DashPrimary)
            ) {
                Text("Go Back", fontSize = 16.sp, fontWeight = FontWeight.Bold)
            }
        }
        
        IconButton(
            onClick = onBack,
            modifier = Modifier.align(Alignment.TopStart).padding(16.dp)
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.Black)
        }
    }
}
