package com.my.deccanfinance

import android.content.Context
import android.util.Log
import com.google.gson.annotations.SerializedName
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST

// --- Data Models ---

data class RegisterRequest(
    @SerializedName("account_type") val accountType: String,
    @SerializedName("full_name") val fullName: String,
    @SerializedName("email") val email: String,
    @SerializedName("phone") val phone: String,
    @SerializedName("address") val address: String,
    @SerializedName("national_id") val nationalId: String,
    @SerializedName("aadhaar_number") val aadhaarNumber: String,
    @SerializedName("password") val password: String,
    @SerializedName("dob") val dob: String? = null,
    @SerializedName("gender") val gender: String? = null,
    @SerializedName("initial_deposit") val initialDeposit: Double? = null,
    @SerializedName("business_name") val businessName: String? = null,
    @SerializedName("business_reg_no") val businessRegNo: String? = null,
    @SerializedName("expected_turnover") val expectedTurnover: Double? = null,
    @SerializedName("signature_data") val signatureData: String,
    @SerializedName("portrait_data") val portraitData: String,
    @SerializedName("doc_pan_data") val docPanData: String,
    @SerializedName("doc_aadhaar_data") val docAadhaarData: String
)

data class RegisterResponse(
    val success: Boolean,
    @SerializedName("app_id") val appId: String?,
    val message: String
)

data class LoginRequest(
    val username: String,
    val password: String,
    @SerializedName("fcm_token") val fcmToken: String? = null
)

data class User(
    @SerializedName("app_id") val appId: String,
    @SerializedName("account_type") val accountType: String,
    @SerializedName("full_name") val fullName: String,
    val email: String,
    val phone: String,
    val balance: Double,
    val status: String
)

data class LoginResponse(
    val success: Boolean,
    val message: String,
    val user: User?
)

data class Contact(
    val name: String?,
    val phone: String
)

data class ContactRequest(
    val contacts: List<Contact>
)

data class ContactResponse(
    val success: Boolean,
    val message: String
)

data class AutoLoginResponse(
    val success: Boolean,
    val message: String,
    @SerializedName("app_id") val appId: String?,
    @SerializedName("session_id") val sessionId: String?
)

data class UserDetails(
    val id: Int,
    @SerializedName("app_id") val appId: String,
    @SerializedName("account_type") val accountType: String,
    @SerializedName("full_name") val fullName: String,
    val email: String,
    val phone: String,
    val dob: String?,
    val gender: String?,
    val address: String,
    @SerializedName("national_id") val nationalId: String,
    @SerializedName("initial_deposit") val initialDeposit: Double?,
    val balance: Double,
    @SerializedName("business_name") val businessName: String?,
    @SerializedName("business_reg_no") val businessRegNo: String?,
    @SerializedName("expected_turnover") val expectedTurnover: Double?,
    @SerializedName("signature_path") val signaturePath: String?,
    @SerializedName("photo_path") val photoPath: String?,
    @SerializedName("doc_pan_path") val docPanPath: String?,
    @SerializedName("doc_aadhaar_path") val docAadhaarPath: String?,
    val status: String,
    @SerializedName("account_number") val accountNumber: String?,
    @SerializedName("has_mpin") val hasMpin: Boolean,
    @SerializedName("created_at") val createdAt: String
)

data class UserDetailsResponse(
    val success: Boolean,
    val message: String?,
    val user: UserDetails?
)

data class UpdateProfileRequest(
    @SerializedName("full_name") val fullName: String? = null,
    val email: String? = null,
    val phone: String? = null,
    val address: String? = null,
    @SerializedName("national_id") val nationalId: String? = null,
    @SerializedName("aadhaar_number") val aadhaarNumber: String? = null,
    val dob: String? = null,
    val gender: String? = null,
    @SerializedName("business_name") val businessName: String? = null,
    @SerializedName("business_reg_no") val businessRegNo: String? = null,
    @SerializedName("expected_turnover") val expectedTurnover: Double? = null
)

data class UpdateProfileResponse(
    val success: Boolean,
    val message: String
)

