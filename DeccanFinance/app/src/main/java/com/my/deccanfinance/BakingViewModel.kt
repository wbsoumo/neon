package com.my.deccanfinance

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import org.json.JSONObject

sealed class ScanPayState {
    object Idle : ScanPayState()
    object Loading : ScanPayState()
    data class UserDetailsLoaded(val user: ScannedUser) : ScanPayState()
    data class PaymentSuccess(val message: String, val transactionId: String?, val remarks: String? = null) : ScanPayState()
    data class Error(val message: String) : ScanPayState()
}

class BakingViewModel : ViewModel() {
    private val _scanPayState = MutableStateFlow<ScanPayState>(ScanPayState.Idle)
    val scanPayState: StateFlow<ScanPayState> = _scanPayState.asStateFlow()

    fun getUserByAccount(apiService: ApiService, accountNumber: String) {
        _scanPayState.value = ScanPayState.Loading
        viewModelScope.launch {
            try {
                val response = apiService.getUserByAccount(RecipientLookupRequest(accountNumber))
                if (response.isSuccessful) {
                    val body = response.body()
                    if (body?.success == true && body.user != null) {
                        _scanPayState.value = ScanPayState.UserDetailsLoaded(body.user)
                    } else {
                        _scanPayState.value = ScanPayState.Error(body?.message ?: "Account not found")
                    }
                } else {
                    val errorMsg = try {
                        val errorBody = response.errorBody()?.string()
                        if (errorBody != null) {
                            JSONObject(errorBody).getString("message")
                        } else {
                            "Failed to fetch user details (${response.code()})"
                        }
                    } catch (e: Exception) {
                        "Failed to fetch user details (${response.code()})"
                    }
                    _scanPayState.value = ScanPayState.Error(errorMsg)
                }
            } catch (e: Exception) {
                _scanPayState.value = ScanPayState.Error(e.localizedMessage ?: "An error occurred")
            }
        }
    }

    fun sendMoney(apiService: ApiService, accountNumber: String, amount: Double, mpin: String, remarks: String? = null) {
        _scanPayState.value = ScanPayState.Loading
        viewModelScope.launch {
            try {
                Log.d("BakingViewModel", "Sending money: account=$accountNumber, amount=$amount, mpin=$mpin, remarks=$remarks")
                val response = apiService.sendMoney(SendMoneyRequest(accountNumber, amount, mpin, remarks))
                
                if (response.isSuccessful) {
                    val body = response.body()
                    if (body?.success == true) {
                        Log.d("BakingViewModel", "Payment success: ${body.message}")
                        _scanPayState.value = ScanPayState.PaymentSuccess(
                            body.message,
                            body.transactionId,
                            remarks
                        )
                    } else {
                        val msg = body?.message ?: "Payment failed"
                        Log.e("BakingViewModel", "Payment failed from body: $msg")
                        _scanPayState.value = ScanPayState.Error(msg)
                    }
                } else {
                    val errorMsg = try {
                        val errorBody = response.errorBody()?.string()
                        if (errorBody != null) {
                            JSONObject(errorBody).getString("message")
                        } else {
                            "Payment failed (${response.code()})"
                        }
                    } catch (e: Exception) {
                        "Payment failed (${response.code()})"
                    }
                    Log.e("BakingViewModel", "Payment failed with code ${response.code()}: $errorMsg")
                    _scanPayState.value = ScanPayState.Error(errorMsg)
                }
            } catch (e: Exception) {
                Log.e("BakingViewModel", "Payment exception", e)
                _scanPayState.value = ScanPayState.Error(e.localizedMessage ?: "An error occurred")
            }
        }
    }

    fun resetState() {
        _scanPayState.value = ScanPayState.Idle
    }
}
