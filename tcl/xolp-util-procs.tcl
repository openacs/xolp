::xo::library doc {
  Utility procs.

  @author Michael Aram
  @creation-date 2017
}

#################
#               #
#   Utilities   #
#               #
#################

namespace eval ::xolp::util {

    ad_proc -private lcontains {list1 list2} {
      foreach pattern $list2 {
        if {[lsearch $list1 $pattern] ne -1} {return 1}
      }
      return 0
    }

    ad_proc -private ltransform {{-prefix ":"} {-suffix ""} list} {
      set transformed_list {}
      foreach e $list {lappend transformed_list ${prefix}${e}${suffix}}
      return $transformed_list
    }

    ad_proc -private lremove {list elements_to_be_removed} {
        foreach e $elements_to_be_removed {
          set list [lsearch -all -inline -not -exact $list $e]
        }
        return $list
    }

    #if {$generate_iri_path} {set iri "${iri}:[ns_uuid]"}
}

######################
#                    #
#   Test Utilities   #
#                    #
######################

namespace eval ::xolp::test {

    ad_proc -private create_test_iris {{-nr 1}} {
      set iris {}
      for {set i 1} {$i <= $nr} {incr i} {
        lappend iris "xolp:test:[ns_uuid]"
      }
      return $iris
    }

    ad_proc -private create_test_users {{-nr 1}} {
      set user_ids [list]
      for {set i 1} {$i <= $nr} {incr i} {
        set user [acs::test::user::create]
        lappend user_ids [dict get $user user_id]
      }
      return $user_ids
    }

    ad_proc -private delete_test_user {-user_id} {
      acs_user::delete -user_id $user_id -permanent
    }

    ad_proc -private random_element {l} {
      lindex $l [expr {int(rand()*[llength $l])}]
    }

    ad_proc -private random_timestamp {} {
      Stupid random date generator.
    } {
        # Random date for dummies...
        for {set i 2001} {$i < 2016} {incr i} {lappend years $i}
        for {set i 1} {$i <= 12} {incr i} {lappend months [format %02d $i]}
        for {set i 1} {$i <= 28} {incr i} {lappend days [format %02d $i]}
        for {set i 0} {$i <= 23} {incr i} {lappend hours [format %02d $i]}
        for {set i 0} {$i <= 59} {incr i} {lappend minsecs [format %02d $i]}
        set ts [::xolp::test::random_element $years]-[::xolp::test::random_element $months]-[::xolp::test::random_element $days]
        append ts " "
        append ts [::xolp::test::random_element $hours]:[::xolp::test::random_element $minsecs]:[::xolp::test::random_element $minsecs]
        append ts " z"
        return $ts
    }

    ad_proc -private random_earlier_timestamp {ts} {
      Simple function to generate from an end_timestamp a "random"
      begin_timestamp, which is within sensible boundaries.
    } {
      set ts [clock scan $ts -format "%Y-%m-%d %T z" -timezone :UTC]
      clock format [clock add $ts -[expr {int(rand()*180)}] minute] -format "%Y-%m-%d %T z" -timezone :UTC
    }

    ad_proc -private get_testcase_for_documentation {
      -case:required
      {-index 3}
    } {
      package require textutil
      foreach t [nsv_get aa_test cases] {
        lassign $t id desc file pkg cats inits err body _
        if {$id eq $case && $pkg eq "xolp"} {
          return "<pre><code>[regsub "\n\n" [textutil::undent [lindex $body 0 $index]] ""]</code></pre>"
        }
      }
    }

  }

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