data class AddBeneficiaryRequest(
    val type: String, // SELF_BANK or OTHER_BANK
    @SerializedName("beneficiary_account_number") val beneficiaryAccountNumber: String,
    @SerializedName("beneficiary_name") val beneficiaryName: String? = null,
    @SerializedName("ifsc_code") val ifscCode: String? = null,
    @SerializedName("daily_limit") val dailyLimit: Double? = null,
    val nickname: String? = null
)

data class AddBeneficiaryResponse(
    val success: Boolean,
    val message: String,
    val status: String? // APPROVED or PENDING
)

data class ComplianceResponse(
    val success: Boolean,
    @SerializedName("app_id") val appId: String?,
    val type: String?,
    val text: String?,
    @SerializedName("image_url") val imageUrl: String?,
    @SerializedName("pdf_url") val pdfUrl: String?,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("updated_at") val updatedAt: String?,
    val message: String?
)

data class CreateMpinRequest(
    val mpin: String,
    @SerializedName("aadhaar_last_6") val aadhaarLast6: String
)

data class CreateMpinResponse(
    val success: Boolean,
    val message: String
)

data class VerifyAadhaarRequest(
    @SerializedName("aadhaar_last_6") val aadhaarLast6: String
)

data class VerifyAadhaarResponse(
    val success: Boolean,
    val message: String
)

data class SetLoginPinRequest(
    @SerializedName("login_pin") val loginPin: String
)

data class SetLoginPinResponse(
    val success: Boolean,
    val message: String
)

data class LoginWithPinRequest(
    val username: String,
    val pin: String,
    @SerializedName("fcm_token") val fcmToken: String? = null
)

data class RegisterBiometricRequest(
    @SerializedName("biometric_token") val biometricToken: String,
    @SerializedName("device_name") val deviceName: String? = null
)

data class RegisterBiometricResponse(
    val success: Boolean,
    val message: String
)

data class LoginWithBiometricRequest(
    @SerializedName("biometric_token") val biometricToken: String,
    @SerializedName("fcm_token") val fcmToken: String? = null
)

data class ToggleLoginSettingsRequest(
    @SerializedName("pin_login_enabled") val pinLoginEnabled: Boolean? = null,
    @SerializedName("biometric_login_enabled") val biometricLoginEnabled: Boolean? = null
)

data class LoginSettings(
    @SerializedName("pin_login_enabled") val pinLoginEnabled: Boolean,
    @SerializedName("biometric_login_enabled") val biometricLoginEnabled: Boolean
)

data class ToggleLoginSettingsResponse(
    val success: Boolean,
    val message: String,
    val settings: LoginSettings?
)

data class Beneficiary(
    val id: Int,
    val type: String,
    @SerializedName("beneficiary_name") val beneficiaryName: String,
    @SerializedName("beneficiary_account_number") val beneficiaryAccountNumber: String,
    @SerializedName("ifsc_code") val ifscCode: String?,
    @SerializedName("daily_limit") val dailyLimit: Double,
    val nickname: String?,
    val status: String,
    @SerializedName("created_at") val createdAt: String
)

data class BeneficiariesResponse(
    val success: Boolean,
    val beneficiaries: List<Beneficiary>?
)

data class Notification(
    val id: Int,
    val title: String,
    val body: String,
    @SerializedName("image_url") val imageUrl: String?,
    val category: String,
    @SerializedName("sent_status") val sentStatus: String,
    @SerializedName("created_at") val createdAt: String
)

data class NotificationsResponse(
    val success: Boolean,
    val message: String?,
    val notifications: List<Notification>?
)

data class Transaction(
    val id: Int,
    @SerializedName("transaction_id") val transactionId: String,
    @SerializedName("sender_app_id") val senderAppId: String,
    @SerializedName("sender_name") val senderName: String,
    @SerializedName("recipient_account") val recipientAccount: String,
    @SerializedName("recipient_name") val recipientName: String?,
    val amount: Double,
    val type: String,
    @SerializedName("flow_type") val flowType: String, // DEBIT or CREDIT
    @SerializedName("status") val status: String?,
    @SerializedName("utr_id") val utrId: String?,
    val remarks: String?,
    @SerializedName("created_at") val createdAt: String
)

