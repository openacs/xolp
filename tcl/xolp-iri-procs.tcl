::xo::library doc {
  IRI (URI/URN) oriented database layer

  @author Michael Aram
  @creation-date 2017
}

namespace eval ::xolp {}
namespace eval ::xolp::iri {

  ::xotcl::Class create ::xolp::iri::MetaClass \
    -superclass ::xo::db::Class \
    -parameter {
      {iri_unique true}
    } -ad_doc {
      This meta class provides generic methods for the
      application classes (such as ::xolp::Activity).
    }

  ::xolp::iri::MetaClass ad_instproc init {args} {
    Initializes the application class with an iri attribute and
    an accompanying (usually unique) index.
  } {
    :superclass ::xo::db::Object
    :slots {
      ::xo::db::Attribute create iri
    }
    next
      if {[::xo::db::require exists_table ${:table_name}]} {
      :log "Requiring unique index for ${:table_name}.iri"
      ::xo::db::require index -table ${:table_name} -col "iri" -unique ${:iri_unique}
    }
  }

  ::xolp::iri::MetaClass ad_instproc get_object_ids {
    -iri:required
  } {
    Get the object_id of the ACS Object identified by this IRI.
    For versioned objects like ::xolp::Activity, multiple ACS Object IDs may be returned.
    @return a list of ACS Object IDs
  } {
    :instvar id_column table_name
    ::xo::dc list_of_lists get_object_ids "SELECT $id_column FROM $table_name WHERE iri = :iri ORDER BY $id_column DESC"
  }

  ::xolp::iri::MetaClass ad_instproc require {
    -iri:required
    {-update true}
    {-return ""}
    args
  } {
    Require (create or update) an object for this IRI.
    @param update Whether or not to update an existing object with the provided values.
    @param return Specify kind of return value. The default will return nothing and is the fastest.
                  Further valid values are "id" (returns the newly created indicator_id)
                  and "object", which returns an initialized instance object of type Indicator.
    @return Returns an id or an instantiated object.
  } {
    set object_ids [:get_object_ids -iri $iri]
    if {$object_ids eq ""} {
      # Newly created object
      set instance [:new_persistent_object -iri $iri {*}$args]
      set object_id [$instance object_id]
    } else {
      # Reused object
      set object_id [lindex $object_ids 0]
      if {$return ne "id" || $update} {
        set instance [::xo::db::Class get_instance_from_db -id $object_id]
      }
      if {$update} {
        #:log "[self] with IRI $iri already exists. Updating properties of latest..."
        $instance configure {*}$args
        $instance save
        set instance [::xo::db::Class get_instance_from_db -id $object_id]
      }
    }
    return [expr {$return eq "id" ? $object_id : $instance}]
  }

  ::xolp::iri::MetaClass ad_instproc delete {
    -iri:required
  } {
    Delete all objects identified by this IRI, including any object versions (if iri_unique false).
  } {
    :instvar table_name
    return [::xo::dc dml delete "DELETE FROM $table_name WHERE iri = :iri"]
  }

}

::xo::library source_dependent
