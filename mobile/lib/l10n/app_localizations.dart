import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne')
  ];

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @reportsQuickStatTodaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get reportsQuickStatTodaySales;

  /// No description provided for @reportsQuickStatPendingCredit.
  ///
  /// In en, this message translates to:
  /// **'Pending Credit'**
  String get reportsQuickStatPendingCredit;

  /// No description provided for @reportsBusinessHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profit, credit risk, stock health, alerts'**
  String get reportsBusinessHealthSubtitle;

  /// No description provided for @reportsSalesReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get reportsSalesReportTitle;

  /// No description provided for @reportsSalesReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue, transactions by period'**
  String get reportsSalesReportSubtitle;

  /// No description provided for @salesReportTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get salesReportTotalRevenue;

  /// No description provided for @salesReportTransactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transaction(s)'**
  String salesReportTransactionCount(int count);

  /// No description provided for @salesReportBreakdownByType.
  ///
  /// In en, this message translates to:
  /// **'Breakdown by Type'**
  String get salesReportBreakdownByType;

  /// No description provided for @salesReportCashSales.
  ///
  /// In en, this message translates to:
  /// **'Cash Sales'**
  String get salesReportCashSales;

  /// No description provided for @salesReportCreditSales.
  ///
  /// In en, this message translates to:
  /// **'Credit Sales'**
  String get salesReportCreditSales;

  /// No description provided for @reportsProfitReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Profit Report'**
  String get reportsProfitReportTitle;

  /// No description provided for @reportsProfitReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gross & net profit breakdown'**
  String get reportsProfitReportSubtitle;

  /// No description provided for @profitReportNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get profitReportNetProfit;

  /// No description provided for @profitReportBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get profitReportBreakdown;

  /// No description provided for @profitReportEstimatedGrossProfit30.
  ///
  /// In en, this message translates to:
  /// **'Est. Gross Profit (30%)'**
  String get profitReportEstimatedGrossProfit30;

  /// No description provided for @profitReportTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get profitReportTotalExpenses;

  /// No description provided for @profitReportEstimatedNotice.
  ///
  /// In en, this message translates to:
  /// **'Gross profit is estimated. Connect product cost prices for accurate margin calculation.'**
  String get profitReportEstimatedNotice;

  /// No description provided for @reportsCreditReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Report'**
  String get reportsCreditReportTitle;

  /// No description provided for @reportsCreditReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Outstanding customer balances'**
  String get reportsCreditReportSubtitle;

  /// No description provided for @creditReportNoOutstandingTitle.
  ///
  /// In en, this message translates to:
  /// **'No outstanding credit'**
  String get creditReportNoOutstandingTitle;

  /// No description provided for @creditReportNoOutstandingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All customers are settled'**
  String get creditReportNoOutstandingSubtitle;

  /// No description provided for @creditReportTotalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get creditReportTotalOutstanding;

  /// No description provided for @creditReportCustomerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} customer(s)'**
  String creditReportCustomerCount(int count);

  /// No description provided for @creditReportRiskBadge.
  ///
  /// In en, this message translates to:
  /// **'{label} Risk'**
  String creditReportRiskBadge(String label);

  /// No description provided for @reportsCreditAgingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Outstanding by age buckets and risk'**
  String get reportsCreditAgingSubtitle;

  /// No description provided for @reportsAlertsFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts Feed'**
  String get reportsAlertsFeedTitle;

  /// No description provided for @reportsAlertsFeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Actionable risk and business alerts'**
  String get reportsAlertsFeedSubtitle;

  /// No description provided for @reportsProductInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Insights'**
  String get reportsProductInsightsTitle;

  /// No description provided for @reportsProductInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profit by product and dead stock'**
  String get reportsProductInsightsSubtitle;

  /// No description provided for @productInsightsDeadStockOnly.
  ///
  /// In en, this message translates to:
  /// **'Dead Stock Only'**
  String get productInsightsDeadStockOnly;

  /// No description provided for @productInsightsNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No product metrics yet'**
  String get productInsightsNoDataTitle;

  /// No description provided for @productInsightsNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create sales and sync to see product insights'**
  String get productInsightsNoDataSubtitle;

  /// No description provided for @productInsightsCachedDataBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing cached product insights (offline). Refresh when internet is available.'**
  String get productInsightsCachedDataBanner;

  /// No description provided for @productInsightsDeadStockItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Dead Stock Items'**
  String get productInsightsDeadStockItemsLabel;

  /// No description provided for @productInsightsLockedValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked Value'**
  String get productInsightsLockedValueLabel;

  /// No description provided for @productInsightsProfitNote.
  ///
  /// In en, this message translates to:
  /// **'Profit is estimated using product cost price (sell price - cost price) x quantity sold. It does not subtract allocated business expenses. Products without cost price are excluded from profit ranking.'**
  String get productInsightsProfitNote;

  /// No description provided for @productInsightsTopProfitProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Profit Products'**
  String get productInsightsTopProfitProductsTitle;

  /// No description provided for @productInsightsProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get productInsightsProfitLabel;

  /// No description provided for @productInsightsFastMovers7dTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast Movers (7d)'**
  String get productInsightsFastMovers7dTitle;

  /// No description provided for @productInsightsQtySold7dLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty sold (7d)'**
  String get productInsightsQtySold7dLabel;

  /// No description provided for @productInsightsDeadStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Dead Stock'**
  String get productInsightsDeadStockTitle;

  /// No description provided for @productInsightsNoSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get productInsightsNoSalesYet;

  /// No description provided for @productInsightsLastSaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Last sale'**
  String get productInsightsLastSaleLabel;

  /// No description provided for @productInsightsCostNotSet.
  ///
  /// In en, this message translates to:
  /// **'Cost not set'**
  String get productInsightsCostNotSet;

  /// No description provided for @productInsightsValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get productInsightsValueLabel;

  /// No description provided for @reportsInvoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, issue and collect invoice payments'**
  String get reportsInvoicesSubtitle;

  /// No description provided for @reportsLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get reportsLedgerTitle;

  /// No description provided for @reportsLedgerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unified financial audit trail'**
  String get reportsLedgerSubtitle;

  /// No description provided for @ledgerNoEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No ledger entries yet'**
  String get ledgerNoEntriesTitle;

  /// No description provided for @ledgerNoEntriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales, expenses, payments and refunds will appear here.'**
  String get ledgerNoEntriesSubtitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Naphaa'**
  String get appName;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProducts;

  /// No description provided for @saveCashSale.
  ///
  /// In en, this message translates to:
  /// **'Save Cash Sale'**
  String get saveCashSale;

  /// No description provided for @saveCreditSale.
  ///
  /// In en, this message translates to:
  /// **'Save Credit Sale'**
  String get saveCreditSale;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today Sales'**
  String get todaySales;

  /// No description provided for @estimatedProfit.
  ///
  /// In en, this message translates to:
  /// **'Estimated Profit'**
  String get estimatedProfit;

  /// No description provided for @creditOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Credit Outstanding'**
  String get creditOutstanding;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @expensesFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Expenses entry screen coming soon'**
  String get expensesFeatureComingSoon;

  /// No description provided for @inject100Records.
  ///
  /// In en, this message translates to:
  /// **'Inject 100 realistic records'**
  String get inject100Records;

  /// No description provided for @injectedDemoData.
  ///
  /// In en, this message translates to:
  /// **'Inserted 100 realistic test records'**
  String get injectedDemoData;

  /// No description provided for @manageProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage products'**
  String get manageProducts;

  /// No description provided for @manageCustomers.
  ///
  /// In en, this message translates to:
  /// **'Manage customers'**
  String get manageCustomers;

  /// No description provided for @trackExpenses.
  ///
  /// In en, this message translates to:
  /// **'Track expenses'**
  String get trackExpenses;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerName;

  /// No description provided for @businessLabel.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessLabel;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @panVatLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN/VAT'**
  String get panVatLabel;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @createLabel.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Dashboard overview'**
  String get dashboardOverview;

  /// No description provided for @failedToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get failedToLoadDashboard;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @criticalLabel.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get criticalLabel;

  /// No description provided for @warningLabel.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warningLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @unknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLabel;

  /// No description provided for @alertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsLabel;

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @alertsFeedMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get alertsFeedMarkAllRead;

  /// No description provided for @alertsFeedMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark Read'**
  String get alertsFeedMarkRead;

  /// No description provided for @alertsFeedEverythingStableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything looks stable right now'**
  String get alertsFeedEverythingStableSubtitle;

  /// No description provided for @alertsActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Action not available yet for this alert'**
  String get alertsActionUnavailable;

  /// No description provided for @alertCount.
  ///
  /// In en, this message translates to:
  /// **'{count} alerts'**
  String alertCount(int count);

  /// No description provided for @alertsCountWithStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} alerts ({status})'**
  String alertsCountWithStatus(int count, String status);

  /// No description provided for @lowStockItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Low stock items'**
  String get lowStockItemsTitle;

  /// No description provided for @checkingStock.
  ///
  /// In en, this message translates to:
  /// **'Checking stock...'**
  String get checkingStock;

  /// No description provided for @unableLoadLowStockData.
  ///
  /// In en, this message translates to:
  /// **'Unable to load low stock data'**
  String get unableLoadLowStockData;

  /// No description provided for @allProductsAboveThreshold.
  ///
  /// In en, this message translates to:
  /// **'All products are above threshold.'**
  String get allProductsAboveThreshold;

  /// No description provided for @stockLeftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String stockLeftCount(String count);

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get quickActionsTitle;

  /// No description provided for @recordPay.
  ///
  /// In en, this message translates to:
  /// **'Record Pay'**
  String get recordPay;

  /// No description provided for @businessHealth.
  ///
  /// In en, this message translates to:
  /// **'Business Health'**
  String get businessHealth;

  /// No description provided for @businessHealthCachedDataBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing cached intelligence data (offline). Pull to refresh when internet is available.'**
  String get businessHealthCachedDataBanner;

  /// No description provided for @businessHealthProfitSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Profit Snapshot'**
  String get businessHealthProfitSnapshotTitle;

  /// No description provided for @businessHealthEstimatedProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Est. Profit'**
  String get businessHealthEstimatedProfitLabel;

  /// No description provided for @businessHealthOutstandingCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Credit'**
  String get businessHealthOutstandingCreditLabel;

  /// No description provided for @businessHealthProfitMarginLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit Margin'**
  String get businessHealthProfitMarginLabel;

  /// No description provided for @businessHealthCashRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash Risk'**
  String get businessHealthCashRiskLabel;

  /// No description provided for @businessHealthCashOutlookTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Outlook'**
  String get businessHealthCashOutlookTitle;

  /// No description provided for @businessHealthExpectedIncomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Incoming'**
  String get businessHealthExpectedIncomingLabel;

  /// No description provided for @businessHealthExpectedOutgoingLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Outgoing'**
  String get businessHealthExpectedOutgoingLabel;

  /// No description provided for @businessHealthNetOutlookNextDays.
  ///
  /// In en, this message translates to:
  /// **'Next {days} days net outlook: NPR {amount}'**
  String businessHealthNetOutlookNextDays(int days, Object amount);

  /// No description provided for @businessHealthProfitSnapshotNote.
  ///
  /// In en, this message translates to:
  /// **'Estimated Profit here is a simple operational snapshot (today sales - today expenses). Product-level profit reports use cost price and may not match this total exactly.'**
  String get businessHealthProfitSnapshotNote;

  /// No description provided for @businessHealthCreditRiskSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Risk Summary'**
  String get businessHealthCreditRiskSummaryTitle;

  /// No description provided for @businessHealthStockHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock Health'**
  String get businessHealthStockHealthTitle;

  /// No description provided for @businessHealthFastMoversTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast Movers'**
  String get businessHealthFastMoversTitle;

  /// No description provided for @businessHealthAlertsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts Preview'**
  String get businessHealthAlertsPreviewTitle;

  /// No description provided for @businessHealthDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String businessHealthDaysShort(int count);

  /// No description provided for @businessHealthNoLowStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'No low stock alerts right now'**
  String get businessHealthNoLowStockAlerts;

  /// No description provided for @businessHealthLowStockItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} low-stock items'**
  String businessHealthLowStockItemsCount(int count);

  /// No description provided for @businessHealthNoActiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get businessHealthNoActiveAlerts;

  /// No description provided for @businessHealthNoFastMovers7d.
  ///
  /// In en, this message translates to:
  /// **'No fast movers in the last 7 days'**
  String get businessHealthNoFastMovers7d;

  /// No description provided for @businessHealthSevenDayQtySoldLabel.
  ///
  /// In en, this message translates to:
  /// **'7-day quantity sold'**
  String get businessHealthSevenDayQtySoldLabel;

  /// No description provided for @thresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get thresholdLabel;

  /// No description provided for @revenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueLabel;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @creditAging.
  ///
  /// In en, this message translates to:
  /// **'Credit Aging'**
  String get creditAging;

  /// No description provided for @creditAgingOverdueOnly.
  ///
  /// In en, this message translates to:
  /// **'Overdue Only'**
  String get creditAgingOverdueOnly;

  /// No description provided for @creditAgingHighRiskOnly.
  ///
  /// In en, this message translates to:
  /// **'High Risk Only'**
  String get creditAgingHighRiskOnly;

  /// No description provided for @creditAgingNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No credit aging data'**
  String get creditAgingNoDataTitle;

  /// No description provided for @creditAgingNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No customers match the selected filters'**
  String get creditAgingNoDataSubtitle;

  /// No description provided for @creditAgingCachedDataBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing cached credit aging data (offline). Refresh when internet is available.'**
  String get creditAgingCachedDataBanner;

  /// No description provided for @creditAgingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Aging Summary'**
  String get creditAgingSummaryTitle;

  /// No description provided for @creditAgingOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get creditAgingOutstandingLabel;

  /// No description provided for @creditAgingOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get creditAgingOverdueLabel;

  /// No description provided for @creditAgingHighRiskCustomersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} high-risk customers'**
  String creditAgingHighRiskCustomersCount(int count);

  /// No description provided for @creditAgingBucketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Aging Buckets'**
  String get creditAgingBucketsTitle;

  /// No description provided for @creditAgingBucket0to7.
  ///
  /// In en, this message translates to:
  /// **'0–7 days'**
  String get creditAgingBucket0to7;

  /// No description provided for @creditAgingBucket8to30.
  ///
  /// In en, this message translates to:
  /// **'8–30 days'**
  String get creditAgingBucket8to30;

  /// No description provided for @creditAgingBucket31to60.
  ///
  /// In en, this message translates to:
  /// **'31–60 days'**
  String get creditAgingBucket31to60;

  /// No description provided for @creditAgingBucket60Plus.
  ///
  /// In en, this message translates to:
  /// **'60+ days'**
  String get creditAgingBucket60Plus;

  /// No description provided for @creditAgingOldestDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Oldest Due'**
  String get creditAgingOldestDueLabel;

  /// No description provided for @creditAgingDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String creditAgingDaysCount(int count);

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @invoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceLabel;

  /// No description provided for @invoicePdfTitle.
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get invoicePdfTitle;

  /// No description provided for @draftLabel.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get draftLabel;

  /// No description provided for @invoiceDueShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get invoiceDueShortLabel;

  /// No description provided for @invoiceListNewInvoice.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get invoiceListNewInvoice;

  /// No description provided for @invoiceListNoInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get invoiceListNoInvoicesTitle;

  /// No description provided for @invoiceListNoInvoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first invoice and issue it offline.'**
  String get invoiceListNoInvoicesSubtitle;

  /// No description provided for @invoiceListCreateInvoiceAction.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get invoiceListCreateInvoiceAction;

  /// No description provided for @invoiceListDraftFallback.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get invoiceListDraftFallback;

  /// No description provided for @invoiceListDraftNotIssued.
  ///
  /// In en, this message translates to:
  /// **'Draft (not issued)'**
  String get invoiceListDraftNotIssued;

  /// No description provided for @invoiceListTotalsSummary.
  ///
  /// In en, this message translates to:
  /// **'Total: NPR {total}   •   Balance: NPR {balance}'**
  String invoiceListTotalsSummary(Object total, Object balance);

  /// No description provided for @netAfterExpenses.
  ///
  /// In en, this message translates to:
  /// **'Net after expenses'**
  String get netAfterExpenses;

  /// No description provided for @cashflowHealth.
  ///
  /// In en, this message translates to:
  /// **'Cashflow health'**
  String get cashflowHealth;

  /// No description provided for @creditExposure.
  ///
  /// In en, this message translates to:
  /// **'Credit exposure'**
  String get creditExposure;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @watchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlist;

  /// No description provided for @risky.
  ///
  /// In en, this message translates to:
  /// **'Risky'**
  String get risky;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Naphaa'**
  String get authTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signup;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @startManagingYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Start managing your business today'**
  String get startManagingYourBusiness;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @businessNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Shop, Sunrise Store'**
  String get businessNameHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get passwordHint;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @businessNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Business name must be at least 3 characters'**
  String get businessNameTooShort;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number'**
  String get invalidPhone;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @switchToSignup.
  ///
  /// In en, this message translates to:
  /// **'Switch to signup'**
  String get switchToSignup;

  /// No description provided for @switchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Switch to login'**
  String get switchToLogin;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Please contact support to reset your password.'**
  String get forgotPasswordHint;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineMode;

  /// No description provided for @syncingShort.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncingShort;

  /// No description provided for @syncingChanges.
  ///
  /// In en, this message translates to:
  /// **'Syncing {count} changes…'**
  String syncingChanges(int count);

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @monthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthLabel;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// No description provided for @invoicePickBsDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter BS date'**
  String get invoicePickBsDateTitle;

  /// No description provided for @invalidBsDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid BS date'**
  String get invalidBsDate;

  /// No description provided for @thisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekLabel;

  /// No description provided for @thisMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonthLabel;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get walkInCustomer;

  /// No description provided for @nprLabel.
  ///
  /// In en, this message translates to:
  /// **'NPR'**
  String get nprLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsLabel;

  /// No description provided for @paymentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountLabel;

  /// No description provided for @saleDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale Details'**
  String get saleDetailsTitle;

  /// No description provided for @saleNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale not found'**
  String get saleNotFoundTitle;

  /// No description provided for @saleNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This sale may have been removed'**
  String get saleNotFoundSubtitle;

  /// No description provided for @salesNoSalesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get salesNoSalesYetTitle;

  /// No description provided for @salesNoSalesYetTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to record your first sale today'**
  String get salesNoSalesYetTodaySubtitle;

  /// No description provided for @salesNoTransactionsInPeriodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period'**
  String get salesNoTransactionsInPeriodSubtitle;

  /// No description provided for @salesNoProductsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get salesNoProductsYetTitle;

  /// No description provided for @salesNoProductsQuickCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Search a product name and quick create it from here.'**
  String get salesNoProductsQuickCreateHint;

  /// No description provided for @salesNoMatchForQuery.
  ///
  /// In en, this message translates to:
  /// **'No match for \"{query}\"'**
  String salesNoMatchForQuery(Object query);

  /// No description provided for @salesCreateProductQuicklyCta.
  ///
  /// In en, this message translates to:
  /// **'Create Product Quickly'**
  String get salesCreateProductQuicklyCta;

  /// No description provided for @salesCreateProductQuicklyFor.
  ///
  /// In en, this message translates to:
  /// **'Create \"{query}\" quickly'**
  String salesCreateProductQuicklyFor(Object query);

  /// No description provided for @salesCreateProductQuicklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter only selling price and continue sale'**
  String get salesCreateProductQuicklySubtitle;

  /// No description provided for @salesQuickAddProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Add Product'**
  String get salesQuickAddProductTitle;

  /// No description provided for @salesQuickCreditCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Credit Customer'**
  String get salesQuickCreditCustomerTitle;

  /// No description provided for @salesCreditRiskWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Risk Warning'**
  String get salesCreditRiskWarningTitle;

  /// No description provided for @salesCreditRiskExistingCustomerMarked.
  ///
  /// In en, this message translates to:
  /// **'Existing customer \"{name}\" is marked {label}.'**
  String salesCreditRiskExistingCustomerMarked(Object name, Object label);

  /// No description provided for @salesCreditRiskOutstandingNpr.
  ///
  /// In en, this message translates to:
  /// **'Outstanding: NPR {amount}'**
  String salesCreditRiskOutstandingNpr(Object amount);

  /// No description provided for @salesCreditRiskOldestDueDays.
  ///
  /// In en, this message translates to:
  /// **'Oldest due: {count} days'**
  String salesCreditRiskOldestDueDays(int count);

  /// No description provided for @salesCreditRiskScore.
  ///
  /// In en, this message translates to:
  /// **'Risk score: {score}'**
  String salesCreditRiskScore(Object score);

  /// No description provided for @salesCreditRiskContinueWarning.
  ///
  /// In en, this message translates to:
  /// **'Continue only if you are comfortable extending more credit.'**
  String get salesCreditRiskContinueWarning;

  /// No description provided for @salesCartItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String salesCartItemsCount(int count);

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers…'**
  String get searchCustomersHint;

  /// No description provided for @failedToLoadCustomers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customers'**
  String get failedToLoadCustomers;

  /// No description provided for @noCustomersFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFoundTitle;

  /// No description provided for @customersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Customer\" to get started.'**
  String get customersEmptySubtitle;

  /// No description provided for @customersTryDifferentSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or phone number.'**
  String get customersTryDifferentSearchSubtitle;

  /// No description provided for @deleteCustomerDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete customer?'**
  String get deleteCustomerDialogTitle;

  /// No description provided for @customerDeletePermanentBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed.'**
  String customerDeletePermanentBody(String name);

  /// No description provided for @owesYouLabel.
  ///
  /// In en, this message translates to:
  /// **'owes you'**
  String get owesYouLabel;

  /// No description provided for @creditLabel.
  ///
  /// In en, this message translates to:
  /// **'credit'**
  String get creditLabel;

  /// No description provided for @recordPaymentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPaymentTooltip;

  /// No description provided for @editCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomerTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get customerNameRequired;

  /// No description provided for @phoneOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (optional)'**
  String get phoneOptionalLabel;

  /// No description provided for @addressOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptionalLabel;

  /// No description provided for @streetCityHint.
  ///
  /// In en, this message translates to:
  /// **'Street, City'**
  String get streetCityHint;

  /// No description provided for @notesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptionalLabel;

  /// No description provided for @customerNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes'**
  String get customerNotesHint;

  /// No description provided for @customerSaveFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to save customer. Try again.'**
  String get customerSaveFailedTryAgain;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get searchProductsHint;

  /// No description provided for @failedToLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get failedToLoadProducts;

  /// No description provided for @productsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Product\" to get started.'**
  String get productsEmptySubtitle;

  /// No description provided for @deleteProductDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get deleteProductDialogTitle;

  /// No description provided for @productDeletePermanentBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed.'**
  String productDeletePermanentBody(String name);

  /// No description provided for @lowStockBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockBadgeLabel;

  /// No description provided for @rsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rs'**
  String get rsLabel;

  /// No description provided for @adjustStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjust Stock'**
  String get adjustStockLabel;

  /// No description provided for @editProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProductTitle;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get productNameRequired;

  /// No description provided for @categoryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get categoryOptionalLabel;

  /// No description provided for @productCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Snacks, Beverages'**
  String get productCategoryHint;

  /// No description provided for @sellPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Sell Price'**
  String get sellPriceLabel;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter valid price'**
  String get enterValidPrice;

  /// No description provided for @costPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPriceLabel;

  /// No description provided for @openingStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening Stock'**
  String get openingStockLabel;

  /// No description provided for @lowStockThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Threshold'**
  String get lowStockThresholdLabel;

  /// No description provided for @lowStockThresholdHint.
  ///
  /// In en, this message translates to:
  /// **'0 to disable alert'**
  String get lowStockThresholdHint;

  /// No description provided for @enterValidThreshold.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid threshold'**
  String get enterValidThreshold;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @productSaveFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to save product. Try again.'**
  String get productSaveFailedTryAgain;

  /// No description provided for @productDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetailsTitle;

  /// No description provided for @productNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFoundTitle;

  /// No description provided for @productNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This product may have been removed'**
  String get productNotFoundSubtitle;

  /// No description provided for @marginLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get marginLabel;

  /// No description provided for @stockHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock History'**
  String get stockHistoryTitle;

  /// No description provided for @noStockMovementsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No stock movements yet'**
  String get noStockMovementsYetTitle;

  /// No description provided for @customerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetailsTitle;

  /// No description provided for @customerNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer not found'**
  String get customerNotFoundTitle;

  /// No description provided for @customerNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This customer may have been removed'**
  String get customerNotFoundSubtitle;

  /// No description provided for @outstandingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstandingBalanceLabel;

  /// No description provided for @recordPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPaymentLabel;

  /// No description provided for @transactionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistoryTitle;

  /// No description provided for @loadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Loading transactions...'**
  String get loadingTransactions;

  /// No description provided for @failedToLoadCustomerTransactions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customer transactions'**
  String get failedToLoadCustomerTransactions;

  /// No description provided for @noTransactionsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYetTitle;

  /// No description provided for @paymentReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceivedLabel;

  /// No description provided for @creditSaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Sale'**
  String get creditSaleLabel;

  /// No description provided for @riskExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk Explanation'**
  String get riskExplanationTitle;

  /// No description provided for @oldestOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Oldest overdue'**
  String get oldestOverdueLabel;

  /// No description provided for @averageDaysToPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Average days to pay'**
  String get averageDaysToPayLabel;

  /// No description provided for @onTimeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'On-time rate'**
  String get onTimeRateLabel;

  /// No description provided for @outstandingSpikeLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding spike'**
  String get outstandingSpikeLabel;

  /// No description provided for @daysValue.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysValue(int count);

  /// No description provided for @daysValueDecimal.
  ///
  /// In en, this message translates to:
  /// **'{value} days'**
  String daysValueDecimal(String value);

  /// No description provided for @oldestDueChipDays.
  ///
  /// In en, this message translates to:
  /// **'Oldest due: {days}d'**
  String oldestDueChipDays(int days);

  /// No description provided for @highLabel.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highLabel;

  /// No description provided for @mediumLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumLabel;

  /// No description provided for @lowLabel.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowLabel;

  /// No description provided for @normalLabel.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalLabel;

  /// No description provided for @failedToLoadExpenses.
  ///
  /// In en, this message translates to:
  /// **'Failed to load expenses'**
  String get failedToLoadExpenses;

  /// No description provided for @expensesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Expense\" to record your first expense.'**
  String get expensesEmptySubtitle;

  /// No description provided for @expenseCategoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get expenseCategoryRent;

  /// No description provided for @expenseCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expenseCategoryTransport;

  /// No description provided for @expenseCategoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get expenseCategoryUtilities;

  /// No description provided for @expenseCategorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get expenseCategorySalary;

  /// No description provided for @expenseCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expenseCategoryOther;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @failedToSaveWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSaveWithError(String error);

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @amountCannotExceedOutstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed outstanding balance'**
  String get amountCannotExceedOutstandingBalance;

  /// No description provided for @paymentRecordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get paymentRecordedSuccessfully;

  /// No description provided for @failedToRecordPaymentTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment. Try again.'**
  String get failedToRecordPaymentTryAgain;

  /// No description provided for @creditCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Customer'**
  String get creditCustomerLabel;

  /// No description provided for @paymentDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetailsTitle;

  /// No description provided for @amountReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Received'**
  String get amountReceivedLabel;

  /// No description provided for @fullLabel.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fullLabel;

  /// No description provided for @paymentMethodLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabelTitle;

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @addStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Stock'**
  String get addStockLabel;

  /// No description provided for @removeStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove Stock'**
  String get removeStockLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @egTenHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get egTenHint;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @additionalDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Additional details…'**
  String get additionalDetailsHint;

  /// No description provided for @saveAdjustmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Save Adjustment'**
  String get saveAdjustmentLabel;

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get enterValidQuantity;

  /// No description provided for @failedToAdjustStockTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to adjust stock. Try again.'**
  String get failedToAdjustStockTryAgain;

  /// No description provided for @currentStockValue.
  ///
  /// In en, this message translates to:
  /// **'Current stock: {value}'**
  String currentStockValue(String value);

  /// No description provided for @serverHasNewerDataPullRetry.
  ///
  /// In en, this message translates to:
  /// **'Server has newer data. Pull latest and retry.'**
  String get serverHasNewerDataPullRetry;

  /// No description provided for @syncFailedWillRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Will retry.'**
  String get syncFailedWillRetry;

  /// No description provided for @pendingChangesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending changes'**
  String pendingChangesCount(int count);

  /// No description provided for @pullRetryShort.
  ///
  /// In en, this message translates to:
  /// **'Pull+Retry'**
  String get pullRetryShort;

  /// No description provided for @syncNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNowLabel;

  /// No description provided for @syncDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Diagnostics'**
  String get syncDiagnosticsTitle;

  /// No description provided for @clearFailedRowsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear Failed Rows'**
  String get clearFailedRowsTooltip;

  /// No description provided for @clearFailedRowsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear failed sync rows?'**
  String get clearFailedRowsConfirmTitle;

  /// No description provided for @clearFailedRowsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This is for demo/testing cleanup. Failed offline changes will be removed from the local sync queue.'**
  String get clearFailedRowsConfirmBody;

  /// No description provided for @clearFailedAction.
  ///
  /// In en, this message translates to:
  /// **'Clear Failed'**
  String get clearFailedAction;

  /// No description provided for @clearedFailedRowsCount.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} failed sync rows'**
  String clearedFailedRowsCount(int count);

  /// No description provided for @retrySyncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Retry Sync'**
  String get retrySyncTooltip;

  /// No description provided for @refreshLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @ackedLabel.
  ///
  /// In en, this message translates to:
  /// **'Acked'**
  String get ackedLabel;

  /// No description provided for @failedLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedLabel;

  /// No description provided for @syncDiagnosticsFailedRowsBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} sync rows failed. Retry sync or open a row for details.'**
  String syncDiagnosticsFailedRowsBanner(int count);

  /// No description provided for @syncDiagnosticsInvalidRowsBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} offline changes are invalid and could not be synced.'**
  String syncDiagnosticsInvalidRowsBanner(int count);

  /// No description provided for @noSyncQueueItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'No sync queue items'**
  String get noSyncQueueItemsTitle;

  /// No description provided for @noSyncQueueItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline changes and sync errors will appear here.'**
  String get noSyncQueueItemsSubtitle;

  /// No description provided for @retryCountShort.
  ///
  /// In en, this message translates to:
  /// **'retry {count}'**
  String retryCountShort(int count);

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @entityIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Entity ID'**
  String get entityIdLabel;

  /// No description provided for @opIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Op ID'**
  String get opIdLabel;

  /// No description provided for @retriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Retries'**
  String get retriesLabel;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedLabel;

  /// No description provided for @lastErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Error'**
  String get lastErrorLabel;

  /// No description provided for @copiedErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Copied error details'**
  String get copiedErrorDetails;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemLabel;

  /// No description provided for @termsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsLabel;

  /// No description provided for @pdfGenerationFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'PDF generation failed'**
  String get pdfGenerationFailedPrefix;

  /// No description provided for @syncTelemetrySummary.
  ///
  /// In en, this message translates to:
  /// **'ack {acked} • fail {failed} • pull {pulled} • {durationMs}ms'**
  String syncTelemetrySummary(int acked, int failed, int pulled, int durationMs);

  /// No description provided for @invoiceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetailTitle;

  /// No description provided for @invoiceDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invoice not found'**
  String get invoiceDetailNotFound;

  /// No description provided for @invoiceDetailDraftFallback.
  ///
  /// In en, this message translates to:
  /// **'Draft Invoice'**
  String get invoiceDetailDraftFallback;

  /// No description provided for @invoiceIssueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get invoiceIssueDateLabel;

  /// No description provided for @invoiceNotIssued.
  ///
  /// In en, this message translates to:
  /// **'Not issued'**
  String get invoiceNotIssued;

  /// No description provided for @invoiceDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get invoiceDueDateLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @vatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatLabel;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @invoiceDetailNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get invoiceDetailNoItems;

  /// No description provided for @invoicePaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get invoicePaymentsTitle;

  /// No description provided for @invoicePaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded'**
  String get invoicePaymentsEmpty;

  /// No description provided for @actionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsLabel;

  /// No description provided for @issueLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueLabel;

  /// No description provided for @invoiceRecordPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get invoiceRecordPaymentLabel;

  /// No description provided for @invoicePdfRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry PDF'**
  String get invoicePdfRetry;

  /// No description provided for @invoicePdfRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate PDF'**
  String get invoicePdfRegenerate;

  /// No description provided for @invoicePdfGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get invoicePdfGenerate;

  /// No description provided for @invoicePdfShare.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get invoicePdfShare;

  /// No description provided for @printLabel.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printLabel;

  /// No description provided for @invoiceIssuedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invoice issued successfully'**
  String get invoiceIssuedSuccess;

  /// No description provided for @invoicePdfGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF generated successfully'**
  String get invoicePdfGeneratedSuccess;

  /// No description provided for @invoiceBalanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Balance: {value}'**
  String invoiceBalanceSummary(String value);

  /// No description provided for @noteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptionalLabel;

  /// No description provided for @invoiceEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get invoiceEnterValidAmount;

  /// No description provided for @invoicePaymentRecordedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get invoicePaymentRecordedSuccess;

  /// No description provided for @invoiceCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get invoiceCreateTitle;

  /// No description provided for @invoiceDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetailsTitle;

  /// No description provided for @invoiceCustomerIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer ID (optional)'**
  String get invoiceCustomerIdOptional;

  /// No description provided for @invoiceDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Discount'**
  String get invoiceDiscountLabel;

  /// No description provided for @invoiceAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add Line'**
  String get invoiceAddLine;

  /// No description provided for @invoiceSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get invoiceSaveDraft;

  /// No description provided for @invoiceIssuing.
  ///
  /// In en, this message translates to:
  /// **'Issuing...'**
  String get invoiceIssuing;

  /// No description provided for @invoiceIssueAction.
  ///
  /// In en, this message translates to:
  /// **'Issue Invoice'**
  String get invoiceIssueAction;

  /// No description provided for @invoiceNoActiveStore.
  ///
  /// In en, this message translates to:
  /// **'No active business/store found. Please login again.'**
  String get invoiceNoActiveStore;

  /// No description provided for @invoiceAddAtLeastOneItem.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get invoiceAddAtLeastOneItem;

  /// No description provided for @invoiceLineItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get invoiceLineItemName;

  /// No description provided for @requiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredLabel;

  /// No description provided for @invoiceProductIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Product ID (optional)'**
  String get invoiceProductIdOptional;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qtyLabel;

  /// No description provided for @invoiceQtyPositive.
  ///
  /// In en, this message translates to:
  /// **'Qty > 0'**
  String get invoiceQtyPositive;

  /// No description provided for @rateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateLabel;

  /// No description provided for @invalidLabel.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalidLabel;

  /// No description provided for @settingsSectionBusiness.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS'**
  String get settingsSectionBusiness;

  /// No description provided for @businessSettings.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettings;

  /// No description provided for @taxSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax Settings'**
  String get taxSettingsTitle;

  /// No description provided for @settingsBusinessSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, address, currency'**
  String get settingsBusinessSettingsSubtitle;

  /// No description provided for @settingsTaxSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'VAT / PAN / tax rate'**
  String get settingsTaxSettingsSubtitle;

  /// No description provided for @settingsSectionTeam.
  ///
  /// In en, this message translates to:
  /// **'TEAM'**
  String get settingsSectionTeam;

  /// No description provided for @userManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagementTitle;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @settingsUserManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite staff, set roles'**
  String get settingsUserManagementSubtitle;

  /// No description provided for @settingsSubscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan, billing details'**
  String get settingsSubscriptionSubtitle;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get settingsSectionPreferences;

  /// No description provided for @englishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLabel;

  /// No description provided for @nepaliLabel.
  ///
  /// In en, this message translates to:
  /// **'Nepali'**
  String get nepaliLabel;

  /// No description provided for @calendarModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar mode'**
  String get calendarModeLabel;

  /// No description provided for @calendarBsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bikram Sambat (BS)'**
  String get calendarBsLabel;

  /// No description provided for @calendarAdLabel.
  ///
  /// In en, this message translates to:
  /// **'Gregorian (AD)'**
  String get calendarAdLabel;

  /// No description provided for @businessTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Business timezone'**
  String get businessTimezoneLabel;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settingsSectionAccount;

  /// No description provided for @settingsProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and edit your profile'**
  String get settingsProfileSubtitle;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get settingsSectionAbout;

  /// No description provided for @settingsSyncDiagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Queue, retries, sync errors'**
  String get settingsSyncDiagnosticsSubtitle;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the login screen.'**
  String get signOutConfirmBody;

  /// No description provided for @signOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutLabel;

  /// No description provided for @myStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'My Store'**
  String get myStoreLabel;

  /// No description provided for @storePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Store Phone'**
  String get storePhoneLabel;

  /// No description provided for @storeAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Store Address'**
  String get storeAddressLabel;

  /// No description provided for @businessTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessTypeLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @authLandingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The digital ledger for your shop.\nFast. Offline. Trusted.'**
  String get authLandingSubtitle;

  /// No description provided for @authLandingFeatureFastSales.
  ///
  /// In en, this message translates to:
  /// **'Record sales in under 10 seconds'**
  String get authLandingFeatureFastSales;

  /// No description provided for @authLandingFeatureOfflineSync.
  ///
  /// In en, this message translates to:
  /// **'Works offline, syncs when connected'**
  String get authLandingFeatureOfflineSync;

  /// No description provided for @authLandingFeatureCreditTracking.
  ///
  /// In en, this message translates to:
  /// **'Track customer credit reliably'**
  String get authLandingFeatureCreditTracking;

  /// No description provided for @authLandingStartFree.
  ///
  /// In en, this message translates to:
  /// **'Start Free'**
  String get authLandingStartFree;

  /// No description provided for @authForgotResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authForgotResetTitle;

  /// No description provided for @authForgotResetBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered phone number and we will send you reset instructions.'**
  String get authForgotResetBody;

  /// No description provided for @authForgotSuccessBanner.
  ///
  /// In en, this message translates to:
  /// **'If an account exists with this number, you will receive reset instructions. Contact support if you need further help.'**
  String get authForgotSuccessBanner;

  /// No description provided for @authForgotBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get authForgotBackToLogin;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @authForgotSendResetInstructions.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Instructions'**
  String get authForgotSendResetInstructions;

  /// No description provided for @authBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get authBackLabel;

  /// No description provided for @authBrandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Business Manager'**
  String get authBrandSubtitle;

  /// No description provided for @businessSettingsAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, City, District'**
  String get businessSettingsAddressHint;

  /// No description provided for @businessSettingsAddressOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get businessSettingsAddressOptionalLabel;

  /// No description provided for @businessSettingsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessSettingsNameLabel;

  /// No description provided for @businessSettingsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get businessSettingsNameRequired;

  /// No description provided for @businessSettingsPhoneOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Phone (optional)'**
  String get businessSettingsPhoneOptionalLabel;

  /// No description provided for @businessSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Check connection and try again.'**
  String get businessSettingsSaveFailed;

  /// No description provided for @businessSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Business settings saved'**
  String get businessSettingsSaved;

  /// No description provided for @businessTypeElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get businessTypeElectronics;

  /// No description provided for @businessTypeGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get businessTypeGrocery;

  /// No description provided for @businessTypePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get businessTypePharmacy;

  /// No description provided for @businessTypeRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get businessTypeRestaurant;

  /// No description provided for @businessTypeRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get businessTypeRetail;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @skipLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipLabel;

  /// No description provided for @otherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherLabel;

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerLabel;

  /// No description provided for @onboardingBusinessTypeGeneralStore.
  ///
  /// In en, this message translates to:
  /// **'General Store'**
  String get onboardingBusinessTypeGeneralStore;

  /// No description provided for @onboardingDefaultMeasurementUnit.
  ///
  /// In en, this message translates to:
  /// **'Default Measurement Unit'**
  String get onboardingDefaultMeasurementUnit;

  /// No description provided for @onboardingDoneOpenStore.
  ///
  /// In en, this message translates to:
  /// **'Done - Open My Store'**
  String get onboardingDoneOpenStore;

  /// No description provided for @onboardingEnableTaxVat.
  ///
  /// In en, this message translates to:
  /// **'Enable Tax (VAT)'**
  String get onboardingEnableTaxVat;

  /// No description provided for @onboardingNoTaxApplied.
  ///
  /// In en, this message translates to:
  /// **'No tax applied'**
  String get onboardingNoTaxApplied;

  /// No description provided for @onboardingSetupStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Your Store'**
  String get onboardingSetupStoreTitle;

  /// No description provided for @onboardingStepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepOfTotal(int step, int total);

  /// No description provided for @onboardingTaxWillApply.
  ///
  /// In en, this message translates to:
  /// **'Tax will be applied to sales'**
  String get onboardingTaxWillApply;

  /// No description provided for @onboardingUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get onboardingUnitKg;

  /// No description provided for @onboardingUnitLitre.
  ///
  /// In en, this message translates to:
  /// **'litre'**
  String get onboardingUnitLitre;

  /// No description provided for @onboardingUnitOverrideHint.
  ///
  /// In en, this message translates to:
  /// **'You can override this per product.'**
  String get onboardingUnitOverrideHint;

  /// No description provided for @onboardingUnitPacket.
  ///
  /// In en, this message translates to:
  /// **'packet'**
  String get onboardingUnitPacket;

  /// No description provided for @onboardingUnitPiece.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get onboardingUnitPiece;

  /// No description provided for @subscriptionFeatureBasicReports.
  ///
  /// In en, this message translates to:
  /// **'Basic Reports'**
  String get subscriptionFeatureBasicReports;

  /// No description provided for @subscriptionFeatureBasicReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales & credit reports'**
  String get subscriptionFeatureBasicReportsSubtitle;

  /// No description provided for @subscriptionFeatureCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get subscriptionFeatureCloudSync;

  /// No description provided for @subscriptionFeatureCloudSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-device sync'**
  String get subscriptionFeatureCloudSyncSubtitle;

  /// No description provided for @subscriptionFeatureCustomerLedger.
  ///
  /// In en, this message translates to:
  /// **'Customer Ledger'**
  String get subscriptionFeatureCustomerLedger;

  /// No description provided for @subscriptionFeatureCustomerLedgerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track credit customers'**
  String get subscriptionFeatureCustomerLedgerSubtitle;

  /// No description provided for @subscriptionFeatureInvoiceGeneration.
  ///
  /// In en, this message translates to:
  /// **'Invoice Generation'**
  String get subscriptionFeatureInvoiceGeneration;

  /// No description provided for @subscriptionFeatureInvoiceGenerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PDF invoices & billing'**
  String get subscriptionFeatureInvoiceGenerationSubtitle;

  /// No description provided for @subscriptionFeatureProductManagement.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get subscriptionFeatureProductManagement;

  /// No description provided for @subscriptionFeatureProductManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to 100 products'**
  String get subscriptionFeatureProductManagementSubtitle;

  /// No description provided for @subscriptionFeatureSalesRecording.
  ///
  /// In en, this message translates to:
  /// **'Sales Recording'**
  String get subscriptionFeatureSalesRecording;

  /// No description provided for @subscriptionFeatureSalesRecordingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited cash & credit sales'**
  String get subscriptionFeatureSalesRecordingSubtitle;

  /// No description provided for @subscriptionFreePlanBadge.
  ///
  /// In en, this message translates to:
  /// **'FREE PLAN'**
  String get subscriptionFreePlanBadge;

  /// No description provided for @subscriptionFreePlanIncludes.
  ///
  /// In en, this message translates to:
  /// **'Free Plan Includes'**
  String get subscriptionFreePlanIncludes;

  /// No description provided for @subscriptionFreePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access core features at no cost'**
  String get subscriptionFreePlanSubtitle;

  /// No description provided for @subscriptionFreePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Naphaa Free'**
  String get subscriptionFreePlanTitle;

  /// No description provided for @subscriptionProComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Pro plan coming soon. Stay tuned!'**
  String get subscriptionProComingSoon;

  /// No description provided for @subscriptionUpgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get subscriptionUpgradeToPro;

  /// No description provided for @taxSettingsEnableVat.
  ///
  /// In en, this message translates to:
  /// **'Enable VAT'**
  String get taxSettingsEnableVat;

  /// No description provided for @taxSettingsEnableVatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply VAT to sales automatically'**
  String get taxSettingsEnableVatSubtitle;

  /// No description provided for @taxSettingsPanHint.
  ///
  /// In en, this message translates to:
  /// **'9-digit PAN'**
  String get taxSettingsPanHint;

  /// No description provided for @taxSettingsPanOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN Number (optional)'**
  String get taxSettingsPanOptionalLabel;

  /// No description provided for @taxSettingsSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Tax Settings'**
  String get taxSettingsSaveAction;

  /// No description provided for @taxSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Try again.'**
  String get taxSettingsSaveFailed;

  /// No description provided for @taxSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Tax settings saved'**
  String get taxSettingsSaved;

  /// No description provided for @taxSettingsVatRateLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT Rate (%)'**
  String get taxSettingsVatRateLabel;

  /// No description provided for @userManagementInviteComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Invitation feature coming soon'**
  String get userManagementInviteComingSoon;

  /// No description provided for @userManagementInviteStaffDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone number of the staff member to invite.'**
  String get userManagementInviteStaffDialogBody;

  /// No description provided for @userManagementInviteStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Invite Staff Member'**
  String get userManagementInviteStaffMember;

  /// No description provided for @userManagementInviteStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite staff to manage your shop'**
  String get userManagementInviteStaffSubtitle;

  /// No description provided for @userManagementInviteStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Staff'**
  String get userManagementInviteStaffTitle;

  /// No description provided for @userManagementNoStaffMembers.
  ///
  /// In en, this message translates to:
  /// **'No staff members yet'**
  String get userManagementNoStaffMembers;

  /// No description provided for @userManagementOwnerFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Owner · Full access'**
  String get userManagementOwnerFullAccess;

  /// No description provided for @userManagementSendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get userManagementSendInvite;

  /// No description provided for @userManagementStaffMembers.
  ///
  /// In en, this message translates to:
  /// **'Staff Members'**
  String get userManagementStaffMembers;

  /// No description provided for @highRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRiskLabel;

  /// No description provided for @mediumRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get mediumRiskLabel;

  /// No description provided for @lowRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRiskLabel;

  /// No description provided for @infoLabel.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infoLabel;

  /// No description provided for @paymentMethodCashLabel.
  ///
  /// In en, this message translates to:
  /// **'CASH'**
  String get paymentMethodCashLabel;

  /// No description provided for @paymentMethodBankLabel.
  ///
  /// In en, this message translates to:
  /// **'BANK'**
  String get paymentMethodBankLabel;

  /// No description provided for @paymentMethodQrLabel.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get paymentMethodQrLabel;

  /// No description provided for @paymentMethodCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'CREDIT'**
  String get paymentMethodCreditLabel;

  /// No description provided for @invoiceStatusDraftLabel.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get invoiceStatusDraftLabel;

  /// No description provided for @invoiceStatusIssuedLabel.
  ///
  /// In en, this message translates to:
  /// **'ISSUED'**
  String get invoiceStatusIssuedLabel;

  /// No description provided for @invoiceStatusPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get invoiceStatusPaidLabel;

  /// No description provided for @invoiceStatusOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get invoiceStatusOverdueLabel;

  /// No description provided for @invoiceStatusCancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get invoiceStatusCancelledLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ne': return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