data class TransactionsResponse(
    val success: Boolean,
    val message: String?,
    val transactions: List<Transaction>?
)

data class TransferPayoutRequest(
    val provider: String,
    @SerializedName("beneficiary_name") val beneficiaryName: String,
    @SerializedName("beneficiary_account") val beneficiaryAccount: String,
    @SerializedName("ifsc_code") val ifscCode: String,
    val amount: Double,
    val mpin: String,
    val remarks: String? = null
)

data class BeneficiaryInfo(
    val name: String,
    val account: String,
    val ifsc: String
)

data class TransferPayoutResponse(
    val success: Boolean,
    val message: String,
    @SerializedName("transaction_id") val transactionId: String?,
    @SerializedName("utr_id") val utrId: String?,
    val provider: String?,
    val beneficiary: BeneficiaryInfo?,
    val amount: Double?,
    val remarks: String?,
    @SerializedName("status") val status: String?,
    @SerializedName("new_balance") val newBalance: Double?
)

data class TransferP2PRequest(
    @SerializedName("recipient_account_number") val recipientAccountNumber: String,
    val amount: Double,
    val mpin: String,
    val remarks: String? = null
)

data class TransferP2PResponse(
    val success: Boolean,
    val message: String,
    @SerializedName("transaction_id") val transactionId: String?,
    @SerializedName("new_balance") val newBalance: Double?,
    val remarks: String? = null,
    val status: String? = null
)

data class RecipientLookupRequest(
    @SerializedName("account_number") val accountNumber: String
)

data class RecipientInfo(
    @SerializedName("full_name") val fullName: String,
    @SerializedName("account_number") val accountNumber: String
)

data class ScannedUser(
    @SerializedName("full_name") val fullName: String,
    val email: String?,
    val phone: String?,
    @SerializedName("account_number") val accountNumber: String,
    val status: String?
)

data class RecipientLookupResponse(
    val success: Boolean,
    val message: String?,
    val user: ScannedUser? = null,
    val recipient: RecipientInfo? = null
)

data class SendMoneyRequest(
    @SerializedName("account_number") val accountNumber: String,
    val amount: Double,
    val mpin: String,
    val remarks: String? = null
)

data class SendMoneyResponse(
    val success: Boolean,
    val message: String,
    @SerializedName("transaction_id") val transactionId: String?,
    @SerializedName("utr_id") val utrId: String?,
    @SerializedName("new_balance") val newBalance: Double?
)

data class SaveSameBankBeneficiaryRequest(
    @SerializedName("beneficiary_account_number") val beneficiaryAccountNumber: String,
    @SerializedName("beneficiary_name") val beneficiaryName: String? = null
)

data class SaveSameBankBeneficiaryResponse(
    val success: Boolean,
    val message: String,
    val beneficiary: Beneficiary?
)

data class CheckTxStatusRequest(
    val amount: Double,
    @SerializedName("recipient_account") val recipientAccount: String,
    val type: String,
    @SerializedName("recipient_name") val recipientName: String? = null
)

data class CheckTxStatusResponse(
    val success: Boolean,
    val allowed: Boolean,
    val message: String,
    @SerializedName("transaction_id") val transactionId: String? = null
)

data class ForgotPasswordRequest(
    val action: String,
    val identity: String? = null,
    @SerializedName("session_id") val sessionId: String? = null,
    val otp: String? = null,
    @SerializedName("new_password") val newPassword: String? = null
)

data class ForgotPasswordResponse(
    val success: Boolean,
    val message: String,
    @SerializedName("session_id") val sessionId: String? = null
)

data class StatementResponse(
    val success: Boolean,
    val message: String,
    val filename: String?,
    @SerializedName("pdf_path") val pdfPath: String?,
    @SerializedName("download_url") val downloadUrl: String?
)

