<h2 id="design-decisions">Design Decisions</h2>

<dl>
  <dt>Scope</dt>
  <dd>
    The <code>xolp</code> package is considered to be a "backend" service
    that provides a storage infrastructure for indicators with
    an accompanying API for retrieval and analysis.<br>
    The following aspects are considered <em>in scope</em>:
    <dl>
      <dt>(Durable) Storage of Indicators and Activities</dt>
      <dd>
        The persistence of indicators and activities.
        Although it is possible to update and delete all data via the API,
        indicators are typically simply imported/pushed into the
        data base without the need for further modification.
        Changes to the activities related to these indicators should
        typically create new activity versions, i.e. activity information is
        historicized.
        An activity should remain in the <code>xolp</code> storage even if the
        source objects (e.g. an assessment object) are deleted. (For pragmatic
        reasons it is possible to delete an activity with the associated
        indicators, though.)
      </dd>
      <dt>Retrieval and Evaluation of Indicators</dt>
      <dd>
        The <code>xolp</code> API provides means for simple retrieval and
        filtering of indicators, and their evaluation with respect to
        evaluation schemas/scales.
      </dd>
    </dl>
    The following aspects should be managed by the client (e.g. a "gradebook"
    package, or an "e-portfolio" package) and are therefore considered
    <em>out of scope</em>:
    <dl>
      <dt>User Interface</dt>
      <dd>
        The <code>xolp</code> package is considered a backend service without a UI.
      </dd>
      <dt>Triggering Activity Historization</dt>
      <dd>
        The <code>xolp</code> API provides means to create a new version of an
        activity. However, the point in time when this should happen must be
        decided by the client application.
      </dd>
      <dt>Permissions Management</dt>
      <dd>
        Access control (e.g. to the indicators) is considered to be
        implemented at the application layer, i.e. within an application using
        the <code>xolp</code> service.
      </dd>
    </dl>
  </dd>
  <dt>Dimensional Data Model</dt>
  <dd>
    In order to gain high query performance and flexible basis for various
    analyses, we decided to follow a
    <a href="http://www.kimballgroup.com/1997/08/a-dimensional-modeling-manifesto/">dimensional
    modeling</a> approach (in contrast to an entity-relationship approach).
    There is a central fact table (<code>xolp_indicator_facts</code>) that stores
    all actual measures (indicators) surrounded by a range of dimension tables
    to provide context for these measured values.
  </dd>
  <dt>Identification for (several) Entities via Schematic String-based Resource Identifiers</dt>
  <dd>
    The architecture of the WWW promotes the notion of <a target="_blank" href="https://www.w3.org/TR/webarch/#identification">
    global identifiers for resource identification</a>, such as Internationalied Resource Identifier (IRI),
    Uniform Resource Identifiers (URI) or Uniform Resource Names (URN).
    <dl>
      <dt>Identification of Sparse Entities via Strings (EvaluationScale, EvaluationSchema, ActivityVerb)</dt>
      <dd>
        There are several entities in <code>xolp</code> for which we expect only a few instances.
        For example, we will only need a handful of ActivityVerbs and EvaluationSchemas, and in practice
        probably even not too many EvalutionScales (if the client application cares about deduplication).
        By referring to these resources via human-readable identifiers, we are able to write nice readable
        code such as
        <code>::xolp::EvaluationSchema require -iri "https://dotlrn.org/xolp/evaluation-schemas/at-five-to-one"</code>
        or
        <code>::xolp::ActivityVerb require -iri "http://adlnet.gov/expapi/verbs/experienced"</code>.
      </dd>
      <dt>Activity Identification</dt>
      <dd>
        At the point in time at which an activity is initially registered within the xolp
        activity dimension table, this activity might (a) already exists as an
        ACS Object in the system, (b) exists as a tuple of a table that does not
        inherit from acs_objects, or (c) not be represented in the system at all.
        An example for (a) would be an xowf based test, for (b) would be a (manual)
        grade book entry (tlf-gradebook), and for (c) could be an not-yet registered
        activity (e.g. a presentation) for which indicators are imported
        via a CSV file.

        There are at least two approaches for handling these cases: On the one hand,
        we could create ACS Objects for all activities that do not already have one
        (such as (b) and (c)). Then, a column "object_id" in the activity dimension
        table could be used to group the activity versions. This, however, would
        require a separate table (such as xolp_activities) that (unintuitively)
        stores only a subset of relevant activities.
        On the other hand, by using IRIs (URIs/URNs), one can simply identify
        arbitrary activities without the need for a separate table. We use the scheme
        <code>openacs:&lt;table&gt;:&lt;id&gt;</code> for ACS Objects (a) and other
        internal tuples (b), but basically allow for arbitrary IRIs.
        The client system that stores the indicators and activities is
        required and trusted to use unambiguous IRIs.
      </dd>
    </dl>
  </dd>
  <dt>Percentage-based Indicators</dt>
  <dd>
    Indicators are the "facts" of our star/snowflake schema and are
    merely <a href="http://martinfowler.com/bliki/ValueObject.html">"value objects"</a>.
    Each indicator is a <em>time-stamped percentage</em> value.
    Therefore, and because we expect a huge amount of entries in this table,
    we did not design indicators as full-fledged ACS Objects.
  </dd>
  <dt>A "Slowly Changing Dimension" for Activities</dt>
  <dd>
    For any indicator (e.g. a grade) the system must persist the
    context permanently and historically valid. For example, the deletion of
    a test question in the system must not cascade to the associated
    students' grades. Therefore, we implemented the Activity Dimension as a
    <a href="http://www.kimballgroup.com/2008/09/slowly-changing-dimensions-part-2/">
    Slowly Changing Dimension (of Type 2)</a>.
  </dd>
  <dt>Activity Hierarchy</dt>
  <dd>
    It is natural to think of activities at different granularity levels, or that
    an activity can comprise several sub-activities.
    Therefore, <code>xolp</code> models activities in the form of an hierarchical tree,
    and treats a course, a test, a group work, etc. as activities.
    Within a context (super-activity), each (sub-)activity has a certain weight, the sum of which
    is typically 100%. (Exceptions are special cases such as the virtual activity
    "Group work" below, where we assume that only one of the two forks is possible for a
    particular user.)
    Although it is not prevented that one activity has multiple parents
    (which makes the hierarchy a polyhierarchy),
    one would typically model activities as a hierarchical tree of contextualized activities.
    <div class="figure">
    <object data="figures/xolp-activity.svg" type="image/svg+xml" style="width:75%">
      <img src="figures/xolp-activity.png" style="width:100%"/>
    </object>
    <p>Figure 2: Example of a simple contextualized activity hierarchy.</p>
    </div>
  </dd>
  <dt>Competency Graph</dt>
  <dd>
    Similar to the activity hierarchy, <code>xolp</code> models competencies in the form of
    directed acyclical graph.
    One or more activities can prove one or more competencies.
    Currently, the activities that book onto the same competency "overlap", i.e. the lowest/average/highest
    percentage takes precedence, depending on the result policy (i.e. whether to count to best result,
    the worst result, or the average result).
    (Example: If one exam shows you are a mediocre software developer, and another one shows
    you are a good one, we assume, you are a good one.)
    <div class="figure">
    <object data="figures/xolp-competency.svg" type="image/svg+xml" style="width:75%">
      <img src="figures/xolp-competency.png" style="width:100%"/>
    </object>
    <p>Figure 2: Example of a simple competency graph (result policy: best).</p>
    </div>
  </dd>
</dl>
