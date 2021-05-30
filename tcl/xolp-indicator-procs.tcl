::xo::library doc {
  Data model and business logic for indicators,
  in particular the central fact table of the data mart.

  @author Michael Aram
  @creation-date 2017
}

::xo::library require xolp-activity-procs
::xo::library require xolp-date-procs
::xo::library require xolp-time-procs
::xo::library require xolp-competency-procs

namespace eval ::xolp {

  #
  # Indicators
  #
  ::xotcl::Class create ::xolp::Indicator \
      -parameter {
        indicator_id
        user_id
        activity_verb_id
        activity_version_id
        competency_set_id
        begin_timestamp
        begin_date_id
        begin_time_id
        end_timestamp
        end_date_id
        end_time_id
        storage_timestamp
        storage_date_id
        storage_time_id
        result_numerator
        result_denominator
      } \
      -ad_doc {
        Primary Fact Table Abstraction
      }

  ::xolp::Indicator ad_proc essential_attributes {} {
    Return essential attributes
  } {
    set attributes [::xolp::util::lremove [:info parameter] {
      indicator_id begin_date_id end_date_id begin_time_id end_time_id storage_date_id storage_time_id
    }]
    return $attributes
  }

  ::xolp::Indicator ad_instproc init args {
    Init class
  } {
    next
    :destroy_on_cleanup
  }

  ::xo::db::require table xolp_indicator_facts {
    indicator_id          {BIGSERIAL PRIMARY KEY}
    user_id               {INTEGER NOT NULL REFERENCES users ON DELETE CASCADE}
    activity_verb_id      {INTEGER NOT NULL REFERENCES xolp_activity_verb_dimension}
    activity_version_id   {INTEGER NOT NULL REFERENCES xolp_activity_dimension ON DELETE CASCADE}
    competency_set_id     {INTEGER DEFAULT 1 NOT NULL REFERENCES xolp_competency_set_dimension ON DELETE SET DEFAULT}
    begin_timestamp       {TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp NOT NULL CHECK (begin_timestamp <= end_timestamp)}
    begin_date_id         {INTEGER NOT NULL REFERENCES xolp_date_dimension}
    begin_time_id         {INTEGER NOT NULL REFERENCES xolp_time_dimension}
    end_timestamp         {TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp NOT NULL}
    end_date_id           {INTEGER NOT NULL REFERENCES xolp_date_dimension}
    end_time_id           {INTEGER NOT NULL REFERENCES xolp_time_dimension}
    storage_timestamp     {TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp NOT NULL CHECK (end_timestamp <= storage_timestamp)}
    storage_date_id       {INTEGER NOT NULL REFERENCES xolp_date_dimension}
    storage_time_id       {INTEGER NOT NULL REFERENCES xolp_time_dimension}
    result_numerator      {INTEGER NOT NULL}
    result_denominator    {INTEGER NOT NULL CHECK (result_numerator <= result_denominator)}
  }

  if {[::xo::db::require exists_table xolp_indicator_facts]} {
    ::xo::dc dml create-index-with-long-default-name "
      CREATE UNIQUE INDEX IF NOT EXISTS xolp_indicator_combined_pk_un_idx
      ON xolp_indicator_facts (user_id, activity_version_id, begin_timestamp, end_timestamp)
    "
  }

  ::xo::db::require index -table xolp_indicator_facts -col user_id
  ::xo::db::require index -table xolp_indicator_facts -col activity_verb_id
  ::xo::db::require index -table xolp_indicator_facts -col activity_version_id
  ::xo::db::require index -table xolp_indicator_facts -col competency_set_id
  ::xo::db::require index -table xolp_indicator_facts -col begin_timestamp
  ::xo::db::require index -table xolp_indicator_facts -col begin_date_id
  ::xo::db::require index -table xolp_indicator_facts -col begin_time_id
  ::xo::db::require index -table xolp_indicator_facts -col end_timestamp
  ::xo::db::require index -table xolp_indicator_facts -col end_date_id
  ::xo::db::require index -table xolp_indicator_facts -col end_time_id
  ::xo::db::require index -table xolp_indicator_facts -col storage_timestamp
  ::xo::db::require index -table xolp_indicator_facts -col storage_date_id
  ::xo::db::require index -table xolp_indicator_facts -col storage_time_id

