::xo::library doc {
  Data model and populator for the date dimension (and its views)

  @author Michael Aram
  @creation-date 2017
  @see http://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/calendar-date-dimension/
}

namespace eval ::xolp {

  #
  # Date Dimension
  #

  ::xo::db::require table xolp_date_dimension {
    date_id     "SERIAL PRIMARY KEY"
    date        date
    year        smallint
    month       smallint
    day         smallint
    dow         text
    term_name   text
    is_weekend  boolean
    is_holiday  boolean
  } {
    INSERT INTO xolp_date_dimension DEFAULT VALUES;
    INSERT INTO xolp_date_dimension (
        date,
        year,
        month,
        day,
        dow,
        term_name,
        is_weekend,
        is_holiday
    )
    SELECT
        d,
        date_part('year', d),
        date_part('month', d),
        date_part('day', d),
        trim(to_char(d, 'Day')),
        '',
        CASE
            WHEN date_part('isodow', d) IN (6, 7) THEN TRUE
            ELSE FALSE
        END,
        FALSE
    FROM
        generate_series('2000-01-01'::date, '2100-12-31'::date, '1 day') d
  }

  ::xo::db::require index -table xolp_date_dimension -col date -unique true
  ::xo::db::require index -table xolp_date_dimension -col year
  ::xo::db::require index -table xolp_date_dimension -col month
  ::xo::db::require index -table xolp_date_dimension -col day
  ::xo::db::require index -table xolp_date_dimension -col dow
  ::xo::db::require index -table xolp_date_dimension -col term_name
  ::xo::db::require index -table xolp_date_dimension -col is_weekend
  ::xo::db::require index -table xolp_date_dimension -col is_holiday

  ::xo::db::require view xolp_begin_date_dimension {
    SELECT
        date_id AS begin_date_id,
        date AS begin_date,
        year AS begin_year,
        month AS begin_month,
        day AS begin_day,
        dow AS begin_dow,
        term_name AS begin_term_name,
        is_weekend AS begin_is_weekend,
        is_holiday AS begin_is_holiday
    FROM
        xolp_date_dimension
  }

  ::xo::db::require view xolp_end_date_dimension {
    SELECT
        date_id AS end_date_id,
        date AS end_date,
        year AS end_year,
        month AS end_month,
        day AS end_day,
        dow AS end_dow,
        term_name AS end_term_name,
        is_weekend AS end_is_weekend,
        is_holiday AS end_is_holiday
    FROM
        xolp_date_dimension
  }

  ::xo::db::require view xolp_storage_date_dimension {
    SELECT
        date_id AS storage_date_id,
        date AS storage_date,
        year AS storage_year,
        month AS storage_month,
        day AS storage_day,
        dow AS storage_dow,
        term_name AS storage_term_name,
        is_weekend AS storage_is_weekend,
        is_holiday AS storage_is_holiday
    FROM
        xolp_date_dimension
  }

}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
