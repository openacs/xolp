::xo::library doc {
  Utility procs.

  @author Michael Aram
  @date 2017
}

package require uuid

#################
#               #
#   Utilities   #
#               #
#################

namespace eval ::xolp::util {

    ad_proc lcontains {list1 list2} {
      foreach pattern $list2 {
        if {[lsearch $list1 $pattern] ne -1} {return 1}
      }
      return 0
    }

    ad_proc ltransform {{-prefix ":"} {-suffix ""} list} {
      set transformed_list {}
      foreach e $list {lappend transformed_list ${prefix}${e}${suffix}}
      return $transformed_list
    }

    ad_proc lremove {list elements_to_be_removed} {
        foreach e $elements_to_be_removed {
          set list [lsearch -all -inline -not -exact $list $e]
        }
        return $list
    }

    #if {$generate_iri_path} {set iri "${iri}:[uuid::uuid generate]"}
}

######################
#                    #
#   Test Utilities   #
#                    #
######################

namespace eval ::xolp::test {

    ad_proc create_test_iris {{-nr 1}} {} {
      set iris {}
      for {set i 1} {$i <= $nr} {incr i} {
        lappend iris "xolp:test:[uuid::uuid generate]"
      }
      return $iris
    }

    ad_proc create_test_users {{-nr 1}} {} {
      set user_ids {}
      for {set i 1} {$i <= $nr} {incr i} {
        set uuid [uuid::uuid generate]
        set email test.xolp.${uuid}@example.com
        set test_user ""
        if {![apm_package_installed_p "tlf-kernel"]} {
          # Normal Mode
          set test_user [auth::create_user -last_name XOLPTEST -first_names $uuid -email $email]
        }
        if {[dict exists $test_user user_id] && [dict get $test_user user_id] ne {}} {
          lappend user_ids [dict get $test_user user_id]
        } else {
          # auth::create_user failed for some reason (e.g. its 'broken' on Learn@WU).
          # Let's give it another try using the low level function.
          # email first_names last_name password password_question password_answer url email_verified_p member_state user_id username authority_id screen_name
          set uid [auth::create_local_account_helper $email $uuid XOLPTEST password password_question password_answer http://example.com t approved "" $email "" ""]
          if {$uid ne 0} {lappend user_ids $uid}
        }
      }
      if {$user_ids eq ""} {
        ns_log Error "Failed to create a test user."
      }
      return $user_ids
    }

    ad_proc delete_test_user {-user_id} {} {
      acs_user::delete -user_id $user_id -permanent
    }

    ad_proc random_element {l} {} {
        lindex $l [expr {int(rand()*[llength $l])}]
    }

    ad_proc random_timestamp {} {
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

    ad_proc random_earlier_timestamp {ts} {
        Simple function to generate from an end_timestamp a "random" begin_timestamp,
        which is within sensible boundaries.
    } {
        set ts [clock scan $ts -format "%Y-%m-%d %T z" -timezone :UTC]
        clock format [clock add $ts -[expr {int(rand()*180)}] minute] -format "%Y-%m-%d %T z" -timezone :UTC
    }

    ad_proc -private get_testcase_for_documentation {-case:required {-index 3}} {
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