  #
  # The following code - which is already PostgreSQL-specific -- avoids
  # "tuple concurrently updated" errors from PostgreSQL, which show
  # up, when there are concurrent attempts to execute "CREATE OR
  # REPLACE FUNCTION" SQL statements. I can't say, whether this is
  # LEARN-specific, or whether this concerns "CREATE OR REPLACE
  # FUNCTION" in general, but the error shows ap at the following
  # statement. The pg_advisory_lock() guarantees sequential updates;
  # maybe this has as well to be defined on other places.
  #
  ::xo::dc dml create-trigger {
    SELECT pg_advisory_lock(4711);
    CREATE OR REPLACE FUNCTION xolp_indicator_upsert_tr() RETURNS trigger AS '
    BEGIN
    NEW.begin_date_id := (SELECT date_id FROM xolp_date_dimension where date = NEW.begin_timestamp::date);
    NEW.begin_time_id := (SELECT time_id FROM xolp_time_dimension where time = to_char(NEW.begin_timestamp::time,''HH24:MI'')::time);
    NEW.end_date_id := (SELECT date_id FROM xolp_date_dimension where date = NEW.end_timestamp::date);
    NEW.end_time_id := (SELECT time_id FROM xolp_time_dimension where time = to_char(NEW.end_timestamp::time,''HH24:MI'')::time);
    NEW.storage_date_id := (SELECT date_id FROM xolp_date_dimension where date = NEW.storage_timestamp::date);
    NEW.storage_time_id := (SELECT time_id FROM xolp_time_dimension where time = to_char(NEW.storage_timestamp::time,''HH24:MI'')::time);
    RETURN NEW;
    END;
    ' LANGUAGE plpgsql;
    DROP TRIGGER IF EXISTS xolp_indicator_upsert_tr ON xolp_indicator_facts;
    CREATE TRIGGER xolp_indicator_upsert_tr BEFORE INSERT OR UPDATE ON xolp_indicator_facts FOR EACH ROW EXECUTE PROCEDURE xolp_indicator_upsert_tr();
    SELECT pg_advisory_unlock(4711);
  }

  ::xolp::Indicator ad_proc exists_in_db {
    {-indicator_id:required}
  } {
    Checks for objects existence in the database
  } {
    ::xo::dc get_value select_object {select 1 from xolp_indicator_facts where indicator_id = :indicator_id} 0
  }

  ::xolp::Indicator ad_proc delete {
    {-indicator_id ""}
    {-user_ids ""}
    {-activity_version_ids ""}
  } {
    Delete object
  } {
    if {$indicator_id ne ""} {
      ::xo::dc dml delete {DELETE FROM xolp_indicator_facts WHERE indicator_id = :indicator_id}
    } elseif {$user_id ne "" and $activity_version_ids ne ""} {
      ::xo::dc dml delete {DELETE FROM xolp_indicator_facts WHERE user_id = :user_ids AND activity_version_id = :activity_version_ids}
    } else {
      error "Invalid arguments provided..."
    }
  }

  ::xolp::Indicator lappend datetime_properties {*}[db_columns xolp_begin_time_dimension]
  ::xolp::Indicator lappend datetime_properties {*}[db_columns xolp_begin_date_dimension]
  ::xolp::Indicator lappend datetime_properties {*}[db_columns xolp_end_time_dimension]
  ::xolp::Indicator lappend datetime_properties {*}[db_columns xolp_end_date_dimension]
  ::xolp::Indicator lappend datetime_properties {*}[db_columns xolp_storage_time_dimension]
  ::xolp::Indicator lappend datetime_properties {*}[db_columns xolp_storage_date_dimension]

  ::xolp::Indicator ad_proc get_values_from_db {
    {-properties "result_percentage"}
    {-aggregate ""}
    {-user_ids ""}
    {-activity_iris ""}
    {-activity_verb_iris ""}
    {-begin_time_constraint ""}
    {-begin_date_constraint ""}
    {-end_time_constraint ""}
    {-end_date_constraint ""}
    {-storage_time_constraint ""}
    {-storage_date_constraint ""}
  } "
    Fast retrieval of duration and percentage values
    from the indicators fact table.
    Each provided parameter value acts as additional filter of the result set.
    For each provided activity, subactivities are searched for indicators as well.
    Note, however, that there is no recursive aggregation and no weighting of indicators.
    In other words, you get all actual indicator values attached to any activity in the tree/forest
    requested by the provided activity_iris.
    The <code>*_constraint</code> parameters are meant to be SQL WHERE clause search conditions that
    are directly applied. Typically using one or a few properties (see above), e.g. <code>-storage_time_constraint \"storage_dow = 'Monday'\"</code>
    @param properties         A list that specifies the values to be included in the dictionary.
                              Allowed properties are:
                              [::xolp::Indicator set datetime_properties]
    @param aggregate          SQL function to be used for aggregating values. Allowed are: min, max, avg, sum.
    @param user_ids           List of user_ids to retrieve indicators for.
    @param activity_iris      List of activity IRIs to retrieve indicators for.
    @param activity_verb_iris List of activity verb IRIs to filter indicators.

