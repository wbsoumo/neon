package com.my.deccanfinance

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class TransferUiState(
    val lookupResult: Result<RecipientInfo>? = null,
    val transferResult: Result<TransferP2PResponse>? = null,
    val payoutResult: Result<TransferPayoutResponse>? = null,
    val isLoading: Boolean = false
)

class TransferViewModel(private val repository: TransferRepository) : ViewModel() {

    private val _uiState = MutableStateFlow(TransferUiState())
    val uiState: StateFlow<TransferUiState> = _uiState.asStateFlow()

    fun lookupRecipient(accountNumber: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, lookupResult = null)
            val result = repository.lookupRecipient(accountNumber)
            _uiState.value = _uiState.value.copy(isLoading = false, lookupResult = result)
        }
    }

    fun sendMoneyP2P(accountNumber: String, amount: Double, mpin: String, recipientName: String? = null) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, transferResult = null)
            val result = repository.executeP2pTransfer(accountNumber, amount, mpin, recipientName)
            _uiState.value = _uiState.value.copy(isLoading = false, transferResult = result)
        }
    }

    fun sendMoneyP2B(name: String, accountNumber: String, ifsc: String, amount: Double, mpin: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, payoutResult = null)
            val result = repository.executeP2bPayout(name, accountNumber, ifsc, amount, mpin)
            _uiState.value = _uiState.value.copy(isLoading = false, payoutResult = result)
        }
    }
    
    fun resetResults() {
        _uiState.value = TransferUiState()
    }
}
