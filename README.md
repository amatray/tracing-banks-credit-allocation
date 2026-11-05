# Replication package: "Tracing Banks' Credit Allocation to their Profits"

Anne Duquerroy, Adrien Matray, Farzad Saidi. *Review of Finance*.

The code is released under the MIT License (see `LICENSE`).

`master.do` builds every intermediate dataset from the raw sources and writes every regression
table of the paper (Tables 2 to 10 and A.1 to A.10) to `$tex`, one `.tex` file per table, named
after the program that produces it (`table_05.do` writes `table_05.tex`), and the figures based on
confidential data to `$fig`. Table 1 reports the regulatory share of regulated deposits transferred
to the CDC and requires no code.

## Data availability

All firm-, bank- and loan-level data are confidential and can only be accessed on Banque de France
premises.

| Source | Content | Location in `config.do` |
|---|---|---|
| Centrale des risques (SCR), credit register | bank x firm credit exposures, quarterly, 2008 to 2016 (`CN_YYYY.dta`) | `$scr` |
| SURFI | bank balance sheets (`situation_france_final_trim`), deposits by counterparty (`m_clienre_france_final`, `m_cliennr_france_final`), income statements (`cpte_resu_france_final`) | `$bdf` |
| SURFI securities | bank securities holdings (`TITRE_PTF_EC`) | `$lec` |
| FIBEN | firm balance sheets and descriptive data, CSV extracts | `$bilans`, `$desc` |
| CEFIT | deposits and credit by bank and département, monthly, 2006 to 2017 | `$data\init\cefit_transpo_fin.dta` |

### Raw input files

These raw files must be placed in `$data` before running.

| File | Official source | Read by | Content |
|---|---|---|---|
| `init\cefit_transpo_fin.dta` | CEFIT, statistiques des dépôts et crédits par guichet, Banque de France DGSEI/DSMF/SAFIN (MUSES `safin003`) | `b04_cefit_deposits.do` | deposits and credit by bank and département, monthly, 2006 to 2017 |
| `init\gea_cib_annuel_clean.dta` | GEA, référentiel des groupes bancaires, Banque de France and ACPR | `b04_cefit_deposits.do` | bank (CIB) x year to banking group, 2005 to 2015 |
| `excel\GEA_trimestriel décembre 2015.xlsx` | GEA, as above | `b01_scr_clean.do` | bank to banking group, quarterly |
| `excel\GEASAABA.xlsx`, `excel\GEA DENOMINATION.xlsx` | GEA, as above | `b03_banking_groups.do` | banking-group codes and names |
| `excel\Rate_eonia_ordinary_snf.xlsx` | ECB (EONIA) and Banque de France interest-rate statistics | `b09_rates.do` | monthly EONIA, rates on ordinary household savings and on firms' short-term savings |
| `excel\siren_NAF.xlsx` | Banque de France, Centrale des risques (CCR) bankruptcy and payment-incident records | `b23_bankruptcy_rates.do` | bankrupt firms by year, with INSEE and Banque de France industry (NAF) codes |
| `geography_crosswalk.dta` | INSEE (public) | `table_A9.do` | commune to 2010 employment zone and department |

### Known features of the deposit-ratio construction

- Banks that file a balance sheet (`situation_france_final_trim`) but no customer-deposit report in
  a quarter enter with a regulated-deposit ratio of 0, as unmatched banks do in Tables A.8 and A.9.
  This concerns 482 observations (10 banks) of the Table 5 sample; dropping them moves the
  coefficient in Table 5, column 2, from -0.1601 to -0.1603.
- Bank-quarters present in the resident deposit file but not the non-resident one lose their
  complementary deposits (191 bank-quarters with a positive complement). Restoring them moves the
  coefficient in Table 5, column 2, from -0.1601 to -0.1620.

## Computational requirements

- Stata 17 or later (run on Stata 18 MP).
- User-written packages from SSC: `ftools`, `reghdfe`, `estout`, `regsave`, `winsor`, `winsor4`, `tsspell`,
  `carryforward`, `egenmore`. Set `install_packages` to 1 in `config.do` to install them.
- Memory: `config.do` sets `max_memory` to 32 GB; the main estimation panel has 4,495,354
  observations and the firm-level panel of Table A.8 has 10,162,977.
- Run time: about 6 to 7 hours on Stata 18 MP at the Banque de France.

## Instructions

