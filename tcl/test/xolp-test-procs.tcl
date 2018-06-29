ad_library {
  Regression test suite

  @author Michael Aram
  @creation-date 2017

}

#######################
#                     #
#   Test Components   #
#                     #
#######################

#
# Activity Verb
#

aa_register_component \
    activity_verb_create \
    "Create an Activity Verb" {
        aa_export_vars {activity_verb}
        set activity_verb [::xolp::ActivityVerb new_persistent_object \
                -iri "https://example.com/verb/perform" \
                -title [ad_generate_random_string] \
                -description [ad_generate_random_string]]
        set activity_verb_id [$activity_verb object_id]
        $activity_verb destroy
        set activity_verb [::xo::db::Class get_instance_from_db -id $activity_verb_id]

        aa_true "Requiring an arbitrary activity verb succeeded" {
            [info exists activity_verb]
            && [::xotcl::Object isobject $activity_verb]
            && [$activity_verb exists object_id]
            && [$activity_verb iri] eq "https://example.com/verb/perform"
        }
    }

aa_register_component \
    activity_verb_require \
    "Require an Activity Verb" {
        aa_export_vars {activity_verb}
        set activity_verb [::xolp::ActivityVerb require \
                -iri "http://adlnet.gov/expapi/verbs/experienced" \
                -title "Ooops" \
                -description [ad_generate_random_string]]

        aa_log "ActivityVerb ID: [$activity_verb set object_id]"
        aa_true "Requiring the standard activity verb succeeded" {
            [info exists activity_verb]
            && [::xotcl::Object isobject $activity_verb]
            && [$activity_verb exists object_id]
            && [$activity_verb title] eq "Ooops"
        }

        set title [ad_generate_random_string]
        set activity_verb [::xolp::ActivityVerb require \
                -iri "http://adlnet.gov/expapi/verbs/experienced" \
                -title $title \
                -description [ad_generate_random_string]]
        aa_log "ActivityVerb ID: [$activity_verb set object_id]"
        aa_true "Requiring the standard activity verb (with fixed typos) succeeded" {
            [info exists activity_verb]
            && [::xotcl::Object isobject $activity_verb]
            && [$activity_verb exists object_id]
            && [$activity_verb title] eq $title
        }
    }

aa_register_component \
    activity_verb_delete \
    "Delete an Activity Verb" {
        aa_export_vars {activity_verb}
        set activity_verb_id [$activity_verb object_id]
        aa_true "activity_verb exists" {
            [::xo::dc get_value select_object {select 1 from acs_objects where object_id = :activity_verb_id} 0]
        }
        aa_true "activity_verb exists" {
            [::xo::dc get_value select_object {select 1 from xolp_activity_verb_dimension where activity_verb_id = :activity_verb_id} 0]
        }
        $activity_verb delete
        aa_false "Deleting activity_verb succeeded" {
            [::xo::dc get_value select_object {select 1 from acs_objects where object_id = :activity_verb_id} 0]
        }
        aa_false "Deleting activity_verb succeeded" {
            [::xo::dc get_value select_object {select 1 from xolp_activity_verb_dimension where activity_verb_id = :activity_verb_id} 0]
        }
    }

#
# Evaluation Schema
#

aa_register_component \
    evaluation_schema_create \
    "Create an Evaluation Schema" {
        aa_export_vars {evaluation_schema}
        catch {::xolp::EvaluationSchema new_persistent_object \
                -iri "https://example.com/xyz" \
                -title [ad_generate_random_string] \
                -description [ad_generate_random_string] \
                -level_names {x y z} \
                -positive_threshold_index 2} catch_result
        aa_log $catch_result
        aa_true "Requiring a schema with a bad positive_threshold_index errored as expected" {
            [string match "*positive_threshold_index must refer*" $catch_result]
        }

        set evaluation_schema [::xolp::EvaluationSchema new_persistent_object \
                -iri "https://example.com/abcd" \
                -title [ad_generate_random_string] \
                -description [ad_generate_random_string] \
                -level_names {a b c d} \
                -positive_threshold_index 1]
        set evaluation_schema_id [$evaluation_schema object_id]
        $evaluation_schema destroy
        set evaluation_schema [::xo::db::Class get_instance_from_db -id $evaluation_schema_id]

        aa_true "Requiring an arbitrary evaluation schema succeeded" {
            [info exists evaluation_schema]
            && [::xotcl::Object isobject $evaluation_schema]
            && [$evaluation_schema exists object_id]
            && [$evaluation_schema iri] eq "https://example.com/abcd"
            && [$evaluation_schema level_names] eq {a b c d}
        }
    }

aa_register_component \
    evaluation_schema_require \
    "Require an Evaluation Schema" {
        aa_export_vars {evaluation_schema}
        set evaluation_schema [::xolp::EvaluationSchema require \
                -iri "https://dotlrn.org/xolp/evaluation-schemas/at-five-to-one" \
                -title "Ooops" \
                -description "Five levels from 5 (worst) to 1 (best). All except 5 are positive. (Austria)" \
                -level_names {five four three two one} \
                -positive_threshold_index 0]

        aa_log "EvaluationSchema ID: [$evaluation_schema set object_id]"
        aa_true "Requiring the standard evaluation schema succeeded" {
            [info exists evaluation_schema]
            && [::xotcl::Object isobject $evaluation_schema]
            && [$evaluation_schema exists object_id]
            && [$evaluation_schema title] eq "Ooops"
        }

        set evaluation_schema [::xolp::EvaluationSchema require \
                -iri "https://dotlrn.org/xolp/evaluation-schemas/at-five-to-one" \
                -title "5 to 1" \
                -description "Five levels from 5 (worst) to 1 (best). All except 5 are positive. (Austria)" \
                -level_names {five four three two one} \
                -positive_threshold_index 0]
        aa_log "EvaluationSchema ID: [$evaluation_schema set object_id]"
        aa_true "Requiring the standard evaluation schema (with fixed typos) succeeded" {
            [info exists evaluation_schema]
            && [::xotcl::Object isobject $evaluation_schema]
            && [$evaluation_schema exists object_id]
            && [$evaluation_schema title] eq "5 to 1"
        }
    }

aa_register_component \
    evaluation_schema_delete \
    "Delete an Evaluation Schema" {
        aa_export_vars {evaluation_schema}
        set evaluation_schema_id [$evaluation_schema object_id]
        aa_true "evaluation_schema exists" {
            [::xo::dc get_value select_object { select 1 from acs_objects where object_id = :evaluation_schema_id } 0]
        }
        aa_true "evaluation_schema exists" {
            [::xo::dc get_value select_object { select 1 from xolp_evalschemas where evalschema_id = :evaluation_schema_id } 0]
        }
        $evaluation_schema delete
        aa_false "Deleting evaluation_schema succeeded" {
            [::xo::dc get_value select_object { select 1 from acs_objects where object_id = :evaluation_schema_id } 0]
        }
        aa_false "Deleting evaluation_schema succeeded" {
            [::xo::dc get_value select_object { select 1 from xolp_evalschemas where evalschema_id = :evaluation_schema_id } 0]
        }
    }

