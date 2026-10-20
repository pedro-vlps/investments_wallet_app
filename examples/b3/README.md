# Synthetic B3 movement examples

These XLSX files reproduce the eight-column `Movimentação` layout of the supplied B3 export. They are synthetic development fixtures, not documents issued by B3. Prices, dates, quantities, operations and broker names are fictional. Product identifiers are examples, not current market quotes. No personal account data is included.

Each workbook has one `Movimentação` sheet with the original Portuguese headers. Numeric values and dates are typed cells. Totals are stored values, like an exported report, rather than formulas. All eligible operations use `Transferência - Liquidação`: dates represent settlement dates, not trade dates.

The XLSX serialization uses Excel serial dates, inline text cells, relative workbook relationship targets and an unprefixed SpreadsheetML namespace for compatibility with the current `excel` reader. These serialization choices do not change the report columns or their values.

## Import sequence

Use an empty development portfolio and import files 01 through 05 in order through **Relatórios > Adicionar relatórios**. Importing examples into a personal portfolio adds fictional holdings to it. These files do not reset or isolate application data automatically.

| File | Scenario | Expected behavior |
| --- | --- | --- |
| `01-initial-purchases.xlsx` | Stocks, FII, ETF, BDR and fractional Treasury purchase | 5 eligible purchases, automatically classified |
| `02-additional-purchases.xlsx` | New purchases, second broker and two identical AAPL34 fills | 5 new purchases; both identical fills retained; PETR4 broker recorded separately |
| `03-partial-sales.xlsx` | Partial stock, FII and Treasury sales | 3 sales; holdings reduced; importing this file alone into an empty portfolio fails without saving it |
| `04-overlapping-period.xlsx` | Two operations already in file 01 and a new BBAS3 purchase | 2 duplicates skipped, 1 new purchase |
| `05-unsupported-events.xlsx` | ITUB4 purchase, dividend, JCP, option and unrelated transfer | 1 purchase and 2 cash credits imported; option and unrelated transfer ignored |
| `06-invalid-total.xlsx` | One consistent purchase followed by an inconsistent quantity × price total | Entire file rejected; neither purchase saved |

Importing the exact same workbook again is rejected without changing holdings. File 06 is intentionally invalid and should not be accepted. No extra invalid-file correction is needed for this fixture.

## Expected holdings after files 01–05

| Asset | Broker | Quantity | Remaining acquisition cost (BRL) |
| --- | --- | ---: | ---: |
| PETR4 | EXAMPLE ALPHA BROKER | 120 | 3,920.00 |
| PETR4 | EXAMPLE BETA BROKER | 20 | 660.00 |
| HGLG11 | EXAMPLE ALPHA BROKER | 12 | 1,824.00 |
| BOVA11 | EXAMPLE ALPHA BROKER | 8 | 960.00 |
| AAPL34 | EXAMPLE ALPHA BROKER | 16 | 980.00 |
| Tesouro Selic 2031 | EXAMPLE ALPHA BROKER | 0.04 | 640.00 |
| BBAS3 | EXAMPLE ALPHA BROKER | 40 | 1,000.00 |
| ITUB4 | EXAMPLE ALPHA BROKER | 30 | 1,050.00 |
| **Total** | | | **11,034.00** |

Expected totals: 5 saved reports, 15 distinct operations, 2 received cash credits totaling BRL 84.00, 7 assets and 8 asset/broker holdings. The portfolio screen consolidates PETR4 across brokers to 140 shares. Remaining acquisition cost excludes fees and taxes; current market values and returns can change when quotes are refreshed. All trade dates in these fixtures are settlement dates, so API entitlement estimates and historical return lines stay unavailable until actual negotiation dates are provided. Confirmed cash credits still appear in the dividend totals and monthly chart.

## Validation

The exported files were checked with the application's actual B3 parser and report repository using disposable SQLite databases. Validation covered classification, settlement provenance, all expected quantities and remaining costs, overlapping periods, identical fills, repeated-file rejection, unsupported-event exclusion, invalid-total rejection and rollback of sales without holdings. Workbook previews were also inspected. The application's file-picker dialog was not automated for these examples.