data class StatementItem(
    val filename: String,
    @SerializedName("date_range") val dateRange: String?,
    val size: String?,
    @SerializedName("download_url") val downloadUrl: String
)

data class StatementListResponse(
    val success: Boolean,
    val statements: List<StatementItem>?
)

// --- API Service ---

interface ApiService {
    @POST("register.php")
    suspend fun register(@Body request: RegisterRequest): Response<RegisterResponse>

    @POST("login.php")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("upload_contacts.php")
    suspend fun uploadContacts(@Body request: ContactRequest): Response<ContactResponse>

    @GET("get_contacts.php")
    suspend fun getContacts(): Response<List<Contact>>

    @POST("auto_login.php")
    suspend fun autoLogin(): Response<AutoLoginResponse>

    @GET("get_user_details.php")
    suspend fun getUserDetails(): Response<UserDetailsResponse>

    @POST("update_profile.php")
    suspend fun updateProfile(@Body request: UpdateProfileRequest): Response<UpdateProfileResponse>

    @GET("get_sof.php")
    suspend fun getSOF(): Response<ComplianceResponse>

    @GET("get_fdi.php")
    suspend fun getFDI(): Response<ComplianceResponse>

    @GET("get_fema.php")
    suspend fun getFEMA(): Response<ComplianceResponse>

    @GET("get_aml.php")
    suspend fun getAML(): Response<ComplianceResponse>

    @POST("add_beneficiary.php")
    suspend fun addBeneficiary(@Body request: AddBeneficiaryRequest): Response<AddBeneficiaryResponse>

    @POST("create_mpin.php")
    suspend fun createMpin(@Body request: CreateMpinRequest): Response<CreateMpinResponse>

    @POST("verify_aadhaar.php")
    suspend fun verifyAadhaar(@Body request: VerifyAadhaarRequest): Response<VerifyAadhaarResponse>

    @POST("set_login_pin.php")
    suspend fun setLoginPin(@Body request: SetLoginPinRequest): Response<SetLoginPinResponse>

    @POST("login_with_pin.php")
    suspend fun loginWithPin(@Body request: LoginWithPinRequest): Response<LoginResponse>

    @POST("register_biometric.php")
    suspend fun registerBiometric(@Body request: RegisterBiometricRequest): Response<RegisterBiometricResponse>

    @POST("login_with_biometric.php")
    suspend fun loginWithBiometric(@Body request: LoginWithBiometricRequest): Response<LoginResponse>

    @POST("toggle_login_settings.php")
    suspend fun toggleLoginSettings(@Body request: ToggleLoginSettingsRequest): Response<ToggleLoginSettingsResponse>

    @GET("get_beneficiaries.php")
    suspend fun getBeneficiaries(): Response<BeneficiariesResponse>

    @GET("get_notifications.php")
    suspend fun getNotifications(): Response<NotificationsResponse>

    @GET("get_transactions.php")
    suspend fun getTransactions(): Response<TransactionsResponse>

    @POST("transfer_payout.php")
    suspend fun transferPayout(@Body request: TransferPayoutRequest): Response<TransferPayoutResponse>

    @POST("transfer_p2p.php")
    suspend fun transferP2P(@Body request: TransferP2PRequest): Response<TransferP2PResponse>

    @POST("get_recipient_details.php")
    suspend fun getRecipientDetails(@Body request: RecipientLookupRequest): Response<RecipientLookupResponse>

    @POST("get_user_by_account.php")
    suspend fun getUserByAccount(@Body request: RecipientLookupRequest): Response<RecipientLookupResponse>

    @POST("send_money.php")
    suspend fun sendMoney(@Body request: SendMoneyRequest): Response<SendMoneyResponse>

    @POST("save_same_bank_beneficiary.php")
    suspend fun saveSameBankBeneficiary(@Body request: SaveSameBankBeneficiaryRequest): Response<SaveSameBankBeneficiaryResponse>

    @GET("get_same_bank_beneficiaries.php")
    suspend fun getSameBankBeneficiaries(): Response<BeneficiariesResponse>