    @param begin_time_constraint see description above
    @param begin_date_constraint see description above
    @param end_time_constraint see description above
    @param end_date_constraint see description above
    @param storage_time_constraint see description above
    @param storage_date_constraint see description above
  " {
    if {$user_ids eq "" && $activity_iris eq ""} {
      error "Invalid arguments. Please provide a filter for the indicators."
    }
    if {$aggregate ni {"" min max avg sum}} {
      error "Invalid aggregate function"
    }
    set properties [::xolp::util::lremove $properties indicator_id]
    set allowed_properties {user_id result_percentage duration}
    lappend allowed_properties {*}${:datetime_properties}

    foreach p $allowed_properties {
      if {$p in $properties} {lappend ordered_properties $p}
    }
    lappend select_list [expr {$aggregate eq "" ? "indicator_id" : "string_agg(indicator_id::text,' ')"}]
    foreach p $ordered_properties {
      switch -- $p {
        duration {
          lappend select_list "${aggregate}(age(facts.end_timestamp, facts.begin_timestamp)) AS duration"
        }
        result_percentage {
          #lappend select_list "xolp_weighted_result(facts.user_id,activity_hierarchy.activity_iri,NULL,:aggregate::TEXT) AS aggregate_weighted_result_percentage"
          lappend select_list "${aggregate}(result_numerator::numeric / result_denominator::numeric) * 100 AS result_percentage"
        }
        default {
          lappend select_list $p
        }
      }
    }
    set sql ""
    set dimensions [list]
    set where_clause [list]
    # Dimension: Activities
    if {$activity_iris ne ""} {
      set dimension_table "xolp_activity_dimension"
      set transformed_list [::xolp::util::ltransform -prefix "'" -suffix "'" $activity_iris]
      # We need the descendants of the provided activities as well, in order to retrieve the
      # descendant indicators.
      set sql "
        WITH RECURSIVE activity_hierarchy AS (
            SELECT a.iri as activity_iri, a.activity_version_id
            FROM xolp_activity_dimension a
            WHERE (a.iri IN ([join $transformed_list ,]))
          UNION
            SELECT br.activity_iri, ac.activity_version_id
            FROM xolp_activity_hierarchy_bridge br, activity_hierarchy h, xolp_activity_dimension ac
            WHERE br.context_iri = h.activity_iri
              AND br.activity_iri = ac.iri
        )
      "
      lappend dimensions "INNER JOIN activity_hierarchy USING (activity_version_id)"
    }
    # Dimension: Users
    if {$user_ids ne ""} {
      lappend where_clause " user_id IN ([join $user_ids ,]) "
    }
    # Dimension: Time / Date
    foreach time_filter {begin_time_constraint begin_date_constraint end_time_constraint end_date_constraint storage_time_constraint storage_date_constraint} {
      if {[set ${time_filter}] ne "" || [::xolp::util::lcontains $ordered_properties ${:datetime_properties}] } {
        set dimension_table xolp_[string map {"constraint" "dimension"} ${time_filter}]
        set dimension_table_pk [string map {"constraint" "id"} ${time_filter}]
        lappend dimensions "INNER JOIN $dimension_table USING ($dimension_table_pk)"
        if {[set ${time_filter}] ne ""} {
          lappend where_clause [set $time_filter]
        }
      }
    }
    # Dimension: Activity Verbs
    if {$activity_verb_iris ne ""} {
      set dimension_table xolp_activity_verb_dimension
      lappend dimensions "INNER JOIN $dimension_table USING (activity_verb_id)"
      set transformed_list [::xolp::util::ltransform -prefix "'" -suffix "'" $activity_verb_iris]
      lappend where_clause " ${dimension_table}.iri IN ([join $transformed_list ,]) "
    }
    if {$where_clause ne ""} {
      set where_clause "WHERE [join $where_clause { AND }]"
    }
    set group_by_clause ""
    if {$aggregate ne ""} {
      set group_by_properties [::xolp::util::lremove $ordered_properties result_percentage]
      set group_by_properties [::xolp::util::lremove $group_by_properties duration]
      set group_by_clause [expr {$group_by_properties eq "" ? "" : "GROUP BY [join $group_by_properties ,]"}]
    }
    append sql "
      SELECT [join $select_list ,]
      FROM xolp_indicator_facts facts
      [join $dimensions " "]
      $where_clause
      $group_by_clause
    "
    set indicators [::xo::dc list_of_lists select_indicators $sql]
    set result_dict {}
    if {[llength $ordered_properties] <= 1} {
      # We only have one value
      foreach l $indicators {
        dict set result_dict [lindex $l 0] [lindex $l 1]
      }
      return $result_dict
    }
    set varnames [list indicator_id {*}$ordered_properties]
    foreach l $indicators {
      lassign $l {*}$varnames
      foreach p $ordered_properties {
        dict set result_dict [lindex $l 0] $p [set $p]
      }
    }
    return $result_dict
  }

  ::xolp::Indicator ad_proc get_instance_from_db {
    {-indicator_id:required}
  } {
  } {
    ::xo::dc 1row fetch {SELECT * FROM xolp_indicator_facts WHERE indicator_id = :indicator_id}
    set attributes [list indicator_id {*}[:essential_attributes]]
    foreach a $attributes {lappend arguments -$a [set $a]}
    return [::xolp::Indicator new {*}$arguments]
  }

  ::xolp::Indicator ad_proc insert {
    {-user_id ""}
    {-activity_verb_id ""}
    {-activity_version_id ""}
    {-competency_set_id 1}
    {-begin_timestamp ""}
    {-end_timestamp ""}
    {-result_numerator:required}
    {-result_denominator 100}
    {-return ""}
  } {
    @param begin_timestamp The timestamp at which the (learning) activity began (default: equal to end_timestamp)
    @param end_timestamp The timestamp at which the (learning) activity ended
    @param return Specify kind of return value. The default will return nothing and is the fastest.
    Further valid values are "id" (returns the newly created indicator_id)
    and "object", which returns an initialized instance object of type Indicator.
  } {
    if {$user_id eq ""} {
      set user_id [ad_conn user_id]
    }
    if {$activity_version_id eq ""} {
      set activity_version_id [::xolp::Activity require \
                                   -iri [ad_url][ad_conn url] \
                                   -update false \
                                   -return id]
    }
    set storage_timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    if {$end_timestamp eq ""} {
      set end_timestamp $storage_timestamp
    }
    if {$begin_timestamp eq ""} {
      set begin_timestamp $end_timestamp
    }
    if {$activity_verb_id eq ""} {
      set activity_verb [::xolp::ActivityVerb require \
                             -iri "http://dotlrn.org/xolp/activity-verbs/unknown" \
                             -update false]
      set activity_verb_id [$activity_verb set activity_verb_id]
    }
    set attributes [:essential_attributes]
    set bind_attributes [::xolp::util::ltransform $attributes]
    set sql "INSERT INTO xolp_indicator_facts ([join $attributes ,]) VALUES ([join $bind_attributes ,])"
    switch -- $return {
      "id" {
        append sql " RETURNING indicator_id"
        ::xo::dc 1row insert_return_id $sql
        return $indicator_id
      }
      object {
        set attributes [list indicator_id {*}$attributes]
        append sql " RETURNING [join $attributes ,]"
        ::xo::dc 1row insert_return_all $sql
        foreach a $attributes {lappend arguments -$a [set $a]}
        return [::xolp::Indicator new {*}$arguments]
      }
      default {
        ::xo::dc dml insert $sql
        return
      }
    }

  }

  ::xolp::Indicator ad_instproc save {} {
    Save object
  } {
    set attributes [[:info class] essential_attributes]
    :instvar indicator_id {*}$attributes
    foreach a $attributes {
      lappend attribute_update_sql "$a = :$a"
    }
    ::xo::dc dml update "
      UPDATE
        xolp_indicator_facts
      SET
        [join $attribute_update_sql ,]
      WHERE
        indicator_id = :indicator_id
    "
  }

  ::xo::db::require view xolp_indicators_activities_view {
    SELECT
    facts.user_id,
    v.iri AS activity_verb_iri,
    a.iri AS activity_iri,
    facts.begin_timestamp,
    facts.end_timestamp,
    age(facts.end_timestamp, facts.begin_timestamp) AS duration,
    facts.result_numerator,
    facts.result_denominator,
    (result_numerator::numeric / result_denominator::numeric) * 100 AS result_percentage
    FROM
    xolp_indicator_facts facts
    INNER JOIN
    xolp_activity_dimension a USING (activity_version_id)
    INNER JOIN
    xolp_activity_verb_dimension v USING (activity_verb_id)
  }


}

::xo::library source_dependent

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
