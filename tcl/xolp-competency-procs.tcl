::xo::library doc {
  Data model prototype for competency (set) dimension.

  @author Michael Aram
  @creation-date 2017
}

::xo::library require xolp-indicator-procs

namespace eval ::xolp {

  #
  # Competency Dimension
  #

  ::xolp::iri::MetaClass create ::xolp::Competency \
    -table_name xolp_competency_dimension \
    -id_column competency_id \
    -slots {
       ::xo::db::Attribute create title -datatype text
       ::xo::db::Attribute create description -datatype text
    } -ad_doc {
      A competency is a demand-oriented human potentiality for action that can be learned
      and involves cognitive and non-cognitive elements (see Stahl and Wild 2006).
    }

  ::xolp::Competency require -iri "http://dotlrn.org/xolp/competencies/unknown"

  ::xolp::Competency ad_proc require_set {
    {-competency_iris:required}
  } {
    Get the competency set or create it if it does not exist.
    @return competency_set_id
  } {
    if {[llength $competency_iris] eq 0} {error "Empty list provided."}
    if {![my all_exist -competency_iris $competency_iris]} {error "List contains unknown competencies."}
    ::xo::dc transaction {
      set set_id [my get_set_id -competency_iris $competency_iris]
      if {$set_id eq ""} {
        set quoted_list [::xolp::util::ltransform -prefix "'" -suffix "'" $competency_iris]
        set set_id [::xo::dc get_value insert_set "
          INSERT INTO xolp_competency_set_dimension
          DEFAULT VALUES
          RETURNING competency_set_id;
        "]
        ::xo::dc dml insert_set "
          INSERT INTO xolp_competency_set_bridge(competency_set_id,competency_id)
          SELECT :set_id, competency_id
          FROM xolp_competency_dimension
          WHERE iri IN ([join $quoted_list ,])
        "
      }
    }
    return $set_id
  }

  ::xolp::Competency ad_proc get_set_id {
    {-competency_iris:required}
  } {
    @return competency_set_id
  } {
    set quoted_list [::xolp::util::ltransform -prefix "'" -suffix "'" $competency_iris]
    ::xo::dc get_value get_competency_set_id "
      SELECT competency_set_id
      FROM xolp_competency_set_bridge
      GROUP BY competency_set_id
      HAVING xolp_compare_array_as_set(
        array_agg(competency_id),
        (select array_agg(competency_id) from xolp_competency_dimension where iri IN ([join $quoted_list ,]))
        ) = TRUE;
    "
  }

  ::xolp::Competency ad_proc all_exist {
    {-competency_iris:required}
  } {
    Check if all competencies exist.
  } {
    if {[llength $competency_iris] eq 0} {error "Empty list provided"}
    set quoted_list [::xolp::util::ltransform -prefix "'" -suffix "'" $competency_iris]
    set nr_known_competencies [::xo::dc get_value count_competencies "
      SELECT count(*)
      FROM xolp_competency_dimension
      WHERE iri IN ([join $quoted_list ,])
    "]
    return [expr {[llength $competency_iris] eq $nr_known_competencies}]
  }

  ::xolp::Competency ad_proc exists_set {
    {-competency_iris:required}
  } {
    Get the competency set id, or create it if it does not exist
  } {
    set quoted_list [::xolp::util::ltransform -prefix "'" -suffix "'" $competency_iris]
    ::xo::dc get_value check_competency_set_exists "
      SELECT 1
      FROM xolp_competency_set_bridge
      GROUP BY competency_set_id
      HAVING xolp_compare_array_as_set(
        array_agg(competency_id),
        (select array_agg(competency_id) from xolp_competency_dimension where iri IN ([join $quoted_list ,]))
      ) = TRUE;
    " 0
  }

  ::xolp::Competency ad_proc add_to_competency {
    {-competency_iri:required}
    {-context_competency_iri:required}
    {-weight_numerator 1}
    {-weight_denominator ""}
    {-check true}
  } {
    Adds a competency as subcomponent to another competency.
    A competency can have more than one super/context-competencies.
  } {
    # TODO: This should be refactored to be more DRY with respect to add_to_context
    ::xo::dc transaction {
      set recalc_siblings [expr {$weight_denominator eq "" ? 1 : 0}]
      if {$weight_denominator eq ""} {
        set weight_denominator [::xo::dc get_value get_subcompetency_count "
          SELECT count(*) + 1
          FROM xolp_competency_hierarchy_bridge
          WHERE context_competency_iri = :context_competency_iri
          AND competency_iri <> :competency_iri
        "]
      }
      set insert_sql "
        INSERT INTO xolp_competency_hierarchy_bridge(context_competency_iri, competency_iri, weight_numerator, weight_denominator)
        VALUES (:context_competency_iri, :competency_iri, :weight_numerator, :weight_denominator)
        ON CONFLICT (context_competency_iri, competency_iri)
          DO UPDATE SET
            weight_numerator = EXCLUDED.weight_numerator,
            weight_denominator = EXCLUDED.weight_denominator
      "
      ::xo::dc dml dbqd..insert_competency_context_weights $insert_sql
      if {$recalc_siblings} {
        ::xo::dc dml recalc_competency_context_weights "
          UPDATE
            xolp_competency_hierarchy_bridge
          SET
            weight_denominator = :weight_denominator
          WHERE
            context_competency_iri = :context_competency_iri
        "
      }
      if {$check} {
        # Consistency check
        set weights_add_up_to_one [::xo::dc get_value check_weight_sum "
          SELECT
            ROUND(SUM((weight_numerator::numeric / weight_denominator::numeric) *100)) = 100
          FROM xolp_competency_hierarchy_bridge
          WHERE context_competency_iri = :context_competency_iri
        "]
        if {$weights_add_up_to_one ne "t"} {error "Weights don't add up to 1"}
      }
    }
  }

  #
  # Bridge: Indicators (facts) reference sets of competencies
  #
  # Refer to Kimball's book "The Data Warehouse Toolkit" p. 347 - Figure 14-4

  ::xo::db::require table xolp_competency_set_dimension {
    competency_set_id {SERIAL PRIMARY KEY}
  } {
    INSERT INTO xolp_competency_set_bridge DEFAULT VALUES;
  }

  ::xo::db::require table xolp_competency_set_bridge {
    competency_set_id {INTEGER NOT NULL REFERENCES xolp_competency_set_dimension ON DELETE CASCADE}
    competency_id {INTEGER NOT NULL REFERENCES xolp_competency_dimension ON DELETE CASCADE}
  } {
    INSERT INTO xolp_competency_set_bridge(competency_set_id,competency_id)
    SELECT 1, competency_id FROM xolp_competency_dimension
    WHERE iri = 'http://dotlrn.org/xolp/competencies/unknown';
  }

  #
  # Bridge: Connect Activities to Competencies
  #

  ::xo::db::require table xolp_activity_competency_bridge {
    activity_iri TEXT
    competency_iri {TEXT REFERENCES xolp_competency_dimension(iri) ON DELETE CASCADE}
    charge_numerator INTEGER
    charge_denominator {INTEGER CHECK (charge_denominator >= charge_numerator)}
  }
  if {[::xo::db::require exists_table xolp_activity_competency_bridge]} {
    ::xo::dc dml create-index-with-long-default-name "
      CREATE UNIQUE INDEX IF NOT EXISTS xolp_act_cmpy_brdg_cmpyiri_actiri_un_idx
      ON xolp_activity_competency_bridge (activity_iri, competency_iri)
    "
  }

  #
  # Bridge: Connect Competencies to Competencies
  #

  ::xo::db::require table xolp_competency_hierarchy_bridge {
    competency_iri {TEXT REFERENCES xolp_competency_dimension(iri) ON DELETE CASCADE}
    context_competency_iri {TEXT REFERENCES xolp_competency_dimension(iri) ON DELETE CASCADE}
    weight_numerator INTEGER
    weight_denominator {INTEGER CHECK (weight_denominator >= weight_numerator)}
  }
  if {[::xo::db::require exists_table xolp_competency_hierarchy_bridge]} {
    ::xo::dc dml create-index-with-long-default-name "
      CREATE UNIQUE INDEX IF NOT EXISTS xolp_cmpy_hchy_brdg_ctxiri_cmpyiri_un_idx
      ON xolp_competency_hierarchy_bridge (competency_iri, context_competency_iri)
    "
  }

}

::xo::library source_dependent
