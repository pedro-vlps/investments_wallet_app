import 'package:sqlite3/sqlite3.dart';

void initializeTaxSchema(Database database) {
  database.execute('''CREATE TABLE IF NOT EXISTS tax_months (
    year INTEGER NOT NULL, month INTEGER NOT NULL CHECK(month BETWEEN 1 AND 12),
    stock_sales INTEGER NOT NULL, stock_result INTEGER NOT NULL,
    other_common_result INTEGER NOT NULL, day_trade_result INTEGER NOT NULL,
    fund_result INTEGER NOT NULL, common_withheld INTEGER NOT NULL,
    day_trade_withheld INTEGER NOT NULL, fund_withheld INTEGER NOT NULL,
    paid INTEGER NOT NULL, notes TEXT NOT NULL,
    PRIMARY KEY(year, month))''');
  database.execute('''CREATE TABLE IF NOT EXISTS tax_openings (
    year INTEGER PRIMARY KEY, common_loss INTEGER NOT NULL,
    day_trade_loss INTEGER NOT NULL, fund_loss INTEGER NOT NULL,
    small_darf INTEGER NOT NULL)''');
  database.execute('''CREATE TABLE IF NOT EXISTS tax_rule_checks (
    id INTEGER PRIMARY KEY CHECK(id = 1), state TEXT NOT NULL)''');
}
