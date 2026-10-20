# Brazilian investment income tax

Reference date: 2026-10-19. Rule revision: `BR-PF-2026-10-19`.
Scope: Brazilian resident individuals, domestic listed securities already
supported by this application, calendar years from 2025. Nonresidents,
companies, derivatives, off-exchange sales and other products are outside the
calculation contract. Adding a product requires an explicit tax classification
and reviewed rules; a portfolio category alone must never imply its tax regime.

## Assisted monthly assessment

The B3 transaction imports do not contain a complete fiscal ledger: fees, actual
IRRF, opening tax costs, all accounts and corporate actions can be missing.
The module therefore does not derive payable tax from the portfolio's displayed
profit or broker-specific average cost. The user must reconcile monthly net
results across every broker for the same CPF, using trade dates and documented
costs. The form records signed results, actual withholding, payments and notes.
Day-trade classification must be reconciled from broker notes, not inferred from
daily aggregate B3 rows without execution order.

B3 Movimentação settlement entries may now feed portfolio quantities. Their
original movement label and settlement date basis are retained in SQLite and
annual reconciliation exports. A settlement date is not an inferred trade date;
the actual trade date and fiscal reporting year must be reconciled separately.
The importer rejects mixing settlement and trade-date histories for the same
asset/broker because these exports have no shared transaction identifier.

- Eligible ordinary stock sales: monthly gross sales up to BRL 20,000 exempt
  positive stock results. Above this amount, the entire stock result is taxable.
  ETFs, BDRs, FIIs and day trades do not receive this exemption. Exempt gains do
  not consume accumulated losses; realized stock losses remain compensable.
- Common operations in stocks, equity ETFs and BDRs share a 15% group. Day
  trades excluding FIIs have a separate 20% group. FII ordinary and day-trade
  results share their own 20% group. Losses never cross these groups.
- Documented losses offset results in the same month or later months, not past
  months. Opening losses are confirmed explicitly each year. This avoids
  silently carrying incomplete prior-year results into a new year.
- Actual IRRF is entered per group rather than estimated from sales. Credits
  reduce that group's tax and remain available within the year. They are not
  automatically carried into a new year: ordinary IRRF and day-trade balances
  have different annual adjustment/refund procedures.
- Tax is calculated in integer cents and truncated at the cent. DARF 6015
  amounts below BRL 10 accumulate with that code until the minimum is reached.
  A payable DARF remains a separate unpaid principal until the user records its
  payment; later tax losses do not erase that obligation. Payments are manually
  reported principal, not verified receipts or interest/penalties.
- Payment is due on the last business day of the following month. The UI directs
  the user to the official tax agenda instead of assuming that weekday arithmetic
  includes every applicable holiday. Sicalc handles overdue interest/penalties.
- Missing opening balances or earlier months mark results as partial; missing
  months are never treated as confirmed zero-operation months. Current-month
  values remain subject to reconciliation at month-end.

## Planning

The planner calls the same assessment engine using a proposed additional net
result and, for eligible ordinary stocks, additional gross sales. It preserves
earlier months, does not change persisted records, and never submits trades.
It illustrates documented-cost deductions, same-group loss compensation and
the monthly stock-sales threshold. It does not recommend transactions or
calculate Treasury, fixed-income ETF or income-distribution taxation.

## Annual preparation

The generation action is available from January through the known official
filing deadline for the current exercise. When that deadline is unknown, the
preparation window ends June 30, explicitly labelled as unconfirmed. A known
extension beyond June extends availability. The built-in deadline for exercise
2026 is May 29, 2026. Preparation in January does not imply that official
transmission has opened. Only closed calendar years can be exported.

The HTML document contains manually reviewed monthly data, carry balances,
actual entered withholding and payments, notes, source-check status, and gross
imported trades for reconciliation. It is not a completed DIRPF, PGD import,
DARF or transmission receipt. Incomplete data are explicitly identified. It is
saved under `Documents/InvestmentsWallet/tax/exports`; the existing database and
this directory are included by backing up the entire application data folder.

The taxpayer still needs complete acquisition costs and December 31 positions
for both years, issuer CNPJ, institution statements, other assets and income,
personal data and the applicable annual filing criteria. These are not invented
from the transaction reports. In particular:

- Treasury income is withheld at source according to the holding-period ladder
  (22.5%, 20%, 17.5%, 15%), with possible short-term IOF. It is not DARF 6015.
