package com.my.deccanfinance

import android.app.DatePickerDialog
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PassbookScreen(
    apiService: ApiService,
    onBack: () -> Unit,
    onAccountDetailsClick: () -> Unit,
    onTransactionClick: (TransferPayoutResponse) -> Unit
) {
    var allTransactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var balance by remember { mutableStateOf(0.0) }
    var accountNumber by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()
    
    // Filter states
    var searchQuery by remember { mutableStateOf("") }
    var filterType by remember { mutableStateOf("All") } // All, DEBIT, CREDIT
    var startDate by remember { mutableStateOf<Long?>(null) }
    var endDate by remember { mutableStateOf<Long?>(null) }
    var visibleLimit by remember { mutableIntStateOf(10) }

    val formatter = DecimalFormat("#,##,##0.00")
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        scope.launch {
            try {
                // Fetch User Details for Balance and Account Number
                val userResponse = apiService.getUserDetails()
                if (userResponse.isSuccessful && userResponse.body()?.success == true) {
                    val user = userResponse.body()?.user
                    balance = user?.balance ?: 0.0
                    accountNumber = user?.accountNumber ?: user?.appId ?: ""
                }

                // Fetch Transactions
                val response = apiService.getTransactions()
                if (response.isSuccessful && response.body()?.success == true) {
                    allTransactions = response.body()?.transactions ?: emptyList()
                }
            } catch (e: Exception) {
                android.util.Log.e("Passbook", "Error fetching data", e)
            } finally {
                isLoading = false
            }
        }
    }

    val filteredTransactions = remember(allTransactions, searchQuery, filterType, startDate, endDate) {
        allTransactions.filter { tx ->
            val matchesSearch = if (searchQuery.isEmpty()) true else {
                tx.recipientName?.contains(searchQuery, ignoreCase = true) == true ||
                tx.senderName.contains(searchQuery, ignoreCase = true) ||
                tx.transactionId.contains(searchQuery, ignoreCase = true) ||
                tx.recipientAccount.contains(searchQuery)
            }
            
            val matchesType = if (filterType == "All") true else tx.flowType == filterType
            
            val txDate = try {
                SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).parse(tx.createdAt)?.time ?: 0L
            } catch (e: Exception) { 0L }
            
            val matchesStartDate = if (startDate == null) true else txDate >= startDate!!
            val matchesEndDate = if (endDate == null) true else txDate <= (endDate!! + 86400000L) // Include the full end day

            matchesSearch && matchesType && matchesStartDate && matchesEndDate
        }
    }

    val pagedTransactions = filteredTransactions.take(visibleLimit)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text("Passbook", fontWeight = FontWeight.ExtraBold, fontSize = 20.sp, color = Color.Black) 
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.Black)
                    }
                },
                actions = {
                    IconButton(onClick = { /* Export */ }) {
                        Icon(Icons.Outlined.FileDownload, contentDescription = "Export", tint = DashPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        },
        containerColor = Color.White
    ) { padding ->
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DashPrimary)
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .padding(padding)
                    .fillMaxSize()
            ) {
                item {
                    PassbookHeaderCard(
                        accountNumber = accountNumber,
                        balance = formatter.format(balance),
                        onClick = onAccountDetailsClick
                    )
                }

                item {
                    PassbookSearchSection(
                        searchQuery = searchQuery,
                        onSearchChange = { searchQuery = it },
                        filterType = filterType,
                        onFilterChange = { filterType = it },
                        onDateRangeClick = {
                            val calendar = Calendar.getInstance()
                            DatePickerDialog(context, { _, year, month, day ->
                                val start = Calendar.getInstance()
                                start.set(year, month, day, 0, 0, 0)
                                startDate = start.timeInMillis
                                
                                DatePickerDialog(context, { _, y2, m2, d2 ->
                                    val end = Calendar.getInstance()
                                    end.set(y2, m2, d2, 23, 59, 59)
                                    endDate = end.timeInMillis
                                }, year, month, day).show()
                            }, calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH), calendar.get(Calendar.DAY_OF_MONTH)).show()
                        }
                    )
                }

                item {
                    TransactionPeriodBanner(
                        startDate = startDate,
                        endDate = endDate,
                        onClear = {
                            startDate = null
                            endDate = null
                        }
                    )
                }

                // Group transactions by date
                val grouped = pagedTransactions.groupBy { 
                    try {
                        val date = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).parse(it.createdAt)
                        SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(date!!)
                    } catch (e: Exception) {
                        it.createdAt.split(" ")[0]
                    }
                }

                if (pagedTransactions.isEmpty()) {
                    item {
                        Box(modifier = Modifier.fillMaxWidth().padding(top = 100.dp), contentAlignment = Alignment.Center) {
                            Text("No transactions found", color = Color.Gray, fontSize = 16.sp)
                        }
                    }
                } else {
                    grouped.forEach { (date, txs) ->
                        item {
                            Text(
                                text = date,
                                modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp),
                                fontSize = 13.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = Color.Black.copy(alpha = 0.7f)
                            )
                        }
                        items(txs) { tx ->
                            TransactionRow(tx, onClick = {
                                onTransactionClick(tx.toTransferPayoutResponse())
                            })
                        }
                    }
                }

                if (visibleLimit < filteredTransactions.size) {
                    item {
                        Spacer(modifier = Modifier.height(24.dp))
                        Box(modifier = Modifier.fillMaxWidth().padding(bottom = 32.dp), contentAlignment = Alignment.Center) {
                            Surface(
                                shape = RoundedCornerShape(14.dp),
                                border = ButtonDefaults.outlinedButtonBorder,
                                color = Color.White,
                                modifier = Modifier.clickable { 
                                    visibleLimit += 10
                                }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("View Older Transactions", color = DashPrimary, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                                }
                            }
                        }
                    }
                } else {
                    item { Spacer(modifier = Modifier.height(32.dp)) }
                }
            }
        }
    }
}