#
# Evaluation Scale
#

aa_register_component \
    evaluation_scale_create \
    "Create an Evaluation Scale" {
        aa_export_vars {evaluation_schema evaluation_scale}
        set evaluation_scale_title "Test Evaluation Scale 60-70-80-90"
        set evaluation_scale [::xolp::EvaluationScale new_persistent_object \
                -title $evaluation_scale_title \
                -evalschema_id [$evaluation_schema object_id] \
                -thresholds "60 70 80 90"]
        aa_true "Persisting a new evaluation scale succeeded" {
            [info exists evaluation_scale]
            && [::xotcl::Object isobject $evaluation_scale]
            && [$evaluation_scale exists object_id]
            && [$evaluation_scale title] eq $evaluation_scale_title
            && [llength [$evaluation_scale thresholds]] eq 4
            && [llength [$evaluation_scale levels]] eq 5
        }
        aa_log "evaluation_scale ID: [$evaluation_scale set object_id]"
    }

aa_register_component \
    evaluation_scale_require \
    "Require an Evaluation Scale" {
        aa_export_vars {evaluation_schema evaluation_scale}
        set evaluation_scale_title "Test Evaluation Scale Bad/Good"
        set evaluation_scale [::xolp::EvaluationScale require \
                -iri "http://example.com/" \
                -title "Ooops" \
                -thresholds "1 99"]
        aa_true "Persisting a new evaluation scale succeeded" {
            [info exists evaluation_scale]
            && [::xotcl::Object isobject $evaluation_scale]
            && [$evaluation_scale exists object_id]
            && [$evaluation_scale title] eq "Ooops"
            && [llength [$evaluation_scale thresholds]] eq 2
            && [llength [$evaluation_scale levels]] eq 3
        }
        aa_log "evaluation_scale ID: [$evaluation_scale set object_id]"

        set evaluation_scale [::xolp::EvaluationScale require \
                -iri "http://example.com/" \
                -title $evaluation_scale_title \
                -thresholds "50"]
        aa_true "Persisting a new evaluation scale succeeded" {
            [info exists evaluation_scale]
            && [::xotcl::Object isobject $evaluation_scale]
            && [$evaluation_scale exists object_id]
        }
        aa_log "[$evaluation_scale serialize]"
        aa_equals "Title" [$evaluation_scale title] $evaluation_scale_title
        aa_equals "Thresholds" [llength [$evaluation_scale thresholds]] 1
        aa_equals "Levels" [llength [$evaluation_scale levels]] 2
        aa_log "evaluation_scale ID: [$evaluation_scale set object_id]"
    }

aa_register_component \
    evaluation_scale_delete \
    "Delete an Evaluation Scale" {
        aa_export_vars {evaluation_scale}
        set evaluation_scale_id [$evaluation_scale object_id]
        aa_true "evaluation_scale exists" {
            [::xo::dc get_value select_object { select 1 from acs_objects where object_id = :evaluation_scale_id } 0]
        }
        aa_true "evaluation_scale exists" {
            [::xo::dc get_value select_object { select 1 from xolp_evalscales where evalscale_id = :evaluation_scale_id } 0]
        }
        $evaluation_scale delete
        aa_false "Deleting evaluation_scale succeeded" {
            [::xo::dc get_value select_object { select 1 from acs_objects where object_id = :evaluation_scale_id } 0]
        }
        aa_false "Deleting evaluation_scale succeeded" {
            [::xo::dc get_value select_object { select 1 from xolp_evalscales where evalscale_id = :evaluation_scale_id } 0]
        }
    }

#
# Activity
#

aa_register_component \
    activity_create \
    "Register an Activity in the activity dimension table" {
        aa_export_vars {iri}
        set iri "http://example.com/a1"
        set activity_title "Test Activity"
        set activity [::xolp::Activity new_persistent_object \
                -iri $iri -title "Oopsy.."]
        set object_id [$activity object_id]
        $activity destroy
        ::xo::db::Class get_instance_from_db -id $object_id
        aa_true "Persisting a new Activity succeeded" {
            [info exists activity]
            && [::xotcl::Object isobject $activity]
            && [$activity exists object_id]
            && [$activity title] eq "Oopsy.."
        }
    }

aa_register_component \
    activity_update \
    "Update an Activity in the activity dimension table" {
        aa_export_vars {iri}
        set new_title "New Title [ad_generate_random_string]"
        set activity [::xolp::Activity update \
              -iri $iri \
              -title $new_title]
        aa_log "Newly inserted Activity Dimension row: $activity"
        aa_true "Persisting a new Activity succeeded" {
            [info exists activity]
            && [::xotcl::Object isobject $activity]
            && [$activity exists object_id]
            && [$activity iri] eq $iri
            && [$activity title] eq $new_title
        }
        set iri [$activity iri]
    }

aa_register_component \
    activity_require \
    "Require an Activity" {
        aa_export_vars {activity}
        set activity_title "Test Activity"
        set activity [::xolp::Activity require \
                -iri "http://example.com/a1" -title "Oopsi.."]
        aa_true "Persisting a new Activity succeeded" {
            [info exists activity]
            && [::xotcl::Object isobject $activity]
            && [$activity exists object_id]
            && [$activity title] eq "Oopsi.."
        }
        aa_log "activity ID: [$activity set object_id]"
        $activity destroy

        set activity [::xolp::Activity require \
                -iri "http://example.com/a1" \
                -title $activity_title]
        aa_true "Persisting a new Activity succeeded" {
            [info exists activity]
            && [::xotcl::Object isobject $activity]
            && [$activity exists object_id]
            && [$activity title] eq $activity_title
        }
        aa_log "activity ID: [$activity set object_id]"
    }


aa_register_component \
    activity_delete \
    "Delete an Activity (all versions) from the activity dimension table" {
        aa_export_vars {iri}
        aa_true "activity exists" {[::xolp::Activity iri_exists_in_db -iri $iri]}
        ::xolp::Activity delete -iri $iri
        aa_false "activity does not exist" {[::xolp::Activity iri_exists_in_db -iri $iri]}
    }

#
# Indicator
#

