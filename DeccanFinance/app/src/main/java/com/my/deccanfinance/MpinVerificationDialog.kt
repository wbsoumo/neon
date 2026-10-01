package com.my.deccanfinance

import android.view.HapticFeedbackConstants
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Backspace
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.my.deccanfinance.ui.theme.DashPrimary

@Composable
fun MpinVerificationDialog(
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var mpin by remember { mutableStateOf("") }
    val view = LocalView.current

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = Color.White
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }

                Spacer(modifier = Modifier.height(48.dp))
                
                Text(
                    "Enter Transaction PIN",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
                Text(
                    "Please enter your 6-digit MPIN to authorize this transaction",
                    fontSize = 14.sp,
                    color = Color.Gray,
                    modifier = Modifier.padding(top = 8.dp)
                )

                Spacer(modifier = Modifier.height(48.dp))

                // PIN Dots
                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.padding(vertical = 24.dp)
                ) {
                    repeat(6) { index ->
                        val isFilled = index < mpin.length
                        Box(
                            modifier = Modifier
                                .size(16.dp)
                                .clip(CircleShape)
                                .background(if (isFilled) DashPrimary else Color(0xFFE5E7EB))
                        )
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                // Numpad
                val keys = listOf(
                    listOf("1", "2", "3"),
                    listOf("4", "5", "6"),
                    listOf("7", "8", "9"),
                    listOf("", "0", "back")
                )

                Column(
                    modifier = Modifier.padding(bottom = 32.dp),
                    verticalArrangement = Arrangement.spacedBy(20.dp)
                ) {
                    keys.forEach { row ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            row.forEach { key ->
                                Box(
                                    modifier = Modifier
                                        .size(80.dp)
                                        .clip(CircleShape)
                                        .clickable {
                                            if (key.isNotEmpty()) {
                                                view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                                                if (key == "back") {
                                                    if (mpin.isNotEmpty()) mpin = mpin.dropLast(1)
                                                } else {
                                                    if (mpin.length < 6) {
                                                        mpin += key
                                                        if (mpin.length == 6) {
                                                            onConfirm(mpin)
                                                        }
                                                    }
                                                }
                                            }
                                        },
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (key == "back") {
                                        Icon(Icons.AutoMirrored.Filled.Backspace, contentDescription = "Delete", tint = Color.Black)
                                    } else {
                                        Text(key, fontSize = 28.sp, fontWeight = FontWeight.SemiBold, color = Color.Black)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
