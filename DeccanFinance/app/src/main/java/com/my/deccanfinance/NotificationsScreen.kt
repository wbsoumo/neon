package com.my.deccanfinance

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
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
fun NotificationsScreen(
    apiService: ApiService,
    onBack: () -> Unit
) {
    var notifications by remember { mutableStateOf<List<Notification>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var selectedFilter by remember { mutableStateOf("All") }
    val scope = rememberCoroutineScope()

    val filters = listOf("All", "Transactions", "Offers", "Updates", "Security")

    LaunchedEffect(Unit) {
        scope.launch {
            try {
                val response = apiService.getNotifications()
                if (response.isSuccessful && response.body()?.success == true) {
                    notifications = response.body()?.notifications ?: emptyList()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isLoading = false
            }
        }
    }

    val filteredNotifications = if (selectedFilter == "All") {
        notifications
    } else {
        notifications.filter { it.category.equals(selectedFilter, ignoreCase = true) }
    }

    val groupedNotifications = groupNotificationsByDate(filteredNotifications)

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text("Notifications", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1A1C1E))
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = DashPrimary)
                    }
                },
                actions = {
                    IconButton(onClick = { /* Handle settings */ }) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings", tint = DashPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DashBg)
            )
        },
        containerColor = DashBg
    ) { padding ->
        Column(modifier = Modifier.padding(padding).fillMaxSize()) {
            // Filters
            LazyRow(
                modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(filters) { filter ->
                    FilterChip(
                        label = filter,
                        isSelected = selectedFilter == filter,
                        onClick = { selectedFilter = filter }
                    )
                }
            }

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = DashPrimary)
                }
            } else if (filteredNotifications.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Outlined.NotificationsActive,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = Color.LightGray.copy(alpha = 0.5f)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text("No notifications found", color = Color.Gray, fontSize = 14.sp)
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 20.dp)
                ) {
                    groupedNotifications.forEach { (dateHeader, items) ->
                        item {
                            Text(
                                text = dateHeader,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.Gray,
                                modifier = Modifier.padding(start = 20.dp, top = 16.dp, bottom = 12.dp)
                            )
                        }
                        items(items) { notification ->
                            NotificationListItem(notification)
                        }
                    }

                    item {
                        Spacer(modifier = Modifier.height(24.dp))
                        Surface(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 20.dp)
                                .clickable { /* Handle archived */ },
                            shape = RoundedCornerShape(12.dp),
                            color = Color.White,
                            border = BorderStroke(1.dp, Color(0xFFF0F0F0))
                        ) {
                            Row(
                                modifier = Modifier.padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Surface(
                                    modifier = Modifier.size(36.dp),
                                    shape = RoundedCornerShape(8.dp),
                                    color = Color(0xFFF5F6FF)
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Icon(Icons.Default.Archive, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                                    }
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Text("Archived Notifications", fontSize = 13.sp, color = DashPrimary, fontWeight = FontWeight.Medium)
                                Spacer(modifier = Modifier.weight(1f))
                                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun FilterChip(label: String, isSelected: Boolean, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(20.dp),
        color = if (isSelected) DashPrimary else Color.White,
        border = if (isSelected) null else BorderStroke(1.dp, Color(0xFFE0E0E0)),
        modifier = Modifier.height(36.dp)
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.padding(horizontal = 20.dp)) {
            Text(
                label,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                color = if (isSelected) Color.White else Color.Gray
            )
        }
    }
}

@Composable
fun NotificationListItem(notification: Notification) {
    val (icon, tint, bgColor) = when {
        notification.title.contains("Received", ignoreCase = true) -> Triple(Icons.Default.ArrowDownward, Color(0xFF4CAF50), Color(0xFFE8F5E9))
        notification.title.contains("Sent", ignoreCase = true) || notification.title.contains("Transfer", ignoreCase = true) -> Triple(Icons.AutoMirrored.Filled.Send, Color(0xFFF44336), Color(0xFFFFEBEE))
        notification.title.contains("Login", ignoreCase = true) || notification.category.equals("Security", ignoreCase = true) -> Triple(Icons.Default.Security, Color(0xFF5E5CE6), Color(0xFFF0F0FF))
        notification.title.contains("Bill", ignoreCase = true) -> Triple(Icons.AutoMirrored.Filled.ReceiptLong, Color(0xFF8B5CF6), Color(0xFFF5F3FF))
        notification.title.contains("Offer", ignoreCase = true) || notification.category.equals("Offers", ignoreCase = true) -> Triple(Icons.Default.LocalOffer, Color(0xFFFFA000), Color(0xFFFFF8E1))
        notification.title.contains("Beneficiary", ignoreCase = true) -> Triple(Icons.Default.PersonAdd, Color(0xFF2196F3), Color(0xFFE3F2FD))
        else -> Triple(Icons.Default.Notifications, Color(0xFF9E9E9E), Color(0xFFF5F5F5))
    }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 6.dp),
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 0.5.dp
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            Surface(
                modifier = Modifier.size(44.dp),
                shape = RoundedCornerShape(12.dp),
                color = bgColor
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(22.dp))
                }
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        notification.title,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                        color = Color(0xFF1A1C1E)
                    )
                    Text(
                        formatNotificationTime(notification.createdAt),
                        fontSize = 10.sp,
                        color = Color.Gray
                    )
                }
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    notification.body,
                    fontSize = 12.sp,
                    color = Color(0xFF666666),
                    lineHeight = 18.sp
                )
            }
            // Status dot
            Box(
                modifier = Modifier
                    .padding(start = 8.dp, top = 4.dp)
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(if (notification.sentStatus == "SUCCESS") tint else Color.Transparent)
            )
        }
    }
}

private fun groupNotificationsByDate(notifications: List<Notification>): Map<String, List<Notification>> {
    val grouped = mutableMapOf<String, MutableList<Notification>>()
    val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    val today = sdf.format(Date())
    val calendar = Calendar.getInstance()
    calendar.add(Calendar.DATE, -1)
    val yesterday = sdf.format(calendar.time)

    notifications.forEach { notification ->
        val datePart = try {
            val date = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).parse(notification.createdAt)
            sdf.format(date!!)
        } catch (e: Exception) {
            notification.createdAt.take(10)
        }

        val header = when (datePart) {
            today -> "Today"
            yesterday -> "Yesterday"
            else -> "Earlier"
        }

        grouped.getOrPut(header) { mutableListOf() }.add(notification)
    }

    // Sort the map keys so Today is first, then Yesterday, then Earlier
    val sortedGrouped = mutableMapOf<String, List<Notification>>()
    if (grouped.containsKey("Today")) sortedGrouped["Today"] = grouped["Today"]!!
    if (grouped.containsKey("Yesterday")) sortedGrouped["Yesterday"] = grouped["Yesterday"]!!
    if (grouped.containsKey("Earlier")) sortedGrouped["Earlier"] = grouped["Earlier"]!!
    
    return sortedGrouped
}

private fun formatNotificationTime(createdAt: String): String {
    return try {
        val date = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).parse(createdAt)
        SimpleDateFormat("hh:mm a", Locale.getDefault()).format(date!!)
    } catch (e: Exception) {
        createdAt.split(" ").getOrNull(1)?.take(5) ?: ""
    }
}