aa_register_component \
    indicator_create_simple \
    "Create an Indicator" {
        aa_export_vars {iri indicator}
        set activity [::xolp::Activity current -iri $iri]
        set activity_version_id [$activity activity_version_id]
        set end_timestamp [dt_systime]
        set result_numerator [format "%.0f" [expr {[random] * 100}]]
        set indicator [::xolp::Indicator insert \
              -activity_version_id $activity_version_id \
              -end_timestamp $end_timestamp \
              -result_numerator $result_numerator \
              -return object]
        # TODO - Timezone...
        aa_log [$indicator serialize]
        aa_true "Persisting a new indicator succeeded" {
            [$indicator activity_version_id] eq $activity_version_id
            && [$indicator user_id] eq [ad_conn user_id]
            && [$indicator result_numerator] eq $result_numerator
            && [$indicator result_denominator] eq 100
            && [$indicator begin_timestamp] eq "${end_timestamp}+01"
            && [$indicator end_timestamp] eq "${end_timestamp}+01"
        }
    }

aa_register_component \
    indicator_create_full \
    "Create an Indicator" {
        aa_export_vars {iri indicator}
        set activity [::xolp::Activity current -iri $iri]
        set activity_version_id [$activity activity_version_id]
        set result_numerator [format "%.0f" [expr {[random] * 100}]]
        set indicator [::xolp::Indicator insert \
          -user_id [ad_conn user_id] \
          -activity_version_id $activity_version_id \
          -begin_timestamp "2014-01-01 00:00:00" \
          -end_timestamp "2014-01-03 00:00:00" \
          -result_numerator $result_numerator \
          -competency_set_id 1 \
          -result_denominator 1000 \
          -return object]
        aa_true "Persisting a new indicator succeeded" {
            [$indicator activity_version_id] eq $activity_version_id
            && [$indicator user_id] eq [ad_conn user_id]
            && [$indicator result_numerator] eq $result_numerator
            && [$indicator result_denominator] eq 1000
            && [$indicator begin_timestamp] eq "2014-01-01 00:00:00+01"
            && [$indicator end_timestamp] eq "2014-01-03 00:00:00+01"
        }
    }

aa_register_component \
    indicator_create_bad \
    "Create an Indicator" {
        aa_export_vars {iri indicator}
        set activity [::xolp::Activity current -iri $iri]
        ns_log Notice "The following error is intended by the test suite!"
        catch {::xolp::Indicator insert \
          -user_id "0" \
          -activity_version_id [$activity activity_version_id] \
          -begin_timestamp "2014-01-04 00:00:00" \
          -end_timestamp "2014-01-03 00:00:00" \
          -result_numerator [format "%.0f" [expr {[random] * 1000}]] \
          -competency_set_id 1 \
          -result_denominator 1000 \
          -return object} catch_result
        aa_log $catch_result
        aa_true "Requiring a indicator with a bad timespan errored as expected" {
            [string match "*violates check constraint*" $catch_result]
        }
    }

aa_register_component \
    indicator_update \
    "Update an Indicator" {
        aa_export_vars {iri indicator}
        set indicator_id [$indicator indicator_id]
        $indicator destroy

        set indicator [::xolp::Indicator get_instance_from_db \
            -indicator_id $indicator_id]
        $indicator user_id 0; # Anonymous
        $indicator begin_timestamp 2013-01-01
        $indicator end_timestamp 2013-01-04
        $indicator result_numerator 1
        $indicator result_denominator 4

        $indicator save

        ::xo::dc 1row x "SELECT * FROM xolp_indicator_facts
            WHERE indicator_id = :indicator_id"
        aa_true "Persisting a new indicator succeeded" {
            $begin_timestamp eq "2013-01-01 00:00:00+01"
            && $end_timestamp eq "2013-01-04 00:00:00+01"
            && $result_numerator == 1
            && $result_denominator == 4
        }
    }

aa_register_component \
    indicator_delete \
    "Delete an Indicator" {
        aa_export_vars {indicator}
        aa_true "indicator exists" {
            [::xolp::Indicator exists_in_db -indicator_id [$indicator indicator_id]]
        }
        ::xolp::Indicator delete -indicator_id [$indicator indicator_id]
        aa_false "indicator does not exist" {
            [::xolp::Indicator exists_in_db -indicator_id [$indicator indicator_id]]
        }
    }

######################
#                    #
#   Initialization   #
#                    #
######################

aa_register_init_class \
    test_data_populate {
        Import some well-defined test data
    } {
        aa_export_vars {data test_user_ids user_ids activity_iris context_iris}
        set test_user_ids [::xolp::test::create_test_users]
        lappend user_ids [ad_conn user_id] {*}$test_user_ids
        lappend activity_iris {*}[::xolp::test::create_test_iris -nr 3]
        lappend context_iris {*}[::xolp::test::create_test_iris -nr 3]
        lassign $user_ids u1 u2
        lassign $context_iris c1 c2 c3
        lassign $activity_iris a1 a2 a3

        set data [list \
            $u1 $c1 $a1 "xolp:test:v:practiced" "2016-10-01 09:00:00" "2016-10-01 10:00:00"   30    90 \
            $u1 $c1 $a1 "xolp:test:v:practiced" "2016-10-01 09:00:00" "2016-10-01 11:00:00"   60    90 \
            $u1 $c1 $a1 "xolp:test:v:competed"  "2016-10-02 08:15:00" "2016-10-02 09:00:00"    1     1 \
            $u1 $c1 $a1 "xolp:test:v:competed"  "2016-10-02 09:30:00" "2016-10-02 10:00:00" 9000 18000 \
            $u1 $c1 $a2 "xolp:test:v:practiced" "2016-11-01 09:00:00" "2016-11-01 10:00:00"   23   100 \
            $u1 $c1 $a2 "xolp:test:v:practiced" "2016-11-02 11:15:00" "2016-11-02 12:00:00"   22   100 \
            $u1 $c1 $a3 "xolp:test:v:competed"  "2016-10-03 09:45:00" "2016-10-03 10:00:00"    0   100 \
            $u2 $c2 $a3 "xolp:test:v:competed"  "2016-10-04 13:00:00" "2016-10-04 14:00:00"   87   100 \
        ]

        foreach {user_id context_iri activity_iri verb_iri begin_timestamp end_timestamp rn rd} $data {
            ::xolp::Activity require -update false -iri $context_iri
            set activity [::xolp::Activity require -update false -iri $activity_iri]
            $activity add_to_context -context_iri $context_iri
            set activity_version_id [$activity activity_version_id]
            set verb [::xolp::ActivityVerb require -update false -iri $verb_iri]
            set activity_verb_id [$verb activity_verb_id]
            ::xolp::Indicator insert \
              -user_id $user_id \
              -activity_verb_id $activity_verb_id \
              -activity_version_id $activity_version_id \
              -begin_timestamp $begin_timestamp \
              -end_timestamp $end_timestamp \
              -result_numerator $rn \
              -result_denominator $rd
        }
    } {
       foreach u $test_user_ids {acs_user::delete -user_id $u -permanent}
       foreach a $activity_iris {::xolp::Activity delete -iri $a}
    }

