package com.my.deccanfinance

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RequestStatementScreen(
    apiService: ApiService,
    onBack: () -> Unit
) {
    var statements by remember { mutableStateOf<List<StatementItem>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var isGenerating by remember { mutableStateOf(false) }
    
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }

    var fromDate by remember { mutableStateOf(Calendar.getInstance().apply { add(Calendar.MONTH, -1) }.time) }
    var toDate by remember { mutableStateOf(Calendar.getInstance().time) }
    
    var showFromDatePicker by remember { mutableStateOf(false) }
    var showToDatePicker by remember { mutableStateOf(false) }

    val dateFormatter = remember { SimpleDateFormat("dd MMM yyyy", Locale.getDefault()) }
    val apiDateFormatter = remember { SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()) }

    fun fetchStatements() {
        isLoading = true
        scope.launch {
            try {
                val response = apiService.getStatements()
                if (response.isSuccessful) {
                    val body = response.body()
                    if (body?.success == true) {
                        val serverStatements = body.statements ?: emptyList()
                        // Merge with existing local statements to prevent newly generated ones from disappearing
                        val currentUrls = serverStatements.map { it.downloadUrl }.toSet()
                        val localOnly = statements.filter { it.downloadUrl !in currentUrls && it.size == "Just now" }
                        statements = (localOnly + serverStatements).sortedByDescending { it.filename }
                    }
                }
            } catch (e: Exception) {
                snackbarHostState.showSnackbar("Failed to load statements")
            } finally {
                isLoading = false
            }
        }
    }

    fun generateStatement() {
        if (isGenerating) return
        isGenerating = true
        scope.launch {
            try {
                val response = apiService.getStatement(
                    fromDate = apiDateFormatter.format(fromDate),
                    toDate = apiDateFormatter.format(toDate)
                )
                val body = response.body()
                if (response.isSuccessful && body?.success == true) {
                    snackbarHostState.showSnackbar("Statement generated successfully")
                    
                    // Manually add the newly generated statement to the UI immediately
                    body.downloadUrl?.let { url ->
                        val newItem = StatementItem(
                            filename = body.filename ?: "Statement_${System.currentTimeMillis() / 1000}.pdf",
                            dateRange = "${dateFormatter.format(fromDate)} - ${dateFormatter.format(toDate)}",
                            size = "Just now",
                            downloadUrl = url
                        )
                        // Prepend to current list
                        if (statements.none { it.downloadUrl == url }) {
                            statements = listOf(newItem) + statements
                        }
                    }
                    
                    kotlinx.coroutines.delay(2000)
                    fetchStatements()
                } else {
                    snackbarHostState.showSnackbar(body?.message ?: "Failed to generate statement")
                }
            } catch (e: Exception) {
                snackbarHostState.showSnackbar("Error generating statement")
            } finally {
                isGenerating = false
            }
        }
    }

    LaunchedEffect(Unit) {
        fetchStatements()
    }

    if (showFromDatePicker) {
        val datePickerState = rememberDatePickerState(initialSelectedDateMillis = fromDate.time)
        DatePickerDialog(
            onDismissRequest = { showFromDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let {
                        fromDate = Date(it)
                    }
                    showFromDatePicker = false
                }) { Text("OK") }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }

    if (showToDatePicker) {
        val datePickerState = rememberDatePickerState(initialSelectedDateMillis = toDate.time)
        DatePickerDialog(
            onDismissRequest = { showToDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let {
                        toDate = Date(it)
                    }
                    showToDatePicker = false
                }) { Text("OK") }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text("Request Statement", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1A1C1E))
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = DashPrimary)
                    }
                },
                actions = {
                    IconButton(onClick = { fetchStatements() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh", tint = DashPrimary)
                    }
                    Row(
                        modifier = Modifier.padding(end = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Outlined.VerifiedUser, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(16.dp))
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
        ) {
            Text(
                "Get your account statement for any selected period",
                fontSize = 13.sp,
                color = Color(0xFF424242),
                modifier = Modifier.align(Alignment.CenterHorizontally).padding(bottom = 16.dp)
            )

            // Select Period Card
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp),
                shape = RoundedCornerShape(16.dp),
                color = Color.White,
                shadowElevation = 2.dp
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("Select Statement Period", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color(0xFF1A1C1E))
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        DateInputField("From Date", dateFormatter.format(fromDate)) { showFromDatePicker = true }
                        Icon(Icons.Default.ArrowForward, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                        DateInputField("To Date", dateFormatter.format(toDate)) { showToDatePicker = true }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Surface(
                        color = Color(0xFFF8F9FF),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.Info, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("You can request statements for a maximum of 12 months.", fontSize = 11.sp, color = Color(0xFF666666))
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    Button(
                        onClick = { generateStatement() },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = DashPrimary),
                        enabled = !isGenerating
                    ) {
                        if (isGenerating) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                        } else {
                            Icon(Icons.Default.Description, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Generate Statement")
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Column(modifier = Modifier.padding(horizontal = 20.dp)) {
                Text("Your Statements", fontWeight = FontWeight.Bold, fontSize = 16.sp, color = Color(0xFF1A1C1E))
                Text("View and download your generated statements", fontSize = 12.sp, color = Color(0xFF666666))
            }

            Spacer(modifier = Modifier.height(12.dp))

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = DashPrimary)
                }
            } else if (statements.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Description,
                            contentDescription = null,
                            tint = Color.LightGray.copy(alpha = 0.5f),
                            modifier = Modifier.size(64.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "No statements available",
                            color = Color.Gray,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .padding(horizontal = 20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    contentPadding = PaddingValues(bottom = 20.dp)
                ) {
                    items(statements) { item ->
                        StatementListItem(item) {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(item.downloadUrl))
                            context.startActivity(intent)
                        }
                    }
                }
            }
            
            // Footer
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                color = Color(0xFFF8F9FF),
                shape = RoundedCornerShape(16.dp)
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Placeholder for the shield icon with lock in the image
                    Surface(
                        modifier = Modifier.size(40.dp),
                        color = Color.White,
                        shape = RoundedCornerShape(8.dp),
                        shadowElevation = 1.dp
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Default.Lock, contentDescription = null, tint = DashPrimary)
                        }
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Your Data is Safe", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Color(0xFF1A1C1E))
                        Text("All statements are password protected and are for your personal use only.", fontSize = 11.sp, color = Color(0xFF666666))
                    }
                    Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.Gray)
                }
            }
        }
    }
}