1. Set `$root` in `master.do` to the folder holding this package.
2. Replace the paths in `config.do` (`$scr`, `$lec`, `$bdf`, `$bilans`, `$desc`, `$raw`, `$data`,
   `$tex`, `$fig`, `$log`): raw-data locations, `$data` (inputs above), and output folders.
   `$raw` must be an empty folder; every intermediate dataset is written there.
3. Run `do master.do`. The log is written to `$log/replication_<date>.smcl`.

The build programs run in the order of their numbers; several read datasets written by earlier
ones; `table_A7.do` and `figures/figures.do` read the panel saved by `table_05.do`.

## Programs

| Program | Builds |
|---|---|
| `config.do` | paths, packages, log, working directory |
| `programs/helpers.do` | `bank_network_flag`, `apply_centralisation` (CDC centralisation schedule) |
| `programs/specifications.do` | fixed-effect and clustering globals used by the tables |
| `programs/fiben_rename_*.do` | variable names of the FIBEN CSV extracts |
| `build/b01` to `b02` | credit register: cleaning and firm x bank x county x quarter panel |
| `build/b03` | banking groups |
| `build/b04` | CEFIT deposits |
| `build/b05` to `b08` | FIBEN: import, cleaning, match to the credit register, balance sheets |
| `build/b09` | livret A and market rates, Gap |
| `build/b10` to `b11` | credit-register samples |
| `build/b12` to `b17` | SURFI: liabilities, deposit ratios, deposits by counterparty, securities, bank characteristics, income statements |
| `build/b18` | main estimation panel (`temp_in_sample2`) |
| `build/b19` to `b21` | bank x county deposit ratios, bank sample, bank heterogeneity variables |
| `build/b22` to `b24` | commune exposure, industry bankruptcy rates, commune aggregates |
| `build/b25` | firm real-effects panel |
| `build/b26` to `b27` | bank x county panel and outcomes |
| `build/b28` | inputs shared by several tables |

## Tables

| Paper | Program | Output |
|---|---|---|
| Table 2 | `tables/table_02.do` | `table_02.tex` |
| Table 3 | `tables/table_03.do` | `table_03.tex` |
| Table 4 | `tables/table_04.do` | `table_04.tex` |
| Table 5 | `tables/table_05.do` | `table_05.tex` |
| Table 6 | `tables/table_06.do` | `table_06.tex` |
| Table 7 | `tables/table_07.do` | `table_07.tex` |
| Table 8 | `tables/table_08.do` | `table_08.tex` |
| Table 9 | `tables/table_09.do` | `table_09.tex` |
| Table 10 | `tables/table_10.do` | `table_10.tex` |
| Tables A.1 to A.10 | `tables/table_A1.do` to `table_A10.do` | `table_A1.tex` to `table_A10.tex` |

## Figures

`figures/figures.do` writes to `$fig`:

| Paper | Output |
|---|---|
| Figure 1 | `G_gap.pdf` |
| Figure 2 | `G_stickiness_2023.pdf` |
| Figure 3 | `Figure3.pdf` |
| Figure 4 | `did_dynamic_median_dr.png` |
| Figure B.1 | `G_livret_gap_dfr.pdf` |
| Figure B.2 | `FigureB2.pdf` |
| Figure B.3 | `FigureB3.pdf` |

Figures D.1 to D.4 use public data from the World Bank Global Financial Development Database
(GFDD) and do not require Banque de France access. `figures/appendix_D/appendix_D.py` (Python 3
with `matplotlib`; `fontTools` optional, for the Gill Sans weights) plots the latest nonmissing
observation of each indicator for 22 advanced economies and writes the four PDFs and
`plotted_values.csv` next to itself. The World Bank API responses it reads are included in
`figures/appendix_D/gfdd/`; a missing file is downloaded again.

| Paper | Output | GFDD indicators |
|---|---|---|
| Figure D.1 | `structure.pdf` | three-bank concentration (`GFDD.OI.01`), capital and reserves to assets (`GFDD.SI.03`) |
| Figure D.2 | `depth.pdf` | private credit by banks to GDP (`GFDD.DI.01`), bank deposits to GDP (`GFDD.OI.02`) |
| Figure D.3 | `balance_sheets.pdf` | bank credit to deposits (`GFDD.SI.04`), nonperforming loans (`GFDD.SI.02`) |
| Figure D.4 | `firm_use.pdf` | firms with a loan or credit line (`GFDD.AI.03`), firms using banks for working capital (`GFDD.AI.29`) |