aa_register_init_class \
    competency_test_data_populate {
        Import some well-defined competency test data
    } {
        aa_export_vars {exam1 exam2}
        set exam1 [::xolp::Activity require -iri "http://example.com/tcl-exam" -return id]
        set exam2 [::xolp::Activity require -iri "http://example.com/openacs-exam" -return id]

        ::xolp::Competency require -iri "http://example.com/competencies/abstract-thinking"
        ::xolp::Competency require -iri "http://example.com/competencies/software-development"
        ::xolp::Competency require -iri "http://example.com/competencies/computational-thinking"
        ::xolp::Competency require -iri "http://example.com/competencies/fullstack-webdev"
        ::xolp::Competency require -iri "http://example.com/competencies/database-design"
        ::xolp::Competency require -iri "http://example.com/competencies/programming/tcl"

        ::xolp::Competency add_to_competency \
                -competency_iri "http://example.com/competencies/computational-thinking" \
                -context_competency_iri "http://example.com/competencies/abstract-thinking" \
                -weight_numerator 6 \
                -weight_denominator 10 \
                -check false

        # Fullstack Webdevelopment books up to SW-Dev and Computational Thinking
        ::xolp::Competency add_to_competency \
                -competency_iri "http://example.com/competencies/fullstack-webdev" \
                -context_competency_iri "http://example.com/competencies/software-development" \
                -weight_numerator 50 \
                -weight_denominator 100 \
                -check false
        ::xolp::Competency add_to_competency \
                -competency_iri "http://example.com/competencies/fullstack-webdev" \
                -context_competency_iri "http://example.com/competencies/computational-thinking" \
                -weight_numerator 75 \
                -weight_denominator 100 \
                -check false

        # Fullstack Webdevelopment is itself a compound competency
        ::xolp::Competency add_to_competency \
                -competency_iri "http://example.com/competencies/programming/tcl" \
                -context_competency_iri "http://example.com/competencies/fullstack-webdev" \
                -weight_numerator 10 \
                -weight_denominator 40 \
                -check false
        ::xolp::Competency add_to_competency \
                -competency_iri "http://example.com/competencies/database-design" \
                -context_competency_iri "http://example.com/competencies/fullstack-webdev" \
                -weight_numerator 1 \
                -weight_denominator 4 \
                -check false

        # This simple Tcl exam can proof only that you know Tcl a bit (33.3%, lets say)
        ::xolp::Activity add_to_competency \
                -activity_iri "http://example.com/tcl-exam" \
                -competency_iri "http://example.com/competencies/programming/tcl" \
                -charge_numerator 3 \
                -charge_denominator 9

        # If you can handle OpenACS, however, you end up nearly as Tcl ninja (90%, lets say)
        ::xolp::Activity add_to_competency \
                -activity_iri "http://example.com/openacs-exam" \
                -competency_iri "http://example.com/competencies/programming/tcl" \
                -charge_numerator 90

        # Moreover, you probably know a bit of database design as well (50%)
        ::xolp::Activity add_to_competency \
                -activity_iri "http://example.com/openacs-exam" \
                -competency_iri "http://example.com/competencies/database-design" \
                -charge_numerator 50

        ::xolp::Activity synchronize_competencies -activity_iri "http://example.com/tcl-exam"
        ::xolp::Activity synchronize_competencies -activity_iri "http://example.com/openacs-exam"

        set evaluation_schema_id [::xolp::EvaluationSchema require \
            -iri "http://example.com/evaluation-schemas/programming" \
            -return id \
            -title "Development Skills" \
            -level_names {"luser" "junior" "senior" "ninja"} \
            -positive_threshold_index 1]

        set evaluation_scale [::xolp::EvaluationScale require \
            -iri "http://example.com/evaluation-scales/programming" \
            -evalschema_id $evaluation_schema_id \
            -title "luser - 25 - junior - 50 - senior - 75 - ninja" \
            -thresholds { 25 50 75 }]

        $evaluation_scale add_to_competency \
            -competency_iri "http://example.com/competencies/programming/tcl"
        $evaluation_scale add_to_competency \
            -competency_iri "http://example.com/competencies/fullstack-webdev"
        $evaluation_scale add_to_competency \
            -competency_iri "http://example.com/competencies/database-design"
        $evaluation_scale add_to_competency \
            -competency_iri "http://example.com/competencies/software-development"
        $evaluation_scale add_to_competency \
            -competency_iri "http://example.com/competencies/computational-thinking"
        $evaluation_scale add_to_competency \
            -competency_iri "http://example.com/competencies/abstract-thinking"
    } {
      # Delete stuff
    }

##################
#                #
#   Test Cases   #
#                #
##################

aa_register_case \
    -procs {::xolp::ActivityVerb} \
    -cats {smoke} \
    activity_verb_create {
      Create an Activity Verb.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_verb_create
          }
    }

aa_register_case \
    -procs {::xolp::ActivityVerb} \
    -cats {smoke} \
    activity_verb_require {
      Require an Activity Verb.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_verb_require
          }
    }

aa_register_case \
    -procs {::xolp::EvaluationSchema} \
    -cats {smoke} \
    activity_verb_delete {
      Delete an Activity Verb.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_verb_create
              aa_call_component activity_verb_delete
          }
    }

aa_register_case \
    -procs {::xolp::EvaluationSchema} \
    -cats {smoke} \
    evaluation_schema_create {
      Create an Evaluation Schema.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component evaluation_schema_create
          }
    }

aa_register_case \
    -procs {::xolp::EvaluationSchema} \
    -cats {smoke} \
    evaluation_schema_require {
      Require an Evaluation Schema.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component evaluation_schema_require
          }
    }

aa_register_case \
    -procs {::xolp::EvaluationSchema} \
    -cats {smoke} \
    evaluation_schema_delete {
      Delete an Evaluation Schema.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component evaluation_schema_create
              aa_call_component evaluation_schema_delete
          }
    }

aa_register_case \
    -procs {::xolp::EvaluationScale} \
    -cats {smoke} \
    evaluation_scale_create {
      Create an Evaluation Scale.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component evaluation_schema_create
              aa_call_component evaluation_scale_create
          }
    }

aa_register_case \
    -procs {::xolp::EvaluationScale} \
    -cats {smoke} \
    evaluation_scale_require {
      Require an Evaluation Scale.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component evaluation_scale_require
          }
    }

