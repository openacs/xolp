::xo::library doc {
  Data model and business logic for activity-related dimensions
  (activity dimension, activity verb dimension).

  @author Michael Aram
  @date 2017
}

::xo::library require xolp-iri-procs

namespace eval ::xolp {

  ####################
  #                  #
  #     ACTIVITY     #
  #                  #
  ####################

  ::xolp::iri::MetaClass create ::xolp::Activity \
    -table_name xolp_activity_dimension \
    -pretty_name "Learning Activity" \
    -id_column activity_version_id \
    -iri_unique false \
    -slots {
      ::xo::db::Attribute create title
      ::xo::db::Attribute create description
      ::xo::db::Attribute create package_id -datatype integer
      ::xo::db::Attribute create package_url
      ::xo::db::Attribute create begin_timestamp -datatype date
      ::xo::db::Attribute create end_timestamp -datatype date
      ::xo::db::Attribute create scd_valid_from -datatype date -default "1900-01-01"
      ::xo::db::Attribute create scd_valid_to -datatype date -default "9999-12-31"
    } -ad_doc {
      Activity Dimension
      Slowly Changing Dimension
      Note, as the pretty_name "Activity" is already taken in OpenACS, we use "Learning Activity"
      (although not all xolp activities necessarily have a learning effect).
    }

  #::xo::db::require index -table xolp_activity_dimension -col "iri text_pattern_ops, scd_valid_from" -unique true
  if {[::xo::db::require exists_table xolp_activity_dimension]} {
    ::xo::dc dml create-index-with-long-default-name "
      CREATE UNIQUE INDEX IF NOT EXISTS xolp_act_dim_iri_scd_valid_from_un_idx
      ON xolp_activity_dimension (iri text_pattern_ops, scd_valid_from)
    "
  }
  ::xo::db::require table xolp_activity_hierarchy_bridge {
    activity_iri TEXT
    context_iri TEXT
    weight_numerator INTEGER
    weight_denominator INTEGER
  }

  #::xo::db::require index -table xolp_activity_context_bridge -col "context_id, activity_iri" -unique true
  if {[::xo::db::require exists_table xolp_activity_hierarchy_bridge]} {
    ::xo::dc dml create-index-with-long-default-name "
      CREATE UNIQUE INDEX IF NOT EXISTS xolp_act_hchy_brdg_ctxiri_actiri_un_idx
      ON xolp_activity_hierarchy_bridge (activity_iri, context_iri)
    "
  }

  ::xolp::Activity ad_proc delete {
    -iri:required
  } {
    In addition to the overloaded 'delete' method of the MetaClass, this delete method
    takes care of deleting references in the xolp_activity_hierarchy_bridge table.
  } {
    next
    return [::xo::dc dml delete_references "DELETE FROM xolp_activity_hierarchy_bridge WHERE activity_iri = :iri"]
  }

  ::xolp::Activity ad_proc iri_exists_in_db {
    {-iri:required}
  } {
    Check whether or not an activity with this iri is already stored in the data base.
    @return Boolean
  } {
    return [::xo::dc get_value select_object "SELECT DISTINCT 1 FROM xolp_activity_dimension WHERE iri = :iri" 0]
  }