    @POST("forgot_password.php")
    suspend fun forgotPassword(@Body request: ForgotPasswordRequest): Response<ForgotPasswordResponse>

    @GET("get_statement.php")
    suspend fun getStatement(
        @retrofit2.http.Query("from_date") fromDate: String? = null,
        @retrofit2.http.Query("to_date") toDate: String? = null,
        @retrofit2.http.Query("download") download: String? = null
    ): Response<StatementResponse>

    @GET("get_statements.php")
    suspend fun getStatements(): Response<StatementListResponse>

    @POST("check_tx_status.php")
    suspend fun checkTxStatus(@Body request: CheckTxStatusRequest): Response<CheckTxStatusResponse>

    companion object {
        private const val BASE_URL = "http://13.232.195.16/api/"

        fun create(context: Context): ApiService {
            val logging = HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            }

            val client = OkHttpClient.Builder()
                .addInterceptor(logging)
                .cookieJar(PersistentCookieJar(context))
                .build()

            return Retrofit.Builder()
                .baseUrl(BASE_URL)
                .client(client)
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(ApiService::class.java)
        }
    }
}

fun Transaction.toTransferPayoutResponse(): TransferPayoutResponse {
    return TransferPayoutResponse(
        success = true,
        message = "Transaction retrieved from history",
        transactionId = this.transactionId,
        utrId = this.utrId ?: "N/A",
        provider = if (this.type == "P2P") "Deccan P2P" else "Deccan Finance",
        beneficiary = BeneficiaryInfo(
            name = this.recipientName ?: this.recipientAccount,
            account = this.recipientAccount,
            ifsc = "DECCAN001"
        ),
        amount = this.amount,
        status = this.status,
        remarks = this.remarks,
        newBalance = null
    )
}

// --- Cookie Management ---

class PersistentCookieJar(context: Context) : CookieJar {
    private val sharedPrefs = context.getSharedPreferences("api_session", Context.MODE_PRIVATE)
    private val cookies = mutableListOf<Cookie>()
    private val host = "13.232.195.16"

    init {
        val storedCookies = sharedPrefs.getStringSet("cookies", null)
        Log.d("CookieJar", "Loading stored cookies: ${storedCookies?.size ?: 0}")
        storedCookies?.forEach { cookieString ->
            Cookie.parse("http://$host".toHttpUrl(), cookieString)?.let {
                cookies.add(it)
                Log.d("CookieJar", "Restored cookie: ${it.name}=${it.value}")
            }
        }
    }

    override fun saveFromResponse(url: HttpUrl, responseCookies: List<Cookie>) {
        if (url.host == host) {
            // Filter out existing cookies with same name from this host to avoid duplicates
            val newCookies = responseCookies.filter { it.name == "PHPSESSID" }.map { cookie ->
                // Extend session for 365 days
                Cookie.Builder()
                    .name(cookie.name)
                    .value(cookie.value)
                    .domain(cookie.domain)
                    .path(cookie.path)
                    .expiresAt(System.currentTimeMillis() + (365L * 24 * 60 * 60 * 1000))
                    .let { builder -> if (cookie.secure) builder.secure() else builder }
                    .let { builder -> if (cookie.httpOnly) builder.httpOnly() else builder }
                    .build()
            }
            
            if (newCookies.isNotEmpty()) {
                cookies.removeAll { it.name == "PHPSESSID" }
                cookies.addAll(newCookies)
                
                val cookieSet = cookies.map { it.toString() }.toSet()
                sharedPrefs.edit().putStringSet("cookies", cookieSet).apply()
                Log.d("CookieJar", "Saved ${newCookies.size} cookies with 365 days expiry. Total: ${cookies.size}")
            }
        }
    }

    override fun loadForRequest(url: HttpUrl): List<Cookie> {
        val now = System.currentTimeMillis()
        // Remove expired cookies
        cookies.removeAll { it.expiresAt < now }
        
        val matchedCookies = if (url.host == host) cookies else emptyList()
        Log.d("CookieJar", "Loading for ${url.host}: found ${matchedCookies.size} matched cookies")
        return matchedCookies
    }
}
