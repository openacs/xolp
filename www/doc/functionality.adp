<h2 id="functionality" class="pagebreak">Functionality</h2>

<p>
The functionality provided by the <code>xolp</code> package is explained
in the form of simple api usage examples in the following.
</p>

<h3 id="usecases">API Usage Examples</h3>

<h4>Minimal example</h4>
<p>
The following example creates an indicator of 95% for the currently
logged in user, where the current URL is taken as activity identifier.
(Developers should carefully consider if these defaults make sense in their
application context.)
</p>
<pre><code>::xolp::Indicator insert -result_numerator 95</code></pre>

<h4>Typical example</h4>
<p>
Suppose there was an Austrian school teacher who conducted a final paper-and-pencil
test with three students on 20th December 2016.
One student did an excellent job, one showed mediocre performance, one failed.
The two positive students practiced before.
</p>

<h5>Practicing</h5>
<p>
Firstly, we require an object in the system for the practicing activity:
</p>
<pre><code>set practice_test_id [::xolp::Activity require \
  -iri "http://myschool.example.com/2016/class1/course1/practice-test" \
  -title "Practice test" \
  -return id]
</code></pre>
<p>
Secondly, we require fetch the id for the verb "practiced":
</p>
<pre><code>set activity_verb_id [::xolp::ActivityVerb require \
  -iri "http://dotlrn.org/xolp/activity-verbs/practiced" \
  -return id]
</code></pre>

<p>
Now we can store the students practicing results:
</p>
<pre><code>::xolp::Indicator insert \
  -user_id 1 \
  -activity_version_id $practice_test_id \
  -begin_timestamp "2016-12-18 20:58:00" \
  -end_timestamp "2016-12-18 22:10:00" \
  -result_numerator 3 \
  -result_denominator 10

::xolp::Indicator insert \
  -user_id 2 \
  -activity_version_id $practice_test_id \
  -begin_timestamp "2016-12-18 15:54:30" \
  -end_timestamp "2016-12-18 16:59:20" \
  -result_numerator 7 \
  -result_denominator 10
</code></pre>

<h5>Examination</h5>
<p>
Analogously, we require an object and verb for the actual test:
</p>
<pre><code>set exam_id [::xolp::Activity require \
  -iri "http://myschool.example.com/2016/class1/course1/final-test" \
  -title "Final test" \
  -return id]
set activity_verb_id [::xolp::ActivityVerb require \
  -iri "http://dotlrn.org/xolp/activity-verbs/competed" \
  -return id]
</code></pre>
<pre><code>::xolp::Indicator insert \
  -user_id 1 \
  -activity_version_id $exam_id \
  -begin_timestamp "2016-12-20 09:00:30" \
  -end_timestamp "2016-12-20 09:58:00" \
  -result_numerator 100 \
  -result_denominator 100

::xolp::Indicator insert \
  -user_id 2 \
  -activity_version_id $exam_id \
  -begin_timestamp "2016-12-20 09:00:20" \
  -end_timestamp "2016-12-20 09:59:30" \
  -result_numerator 60 \
  -result_denominator 100

::xolp::Indicator insert \
  -user_id 3 \
  -activity_version_id $exam_id \
  -begin_timestamp "2016-12-20 09:01:00" \
  -end_timestamp "2016-12-20 10:02:00" \
  -result_numerator 25 \
  -result_denominator 100
</code></pre>

<h5>Evaluation</h5>
<p>
At the end of the day, the teacher decides to evaluate the students' results
with his usual grade scale, where one needs 50% to be positive, and 70%,
80% and 90% to get the next higher mark within the Austrian Grading Schema.
</p>

<pre><code>set evalschema [::xolp::EvaluationSchema require \
  -iri "https://dotlrn.org/xolp/evaluation-schemas/at-five-to-one"]

set evalscale [::xolp::EvaluationScale require \
  -iri "http://myschool.example.com/gradingschemas/standard" \
  -evalschema_id [$evalschema object_id] \
  -title "MySchool Standard Evaluation Scale" \
  -thresholds {50 70 80 90}]

$evalscale add_to_activity -activity_version_id $activity_version_id

::xolp::User get_activity_evaluation \
    -user_id 1 \
    -iri "http://myschool.example.com/2016/class1/course1/final-test"
</code></pre>

<h4>Indicator Retrieval</h4>
<p>
There is a generic procedure
<a href="/api-doc/proc-view?proc=%3a%3axolp%3a%3aIndicator+proc+get_values_from_db&source_p=1"><code>::xolp::Indicator get_values_from_db</code></a>
that allows for (filtered) retrieval of indicators from the fact table.
</p>

