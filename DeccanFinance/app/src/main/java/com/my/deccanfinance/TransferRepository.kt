package com.my.deccanfinance

import retrofit2.Response
import org.json.JSONObject

sealed class Result<out T> {
    object Loading : Result<Nothing>()
    data class Success<out T>(val data: T) : Result<T>()
    data class Error(val message: String) : Result<Nothing>()
}

class TransferRepository(private val apiService: ApiService) {

    suspend fun lookupRecipient(accountNumber: String): Result<RecipientInfo> {
        return try {
            val response = apiService.getRecipientDetails(RecipientLookupRequest(accountNumber))
            if (response.isSuccessful && response.body()?.success == true) {
                response.body()?.recipient?.let { Result.Success(it) } 
                    ?: Result.Error("Recipient data missing")
            } else {
                Result.Error(response.body()?.message ?: "Recipient not found")
            }
        } catch (e: Exception) {
            Result.Error(e.message ?: "Unknown error occurred")
        }
    }

    suspend fun executeP2pTransfer(
        recipientAccount: String,
        amount: Double,
        mpin: String,
        recipientName: String? = null
    ): Result<TransferP2PResponse> {
        return try {
            // First check if transaction is allowed
            val checkResponse = apiService.checkTxStatus(
                CheckTxStatusRequest(amount, recipientAccount, "P2P", recipientName)
            )
            
            if (checkResponse.isSuccessful) {
                val checkBody = checkResponse.body()
                if (checkBody?.allowed == false) {
                    // Transaction suspended, return as error but could also be successful "FAILED" result
                    // The user wants same failed page like success and pending.
                    // We can return a fake TransferP2PResponse with success=false and status=FAILED
                    return Result.Success(TransferP2PResponse(
                        success = false,
                        message = checkBody.message,
                        transactionId = checkBody.transactionId,
                        newBalance = null,
                        remarks = checkBody.message,
                        status = "FAILED"
                    ))
                }
            } else if (checkResponse.code() == 400 || checkResponse.code() == 401) {
                val errorBody = checkResponse.errorBody()?.string()
                if (errorBody != null) {
                    val jsonObj = org.json.JSONObject(errorBody)
                    if (jsonObj.has("allowed") && !jsonObj.getBoolean("allowed")) {
                        return Result.Success(TransferP2PResponse(
                            success = false,
                            message = jsonObj.getString("message"),
                            transactionId = if (jsonObj.has("transaction_id")) jsonObj.getString("transaction_id") else null,
                            newBalance = null,
                            remarks = jsonObj.getString("message"),
                            status = "FAILED"
                        ))
                    }
                }
            }

            val response = apiService.transferP2P(TransferP2PRequest(recipientAccount, amount, mpin))
            if (response.isSuccessful && response.body()?.success == true) {
                Result.Success(response.body()!!)
            } else {
                Result.Error(response.body()?.message ?: "Transfer failed")
            }
        } catch (e: Exception) {
            Result.Error(e.message ?: "Network error")
        }
    }

    suspend fun executeP2bPayout(
        name: String,
        account: String,
        ifsc: String,
        amount: Double,
        mpin: String
    ): Result<TransferPayoutResponse> {
        return try {
            // First check if transaction is allowed
            val checkResponse = apiService.checkTxStatus(
                CheckTxStatusRequest(amount, account, "PAYOUT", name)
            )
            
            if (checkResponse.isSuccessful) {
                val checkBody = checkResponse.body()
                if (checkBody?.allowed == false) {
                    return Result.Success(TransferPayoutResponse(
                        success = false,
                        message = checkBody.message,
                        transactionId = checkBody.transactionId,
                        utrId = null,
                        provider = "Deccan Finance",
                        beneficiary = BeneficiaryInfo(name, account, ifsc),
                        amount = amount,
                        remarks = checkBody.message,
                        status = "FAILED",
                        newBalance = null
                    ))
                }
            } else if (checkResponse.code() == 400 || checkResponse.code() == 401) {
                val errorBody = checkResponse.errorBody()?.string()
                if (errorBody != null) {
                    val jsonObj = org.json.JSONObject(errorBody)
                    if (jsonObj.has("allowed") && !jsonObj.getBoolean("allowed")) {
                        return Result.Success(TransferPayoutResponse(
                            success = false,
                            message = jsonObj.getString("message"),
                            transactionId = if (jsonObj.has("transaction_id")) jsonObj.getString("transaction_id") else null,
                            utrId = null,
                            provider = "Deccan Finance",
                            beneficiary = BeneficiaryInfo(name, account, ifsc),
                            amount = amount,
                            remarks = jsonObj.getString("message"),
                            status = "FAILED",
                            newBalance = null
                        ))
                    }
                }
            }

            val response = apiService.transferPayout(
                TransferPayoutRequest(
                    provider = "bharat4u",
                    beneficiaryName = name,
                    beneficiaryAccount = account,
                    ifscCode = ifsc,
                    amount = amount,
                    mpin = mpin
                )
            )
            if (response.isSuccessful && response.body()?.success == true) {
                Result.Success(response.body()!!)
            } else {
                Result.Error(response.body()?.message ?: "Payout failed")
            }
        } catch (e: Exception) {
            Result.Error(e.message ?: "Network error")
        }
    }
}
