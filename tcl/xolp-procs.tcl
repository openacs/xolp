::xo::library doc {
  XOLP – Learning Performance Service

  @author Michael Aram
  @date 2017
}

::xo::library require xolp-indicator-procs

namespace eval ::xolp {

  #
  #
  # xolp_weighted_result()
  #
  #

  ::xo::dc dml create_function_xolp_weighted_result {
    CREATE OR REPLACE FUNCTION xolp_weighted_result(vuser_id INTEGER, viri TEXT, vctxiri TEXT DEFAULT NULL, vagg TEXT DEFAULT 'AVG') RETURNS NUMERIC AS $$
      --
      -- This function retrieves a particular user's result for an activity
      -- and weighs it according to the activity's contextual weight.
      -- For activities without an explicitly assigned result value, it
      -- recurses down the activity tree.
      --

      DECLARE
        result NUMERIC;
        parent_node_weight NUMERIC;
      BEGIN
        --
        -- Current tree node
        --
        SELECT
            -- If the context is NULL/unknown/invalid, then we take a weight of 100%
            COALESCE((weight_numerator::numeric / weight_denominator::numeric), 1)
          *
            CASE UPPER(vagg)
              -- Here, we aggregate potential multiple attempts to the same activity.
              WHEN 'MIN' THEN MIN((COALESCE(result_numerator::numeric, 0) / COALESCE(result_denominator::numeric, 100)) * 100)
              WHEN 'MAX' THEN MAX((COALESCE(result_numerator::numeric, 0) / COALESCE(result_denominator::numeric, 100)) * 100)
              ELSE            AVG((COALESCE(result_numerator::numeric, 0) / COALESCE(result_denominator::numeric, 100)) * 100)
            END
          AS weighted_result_percentage
        INTO result
        FROM
          xolp_activity_dimension a
          -- Join weights. If the context is NULL/unknown/invalid), then nothing will be left-joined and the weight will be 1.
          LEFT OUTER JOIN xolp_activity_hierarchy_bridge h ON (a.iri = h.activity_iri AND h.context_iri = vctxiri)
          -- Join results.
          LEFT OUTER JOIN xolp_indicator_facts f ON a.activity_version_id = f.activity_version_id AND vuser_id = f.user_id
        WHERE
            a.iri = viri
          AND
            -- We need this in order to get NULL instead of 0 if the user hasn't experienced the activity.
            vuser_id = f.user_id
        GROUP BY a.iri, weight_numerator, weight_denominator;

        --
        -- Current node weight
        --

        SELECT (weight_numerator::numeric / weight_denominator::numeric)
        INTO parent_node_weight
        FROM xolp_activity_hierarchy_bridge
        WHERE activity_iri = viri AND context_iri = vctxiri;
        IF parent_node_weight IS NULL THEN
          parent_node_weight := 1;
        END IF;
        -- RAISE INFO 'WEIGHT % - % - %', vctxiri, viri, parent_node_weight;

        --
        -- Subtree recursion
        --

