package com.my.deccanfinance

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.view.View
import android.widget.Toast
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PayoutTransactionDetailsScreen(
    response: TransferPayoutResponse,
    dataManager: DataManager,
    onBack: () -> Unit
) {
    var isExpanded by remember { mutableStateOf(false) }
    val userData by dataManager.userData.collectAsState(initial = emptyMap())
    val senderName = userData["full_name"] as? String ?: "User"
    val senderAccount = userData["account_number"] as? String ?: "****"
    val senderAccountType = userData["account_type"] as? String ?: "Savings Account"
    
    val context = LocalContext.current
    val view = LocalView.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(
                            "Transaction Details",
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
                    IconButton(onClick = { captureAndShare(view, context) }) {
                        Icon(Icons.Default.Share, contentDescription = "Share", tint = Color(0xFF6366F1))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        },
        containerColor = DashBg,
        bottomBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = { captureAndSave(view, context) },
                    modifier = Modifier.weight(1f).height(50.dp),
                    shape = RoundedCornerShape(12.dp),
                    border = BorderStroke(1.dp, Color(0xFFE0E0E0))
                ) {
                    Icon(Icons.Outlined.FileDownload, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Download Receipt", color = DashPrimary, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                }
                Button(
                    onClick = { captureAndShare(view, context) },
                    modifier = Modifier.weight(1f).height(50.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4F46E5))
                ) {
                    Icon(Icons.Default.Share, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Share Receipt", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // Success Header
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                color = Color.White
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxWidth()) {
                        Surface(
                            modifier = Modifier.size(72.dp),
                            shape = CircleShape,
                            color = Color(0xFFF0FDF4)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = when(response.status?.uppercase()) {
                                        "SUCCESS", "SUCCESSFUL" -> Icons.Default.Check
                                        "PENDING" -> Icons.Default.Schedule
                                        "FAILED", "FAILURE" -> Icons.Default.Close
                                        else -> Icons.Default.Check
                                    },
                                    contentDescription = null,
                                    tint = when(response.status?.uppercase()) {
                                        "SUCCESS", "SUCCESSFUL" -> Color(0xFF22C55E)
                                        "PENDING" -> Color(0xFFF59E0B)
                                        "FAILED", "FAILURE" -> Color(0xFFEF4444)
                                        else -> Color(0xFF22C55E)
                                    },
                                    modifier = Modifier.size(40.dp)
                                )
                            }
                        }
                        Surface(
                            modifier = Modifier.align(Alignment.TopEnd),
                            color = when(response.status?.uppercase()) {
                                "SUCCESS", "SUCCESSFUL" -> Color(0xFFF0FDF4)
                                "PENDING" -> Color(0xFFFFF7ED)
                                "FAILED", "FAILURE" -> Color(0xFFFEF2F2)
                                else -> Color(0xFFF0FDF4)
                            },
                            shape = RoundedCornerShape(6.dp)
                        ) {
                            Text(
                                text = response.status?.lowercase()?.replaceFirstChar { it.uppercase() } ?: "Pending",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = when(response.status?.uppercase()) {
                                    "SUCCESS", "SUCCESSFUL" -> Color(0xFF22C55E)
                                    "PENDING" -> Color(0xFFF59E0B)
                                    "FAILED", "FAILURE" -> Color(0xFFEF4444)
                                    else -> Color(0xFF22C55E)
                                }
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = when(response.status?.uppercase()) {
                            "SUCCESS", "SUCCESSFUL" -> "Money Sent"
                            "PENDING" -> "Transfer Pending"
                            "FAILED", "FAILURE" -> "Transfer Failed"
                            else -> "Transaction Details"
                        },
                        fontSize = 15.sp, 
                        fontWeight = FontWeight.Bold, 
                        color = Color.Black
                    )
                    Text(
                        "₹${String.format(Locale.getDefault(), "%,.2f", response.amount ?: 0.0)}",
                        fontSize = 32.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.Black
                    )
                    Text(
                        "Rupees ${numberToWords(response.amount?.toInt() ?: 0)} Only",
                        fontSize = 12.sp,
                        color = Color.Gray,
                        textAlign = TextAlign.Center
                    )
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    HorizontalDivider(thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.CalendarToday, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color.Gray)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()).format(Date()),
                                fontSize = 13.sp,
                                color = Color.Gray
                            )
                        }
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("UPI Payment", fontSize = 13.sp, color = Color.Gray)
                            Spacer(modifier = Modifier.width(6.dp))
                            Icon(Icons.Default.AccountBalanceWallet, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color.Gray)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // To Section
            val recipientName = response.beneficiary?.name ?: response.beneficiary?.account ?: "Recipient"
            TransactionPartySection(
                title = "To",
                name = recipientName,
                detail1 = "A/c No: ${response.beneficiary?.account ?: ""}",
                detail2 = "IFSC: ${response.beneficiary?.ifsc ?: ""}",
                iconText = if (recipientName.all { it.isDigit() }) "AC" else recipientName.take(2).uppercase()
            )

            Spacer(modifier = Modifier.height(2.dp))
            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                Surface(
                    modifier = Modifier.size(32.dp),
                    shape = CircleShape,
                    color = Color.White,
                    shadowElevation = 2.dp
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, modifier = Modifier.size(20.dp), tint = DashPrimary)
                    }
                }
            }
            Spacer(modifier = Modifier.height(2.dp))

            // From Section
            TransactionPartySection(
                title = "From",
                name = senderName,
                detail1 = senderAccountType,
                detail2 = "Deccan Finance Bank - $senderAccount",
                iconText = senderName.take(2).uppercase()
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Transaction Details Accordion
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                color = Color.White
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Transaction Details", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                    }
                    
                    Spacer(modifier = Modifier.height(20.dp))
                    
                    DetailRow(Icons.Outlined.QrCode, "Transaction ID", response.transactionId ?: "N/A", true)
                    DetailRow(Icons.Outlined.Badge, "UTR / Reference No.", response.utrId ?: "N/A", true)
                    DetailRow(
                        icon = when(response.status?.uppercase()) {
                            "SUCCESS", "SUCCESSFUL" -> Icons.Outlined.CheckCircle
                            "PENDING" -> Icons.Outlined.Schedule
                            "FAILED", "FAILURE" -> Icons.Outlined.ErrorOutline
                            else -> Icons.Outlined.CheckCircle
                        },
                        label = "Status",
                        value = response.status?.lowercase()?.replaceFirstChar { it.uppercase() } ?: "Pending",
                        showCopy = false,
                        valueColor = when(response.status?.uppercase()) {
                            "SUCCESS", "SUCCESSFUL" -> Color(0xFF2E7D32)
                            "PENDING" -> Color(0xFFF59E0B)
                            "FAILED", "FAILURE" -> Color(0xFFD32F2F)
                            else -> Color(0xFF2E7D32)
                        }
                    )
                    
                    if (isExpanded) {
                        DetailRow(Icons.Outlined.Payment, "Payment Mode", if (response.provider?.contains("P2P", true) == true) "P2P Transfer" else "Bank Transfer", false)
                        DetailRow(Icons.Outlined.Description, "Remarks", response.remarks ?: "N/A", false)
                        DetailRow(Icons.Outlined.CancelPresentation, "Charges", "₹0.00", false)
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { isExpanded = !isExpanded },
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            if (isExpanded) "View Less" else "View More",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = DashPrimary
                        )
                        Icon(
                            if (isExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                            contentDescription = null,
                            tint = DashPrimary,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Need Help
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                color = Color(0xFFF5F6FF)
            ) {
                Row(
                    modifier = Modifier.padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        modifier = Modifier.size(44.dp),
                        shape = CircleShape,
                        color = Color.White
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Outlined.HeadsetMic, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(24.dp))
                        }
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Need Help?", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        Text(
                            "If you have any issues with this transaction, please contact our support team.",
                            fontSize = 10.sp,
                            color = Color.Gray,
                            lineHeight = 14.sp
                        )
                    }
                    Button(
                        onClick = { /* TODO */ },
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color.White),
                        border = BorderStroke(1.dp, Color(0xFFE0E0E0)),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 0.dp),
                        modifier = Modifier.height(36.dp)
                    ) {
                        Text("Get Help", color = DashPrimary, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(20.dp))
        }
    }
}

