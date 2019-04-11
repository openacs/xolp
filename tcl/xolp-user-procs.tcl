::xo::library doc {
  User dimension.

  OpenACS's user table is directly used as dimension table.
  However, we provide an interface for queries that have
  the user as "anchor", such as "get all results for this user".

  @author Michael Aram
  @creation-date 2017
}

namespace eval ::xolp {

  ::xotcl::Object create ::xolp::User -ad_doc {}

  ::xolp::User ad_proc get_result {
    {-user_id:required}
    {-iri:required}
    {-context_iri ""}
    {-policy "best"}
    {-format "%.2f"}
    {-null_as_zero false}
  } {
    Calculate the user's result for the given context, i.e. some kind of
    composite activity (course, test, ...).
    @param policy Define the method for aggregating multiple results per activity.
  } {
    set agg [string map -nocase {best max  worst min  average avg} $policy]
    if {$agg ni "min max avg"} {error "Unknown policy."}
    if {![::xolp::Activity iri_exists_in_db -iri $iri]} {error "Activity $iri does not exists"}

    set sql "SELECT xolp_weighted_result(:user_id::INTEGER,:iri::TEXT,:context_iri::TEXT,:agg::TEXT)"
    set result [::xo::dc get_value get_aggregated_weighted_activity_result $sql]
    if {$result eq "" && $null_as_zero} {
      set result 0
    }
    if {$result eq ""} return
    return [format $format $result]
  }

  ::xolp::User ad_proc get_evaluation {
    {-user_id:required}
    {-iri:required}
    {-context_iri ""}
    {-policy "best"}
    {-null_as_zero false}
  } {
      Get evaluation
  } {
    set activity_version_id [lindex [::xolp::Activity get_object_ids -iri $iri] 0]
    set evalscale [::xolp::EvaluationScale get_evalscales_from_activity_version_id -activity_version_id $activity_version_id]
    if {$evalscale eq ""} {
      error "There is no evaluation scale associated with context '$iri'."
    }
    set result [my get_result \
        -format "%s" \
        -user_id $user_id \
        -context_iri $context_iri \
        -iri $iri \
        -policy $policy \
        -null_as_zero $null_as_zero]
    if {$result eq ""} {
      error "There is no result for user '$user_id' and activity '$iri' in context '$context_iri'.\n
          Depending on the context, you may want to use parameter null_as_zero to handle this."
    }
    set evaluated_results [::xolp::Evaluator evaluate \
        -results $result \
        -evalscales $evalscale]
    set evaluation [dict get $evaluated_results $result $evalscale]
    return $evaluation
  }

  ::xolp::User ad_proc get_competencies {
    {-user_id:required}
    {-policy "best"}
  } {
    @return List of competency IRIs attached to activities for which the user has indicators.
  } {
    set agg [string map -nocase {best max  worst min  average avg} $policy]
    if {$agg ni "min max avg"} {error "Unknown policy."}
    set sql "
      WITH competencies AS (
        SELECT DISTINCT competency_id
        FROM xolp_competency_set_bridge
        WHERE competency_set_id IN (
          SELECT DISTINCT competency_set_id
          FROM xolp_indicator_facts f
          WHERE user_id = :user_id
        )
        AND competency_set_id <> 1
      )
      SELECT iri, xolp_weighted_competency_result(:user_id,iri,:agg)
      FROM xolp_competency_dimension INNER JOIN competencies USING (competency_id)
    "
    set competencies [::xo::dc list_of_lists get_competencies $sql]
    set result_dict ""
    foreach c $competencies {
      lassign $c iri result
      dict set result_dict $iri result $result
    }
    return $result_dict
  }

  ::xolp::User ad_proc get_competencies_recursive {
    {-user_id:required}
    {-policy "best"}
  } {
    @return List of competency IRIs including derived (super) competencies
  } {
    set agg [string map -nocase {best max  worst min  average avg} $policy]
    if {$agg ni "min max avg"} {error "Unknown policy."}
    set competency_dict [my get_competencies -user_id $user_id -policy $policy]
    set competency_iris [dict keys $competency_dict]
    set quoted_list [::xolp::util::ltransform -prefix "'" -suffix "'" $competency_iris]
    # TODO: Avoid the second "poor mans" union clause
    set sql "
      WITH RECURSIVE competency_hierarchy AS (
          SELECT competency_iri, context_competency_iri
          FROM xolp_competency_hierarchy_bridge
          WHERE competency_iri IN ([join $quoted_list ,])
        UNION
          SELECT b.competency_iri, b.context_competency_iri
          FROM xolp_competency_hierarchy_bridge b, competency_hierarchy h
          WHERE b.competency_iri = h.context_competency_iri
      )
        SELECT DISTINCT context_competency_iri, xolp_weighted_competency_result(:user_id,context_competency_iri,:agg)
        FROM competency_hierarchy
      UNION
        SELECT competency_iri, xolp_weighted_competency_result(:user_id,context_competency_iri,:agg)
        FROM xolp_competency_hierarchy_bridge
        WHERE competency_iri IN ([join $quoted_list ,])
    "
    set competencies [::xo::dc list_of_lists get_competencies $sql]
    set result_dict ""
    foreach c $competencies {
      lassign $c iri result
      dict set result_dict $iri result $result
    }
    return $result_dict
  }

  ::xolp::User ad_proc get_competency_result {
    {-user_id:required}
    {-competency_iri ""}
    {-policy "best"}
    {-format "%.2f"}
    {-null_as_zero false}
  } {
      Get competency result
  } {
    set agg [string map -nocase {best max  worst min  average avg} $policy]
    if {$agg ni "min max avg"} {error "Unknown policy."}
    set sql "SELECT xolp_weighted_competency_result(:user_id::INTEGER,:competency_iri::TEXT,:agg::TEXT)"
    set result [::xo::dc get_value get_aggregated_weighted_activity_result $sql]
    if {$result eq ""} return
    return [format $format $result]
  }

  ::xolp::User ad_proc get_competency_evaluation {
    {-user_id:required}
    {-competency_iri:required}
    {-policy "best"}
    {-format "%.2f"}
    {-null_as_zero false}
  } {
      Get competency evaluation
  } {
    set result [my get_competency_result \
        -format "%s" \
        -user_id $user_id \
        -competency_iri $competency_iri \
        -policy $policy \
        -null_as_zero $null_as_zero]
    if {$result eq ""} {
      error "There is no result for user '$user_id' and competency '$competency_iri'."
    }
    set evalscale [::xolp::EvaluationScale get_evalscales_from_competency_iri \
        -competency_iri $competency_iri]
    set evaluated_results [::xolp::Evaluator evaluate \
        -results $result \
        -evalscales $evalscale]
    set evaluation [dict get $evaluated_results $result $evalscale]
    return $evaluation
  }

}

::xo::library source_dependent
