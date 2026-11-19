const clean = (col) =>
  `IF(TRIM(${col}) IN ('-', 'N.A', 'N,A', ''), NULL, TRIM(${col}))`;

const toInt = (col) => `SAFE_CAST(${clean(col)} AS INT64)`;
const toFloat = (col) => `SAFE_CAST(${clean(col)} AS FLOAT64)`;
const toPct = (col) => `SAFE_CAST(REPLACE(${clean(col)}, '%', '') AS FLOAT64)`;

const toDate = (col) => String.raw`SAFE.PARSE_DATE('%b %d, %Y',
  REGEXP_REPLACE(
    REGEXP_REPLACE(
      REGEXP_REPLACE(TRIM(${col}), r'^Sept\b', 'Sep'),
      r'^(\d{1,2}) ([A-Za-z]+),', r'\2 \1,'),
    r'^([A-Za-z]+) (\d{1,2}) (\d{4})$', r'\1 \2, \3'))`;

module.exports = { clean, toInt, toFloat, toPct, toDate };