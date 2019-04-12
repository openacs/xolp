::xo::library doc {
  Data model and implementation for evaluation scale and evaluation schema.

  @author Michael Aram
  @creation-date 2017
}

package require math::fuzzy

::xo::library require xolp-iri-procs

namespace eval ::xolp {

  #
  # Evaluation Schema
  #

  ::xolp::iri::MetaClass create ::xolp::EvaluationSchema \
      -table_name xolp_evalschemas \
      -id_column evalschema_id \
      -slots {
        ::xo::db::Attribute create title
        ::xo::db::Attribute create description
        ::xo::db::Attribute create level_names
        ::xo::db::Attribute create positive_threshold_index \
            -default 0 \
            -datatype integer
      } -ad_doc {
        An evaluation schema is used for translating
        raw (percentage) scores into meaningful levels,
        e.g. grades.
      }

  ::xolp::EvaluationSchema ad_proc new_persistent_object {args} {
    Create new persistent object
  } {
    array set argsarray $args
    if {[llength [array get argsarray "-level_names"]] > 0
        && [llength [array get argsarray "-positive_threshold_index"]] > 0
        && (([llength $argsarray(-level_names)] - 1 ) <= $argsarray(-positive_threshold_index))} {
      error "The positive_threshold_index must refer to a threshold index, i.e. it must not be larger than the list of levels minus one..."
    }
    next
  }

  ::xolp::iri::MetaClass create ::xolp::EvaluationScale \
      -table_name xolp_evalscales \
      -id_column evalscale_id \
      -slots {
        ::xo::db::Attribute create title
        ::xo::db::Attribute create evalschema_id \
            -datatype integer \
            -references "xolp_evalschemas"
        ::xo::db::Attribute create thresholds
      } -ad_doc {
        An evaluation scale carries the actual thresholds
        for dividing the range from 0 to 100 into levels.
      }

  ::xo::db::require table xolp_evalscale_activity_bridge {
    evalscale_id {INTEGER NOT NULL REFERENCES xolp_evalscales ON DELETE CASCADE}
    activity_version_id {INTEGER NOT NULL}
  }

  #::xo::db::require index -table xolp_evalscale_activity_bridge -col "evalscale_id, activity_version_id" -unique true
  if {[::xo::db::require exists_table xolp_evalscale_activity_bridge]} {
    ::xo::dc dml create-index-with-long-default-name "
      CREATE UNIQUE INDEX IF NOT EXISTS xolp_eval_scale_act_brdg_un_idx
      ON xolp_evalscale_activity_bridge (evalscale_id, activity_version_id)
    "
  }

  ::xo::db::require table xolp_evalscale_competency_bridge {
    evalscale_id {INTEGER NOT NULL REFERENCES xolp_evalscales ON DELETE CASCADE}
    competency_iri {TEXT NOT NULL}
  }

  if {[::xo::db::require exists_table xolp_evalscale_competency_bridge]} {
    ::xo::dc dml create-index-with-long-default-name "
      CREATE UNIQUE INDEX IF NOT EXISTS xolp_eval_scale_cmpy_brdg_un_idx
      ON xolp_evalscale_competency_bridge (evalscale_id, competency_iri)
    "
  }

  ::xolp::EvaluationScale ad_instproc initialize_loaded_object {} {
    Initialize loaded object
  } {
    :levels
  }

