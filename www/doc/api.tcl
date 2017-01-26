set lib_root packages/xolp/tcl
set porcelain_lib [api_library_documentation $lib_root/porcelain-procs.tcl]

set porcelain_api {
}

foreach p [nsv_get api_proc_doc_scripts $lib_root/xolp-procs.tcl] {
    if {[lsearch $porcelain_api $p] eq -1} {
        ns_log notice "XOCP Doc: procedure $p is not included in the handbook"
    }
}

::template::multirow create porcelain_procs porcelain_proc
foreach porcelain_proc $porcelain_api {
  ::template::multirow append porcelain_procs [api_proc_documentation $porcelain_proc]
}

::template::multirow create library_files path
set libfiles [lsort -dictionary [list \
    {*}[glob -directory [acs_root_dir]/$lib_root/ *-procs.tcl] \
    {*}[glob -directory [acs_root_dir]/$lib_root/test/ *-procs.tcl]]]
foreach library_file $libfiles {
  if {[string match *porcelain* $library_file]} continue
  set doc [api_library_documentation [regsub [acs_root_dir]/ $library_file ""]]
  ::template::multirow append library_files $doc
}

