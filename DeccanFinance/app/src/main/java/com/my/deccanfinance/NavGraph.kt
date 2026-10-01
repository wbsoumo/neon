package com.my.deccanfinance

import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.google.gson.Gson
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

sealed class Screen(val route: String) {
    object Splash : Screen("splash")
    object Login : Screen("login")
    object Register : Screen("register")
    object Dashboard : Screen("dashboard")
    object Profile : Screen("profile")
    object UpdateProfile : Screen("update_profile")
    object SetMpin : Screen("set_mpin")
    object Baking : Screen("baking")
    object Transfer : Screen("transfer")
    object AddBeneficiary : Screen("add_beneficiary")
    object AddSameBankBeneficiary : Screen("add_same_bank_beneficiary")
    object AccountDetails : Screen("account_details")
    object Settings : Screen("settings")
    object Notifications : Screen("notifications")
    object Passbook : Screen("passbook")
    object SetLoginPin : Screen("set_login_pin")
    object PinLogin : Screen("pin_login")
    object ForgotPassword : Screen("forgot_password")
    object Beneficiaries : Screen("beneficiaries")
    object ReceiveMoney : Screen("receive_money")
    object LoanService : Screen("loan_service")
    object PayoutDetails : Screen("payout_details/{data}") {
        fun createRoute(data: String) = "payout_details/$data"
    }
    object SOF : Screen("sof")
    object FDI : Screen("fdi")
    object FEMA : Screen("fema")
    object AML : Screen("aml")
    object RequestStatement : Screen("request_statement")
}

