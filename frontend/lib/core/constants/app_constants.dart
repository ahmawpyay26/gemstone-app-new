class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://gemstone-backendkst.onrender.com/api';
  static const String apiTimeout = '30';
  
  // API Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefreshToken = '/auth/refresh-token';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  
  // Storage Keys
  static const String storageKeyAccessToken = 'access_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUser = 'user_data';
  static const String storageKeyUserRole = 'user_role';
  
  // App Configuration
  static const String appName = 'Gemstone Management';
  static const String appVersion = '1.0.0';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  
  // Pagination
  static const int pageSize = 20;
  
  // Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}

class AppMessages {
  // Success Messages
  static const String registerSuccess = 'အသုံးပြုသူ အကောင်းအကျ စာရင်းသွင်းပြီးပါပြီ';
  static const String loginSuccess = 'အောင်မြင်စွာ ဝင်ရောက်ပြီးပါပြီ';
  static const String logoutSuccess = 'အောင်မြင်စွာ ထွက်ခွာပြီးပါပြီ';
  
  // Error Messages
  static const String networkError = 'အင်တာနက်ချိတ်ဆက်မှု ပွင့်လင်းမရှိပါ';
  static const String serverError = 'Server မှ အမှားတစ်ခု ဖြစ်ပေါ်ခဲ့ပါသည်';
  static const String invalidEmail = 'အီမေးလ်လိပ်စာ မှားယွင်းနေပါသည်';
  static const String weakPassword = 'စကားဝှက် အားနည်းနေပါသည်';
  static const String userNotFound = 'အသုံးပြုသူ မတွေ့ရှိပါ';
  static const String invalidCredentials = 'အီမေးလ် သို့မဟုတ် စကားဝှက် မှားယွင်းနေပါသည်';
  
  // Validation Messages
  static const String emailRequired = 'အီမေးလ်လိပ်စာ လိုအပ်ပါသည်';
  static const String passwordRequired = 'စကားဝှက် လိုအပ်ပါသည်';
  static const String firstNameRequired = 'အမည် (ကျောင်း) လိုအပ်ပါသည်';
  static const String lastNameRequired = 'အမည် (မိသားစု) လိုအပ်ပါသည်';
}

class AppDurations {
  static const Duration shortDuration = Duration(milliseconds: 300);
  static const Duration mediumDuration = Duration(milliseconds: 500);
  static const Duration longDuration = Duration(milliseconds: 1000);
}
