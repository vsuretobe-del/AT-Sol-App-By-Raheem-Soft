/// Central configuration for the AT Sol mobile app.
///
/// The default server URL points to where the AT Sol web software is hosted.
/// Users can change it on the login screen at any time.
class AppConfig {
  static const String appName = 'AT Sol';
  static const String appTagline = 'Ahsan Traders Solutions';

  /// Default server base URL. Change this to your hosted software address,
  /// e.g. https://yourdomain.com/atsol  (no trailing slash)
  static const String defaultServerUrl = 'https://yourdomain.com/atsol';

  // API endpoints (relative to server URL)
  static const String epLogin = '/api/login.php';
  static const String epLogout = '/api/logout.php';
  static const String epChangePassword = '/api/change_password.php';
  static const String epVerifyPassword = '/api/verify_password.php';
  static const String epUsers = '/api/users.php';
  static const String epSummary = '/api/mobile_summary.php';

  static const String epSalesList = '/api/get_sales.php';
  static const String epSaleSave = '/api/save_sale.php';
  static const String epSaleDelete = '/api/delete_sale.php';
  static const String epSaleNextCode = '/api/get_next_sale_code.php';
  static const String epSaleReturnsList = '/api/get_sale_returns.php';
  static const String epSaleReturnSave = '/api/save_sale_return.php';
  static const String epPendingInvoices = '/api/get_pending_invoices.php';

  static const String epPurchasesList = '/api/get_purchases.php';
  static const String epPurchaseSave = '/api/save_purchase.php';
  static const String epPurchaseDelete = '/api/delete_purchase.php';
  static const String epPoList = '/api/get_purchase_orders.php';
  static const String epPoSave = '/api/save_purchase_order.php';
  static const String epPoDelete = '/api/delete_pur_order.php';
  static const String epPurReturnsList = '/api/get_pur_returns.php';
  static const String epPurReturnSave = '/api/save_pur_return.php';
  static const String epPurReturnDelete = '/api/delete_pur_return.php';

  static const String epTransactions = '/api/get_transactions.php';
  static const String epTransactionSave = '/api/save_transaction.php';
  static const String epTransactionDelete = '/api/delete_transaction.php';
  static const String epBankCash = '/api/get_bank_cash.php';
  static const String epCoaHierarchy = '/api/get_coa_hierarchy.php';

  static const String epCustomers = '/api/customer.php';
  static const String epSuppliers = '/api/supplier.php';
  static const String epDealers = '/api/dealer.php';
  static const String epItems = '/api/item.php';
  static const String epItemGroups = '/api/item_group.php';
  static const String epMeasurements = '/api/measurement.php';
  static const String epGodowns = '/api/godown.php';
  static const String epAreas = '/api/area.php';
  static const String epZones = '/api/zone.php';
  static const String epTransporters = '/api/transporter.php';
  static const String epSaleTypes = '/api/sale_type.php';
  static const String epBankAccounts = '/api/bank_account.php';
  static const String epCashAccounts = '/api/cash_account.php';
  static const String epSuppliersList = '/api/get_suppliers_list.php';

  static const String epReportAccounting = '/api/reports/accounting.php';
  static const String epReportStock = '/api/reports/stock.php';
  static const String epReportRegisters = '/api/reports/registers.php';
  static const String epReportFinancials = '/api/reports/financials.php';
}