@Composable
fun PassbookHeaderCard(accountNumber: String, balance: String, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFF3F5FF)), // Slightly darker background for better visibility
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .padding(24.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(56.dp),
                shape = CircleShape,
                color = DashPrimary
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.Default.AccountBalance, contentDescription = null, tint = Color.White, modifier = Modifier.size(28.dp))
                }
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text("Savings Account", fontWeight = FontWeight.ExtraBold, fontSize = 16.sp, color = Color.Black)
                Text(accountNumber, fontSize = 14.sp, color = Color.DarkGray, fontWeight = FontWeight.Medium)
                Text("Deccan Finance", fontSize = 13.sp, color = Color.Gray)
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(1.2f)) {
                Text("Available Balance", fontSize = 11.sp, color = Color.DarkGray, fontWeight = FontWeight.Bold)
                Text(
                    text = "₹ $balance", 
                    fontWeight = FontWeight.Black, 
                    fontSize = 18.sp, 
                    color = Color.Black,
                    textAlign = TextAlign.End,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    lineHeight = 22.sp
                )
            }
            
            Spacer(modifier = Modifier.width(8.dp))
            Icon(Icons.Default.ChevronRight, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(22.dp))
        }
    }
}

@Composable
fun PassbookSearchSection(
    searchQuery: String,
    onSearchChange: (String) -> Unit,
    filterType: String,
    onFilterChange: (String) -> Unit,
    onDateRangeClick: () -> Unit
) {
    var showFilterMenu by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box {
            Surface(
                shape = RoundedCornerShape(12.dp),
                border = ButtonDefaults.outlinedButtonBorder,
                color = Color.White,
                modifier = Modifier.clickable { showFilterMenu = true }
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.FilterList, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(if (filterType == "All") "Filter" else filterType, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                    Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = Color.Black, modifier = Modifier.size(18.dp))
                }
            }
            DropdownMenu(expanded = showFilterMenu, onDismissRequest = { showFilterMenu = false }) {
                DropdownMenuItem(text = { Text("All") }, onClick = { onFilterChange("All"); showFilterMenu = false })
                DropdownMenuItem(text = { Text("Debits") }, onClick = { onFilterChange("DEBIT"); showFilterMenu = false })
                DropdownMenuItem(text = { Text("Credits") }, onClick = { onFilterChange("CREDIT"); showFilterMenu = false })
            }
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Surface(
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(12.dp),
            color = Color(0xFFF1F5F9), // Better background contrast
            border = BorderStroke(1.dp, Color.LightGray.copy(alpha = 0.5f))
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.Search, contentDescription = null, tint = Color.DarkGray, modifier = Modifier.size(20.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Box(modifier = Modifier.weight(1f)) {
                    if (searchQuery.isEmpty()) {
                        Text("Search transactions", color = Color.Gray, fontSize = 14.sp)
                    }
                    BasicTextField(
                        value = searchQuery,
                        onValueChange = onSearchChange,
                        textStyle = TextStyle(fontSize = 14.sp, color = Color.Black),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Surface(
            modifier = Modifier.size(44.dp).clickable { onDateRangeClick() },
            shape = RoundedCornerShape(12.dp),
            border = ButtonDefaults.outlinedButtonBorder,
            color = Color.White
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(Icons.Outlined.CalendarMonth, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(22.dp))
            }
        }
    }
}

@Composable
fun TransactionPeriodBanner(
    startDate: Long?,
    endDate: Long?,
    onClear: () -> Unit
) {
    val dateText = if (startDate != null && endDate != null) {
        val sdf = SimpleDateFormat("dd MMM", Locale.getDefault())
        "Showing transactions from ${sdf.format(Date(startDate))} to ${sdf.format(Date(endDate))}"
    } else {
        "Showing transactions for last 30 days"
    }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp),
        shape = RoundedCornerShape(14.dp),
        color = Color(0xFFEEF2FF) // Slightly more saturated for visibility
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Outlined.Info, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                dateText, 
                fontSize = 13.sp, 
                color = Color.Black.copy(alpha = 0.7f),
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f)
            )
            Text(
                if (startDate != null) "Clear" else "Change", 
                fontSize = 13.sp, 
                fontWeight = FontWeight.ExtraBold, 
                color = DashPrimary,
                modifier = Modifier.clickable { onClear() }
            )
        }
    }
}

