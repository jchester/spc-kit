-- Copyright (C) 2024 Jacques Chester. See LICENSE.

-- This schema encapsulates a variety of intermediate calculations, taking data from spc_data and exposing calculated
-- values that are used in spc_reports.
create schema if not exists spc_intermediates;

-- These are scaling factors used in calculations of control limits on a variety of charts, according to the sample size
-- used. Some of these values are derived from other values and could be calculated at view creation time, but for
-- simplicity pre-computed values are used. Other values (like c4) are derived from calculus equations that cannot be
-- performed by the database and so must be sourced from existing lookup tables.
--
-- Because this table only runs to 25 samples, that is the maximum sample size this schema can deal with. Ideally in
-- future a program may be able to generate a much larger table for cases where very large samples can be obtained (eg.
-- computer benchmarking).
--
-- Data from https://qualityamerica.com/LSS-Knowledge-Center/statisticalprocesscontrol/control_chart_constants.php and
-- Appendix VI of Montgomery.
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
-- @formatter:on

-- Shewhart chart statistics

-- The basis of statistical process control (SPC) is to batch periodic measurements into samples, and then to calculate
-- information about them at the sample level, rather than the individual level. This allows SPC techniques to
-- distinguish between variation that is due to in-sample effects versus between-sample effects.
--
-- This view calculates the four foundational sample statistics that are used in SPC calculations. These are:
--
-- * x̄, aka "X bar". The average of the measurements in the sample.
-- * s. The sample standard deviation of the measurements in the sample.
-- * R. The range of the measurements in the sample.
-- * The sample size or count of the measurements in the sample.
--
-- Note that this data is used for variable data only. For attribute data, see the views used for calculating fraction
-- conformant & non-conformant.
create view spc_intermediates.measurement_sample_statistics as
  select s.id
       , s.window_id
       , s.include_in_limit_calculations
       , avg(measured_value)                       as sample_mean
       , stddev_samp(measured_value)               as sample_stddev
       , max(measured_value) - min(measured_value) as sample_range
       , count(1)                                  as sample_size
  from spc_data.measurements m
       join spc_data.samples s on s.id = m.sample_id
       join spc_data.windows w on s.window_id = w.id
  group by s.id, w.id;

-- Once per-sample statistics have been calculated, the next step in SPC is to derive the center lines for each of the
-- control charts. These are, simply put, the averages of the sample statistics within the limit establishment window.
-- These are:
--
-- * ̿x, aka "X double bar" or "grand average/mean". The average of all sample x̄ values. Equals the average of all
--   measurements in the window if the sample sizes are equal.
-- * s̄, aka "s bar". The average of the standard deviations of the samples.
-- * R̄, aka "R bar". The average of the ranges of the samples.
-- * The average sample size or average count of measurements in the samples. This is used as a join value in subsequent
--   views to look up records in scaling_factors.
--
-- At the moment this code does not support variable sample sizes, so the average sample size should be identical to
-- every sample size in the window.
create view spc_intermediates.measurement_limit_establishment_statistics as
  select w.id               as limit_establishment_window_id
       , avg(sample_mean)   as grand_mean
       , avg(sample_stddev) as mean_stddev
       , avg(sample_range)  as mean_range
       , avg(sample_size)   as mean_sample_size
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows w                           on ss.window_id = w.id
  where w.type = 'limit_establishment'
    and ss.include_in_limit_calculations
  group by w.id;