@Composable
fun TransactionPartySection(title: String, name: String, detail1: String, detail2: String, iconText: String) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        color = Color.White
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Gray)
            Spacer(modifier = Modifier.height(12.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Surface(
                    modifier = Modifier.size(48.dp),
                    shape = CircleShape,
                    color = Color(0xFFE8F5E9)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(iconText, color = Color(0xFF2E7D32), fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    }
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(name, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                    Text(detail1, fontSize = 11.sp, color = Color.Gray)
                    Text(detail2, fontSize = 11.sp, color = Color.Gray)
                }
            }
        }
    }
}

@Composable
fun DetailRow(icon: ImageVector, label: String, value: String, showCopy: Boolean, valueColor: Color = Color.Black) {
    val clipboardManager = LocalClipboardManager.current
    val context = LocalContext.current

    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            modifier = Modifier.size(32.dp),
            shape = RoundedCornerShape(8.dp),
            color = Color(0xFFF8F9FA)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(16.dp))
            }
        }
        Spacer(modifier = Modifier.width(12.dp))
        Text(label, fontSize = 12.sp, color = Color.Gray, modifier = Modifier.weight(1f))
        Text(value, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = valueColor)
        if (showCopy) {
            Spacer(modifier = Modifier.width(8.dp))
            Icon(
                Icons.Outlined.ContentCopy, 
                contentDescription = "Copy", 
                tint = DashPrimary, 
                modifier = Modifier.size(16.dp).clickable {
                    clipboardManager.setText(AnnotatedString(value))
                    Toast.makeText(context, "$label copied", Toast.LENGTH_SHORT).show()
                }
            )
        }
    }
}

private fun captureScreenshot(view: View): Bitmap {
    val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    view.draw(canvas)
    return bitmap
}

private fun captureAndSave(view: View, context: Context) {
    val bitmap = captureScreenshot(view)
    val filename = "Receipt_${System.currentTimeMillis()}.jpg"
    var fos: OutputStream? = null
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        context.contentResolver?.also { resolver ->
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/jpg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
            }
            val imageUri: Uri? = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
            fos = imageUri?.let { resolver.openOutputStream(it) }
        }
    } else {
        val imagesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        val image = File(imagesDir, filename)
        fos = FileOutputStream(image)
    }
    fos?.use {
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, it)
        Toast.makeText(context, "Receipt saved to Gallery", Toast.LENGTH_SHORT).show()
    }
}

private fun captureAndShare(view: View, context: Context) {
    val bitmap = captureScreenshot(view)
    val cachePath = File(context.cacheDir, "images")
    cachePath.mkdirs()
    val stream = FileOutputStream("$cachePath/receipt.jpg")
    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
    stream.close()

    val imageFile = File(cachePath, "receipt.jpg")
    val contentUri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", imageFile)

    if (contentUri != null) {
        val shareIntent = Intent().apply {
            action = Intent.ACTION_SEND
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            setDataAndType(contentUri, context.contentResolver.getType(contentUri))
            putExtra(Intent.EXTRA_STREAM, contentUri)
        }
        context.startActivity(Intent.createChooser(shareIntent, "Share Receipt"))
    }
}