aa_register_case \
    -procs {::xolp::EvaluationScale} \
    -cats {smoke} \
    evaluation_scale_delete {
      Delete an Evaluation Scale.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component evaluation_schema_create
              aa_call_component evaluation_scale_create
              aa_call_component evaluation_scale_delete
          }
    }

aa_register_case \
    -procs {::xolp::EvaluationScale} \
    -cats {api} \
    evaluation_scale_levels {
      Correctness of Levels of an Evaluation Scale.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component evaluation_schema_create
              aa_call_component evaluation_scale_create

              set levels [$evaluation_scale levels]
              set lowest_level [lindex $levels 0]
              set highest_level [lindex $levels end]
              set medium_level [$evaluation_scale get_level -result 75]
              aa_equals "5 levels?"               [llength $levels] 5
              aa_equals "Lowest level min 0?"     [$lowest_level min] 0
              aa_equals "Lowest level max 60?"    [$lowest_level max] 60
              aa_equals "Lowest level height 0?"  [$lowest_level height] 0
              aa_equals "Medium level min 70?"    [$medium_level min] 70
              aa_equals "Medium level max 80?"    [$medium_level max] 80
              aa_equals "Medium level height 2?"  [$medium_level height] 2
              aa_equals "Highest level min 90?"   [$highest_level min] 90
              aa_equals "Highest level max 100?"  [$highest_level max] 100
              aa_equals "Highest level height 4?" [$highest_level height] 4

              aa_true "Is 0 negative?" {[$lowest_level encompasses -result 0]}
              aa_true "Is 59.9 negative?" {[$lowest_level encompasses -result 59.9]}
              aa_true "Is 70 satisfactory?" {[$medium_level encompasses -result 70]}
              aa_true "Is 75 satisfactory?" {[$medium_level encompasses -result 75]}
              aa_false "Is 80 better than satisfactory?" {[$medium_level encompasses -result 80]}
              aa_true "Is 90 excellent?" {[$highest_level encompasses -result 90]}
              aa_true "Is 100 excellent?" {[$highest_level encompasses -result 100]}
              aa_false "Is 101 invalid?" {[$highest_level encompasses -result 100.1]}
          }
    }

aa_register_case \
    -procs {::xolp::Activity} \
    -cats {smoke} \
    activity_create {
      Register an activity for the first time in the activity dimension.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_create
          }
    }

aa_register_case \
    -procs {::xolp::Activity} \
    -cats {smoke} \
    activity_update {
      Update activity in the activity dimension.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_create
              aa_call_component activity_update
          }
    }

aa_register_case \
    -procs {::xolp::Activity} \
    -cats {smoke} \
    activity_require {
      Require activity in the activity dimension.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_require
          }
    }

aa_register_case \
    -procs {::xolp::Activity} \
    -cats {smoke} \
    activity_delete {
      Delete activity in the activity dimension.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_create
              aa_call_component activity_delete
          }
    }

aa_register_case \
    -procs {::xolp::Indicator ::xolp::Activity} \
    -cats {smoke} \
    indicator_create {
      Create one simple indicator.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_create
              aa_call_component indicator_create_simple
              aa_call_component indicator_create_full
              aa_call_component indicator_create_bad
          }
    }

aa_register_case \
    -procs {::xolp::Indicator} \
    -cats {smoke} \
    indicator_update {
      Update one simple indicator.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_create
              aa_call_component indicator_create_full
              aa_call_component indicator_update
          }
    }

aa_register_case \
    -procs {::xolp::Indicator} \
    -cats {smoke} \
    indicator_delete {
      Delete one simple indicator.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              aa_call_component activity_create
              aa_call_component indicator_create_simple
              aa_call_component indicator_delete
              aa_call_component activity_delete
          }
    }

aa_register_case \
    -init_classes {test_data_populate} \
    -cats {api} \
    indicator_verb_queries {
      Query indicators based on verbs.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids [ad_conn user_id] \
                -activity_iris $activity_iris \
                -activity_verb_iris {"xolp:test:v:competed"}]
              aa_log $li
              aa_equals "Number of indicators:" [llength [dict keys $li]] 3
              aa_equals "Sum of indicators:" [::tcl::mathop::+ {*}[dict values $li]] 150.0

              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids [ad_conn user_id] \
                -activity_iris $activity_iris \
                -activity_verb_iris {"xolp:test:v:practiced"}]
              aa_log $li
              aa_equals "Number of indicators:" [llength [dict keys $li]] 4
              aa_equals "Sum of indicators:" [::tcl::mathop::+ {*}[dict values $li]] 145.0
          }
    }

aa_register_case \
    -cats {api} \
    indicator_datetime_queries {
      Query indicators based on time.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {

              # Assumption: Aggregations of the activity hierarchy do
              #             not fit well to time-queries, because
              #             questions like "What mark would you have
              #             if you had been only attending the course
              #             on Mondays" doesn't make too much
              #             sense. However, the average result on
              #             weekends in comparison to weekdays might
              #             be interesting.

              set activity_iri "http://example.com/practice1"
              set activity_version_id [::xolp::Activity require -iri $activity_iri -return id]

              # Weekend practicing
              ::xolp::Indicator insert \
                      -activity_version_id $activity_version_id \
                      -end_timestamp "2016-12-31 23:00:00" \
                      -result_numerator 40
              ::xolp::Indicator insert \
                      -activity_version_id $activity_version_id \
                      -end_timestamp "2017-01-01 01:00:00" \
                      -result_numerator 48

              # Weekday practicing
              ::xolp::Indicator insert \
                      -activity_version_id $activity_version_id \
                      -end_timestamp "2017-01-02 11:30:00" \
                      -result_numerator 60
              ::xolp::Indicator insert \
                      -activity_version_id $activity_version_id \
                      -end_timestamp "2017-01-02 13:15:00" \
                      -result_numerator 68

              # Weekend 2016
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids [ad_conn user_id] \
                -activity_iris $activity_iri \
                -begin_date_constraint "begin_year = '2016'" \
                -end_date_constraint "end_is_weekend = TRUE" ]
              aa_log $li
              aa_equals "Number of indicators:" [llength [dict keys $li]] 1
              aa_equals "Sum of indicators:" [::tcl::mathop::+ {*}[dict values $li]] 40.0

              # Weekend
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids [ad_conn user_id] \
                -activity_iris $activity_iri \
                -end_date_constraint "end_is_weekend = TRUE" ]
              aa_log $li
              aa_equals "Number of indicators:" [llength [dict keys $li]] 2
              aa_equals "Sum of indicators:" [::tcl::mathop::+ {*}[dict values $li]] 88.0

              # AM
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids [ad_conn user_id] \
                -activity_iris $activity_iri \
                -end_time_constraint "end_day_time_name = 'am'" ]
              aa_log $li
              aa_equals "Number of indicators:" [llength [dict keys $li]] 1
              aa_equals "Sum of indicators:" [::tcl::mathop::+ {*}[dict values $li]] 60.0

              # Total
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids [ad_conn user_id] \
                -activity_iris $activity_iri]
              aa_log $li
              aa_equals "Number of indicators:" [llength [dict keys $li]] 4
              aa_equals "Sum of indicators:" [::tcl::mathop::+ {*}[dict values $li]] 216.0
          }
    }