- Fixed-income ETFs use source withholding and portfolio maturity rules
  (25%, 20%, 15%), not the equity-ETF trading rule. The import category does not
  currently distinguish the two, so the user must exclude fixed-income ETFs
  from the common equity-results input.
- JCP withholding changed from 15% in 2025 to 17.5% in 2026 under LC 224/2025.
- Law 15,270/2025 introduced dividend withholding above BRL 50,000 per payer,
  resident individual and month in 2026, on the full payment, subject to
  transitional exceptions. The annual high-income regime starts with calendar
  2026/exercise 2027 and requires whole-income data and exclusions. The module
  does not automatically calculate these regimes or assume dividend exemption.
- FII distribution exemptions depend on legal conditions for the fund and
  investor. BDR distributions require their own foreign-income analysis; the
  domestic BDR sale rule must not be used for those distributions.

## Official-source checks and rule updates

Eight public Receita Federal articles have normalized-content SHA-256 baselines
recorded during development. On startup and entry to the tax page the app checks
access to an official source. With the app open, a timer repeats this hourly.
A complete comparison runs initially, after six calendar months from the last
successful complete check, or when requested manually. During January-June,
complete comparisons also run at least weekly to look for deadline updates.
Closing the application stops checks; no operating-system background job is
installed. Failed checks retain the last successful timestamp and cached rules.

A failed network access shows an offline warning; an HTTP/content/partial
failure shows a verification warning. Content changes remain flagged until a
reviewed application revision replaces the reference. A successful download
does not validate legislation, discover every newly enacted law or automatically
change tax formulas. The UI states this explicitly. Unknown markup is a failed
check, never a successful unchanged result. Only a full, explicitly dated
sentence on the official deadline page may update the seasonal cutoff.

Monitoring arbitrary official HTML is not a trusted machine-readable rule feed.
Automatic legal-rule replacement is intentionally not claimed: an engineer
must review the change, update effective-date-specific rules and sources, and
verify calculations before shipping a new application revision. The reference
date and last complete source check remain separate. No financial data,
identifiers or imported documents are sent with these public HTTP requests.

## Sources

Verification on Windows: 49 temporary focused checks passed for exemption
boundaries, separated compensation groups, forward-only losses, IRRF credits,
subminimum DARF accumulation, payment principal, missing history, planning,
calendar deadlines, offline/HTTP failures, changed-source persistence, SQLite
roundtrips and escaped partial HTML reports. A live check of the eight sources
matched the recorded baselines and parsed the 2026 deadline. Native rendering
at 1280 and 650 logical pixels covered the three panels, disabled out-of-season
generation and the entry dialog without Flutter layout errors. Validation
scripts, isolated databases and screenshots were removed afterwards; no
persistent automated regression suite was added. macOS/Linux native builds and
complete end-to-end reconciliation against an actual taxpayer's notes, income
statements and filed declaration were not executed on this Windows host.

- [Receita: exchange taxation and deductible costs](https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/bolsa-de-valores/)
- [Receita: exemptions](https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/isencoes)
- [Receita: loss compensation](https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/compensacoes)
- [Receita: actual withholding and year-end credits](https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/retencoes)
- [Receita: calculation and payment](https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/bolsa-de-valores-1/calculo-e-pagamento-do-imposto)
- [Receita: ReVar groups and subminimum DARF](https://www.gov.br/receitafederal/pt-br/assuntos/meu-imposto-de-renda/pagamento/renda-variavel/manual)
- [Receita: official annual deadline](https://www.gov.br/receitafederal/pt-br/acesso-a-informacao/perguntas-frequentes/imposto-de-renda/dirpf/declaracao/prazo)
- [Receita: 2026 dividend withholding](https://www.gov.br/receitafederal/pt-br/assuntos/noticias/2026/agosto/receita-federal-orienta-sobre-os-procedimentos-para-o-recolhimento-do-imposto-de-renda-retido-na-fonte-sobre-lucros-e-dividendos/)
- [Law 15,270/2025](https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2025/lei/l15270.htm)
- [LC 224/2025: JCP withholding](https://www.planalto.gov.br/ccivil_03/leis/lcp/lcp224.htm)
- [Law 13,043/2014: fixed-income ETFs](https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2014/lei/l13043.htm)
- [B3: Treasury taxation and statements](https://www.b3.com.br/pt_br/noticias/como-declarar-investimentos-do-tesouro-direto-no-imposto-de-renda-2026.htm)
