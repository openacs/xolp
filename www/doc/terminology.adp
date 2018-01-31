<h2 id="terminology" class="pagebreak">Terminology</h2>

<dl>
  <dt>Activity</dt>
  <dd>
    In general, an activity is <a href=
    "http://www.macmillandictionary.com/dictionary/british/activity" target="_blank">
    something that someone does</a>.
    For example, 'hiking' in the course of a hiking day in school,
    'experiencing a video', 'attempting a test', 'carrying out an experiment', or
    'participating in a course'.
    Within the xolp system, these processes (activities) are considered to be
    referred to/identified by IRIs.
    <br>
    Note: The detailed semantics of how to represent activities (processes)
    and/or their instances is up to the context and domain of the client of
    the xolp package.
    In other words, whether or not the fact that "three people answered a personalized
    questionnaire" translates into one activity (performed by three people) or
    into three distinct activities) has to be decided by the client package's
    designer.
  </dd>
  <dt>Indicator</dt>
  <dd>
    An indicator is a small-grained a measurable fact,
    such as the amount of points scored by answering a question, or
    the fact that a user has downloaded a PDF file.
    Each indicator is associated with exactly one activity.
  </dd>
  <dt>Competency</dt>
  <dd>
    A competency is a demand-oriented human potentiality for action
    that can be learned and involves cognitive and non-cognitive elements
    (see Stahl and Wild 2006).
  </dd>
  <dt>Evaluation Schema</dt>
  <dd>
    An evaluation schema is a schema for translating learning
    indicators into semantically more meaningful units (such as grades).
    Each evaluation schema has (at least two) ordered levels (e.g. "not
    attempted" and "attempted"), one or more of which are considered.
    For example, the Austrian grading schema, which comprises five
    distinct grades (1 to 5) is an evaluation schema with five levels.
  </dd>
  <dt>Evaluation Scale</dt>
  <dd>
    An evaluation scale specifies the ranges of the levels
    of an evaluation schema in terms of percentage thresholds.
    For example, in the context of activity A, one might need at least
    90% to gain the highest level, whereas for activity B 75% are
    considered sufficient.
  </dd>
</dl>

<div class="figure">
<object data="figures/xolp-evaluation.svg" type="image/svg+xml" style="width:100%">
  <img src="figures/xolp-evaluation.png" style="width:100%"/>
</object>
<p>Figure 1: Evaluation Schemas and Evaluation Scales exemplified.</p>
</div>