  ::xolp::EvaluationScale ad_proc get_evalscales_from_competency_iri {
    -competency_iri:required
  } {
    @return A list of instances of ::xolp::EvaluationScale associated with the competency_iri.
  } {
    set evalscales {}
    set evalscale_ids [::xo::dc list_of_lists get_evalscales_from_competency_iri "
      SELECT evalscale_id FROM xolp_evalscale_competency_bridge WHERE competency_iri = :competency_iri
    "]
    foreach evalscale_id $evalscale_ids {
      lappend evalscales [::xo::db::Class get_instance_from_db -id $evalscale_id]
    }
    return $evalscales
  }

  ::xolp::EvaluationScale ad_proc get_evalscales_from_activity_version_id {
    -activity_version_id:required
  } {
    @return A list of instances of ::xolp::EvaluationScale associated with the activity_version_id.
  } {
    set evalscales {}
    set evalscale_ids [::xo::dc list_of_lists get_evalscales_from_activity_version_id "
      SELECT evalscale_id FROM xolp_evalscale_activity_bridge WHERE activity_version_id = :activity_version_id
    "]
    foreach evalscale_id $evalscale_ids {
      lappend evalscales [::xo::db::Class get_instance_from_db -id $evalscale_id]
    }
    return $evalscales
  }

  ::xolp::EvaluationScale ad_instproc add_to_activity {
    -activity_version_id:required
  } {
    Associate the EvaluationScale with the object, if it isn't already.
  } {
    :instvar evalscale_id
    ::xo::dc dml associate_evalscale_to_activity "
      INSERT INTO xolp_evalscale_activity_bridge(evalscale_id, activity_version_id)
      VALUES (:evalscale_id, :activity_version_id)
      ON CONFLICT DO NOTHING
    "
  }

  ::xolp::EvaluationScale ad_instproc add_to_competency {
    -competency_iri:required
  } {
    Associate the EvaluationScale with the competency, if it isn't already.
  } {
    :instvar evalscale_id
    ::xo::dc dml associate_evalscale_to_competency "
      INSERT INTO xolp_evalscale_competency_bridge(evalscale_id, competency_iri)
      VALUES (:evalscale_id, :competency_iri)
      ON CONFLICT DO NOTHING
    "
  }

  ::xolp::EvaluationScale ad_instproc get_level {
    -result:required
  } {
    Get the level that encompasses the result.
  } {
    if {$result < 0 || $result > 100} {
      ns_log Warning "Result must be within 0 and 100"
      return -1
    }
    foreach l [:levels] {
      if {[$l encompasses -result $result]} {return $l}
    }
    error "None of the levels encompassed the result... ($result)"
  }

  ::xolp::EvaluationScale ad_instproc levels {} {
    Get levels based on thresholds.
  } {
    if {[info exists :levels]} {return ${:levels}}
    set ticks [list 0 {*}${:thresholds} 100]
    for {set i 0} {$i < [llength $ticks]-1} {incr i} {
      lappend levels [::xolp::EvaluationScale::Level create [self]::$i \
                          -min [lindex $ticks $i] \
                          -max [lindex $ticks $i+1]]
    }
    return $levels
  }

  ::xotcl::Class create ::xolp::EvaluationScale::Level \
      -parameter {
        min:required
        max:required
      } -ad_doc {
        @param min Lower boundary (inklusive)
        @param max Upper boundary (exklusive for all but highest level)
      }

  ::xolp::EvaluationScale::Level ad_instproc name {
  } {
    @return The "name" of the evaluation level.
  } {
    set level_index [namespace tail [self]]
    set scale [namespace qualifiers [self]]
    set schema [$scale evalschema_id]
    if {![:isobject $schema]} {
      ::xo::db::Class get_instance_from_db -id $schema
    }
    set name [lindex [$schema level_names] $level_index]
    if {$name eq ""} {
      set name $level_index
    }
    return $name
  }

  ::xolp::EvaluationScale::Level ad_instproc height {
  } {
    @return The "height" of the evaluation level.
    Levels start at 0 and increment by 1,
    theoretically open ended,
    but practically only up to a handful...
  } {
    return [namespace tail [self]]
  }

  ::xolp::EvaluationScale::Level ad_instproc encompasses {
    -result:required
  } {
    Check whether or not this level encompasses the give result value.
    @return Boolean
  } {
    if {${:max} == 100 && [::math::fuzzy::teq ${:max} $result]} {
      return true
    }
    return [expr {[::math::fuzzy::tge $result ${:min}] && [::math::fuzzy::tlt $result ${:max}]}]
  }

  #
  # Evaluator
  #

  ::xotcl::Object create ::xolp::Evaluator -ad_doc {}

  ::xolp::Evaluator ad_proc evaluate {
    -results:required
    -evalscales:required
  } {
    Evaluates one or more results according to one or more evaluation scales.
  } {
    set result_dict {}
    foreach result $results {
      foreach evalscale $evalscales {
        dict set result_dict $result $evalscale [$evalscale get_level -result $result]
      }
    }
    return $result_dict
  }

}

::xo::library source_dependent

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
