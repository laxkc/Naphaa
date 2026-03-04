// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get dashboard => 'ड्यासबोर्ड';

  @override
  String get sales => 'बिक्री';

  @override
  String get products => 'सामान';

  @override
  String get customers => 'ग्राहक';

  @override
  String get expenses => 'खर्च';

  @override
  String get settings => 'सेटिङ';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get reportsQuickStatTodaySales => 'आजको बिक्री';

  @override
  String get reportsQuickStatPendingCredit => 'बाँकी उधारो';

  @override
  String get reportsBusinessHealthSubtitle => 'नाफा, उधारो जोखिम, स्टक स्वास्थ्य, अलर्ट';

  @override
  String get reportsSalesReportTitle => 'बिक्री रिपोर्ट';

  @override
  String get reportsSalesReportSubtitle => 'अवधिअनुसार आम्दानी र कारोबार';

  @override
  String get salesReportTotalRevenue => 'कुल आम्दानी';

  @override
  String salesReportTransactionCount(int count) {
    return '$count कारोबार';
  }

  @override
  String get salesReportBreakdownByType => 'प्रकार अनुसार विवरण';

  @override
  String get salesReportCashSales => 'नगद बिक्री';

  @override
  String get salesReportCreditSales => 'उधारो बिक्री';

  @override
  String get reportsProfitReportTitle => 'नाफा रिपोर्ट';

  @override
  String get reportsProfitReportSubtitle => 'कुल र खुद नाफा विवरण';

  @override
  String get profitReportNetProfit => 'खुद नाफा';

  @override
  String get profitReportBreakdown => 'विवरण';

  @override
  String get profitReportEstimatedGrossProfit30 => 'अनुमानित कुल नाफा (३०%)';

  @override
  String get profitReportTotalExpenses => 'कुल खर्च';

  @override
  String get profitReportEstimatedNotice => 'कुल नाफा अनुमानित हो। सही मार्जिनका लागि सामानको लागत मूल्य राख्नुहोस्।';

  @override
  String get reportsCreditReportTitle => 'उधारो रिपोर्ट';

  @override
  String get reportsCreditReportSubtitle => 'ग्राहकहरूको बाँकी उधारो';

  @override
  String get creditReportNoOutstandingTitle => 'कुनै बाँकी उधारो छैन';

  @override
  String get creditReportNoOutstandingSubtitle => 'सबै ग्राहकको हिसाब मिलेको छ';

  @override
  String get creditReportTotalOutstanding => 'कुल बाँकी उधारो';

  @override
  String creditReportCustomerCount(int count) {
    return '$count ग्राहक';
  }

  @override
  String creditReportRiskBadge(String label) {
    return '$label जोखिम';
  }

  @override
  String get reportsCreditAgingSubtitle => 'उमेर समूह र जोखिम अनुसार बाँकी उधारो';

  @override
  String get reportsAlertsFeedTitle => 'अलर्ट फिड';

  @override
  String get reportsAlertsFeedSubtitle => 'कार्यात्मक जोखिम र व्यवसायिक अलर्टहरू';

  @override
  String get reportsProductInsightsTitle => 'वस्तु अन्तर्दृष्टि';

  @override
  String get reportsProductInsightsSubtitle => 'वस्तु अनुसार नाफा र नचल्ने स्टक';

  @override
  String get productInsightsDeadStockOnly => 'नचल्ने स्टक मात्र';

  @override
  String get productInsightsNoDataTitle => 'अहिलेसम्म वस्तु मेट्रिक्स छैन';

  @override
  String get productInsightsNoDataSubtitle => 'वस्तु अन्तर्दृष्टि हेर्न बिक्री र सिङ्क गर्नुहोस्';

  @override
  String get productInsightsCachedDataBanner => 'क्यास गरिएको वस्तु अन्तर्दृष्टि देखाइँदैछ (अफलाइन)। इन्टरनेट आएपछि रिफ्रेस गर्नुहोस्।';

  @override
  String get productInsightsDeadStockItemsLabel => 'नचल्ने स्टक';

  @override
  String get productInsightsLockedValueLabel => 'अड्किएको मूल्य';

  @override
  String get productInsightsProfitNote => 'नाफा अनुमानित हो (बिक्री मूल्य - लागत मूल्य) x बिक्री मात्रा। यसमा व्यवसायिक खर्च बाँडेर घटाइएको छैन। लागत मूल्य नभएका वस्तु नाफा सूचीमा समावेश हुँदैनन्।';

  @override
  String get productInsightsTopProfitProductsTitle => 'उच्च नाफा वस्तु';

  @override
  String get productInsightsProfitLabel => 'नाफा';

  @override
  String get productInsightsFastMovers7dTitle => 'छिटो बिक्ने वस्तु (७ दिन)';

  @override
  String get productInsightsQtySold7dLabel => '७ दिनको बिक्री मात्रा';

  @override
  String get productInsightsDeadStockTitle => 'नचल्ने स्टक';

  @override
  String get productInsightsNoSalesYet => 'अहिलेसम्म बिक्री छैन';

  @override
  String get productInsightsLastSaleLabel => 'अन्तिम बिक्री';

  @override
  String get productInsightsCostNotSet => 'लागत सेट छैन';

  @override
  String get productInsightsValueLabel => 'मूल्य';

  @override
  String get reportsInvoicesSubtitle => 'इनभ्वाइस बनाउनुहोस्, जारी गर्नुहोस् र भुक्तानी लिनुहोस्';

  @override
  String get reportsLedgerTitle => 'लेजर';

  @override
  String get reportsLedgerSubtitle => 'एकीकृत वित्तीय अडिट ट्रेल';

  @override
  String get ledgerNoEntriesTitle => 'लेजर प्रविष्टि छैन';

  @override
  String get ledgerNoEntriesSubtitle => 'बिक्री, खर्च, भुक्तानी र फिर्ता रकम यहाँ देखिनेछन्।';

  @override
  String get appName => 'Naphaa';

  @override
  String get newSale => 'नयाँ बिक्री';

  @override
  String get searchProducts => 'सामान खोज्नुहोस्';

  @override
  String get saveCashSale => 'नगद बिक्री सेभ';

  @override
  String get saveCreditSale => 'उधारो बिक्री सेभ';

  @override
  String get todaySales => 'आजको बिक्री';

  @override
  String get estimatedProfit => 'अनुमानित नाफा';

  @override
  String get creditOutstanding => 'उधारो बाँकी';

  @override
  String get language => 'भाषा';

  @override
  String get languageSelectionTitle => 'आफ्नो भाषा छान्नुहोस्';

  @override
  String get languageSelectionSubtitle => 'आफूलाई सहज लाग्ने भाषाबाट सुरु गर्नुहोस्। पछि सेटिङबाट परिवर्तन गर्न सकिन्छ।';

  @override
  String get expensesFeatureComingSoon => 'खर्च प्रविष्टि स्क्रिन चाँडै';

  @override
  String get inject100Records => '१०० यथार्थपरक डेटा हाल्नुहोस्';

  @override
  String get injectedDemoData => '१०० वटा परीक्षण डेटा हालियो';

  @override
  String get manageProducts => 'सामान व्यवस्थापन';

  @override
  String get manageCustomers => 'ग्राहक व्यवस्थापन';

  @override
  String get trackExpenses => 'खर्च ट्रयाक';

  @override
  String get addProduct => 'सामान थप्नुहोस्';

  @override
  String get addCustomer => 'ग्राहक थप्नुहोस्';

  @override
  String get addExpense => 'खर्च थप्नुहोस्';

  @override
  String get productName => 'सामानको नाम';

  @override
  String get customerName => 'ग्राहकको नाम';

  @override
  String get businessLabel => 'व्यवसाय';

  @override
  String get phone => 'फोन';

  @override
  String get emailLabel => 'इमेल';

  @override
  String get panVatLabel => 'PAN/VAT';

  @override
  String get price => 'मूल्य';

  @override
  String get stock => 'स्टक';

  @override
  String get amount => 'रकम';

  @override
  String get note => 'टिप्पणी';

  @override
  String get dateLabel => 'मिति';

  @override
  String get save => 'सेभ';

  @override
  String get saveChanges => 'परिवर्तन सेभ गर्नुहोस्';

  @override
  String get cancel => 'रद्द';

  @override
  String get continueLabel => 'जारी राख्नुहोस्';

  @override
  String get createLabel => 'सिर्जना गर्नुहोस्';

  @override
  String get deleteLabel => 'मेटाउनुहोस्';

  @override
  String get dashboardOverview => 'ड्यासबोर्ड सारांश';

  @override
  String get dashboardFirstRunTitle => 'Naphaa मा स्वागत छ';

  @override
  String get dashboardFirstRunSubtitle => 'तपाईंको पसल तयार छ। तलका सर्टकटबाट सामान थप्नुहोस्, बिक्री रेकर्ड गर्नुहोस्, र व्यवसाय विवरण सेटअप गर्नुहोस्।';

  @override
  String get dashboardLowStockEmptyNoProducts => 'पहिले सामान थप्नुहोस्। इन्भेन्टरी बनेपछि मात्र लो-स्टक ट्र्याकिङ सुरु हुन्छ।';

  @override
  String get failedToLoadDashboard => 'ड्यासबोर्ड लोड गर्न सकिएन';

  @override
  String get loadingLabel => 'लोड हुँदैछ';

  @override
  String get errorLabel => 'त्रुटि';

  @override
  String get criticalLabel => 'गम्भीर';

  @override
  String get warningLabel => 'चेतावनी';

  @override
  String get clearLabel => 'सफा';

  @override
  String get unknownLabel => 'अज्ञात';

  @override
  String get alertsLabel => 'सूचनाहरू';

  @override
  String get openLabel => 'खोल्नुहोस्';

  @override
  String get alertsFeedMarkAllRead => 'सबै पढियो चिन्ह लगाउनुहोस्';

  @override
  String get alertsFeedMarkRead => 'पढियो';

  @override
  String get alertsFeedEverythingStableSubtitle => 'अहिले सबै ठीक देखिन्छ';

  @override
  String get alertsActionUnavailable => 'यो अलर्टको कार्य अहिले उपलब्ध छैन';

  @override
  String alertCount(int count) {
    return '$count सूचना';
  }

  @override
  String alertsCountWithStatus(int count, String status) {
    return '$count सूचना ($status)';
  }

  @override
  String get lowStockItemsTitle => 'कम स्टक वस्तुहरू';

  @override
  String get checkingStock => 'स्टक जाँच्दै...';

  @override
  String get unableLoadLowStockData => 'कम स्टक डेटा लोड गर्न सकिएन';

  @override
  String get allProductsAboveThreshold => 'सबै सामानहरू थ्रेसहोल्डभन्दा माथि छन्।';

  @override
  String stockLeftCount(String count) {
    return '$count बाँकी';
  }

  @override
  String get quickActionsTitle => 'छिटो कार्यहरू';

  @override
  String get setupSectionTitle => 'सेटअप';

  @override
  String get setupPromptBusinessProfileTitle => 'व्यवसाय प्रोफाइल पूरा गर्नुहोस्';

  @override
  String get setupPromptBusinessProfileSubtitle => 'इनभ्वाइस र रिपोर्टहरू व्यावसायिक देखिन पसलको नाम, फोन र ठेगाना थप्नुहोस्।';

  @override
  String get setupPromptBusinessProfileAction => 'व्यवसाय सेटअप';

  @override
  String get setupPromptTaxSettingsTitle => 'कर सेटिङ सक्षम गर्नुहोस्';

  @override
  String get setupPromptTaxSettingsSubtitle => 'कर इनभ्वाइस जारी गर्नु अघि VAT खोल्नुहोस् र PAN/VAT विवरण सुरक्षित गर्नुहोस्।';

  @override
  String get setupPromptTaxSettingsAction => 'कर कन्फिगर गर्नुहोस्';

  @override
  String get setupPromptFirstProductTitle => 'पहिलो सामान थप्नुहोस्';

  @override
  String get setupPromptFirstProductSubtitle => 'बिक्री, स्टक र लो-स्टक अलर्ट सही चलाउन पहिले सामान सिर्जना गर्नुहोस्।';

  @override
  String get setupPromptFirstProductAction => 'सामान थप्नुहोस्';

  @override
  String get setupPromptFirstCustomerTitle => 'पहिलो ग्राहक थप्नुहोस्';

  @override
  String get setupPromptFirstCustomerSubtitle => 'उधारो बिक्री र असुली ट्र्याक गर्ने भए ग्राहक विवरण अहिले नै सुरक्षित गर्नुहोस्।';

  @override
  String get setupPromptFirstCustomerAction => 'ग्राहक थप्नुहोस्';

  @override
  String get setupPromptInvoicePrefixTitle => 'इनभ्वाइस प्रिफिक्स सेट गर्नुहोस्';

  @override
  String get setupPromptInvoicePrefixSubtitle => 'ग्राहकलाई बिल जारी गर्नु अघि इनभ्वाइस नम्बरिङ आफ्नै ढंगले सेट गर्नुहोस्।';

  @override
  String get setupPromptInvoicePrefixAction => 'इनभ्वाइस खोल्नुहोस्';

  @override
  String get recordPay => 'भुक्तानी रेकर्ड';

  @override
  String get businessHealth => 'व्यवसाय स्वास्थ्य';

  @override
  String get businessHealthCachedDataBanner => 'क्यास गरिएको विश्लेषण डेटा देखाइँदैछ (अफलाइन)। इन्टरनेट आएपछि रिफ्रेस गर्नुहोस्।';

  @override
  String get businessHealthProfitSnapshotTitle => 'नाफा झलक';

  @override
  String get businessHealthEstimatedProfitLabel => 'अनुमानित नाफा';

  @override
  String get businessHealthOutstandingCreditLabel => 'बाँकी उधारो';

  @override
  String get businessHealthProfitMarginLabel => 'नाफा मार्जिन';

  @override
  String get businessHealthCashRiskLabel => 'नगद जोखिम';

  @override
  String get businessHealthCashOutlookTitle => 'नगद पूर्वानुमान';

  @override
  String get businessHealthExpectedIncomingLabel => 'अपेक्षित आम्दानी';

  @override
  String get businessHealthExpectedOutgoingLabel => 'अपेक्षित खर्च';

  @override
  String businessHealthNetOutlookNextDays(int days, Object amount) {
    return 'अर्को $days दिनको खुद पूर्वानुमान: NPR $amount';
  }

  @override
  String get businessHealthProfitSnapshotNote => 'यहाँको अनुमानित नाफा सरल सञ्चालन झलक हो (आजको बिक्री - आजको खर्च)। वस्तु-स्तर नाफा रिपोर्टले लागत मूल्य प्रयोग गर्छ र यो कुलसँग ठ्याक्कै मिल्न नपर्न सक्छ।';

  @override
  String get businessHealthCreditRiskSummaryTitle => 'उधारो जोखिम सारांश';

  @override
  String get businessHealthStockHealthTitle => 'स्टक स्वास्थ्य';

  @override
  String get businessHealthFastMoversTitle => 'छिटो बिक्ने वस्तु';

  @override
  String get businessHealthAlertsPreviewTitle => 'अलर्ट झलक';

  @override
  String businessHealthDaysShort(int count) {
    return '$countदिन';
  }

  @override
  String get businessHealthNoLowStockAlerts => 'अहिले कम स्टक अलर्ट छैन';

  @override
  String businessHealthLowStockItemsCount(int count) {
    return '$count कम-स्टक वस्तु';
  }

  @override
  String get businessHealthNoActiveAlerts => 'कुनै सक्रिय अलर्ट छैन';

  @override
  String get businessHealthNoFastMovers7d => 'पछिल्लो ७ दिनमा छिटो बिक्ने वस्तु छैन';

  @override
  String get businessHealthSevenDayQtySoldLabel => '७ दिनमा बिक्री मात्रा';

  @override
  String get thresholdLabel => 'सीमा';

  @override
  String get revenueLabel => 'आम्दानी';

  @override
  String get customerLabel => 'ग्राहक';

  @override
  String get creditAging => 'उधारो उमेर';

  @override
  String get creditAgingOverdueOnly => 'समय नाघेको मात्र';

  @override
  String get creditAgingHighRiskOnly => 'उच्च जोखिम मात्र';

  @override
  String get creditAgingNoDataTitle => 'उधारो उमेर डेटा छैन';

  @override
  String get creditAgingNoDataSubtitle => 'छनोट गरिएका फिल्टरमा कुनै ग्राहक छैन';

  @override
  String get creditAgingCachedDataBanner => 'क्यास गरिएको उधारो उमेर डेटा देखाइँदैछ (अफलाइन)। इन्टरनेट आएपछि रिफ्रेस गर्नुहोस्।';

  @override
  String get creditAgingSummaryTitle => 'उधारो उमेर सारांश';

  @override
  String get creditAgingOutstandingLabel => 'कुल बाँकी';

  @override
  String get creditAgingOverdueLabel => 'समय नाघेको';

  @override
  String creditAgingHighRiskCustomersCount(int count) {
    return '$count उच्च जोखिम ग्राहक';
  }

  @override
  String get creditAgingBucketsTitle => 'उमेर समूह';

  @override
  String get creditAgingBucket0to7 => '0–7 दिन';

  @override
  String get creditAgingBucket8to30 => '8–30 दिन';

  @override
  String get creditAgingBucket31to60 => '31–60 दिन';

  @override
  String get creditAgingBucket60Plus => '60+ दिन';

  @override
  String get creditAgingOldestDueLabel => 'सबैभन्दा पुरानो बाँकी';

  @override
  String creditAgingDaysCount(int count) {
    return '$count दिन';
  }

  @override
  String get invoices => 'इनभ्वाइसहरू';

  @override
  String get invoiceLabel => 'इनभ्वाइस';

  @override
  String get invoicePdfTitle => 'बिल';

  @override
  String get draftLabel => 'ड्राफ्ट';

  @override
  String get invoiceDueShortLabel => 'बुझाउने मिति';

  @override
  String get invoiceListNewInvoice => 'नयाँ इनभ्वाइस';

  @override
  String get invoiceListNoInvoicesTitle => 'अहिलेसम्म इनभ्वाइस छैन';

  @override
  String get invoiceListNoInvoicesSubtitle => 'पहिलो इनभ्वाइस बनाउनुहोस् र अफलाइनमै जारी गर्नुहोस्।';

  @override
  String get invoiceListCreateInvoiceAction => 'इनभ्वाइस बनाउनुहोस्';

  @override
  String get invoiceListDraftFallback => 'ड्राफ्ट';

  @override
  String get invoiceListDraftNotIssued => 'ड्राफ्ट (जारी गरिएको छैन)';

  @override
  String invoiceListTotalsSummary(Object total, Object balance) {
    return 'कुल: NPR $total   •   बाकी: NPR $balance';
  }

  @override
  String get netAfterExpenses => 'खर्चपछि बाँकी';

  @override
  String get cashflowHealth => 'नगद प्रवाह अवस्था';

  @override
  String get creditExposure => 'उधारो जोखिम';

  @override
  String get healthy => 'स्वस्थ';

  @override
  String get watchlist => 'ध्यान दिनुहोस्';

  @override
  String get risky => 'जोखिमपूर्ण';

  @override
  String get authTitle => 'Naphaa मा साइन इन गर्नुहोस्';

  @override
  String get login => 'लगइन';

  @override
  String get signup => 'साइन अप';

  @override
  String get password => 'पासवर्ड';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get logout => 'लगआउट';

  @override
  String get store => 'पसल';

  @override
  String get welcomeBack => 'फेरि स्वागत छ';

  @override
  String get signInToContinue => 'जारी राख्न साइन इन गर्नुहोस्';

  @override
  String get forgotPassword => 'पासवर्ड बिर्सनुभयो?';

  @override
  String get noAccount => 'खाता छैन?';

  @override
  String get haveAccount => 'पहिले नै खाता छ?';

  @override
  String get createAccount => 'खाता बनाउनुहोस्';

  @override
  String get startManagingYourBusiness => 'आज आफ्नो व्यापार व्यवस्थापन सुरु गर्नुहोस्';

  @override
  String get businessName => 'व्यापारको नाम';

  @override
  String get businessNameHint => 'जस्तै: मेरो पसल, सनराइज स्टोर';

  @override
  String get passwordHint => 'कम्तिमा ८ अक्षर';

  @override
  String get passwordMinLength => 'पासवर्ड कम्तिमा ८ अक्षर हुनुपर्छ';

  @override
  String get businessNameTooShort => 'व्यापारको नाम कम्तिमा ३ अक्षर हुनुपर्छ';

  @override
  String get invalidPhone => 'मान्य १०-अङ्कको फोन नम्बर लेख्नुहोस्';

  @override
  String get fieldRequired => 'यो फिल्ड आवश्यक छ';

  @override
  String get back => 'पछाडि';

  @override
  String get signIn => 'साइन इन';

  @override
  String get switchToSignup => 'साइन अपमा जानुहोस्';

  @override
  String get switchToLogin => 'लगइनमा जानुहोस्';

  @override
  String get forgotPasswordHint => 'पासवर्ड रिसेटका लागि सहयोग टोलीलाई सम्पर्क गर्नुहोस्।';

  @override
  String get authOtpTitle => 'फोन नम्बरबाट सुरु गर्नुहोस्';

  @override
  String get authOtpSubtitle => 'आफ्नो मोबाइल नम्बर लेख्नुहोस्। साइन इन गर्न वा खाता स्वतः बनाउन एकपटक प्रयोग हुने कोड पठाइन्छ।';

  @override
  String get authSendOtp => 'OTP पठाउनुहोस्';

  @override
  String get authVerifyOtpTitle => 'OTP प्रमाणित गर्नुहोस्';

  @override
  String get authOtpCodeLabel => 'एकपटक प्रयोग हुने कोड';

  @override
  String get authVerifyOtp => 'प्रमाणित गरेर अघि बढ्नुहोस्';

  @override
  String get authResendOtp => 'OTP फेरि पठाउनुहोस्';

  @override
  String get authChangePhone => 'फोन नम्बर बदल्नुहोस्';

  @override
  String get authOtpInvalidCode => 'मान्य कोड लेख्नुहोस्';

  @override
  String get authOtpAutoCreateBody => 'नयाँ फोन नम्बरले डिफल्ट व्यवसाय सेटिङसहित खाता स्वतः बनाउँछ। पहिलेको नम्बरले सिधै साइन इन गर्छ।';

  @override
  String authOtpSentTo(Object phone) {
    return '$phone मा कोड पठाइएको छ';
  }

  @override
  String authOtpDebugCode(Object code) {
    return 'डिबग OTP: $code';
  }

  @override
  String get offlineMode => 'अफलाइन मोड';

  @override
  String get syncingShort => 'सिंक हुँदै…';

  @override
  String syncingChanges(int count) {
    return '$count परिवर्तन सिंक हुँदै…';
  }

  @override
  String get todayLabel => 'आज';

  @override
  String get yearLabel => 'वर्ष';

  @override
  String get monthLabel => 'महिना';

  @override
  String get dayLabel => 'दिन';

  @override
  String get invoicePickBsDateTitle => 'BS मिति लेख्नुहोस्';

  @override
  String get invalidBsDate => 'मान्य BS मिति लेख्नुहोस्';

  @override
  String get thisWeekLabel => 'यो हप्ता';

  @override
  String get thisMonthLabel => 'यो महिना';

  @override
  String get allLabel => 'सबै';

  @override
  String get walkInCustomer => 'वाक-इन ग्राहक';

  @override
  String get nprLabel => 'NPR';

  @override
  String get itemsLabel => 'वस्तुहरू';

  @override
  String get paymentsLabel => 'भुक्तानीहरू';

  @override
  String get totalLabel => 'कुल जम्मा';

  @override
  String get totalAmountLabel => 'कुल रकम';

  @override
  String get saleDetailsTitle => 'बिक्री विवरण';

  @override
  String get saleNotFoundTitle => 'बिक्री फेला परेन';

  @override
  String get saleNotFoundSubtitle => 'यो बिक्री हटाइएको हुन सक्छ';

  @override
  String get salesNoSalesYetTitle => 'अहिलेसम्म बिक्री छैन';

  @override
  String get salesNoSalesYetTodaySubtitle => 'आजको पहिलो बिक्री रेकर्ड गर्न + थिच्नुहोस्';

  @override
  String get salesNoTransactionsInPeriodSubtitle => 'यो अवधिमा कुनै कारोबार छैन';

  @override
  String get salesNoProductsYetTitle => 'अहिलेसम्म सामान छैन';

  @override
  String get salesNoProductsQuickCreateHint => 'सामानको नाम खोजेर यहींबाट छिटो सिर्जना गर्नुहोस्।';

  @override
  String salesNoMatchForQuery(Object query) {
    return '\"$query\" फेला परेन';
  }

  @override
  String get salesCreateProductQuicklyCta => 'सामान छिट्टै सिर्जना गर्नुहोस्';

  @override
  String salesCreateProductQuicklyFor(Object query) {
    return '\"$query\" छिट्टै सिर्जना गर्नुहोस्';
  }

  @override
  String get salesCreateProductQuicklySubtitle => 'बिक्री मूल्य मात्र हालेर बिक्री जारी राख्नुहोस्';

  @override
  String get salesQuickAddProductTitle => 'छिटो सामान थप्नुहोस्';

  @override
  String get salesQuickCreditCustomerTitle => 'छिटो उधारो ग्राहक';

  @override
  String get salesCreditRiskWarningTitle => 'उधारो जोखिम चेतावनी';

  @override
  String salesCreditRiskExistingCustomerMarked(Object name, Object label) {
    return 'अहिलेको ग्राहक \"$name\" लाई $label चिन्ह लगाइएको छ।';
  }

  @override
  String salesCreditRiskOutstandingNpr(Object amount) {
    return 'बाँकी: NPR $amount';
  }

  @override
  String salesCreditRiskOldestDueDays(int count) {
    return 'सबैभन्दा पुरानो बक्यौता: $count दिन';
  }

  @override
  String salesCreditRiskScore(Object score) {
    return 'जोखिम स्कोर: $score';
  }

  @override
  String get salesCreditRiskContinueWarning => 'थप उधारो दिन सहज लागेमा मात्र जारी राख्नुहोस्।';

  @override
  String salesCartItemsCount(int count) {
    return '$count वस्तु';
  }

  @override
  String get searchCustomersHint => 'ग्राहक खोज्नुहोस्…';

  @override
  String get failedToLoadCustomers => 'ग्राहक लोड गर्न सकिएन';

  @override
  String get noCustomersFoundTitle => 'ग्राहक फेला परेन';

  @override
  String get customersEmptySubtitle => 'सुरु गर्न \"ग्राहक थप्नुहोस्\" थिच्नुहोस्।';

  @override
  String get customersTryDifferentSearchSubtitle => 'अर्को नाम वा फोन नम्बर प्रयास गर्नुहोस्।';

  @override
  String get deleteCustomerDialogTitle => 'ग्राहक मेटाउने?';

  @override
  String customerDeletePermanentBody(String name) {
    return '\"$name\" स्थायी रूपमा हटाइनेछ।';
  }

  @override
  String get owesYouLabel => 'तपाईंलाई तिर्न बाँकी';

  @override
  String get creditLabel => 'क्रेडिट';

  @override
  String get recordPaymentTooltip => 'भुक्तानी रेकर्ड';

  @override
  String get editCustomerTitle => 'ग्राहक सम्पादन';

  @override
  String get fullNameLabel => 'पूरा नाम';

  @override
  String get customerNameRequired => 'नाम आवश्यक छ';

  @override
  String get phoneOptionalLabel => 'फोन नम्बर (वैकल्पिक)';

  @override
  String get addressOptionalLabel => 'ठेगाना (वैकल्पिक)';

  @override
  String get streetCityHint => 'सडक, शहर';

  @override
  String get notesOptionalLabel => 'नोट (वैकल्पिक)';

  @override
  String get customerNotesHint => 'थप नोटहरू';

  @override
  String get customerSaveFailedTryAgain => 'ग्राहक सेभ गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get searchProductsHint => 'सामान खोज्नुहोस्…';

  @override
  String get failedToLoadProducts => 'सामान लोड गर्न सकिएन';

  @override
  String get productsEmptySubtitle => 'सुरु गर्न \"सामान थप्नुहोस्\" थिच्नुहोस्।';

  @override
  String get deleteProductDialogTitle => 'सामान मेटाउने?';

  @override
  String productDeletePermanentBody(String name) {
    return '\"$name\" स्थायी रूपमा हटाइनेछ।';
  }

  @override
  String get lowStockBadgeLabel => 'कम स्टक';

  @override
  String get rsLabel => 'रु';

  @override
  String get adjustStockLabel => 'स्टक मिलाउनुहोस्';

  @override
  String get editProductTitle => 'सामान सम्पादन';

  @override
  String get productNameLabel => 'सामानको नाम';

  @override
  String get productNameRequired => 'नाम आवश्यक छ';

  @override
  String get categoryOptionalLabel => 'श्रेणी (वैकल्पिक)';

  @override
  String get productCategoryHint => 'जस्तै स्न्याक्स, पेय पदार्थ';

  @override
  String get sellPriceLabel => 'बिक्री मूल्य';

  @override
  String get enterValidPrice => 'मान्य मूल्य लेख्नुहोस्';

  @override
  String get costPriceLabel => 'खरिद मूल्य';

  @override
  String get openingStockLabel => 'सुरुआती स्टक';

  @override
  String get lowStockThresholdLabel => 'कम स्टक सीमा';

  @override
  String get lowStockThresholdHint => 'अलर्ट बन्द गर्न ०';

  @override
  String get enterValidThreshold => 'मान्य सीमा लेख्नुहोस्';

  @override
  String get unitLabel => 'एकाइ';

  @override
  String get productSaveFailedTryAgain => 'सामान सेभ गर्न सकेन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get productDetailsTitle => 'सामान विवरण';

  @override
  String get productNotFoundTitle => 'सामान फेला परेन';

  @override
  String get productNotFoundSubtitle => 'यो सामान हटाइएको हुन सक्छ';

  @override
  String get marginLabel => 'मार्जिन';

  @override
  String get stockHistoryTitle => 'स्टक इतिहास';

  @override
  String get noStockMovementsYetTitle => 'अहिलेसम्म स्टक चलन छैन';

  @override
  String get customerDetailsTitle => 'ग्राहक विवरण';

  @override
  String get customerNotFoundTitle => 'ग्राहक फेला परेन';

  @override
  String get customerNotFoundSubtitle => 'यो ग्राहक हटाइएको हुन सक्छ';

  @override
  String get outstandingBalanceLabel => 'बाकी रकम';

  @override
  String get recordPaymentLabel => 'भुक्तानी रेकर्ड';

  @override
  String get transactionHistoryTitle => 'कारोबार इतिहास';

  @override
  String get loadingTransactions => 'कारोबार लोड हुँदैछ...';

  @override
  String get failedToLoadCustomerTransactions => 'ग्राहक कारोबार लोड गर्न सकिएन';

  @override
  String get noTransactionsYetTitle => 'अहिलेसम्म कारोबार छैन';

  @override
  String get paymentReceivedLabel => 'भुक्तानी प्राप्त';

  @override
  String get creditSaleLabel => 'उधार बिक्री';

  @override
  String get riskExplanationTitle => 'जोखिम व्याख्या';

  @override
  String get oldestOverdueLabel => 'सबैभन्दा पुरानो बक्यौता';

  @override
  String get averageDaysToPayLabel => 'औसत भुक्तानी दिन';

  @override
  String get onTimeRateLabel => 'समयमै भुक्तानी दर';

  @override
  String get outstandingSpikeLabel => 'बाकी रकम वृद्धि';

  @override
  String daysValue(int count) {
    return '$count दिन';
  }

  @override
  String daysValueDecimal(String value) {
    return '$value दिन';
  }

  @override
  String oldestDueChipDays(int days) {
    return 'सबैभन्दा पुरानो बक्यौता: $days दिन';
  }

  @override
  String get highLabel => 'उच्च';

  @override
  String get mediumLabel => 'मध्यम';

  @override
  String get lowLabel => 'कम';

  @override
  String get normalLabel => 'सामान्य';

  @override
  String get failedToLoadExpenses => 'खर्च लोड गर्न सकिएन';

  @override
  String get expensesEmptySubtitle => 'पहिलो खर्च रेकर्ड गर्न \"खर्च थप्नुहोस्\" थिच्नुहोस्।';

  @override
  String get expenseCategoryRent => 'भाडा';

  @override
  String get expenseCategoryTransport => 'यातायात';

  @override
  String get expenseCategoryUtilities => 'युटिलिटी';

  @override
  String get expenseCategorySalary => 'तलब';

  @override
  String get expenseCategoryOther => 'अन्य';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String failedToSaveWithError(String error) {
    return 'सेभ गर्न सकिएन: $error';
  }

  @override
  String get enterValidAmount => 'मान्य रकम लेख्नुहोस्';

  @override
  String get amountCannotExceedOutstandingBalance => 'रकम बाँकी उधारो भन्दा बढी हुन सक्दैन';

  @override
  String get paymentRecordedSuccessfully => 'भुक्तानी सफलतापूर्वक रेकर्ड भयो';

  @override
  String get failedToRecordPaymentTryAgain => 'भुक्तानी रेकर्ड गर्न सकेन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get creditCustomerLabel => 'उधारो ग्राहक';

  @override
  String get paymentDetailsTitle => 'भुक्तानी विवरण';

  @override
  String get amountReceivedLabel => 'प्राप्त रकम';

  @override
  String get fullLabel => 'पूरै';

  @override
  String get paymentMethodLabelTitle => 'भुक्तानी विधि';

  @override
  String get balanceLabel => 'बाकी';

  @override
  String get notesLabel => 'नोट';

  @override
  String get typeLabel => 'प्रकार';

  @override
  String get addStockLabel => 'स्टक थप्नुहोस्';

  @override
  String get removeStockLabel => 'स्टक घटाउनुहोस्';

  @override
  String get quantityLabel => 'परिमाण';

  @override
  String get egTenHint => 'जस्तै १०';

  @override
  String get reasonLabel => 'कारण';

  @override
  String get additionalDetailsHint => 'थप विवरण…';

  @override
  String get saveAdjustmentLabel => 'समायोजन सेभ गर्नुहोस्';

  @override
  String get enterValidQuantity => 'मान्य परिमाण लेख्नुहोस्';

  @override
  String get failedToAdjustStockTryAgain => 'स्टक समायोजन गर्न सकेन। फेरि प्रयास गर्नुहोस्।';

  @override
  String currentStockValue(String value) {
    return 'हालको स्टक: $value';
  }

  @override
  String get serverHasNewerDataPullRetry => 'सर्भरमा नयाँ डाटा छ। नयाँ डाटा तानेर फेरि प्रयास गर्नुहोस्।';

  @override
  String get syncFailedWillRetry => 'सिंक असफल भयो। फेरि प्रयास हुनेछ।';

  @override
  String pendingChangesCount(int count) {
    return '$count परिवर्तन बाँकी';
  }

  @override
  String get pullRetryShort => 'तान्नुहोस्+फेरि';

  @override
  String get syncNowLabel => 'अहिले सिंक';

  @override
  String get syncDiagnosticsTitle => 'सिंक डायग्नोस्टिक्स';

  @override
  String get clearFailedRowsTooltip => 'असफल पंक्ति हटाउनुहोस्';

  @override
  String get clearFailedRowsConfirmTitle => 'असफल सिंक पंक्तिहरू हटाउने?';

  @override
  String get clearFailedRowsConfirmBody => 'यो डेमो/परीक्षण सफाइका लागि हो। असफल अफलाइन परिवर्तनहरू स्थानीय सिंक क्यूबाट हटाइनेछन्।';

  @override
  String get clearFailedAction => 'असफल हटाउनुहोस्';

  @override
  String clearedFailedRowsCount(int count) {
    return '$count असफल सिंक पंक्ति हटाइयो';
  }

  @override
  String get retrySyncTooltip => 'फेरि सिंक';

  @override
  String get refreshLabel => 'रिफ्रेस';

  @override
  String get pendingLabel => 'बाँकी';

  @override
  String get ackedLabel => 'स्वीकृत';

  @override
  String get failedLabel => 'असफल';

  @override
  String syncDiagnosticsFailedRowsBanner(int count) {
    return '$count सिंक पंक्ति असफल भए। फेरि सिंक गर्नुहोस् वा विवरणका लागि पंक्ति खोल्नुहोस्।';
  }

  @override
  String syncDiagnosticsInvalidRowsBanner(int count) {
    return '$count अफलाइन परिवर्तन अवैध छन् र सिंक हुन सकेनन्।';
  }

  @override
  String get noSyncQueueItemsTitle => 'सिंक क्यू खाली छ';

  @override
  String get noSyncQueueItemsSubtitle => 'अफलाइन परिवर्तन र सिंक त्रुटिहरू यहाँ देखिनेछन्।';

  @override
  String retryCountShort(int count) {
    return 'पुन:प्रयास $count';
  }

  @override
  String get statusLabel => 'स्थिति';

  @override
  String get entityIdLabel => 'इकाइ ID';

  @override
  String get opIdLabel => 'अपरेशन ID';

  @override
  String get retriesLabel => 'पुन:प्रयास';

  @override
  String get createdLabel => 'सिर्जना';

  @override
  String get updatedLabel => 'अपडेट';

  @override
  String get lastErrorLabel => 'अन्तिम त्रुटि';

  @override
  String get copiedErrorDetails => 'त्रुटि विवरण कपी गरियो';

  @override
  String get copyLabel => 'कपी';

  @override
  String get retry => 'फेरि प्रयास';

  @override
  String get somethingWentWrong => 'केही समस्या भयो';

  @override
  String get itemLabel => 'सामान';

  @override
  String get termsLabel => 'शर्तहरू';

  @override
  String get pdfGenerationFailedPrefix => 'PDF बनाउन असफल';

  @override
  String syncTelemetrySummary(int acked, int failed, int pulled, int durationMs) {
    return 'स्वीकृत $acked • असफल $failed • तानिएको $pulled • ${durationMs}ms';
  }

  @override
  String get invoiceDetailTitle => 'इनभ्वाइस विवरण';

  @override
  String get invoiceDetailNotFound => 'इनभ्वाइस भेटिएन';

  @override
  String get invoiceDetailDraftFallback => 'ड्राफ्ट इनभ्वाइस';

  @override
  String get invoiceIssueDateLabel => 'जारी मिति';

  @override
  String get invoiceNotIssued => 'जारी गरिएको छैन';

  @override
  String get invoiceDueDateLabel => 'बुझाउने मिति';

  @override
  String get subtotalLabel => 'जम्मा';

  @override
  String get discountLabel => 'छुट';

  @override
  String get vatLabel => 'भ्याट';

  @override
  String get paidLabel => 'तिरेको';

  @override
  String get invoiceDetailNoItems => 'कुनै सामान छैन';

  @override
  String get invoicePaymentsTitle => 'भुक्तानीहरू';

  @override
  String get invoicePaymentsEmpty => 'भुक्तानी रेकर्ड छैन';

  @override
  String get actionsLabel => 'कार्यहरू';

  @override
  String get issueLabel => 'जारी गर्नुहोस्';

  @override
  String get invoiceRecordPaymentLabel => 'भुक्तानी रेकर्ड';

  @override
  String get invoicePdfRetry => 'PDF पुन: प्रयास';

  @override
  String get invoicePdfRegenerate => 'PDF पुन: बनाउनुहोस्';

  @override
  String get invoicePdfGenerate => 'PDF बनाउनुहोस्';

  @override
  String get invoicePdfShare => 'PDF सेयर';

  @override
  String get printLabel => 'प्रिन्ट';

  @override
  String get invoiceIssuedSuccess => 'इनभ्वाइस सफलतापूर्वक जारी भयो';

  @override
  String get invoicePdfGeneratedSuccess => 'PDF सफलतापूर्वक बन्यो';

  @override
  String invoiceBalanceSummary(String value) {
    return 'बाकी: $value';
  }

  @override
  String get noteOptionalLabel => 'नोट (वैकल्पिक)';

  @override
  String get invoiceEnterValidAmount => 'सही रकम हाल्नुहोस्';

  @override
  String get invoicePaymentRecordedSuccess => 'भुक्तानी रेकर्ड भयो';

  @override
  String get invoiceCreateTitle => 'इनभ्वाइस बनाउनुहोस्';

  @override
  String get invoiceDetailsTitle => 'इनभ्वाइस विवरण';

  @override
  String get invoiceCustomerIdOptional => 'ग्राहक ID (वैकल्पिक)';

  @override
  String get invoiceDiscountLabel => 'इनभ्वाइस छुट';

  @override
  String get invoiceAddLine => 'लाइन थप्नुहोस्';

  @override
  String get invoiceSaveDraft => 'ड्राफ्ट सेभ';

  @override
  String get invoiceIssuing => 'जारी गर्दै...';

  @override
  String get invoiceIssueAction => 'इनभ्वाइस जारी गर्नुहोस्';

  @override
  String get invoiceNoActiveStore => 'सक्रिय व्यवसाय/स्टोर भेटिएन। फेरि लगइन गर्नुहोस्।';

  @override
  String get invoiceAddAtLeastOneItem => 'कम्तीमा एक सामान थप्नुहोस्';

  @override
  String get invoiceLineItemName => 'सामानको नाम';

  @override
  String get requiredLabel => 'अनिवार्य';

  @override
  String get invoiceProductIdOptional => 'उत्पादन ID (वैकल्पिक)';

  @override
  String get qtyLabel => 'परिमाण';

  @override
  String get invoiceQtyPositive => 'परिमाण ० भन्दा बढी';

  @override
  String get rateLabel => 'दर';

  @override
  String get invalidLabel => 'अमान्य';

  @override
  String get settingsSectionBusiness => 'व्यवसाय';

  @override
  String get businessSettings => 'व्यवसाय सेटिङ';

  @override
  String get billingSettingsTitle => 'बिलिङ सेटिङ';

  @override
  String get billingSettingsSubtitle => 'इनभ्वाइस प्रिफिक्स, भाषा, कर मोड, र पूर्वनिर्धारित टिप्पणीहरू';

  @override
  String get settingsBillingSettingsSubtitle => 'इनभ्वाइस प्रिफिक्स, सर्त, फुटर';

  @override
  String get billingSettingsInvoicePrefixLabel => 'इनभ्वाइस प्रिफिक्स';

  @override
  String get billingSettingsInvoicePrefixRequired => 'इनभ्वाइस प्रिफिक्स आवश्यक छ';

  @override
  String get billingSettingsTaxModeLabel => 'कर मोड';

  @override
  String get billingSettingsTaxModeExclusive => 'कर छुट्टै';

  @override
  String get billingSettingsTaxModeInclusive => 'कर समावेश';

  @override
  String get billingSettingsTermsDefaultLabel => 'पूर्वनिर्धारित सर्तहरू';

  @override
  String get billingSettingsTermsDefaultHint => 'भुक्तानी ७ दिनभित्र गर्नुहोस्';

  @override
  String get billingSettingsFooterDefaultLabel => 'पूर्वनिर्धारित फुटर';

  @override
  String get billingSettingsFooterDefaultHint => 'तपाईंको व्यापारका लागि धन्यवाद';

  @override
  String get billingSettingsSaved => 'बिलिङ सेटिङ सेभ भयो';

  @override
  String get billingSettingsSaveFailed => 'बिलिङ सेटिङ सेभ गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get taxSettingsTitle => 'कर सेटिङ';

  @override
  String get settingsBusinessSettingsSubtitle => 'नाम, ठेगाना, मुद्रा';

  @override
  String get settingsTaxSettingsSubtitle => 'VAT / PAN / कर दर';

  @override
  String get settingsSectionTeam => 'टोली';

  @override
  String get userManagementTitle => 'प्रयोगकर्ता व्यवस्थापन';

  @override
  String get subscriptionTitle => 'सदस्यता';

  @override
  String get settingsUserManagementSubtitle => 'कर्मचारी बोलाउनुहोस्, भूमिका सेट गर्नुहोस्';

  @override
  String get settingsSubscriptionSubtitle => 'योजना, बिलिङ विवरण';

  @override
  String get settingsSectionPreferences => 'प्राथमिकताहरू';

  @override
  String get englishLabel => 'अंग्रेजी';

  @override
  String get nepaliLabel => 'नेपाली';

  @override
  String get calendarModeLabel => 'क्यालेन्डर मोड';

  @override
  String get calendarBsLabel => 'बिक्रम सम्बत (BS)';

  @override
  String get calendarAdLabel => 'ग्रेगोरियन (AD)';

  @override
  String get businessTimezoneLabel => 'व्यवसाय समय क्षेत्र';

  @override
  String get settingsSectionAccount => 'खाता';

  @override
  String get settingsProfileSubtitle => 'आफ्नो प्रोफाइल हेर्नुहोस् र सम्पादन गर्नुहोस्';

  @override
  String get settingsSectionAbout => 'बारेमा';

  @override
  String get settingsSyncDiagnosticsSubtitle => 'क्यू, पुन:प्रयास, सिंक त्रुटिहरू';

  @override
  String get versionLabel => 'संस्करण';

  @override
  String get signOutConfirmTitle => 'साइन आउट गर्ने?';

  @override
  String get signOutConfirmBody => 'तपाईं लगइन स्क्रिनमा फर्कनुहुनेछ।';

  @override
  String get signOutLabel => 'साइन आउट';

  @override
  String get myStoreLabel => 'मेरो स्टोर';

  @override
  String get storePhoneLabel => 'स्टोर फोन';

  @override
  String get storeAddressLabel => 'स्टोर ठेगाना';

  @override
  String get businessTypeLabel => 'व्यवसाय प्रकार';

  @override
  String get currencyLabel => 'मुद्रा';

  @override
  String get roleLabel => 'भूमिका';

  @override
  String get authLandingSubtitle => 'तपाईंको पसलको डिजिटल लेजर।\nछिटो। अफलाइन। भरपर्दो।';

  @override
  String get authLandingFeatureFastSales => '१० सेकेन्डभित्र बिक्री रेकर्ड गर्नुहोस्';

  @override
  String get authLandingFeatureOfflineSync => 'अफलाइन काम गर्छ, इन्टरनेट हुँदा सिंक हुन्छ';

  @override
  String get authLandingFeatureCreditTracking => 'ग्राहक उधार भरपर्दो रूपमा ट्र्याक गर्नुहोस्';

  @override
  String get authLandingStartFree => 'फ्रि सुरु गर्नुहोस्';

  @override
  String get authForgotResetTitle => 'आफ्नो पासवर्ड रिसेट गर्नुहोस्';

  @override
  String get authForgotResetBody => 'आफ्नो दर्ता गरिएको फोन नम्बर हाल्नुहोस्, हामी रिसेट निर्देशन पठाउनेछौं।';

  @override
  String get authForgotSuccessBanner => 'यो नम्बरमा खाता भएमा रिसेट निर्देशन प्राप्त हुनेछ। थप सहयोग चाहियो भने सपोर्टमा सम्पर्क गर्नुहोस्।';

  @override
  String get authForgotBackToLogin => 'लगइनमा फर्कनुहोस्';

  @override
  String get phoneNumberLabel => 'फोन नम्बर';

  @override
  String get authForgotSendResetInstructions => 'रिसेट निर्देशन पठाउनुहोस्';

  @override
  String get authBackLabel => 'फर्कनुहोस्';

  @override
  String get authBrandSubtitle => 'व्यवसाय व्यवस्थापक';

  @override
  String get businessSettingsAddressHint => 'सडक, सहर, जिल्ला';

  @override
  String get businessSettingsAddressOptionalLabel => 'ठेगाना (वैकल्पिक)';

  @override
  String get businessSettingsNameLabel => 'व्यवसाय नाम';

  @override
  String get businessSettingsNameRequired => 'नाम आवश्यक छ';

  @override
  String get businessSettingsPhoneOptionalLabel => 'व्यवसाय फोन (वैकल्पिक)';

  @override
  String get businessSettingsSaveFailed => 'सेभ गर्न सकिएन। इन्टरनेट जाँचेर फेरि प्रयास गर्नुहोस्।';

  @override
  String get businessSettingsSaved => 'व्यवसाय सेटिङ सेभ भयो';

  @override
  String get businessTypeElectronics => 'इलेक्ट्रोनिक्स';

  @override
  String get businessTypeGrocery => 'किराना';

  @override
  String get businessTypePharmacy => 'फार्मेसी';

  @override
  String get businessTypeRestaurant => 'रेस्टुरेन्ट';

  @override
  String get businessTypeRetail => 'खुद्रा';

  @override
  String get nextLabel => 'अर्को';

  @override
  String get skipLabel => 'छोड्नुहोस्';

  @override
  String get otherLabel => 'अन्य';

  @override
  String get ownerLabel => 'मालिक';

  @override
  String get onboardingBusinessTypeGeneralStore => 'जनरल स्टोर';

  @override
  String get onboardingDefaultMeasurementUnit => 'पूर्वनिर्धारित नाप एकाइ';

  @override
  String get onboardingDoneOpenStore => 'सकियो - मेरो पसल खोल्नुहोस्';

  @override
  String get onboardingEnableTaxVat => 'कर (VAT) सक्षम गर्नुहोस्';

  @override
  String get onboardingNoTaxApplied => 'कर लागू छैन';

  @override
  String get onboardingSetupStoreTitle => 'आफ्नो पसल सेटअप गर्नुहोस्';

  @override
  String onboardingStepOfTotal(int step, int total) {
    return 'चरण $step / $total';
  }

  @override
  String get onboardingTaxWillApply => 'बिक्रीमा कर लागू हुनेछ';

  @override
  String get onboardingUnitKg => 'केजी';

  @override
  String get onboardingUnitLitre => 'लिटर';

  @override
  String get onboardingUnitOverrideHint => 'तपाईंले प्रत्येक सामानमा फरक राख्न सक्नुहुन्छ।';

  @override
  String get onboardingUnitPacket => 'प्याकेट';

  @override
  String get onboardingUnitPiece => 'थान';

  @override
  String get subscriptionFeatureBasicReports => 'आधारभूत रिपोर्ट';

  @override
  String get subscriptionFeatureBasicReportsSubtitle => 'बिक्री र उधारो रिपोर्ट';

  @override
  String get subscriptionFeatureCloudSync => 'क्लाउड सिंक';

  @override
  String get subscriptionFeatureCloudSyncSubtitle => 'धेरै डिभाइस सिंक';

  @override
  String get subscriptionFeatureCustomerLedger => 'ग्राहक लेजर';

  @override
  String get subscriptionFeatureCustomerLedgerSubtitle => 'उधारो ग्राहक ट्रयाक गर्नुहोस्';

  @override
  String get subscriptionFeatureInvoiceGeneration => 'इनभ्वाइस बनाउने';

  @override
  String get subscriptionFeatureInvoiceGenerationSubtitle => 'PDF इनभ्वाइस र बिलिङ';

  @override
  String get subscriptionFeatureProductManagement => 'सामान व्यवस्थापन';

  @override
  String get subscriptionFeatureProductManagementSubtitle => '१०० वस्तुसम्म';

  @override
  String get subscriptionFeatureSalesRecording => 'बिक्री रेकर्डिङ';

  @override
  String get subscriptionFeatureSalesRecordingSubtitle => 'असीमित नगद र उधारो बिक्री';

  @override
  String get subscriptionFreePlanBadge => 'फ्री योजना';

  @override
  String get subscriptionFreePlanIncludes => 'फ्री योजनामा समावेश';

  @override
  String get subscriptionFreePlanSubtitle => 'मुख्य सुविधाहरू निःशुल्क प्रयोग गर्नुहोस्';

  @override
  String get subscriptionFreePlanTitle => 'Naphaa Free';

  @override
  String get subscriptionProComingSoon => 'Pro योजना चाँडै आउँदैछ। प्रतीक्षा गर्नुहोस्!';

  @override
  String get subscriptionUpgradeToPro => 'Pro मा अपग्रेड';

  @override
  String get taxSettingsEnableVat => 'VAT सक्षम गर्नुहोस्';

  @override
  String get taxSettingsEnableVatSubtitle => 'बिक्रीमा VAT स्वतः लागू गर्नुहोस्';

  @override
  String get taxSettingsPanHint => '९ अङ्कको PAN';

  @override
  String get taxSettingsPanOptionalLabel => 'PAN नम्बर (वैकल्पिक)';

  @override
  String get taxSettingsSaveAction => 'कर सेटिङ सेभ गर्नुहोस्';

  @override
  String get taxSettingsSaveFailed => 'सेभ गर्न सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get taxSettingsSaved => 'कर सेटिङ सेभ भयो';

  @override
  String get taxSettingsVatRateLabel => 'VAT दर (%)';

  @override
  String get userManagementInviteComingSoon => 'निमन्त्रणा सुविधा चाँडै आउँदैछ';

  @override
  String get userManagementInviteStaffDialogBody => 'निमन्त्रणा गर्नुपर्ने कर्मचारीको फोन नम्बर लेख्नुहोस्।';

  @override
  String get userManagementInviteStaffMember => 'कर्मचारी निमन्त्रणा गर्नुहोस्';

  @override
  String get userManagementInviteStaffSubtitle => 'पसल व्यवस्थापनका लागि कर्मचारी बोलाउनुहोस्';

  @override
  String get userManagementInviteStaffTitle => 'कर्मचारी निमन्त्रणा';

  @override
  String get userManagementNoStaffMembers => 'अहिलेसम्म कर्मचारी सदस्य छैनन्';

  @override
  String get userManagementOwnerFullAccess => 'मालिक · पूर्ण पहुँच';

  @override
  String get userManagementSendInvite => 'निमन्त्रणा पठाउनुहोस्';

  @override
  String get userManagementStaffMembers => 'कर्मचारी सदस्यहरू';

  @override
  String get highRiskLabel => 'उच्च जोखिम';

  @override
  String get mediumRiskLabel => 'मध्यम जोखिम';

  @override
  String get lowRiskLabel => 'कम जोखिम';

  @override
  String get infoLabel => 'जानकारी';

  @override
  String get paymentMethodCashLabel => 'नगद';

  @override
  String get paymentMethodBankLabel => 'बैंक';

  @override
  String get paymentMethodQrLabel => 'QR';

  @override
  String get paymentMethodCreditLabel => 'उधारो';

  @override
  String get invoiceStatusDraftLabel => 'ड्राफ्ट';

  @override
  String get invoiceStatusIssuedLabel => 'जारी';

  @override
  String get invoiceStatusPaidLabel => 'तिरेको';

  @override
  String get invoiceStatusOverdueLabel => 'म्याद नाघेको';

  @override
  String get invoiceStatusCancelledLabel => 'रद्द';
}