aa_register_case \
    -cats {api} \
    scenario_composite_activity {
      Register several indicators for several activities that form a composite.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              lassign [list [ad_conn user_id] {*}[::xolp::test::create_test_users -nr 5]] u1 u2 u3 u4 u5 u6

              # Setup the course, add schema and scale.
              set c1 [::xolp::Activity require -iri "http://example.com/course1" -return id]
              set evalschema_id [::xolp::EvaluationSchema require -iri "https://dotlrn.org/xolp/evaluation-schemas/at-five-to-one" -update false -return id]
              set evalscale [::xolp::EvaluationScale require -iri "http://example.com/evalscales/course1" -evalschema_id $evalschema_id -thresholds "60 70 80 90"]
              $evalscale add_to_activity -activity_version_id $c1

              set c1t1 [::xolp::Activity require -iri "http://example.com/course1/test1" -return id]
              set c1t2 [::xolp::Activity require -iri "http://example.com/course1/test2" -return id]

              # The final test performance counts 50% overall.
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/test1" \
                      -context_iri "http://example.com/course1" \
                      -check false \
                      -weight_numerator 25 \
                      -weight_denominator 100
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/test2" \
                      -context_iri "http://example.com/course1" \
                      -check false \
                      -weight_numerator 50 \
                      -weight_denominator 100


              # We create a virtual "groups" context to collect all (alternative) groups.
              # This allows for easier weighting (otherwise course1's subactivities would add up to more than 100%
              set c1g     [::xolp::Activity require -iri "http://example.com/course1/groups" -return id]
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/groups" \
                      -context_iri "http://example.com/course1" \
                      -weight_numerator 25 \
                      -weight_denominator 100

              # We create the alternative groups and their tasks.
              set c1g1    [::xolp::Activity require -iri "http://example.com/course1/group1" -return id]
              set c1g1p1  [::xolp::Activity require -iri "http://example.com/course1/group1/presentation1" -return id]
              set c1g1p2  [::xolp::Activity require -iri "http://example.com/course1/group1/presentation2" -return id]
              set c1g2    [::xolp::Activity require -iri "http://example.com/course1/group2" -return id]
              set c1g2d   [::xolp::Activity require -iri "http://example.com/course1/group2/deliverable" -return id]
              set c1g2p   [::xolp::Activity require -iri "http://example.com/course1/group2/presentation" -return id]

              # The first presentation of each group counts not as much as the second one.
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/group1/presentation1" \
                      -context_iri "http://example.com/course1/group1" \
                      -check false \
                      -weight_numerator 4 \
                      -weight_denominator 10
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/group1/presentation2" \
                      -context_iri "http://example.com/course1/group1" \
                      -weight_numerator 6 \
                      -weight_denominator 10
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/group2/presentation" \
                      -context_iri "http://example.com/course1/group2" \
                      -check false \
                      -weight_numerator 4 \
                      -weight_denominator 10
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/group2/deliverable" \
                      -context_iri "http://example.com/course1/group2" \
                      -weight_numerator 6 \
                      -weight_denominator 10

              # The groups performance, as well as the first test, count only 25% of the overall course mark.
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/group1" \
                      -context_iri "http://example.com/course1/groups" \
                      -check false \
                      -weight_numerator 100 \
                      -weight_denominator 100
              ::xolp::Activity add_to_context \
                      -activity_iri "http://example.com/course1/group2" \
                      -context_iri "http://example.com/course1/groups" \
                      -check false \
                      -weight_numerator 100 \
                      -weight_denominator 100

              # User 1
              ::xolp::Indicator insert \
                      -user_id $u1 \
                      -activity_version_id $c1g1p1 \
                      -result_numerator 25
              ::xolp::Indicator insert \
                      -user_id $u1 \
                      -activity_version_id $c1g1p2 \
                      -result_numerator 75
              ::xolp::Indicator insert \
                      -user_id $u1 \
                      -activity_version_id $c1t1 \
                      -result_numerator 60
              ::xolp::Indicator insert \
                      -user_id $u1 \
                      -activity_version_id $c1t2 \
                      -result_numerator 90

              # User 2
              ::xolp::Indicator insert \
                      -user_id $u2 \
                      -activity_version_id $c1g1p1 \
                      -result_numerator 23
              ::xolp::Indicator insert \
                      -user_id $u2 \
                      -activity_version_id $c1g1p2 \
                      -result_numerator 43
              ::xolp::Indicator insert \
                      -user_id $u2 \
                      -activity_version_id $c1t1 \
                      -result_numerator 48
              ::xolp::Indicator insert \
                      -user_id $u2 \
                      -activity_version_id $c1t2 \
                      -result_numerator 65

              # User 3 - Did nothing

              # User 4 - Failed on first test, thus failed completely
              ::xolp::Indicator insert \
                      -user_id $u4 \
                      -activity_version_id $c1t1 \
                      -result_numerator 3
              ::xolp::Indicator insert \
                      -user_id $u4 \
                      -activity_version_id $c1g2d \
                      -result_numerator 100
              ::xolp::Indicator insert \
                      -user_id $u4 \
                      -activity_version_id $c1g2p \
                      -result_numerator 90
              ::xolp::Indicator insert \
                      -user_id $u4 \
                      -activity_version_id $c1t2 \
                      -result_numerator 99

              # User 1 on Presentation 1
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u1 \
                -activity_iris "http://example.com/course1/group1/presentation1"]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 1
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 25

              aa_equals "User 1 in test 1:" [::xolp::User get_result -user_id $u1 -iri "http://example.com/course1/test1"] 60.00
              aa_equals "User 1 in test 2:" [::xolp::User get_result -user_id $u1 -iri "http://example.com/course1/test2"] 90.00
              aa_equals "User 1 in group 1 presentation 1:" [::xolp::User get_result -user_id $u1 -iri "http://example.com/course1/group1/presentation1"] 25.00
              aa_equals "User 1 in group 1 presentation 2:" [::xolp::User get_result -user_id $u1 -iri "http://example.com/course1/group1/presentation2"] 75.00
              aa_equals "User 1 in group 1:" [::xolp::User get_result -user_id $u1 -iri "http://example.com/course1/group1"] 55.00
              aa_equals "User 1 in virtual group:" [::xolp::User get_result -user_id $u1 -iri "http://example.com/course1/groups"] 55.00
              aa_equals "User 1 in course 1:" [::xolp::User get_result -user_id $u1 -iri "http://example.com/course1"] 73.75

              aa_equals "User 2 in group 1 test 1:" [::xolp::User get_result -user_id $u2 -iri "http://example.com/course1/test1"] 48.00
              aa_equals "User 2 in group 1 test 2:" [::xolp::User get_result -user_id $u2 -iri "http://example.com/course1/test2"] 65.00
              aa_equals "User 2 in group 1 presentation 1:" [::xolp::User get_result -user_id $u2 -iri "http://example.com/course1/group1/presentation1"] 23.00
              aa_equals "User 2 in group 1 presentation 2:" [::xolp::User get_result -user_id $u2 -iri "http://example.com/course1/group1/presentation2"] 43.00
              aa_equals "User 2 in group 1:" [::xolp::User get_result -user_id $u2 -iri "http://example.com/course1/group1"] 35.00
              aa_equals "User 2 in virtual group:" [::xolp::User get_result -user_id $u2 -iri "http://example.com/course1/groups"] 35.00
              aa_equals "User 2 in course 1:" [::xolp::User get_result -user_id $u2 -iri "http://example.com/course1"] 53.25

              # User 1 on Group 1
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u1 \
                -activity_iris "http://example.com/course1/group1"]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 2
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 100

              # User 2 on Group 1
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u2 \
                -activity_iris "http://example.com/course1/group1"]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 2
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 66

              # User 3 on Group 1 (absent)
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u3 \
                -activity_iris "http://example.com/course1/group1"]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 0
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 0

              # User 1 on whole course
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u1 \
                -activity_iris "http://example.com/course1"]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 4
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 250

              # User 2 on whole course
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u2 \
                -activity_iris "http://example.com/course1"]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 4
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 179

              # User 3 on whole course
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u3 \
                -activity_iris "http://example.com/course1"]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 0
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 0

              # User 4 on whole course
              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u4 \
                -activity_iris "http://example.com/course1"]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 4
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 292

          }
    }