@Composable
fun DateInputField(label: String, value: String, onClick: () -> Unit) {
    Column {
        Text(label, fontSize = 11.sp, color = Color(0xFF666666), modifier = Modifier.padding(start = 4.dp))
        Spacer(modifier = Modifier.height(4.dp))
        Surface(
            onClick = onClick,
            modifier = Modifier.width(140.dp),
            shape = RoundedCornerShape(8.dp),
            border = BorderStroke(1.dp, Color(0xFFE0E0E0)),
            color = Color.White
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 10.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.CalendarToday, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text(value, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color(0xFF1A1C1E))
            }
        }
    }
}

@Composable
fun StatementListItem(item: StatementItem, onDownload: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onDownload() },
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, Color(0xFFF0F0F0)),
        shadowElevation = 1.dp
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(44.dp),
                shape = RoundedCornerShape(10.dp),
                color = Color(0xFFF5F6FF)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.Default.PictureAsPdf, 
                        contentDescription = null, 
                        tint = DashPrimary, 
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    item.filename, 
                    fontSize = 14.sp, 
                    fontWeight = FontWeight.Bold, 
                    maxLines = 1, 
                    color = Color(0xFF1A1C1E)
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(item.dateRange ?: "Period not specified", fontSize = 11.sp, color = Color(0xFF666666))
                    if (item.size != null) {
                        Text(" • ", fontSize = 11.sp, color = Color.LightGray)
                        Text(item.size, fontSize = 11.sp, color = if (item.size == "Just now") DashPrimary else Color(0xFF666666))
                    }
                }
            }
            Surface(
                modifier = Modifier.size(32.dp),
                shape = RoundedCornerShape(8.dp),
                color = DashPrimary.copy(alpha = 0.1f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.Default.FileDownload, 
                        contentDescription = "Download", 
                        tint = DashPrimary, 
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}