        IF result IS NULL THEN
          SELECT
              parent_node_weight
            *
              -- Here, we sum up the weighted results of subactivities.
              SUM(xolp_weighted_result(vuser_id,activity_iri,viri,vagg))
          INTO result
          FROM xolp_activity_hierarchy_bridge
          WHERE context_iri = viri;
        END IF;
      -- RAISE INFO 'RESULT % - %',viri , result;
      RETURN result;
      END;
    $$ LANGUAGE plpgsql;
  }

  #
  #
  # xolp_weighted_competency_result()
  #
  #

  ::xo::dc dml create_function_xolp_weighted_competency_result {
    CREATE OR REPLACE FUNCTION xolp_weighted_competency_result(vuser_id INTEGER, vcmpyiri TEXT, vagg TEXT DEFAULT 'MAX', vactagg TEXT DEFAULT 'MAX', vsubcmpyagg TEXT DEFAULT 'SUM') RETURNS NUMERIC AS $$
      DECLARE
        result NUMERIC;
      BEGIN
        --
        -- Case 1 Get any activities that are directly attached to this competency
        --
        WITH sub_activity_results AS (
            SELECT
              activity_iri AS iri,
              xolp_weighted_result(vuser_id::INTEGER, activity_iri, NULL, vactagg::TEXT) AS weighted_result,
              (charge_numerator::numeric / charge_denominator::numeric) AS weight_percentage
            FROM xolp_activity_competency_bridge
            WHERE competency_iri = vcmpyiri
        )
        SELECT
           CASE UPPER(vagg)
             WHEN 'MIN' THEN MIN(weighted_result * weight_percentage)
             WHEN 'MAX' THEN MAX(weighted_result * weight_percentage)
             WHEN 'AVG' THEN AVG(weighted_result * weight_percentage)
             ELSE            SUM(weighted_result * weight_percentage)
           END
          AS weighted_result_percentage
        INTO result
        FROM sub_activity_results;

        --
        -- Case 2 Get any sub-competencies of this competency
        --
        IF result IS NULL THEN
          WITH sub_competency_results AS (
              SELECT
                competency_iri AS iri,
                xolp_weighted_competency_result(vuser_id, competency_iri, vagg, vactagg, vsubcmpyagg) as weighted_result,
                (weight_numerator::numeric / weight_denominator::numeric) AS weight_percentage
              FROM xolp_competency_hierarchy_bridge
              WHERE context_competency_iri = vcmpyiri
          )
          SELECT SUM(weighted_result * weight_percentage) AS weighted_result_percentage
          INTO result
          FROM sub_competency_results;
        END IF;
        -- RAISE INFO 'WEIGHTED COMPETENCY RESULT % - %', vcmpyiri, result;
        RETURN result;
      END;
    $$ LANGUAGE plpgsql;
  }

  ::xo::dc dml create_function_xolp_compare_array_as_set {
    CREATE OR REPLACE FUNCTION xolp_compare_array_as_set(anyarray,anyarray) RETURNS boolean AS $$
    SELECT CASE
      WHEN array_dims($1) <> array_dims($2) THEN
        'f'
      WHEN array_length($1,1) <> array_length($2,1) THEN
        'f'
      ELSE
        NOT EXISTS (
            SELECT 1
            FROM unnest($1) a
            FULL JOIN unnest($2) b ON (a=b)
            WHERE a IS NULL or b IS NULL
        )
      END
    $$ LANGUAGE 'sql' IMMUTABLE;
  }

  #
  #
  # Some numbers; only for development
  #
  #

  ::xo::db::require view xolp_statistics_view {
    SELECT
      (SELECT count(DISTINCT user_id) from xolp_indicator_facts) AS users,
      (SELECT count(*) from xolp_indicator_facts) AS indicators,
      (SELECT count(DISTINCT iri) from xolp_activity_dimension) AS activities,
      (SELECT count(*) from xolp_activity_dimension) AS activity_versions,
      (SELECT count(*) from xolp_activity_verb_dimension) AS activity_verbs,
      (SELECT count(*) from xolp_evalschemas) AS evalschemas,
      (SELECT count(*) from xolp_evalscales) AS evalscales;
  }

#   #
#   #
#   # Development stub: CSV Import
#   #
#   #
# 
#   package require csv
#   package require struct::matrix
# 
#   ::xotcl::Object create ::xolp::Importer -ad_doc {}
# 
#   Importer ad_proc import_csv {
#     {-file:required}
#     {-activity_iri_base:required}
#   } {
#     @param headers Name each
#     @param columns Provides a header for each column in the csv.
#                    Columns with known headers are processed, others are ignored.
#   } {
#     oacs_util::csv_foreach \
#       -file $file \
#       -array_name row {
#           set iri ${activity_iri_base}[ns_sha1 $row(activity)]
#           ::xolp::Activity require \
#                   -iri $iri \
#                   -title $row(activity)
#           ::xolp::Indicator insert \
#                   -user_id 1 \
#                   -activity_version_id $activity_version_id \
#                   -end_timestamp "2016-12-20 09:58:00" \
#                   -result_numerator 100 \
#                   -result_denominator 100
#       }
#   }

}

::xo::library source_dependent
