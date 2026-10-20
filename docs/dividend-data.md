# Dividend data and return calculations

Cash credits from B3 movement exports populate dividend totals, filters, pagination and the monthly received chart automatically. Supported movement labels are Dividendo(s), Juros Sobre Capital Próprio/JCP and Rendimento(s). Only credit/entrada directions and supported listed instruments are accepted. Treasury coupons, amortizations, transfers and derivatives are outside this import context. A malformed eligible credit rejects the whole report. Quantity and unit rate may be absent; the actual reported total is authoritative and is never grossed up or taxed again. Future dated credits cannot confirm receipt.

Original reports and dividend records commit together. Occurrence-aware hashes prevent overlapping reports from duplicating a payment while retaining identical separate credits inside one file. Broker is part of the identity. Existing archived originals are re-read once, checked against their SHA-256 identifiers, and formerly ignored credits recovered without re-importing trades. Missing or changed originals produce an error instead of guessed data. Back up the complete application data folder.

## Online updates

The dividend screen updates on entry when the last attempt is older than one day, after a successful report import, or through **Atualizar proventos e histórico**. It uses the same securely stored brapi credential as quotes. Only asset symbols and the requested date window are sent; quantities, broker names and report files remain local. Cached data is available offline. The stored timestamp is the last attempted refresh, not proof that all endpoints succeeded. Failures and coverage limits remain visible.

Stock events use `/api/v2/stocks/dividends` with `includeRaw=true`. FIIs use `/api/v2/fii/dividends`. Daily prices use `/api/v2/stocks/historical` with `interval=1d` and `includeRaw=true`. Access depends on the account plan and instrument coverage. Raw stock rates and raw prices require the provider's Pro plan; a quote permission does not imply access to them. Failure in one component preserves its earlier cache and does not turn missing data into zero. No paid plan is purchased by the app.

Original prices/rates are required because adjusted series can already incorporate distributions and corporate actions. Adding cash dividends to an adjusted price return could count income twice. Provider remapping to a different ticker is rejected. FII events marked as backfilled from monthly reports are excluded from entitlement calculations because their dates can be reference dates. Unknown events, including amortizations, are flagged rather than counted as dividends.

## Eligibility and reconciliation

API announcements are gross estimates, not confirmation of cash received. Shares held at the close of the data-com are calculated from the complete imported negotiation history, including purchases and sales on that date. Purchases after that date do not participate. Settlement dates are not substituted for trade dates. Estimates are suppressed for settlement-based histories, corporate actions that the app cannot reconstruct, missing original amounts or approximate dates. Only entitlement dates already reached generate an estimate. The application assumes the user has imported the complete history; it cannot detect every omitted operation or transfer.

A confirmed report credit takes priority over an estimate for the same ticker, kind and payment date. If any confirmed credit exists, an aggregate estimate is suppressed conservatively; missing payments from another broker require reconciliation. A unique matching announcement can supply data-com/data-ex, without replacing the reported amount or quantity. Ambiguous matches remain unknown. Past announcements without a report credit stay **a confirmar**, and never increase received totals. Estimated JCP amounts are gross and do not assume a net tax withholding rate. Future announcements appear only when supplied by the provider; empty results do not establish that no dividend will be paid.

## Return lines

The return chart uses daily original closing prices and negotiation quantities, and chains daily return factors. For each day, the denominator is the previous closing portfolio value plus purchases. The numerator is the current closing value plus sales, with confirmed cash credits added only for the line with dividends. This is a daily approximation of time-weighted performance, treating purchases as beginning-of-day flows and sales as end-of-day flows. Chaining the income-inclusive factors represents theoretical reinvestment. It excludes taxes/fees beyond the cash amounts actually reported. Monthly points use the last available daily valuation in each month.

Both lines require original closes for every held asset, full negotiation history and reconstructable corporate actions. Missing prices, settlement-only dates, Treasury holdings or unsupported corporate actions leave lines unavailable with an explanation. No interpolation or synthetic daily prices are used. Returns for portfolios with cash income after all invested capital has been withdrawn require separate cash-account reconciliation and are not fabricated.

Sources checked on 2026-10-20:

- [B3 dividend entitlement](https://borainvestir.b3.com.br/glossario/dividendos/)
- [brapi stock dividends](https://brapi.dev/docs/acoes/dividendos)
- [brapi FII dividends](https://brapi.dev/docs/fiis/dividendos)
- [brapi daily prices and adjustment semantics](https://brapi.dev/docs/acoes/historico)