  ::xolp::Activity ad_proc current {
    {-iri:required}
  } {
    Get the most recent version of the Activity from the data base.
    @return Instance of ::xolp::Activity
  } {
    if {![my iri_exists_in_db -iri $iri]} {error "Activity $iri does not exists"}
    set activity_version_id [::xo::dc get_value select_current_activity_version "
        SELECT activity_version_id
        FROM xolp_activity_dimension
        WHERE iri = :iri
        ORDER BY scd_valid_to DESC
        LIMIT 1
    "]
    return [::xo::db::Class get_instance_from_db -id $activity_version_id]
  }

  ::xolp::Activity ad_proc get_descendant_object_ids {
    {-iri:required}
    {-current true}
  } {
    @return List of object IDs
  } {
    # TODO: This is suboptimal, improve.
    set oids {}
    foreach {k v} [::xolp::Activity get_descendant_iris -iri $iri] {
      set descendant_object_ids [::xolp::Activity get_object_ids -iri $k]
      lappend oids {*}[expr {$current ? [lindex $descendant_object_ids 0] : $descendant_object_ids}]
    }
    return $oids
  }

  ::xolp::Activity ad_proc get_descendant_iris {
    {-iri:required}
  } {
    @return IRIs of descendant activities (according to xolp_activity_hierarchy_bridge table)
  } {
    if {![my iri_exists_in_db -iri $iri]} {error "Activity $iri does not exists"}
    set sql "
      WITH RECURSIVE heritage_tree AS (
          SELECT activity_iri, 1 as depth
          FROM xolp_activity_hierarchy_bridge
          WHERE context_iri = :iri
        UNION
          SELECT ahb.activity_iri, ht.depth + 1
          FROM heritage_tree ht, xolp_activity_hierarchy_bridge ahb
          WHERE ht.activity_iri = ahb.context_iri
      )
      SELECT activity_iri, depth FROM heritage_tree;
    "
    set descendants [::xo::dc list_of_lists recursive_tree $sql]
    set result_dict ""
    foreach descendant $descendants {
      lassign $descendant iri depth
      dict set result_dict $iri depth $depth
    }
    return $result_dict
  }

  ::xolp::Activity ad_proc new_persistent_object {
    {-iri:required}
    {-title ""}
    {-package_id ""}
    {-package_url ""}
    {-begin_timestamp ""}
    {-end_timestamp ""}
    {-scd_valid_from "NOW()"}
    args
  } {
    @return Instance of ::xolp::Activity
  } {
    if {[my iri_exists_in_db -iri $iri]} {
      set latest_persisted_activity [my current -iri $iri]
      if {[::xo::dc get_value is_newer "SELECT '$scd_valid_from' > '[$latest_persisted_activity scd_valid_to]'"] eq f} {
        error "Activity $iri is already registered.\n$scd_valid_from < [$latest_persisted_activity scd_valid_to]\nUse 'update' (or 'require') instead... "
      }
    }
    next
  }

  ::xolp::Activity ad_proc update {
    {-iri}
    args
  } {
    Updates the activity in the xolp_activity_dimension table by creating a new version.
  } {
    ::xo::dc transaction {
      set old [my current -iri $iri]
      set scd_valid_to_new [::xo::dc get_value roll-step1 "
        UPDATE xolp_activity_dimension
        SET scd_valid_to = NOW()
        WHERE activity_version_id = [$old activity_version_id]
        RETURNING scd_valid_to + INTERVAL '0.000001' SECOND
      "]
      array set argarray $args
      set argarray(-iri) $iri
      set argarray(-scd_valid_from) $scd_valid_to_new
      set new [my new_persistent_object {*}[array get argarray]]
    }
    return $new
  }

  ::xolp::Activity ad_proc is_composite {
    {-iri:required}
  } {
    Check if the activity has subactivities.
    @return Boolean
  } {
    return [::xo::dc get_value select_object "SELECT DISTINCT 1 FROM xolp_activity_hierarchy_bridge WHERE context_iri = :iri" 0]
  }

  ::xolp::Activity ad_instproc add_to_context {
    {-context_iri:required}
    {-weight_numerator 1}
    {-weight_denominator ""}
  } {
    @see ::xolp::Activity->add_to_context
  } {
    [my info class] add_to_context \
        -activity_iri [my iri] \
        -context_iri $context_iri \
        -weight_numerator $weight_numerator \
        -weight_denominator $weight_denominator
  }

  ::xolp::Activity ad_proc add_to_context {
    {-activity_iri:required}
    {-context_iri:required}
    {-weight_numerator 1}
    {-weight_denominator ""}
    {-check true}
  } {
    Associate the activity with this context (e.g. the final test in a community).
    An activity can be associated to multiple contexts.
    Within each context, the activity has a relative weight (among the other activities
    of this context).
    In the standard case, the activities of a context have an equal share of the total weight.
    (E.g. when there are four activities 25% weight each).
    Of course, one can define differentiated weights.
  } {
    ::xo::dc transaction {
      set recalc_siblings [expr {$weight_denominator eq "" ? 1 : 0}]
      if {$weight_denominator eq ""} {
        set weight_denominator [::xo::dc get_value get_activity_count "
          SELECT count(*) + 1
          FROM xolp_activity_hierarchy_bridge
          WHERE context_iri = :context_iri
          AND activity_iri <> :activity_iri
        "]
      }
      set insert_sql "
        INSERT INTO xolp_activity_hierarchy_bridge(context_iri, activity_iri, weight_numerator, weight_denominator)
        VALUES (:context_iri, :activity_iri, :weight_numerator, :weight_denominator)
        ON CONFLICT (context_iri, activity_iri)
          DO UPDATE SET
            weight_numerator = EXCLUDED.weight_numerator,
            weight_denominator = EXCLUDED.weight_denominator
      "
      ::xo::dc dml dbqd..import_activity_context_weights $insert_sql
      if {$recalc_siblings} {
        ::xo::dc dml recalc_activity_context_weights "
          UPDATE
            xolp_activity_hierarchy_bridge
          SET
            weight_denominator = :weight_denominator
          WHERE
            context_iri = :context_iri
        "
      }
      if {$check} {
        # Consistency check
        set weights_add_up_to_one [::xo::dc get_value check_weight_sum "
          SELECT
            ROUND(SUM((weight_numerator::numeric / weight_denominator::numeric) *100)) = 100
          FROM xolp_activity_hierarchy_bridge
          WHERE context_iri = :context_iri
        "]
        if {$weights_add_up_to_one ne "t"} {error "Weights don't add up to 1"}
      }
    }
  }

  ::xolp::Activity ad_proc add_to_competency {
    {-activity_iri:required}
    {-competency_iri:required}
    {-charge_numerator 0}
    {-charge_denominator 100}
  } {
    Attach the activity to a competency, i.e. the activity is considered
    to prove this competency up to a certain level (charge percentage).
  } {
    ::xo::dc transaction {
      set insert_sql "
        INSERT INTO xolp_activity_competency_bridge(activity_iri, competency_iri, charge_numerator, charge_denominator)
        VALUES (:activity_iri, :competency_iri, :charge_numerator, :charge_denominator)
        ON CONFLICT (activity_iri, competency_iri)
          DO UPDATE SET
            charge_numerator = EXCLUDED.charge_numerator,
            charge_denominator = EXCLUDED.charge_denominator
      "
      ::xo::dc dml dbqd..insert_activity_competency_charge $insert_sql
    }
  }

  ::xolp::Activity ad_proc get_competencies {
    {-activity_iri:required}
  } {
    @return List of competency IRIs directly associated with this activity.
  } {
      set sql "
        SELECT DISTINCT competency_iri
        FROM xolp_activity_competency_bridge
        WHERE activity_iri = :activity_iri
      "
      ::xo::dc list_of_lists dbqd..get_activity_competencies $sql
  }

  ::xolp::Activity ad_proc synchronize_competencies {
    {-activity_iri:required}
  } {
    Update indicators to reflect their respective activities' current competencies.
  } {
    ::xo::dc transaction {
      set activity_version_ids [my get_object_ids -iri $activity_iri]
      set competency_iris [my get_competencies -activity_iri $activity_iri]
      set competency_set_id [::xolp::Competency require_set -competency_iris $competency_iris]
      set sql "
        UPDATE xolp_indicator_facts
        SET competency_set_id = :competency_set_id
        WHERE activity_version_id IN ([join $activity_version_ids ,])
        AND competency_set_id <> :competency_set_id
      "
      ::xo::dc dml dbqd..insert_activity_competency_charge $sql
    }
  }

  #
  # Activity Verb
  #

  ::xolp::iri::MetaClass create ::xolp::ActivityVerb \
    -table_name xolp_activity_verb_dimension \
    -id_column activity_verb_id \
    -slots {
       ::xo::db::Attribute create title
       ::xo::db::Attribute create description
    } -ad_doc {
      An activity verb may be referred to as "type of usage" of an activity object.
      For example, a client application may want to differentiate between
      "practicing" and "competing in" an exam.
    }

  ::xolp::ActivityVerb require -iri "http://dotlrn.org/xolp/activity-verbs/unknown"

  # This is currently not used. The idea was to define types of activities, similar
  # to ActivityVerbs, such as "http://dotlrn.org/xolp/activity-types/course".
  # This could also be realized as simple column in the activity_dimension table.

  ::xolp::iri::MetaClass create ::xolp::ActivityType \
    -table_name xolp_activity_types \
    -id_column activity_type_id

}

::xo::library source_dependent
