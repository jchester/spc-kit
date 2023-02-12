create schema if not exists spc_intermediates;

comment on schema spc_intermediates is $$
This schema encapsulates a variety of intermediate calculations, taking data from spc_data and exposing calculated
values that are used in spc_reports.
$$;

-- @formatter:off
create view spc_intermediates.scaling_factors(sample_size, a, a2, a3, c4, c4_reciprocal, b3, b4, b5, b6, lower_d2, lower_d2_reciprocal, lower_d3, upper_d1, upper_d2, upper_d3, upper_d4) as
values
--         a       a2      a3       c4    c4_reciprocal   b3        b4,   b5         b6    lower_d2  lower_d2_reciprocal   lower_d3   upper_d1    upper_d2    upper_d3   upper_d4
  (2,     2.121,  1.88,   2.659,  0.7979,   1.0/0.7979,   0,      3.267,  0,        2.606,  1.128,     1.0/1.128,            0.853,      0,        3.686,       0,        3.267)
, (3,     1.732,  1.023,  1.954,  0.8862,   1.0/0.8862,   0,      2.568,  0,        2.276,  1.693,     1.0/1.693,            0.888,      0,        4.358,       0,        2.574)
, (4,     1.5,    0.729,  1.628,  0.9213,   1.0/0.9213,   0,      2.266,  0,        2.008,  2.059,     1.0/2.059,            0.88,       0,        4.698,       0,        2.282)
, (5,     1.342,  0.577,  1.427,  0.94,     1.0/0.94,     0,      2.089,  0,        1.964,  2.326,     1.0/2.326,            0.864,      0,        4.918,       0,        2.114)
, (6,     1.225,  0.483,  1.287,  0.9515,   1.0/0.9515,   0.03,   1.97,   0.029,    1.874,  2.534,     1.0/2.534,            0.848,      0,        5.078,       0,        2.004)
, (7,     1.134,  0.419,  1.182,  0.9594,   1.0/0.9594,   0.118,  1.882,  0.113,    1.806,  2.704,     1.0/2.704,            0.833,      0.204,    5.204,       0.076,    1.924)
, (8,     1.061,  0.373,  1.099,  0.965,    1.0/0.965,    0.185,  1.815,  0.179,    1.751,  2.847,     1.0/2.847,            0.82,       0.388,    5.306,       0.136,    1.864)
, (9,     1,      0.337,  1.032,  0.9693,   1.0/0.9693,   0.239,  1.761,  0.232,    1.707,  2.97,      1.0/2.97,             0.808,      0.547,    5.393,       0.184,    1.816)
, (10,    0.949,  0.308,  0.975,  0.9727,   1.0/0.9727,   0.284,  1.716,  0.276,    1.669,  3.078,     1.0/3.078,            0.797,      0.687,    5.469,       0.223,    1.777)
, (11,    0.905,  0.285,  0.927,  0.9754,   1.0/0.9754,   0.321,  1.679,  0.313,    1.637,  3.173,     1.0/3.173,            0.787,      0.811,    5.535,       0.256,    1.744)
, (12,    0.866,  0.266,  0.886,  0.9776,   1.0/0.9776,   0.354,  1.646,  0.346,    1.610,  3.258,     1.0/3.258,            0.778,      0.922,    5.594,       0.283,    1.717)
, (13,    0.832,  0.249,  0.85,   0.9794,   1.0/0.9794,   0.382,  1.618,  0.374,    1.585,  3.336,     1.0/3.336,            0.77,       1.025,    5.647,       0.307,    1.693)
, (14,    0.802,  0.235,  0.817,  0.981,    1.0/0.981,    0.406,  1.594,  0.399,    1.563,  3.407,     1.0/3.407,            0.763,      1.118,    5.696,       0.328,    1.672)
, (15,    0.775,  0.223,  0.789,  0.9823,   1.0/0.9823,   0.428,  1.572,  0.421,    1.544,  3.472,     1.0/3.472,            0.756,      1.203,    5.741,       0.347,    1.653)
, (16,    0.75,   0.212,  0.763,  0.9835,   1.0/0.9835,   0.448,  1.552,  0.44,     1.526,  3.532,     1.0/3.532,            0.75,       1.282,    5.782,       0.363,    1.637)
, (17,    0.728,  0.203,  0.739,  0.9845,   1.0/0.9845,   0.466,  1.534,  0.458,    1.511,  3.588,     1.0/3.588,            0.744,      1.356,    5.82,        0.378,    1.622)
, (18,    0.707,  0.194,  0.718,  0.9854,   1.0/0.9854,   0.482,  1.518,  0.475,    1.496,  3.64,      1.0/3.64,             0.739,      1.424,    5.856,       0.391,    1.608)
, (19,    0.688,  0.187,  0.698,  0.9862,   1.0/0.9862,   0.497,  1.503,  0.490,    1.483,  3.689,     1.0/3.689,            0.734,      1.487,    5.891,       0.403,    1.597)
, (20,    0.671,  0.18,   0.68,   0.9869,   1.0/0.9869,   0.51,   1.49,   0.504,    1.470,  3.735,     1.0/3.735,            0.729,      1.549,    5.921,       0.415,    1.585)
, (21,    0.655,  0.173,  0.663,  0.9876,   1.0/0.9876,   0.523,  1.477,  0.516,    1.459,  3.778,     1.0/3.778,            0.724,      1.605,    5.951,       0.425,    1.575)
, (22,    0.64,   0.167,  0.647,  0.9882,   1.0/0.9882,   0.534,  1.466,  0.528,    1.448,  3.819,     1.0/3.819,            0.72,       1.659,    5.979,       0.434,    1.566)
, (23,    0.626,  0.162,  0.633,  0.9887,   1.0/0.9887,   0.545,  1.455,  0.539,    1.438,  3.858,     1.0/3.858,            0.716,      1.710,    6.006,       0.443,    1.557)
, (24,    0.612,  0.157,  0.619,  0.9892,   1.0/0.9892,   0.555,  1.445,  0.549,    1.429,  3.895,     1.0/3.895,            0.712,      1.759,    6.031,       0.451,    1.548)
, (25,    0.6,    0.153,  0.606,  0.9896,   1.0/0.9896,   0.565,  1.435,  0.559,    1.420,  3.931,     1.0/3.931,            0.708,      1.806,    6.056,       0.459,    1.541);

