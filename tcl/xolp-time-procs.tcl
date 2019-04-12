::xo::library doc {
  Data model and populator for the time dimension (and its views)

  @author Michael Aram
  @creation-date 2017
  @see http://www.kimballgroup.com/1997/07/its-time-for-time/
}

namespace eval ::xolp {

  #
  # Time Dimension
  #

  ::xo::db::require table xolp_time_dimension {
    time_id       "SERIAL PRIMARY KEY"
    time          time
    hour          smallint
    minute        smallint
    day_time_name text
  } {
    INSERT INTO xolp_time_dimension DEFAULT VALUES;
    INSERT INTO xolp_time_dimension (
        time,
        hour,
        minute,
        day_time_name
    )
    SELECT
        to_char(MINUTE, 'hh24:mi')::time AS time,
        -- Hour of the day (0 - 23)
        EXTRACT(HOUR FROM MINUTE) AS hour,
        -- Minute of the day (0 - 1439)
        EXTRACT(HOUR FROM MINUTE)*60 + EXTRACT(MINUTE FROM MINUTE) AS minute,
        -- Names of day periods
        CASE WHEN to_char(MINUTE, 'hh24:mi') BETWEEN '06:00' AND '08:29'
          THEN 'morning'
             WHEN to_char(MINUTE, 'hh24:mi') BETWEEN '08:30' AND '11:59'
          THEN 'am'
             WHEN to_char(MINUTE, 'hh24:mi') BETWEEN '12:00' AND '17:59'
          THEN 'pm'
             WHEN to_char(MINUTE, 'hh24:mi') BETWEEN '18:00' AND '22:29'
          THEN 'evening'
             ELSE 'night'
        END AS day_time_name
    FROM (
        SELECT '0:00'::TIME + (SEQUENCE.MINUTE || ' minutes')::INTERVAL AS MINUTE
        FROM generate_series(0,1439) AS SEQUENCE(MINUTE)
        GROUP BY SEQUENCE.MINUTE
    ) DQ
    ORDER BY 1
  }

  ::xo::db::require index -table xolp_time_dimension -col time -unique true
  ::xo::db::require index -table xolp_time_dimension -col hour
  ::xo::db::require index -table xolp_time_dimension -col minute
  ::xo::db::require index -table xolp_time_dimension -col day_time_name

  ::xo::db::require view xolp_begin_time_dimension {
    SELECT
        time_id AS begin_time_id,
        time AS begin_time,
        hour AS begin_hour,
        minute AS begin_minute,
        day_time_name AS begin_day_time_name
    FROM
        xolp_time_dimension
  }

  ::xo::db::require view xolp_end_time_dimension {
    SELECT
        time_id AS end_time_id,
        time AS end_time,
        hour AS end_hour,
        minute AS end_minute,
        day_time_name AS end_day_time_name
    FROM
        xolp_time_dimension
  }

  ::xo::db::require view xolp_storage_time_dimension {
    SELECT
        time_id AS storage_time_id,
        time AS storage_time,
        hour AS storage_hour,
        minute AS storage_minute,
        day_time_name AS storage_day_time_name
    FROM
        xolp_time_dimension
  }

}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
