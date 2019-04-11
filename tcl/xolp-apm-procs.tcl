::xo::library doc {
  OpenACS package manager (APM) callback implementation.

  @author Michael Aram
  @creation-date 2017
}

namespace eval ::xolp {}
namespace eval ::xolp::apm {

  ad_proc -private ::xolp::apm::after_install {} {
    ::xolp::EvaluationSchema require \
        -iri "https://dotlrn.org/xolp/evaluation-schemas/at-five-to-one" \
        -title "5 to 1" \
        -description "Five levels from 5 (worst) to 1 (best). All except 5 are positive. (Austria)" \
        -level_names {five four three two one} \
        -positive_threshold_index 0

    ::xolp::EvaluationSchema require \
        -iri "https://dotlrn.org/xolp/evaluation-schema/de-six-to-one" \
        -title "6 to 1" \
        -description "Six levels from 6 (worst) to 1 (best). All except 6 and 5 are positive. (Germany)" \
        -level_names {six five four three two one} \
        -positive_threshold_index 1

    ::xolp::EvaluationSchema require \
        -iri "https://dotlrn.org/xolp/evaluation-schema/ch-one-to-six" \
        -title "1.0 to 6.0" \
        -description "Eleven levels from 1.0 (worst) to 6.0 (best) in 0.5 steps. 1 to 3.5 are negative, 4.0 to 6.0 are positive. (Switzerland)" \
        -level_names {6.0 5.5 5.0 4.5 4.0 3.5 3.0 2.5 2.0 1.5 1.0} \
        -positive_threshold_index 5

    ::xolp::EvaluationSchema require \
        -iri "https://dotlrn.org/xolp/evaluation-schemas/negative-positive" \
        -title "Negative / positive" \
        -level_names {negative positive} \
        -positive_threshold_index 0

    set evaluation_schema [::xolp::EvaluationSchema require \
        -iri "https://dotlrn.org/xolp/evaluation-schemas/notattempted-attempted" \
        -title "Not attempted / attempted" \
        -level_names {"not attempted" "attempted"} \
        -positive_threshold_index -1]

    ::xolp::EvaluationScale require \
        -iri "https://dotlrn.org/xolp/evaluation-scales/notattempted-attempted" \
        -evalschema_id [$evaluation_schema object_id] \
        -title "Not attempted - 50 - Attempted" \
        -thresholds 50


    ::xolp::ActivityVerb require -iri "http://adlnet.gov/expapi/verbs/experienced"
    ::xolp::ActivityVerb require -iri "http://adlnet.gov/expapi/verbs/attempted"
    ::xolp::ActivityVerb require -iri "http://adlnet.gov/expapi/verbs/completed"
    ::xolp::ActivityVerb require -iri "http://adlnet.gov/expapi/verbs/passed"
    ::xolp::ActivityVerb require -iri "http://adlnet.gov/expapi/verbs/failed"

    ::xolp::ActivityVerb require -iri "http://dotlrn.org/xolp/activity-verbs/practiced"
    ::xolp::ActivityVerb require -iri "http://dotlrn.org/xolp/activity-verbs/competed"

    ::xolp::ActivityType require -iri "http://adlnet.gov/expapi/activities/assessment"
    ::xolp::ActivityType require -iri "http://adlnet.gov/expapi/activities/question"
  }

  ad_proc -private ::xolp::apm::before_uninstall {} {
    # drop functions
    ::xo::dc dml drop "DROP FUNCTION IF EXISTS xolp_activity_dimension__upsert(TEXT, TEXT, INTEGER, TEXT, INTEGER, TIMESTAMP WITH TIME ZONE)"
    ::xo::dc dml drop "DROP FUNCTION IF EXISTS xolp_weighted_result(INTEGER, TEXT, TEXT, TEXT)"
    ::xo::dc dml drop "DROP FUNCTION IF EXISTS xolp_weighted_competency_result(INTEGER, TEXT, TEXT, TEXT, TEXT)"
    ::xo::dc dml drop "DROP FUNCTION IF EXISTS xolp_compare_array_as_set(anyarray,anyarray)"
    
    # drop tables
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_activity_hierarchy_bridge CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_indicator_facts CASCADE"
    ::xo::dc dml drop "DROP VIEW IF EXISTS xolp_begin_date_dimension CASCADE"
    ::xo::dc dml drop "DROP VIEW IF EXISTS xolp_end_date_dimension CASCADE"
    ::xo::dc dml drop "DROP VIEW IF EXISTS xolp_begin_time_dimension CASCADE"
    ::xo::dc dml drop "DROP VIEW IF EXISTS xolp_end_time_dimension CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_competency_hierarchy_bridge CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_activity_competency_bridge CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_evalscale_competency_bridge CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_competency_set_bridge CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_competency_set_dimension CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_evalscale_activity_bridge CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_time_dimension CASCADE"
    ::xo::dc dml drop "DROP TABLE IF EXISTS xolp_date_dimension CASCADE"
    
    # triggers
    ::xo::dc dml drop "DROP FUNCTION IF EXISTS xolp_indicator_upsert_tr()"
    
    
    set classes {
      ::xolp::Activity ::xolp::EvaluationScale ::xolp::EvaluationSchema
      ::xolp::ActivityVerb ::xolp::ActivityType ::xolp::Competency
    }
    foreach object_type $classes {
      # Note: ::xo::db:Class->drop_type is currently broken on Learn@WU
      ::xo::dc dml delete_instances "delete from [$object_type table_name]"
      ::xo::dc dml delete_instances "delete from acs_objects where object_type = :object_type"
      ::xo::dc dml drop_table "drop table [$object_type table_name] CASCADE"
      ::xo::db::sql::acs_object_type drop_type -object_type $object_type -drop_children_p t -drop_table_p f
    }
  }

}