comment on view spc_intermediates.scaling_factors is $$
These are scaling factors used in calculations of control limits on a variety of charts, according to the sample size
used. Some of these values are derived from other values and could be calculated at view creation time, but for
simplicity pre-computed values are used. Other values (like c4) are derived from calculus equations that cannot be
performed by the database and so must be sourced from existing lookup tables.

Because this table only runs to 25 samples, that is the maximum sample size this schema can deal with. Ideally in future
a program may be able to generate a much larger table for cases where very large samples can be obtained (eg. computer
benchmarking).

Data from https://qualityamerica.com/LSS-Knowledge-Center/statisticalprocesscontrol/control_chart_constants.php and
Appendix VI of Montgomery.
$$;
-- @formatter:on

-- Shewart chart statistics

create view spc_intermediates.measurement_sample_statistics as
  select s.id
       , s.period
       , s.include_in_limit_calculations
       , avg(measured_value)                       as sample_mean
       , stddev_samp(measured_value)               as sample_stddev
       , max(measured_value) - min(measured_value) as sample_range
       , count(1)                                  as sample_size
  from spc_data.measurements m
       join spc_data.samples s on s.id = m.sample_id
  group by s.id, s.period;

comment on view spc_intermediates.measurement_sample_statistics is $$
The basis of statistical process control (SPC) is to batch periodic measurements into samples, and then to calculate
information about them at the sample level, rather than the individual level. This allows SPC techniques to distinguish
between variation that is due to in-sample effects versus between-sample effects.

This view calculates the four foundational sample statistics that are used in SPC calculations. These are:

* x̄, aka "X bar". The average of the measurements in the sample.
* s. The sample standard deviation of the measurements in the sample.
* R. The range of the measurements in the sample.
* The sample size or count of the measurements in the sample.

Note that this data is used for variable data only. For attribute data, see the views used for calculating fraction
conformant & non-conformant.
$$;