<h5>Date/Time-based Filtering</h5>
<p>
An example for retrieving indicators filtered by time
is implemented in testcase
<a href="/test/admin/testcase?testcase_id=indicator_time_queries&package_key=xolp&showsource=1">indicator_datetime_queries</a>
and exemplified below.
</p>
<pre><code>set activity_iri "http://example.com/practice1"
set activity_version_id [::xolp::Activity require -iri $activity_iri -return id]

# Weekend practicing
::xolp::Indicator insert \
  -activity_version_id $activity_version_id \
  -end_timestamp "2016-12-31 23:00:00" \
  -result_numerator 40
::xolp::Indicator insert \
  -activity_version_id $activity_version_id \
  -end_timestamp "2017-01-01 11:30:00" \
  -result_numerator 50

# Weekday practicing
::xolp::Indicator insert \
  -activity_version_id $activity_version_id \
  -end_timestamp "2017-01-02 11:30:00" \
  -result_numerator 60

# All results for this activity
set li [::xolp::Indicator get_values_from_db \
  -user_ids [ad_conn user_id] \
  -activity_iris $activity_iri]

# Dictionary "li"
#  - keys: indicator_ids
#  - values: percentages
# 12345 40.00 12346 50.00 12347 60.00

# Results from weekends
set li [::xolp::Indicator get_values_from_db \
  -user_ids [ad_conn user_id] \
  -activity_iris $activity_iri \
  -end_date_constraint "end_is_weekend = TRUE" ]

# Dictionary "li"
# 12345 40.00 12346 50.00

# Results from weekends in 2016
set li [::xolp::Indicator get_values_from_db \
  -user_ids [ad_conn user_id] \
  -activity_iris $activity_iri \
  -begin_date_constraint "begin_year = '2016'" \
  -end_date_constraint "end_is_weekend = TRUE" ]

# Dictionary "li"
# 12345 40.00

# Average result for this activity
set li [::xolp::Indicator get_values_from_db \
  -aggregate avg \
  -user_ids [ad_conn user_id] \
  -activity_iris $activity_iri]

# Dictionary "li"
#  - keys: aggregated indicator_ids
#  - values: aggregated percentages
# {12345 12346 12347} 50.00

</code>
</pre>

<comment>
<%= [::xolp::test::get_testcase_for_documentation -case "indicator_datetime_queries"] %>
</comment>

<h5>Activity Verb-based Filtering (i.e. Usage Type)</h5>
<p>
An example for retrieving indicators filtered by usage type (ActivityVerb) is implemented in testcase
<a href="/test/admin/testcase?testcase_id=indicator_verb_queries&package_key=xolp&showsource=1">indicator_verb_queries</a>.
</p>

<pre><code>
set activity [::xolp::Activity require -iri "http://example.com/activities/test1"]
set practiced_verb [::xolp::ActivityVerb require -iri "http://example.com/verbs/practiced"]
set competed_verb [::xolp::ActivityVerb require -iri "http://example.com/verbs/competed"]

# Practicing
::xolp::Indicator insert \
  -end_timestamp "2014-01-01" \
  -activity_version_id [$activity activity_version_id] \
  -activity_verb_id [$practiced_verb activity_verb_id] \
  -result_numerator 80

# Exam
::xolp::Indicator insert \
  -end_timestamp "2014-01-02" \
  -activity_version_id [$activity activity_version_id] \
  -activity_verb_id [$competed_verb activity_verb_id] \
  -result_numerator 90

# All results for this activity
set results(all) [::xolp::Indicator get_values_from_db \
  -user_ids [ad_conn user_id] \
  -activity_iris [$activity iri]]

# Only exam results
set results(competed) [::xolp::Indicator get_values_from_db \
  -user_ids [ad_conn user_id] \
  -activity_iris [$activity iri] \
  -activity_verb_iris [$competed_verb iri]]

array get results
# competed {124 90.00} all {123 80.00 124 90.00}
</code>
</pre>

<h3>Test Cases</h3>

<p>
The xolp package is shipped with a
<a href="/test/admin/index?by_package_key=xolp&view_by=testcase">comprehensive test suite</a>,
which can serve as a cookbook for developers with respect to correctly
using the api.
</p>


<!--
<table>
  <tr>
    <td>Name</td>
    <td></td>
  </tr>
  <tr>
    <td>Description</td>
    <td></td>
  </tr>
  <tr>
    <td>Actors</td>
    <td></td>
  </tr>
  <tr>
    <td>Assumptions & Triggers</td>
    <td></td>
  </tr>
  <tr>
    <td>Basic Flow of Events</td>
    <td></td>
  </tr>
  <tr>
    <td>Variants and Exceptions</td>
    <td></td>
  </tr>
  <tr>
    <td>Results</td>
    <td></td>
  </tr>
  <tr>
    <td>Issues</td>
    <td></td>
  </tr>
</table>
-->