@Composable
fun NavGraph(
    navController: NavHostController, 
    apiService: ApiService,
    ifscService: IfscService,
    dataManager: DataManager,
    onCloseApp: () -> Unit
) {
    val scope = rememberCoroutineScope()
    NavHost(
        navController = navController,
        startDestination = Screen.Splash.route
    ) {
        composable(Screen.Splash.route) {
            SplashScreen(
                apiService = apiService,
                dataManager = dataManager,
                onSplashFinished = { isLogged ->
                    scope.launch {
                        val userData = dataManager.userData.first()
                        val loginPinEnabled = userData["login_pin_enabled"] as? Boolean ?: false
                        val biometricEnabled = userData["biometric_enabled"] as? Boolean ?: false
                        
                        val destination = if (isLogged) {
                            if (loginPinEnabled || biometricEnabled) Screen.PinLogin.route 
                            else Screen.Dashboard.route
                        } else {
                            Screen.Login.route
                        }
                        
                        navController.navigate(destination) {
                            popUpTo(Screen.Splash.route) { inclusive = true }
                        }
                    }
                }
            )
        }
        composable(Screen.Login.route) {
            LoginScreen(
                apiService = apiService,
                dataManager = dataManager,
                onLoginSuccess = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onRegisterClick = {
                    navController.navigate(Screen.Register.route)
                },
                onForgotPasswordClick = {
                    navController.navigate(Screen.ForgotPassword.route)
                }
            )
        }
        composable(Screen.ForgotPassword.route) {
            ForgotPasswordScreen(
                apiService = apiService,
                onSuccess = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.ForgotPassword.route) { inclusive = true }
                    }
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.Register.route) {
            RegisterScreen(
                apiService = apiService,
                dataManager = dataManager,
                onRegisterSuccess = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.Register.route) { inclusive = true }
                    }
                }, onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.Dashboard.route) {
            DashboardScreen(
                apiService = apiService,
                dataManager = dataManager,
                onBakingClick = {
                    navController.navigate(Screen.Baking.route)
                },
                onProfileClick = {
                    navController.navigate(Screen.Profile.route)
                },
                onNotificationClick = {
                    navController.navigate(Screen.Notifications.route)
                },
                onTransferClick = {
                    navController.navigate(Screen.Transfer.route)
                },
                onReceiveClick = {
                    navController.navigate(Screen.ReceiveMoney.route)
                },
                onBeneficiariesClick = {
                    navController.navigate(Screen.Beneficiaries.route)
                },
                onAccountDetailsClick = {
                    navController.navigate(Screen.AccountDetails.route)
                },
                onSettingsClick = {
                    navController.navigate(Screen.Settings.route)
                },
                onSetMpinClick = {
                    navController.navigate(Screen.SetMpin.route)
                },
                onPassbookClick = {
                    navController.navigate(Screen.Passbook.route)
                },
                onSofClick = {
                    navController.navigate(Screen.SOF.route)
                },
                onFdiClick = {
                    navController.navigate(Screen.FDI.route)
                },
                onFemaClick = {
                    navController.navigate(Screen.FEMA.route)
                },
                onAmlClick = {
                    navController.navigate(Screen.AML.route)
                },
                onLoanProductClick = {
                    navController.navigate(Screen.LoanService.route)
                },
                onTransactionClick = { response ->
                    val json = Gson().toJson(response)
                    navController.navigate(Screen.PayoutDetails.createRoute(java.net.URLEncoder.encode(json, "UTF-8")))
                },
                onCloseApp = onCloseApp
            )
        }
        composable(Screen.SOF.route) {
            ComplianceDetailScreen("Sources of Fund", "SOF", apiService) { navController.popBackStack() }
        }
        composable(Screen.FDI.route) {
            ComplianceDetailScreen("Foreign Direct Investment", "FDI", apiService) { navController.popBackStack() }
        }
        composable(Screen.FEMA.route) {
            ComplianceDetailScreen("FEMA Compliance", "FEMA", apiService) { navController.popBackStack() }
        }
        composable(Screen.AML.route) {
            ComplianceDetailScreen("Anti-Money Laundering", "AML", apiService) { navController.popBackStack() }
        }
        composable(Screen.SetMpin.route) {
            SetMpinScreen(
                apiService = apiService,
                dataManager = dataManager,
                onSuccess = {
                    navController.popBackStack()
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.Profile.route) {
            ProfileScreen(
                apiService = apiService,
                dataManager = dataManager,
                onBack = {
                    navController.popBackStack()
                },
                onUpdateProfileClick = {
                    navController.navigate(Screen.UpdateProfile.route)
                },
                onSetLoginPin = {
                    navController.navigate(Screen.SetLoginPin.route)
                },
                onSetMpin = {
                    navController.navigate(Screen.SetMpin.route)
                },
                onNotificationsClick = {
                    navController.navigate(Screen.Notifications.route)
                },
                onLogout = {
                    scope.launch {
                        dataManager.clearData()
                        dataManager.clearSession(navController.context)
                        navController.navigate(Screen.Login.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                }
            )
        }
        composable(Screen.UpdateProfile.route) {
            UpdateProfileScreen(
                apiService = apiService,
                dataManager = dataManager,
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.Transfer.route) {
            TransferScreen(
                apiService = apiService,
                dataManager = dataManager,
                onBack = {
                    navController.popBackStack()
                },
                onAddNewBeneficiary = { type ->
                    if (type == "DECCAN") {
                        navController.navigate(Screen.AddSameBankBeneficiary.route)
                    } else {
                        navController.navigate(Screen.AddBeneficiary.route)
                    }
                },
                onPayoutSuccess = { response ->
                    val json = Gson().toJson(response)
                    navController.navigate(Screen.PayoutDetails.createRoute(java.net.URLEncoder.encode(json, "UTF-8")))
                }
            )
        }
        composable(
            route = Screen.PayoutDetails.route,
            arguments = listOf(navArgument("data") { type = NavType.StringType })
        ) { backStackEntry ->
            val json = backStackEntry.arguments?.getString("data")
            val response = Gson().fromJson(java.net.URLDecoder.decode(json ?: "", "UTF-8"), TransferPayoutResponse::class.java)
            
            val isFinalStatus = response.status == "SUCCESS" || response.status == "SUCCESSFUL" || response.status == "FAILED" || response.status == "FAILURE"
            val isHistory = response.message == "Transaction retrieved from history"

            if (isFinalStatus || isHistory || response.status == "PENDING") {
                PayoutTransactionDetailsScreen(
                    response = response,
                    dataManager = dataManager,
                    onBack = {
                        navController.navigate(Screen.Dashboard.route) {
                            popUpTo(Screen.Dashboard.route) { inclusive = true }
                        }
                    }
                )
            } else {
                PaymentProcessingScreen(
                    response = response,
                    onBack = {
                        navController.navigate(Screen.Dashboard.route) {
                            popUpTo(Screen.Dashboard.route) { inclusive = true }
                        }
                    }
                )
            }
        }
        composable(Screen.AddBeneficiary.route) {
            AddBeneficiaryScreen(
                apiService = apiService,
                ifscService = ifscService,
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.AddSameBankBeneficiary.route) {
            AddSameBankBeneficiaryScreen(
                apiService = apiService,
                onBack = {
                    navController.popBackStack()
                },
                onSuccess = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.AccountDetails.route) {
            AccountDetailsScreen(
                apiService = apiService,
                dataManager = dataManager,
                onSetLoginPin = {
                    navController.navigate(Screen.SetLoginPin.route)
                },
                onTransferClick = {
                    navController.navigate(Screen.Transfer.route)
                },
                onReceiveClick = {
                    navController.navigate(Screen.ReceiveMoney.route)
                },
                onSettingsClick = {
                    navController.navigate(Screen.Settings.route)
                },
                onRequestStatement = {
                    navController.navigate(Screen.RequestStatement.route)
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.ReceiveMoney.route) {
            ReceiveMoneyScreen(
                dataManager = dataManager,
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.Settings.route) {
            SettingsScreen(
                apiService = apiService,
                dataManager = dataManager,
                onBack = {
                    navController.popBackStack()
                },
                onSetLoginPin = {
                    navController.navigate(Screen.SetLoginPin.route)
                },
                onSetMpin = {
                    navController.navigate(Screen.SetMpin.route)
                },
                onRequestStatement = {
                    navController.navigate(Screen.RequestStatement.route)
                },
                onLogout = {
                    scope.launch {
                        dataManager.clearData()
                        dataManager.clearSession(navController.context)
                        navController.navigate(Screen.Login.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                }
            )
        }
        composable(Screen.SetLoginPin.route) {
            SetLoginPinScreen(
                apiService = apiService,
                dataManager = dataManager,
                onSuccess = {
                    navController.popBackStack()
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.PinLogin.route) {
            PinLoginScreen(
                apiService = apiService,
                dataManager = dataManager,
                onLoginSuccess = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.PinLogin.route) { inclusive = true }
                    }
                },
                onForgotPin = {
                    // Handle forgot pin - maybe logout or verify identity
                }
            )
        }
        composable(Screen.Beneficiaries.route) {
            BeneficiaryListScreen(
                apiService = apiService,
                onBack = {
                    navController.popBackStack()
                },
                onAddOtherBank = {
                    navController.navigate(Screen.AddBeneficiary.route)
                },
                onAddSameBank = {
                    navController.navigate(Screen.AddSameBankBeneficiary.route)
                }
            )
        }
        composable(Screen.Notifications.route) {
            NotificationsScreen(
                apiService = apiService,
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(Screen.Passbook.route) {
            PassbookScreen(
                apiService = apiService,
                onBack = {
                    navController.popBackStack()
                },
                onAccountDetailsClick = {
                    navController.navigate(Screen.AccountDetails.route)
                },
                onTransactionClick = { response ->
                    val json = Gson().toJson(response)
                    navController.navigate(Screen.PayoutDetails.createRoute(java.net.URLEncoder.encode(json, "UTF-8")))
                }
            )
        }
        composable(Screen.Baking.route) {
            BakingScreen(onBack = { navController.popBackStack() })
        }
        composable(Screen.LoanService.route) {
            LoanServiceUnavailableScreen(onBack = { navController.popBackStack() })
        }
        composable(Screen.RequestStatement.route) {
            RequestStatementScreen(
                apiService = apiService,
                onBack = { navController.popBackStack() }
            )
        }
    }
}
