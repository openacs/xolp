<h3 id="api">Application Programming Interface</h3>
<p>
In this section, the most important parts of the application programming
interface of the <code>xolp</code> package are described. For a complete,
browsable version please refer to the
<a href="/api-doc/?about_package_key=xolp">OpenACS API Browser</a>.
</p>

<p>
In general, the xolp package is based on the
<a href="http://www.openacs.org/xowiki/xotcl-core-db">::xo::db object relational database interface</a>
and therefore the model classes (those classes that manage persistent objects)
inherit generic methods such as <code>new_persistent_object</code> from there.

</p>
<comment>
<h4>Porcelain API</h4>
<div class="library_file">
    @porcelain_lib;noquote@
    <multiple name="porcelain_procs">
        <div class="porcelain_proc">
            @porcelain_procs.porcelain_proc;noquote@
        </div>
    </multiple>
</div>

<h4>Internal Components</h4>
</comment>
<multiple name="library_files">
<div class="library_file">
    @library_files.path;noquote@
</div>
</multiple>