create view spc_intermediates.measurement_limit_establishment_statistics as
  select w.id               as limit_establishment_window_id
       , avg(sample_mean)   as grand_mean
       , avg(sample_stddev) as mean_stddev
       , avg(sample_range)  as mean_range
       , avg(sample_size)   as mean_sample_size
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           w on ss.period <@ w.period
  where w.type = 'limit_establishment'
    and ss.include_in_limit_calculations
  group by w.id;

comment on view spc_intermediates.measurement_limit_establishment_statistics is $$
Once per-sample statistics have been calculated, the next step in SPC is to derive the center lines for each of the
control charts. These are, simply put, the averages of the sample statistics within the limit establishment window.
These are:

* ̿x, aka "X double bar" or "grand average/mean". The average of all sample x̄ values. Equals the average of all
  measurements in the window if the sample sizes are equal.
* s̄, aka "s bar". The average of the standard deviations of the samples.
* R̄, aka "R bar". The average of the ranges of the samples.
* The average sample size or average count of measurements in the samples. This is used as a join value in subsequent
  views to look up records in scaling_factors.

At the moment this code does not support variable sample sizes, so the average sample size should be identical to every
sample size in the window.
$$;

create view spc_intermediates.x_bar_r_limits as
  select limit_establishment_window_id
       , grand_mean +
         ((select a2 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_range) as upper_control_limit
       , grand_mean   as center_line
       , grand_mean -
         ((select a2 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_range) as lower_control_limit
  from spc_intermediates.measurement_limit_establishment_statistics;

comment on view spc_intermediates.x_bar_r_limits is $$
For each limit establishment window, this view derives the x̄R upper control limit, center line and lower control limit.
The x̄R (aka XbarR) limits are based on the average of samples for the center line and sample ranges as its measurement
of variability within each sample and across samples.

Historically, x̄R limits have been typically used for samples where the sample size is 10 or less. Ranges were preferred
as the measurement of sample variability because they are easy to calculate by hand.
$$;


create view spc_intermediates.r_limits as
  select limit_establishment_window_id
       , ((select upper_d4 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_range) as upper_control_limit
       , mean_range   as center_line
       , ((select upper_d3 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_range) as lower_control_limit
  from spc_intermediates.measurement_limit_establishment_statistics;

comment on view spc_intermediates.r_limits is $$
For each limit establishment window, this view derives the R̄ upper control limit, center line and lower control limit.
The R̄ (aka R bar) limits are based on the ranges (max - min) of samples.
$$;

create view spc_intermediates.x_bar_s_limits as
  select limit_establishment_window_id
       , grand_mean + ((select a3 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
                       mean_stddev) as upper_control_limit
       , grand_mean                 as center_line
       , grand_mean - ((select a3 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
                       mean_stddev) as lower_control_limit
  from spc_intermediates.measurement_limit_establishment_statistics;

comment on view spc_intermediates.x_bar_s_limits is $$
For each limit establishment window, this view derives the x̄s upper control limit, center line and lower control limit.
The x̄s (aka XbarS) limits are based on the average of samples for the center line and sample standard deviations as its
measurement of variability within each sample and across samples.

Historically x̄s limits were not used often, because standard deviation is tedious to calculate by hand, meaning that the
most popular choice was x̄R limits. However, as sample size increases, range becomes a less accurate reflection of
variability in a sample, because it only accounts for the most extreme values and does not account for the centrality of
mass in the sample. Standard deviation does not have this problem and so x̄s is usually recommended when sample
sizes > 10. In principle nothing stops you from using x̄s for any sample size other than tradition.
$$;

create view spc_intermediates.s_limits as
  select limit_establishment_window_id
       , ((select b4 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_stddev) as upper_control_limit
       , mean_stddev   as center_line
       , ((select b3 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_stddev) as lower_control_limit
  from spc_intermediates.measurement_limit_establishment_statistics;

comment on view spc_intermediates.s_limits is $$
For each limit establishment window, this view derives the s̄ upper control limit, center line and lower control limit.
The s̄ limits are based on the standard deviations of samples.
$$;

-- p charts

create view spc_intermediates.fraction_conforming as
  select id
       , sample_id
       , performed_at
       , cast(conformant_count as decimal) / (conformant_count + non_conformant_count)     as fraction_conforming
       , cast(non_conformant_count as decimal) / (conformant_count + non_conformant_count) as fraction_non_conforming
       , conformant_count + non_conformant_count                                           as sample_size
  from spc_data.whole_unit_conformance_inspections;

comment on view spc_intermediates.fraction_conforming is $$
We take the raw data representing the counts of conforming and non-conforming items in a given sample, and convert them
into fractions (along with calculating the sample size).

It's these fractions that are the controlled values. Note that this is a quite different idea from controlling values
derived from measurements. See the comment on spc_data.whole_unit_conformance_inspections for further discussion.
$$;

create view spc_intermediates.fraction_conforming_sample_statistics as
  select fc.sample_id
       , s.period
       , s.include_in_limit_calculations
       , avg(fraction_conforming)     as mean_fraction_conforming
       , avg(fraction_non_conforming) as mean_fraction_non_conforming
       , sum(sample_size)             as sample_size
  from spc_intermediates.fraction_conforming fc
       join spc_data.samples                 s on fc.sample_id = s.id
  group by fc.sample_id, s.period, s.include_in_limit_calculations;

comment on view spc_intermediates.fraction_conforming_sample_statistics is $$
Here we convert fraction conformant/non-conformant values into means for each sample.
$$;

create view spc_intermediates.conformant_limit_establishment_statistics as
  select w.id                              as limit_establishment_window_id
       , avg(mean_fraction_conforming)     as grand_mean_conforming
       , avg(mean_fraction_non_conforming) as grand_mean_non_conforming
       , avg(sample_size)                  as mean_sample_size
  from spc_intermediates.fraction_conforming_sample_statistics fcss
       join spc_data.windows                                   w on fcss.period <@ w.period
  where w.type = 'limit_establishment'
    and fcss.include_in_limit_calculations
  group by w.id;

comment on view spc_intermediates.conformant_limit_establishment_statistics is $$
Once we have calculated statistics for each sample, the next step is to derive the center line for each of the control
charts, taking values from limit establishment windows. The center lines are simply the grand mean, the mean of means
for samples in the window.

In fraction conforming/non-conforming charts were are only interested in the fractional values. There's no equivalent to
the R or s charts used with measurement data. That is: we don't chart the variability of the samples, because every
sample has been reduced to a single number, being the fraction.
$$;

create view spc_intermediates.p_limits_conformant as
  select limit_establishment_window_id
       , grand_mean_conforming + (3 * (sqrt((grand_mean_conforming * (1.0 - grand_mean_conforming)) /
                                            mean_sample_size))) as upper_control_limit
       , grand_mean_conforming                                  as center_line
       , grand_mean_conforming - (3 * (sqrt((grand_mean_conforming * (1.0 - grand_mean_conforming)) /
                                            mean_sample_size))) as lower_control_limit
  from spc_intermediates.conformant_limit_establishment_statistics;

comment on view spc_intermediates.p_limits_conformant is $$
For each limit establishment window, this view derives the p chart upper control limit, center line and lower control
limit for fraction conforming (aka a yield chart). The limits are based on a function of the grand mean of fractions
conforming.

This chart is not very commonly used; it is more traditional to use the fraction non-conforming for control. This is
included mostly for completeness.
$$;

create view spc_intermediates.p_limits_non_conformant as
  select limit_establishment_window_id
       , grand_mean_non_conforming + (3 * (sqrt((grand_mean_non_conforming * (1.0 - grand_mean_non_conforming)) /
                                                mean_sample_size))) as upper_control_limit
       , grand_mean_non_conforming                                  as center_line
       , grand_mean_non_conforming - (3 * (sqrt((grand_mean_non_conforming * (1.0 - grand_mean_non_conforming)) /
                                                mean_sample_size))) as lower_control_limit
  from spc_intermediates.conformant_limit_establishment_statistics;

comment on view spc_intermediates.p_limits_non_conformant is $$
For each limit establishment window, this view derives the p chart upper control limit, center line and lower control
limit for fraction non-conforming (aka a fallout chart). The limits are based on a function of the grand mean of
fractions non-conforming.

When people refer to p charts, this is usually what they are thinking of.
$$;