aa_register_case \
    -procs {::xolp::Activity} \
    -cats {populator stress} \
    populate_activities {
      Generate 10,000 activities.
    } {
        aa_run_with_teardown \
            -test_code {
                aa_export_vars {activity_iris activity_version_ids}
                set amount 10000
                for {set i 1} {$i <= $amount} {incr i} {
                    set activity_iri [::xolp::test::create_test_iris]"
                    set activity [::xolp::Activity new_persistent_object \
                      -iri $activity_iri \
                      -title "Activity $i"]
                    lappend activity_version_ids [$activity activity_version_id]
                    lappend activity_iris $activity_iri
                }
            }
    }

aa_register_case \
    -procs {::xolp::Indicator} \
    -cats {populator stress} \
    populate_indicators {
      Generate 250,000 random indicators for 5,000 users
      and 5000 activities.
    } {
        aa_run_with_teardown \
            -test_code {
                aa_export_vars {user_ids activity_iris}
                set activity_version_ids [db_list -cache_key "xolp_test_activity_version_ids" _ "select activity_version_id from xolp_activity_dimension limit 5000"]
                set activity_verb_ids [db_list _ "select activity_verb_id from xolp_activity_verb_dimension"]
                set user_ids [db_list -cache_key "xolp_test_user_ids" _ "select user_id from users limit 5000"]
                lappend user_ids [ad_conn user_id]
                # Indicators
                for {set i 0} {$i < 250000} {incr i} {
                    set user_id [::xolp::test::random_element $user_ids]
                    set activity_verb_id [::xolp::test::random_element $activity_verb_ids]
                    set activity_version_id [::xolp::test::random_element $activity_version_ids]
                    set end_timestamp [::xolp::test::random_timestamp]
                    set begin_timestamp [::xolp::test::random_earlier_timestamp $end_timestamp]
                    ::xolp::Indicator insert \
                      -user_id $user_id \
                      -activity_verb_id $activity_verb_id \
                      -activity_version_id $activity_version_id \
                      -begin_timestamp $begin_timestamp \
                      -end_timestamp $end_timestamp \
                      -result_numerator [expr {int(rand()*100)}] \
                      -result_denominator 100
                }
            }
    }

aa_register_case \
    -init_classes {test_data_populate} \
    -cats {api} \
    user_get_composite_activity_result {
      Get result a user gained in a context (for example a community/course).
    } {
      aa_run_with_teardown \
          -test_code {
              set result [::xolp::User get_result \
                  -user_id [lindex $user_ids 0] \
                  -iri [lindex $context_iris 0] \
                  -policy best]
              aa_true "Best result: expected 41.00% got $result" {[format "%.2f" $result] == 41.00}

              set result [::xolp::User get_result \
                  -user_id [lindex $user_ids 0] \
                  -iri [lindex $context_iris 0] \
                  -policy worst]
              aa_true "Worst result: expected 18.44% got $result" {[format "%.2f" $result] == 18.44}

              set result [::xolp::User get_result \
                  -user_id [lindex $user_ids 0] \
                  -iri [lindex $context_iris 0] \
                  -policy average]
              aa_true "Average result: expected 28.33% got $result" {[format "%.2f" $result] == 28.33}

              set result [::xolp::User get_result \
                  -user_id [lindex $user_ids 1] \
                  -iri [lindex $context_iris 1]]
              aa_true "Best result: expected 87% got $result" {$result == 87}
          }
    }

aa_register_case \
    -init_classes {test_data_populate} \
    -cats {api} \
    user_get_result {
      Get result of a user.
    } {
      aa_run_with_teardown \
          -test_code {
              set result [::xolp::User get_result \
                  -user_id [lindex $user_ids 1] \
                  -iri [lindex $activity_iris 0] \
                  -policy best]
              aa_log "Result: $result"
              aa_true "User didnt do this activity" {$result eq ""}

              set result [::xolp::User get_result \
                  -user_id [lindex $user_ids 0] \
                  -iri [lindex $activity_iris 0] \
                  -policy best]
              aa_log "Result: $result"
              aa_true "Best result is 100%" {$result == 100}

              set result [::xolp::User get_result \
                  -user_id [lindex $user_ids 0] \
                  -iri [lindex $activity_iris 0] \
                  -policy average]
              aa_log "Result: $result"
              aa_true "Average result is 62.5%" {$result == 62.5}

              set result [::xolp::User get_result \
                  -user_id [lindex $user_ids 0] \
                  -iri [lindex $activity_iris 0] \
                  -policy worst]

              aa_log "Result: $result"
              aa_true "Worst result is ~33%" {[format "%.2f" $result] == 33.33}
          }
    }

