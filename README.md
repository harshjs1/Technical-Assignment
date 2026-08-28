# Affinity Answers — Technical Assignment

Full-stack engineering take-home covering Python web scraping, SQL querying against the Rfam public database, and Unix shell scripting.

## Repository Structure

```
technical-assignment/
├── README.md
├── requirements.txt
├── question1/
│   └── scraper.py
├── question2/
│   └── queries.sql
└── question3/
    └── companies.sh
```

## Prerequisites

- Python 3.9+
- Bash
- `curl`
- GNU `awk` (for CSV field parsing in Question 3)
- Optional: MySQL client or Python `pymysql` to run and test the SQL queries

## Setup

Install Python dependencies for Question 1:

```bash
pip install -r requirements.txt
```

Make the shell script executable:

```bash
chmod +x question3/companies.sh
```

## Question 1 — Python Web Scraper

### Description

`question1/scraper.py` accepts a search term, builds the MDComputers search URL, retrieves the search-results page, and extracts product names with their current selling prices.

The scraper uses:

- `cloudscraper` to handle Cloudflare protection on the site
- `BeautifulSoup` to parse product cards from the HTML

Selling price is taken from the discounted price when present; otherwise the single listed price is used.

### Run

```bash
python question1/scraper.py
```

Example:

```text
Enter search term: external hard drive

Products found for 'external hard drive':

#    Product Name                                                 Selling Price
---------------------------------------------------------------------------------
1    Seagate Expansion 1TB External Hard Drive                      ₹9,140
2    WD Elements 1TB External Hard Drive                            ₹9,290
...
```

### Error Handling

- Empty search term
- Network/request failures
- No products found for the supplied term

## Question 2 — SQL Queries

### Description

`question2/queries.sql` contains three queries against the public Rfam MySQL database.

Connection details:

- Host: `mysql-rfam-public.ebi.ac.uk`
- Port: `4497`
- User: `rfamro`
- Password: none
- Database: `Rfam`

### Run

Using the MySQL client:

```bash
mysql --user rfamro --host mysql-rfam-public.ebi.ac.uk --port 4497 --database Rfam < question2/queries.sql
```

### Verified Results

**2A — Acacia plant types**

```text
acacia_plant_types
325
```

**2B — Wheat type with longest DNA sequence**

```text
wheat_type                      dna_sequence_length
Triticum durum (durum wheat)    836514780
```

**2C — Page 9 of families with max DNA length > 1,000,000**

Returns rows 121–135 when sorted by maximum DNA sequence length descending. Example rows:

```text
family_accession  family_name   max_dna_sequence_length
RF01219           snoR100       836514780
RF01220           snoR104       836514780
...
```

Note: Query 2C joins `full_region` and `rfamseq`, so it can take several minutes to complete on the public database.

## Question 3 — Unix Shell Script

### Description

`question3/companies.sh` accepts a CSV URL, downloads the dataset, extracts company name, headquarters location, and founding year, then sorts the records by founding year.

The script uses `curl`, `awk` with quoted-field CSV parsing, and `column` for readable output.

### Run

```bash
./question3/companies.sh "https://raw.githubusercontent.com/datasets/s-and-p-500-companies/main/data/constituents.csv"
```

Example output:

```text
Company Name              Location                    Founding Year
------------              --------                    -------------
BNY Mellon                New York City, New York     1784
State Street Corporation  Boston, Massachusetts       1792
...
```

### Error Handling

- Missing URL argument
- Failed download
- Empty CSV response
- Missing required tools

## Dependencies

| Component   | Dependencies                                 |
|------------|-----------------------------------------------|
| Question 1 | `requests`, `beautifulsoup4`, `cloudscraper`  |
| Question 2 | Rfam public MySQL database access             |
| Question 3 | `bash`, `curl`, `awk`, `column`               |

## Assumptions and Limitations

- **Question 1:** MDComputers uses Cloudflare; `cloudscraper` is used instead of plain `requests`. Site HTML structure may change over time.
- **Question 2A:** Acacia types are counted as distinct species in genus Acacia using `tax_string LIKE '%; Acacia.'`.
- **Question 2B:** Wheat types are species under genus Triticum. The longest sequence comes from `rfamseq.length`.
- **Question 2C:** Maximum DNA sequence length is computed from associated `rfamseq` records via `full_region`.
- **Question 3:** Founding year sorting uses the first 4-digit year found in the `Founded` column. Records without a year are placed last.