@Composable
fun TransactionRow(tx: Transaction, onClick: () -> Unit) {
    val isDebit = tx.flowType == "DEBIT"
    val formatter = DecimalFormat("#,##,##0.00")
    
    val time = try {
        val date = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).parse(tx.createdAt)
        SimpleDateFormat("hh:mm a", Locale.getDefault()).format(date!!)
    } catch (e: Exception) {
        tx.createdAt.split(" ").getOrNull(1) ?: ""
    }

    val title = when(tx.type) {
        "P2P" -> if (isDebit) "Money Sent" else "Money Received"
        "BANK_TRANSFER" -> "Bank Transfer"
        "BILL_PAYMENT" -> "Bill Payment"
        else -> tx.type.replace("_", " ").lowercase().replaceFirstChar { it.uppercase() }
    }

    val description = if (isDebit) {
        "To ${tx.recipientName ?: tx.recipientAccount}"
    } else {
        "From ${tx.senderName}"
    }

    val icon = when {
        tx.type == "BILL_PAYMENT" -> Icons.AutoMirrored.Filled.ReceiptLong
        tx.type == "INTEREST" -> Icons.Default.AccountBalance
        isDebit -> Icons.Default.ArrowOutward
        else -> Icons.Default.ArrowDownward
    }

    val iconBg = when {
        tx.type == "BILL_PAYMENT" -> Color(0xFFFFF7ED)
        tx.type == "INTEREST" -> Color(0xFFEEF2FF)
        isDebit -> Color(0xFFFFEBEE)
        else -> Color(0xFFE8F5E9)
    }

    val iconTint = when {
        tx.type == "BILL_PAYMENT" -> Color(0xFFF59E0B)
        tx.type == "INTEREST" -> DashPrimary
        isDebit -> Color.Red
        else -> Color(0xFF22C55E)
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(horizontal = 24.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(48.dp),
            shape = CircleShape,
            color = iconBg
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(22.dp))
            }
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.ExtraBold, fontSize = 15.sp, color = Color.Black)
            Text(description, fontSize = 12.sp, color = Color.Black.copy(alpha = 0.6f), maxLines = 1, overflow = TextOverflow.Ellipsis, fontWeight = FontWeight.Medium)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(time, fontSize = 12.sp, color = Color.Gray)
                val status = tx.status ?: "PENDING"
                Spacer(modifier = Modifier.width(8.dp))
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
        
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = "${if (isDebit) "-" else "+"} ₹${formatter.format(tx.amount)}",
                fontWeight = FontWeight.Black,
                fontSize = 15.sp,
                color = if (isDebit) Color.Black else Color(0xFF16A34A) // Darker green for visibility
            )
        }
    }
    
    HorizontalDivider(
        modifier = Modifier.padding(horizontal = 24.dp),
        thickness = 1.dp,
        color = Color.LightGray.copy(alpha = 0.2f)
    )
}
