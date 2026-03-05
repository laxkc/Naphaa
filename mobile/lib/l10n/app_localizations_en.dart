// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboard => 'Dashboard';

  @override
  String get sales => 'Sales';

  @override
  String get products => 'Products';

  @override
  String get customers => 'Customers';

  @override
  String get expenses => 'Expenses';

  @override
  String get settings => 'Settings';

  @override
  String get reports => 'Reports';

  @override
  String get reportsQuickStatTodaySales => 'Today\'s Sales';

  @override
  String get reportsQuickStatPendingCredit => 'Pending Credit';

  @override
  String get reportsBusinessHealthSubtitle => 'Profit, credit risk, stock health, alerts';

  @override
  String get reportsSalesReportTitle => 'Sales Report';

  @override
  String get reportsSalesReportSubtitle => 'Revenue, transactions by period';

  @override
  String get salesReportTotalRevenue => 'Total Revenue';

  @override
  String salesReportTransactionCount(int count) {
    return '$count transaction(s)';
  }

  @override
  String get salesReportBreakdownByType => 'Breakdown by Type';

  @override
  String get salesReportCashSales => 'Cash Sales';

  @override
  String get salesReportCreditSales => 'Credit Sales';

  @override
  String get reportsProfitReportTitle => 'Profit Report';

  @override
  String get reportsProfitReportSubtitle => 'Gross & net profit breakdown';

  @override
  String get profitReportNetProfit => 'Net Profit';

  @override
  String get profitReportBreakdown => 'Breakdown';

  @override
  String get profitReportEstimatedGrossProfit30 => 'Est. Gross Profit (30%)';

  @override
  String get profitReportTotalExpenses => 'Total Expenses';

  @override
  String get profitReportEstimatedNotice => 'Gross profit is estimated. Connect product cost prices for accurate margin calculation.';

  @override
  String get reportsCreditReportTitle => 'Credit Report';

  @override
  String get reportsCreditReportSubtitle => 'Outstanding customer balances';

  @override
  String get creditReportNoOutstandingTitle => 'No outstanding credit';

  @override
  String get creditReportNoOutstandingSubtitle => 'All customers are settled';

  @override
  String get creditReportTotalOutstanding => 'Total Outstanding';

  @override
  String creditReportCustomerCount(int count) {
    return '$count customer(s)';
  }

  @override
  String creditReportRiskBadge(String label) {
    return '$label Risk';
  }

  @override
  String get reportsCreditAgingSubtitle => 'Outstanding by age buckets and risk';

  @override
  String get reportsAlertsFeedTitle => 'Alerts Feed';

  @override
  String get reportsAlertsFeedSubtitle => 'Actionable risk and business alerts';

  @override
  String get reportsProductInsightsTitle => 'Product Insights';

  @override
  String get reportsProductInsightsSubtitle => 'Profit by product and dead stock';

  @override
  String get productInsightsDeadStockOnly => 'Dead Stock Only';

  @override
  String get productInsightsNoDataTitle => 'No product metrics yet';

  @override
  String get productInsightsNoDataSubtitle => 'Create sales and sync to see product insights';

  @override
  String get productInsightsCachedDataBanner => 'Showing cached product insights (offline). Refresh when internet is available.';

  @override
  String get productInsightsDeadStockItemsLabel => 'Dead Stock Items';

  @override
  String get productInsightsLockedValueLabel => 'Locked Value';

  @override
  String get productInsightsProfitNote => 'Profit is estimated using product cost price (sell price - cost price) x quantity sold. It does not subtract allocated business expenses. Products without cost price are excluded from profit ranking.';

  @override
  String get productInsightsTopProfitProductsTitle => 'Top Profit Products';

  @override
  String get productInsightsProfitLabel => 'Profit';

  @override
  String get productInsightsFastMovers7dTitle => 'Fast Movers (7d)';

  @override
  String get productInsightsQtySold7dLabel => 'Qty sold (7d)';

  @override
  String get productInsightsDeadStockTitle => 'Dead Stock';

  @override
  String get productInsightsNoSalesYet => 'No sales yet';

  @override
  String get productInsightsLastSaleLabel => 'Last sale';

  @override
  String get productInsightsCostNotSet => 'Cost not set';

  @override
  String get productInsightsValueLabel => 'Value';

  @override
  String get reportsInvoicesSubtitle => 'Create, issue and collect invoice payments';

  @override
  String get reportsLedgerTitle => 'Ledger';

  @override
  String get reportsLedgerSubtitle => 'Unified financial audit trail';

  @override
  String get ledgerNoEntriesTitle => 'No ledger entries yet';

  @override
  String get ledgerNoEntriesSubtitle => 'Sales, expenses, payments and refunds will appear here.';

  @override
  String get appName => 'Naphaa';

  @override
  String get newSale => 'New Sale';

  @override
  String get searchProducts => 'Search products';

  @override
  String get saveCashSale => 'Save Cash Sale';

  @override
  String get saveCreditSale => 'Save Credit Sale';

  @override
  String get todaySales => 'Today Sales';

  @override
  String get estimatedProfit => 'Estimated Profit';

  @override
  String get creditOutstanding => 'Credit Outstanding';

  @override
  String get language => 'Language';

  @override
  String get languageSelectionTitle => 'Choose your language';

  @override
  String get languageSelectionSubtitle => 'Start in the language you are most comfortable with. You can change it later in settings.';

  @override
  String get expensesFeatureComingSoon => 'Expenses entry screen coming soon';

  @override
  String get inject100Records => 'Inject 100 realistic records';

  @override
  String get injectedDemoData => 'Inserted 100 realistic test records';

  @override
  String get manageProducts => 'Manage products';

  @override
  String get manageCustomers => 'Manage customers';

  @override
  String get trackExpenses => 'Track expenses';

  @override
  String get addProduct => 'Add Product';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get productName => 'Product name';

  @override
  String get customerName => 'Customer name';

  @override
  String get businessLabel => 'Business';

  @override
  String get phone => 'Phone';

  @override
  String get emailLabel => 'Email';

  @override
  String get panVatLabel => 'PAN/VAT';

  @override
  String get price => 'Price';

  @override
  String get stock => 'Stock';

  @override
  String get amount => 'Amount';

  @override
  String get note => 'Note';

  @override
  String get dateLabel => 'Date';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get createLabel => 'Create';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get dashboardOverview => 'Dashboard overview';

  @override
  String get dashboardSectionPayments => 'Payments';

  @override
  String get dashboardSectionInventory => 'Inventory';

  @override
  String get dashboardSectionCredit => 'Credit';

  @override
  String get dashboardKpiTotalRevenue => 'Total Revenue';

  @override
  String get dashboardKpiTransactionsCount => 'Transactions Count';

  @override
  String get dashboardKpiAverageBill => 'Average Bill';

  @override
  String get dashboardKpiCashCollected => 'Cash Collected';

  @override
  String get dashboardKpiDigitalCollected => 'Digital Collected';

  @override
  String get dashboardKpiCreditCreated => 'Credit Created';

  @override
  String get dashboardKpiCreditCollected => 'Credit Collected';

  @override
  String get dashboardKpiLowStockItems => 'Low Stock Items';

  @override
  String get dashboardKpiInventoryLoss => 'Inventory Loss';

  @override
  String get dashboardKpiTopSellingItems => 'Top Selling Items';

  @override
  String get dashboardKpiCustomersWithDues => 'Customers With Dues';

  @override
  String get dashboardKpiOverdueCredit => 'Overdue Credit';

  @override
  String get dashboardKpiNoTopSelling => 'No top-selling items yet';

  @override
  String get dashboardFirstRunTitle => 'Welcome to Naphaa';

  @override
  String get dashboardFirstRunSubtitle => 'Your store is ready. Add products, record sales, and set up business details from the shortcuts below.';

  @override
  String get dashboardLowStockEmptyNoProducts => 'Add products first. Low-stock tracking starts after your inventory is created.';

  @override
  String get failedToLoadDashboard => 'Failed to load dashboard';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get errorLabel => 'Error';

  @override
  String get criticalLabel => 'Critical';

  @override
  String get warningLabel => 'Warning';

  @override
  String get clearLabel => 'Clear';

  @override
  String get unknownLabel => 'Unknown';

  @override
  String get alertsLabel => 'Alerts';

  @override
  String get openLabel => 'Open';

  @override
  String get alertsFeedMarkAllRead => 'Mark all read';

  @override
  String get alertsFeedMarkRead => 'Mark Read';

  @override
  String get alertsFeedEverythingStableSubtitle => 'Everything looks stable right now';

  @override
  String get alertsActionUnavailable => 'Action not available yet for this alert';

  @override
  String alertCount(int count) {
    return '$count alerts';
  }

  @override
  String alertsCountWithStatus(int count, String status) {
    return '$count alerts ($status)';
  }

  @override
  String get lowStockItemsTitle => 'Low stock items';

  @override
  String get checkingStock => 'Checking stock...';

  @override
  String get unableLoadLowStockData => 'Unable to load low stock data';

  @override
  String get allProductsAboveThreshold => 'All products are above threshold.';

  @override
  String stockLeftCount(String count) {
    return '$count left';
  }

  @override
  String get quickActionsTitle => 'QUICK ACTIONS';

  @override
  String get setupSectionTitle => 'SETUP';

  @override
  String get setupPromptBusinessProfileTitle => 'Complete business profile';

  @override
  String get setupPromptBusinessProfileSubtitle => 'Add your store name, phone, and address so invoices and reports look professional.';

  @override
  String get setupPromptBusinessProfileAction => 'Setup Business';

  @override
  String get setupPromptTaxSettingsTitle => 'Enable tax settings';

  @override
  String get setupPromptTaxSettingsSubtitle => 'Turn on VAT and save your PAN/VAT details before you start issuing tax invoices.';

  @override
  String get setupPromptTaxSettingsAction => 'Configure Tax';

  @override
  String get setupPromptFirstProductTitle => 'Add your first product';

  @override
  String get setupPromptFirstProductSubtitle => 'Create products first so sales, stock, and low-stock alerts work correctly.';

  @override
  String get setupPromptFirstProductAction => 'Add Product';

  @override
  String get setupPromptFirstCustomerTitle => 'Add your first customer';

  @override
  String get setupPromptFirstCustomerSubtitle => 'Save customer details now if you plan to track credit sales and collections.';

  @override
  String get setupPromptFirstCustomerAction => 'Add Customer';

  @override
  String get setupPromptInvoicePrefixTitle => 'Set your invoice prefix';

  @override
  String get setupPromptInvoicePrefixSubtitle => 'Customize invoice numbering before you start issuing bills to customers.';

  @override
  String get setupPromptInvoicePrefixAction => 'Open Invoices';

  @override
  String get recordPay => 'Record Pay';

  @override
  String get businessHealth => 'Business Health';

  @override
  String get businessHealthCachedDataBanner => 'Showing cached intelligence data (offline). Pull to refresh when internet is available.';

  @override
  String get businessHealthProfitSnapshotTitle => 'Profit Snapshot';

  @override
  String get businessHealthEstimatedProfitLabel => 'Est. Profit';

  @override
  String get businessHealthOutstandingCreditLabel => 'Outstanding Credit';

  @override
  String get businessHealthProfitMarginLabel => 'Profit Margin';

  @override
  String get businessHealthCashRiskLabel => 'Cash Risk';

  @override
  String get businessHealthCashOutlookTitle => 'Cash Outlook';

  @override
  String get businessHealthExpectedIncomingLabel => 'Expected Incoming';

  @override
  String get businessHealthExpectedOutgoingLabel => 'Expected Outgoing';

  @override
  String businessHealthNetOutlookNextDays(int days, Object amount) {
    return 'Next $days days net outlook: NPR $amount';
  }

  @override
  String get businessHealthProfitSnapshotNote => 'Estimated Profit here is a simple operational snapshot (today sales - today expenses). Product-level profit reports use cost price and may not match this total exactly.';

  @override
  String get businessHealthCreditRiskSummaryTitle => 'Credit Risk Summary';

  @override
  String get businessHealthStockHealthTitle => 'Stock Health';

  @override
  String get businessHealthFastMoversTitle => 'Fast Movers';

  @override
  String get businessHealthAlertsPreviewTitle => 'Alerts Preview';

  @override
  String businessHealthDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get businessHealthNoLowStockAlerts => 'No low stock alerts right now';

  @override
  String businessHealthLowStockItemsCount(int count) {
    return '$count low-stock items';
  }

  @override
  String get businessHealthNoActiveAlerts => 'No active alerts';

  @override
  String get businessHealthNoFastMovers7d => 'No fast movers in the last 7 days';

  @override
  String get businessHealthSevenDayQtySoldLabel => '7-day quantity sold';

  @override
  String get thresholdLabel => 'Threshold';

  @override
  String get revenueLabel => 'Revenue';

  @override
  String get customerLabel => 'Customer';

  @override
  String get creditAging => 'Credit Aging';

  @override
  String get creditAgingOverdueOnly => 'Overdue Only';

  @override
  String get creditAgingHighRiskOnly => 'High Risk Only';

  @override
  String get creditAgingNoDataTitle => 'No credit aging data';

  @override
  String get creditAgingNoDataSubtitle => 'No customers match the selected filters';

  @override
  String get creditAgingCachedDataBanner => 'Showing cached credit aging data (offline). Refresh when internet is available.';

  @override
  String get creditAgingSummaryTitle => 'Credit Aging Summary';

  @override
  String get creditAgingOutstandingLabel => 'Outstanding';

  @override
  String get creditAgingOverdueLabel => 'Overdue';

  @override
  String creditAgingHighRiskCustomersCount(int count) {
    return '$count high-risk customers';
  }

  @override
  String get creditAgingBucketsTitle => 'Aging Buckets';

  @override
  String get creditAgingBucket0to7 => '0–7 days';

  @override
  String get creditAgingBucket8to30 => '8–30 days';

  @override
  String get creditAgingBucket31to60 => '31–60 days';

  @override
  String get creditAgingBucket60Plus => '60+ days';

  @override
  String get creditAgingOldestDueLabel => 'Oldest Due';

  @override
  String creditAgingDaysCount(int count) {
    return '$count days';
  }

  @override
  String get invoices => 'Invoices';

  @override
  String get invoiceLabel => 'Invoice';

  @override
  String get invoicePdfTitle => 'INVOICE';

  @override
  String get draftLabel => 'DRAFT';

  @override
  String get invoiceDueShortLabel => 'Due';

  @override
  String get invoiceListNewInvoice => 'New Invoice';

  @override
  String get invoiceListNoInvoicesTitle => 'No invoices yet';

  @override
  String get invoiceListNoInvoicesSubtitle => 'Create your first invoice and issue it offline.';

  @override
  String get invoiceListCreateInvoiceAction => 'Create Invoice';

  @override
  String get invoiceListDraftFallback => 'Draft';

  @override
  String get invoiceListDraftNotIssued => 'Draft (not issued)';

  @override
  String invoiceListTotalsSummary(Object total, Object balance) {
    return 'Total: NPR $total   •   Balance: NPR $balance';
  }

  @override
  String get netAfterExpenses => 'Net after expenses';

  @override
  String get cashflowHealth => 'Cashflow health';

  @override
  String get creditExposure => 'Credit exposure';

  @override
  String get healthy => 'Healthy';

  @override
  String get watchlist => 'Watchlist';

  @override
  String get risky => 'Risky';

  @override
  String get authTitle => 'Sign in to Naphaa';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign up';

  @override
  String get password => 'Password';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get store => 'Store';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get createAccount => 'Create account';

  @override
  String get startManagingYourBusiness => 'Start managing your business today';

  @override
  String get businessName => 'Business name';

  @override
  String get businessNameHint => 'e.g. My Shop, Sunrise Store';

  @override
  String get passwordHint => 'Min. 8 characters';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get businessNameTooShort => 'Business name must be at least 3 characters';

  @override
  String get invalidPhone => 'Enter a valid 10-digit phone number';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get back => 'Back';

  @override
  String get signIn => 'Sign in';

  @override
  String get switchToSignup => 'Switch to signup';

  @override
  String get switchToLogin => 'Switch to login';

  @override
  String get forgotPasswordHint => 'Please contact support to reset your password.';

  @override
  String get authOtpTitle => 'Continue with your phone number';

  @override
  String get authOtpSubtitle => 'Enter your mobile number. We will send a one-time code to sign in or create your account automatically.';

  @override
  String get authSendOtp => 'Send OTP';

  @override
  String get authVerifyOtpTitle => 'Verify your OTP';

  @override
  String get authOtpCodeLabel => 'One-time code';

  @override
  String get authVerifyOtp => 'Verify and continue';

  @override
  String get authResendOtp => 'Resend OTP';

  @override
  String get authChangePhone => 'Change phone';

  @override
  String get authOtpInvalidCode => 'Enter a valid code';

  @override
  String get authOtpAutoCreateBody => 'New phone numbers create an account automatically with default business settings. Existing numbers sign in directly.';

  @override
  String authOtpSentTo(Object phone) {
    return 'We sent a code to $phone';
  }

  @override
  String authOtpDebugCode(Object code) {
    return 'Debug OTP: $code';
  }

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get syncingShort => 'Syncing…';

  @override
  String syncingChanges(int count) {
    return 'Syncing $count changes…';
  }

  @override
  String get todayLabel => 'Today';

  @override
  String get yearLabel => 'Year';

  @override
  String get monthLabel => 'Month';

  @override
  String get dayLabel => 'Day';

  @override
  String get invoicePickBsDateTitle => 'Enter BS date';

  @override
  String get invalidBsDate => 'Enter a valid BS date';

  @override
  String get thisWeekLabel => 'This Week';

  @override
  String get thisMonthLabel => 'This Month';

  @override
  String get allLabel => 'All';

  @override
  String get walkInCustomer => 'Walk-in Customer';

  @override
  String get nprLabel => 'NPR';

  @override
  String get itemsLabel => 'Items';

  @override
  String get paymentsLabel => 'Payments';

  @override
  String get totalLabel => 'Total';

  @override
  String get totalAmountLabel => 'Total Amount';

  @override
  String get saleDetailsTitle => 'Sale Details';

  @override
  String get saleNotFoundTitle => 'Sale not found';

  @override
  String get saleNotFoundSubtitle => 'This sale may have been removed';

  @override
  String get salesNoSalesYetTitle => 'No sales yet';

  @override
  String get salesNoSalesYetTodaySubtitle => 'Tap + to record your first sale today';

  @override
  String get salesNoTransactionsInPeriodSubtitle => 'No transactions in this period';

  @override
  String get salesNoProductsYetTitle => 'No products yet';

  @override
  String get salesNoProductsQuickCreateHint => 'Search a product name and quick create it from here.';

  @override
  String salesNoMatchForQuery(Object query) {
    return 'No match for \"$query\"';
  }

  @override
  String get salesCreateProductQuicklyCta => 'Create Product Quickly';

  @override
  String salesCreateProductQuicklyFor(Object query) {
    return 'Create \"$query\" quickly';
  }

  @override
  String get salesCreateProductQuicklySubtitle => 'Enter only selling price and continue sale';

  @override
  String get salesQuickAddProductTitle => 'Quick Add Product';

  @override
  String get salesQuickCreditCustomerTitle => 'Quick Credit Customer';

  @override
  String get salesCreditRiskWarningTitle => 'Credit Risk Warning';

  @override
  String salesCreditRiskExistingCustomerMarked(Object name, Object label) {
    return 'Existing customer \"$name\" is marked $label.';
  }

  @override
  String salesCreditRiskOutstandingNpr(Object amount) {
    return 'Outstanding: NPR $amount';
  }

  @override
  String salesCreditRiskOldestDueDays(int count) {
    return 'Oldest due: $count days';
  }

  @override
  String salesCreditRiskScore(Object score) {
    return 'Risk score: $score';
  }

  @override
  String get salesCreditRiskContinueWarning => 'Continue only if you are comfortable extending more credit.';

  @override
  String salesCartItemsCount(int count) {
    return '$count items';
  }

  @override
  String get searchCustomersHint => 'Search customers…';

  @override
  String get failedToLoadCustomers => 'Failed to load customers';

  @override
  String get noCustomersFoundTitle => 'No customers found';

  @override
  String get customersEmptySubtitle => 'Tap \"Add Customer\" to get started.';

  @override
  String get customersTryDifferentSearchSubtitle => 'Try a different name or phone number.';

  @override
  String get deleteCustomerDialogTitle => 'Delete customer?';

  @override
  String customerDeletePermanentBody(String name) {
    return '\"$name\" will be permanently removed.';
  }

  @override
  String get owesYouLabel => 'owes you';

  @override
  String get creditLabel => 'credit';

  @override
  String get recordPaymentTooltip => 'Record payment';

  @override
  String get editCustomerTitle => 'Edit Customer';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get customerNameRequired => 'Name is required';

  @override
  String get phoneOptionalLabel => 'Phone Number (optional)';

  @override
  String get addressOptionalLabel => 'Address (optional)';

  @override
  String get streetCityHint => 'Street, City';

  @override
  String get notesOptionalLabel => 'Notes (optional)';

  @override
  String get customerNotesHint => 'Any additional notes';

  @override
  String get customerSaveFailedTryAgain => 'Failed to save customer. Try again.';

  @override
  String get searchProductsHint => 'Search products…';

  @override
  String get failedToLoadProducts => 'Failed to load products';

  @override
  String get productsEmptySubtitle => 'Tap \"Add Product\" to get started.';

  @override
  String get deleteProductDialogTitle => 'Delete product?';

  @override
  String productDeletePermanentBody(String name) {
    return '\"$name\" will be permanently removed.';
  }

  @override
  String get lowStockBadgeLabel => 'Low stock';

  @override
  String get rsLabel => 'Rs';

  @override
  String get adjustStockLabel => 'Adjust Stock';

  @override
  String get editProductTitle => 'Edit Product';

  @override
  String get productNameLabel => 'Product Name';

  @override
  String get productNameRequired => 'Name is required';

  @override
  String get categoryOptionalLabel => 'Category (optional)';

  @override
  String get productCategoryHint => 'e.g. Snacks, Beverages';

  @override
  String get sellPriceLabel => 'Sell Price';

  @override
  String get enterValidPrice => 'Enter valid price';

  @override
  String get costPriceLabel => 'Cost Price';

  @override
  String get openingStockLabel => 'Opening Stock';

  @override
  String get lowStockThresholdLabel => 'Low Stock Threshold';

  @override
  String get lowStockThresholdHint => '0 to disable alert';

  @override
  String get enterValidThreshold => 'Enter a valid threshold';

  @override
  String get unitLabel => 'Unit';

  @override
  String get productSaveFailedTryAgain => 'Failed to save product. Try again.';

  @override
  String get productDetailsTitle => 'Product Details';

  @override
  String get productNotFoundTitle => 'Product not found';

  @override
  String get productNotFoundSubtitle => 'This product may have been removed';

  @override
  String get marginLabel => 'Margin';

  @override
  String get stockHistoryTitle => 'Stock History';

  @override
  String get noStockMovementsYetTitle => 'No stock movements yet';

  @override
  String get customerDetailsTitle => 'Customer Details';

  @override
  String get customerNotFoundTitle => 'Customer not found';

  @override
  String get customerNotFoundSubtitle => 'This customer may have been removed';

  @override
  String get outstandingBalanceLabel => 'Outstanding Balance';

  @override
  String get recordPaymentLabel => 'Record Payment';

  @override
  String get transactionHistoryTitle => 'Transaction History';

  @override
  String get loadingTransactions => 'Loading transactions...';

  @override
  String get failedToLoadCustomerTransactions => 'Failed to load customer transactions';

  @override
  String get noTransactionsYetTitle => 'No transactions yet';

  @override
  String get paymentReceivedLabel => 'Payment Received';

  @override
  String get creditSaleLabel => 'Credit Sale';

  @override
  String get riskExplanationTitle => 'Risk Explanation';

  @override
  String get oldestOverdueLabel => 'Oldest overdue';

  @override
  String get averageDaysToPayLabel => 'Average days to pay';

  @override
  String get onTimeRateLabel => 'On-time rate';

  @override
  String get outstandingSpikeLabel => 'Outstanding spike';

  @override
  String daysValue(int count) {
    return '$count days';
  }

  @override
  String daysValueDecimal(String value) {
    return '$value days';
  }

  @override
  String oldestDueChipDays(int days) {
    return 'Oldest due: ${days}d';
  }

  @override
  String get highLabel => 'High';

  @override
  String get mediumLabel => 'Medium';

  @override
  String get lowLabel => 'Low';

  @override
  String get normalLabel => 'Normal';

  @override
  String get failedToLoadExpenses => 'Failed to load expenses';

  @override
  String get expensesEmptySubtitle => 'Tap \"Add Expense\" to record your first expense.';

  @override
  String get expenseCategoryRent => 'Rent';

  @override
  String get expenseCategoryTransport => 'Transport';

  @override
  String get expenseCategoryUtilities => 'Utilities';

  @override
  String get expenseCategorySalary => 'Salary';

  @override
  String get expenseCategoryOther => 'Other';

  @override
  String get categoryLabel => 'Category';

  @override
  String failedToSaveWithError(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get amountCannotExceedOutstandingBalance => 'Amount cannot exceed outstanding balance';

  @override
  String get paymentRecordedSuccessfully => 'Payment recorded successfully';

  @override
  String get failedToRecordPaymentTryAgain => 'Failed to record payment. Try again.';

  @override
  String get creditCustomerLabel => 'Credit Customer';

  @override
  String get paymentDetailsTitle => 'Payment Details';

  @override
  String get amountReceivedLabel => 'Amount Received';

  @override
  String get fullLabel => 'Full';

  @override
  String get paymentMethodLabelTitle => 'Payment Method';

  @override
  String get balanceLabel => 'Balance';

  @override
  String get notesLabel => 'Notes';

  @override
  String get typeLabel => 'Type';

  @override
  String get addStockLabel => 'Add Stock';

  @override
  String get removeStockLabel => 'Remove Stock';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get egTenHint => 'e.g. 10';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get additionalDetailsHint => 'Additional details…';

  @override
  String get saveAdjustmentLabel => 'Save Adjustment';

  @override
  String get enterValidQuantity => 'Enter a valid quantity';

  @override
  String get failedToAdjustStockTryAgain => 'Failed to adjust stock. Try again.';

  @override
  String currentStockValue(String value) {
    return 'Current stock: $value';
  }

  @override
  String get serverHasNewerDataPullRetry => 'Server has newer data. Pull latest and retry.';

  @override
  String get syncFailedWillRetry => 'Sync failed. Will retry.';

  @override
  String pendingChangesCount(int count) {
    return '$count pending changes';
  }

  @override
  String get pullRetryShort => 'Pull+Retry';

  @override
  String get syncNowLabel => 'Sync now';

  @override
  String get syncDiagnosticsTitle => 'Sync Diagnostics';

  @override
  String get clearFailedRowsTooltip => 'Clear Failed Rows';

  @override
  String get clearFailedRowsConfirmTitle => 'Clear failed sync rows?';

  @override
  String get clearFailedRowsConfirmBody => 'This is for demo/testing cleanup. Failed offline changes will be removed from the local sync queue.';

  @override
  String get clearFailedAction => 'Clear Failed';

  @override
  String clearedFailedRowsCount(int count) {
    return 'Cleared $count failed sync rows';
  }

  @override
  String get retrySyncTooltip => 'Retry Sync';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get ackedLabel => 'Acked';

  @override
  String get failedLabel => 'Failed';

  @override
  String syncDiagnosticsFailedRowsBanner(int count) {
    return '$count sync rows failed. Retry sync or open a row for details.';
  }

  @override
  String syncDiagnosticsInvalidRowsBanner(int count) {
    return '$count offline changes are invalid and could not be synced.';
  }

  @override
  String get noSyncQueueItemsTitle => 'No sync queue items';

  @override
  String get noSyncQueueItemsSubtitle => 'Offline changes and sync errors will appear here.';

  @override
  String retryCountShort(int count) {
    return 'retry $count';
  }

  @override
  String get statusLabel => 'Status';

  @override
  String get entityIdLabel => 'Entity ID';

  @override
  String get opIdLabel => 'Op ID';

  @override
  String get retriesLabel => 'Retries';

  @override
  String get createdLabel => 'Created';

  @override
  String get updatedLabel => 'Updated';

  @override
  String get lastErrorLabel => 'Last Error';

  @override
  String get copiedErrorDetails => 'Copied error details';

  @override
  String get copyLabel => 'Copy';

  @override
  String get retry => 'Retry';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get itemLabel => 'Item';

  @override
  String get termsLabel => 'Terms';

  @override
  String get pdfGenerationFailedPrefix => 'PDF generation failed';

  @override
  String syncTelemetrySummary(int acked, int failed, int pulled, int durationMs) {
    return 'ack $acked • fail $failed • pull $pulled • ${durationMs}ms';
  }

  @override
  String get invoiceDetailTitle => 'Invoice Details';

  @override
  String get invoiceDetailNotFound => 'Invoice not found';

  @override
  String get invoiceDetailDraftFallback => 'Draft Invoice';

  @override
  String get invoiceIssueDateLabel => 'Issue Date';

  @override
  String get invoiceNotIssued => 'Not issued';

  @override
  String get invoiceDueDateLabel => 'Due Date';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get discountLabel => 'Discount';

  @override
  String get vatLabel => 'VAT';

  @override
  String get paidLabel => 'Paid';

  @override
  String get invoiceDetailNoItems => 'No items';

  @override
  String get invoicePaymentsTitle => 'Payments';

  @override
  String get invoicePaymentsEmpty => 'No payments recorded';

  @override
  String get actionsLabel => 'Actions';

  @override
  String get issueLabel => 'Issue';

  @override
  String get invoiceRecordPaymentLabel => 'Record Payment';

  @override
  String get invoicePdfRetry => 'Retry PDF';

  @override
  String get invoicePdfRegenerate => 'Regenerate PDF';

  @override
  String get invoicePdfGenerate => 'Generate PDF';

  @override
  String get invoicePdfShare => 'Share PDF';

  @override
  String get printLabel => 'Print';

  @override
  String get invoiceIssuedSuccess => 'Invoice issued successfully';

  @override
  String get invoicePdfGeneratedSuccess => 'PDF generated successfully';

  @override
  String invoiceBalanceSummary(String value) {
    return 'Balance: $value';
  }

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get invoiceEnterValidAmount => 'Enter a valid amount';

  @override
  String get invoicePaymentRecordedSuccess => 'Payment recorded';

  @override
  String get invoiceCreateTitle => 'Create Invoice';

  @override
  String get invoiceDetailsTitle => 'Invoice Details';

  @override
  String get invoiceCustomerIdOptional => 'Customer ID (optional)';

  @override
  String get invoiceDiscountLabel => 'Invoice Discount';

  @override
  String get invoiceAddLine => 'Add Line';

  @override
  String get invoiceSaveDraft => 'Save Draft';

  @override
  String get invoiceIssuing => 'Issuing...';

  @override
  String get invoiceIssueAction => 'Issue Invoice';

  @override
  String get invoiceNoActiveStore => 'No active business/store found. Please login again.';

  @override
  String get invoiceAddAtLeastOneItem => 'Add at least one item';

  @override
  String get invoiceLineItemName => 'Item name';

  @override
  String get requiredLabel => 'Required';

  @override
  String get invoiceProductIdOptional => 'Product ID (optional)';

  @override
  String get qtyLabel => 'Qty';

  @override
  String get invoiceQtyPositive => 'Qty > 0';

  @override
  String get rateLabel => 'Rate';

  @override
  String get invalidLabel => 'Invalid';

  @override
  String get settingsSectionBusiness => 'BUSINESS';

  @override
  String get businessSettings => 'Business Settings';

  @override
  String get billingSettingsTitle => 'Billing Settings';

  @override
  String get billingSettingsSubtitle => 'Invoice prefix, language, tax mode, and default notes';

  @override
  String get settingsBillingSettingsSubtitle => 'Invoice prefix, terms, footer';

  @override
  String get billingSettingsInvoicePrefixLabel => 'Invoice Prefix';

  @override
  String get billingSettingsInvoicePrefixRequired => 'Invoice prefix is required';

  @override
  String get billingSettingsTaxModeLabel => 'Tax Mode';

  @override
  String get billingSettingsTaxModeExclusive => 'Exclusive';

  @override
  String get billingSettingsTaxModeInclusive => 'Inclusive';

  @override
  String get billingSettingsTermsDefaultLabel => 'Default Terms';

  @override
  String get billingSettingsTermsDefaultHint => 'Payment due within 7 days';

  @override
  String get billingSettingsFooterDefaultLabel => 'Default Footer';

  @override
  String get billingSettingsFooterDefaultHint => 'Thank you for your business';

  @override
  String get billingSettingsSaved => 'Billing settings saved';

  @override
  String get billingSettingsSaveFailed => 'Failed to save billing settings. Try again.';

  @override
  String get taxSettingsTitle => 'Tax Settings';

  @override
  String get settingsBusinessSettingsSubtitle => 'Name, address, currency';

  @override
  String get settingsTaxSettingsSubtitle => 'VAT / PAN / tax rate';

  @override
  String get settingsSectionTeam => 'TEAM';

  @override
  String get userManagementTitle => 'User Management';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get settingsUserManagementSubtitle => 'Invite staff, set roles';

  @override
  String get settingsSubscriptionSubtitle => 'Plan, billing details';

  @override
  String get settingsSectionPreferences => 'PREFERENCES';

  @override
  String get englishLabel => 'English';

  @override
  String get nepaliLabel => 'Nepali';

  @override
  String get calendarModeLabel => 'Calendar mode';

  @override
  String get calendarBsLabel => 'Bikram Sambat (BS)';

  @override
  String get calendarAdLabel => 'Gregorian (AD)';

  @override
  String get businessTimezoneLabel => 'Business timezone';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsProfileSubtitle => 'View and edit your profile';

  @override
  String get settingsSectionAbout => 'ABOUT';

  @override
  String get settingsSyncDiagnosticsSubtitle => 'Queue, retries, sync errors';

  @override
  String get versionLabel => 'Version';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody => 'You will be returned to the login screen.';

  @override
  String get signOutLabel => 'Sign out';

  @override
  String get myStoreLabel => 'My Store';

  @override
  String get storePhoneLabel => 'Store Phone';

  @override
  String get storeAddressLabel => 'Store Address';

  @override
  String get businessTypeLabel => 'Business Type';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get roleLabel => 'Role';

  @override
  String get authLandingSubtitle => 'The digital ledger for your shop.\nFast. Offline. Trusted.';

  @override
  String get authLandingFeatureFastSales => 'Record sales in under 10 seconds';

  @override
  String get authLandingFeatureOfflineSync => 'Works offline, syncs when connected';

  @override
  String get authLandingFeatureCreditTracking => 'Track customer credit reliably';

  @override
  String get authLandingStartFree => 'Start Free';

  @override
  String get authForgotResetTitle => 'Reset your password';

  @override
  String get authForgotResetBody => 'Enter your registered phone number and we will send you reset instructions.';

  @override
  String get authForgotSuccessBanner => 'If an account exists with this number, you will receive reset instructions. Contact support if you need further help.';

  @override
  String get authForgotBackToLogin => 'Back to Login';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get authForgotSendResetInstructions => 'Send Reset Instructions';

  @override
  String get authBackLabel => 'Back';

  @override
  String get authBrandSubtitle => 'Business Manager';

  @override
  String get businessSettingsAddressHint => 'Street, City, District';

  @override
  String get businessSettingsAddressOptionalLabel => 'Address (optional)';

  @override
  String get businessSettingsNameLabel => 'Business Name';

  @override
  String get businessSettingsNameRequired => 'Name is required';

  @override
  String get businessSettingsPhoneOptionalLabel => 'Business Phone (optional)';

  @override
  String get businessSettingsSaveFailed => 'Failed to save. Check connection and try again.';

  @override
  String get businessSettingsSaved => 'Business settings saved';

  @override
  String get businessTypeElectronics => 'Electronics';

  @override
  String get businessTypeGrocery => 'Grocery';

  @override
  String get businessTypePharmacy => 'Pharmacy';

  @override
  String get businessTypeRestaurant => 'Restaurant';

  @override
  String get businessTypeRetail => 'Retail';

  @override
  String get nextLabel => 'Next';

  @override
  String get skipLabel => 'Skip';

  @override
  String get otherLabel => 'Other';

  @override
  String get ownerLabel => 'Owner';

  @override
  String get onboardingBusinessTypeGeneralStore => 'General Store';

  @override
  String get onboardingDefaultMeasurementUnit => 'Default Measurement Unit';

  @override
  String get onboardingDoneOpenStore => 'Done - Open My Store';

  @override
  String get onboardingEnableTaxVat => 'Enable Tax (VAT)';

  @override
  String get onboardingNoTaxApplied => 'No tax applied';

  @override
  String get onboardingSetupStoreTitle => 'Setup Your Store';

  @override
  String onboardingStepOfTotal(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingTaxWillApply => 'Tax will be applied to sales';

  @override
  String get onboardingUnitKg => 'kg';

  @override
  String get onboardingUnitLitre => 'litre';

  @override
  String get onboardingUnitOverrideHint => 'You can override this per product.';

  @override
  String get onboardingUnitPacket => 'packet';

  @override
  String get onboardingUnitPiece => 'piece';

  @override
  String get subscriptionFeatureBasicReports => 'Basic Reports';

  @override
  String get subscriptionFeatureBasicReportsSubtitle => 'Sales & credit reports';

  @override
  String get subscriptionFeatureCloudSync => 'Cloud Sync';

  @override
  String get subscriptionFeatureCloudSyncSubtitle => 'Multi-device sync';

  @override
  String get subscriptionFeatureCustomerLedger => 'Customer Ledger';

  @override
  String get subscriptionFeatureCustomerLedgerSubtitle => 'Track credit customers';

  @override
  String get subscriptionFeatureInvoiceGeneration => 'Invoice Generation';

  @override
  String get subscriptionFeatureInvoiceGenerationSubtitle => 'PDF invoices & billing';

  @override
  String get subscriptionFeatureProductManagement => 'Product Management';

  @override
  String get subscriptionFeatureProductManagementSubtitle => 'Up to 100 products';

  @override
  String get subscriptionFeatureSalesRecording => 'Sales Recording';

  @override
  String get subscriptionFeatureSalesRecordingSubtitle => 'Unlimited cash & credit sales';

  @override
  String get subscriptionFreePlanBadge => 'FREE PLAN';

  @override
  String get subscriptionFreePlanIncludes => 'Free Plan Includes';

  @override
  String get subscriptionFreePlanSubtitle => 'Access core features at no cost';

  @override
  String get subscriptionFreePlanTitle => 'Naphaa Free';

  @override
  String get subscriptionProComingSoon => 'Pro plan coming soon. Stay tuned!';

  @override
  String get subscriptionUpgradeToPro => 'Upgrade to Pro';

  @override
  String get taxSettingsEnableVat => 'Enable VAT';

  @override
  String get taxSettingsEnableVatSubtitle => 'Apply VAT to sales automatically';

  @override
  String get taxSettingsPanHint => '9-digit PAN';

  @override
  String get taxSettingsPanOptionalLabel => 'PAN Number (optional)';

  @override
  String get taxSettingsSaveAction => 'Save Tax Settings';

  @override
  String get taxSettingsSaveFailed => 'Failed to save. Try again.';

  @override
  String get taxSettingsSaved => 'Tax settings saved';

  @override
  String get taxSettingsVatRateLabel => 'VAT Rate (%)';

  @override
  String get userManagementInviteComingSoon => 'Invitation feature coming soon';

  @override
  String get userManagementInviteStaffDialogBody => 'Enter the phone number of the staff member to invite.';

  @override
  String get userManagementInviteStaffMember => 'Invite Staff Member';

  @override
  String get userManagementInviteStaffSubtitle => 'Invite staff to manage your shop';

  @override
  String get userManagementInviteStaffTitle => 'Invite Staff';

  @override
  String get userManagementNoStaffMembers => 'No staff members yet';

  @override
  String get userManagementOwnerFullAccess => 'Owner · Full access';

  @override
  String get userManagementSendInvite => 'Send Invite';

  @override
  String get userManagementStaffMembers => 'Staff Members';

  @override
  String get highRiskLabel => 'High Risk';

  @override
  String get mediumRiskLabel => 'Medium Risk';

  @override
  String get lowRiskLabel => 'Low Risk';

  @override
  String get infoLabel => 'Info';

  @override
  String get paymentMethodCashLabel => 'CASH';

  @override
  String get paymentMethodBankLabel => 'BANK';

  @override
  String get paymentMethodQrLabel => 'QR';

  @override
  String get paymentMethodCreditLabel => 'CREDIT';

  @override
  String get invoiceStatusDraftLabel => 'DRAFT';

  @override
  String get invoiceStatusIssuedLabel => 'ISSUED';

  @override
  String get invoiceStatusPaidLabel => 'PAID';

  @override
  String get invoiceStatusOverdueLabel => 'OVERDUE';

  @override
  String get invoiceStatusCancelledLabel => 'CANCELLED';

  @override
  String get dashboardGreetingMorning => 'Good morning,';

  @override
  String get dashboardGreetingAfternoon => 'Good afternoon,';

  @override
  String get dashboardGreetingEvening => 'Good evening,';

  @override
  String get dashboardMoreActions => 'More actions';

  @override
  String get dashboardLessActions => 'Less';
}
