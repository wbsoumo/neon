package com.my.deccanfinance

import com.google.gson.annotations.SerializedName
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.GET
import retrofit2.http.Path

data class IfscResponse(
    @SerializedName("BANK") val bank: String,
    @SerializedName("IFSC") val ifsc: String,
    @SerializedName("BRANCH") val branch: String,
    @SerializedName("ADDRESS") val address: String,
    @SerializedName("CONTACT") val contact: String,
    @SerializedName("CITY") val city: String,
    @SerializedName("DISTRICT") val district: String,
    @SerializedName("STATE") val state: String,
    @SerializedName("RTGS") val rtgs: Boolean,
    @SerializedName("NEFT") val neft: Boolean,
    @SerializedName("IMPS") val imps: Boolean,
    @SerializedName("UPI") val upi: Boolean,
    @SerializedName("MICR") val micr: String?
)

interface IfscService {
    @GET("{ifsc}")
    suspend fun getBankDetails(@Path("ifsc") ifsc: String): Response<IfscResponse>

    companion object {
        private const val BASE_URL = "https://ifsc.razorpay.com/"

        fun create(): IfscService {
            val logging = HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            }

            val client = OkHttpClient.Builder()
                .addInterceptor(logging)
                .build()

            return Retrofit.Builder()
                .baseUrl(BASE_URL)
                .client(client)
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(IfscService::class.java)
        }
    }
}
