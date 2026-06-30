# STA Multi-Report Timing Analyzer

A TCL-based automation tool I built to make STA (Static Timing Analysis) report analysis less painful. Instead of going through each timing report manually and copy-pasting values into a spreadsheet, this script does all of that automatically — parses the reports, runs the calculations, and dumps everything into clean CSV files.


## Why I Built This

During the coursework, We had to deal with multiple STA timing reports and manually extracting slack values, identifying violations, finding worst paths, etc. was taking way too long. So I wrote this TCL script to automate the whole thing. It processes all reports in a folder at once and generates organized summaries.


## What It Does

- Reads all STA timing reports from a folder automatically
- Extracts key timing information from each report
- Calculates WNS, TNS, violated paths, and more
- Generates individual CSVs for each report
- Creates a master summary across all reports
- Flags all paths below a user-specified slack threshold
- Picks and lists the top 5 worst timing paths across all reports

---

## Extracted Fields

From each timing report, the script pulls out:

- Report Name
- Module Name
- Startpoint and Endpoint
- Path Type
- Analysis Type (Setup / Hold)
- Scenario
- Slack
- Data Arrival Time
- Data Required Time

---

## Calculated Metrics

For each report:

**WNS** – Worst Negative Slack
**TNS** – Total Negative Slack
**Best Slack**
**Total Paths**
**Violated Paths** and **MET Paths**
**Report Status** – Pass or Fail


## Project Structure

project/
│
├── TIMINGREPORTS/          # Put your STA timing reports here
│
├── OUTPUT_REPORTS/         # Individual CSVs generated per report
│
├── SUMMARIES/
│   ├── MASTER_SUMMARY.csv
│   ├── VIOLATION_SUMMARY.csv
│   └── TOP_5_WORST_PATHS.csv
│
├── TCL_SCRIPTS/
    ├── Run_All.tcl         # Main script — run this
    ├── report_parser.tcl   # Parsing logic



## Generated Output Files

### `MASTER_SUMMARY.csv`
One row per report. Columns:
`Report Name | Module | Analysis Type | Scenario | Best Slack | WNS | TNS | Total Paths | Violated Paths | Hold Violations | Setup Violations | Report Status`

### Individual Report CSVs (inside `OUTPUT_REPORTS/`)
One CSV per timing report. Columns:
`Startpoint | Endpoint | Slack | Path Type | Path Status | Data Arrival Time | Data Required Time | Critical Path Details | Timing Summary`

### `VIOLATION_SUMMARY.csv`
Lists all paths where slack is below the threshold you enter when running the script.
`Report Name | Startpoint | Endpoint | Slack`

### `TOP_5_WORST_PATHS.csv`
Top 5 worst slack paths collected across all reports, sorted by slack value.
`S.No | Report Name | Startpoint | Endpoint | Slack`


## How to Run

1. Copy all your STA timing reports into the `TIMINGREPORTS/` folder
2. Open a terminal and run:

tclsh TCL_SCRIPTS/Run_All.tcl

3. When prompted, enter the slack threshold for violation detection
4. Check `OUTPUT_REPORTS_CSV/` and `SUMMARIES/` for the generated CSVs


## Technologies Used

- TCL (Tool Command Language)
- Static Timing Analysis concepts
- CSV file handling