-- For each limit establishment window, this view derives the x̄R upper control limit, center line and lower control
-- limit. The x̄R (aka XbarR) limits are based on the average of samples for the center line and sample ranges as its
-- measurement of variability within each sample and across samples.
--
-- Historically, x̄R limits have been typically used for samples where the sample size is 10 or less. Ranges were
-- preferred as the measurement of sample variability because they are easy to calculate by hand.
--
-- x̄R limits are meaningless when sample size = 1 because there is no range when the sample size is 1. In this case the
-- upper and lower control limits will be null.
create view spc_intermediates.x_bar_r_limits as
  select limit_establishment_window_id
       , grand_mean +
         ((select a2 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_range) as upper_limit
       , grand_mean   as center_line
       , grand_mean -
         ((select a2 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_range) as lower_limit
  from spc_intermediates.measurement_limit_establishment_statistics;

-- For each limit establishment window, this view derives the R̄ upper control limit, center line and lower control
-- limit. The R̄ (aka R bar) limits are based on the ranges (max - min) of samples.
--
-- ̄̄R̄ limits are meaningless when sample size = 1 because there is no range when the sample size is 1. In this case the
-- upper and lower control limits will be null.
create view spc_intermediates.r_limits as
  select limit_establishment_window_id
       , ((select upper_d4 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_range) as upper_limit
       , mean_range   as center_line
       , ((select upper_d3 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_range) as lower_limit
  from spc_intermediates.measurement_limit_establishment_statistics;

-- For each limit establishment window, this view derives the x̄s upper control limit, center line and lower control
-- limit. The x̄s (aka XbarS) limits are based on the average of samples for the center line and sample standard
-- deviations as its measurement of variability within each sample and across samples.
--
-- Historically x̄s limits were not used often, because standard deviation is tedious to calculate by hand, meaning that
-- the most popular choice was x̄R limits. However, as sample size increases, range becomes a less accurate reflection of
-- variability in a sample, because it only accounts for the most extreme values and does not account for the centrality
-- of mass in the sample. Standard deviation does not have this problem and so x̄s is usually recommended when sample
-- sizes > 10. In principle nothing stops you from using x̄s for any sample size other than tradition (except when sample
-- size = 1).
--
-- x̄s limits are meaningless when sample size = 1 because there is no deviation when the sample size is 1. In this case
-- the upper and lower control limits will be null.
create view spc_intermediates.x_bar_s_limits as
  select limit_establishment_window_id
       , grand_mean + ((select a3 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
                       mean_stddev) as upper_limit
       , grand_mean                 as center_line
       , grand_mean - ((select a3 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
                       mean_stddev) as lower_limit
  from spc_intermediates.measurement_limit_establishment_statistics;

-- For each limit establishment window, this view derives the s̄ upper control limit, center line and lower control
-- limit. The s̄ limits are based on the standard deviations of samples.
--
-- s̄ limits are meaningless when sample size = 1 because there is no deviation when the sample size is 1. In this case
-- the upper and lower control limits will be null.
create view spc_intermediates.s_limits as
  select limit_establishment_window_id
       , ((select b4 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_stddev) as upper_limit
       , mean_stddev   as center_line
       , ((select b3 from spc_intermediates.scaling_factors where sample_size = mean_sample_size) *
          mean_stddev) as lower_limit
  from spc_intermediates.measurement_limit_establishment_statistics;

-- p charts

-- We take the raw data representing the counts of conforming and non-conforming items in a given sample, and convert
-- them into fractions (along with calculating the sample size).
--
-- It's these fractions that are the controlled values. Note that this is a quite different idea from controlling values
-- derived from measurements. See the comment on spc_data.whole_unit_conformance_inspections for further discussion.
create view spc_intermediates.fraction_conforming as
  with counts as (select sample_id
                       , count(1) filter ( where conformant = true )  as conformant_count
                       , count(1) filter ( where conformant = false ) as non_conformant_count
                  from spc_data.whole_unit_conformance_inspections
                       join spc_data.samples s on s.id = whole_unit_conformance_inspections.sample_id
                  group by sample_id)

  select sample_id
       , cast(non_conformant_count as decimal) / (conformant_count + non_conformant_count) as fraction_non_conforming
       , conformant_count + non_conformant_count                                           as sample_size
  from counts;

-- Here we convert fraction conformant/non-conformant values into means for each sample.
create view spc_intermediates.fraction_conforming_sample_statistics as
  select fc.sample_id
       , s.window_id
       , s.include_in_limit_calculations
       , avg(fraction_non_conforming) as mean_fraction_non_conforming
       , sum(sample_size)             as sample_size
  from spc_intermediates.fraction_conforming fc
       join spc_data.samples                 s on fc.sample_id = s.id
  group by fc.sample_id, s.window_id, s.include_in_limit_calculations;

-- Once we have calculated statistics for each sample, the next step is to derive the center line for each of the
-- control charts, taking values from limit establishment windows. The center lines are simply the grand mean, the mean
-- of means, for samples in the window.
--
-- In fraction conforming/non-conforming charts were are only interested in the fractional values. There's no equivalent
-- to the R or s charts used with measurement data. That is: we don't chart the variability of the samples, because
-- every sample has been reduced to a single number, being the fraction.
create view spc_intermediates.conformant_limit_establishment_statistics as
  select w.id                              as limit_establishment_window_id
       , avg(mean_fraction_non_conforming) as grand_mean_non_conforming
       , avg(sample_size)                  as mean_sample_size
  from spc_intermediates.fraction_conforming_sample_statistics fcss
       join spc_data.windows w on fcss.window_id = w.id
  where w.type = 'limit_establishment'
    and fcss.include_in_limit_calculations
  group by w.id;

-- For each limit establishment window, this view derives the p chart upper control limit, center line and lower control
-- limit for fraction non-conforming (aka a fallout chart). The limits are based on a function of the grand mean of
-- fractions non-conforming.
--
-- When people refer to p charts, this is usually what they are thinking of.
create view spc_intermediates.p_limits_non_conformant as
  select limit_establishment_window_id
       , grand_mean_non_conforming + (3 * (sqrt((grand_mean_non_conforming * (1.0 - grand_mean_non_conforming)) /
                                                mean_sample_size))) as upper_limit
       , grand_mean_non_conforming                                  as center_line
       , greatest(0.0, grand_mean_non_conforming -
                       (3 * (sqrt((grand_mean_non_conforming * (1.0 - grand_mean_non_conforming)) /
                                  mean_sample_size))))              as lower_limit
  from spc_intermediates.conformant_limit_establishment_statistics;

-- np charts

-- For each limit establishment window, this view derives the np chart (number non-conforming) upper control limit,
-- center line and lower control limit. Note that the p chart and np chart can disagree whether a sample is in-control
-- or not, because the limits are calculated as decimals but samples are composed of an integer number of inspected
-- items.
--
-- When people refer to np charts, this is usually what they are thinking of.
create view spc_intermediates.np_limits_non_conformant as
  select limit_establishment_window_id
       , (grand_mean_non_conforming * mean_sample_size) +
         (3 * (sqrt((grand_mean_non_conforming * mean_sample_size)
           * (1.0 - grand_mean_non_conforming))))                       as upper_limit
       , grand_mean_non_conforming * mean_sample_size                   as center_line
       , greatest(0.0, (grand_mean_non_conforming * mean_sample_size) -
                       (3 * (sqrt((grand_mean_non_conforming * mean_sample_size) *
                                  (1.0 - grand_mean_non_conforming))))) as lower_limit
  from spc_intermediates.conformant_limit_establishment_statistics;

-- c charts

-- This view joins values for downstream processing.
create view spc_intermediates.non_conformities_sample_statistics as
  select punci.sample_id
       , s.window_id
       , s.include_in_limit_calculations
       , punci.non_conformities
  from spc_data.per_unit_non_conformities_inspections punci
       join spc_data.samples                          s on punci.sample_id = s.id;

-- Here we convert non-conformity counts from individual statistics in a limit establishment window into the mean that
-- will be used in c_limits.
create view spc_intermediates.conformities_limit_establishment_statistics as
  select w.id                  as limit_establishment_window_id
       , avg(non_conformities) as mean_non_conformities
  from spc_intermediates.non_conformities_sample_statistics css
       join spc_data.windows w on css.window_id = w.id
  where w.type = 'limit_establishment'
    and css.include_in_limit_calculations
  group by w.id;

-- Here we calculate the center line, upper control limit and lower control limit for a count of non-conformities chart
-- (aka c charts). Note that calculation is made for non-conformities only, no calculation is made for conformities.
-- This is because the assumed distribution for c charts is a Poisson distribution, which is asymmetrical.
create view spc_intermediates.c_limits as
  select limit_establishment_window_id
       , mean_non_conformities + (3 * sqrt(mean_non_conformities))                as upper_limit
       , mean_non_conformities                                                    as center_line
       , greatest(0.0, mean_non_conformities - (3 * sqrt(mean_non_conformities))) as lower_limit
  from spc_intermediates.conformities_limit_establishment_statistics;

-- XmR charts

-- This view joins measurements and moving ranges with sample and window information, intended for downstream processing
-- into chart for individual values and moving ranges (aka XmR charts). A moving range is the difference between two
-- successive measurements, achieved with the lag() window function.
--
-- This view has an important difference from its peers for things like sample statistics, or fractions and counts of
-- non-conforming / non-conformities. Because the sample size is 1, it does not make sense to perform statistical
-- summaries on a per-sample basis. Instead this view collects sample *and* window data, because single-measurement
-- samples will need to be summarized on a window-by-window basis.
create view spc_intermediates.individual_measurements_and_moving_ranges as
  select w.id                                                               as window_id
       , s.id                                                               as sample_id
       , w.type                                                             as window_type
       , m.performed_at
       , s.include_in_limit_calculations
       , measured_value
       , abs(measured_value -
             lag(measured_value, 1) over (partition by w.instrument_id order by m.id)) as moving_range
  from spc_data.measurements m
       join spc_data.samples s on s.id = m.sample_id
       join spc_data.windows w on s.window_id = w.id;

-- Converts the basic sample/window figures from individual_measurements_and_moving_ranges into summary averages for
-- each of the measurement value and the moving range.
create view spc_intermediates.individual_measurement_and_moving_range_statistics as
  select w.id           as limit_establishment_window_id
       , avg(measured_value) as mean_measured_value
       , avg(moving_range)   as mean_moving_range
  from spc_intermediates.individual_measurements_and_moving_ranges immr
       join spc_data.windows                                       w on w.id = immr.window_id
  where window_type = 'limit_establishment'
    and include_in_limit_calculations
  group by w.id;

-- Here we calculate the center line, upper natural process limit (UNPL) and lower natural process limit (LNPL). Note
-- the change in nomenclature - these are not control limits in the sense used in other Shewhart charts, because data is
-- not grouped into samples with multiple measurements. Instead the limits are calculated over entire windows of data,
-- meaning that all variation is captured in its original natural form.
create view spc_intermediates.xmr_x_limits as
  select limit_establishment_window_id
       , mean_measured_value + (3 * (mean_moving_range / (select lower_d2
                                                          from spc_intermediates.scaling_factors
                                                          where sample_size = 2))) as upper_limit
       , mean_measured_value                                                       as center_line
       , mean_measured_value - (3 * (mean_moving_range / (select lower_d2
                                                          from spc_intermediates.scaling_factors
                                                          where sample_size = 2))) as lower_limit
  from spc_intermediates.individual_measurement_and_moving_range_statistics;

-- Here we calculate the center line and upper range limit (URL) of the moving range (URL is the nomenclature from
-- Wheeler & Chambers, Montgomery calls it an upper control limit). As with xmr_x_limits, the data is calculated over a
-- whole window of data rather than grouped by samples.
--
-- There is no "lower range limit". This is because the formula for such a limit would require multiplying the mean
-- moving range by the upper_d4 constant, which is zero when sample size = 2. Hence it is always zero. This should make
-- sense, since the smallest possible value of subtracting two values is zero (when the values are equal).
create view spc_intermediates.xmr_mr_limits as
  select limit_establishment_window_id
       , mean_moving_range *
         (select upper_d4 from spc_intermediates.scaling_factors where sample_size = 2) as upper_limit
       , mean_moving_range                                                              as center_line
  from spc_intermediates.individual_measurement_and_moving_range_statistics;

-- Exponentially Weighted Moving Average (EWMA)

-- Calculating an exponentially-weighted moving average (EWMA; aka Simple Exponential Smoothing) works as a recurrence
-- relationship. It can be defined as an iterative function where each execution takes as an input the value of the
-- previous execution.
--
-- This is the function that gets called iteratively.
--
-- * `last_avg` represents the output of the previous execution. If it is nil, the `target_mean` value is substituted.
-- * `measurement` represents the value of the current measurement, used to update the EWMA.
-- * `weighting` represents the fraction by which the `last_avg` is applied with the `measurement` to create a new
--   average.
--   Put another way, it is the speed at which older values become ignored in updating the average. High values of
--   `weighting` cause older values to be ignored quickly, making the function more responsive to more recent values.
--   Low values of `weighting` cause the influence of older values to linger longer, meaning the function takes longer
--   to respond to shifts but is less sensitive to noise. In literature this parameter is called λ (typical of SPC
--   literature) or α (typical of data science / forecasting literature).
-- * `target_mean` is the declared mean of the data.
-- * `scale` sets the maximum number of numbers after the decimal point that the calculation will make.
create function spc_intermediates.ewma_step(
    last_avg           decimal
  , measurement        decimal
  , weighting          decimal
  , target_mean        decimal
  , scale              integer
) returns decimal immutable language plpgsql as
$$
begin
  if last_avg is null then
    return trunc((weighting * measurement + (1.0 - weighting) * target_mean), scale);
  else
    return trunc((weighting * measurement + (1.0 - weighting) * last_avg), scale);
  end if;
end;
$$;

-- The `ewma` aggregate is what wraps up `ewma_step` into an iterative loop. This means it can be used as an aggregate
-- in the same way as inbuilt aggregates like `sum` or `avg`.
create aggregate spc_intermediates.ewma(measurement decimal, weighting decimal, target_mean decimal, scale integer) (
  sfunc = spc_intermediates.ewma_step,
  stype = decimal
);

-- This prepares the underlying windows, samples and measurements for transformation into EWMAs and control limits. An
-- important distinction from similar views like `individual_measurements_and_moving_ranges` is the calculation of
-- `sample_number_in_window`. This value is used as an input for calculating the amount by which each particular
-- measurement is weighted (see Montgomery formulae 9.25 and 9.26, where it is the value 'i').
create view spc_intermediates.individual_measurements_ewma as
  select w.id                                                as window_id
       , s.id                                                as sample_id
       , w.instrument_id
       , m.id                                                as measurement_id
       , w.type                                              as window_type
       , row_number() over (partition by w.id order by s.id) as sample_number_in_window
       , m.performed_at
       , s.include_in_limit_calculations
       , m.measured_value
  from spc_data.measurements m
       join spc_data.samples s on s.id = m.sample_id
       join spc_data.windows w on s.window_id = w.id;

-- This view calculates the mean and standard deviation of EWMA control windows. The mean is used as a target_mean and
-- the standard deviation is an input to the calculation of EWMA control limits (see Montgomery formulae 9.25 and 9.26,
-- where it is the value 'σ').
create view spc_intermediates.individual_measurement_statistics_window as
    select w.id                        as window_id
         , avg(measured_value)         as mean_measured_value
         , stddev_samp(measured_value) as std_dev_measured_value
    from spc_data.measurements m
       join spc_data.samples s on s.id = m.sample_id
       join spc_data.windows w on s.window_id = w.id
    where include_in_limit_calculations
    group by w.id;

-- This is the core of the EWMA calculation process.
--
-- Upper limit is based on Montgomery formula 9.25, lower limit on formula 9.26.
create function spc_intermediates.ewma_individual_measurements(
    p_weighting decimal,
    p_limits_width decimal,
    p_target_mean decimal default null,
    p_target_std_dev decimal default null,
    scale integer default 8
) returns table (
  window_id                     bigint,
  sample_id                     bigint,
  measurement_id                bigint,
  instrument_id                 bigint,
  window_type                   spc_data.window_type,
  sample_number_in_window       bigint,
  performed_at                  timestamptz,
  measured_value                decimal,
  ewma                          decimal,
  upper_limit                   decimal,
  center_line                   decimal,
  lower_limit                   decimal
)
immutable language plpgsql as
$$
begin
  return query
    select wms.window_id
         , wms.sample_id
         , wms.measurement_id
         , wms.instrument_id
         , wms.window_type
         , wms.sample_number_in_window
         , wms.performed_at
         , wms.measured_value
         , spc_intermediates.ewma(wms.measured_value, p_weighting, coalesce(p_target_mean, mean_measured_value), scale)
           over (partition by wms.window_id order by wms.measurement_id)                       as ewma
         , coalesce(p_target_mean, mean_measured_value) + (p_limits_width * coalesce(p_target_std_dev, std_dev_measured_value)) *
                           sqrt(((p_weighting / (2 - p_weighting)) *
                                 (1 - (1 - p_weighting) ^ (2 * wms.sample_number_in_window)))) as upper_limit
         , coalesce(p_target_mean, mean_measured_value)                                                                       as center_line
         , coalesce(p_target_mean, mean_measured_value) - (p_limits_width * coalesce(p_target_std_dev, std_dev_measured_value)) *
                           sqrt(((p_weighting / (2 - p_weighting)) *
                                 (1 - (1 - p_weighting) ^ (2 * wms.sample_number_in_window)))) as lower_limit
    from spc_intermediates.individual_measurements_ewma wms
    join spc_intermediates.individual_measurement_statistics_window imsw on wms.window_id = imsw.window_id;
end;
$$;

-- Cumulative Sum, aka Cusum

create function spc_intermediates.cusum_c_plus_step(
      last_c_plus decimal
    , measurement decimal
    , allowance   decimal
    , target_mean decimal
) returns decimal immutable language sql as
$$
    select greatest(coalesce(last_c_plus, 0) + (measurement - target_mean - allowance), 0);
$$;

create aggregate spc_intermediates.cusum_c_plus(
      measurement decimal
    , allowance decimal
    , target_mean decimal
) (
    sfunc = spc_intermediates.cusum_c_plus_step,
    stype = decimal
);

create function spc_intermediates.cusum_c_minus_step(
      last_c_minus decimal
    , measurement  decimal
    , allowance    decimal
    , target_mean  decimal
) returns decimal immutable language sql as
$$
    select least(coalesce(last_c_minus, 0) + (measurement - target_mean + allowance), 0);
$$;

create aggregate spc_intermediates.cusum_c_minus(
      measurement decimal
    , allowance decimal
    , target_mean decimal
) (
    sfunc = spc_intermediates.cusum_c_minus_step,
    stype = decimal
);
