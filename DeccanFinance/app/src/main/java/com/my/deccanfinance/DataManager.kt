package com.my.deccanfinance

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_data")

class DataManager(private val context: Context) {

    companion object {
        val FULL_NAME = stringPreferencesKey("full_name")
        val EMAIL = stringPreferencesKey("email")
        val PHONE = stringPreferencesKey("phone")
        val APP_ID = stringPreferencesKey("app_id")
        val ACCOUNT_TYPE = stringPreferencesKey("account_type")
        val STATUS = stringPreferencesKey("status")
        val HAS_MPIN = booleanPreferencesKey("has_mpin")
        val ACCOUNT_NUMBER = stringPreferencesKey("account_number")
        val LOGIN_PIN_ENABLED = booleanPreferencesKey("login_pin_enabled")
        val BIOMETRIC_ENABLED = booleanPreferencesKey("biometric_enabled")
    }

    suspend fun saveUserData(user: UserDetails) {
        context.dataStore.edit { preferences ->
            preferences[FULL_NAME] = user.fullName
            preferences[EMAIL] = user.email
            preferences[PHONE] = user.phone
            preferences[APP_ID] = user.appId
            preferences[ACCOUNT_TYPE] = user.accountType
            preferences[STATUS] = user.status
            preferences[HAS_MPIN] = user.hasMpin
            preferences[ACCOUNT_NUMBER] = user.accountNumber ?: ""
        }
    }

    suspend fun saveUserFromLogin(user: User) {
        context.dataStore.edit { preferences ->
            preferences[FULL_NAME] = user.fullName
            preferences[EMAIL] = user.email
            preferences[PHONE] = user.phone
            preferences[APP_ID] = user.appId
            preferences[ACCOUNT_TYPE] = user.accountType
            preferences[STATUS] = user.status
        }
    }

    suspend fun setLoginPinEnabled(enabled: Boolean) {
        context.dataStore.edit { it[LOGIN_PIN_ENABLED] = enabled }
    }

    suspend fun setBiometricEnabled(enabled: Boolean) {
        context.dataStore.edit { it[BIOMETRIC_ENABLED] = enabled }
    }

    val userData: Flow<Map<String, Any>> = context.dataStore.data.map { preferences ->
        mapOf(
            "full_name" to (preferences[FULL_NAME] ?: ""),
            "email" to (preferences[EMAIL] ?: ""),
            "phone" to (preferences[PHONE] ?: ""),
            "app_id" to (preferences[APP_ID] ?: ""),
            "account_type" to (preferences[ACCOUNT_TYPE] ?: ""),
            "status" to (preferences[STATUS] ?: ""),
            "has_mpin" to (preferences[HAS_MPIN] ?: false),
            "account_number" to (preferences[ACCOUNT_NUMBER] ?: ""),
            "login_pin_enabled" to (preferences[LOGIN_PIN_ENABLED] ?: false),
            "biometric_enabled" to (preferences[BIOMETRIC_ENABLED] ?: false)
        )
    }
    
    suspend fun clearData() {
        context.dataStore.edit { it.clear() }
    }

    suspend fun saveStatusDirectly(status: String) {
        context.dataStore.edit { it[STATUS] = status }
    }

    suspend fun saveAppIdDirectly(appId: String) {
        context.dataStore.edit { it[APP_ID] = appId }
    }

    fun clearSession(context: Context) {
        val sharedPrefs = context.getSharedPreferences("api_session", Context.MODE_PRIVATE)
        sharedPrefs.edit().remove("cookies").apply()
    }
}