aa_register_case \
    -init_classes {test_data_populate} \
    -cats {api} \
    indicator_get_duration {
      Get indicators duration...
    } {
      aa_run_with_teardown \
          -test_code {
              lassign $user_ids u1 u2
              lassign $activity_iris a1 a2 a3
              lassign $context_iris c1 c2 c3

              set li [::xolp::Indicator get_values_from_db \
                -properties "duration" \
                -aggregate "sum" \
                -user_ids $u1 \
                -activity_iris $c1]
              aa_log $li
              aa_equals "Number of indicators:" [llength {*}[dict keys $li]] 7
              aa_equals "Sum of indicators:" [dict values $li] "06:15:00"

              set li [::xolp::Indicator get_values_from_db \
                -properties "duration" \
                -aggregate "sum" \
                -user_ids $u1 \
                -activity_iris $a2]
              aa_log $li
              aa_equals "Number of indicators:" [llength [dict keys $li]] 1
              aa_equals "Sum of indicators:" [dict values $li] "01:45:00"

              set li [::xolp::Indicator get_values_from_db \
                -properties "duration" \
                -aggregate "sum" \
                -user_ids $u2 \
                -activity_iris $c2]
              aa_log $li
              aa_equals "Number of indicators:" [llength {*}[dict keys $li]] 1
              aa_equals "Sum of indicators:" [dict values $li] "01:00:00"
          }
    }

aa_register_case \
    -init_classes {test_data_populate} \
    -cats {api} \
    indicator_get_values {
      Get indicators values...
    } {
      aa_run_with_teardown \
          -test_code {
              lassign $user_ids u1 u2
              lassign $activity_iris a1 a2 a3
              lassign $context_iris c1 c2 c3

              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u1 \
                -activity_iris $c1]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 7
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 295

              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u1 \
                -activity_iris $a2]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 2
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 45

              set li [::xolp::Indicator get_values_from_db \
                -properties "result_percentage" \
                -user_ids $u2 \
                -activity_iris $c2]
              aa_equals "Number of indicators:" [llength [dict keys $li]] 1
              aa_equals "Sum of indicators:" [format "%.0f" [::tcl::mathop::+ {*}[dict values $li]]] 87
          }
    }

aa_register_case \
    -init_classes {competency_test_data_populate} \
    -cats {api} \
    user_get_competencies {
        Get results/evaluations of users for competencies.
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {
              set c [::xolp::User get_competencies -user_id [ad_conn user_id]]
              aa_equals "2 directly attached competencies." [llength [dict keys $c]] 2
              set c [::xolp::User get_competencies_recursive -user_id [ad_conn user_id]]
              aa_equals "6 competencies." [llength [dict keys $c]] 6
            }
    }

aa_register_case \
    -init_classes {competency_test_data_populate} \
    -cats {api} \
    user_get_competency_evaluation {
      Get results/evaluations of users for competencies.
    } {
      aa_run_with_teardown \
          -rollback \
          -test_code {
              ::xolp::Indicator insert \
                      -user_id [ad_conn user_id] \
                      -activity_version_id $exam1 \
                      -result_numerator 90

              ::xolp::Indicator insert \
                      -user_id [ad_conn user_id] \
                      -activity_version_id $exam2 \
                      -result_numerator 80

              #
              # Tcl
              #
              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -policy "best" \
                      -competency_iri "http://example.com/competencies/programming/tcl"]
              aa_equals "User has 72% of competency 'Tcl Programming' (best)" $result 72.00
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -policy "best" \
                      -competency_iri "http://example.com/competencies/programming/tcl"]
              aa_equals "User is a senior Tcl dev. (best)" [$level name] "senior"

              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -policy "average" \
                      -competency_iri "http://example.com/competencies/programming/tcl"]
              aa_equals "User has 72% of competency 'Tcl Programming' (average)" $result 51.00
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -policy "average" \
                      -competency_iri "http://example.com/competencies/programming/tcl"]
              aa_equals "User is a senior Tcl dev. (average)" [$level name] "senior"

              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -policy "worst" \
                      -competency_iri "http://example.com/competencies/programming/tcl"]
              aa_equals "User has 72% of competency 'Tcl Programming' (worst)" $result 30.00
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -policy "worst" \
                      -competency_iri "http://example.com/competencies/programming/tcl"]
              aa_equals "User is a senior Tcl dev. (worst)" [$level name] "junior"

              #
              # Database Design
              #
              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/database-design"]
              aa_equals "User has 40% of competency 'Database Design'" $result 40.00
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/database-design"]
              aa_equals "User is a junior DB dev." [$level name] "junior"

              #
              # Full Stack Web Development
              #
              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/fullstack-webdev"]
              aa_equals "User has 28% full stack power." $result 28.00
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/fullstack-webdev"]
              aa_equals "User is a junior dev." [$level name] "junior"

              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -policy "average" \
                      -competency_iri "http://example.com/competencies/fullstack-webdev"]
              aa_equals "User has 22.75% full stack power." $result 22.75
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -policy "average" \
                      -competency_iri "http://example.com/competencies/fullstack-webdev"]
              aa_equals "User is a luser dev." [$level name] "luser"

              #
              # Software Development
              #
              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/software-development"]
              aa_equals "User has 14% software dev competency." $result 14.00
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/software-development"]
              aa_equals "User is a luser dev." [$level name] "luser"

              #
              # Computational Thinking
              #
              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/computational-thinking"]
              aa_equals "User has 21% computational thinking skills." $result 21.00
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/computational-thinking"]
              aa_equals "User is a luser comp-thinker." [$level name] "luser"

              #
              # Abstract Thinking
              #
              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/abstract-thinking"]
              aa_equals "User can 12.6 abstract thinking skills" $result 12.60
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -competency_iri "http://example.com/competencies/abstract-thinking"]
              aa_equals "User is not a thinker." [$level name] "luser"

              set result [::xolp::User get_competency_result \
                      -user_id [ad_conn user_id] \
                      -policy "average" \
                      -competency_iri "http://example.com/competencies/abstract-thinking"]
              aa_equals "User can 10.2375 abstract thinking skills" $result 10.24
              set level [::xolp::User get_competency_evaluation \
                      -user_id [ad_conn user_id] \
                      -policy "average" \
                      -competency_iri "http://example.com/competencies/abstract-thinking"]
              aa_equals "User is not a thinker." [$level name] "luser"
          }
    }

