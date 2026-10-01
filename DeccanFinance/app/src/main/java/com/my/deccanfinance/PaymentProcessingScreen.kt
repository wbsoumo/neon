package com.my.deccanfinance

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dotlottie.dlplayer.Mode
import com.lottiefiles.dotlottie.core.compose.ui.DotLottieAnimation
import com.lottiefiles.dotlottie.core.util.DotLottieSource
import com.my.deccanfinance.ui.theme.DashBg
import com.my.deccanfinance.ui.theme.DashPrimary
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentProcessingScreen(
    response: TransferPayoutResponse,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(
                            "Payment Processing",
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
                actions = { Spacer(modifier = Modifier.width(48.dp)) },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        },
        containerColor = Color.White
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(24.dp))

            // Lottie Processing Animation
            Box(contentAlignment = Alignment.Center, modifier = Modifier.size(180.dp)) {
                DotLottieAnimation(
                    source = DotLottieSource.Asset("processing.lottie"),
                    autoplay = true,
                    loop = true,
                    speed = 2f,
                    useFrameInterpolation = false,
                    playMode = Mode.FORWARD,
                    modifier = Modifier.fillMaxSize()
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                "Processing Payment",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF1A1C1E),
                textAlign = TextAlign.Center
            )
            Text(
                "Please wait while we securely process your payment",
                fontSize = 14.sp,
                color = Color.Gray,
                modifier = Modifier.padding(top = 8.dp),
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(40.dp))

            // Payment Stepper
            PaymentStepper()

            Spacer(modifier = Modifier.height(32.dp))

            // Security Badge
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color(0xFFF5F6FF)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(Icons.Outlined.Shield, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Your payment is secure and encrypted", fontSize = 13.sp, color = DashPrimary, fontWeight = FontWeight.Medium)
                }
            }

            Spacer(modifier = Modifier.height(40.dp))

            // Payment Summary
            Text(
                "Payment Summary",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = Color.Black,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(16.dp))

            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                border = BorderStroke(1.dp, Color(0xFFF0F0F0)),
                color = Color.White
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Surface(
                            modifier = Modifier.size(44.dp),
                            shape = RoundedCornerShape(12.dp),
                            color = Color(0xFFF5F6FF)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.ArrowOutward, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                            }
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text("To", fontSize = 11.sp, color = Color.Gray)
                            Text(response.beneficiary?.name ?: "Unknown", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                            Text("A/c: ${response.beneficiary?.account ?: ""}", fontSize = 11.sp, color = Color.Gray)
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text("Amount", fontSize = 11.sp, color = Color.Gray)
                            Text("₹${String.format(Locale.getDefault(), "%,.2f", response.amount ?: 0.0)}", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        }
                    }

                    HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))

                    Row(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Outlined.Description, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color.Gray)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Remarks", fontSize = 11.sp, color = Color.Gray)
                            }
                            Text(response.remarks ?: "N/A", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color.Black, modifier = Modifier.padding(top = 4.dp))
                        }
                        Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.End) {
                            Text("Payment Mode", fontSize = 11.sp, color = Color.Gray)
                            Text("IMPS / Payout", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color.Black, modifier = Modifier.padding(top = 4.dp))
                        }
                    }

                    HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp), thickness = 0.5.dp, color = Color.LightGray.copy(alpha = 0.3f))

                    Row(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Outlined.CalendarToday, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color.Gray)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Date & Time", fontSize = 11.sp, color = Color.Gray)
                            }
                            Text(SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()).format(Date()), fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color.Black, modifier = Modifier.padding(top = 4.dp))
                        }
                        Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.End) {
                            Text("Reference No.", fontSize = 11.sp, color = Color.Gray)
                            Text(response.transactionId ?: "PENDING", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color.Black, modifier = Modifier.padding(top = 4.dp))
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // What's happening?
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color.White
            ) {
                Row(modifier = Modifier.padding(4.dp), verticalAlignment = Alignment.Top) {
                    Icon(Icons.Outlined.Info, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(20.dp))
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text("What's happening?", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DashPrimary)
                        Text(
                            "We are securely transferring your money. This usually takes a few seconds.",
                            fontSize = 12.sp,
                            color = Color.Gray,
                            lineHeight = 18.sp,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Footer Notice
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                color = Color(0xFFF8F9FF)
            ) {
                Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.Lock, contentDescription = null, tint = DashPrimary, modifier = Modifier.size(24.dp))
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text("Safe. Secure. Instant.", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DashPrimary)
                        Text(
                            "Please do not press back or close the app until the payment is completed.",
                            fontSize = 11.sp,
                            color = Color.Gray,
                            lineHeight = 16.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
fun PaymentStepper() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        StepItem("Payment Initiated", true, true)
        StepDivider(true)
        StepItem("Processing", true, false)
        StepDivider(false)
        StepItem("Verifying", false, false)
        StepDivider(false)
        StepItem("Completed", false, false)
    }
}

@Composable
fun StepItem(label: String, isCompleted: Boolean, isFirst: Boolean) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(70.dp)
    ) {
        Box(
            modifier = Modifier
                .size(28.dp)
                .clip(CircleShape)
                .background(if (isCompleted) DashPrimary else Color.White)
                .border(2.dp, if (isCompleted) DashPrimary else Color.LightGray.copy(alpha = 0.5f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            if (isCompleted) {
                if (isFirst) {
                    Icon(Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                } else {
                    Box(modifier = Modifier.size(10.dp).clip(CircleShape).background(Color.White))
                }
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            label,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            color = if (isCompleted) DashPrimary else Color.Gray,
            textAlign = TextAlign.Center,
            lineHeight = 12.sp
        )
    }
}

@Composable
fun StepDivider(isCompleted: Boolean) {
    Box(
        modifier = Modifier
            .padding(bottom = 20.dp) // Align with circles
            .height(2.dp)
            .width(20.dp)
            .background(if (isCompleted) DashPrimary else Color.LightGray.copy(alpha = 0.5f))
    )
}
