-- Copyright (C) 2024 Jacques Chester. See LICENSE.

-- This is where you read out the control status of individual samples, based on the application of various rules.
-- Control status can be one of four conditions:
--
-- * in_control. There is nothing to do, the process is operating with common cause variability.
-- * out_of_control_upper. The process sample has exceeded the upper control limit for the process. Investigation is
--   necessary to establish why the upper control limit has been exceeded.
-- * out_of_control_lower. As with out_of_control_upper, except that the lower control limit has been breached.
-- * na. There is no meaningful limit to apply (sample size = 1).
--
-- When using an ORM, you will typically join these views to the base tables in spc_data in order to attach control
-- status about samples to the sample object.
create schema if not exists spc_reports;

-- Shewhart charts

-- This view applies the limits derived in x_bar_r_limits to matching control windows, showing which sample averages
-- were in-control and out-of-control according to the x̄R limits on x̄.
--
-- x̄R rules are meaningless when sample size = 1 because there is no range when the sample size is 1. This is indicated
-- by rule_valid_sample_size being set to 'false'. When sample size is 1, use xmr_x_rules instead. If you get a null in
-- any rule, it is because your sample size = 1. This case is a bug: it indicates that you should not be using this view
-- with that sample.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the grand mean of all samples.
-- * `data_controlled_value`. The value under control. In this case it is the sample mean.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row. Null when sample size = 1.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Is
--   identical for every row. Null when sample size = 1.
-- * `rule_valid_sample_size`. False if the sample size is 1, true otherwise. If you don't know in advance whether all
--   your samples will have sample size > 1, ensure that this is true before relying on the values of the other rules in
--   this view.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise. Null when sample
--   size = 1.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit. Null when sample
--   size = 1.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit. Null when sample
--   size = 1.
create view spc_reports.x_bar_r_rules as
  select ss.id                                                      as id_sample
       , control_w.id                                               as id_control_window
       , limits_w.id                                                as id_limit_establishment_window
       , i.id                                                       as id_instrument
       , center_line                                                as data_center_line
       , sample_mean                                                as data_controlled_value
       , upper_limit                                                as data_upper_limit
       , lower_limit                                                as data_lower_limit
       , upper_limit is not null and lower_limit is not null        as rule_valid_sample_size
       , sample_mean < upper_limit and sample_mean > lower_limit    as rule_in_control
       , sample_mean > upper_limit                                  as rule_out_of_control_upper
       , sample_mean < lower_limit                                  as rule_out_of_control_lower
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.window_id = control_w.id
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                       i on control_w.instrument_id = i.id
       join spc_intermediates.x_bar_r_limits on limits_w.id = x_bar_r_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in r_limits to matching control windows, showing which sample ranges where
-- in-control and out-of-control according the R̄ limits on R. These signals are useful up until sample size = 10;
-- after that you should switch to using s_rules instead.
--
-- R̄̄ rules are meaningless when sample size = 1 because there is no range when the sample size is 1. This is indicated
-- by rule_valid_sample_size being set to 'false'. When sample size is 1, use xmr_mr_rules instead. If you get a null in
-- any rule, it is because your sample size = 1. This case is a bug: it indicates that you should not be using this view
-- with that sample.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the mean range of all samples.
-- * `data_controlled_value`. The value under control. In this case it is the sample range.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row. Null when sample size = 1.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Is
--   identical for every row. Null when sample size = 1.
-- * `rule_valid_sample_size`. False if the sample size is 1, true otherwise. If you don't know in advance whether all
--   your samples will have sample size > 1, ensure that this is true before relying on the values of the other rules in
--   this view.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise. Null when sample
--   size = 1.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit. Null when sample
--   size = 1.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit. Null when sample
--   size = 1.
create view spc_reports.r_rules as
  select ss.id                                                      as id_sample
       , control_w.id                                               as id_control_window
       , limits_w.id                                                as id_limit_establishment_window
       , i.id                                                       as id_instrument
       , sample_range                                               as data_controlled_value
       , center_line                                                as data_center_line
       , upper_limit                                                as data_upper_limit
       , lower_limit                                                as data_lower_limit
       , upper_limit is not null and lower_limit is not null        as rule_valid_sample_size
       , sample_range < upper_limit and sample_range > lower_limit  as rule_in_control
       , sample_range > upper_limit                                 as rule_out_of_control_upper
       , sample_range < lower_limit                                 as rule_out_of_control_lower
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.window_id = control_w.id
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                       i on control_w.instrument_id = i.id
       join spc_intermediates.r_limits on limits_w.id = r_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in x_bar_s_limits to matching control windows, showing which sample ranges are
-- in-control and out-of-control according to the x̄s limits on s.
--
-- x̄s rules are meaningless when sample size = 1 because there is no deviation when the sample size is 1. This is
-- indicated by rule_valid_sample_size being set to 'false'. When sample size is 1, use xmr_x_rules instead. If you get
-- a null in any rule, it is because your sample size = 1. This case is a bug: it indicates that you should not be using
-- this view with that sample.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the grand mean of all samples.
-- * `data_controlled_value`. The value under control. In this case it is the sample mean.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row. Null when sample size = 1.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Is
--   identical for every row. Null when sample size = 1.
-- * `rule_valid_sample_size`. False if the sample size is 1, true otherwise. If you don't know in advance whether all
--   your samples will have sample size > 1, ensure that this is true before relying on the values of the other rules in
--   this view.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise. Null when sample
--   size = 1.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit. Null when sample
--   size = 1.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit. Null when sample
--   size = 1.
create view spc_reports.x_bar_s_rules as
  select ss.id                                                      as id_sample
       , control_w.id                                               as id_control_window
       , limits_w.id                                                as id_limit_establishment_window
       , i.id                                                       as id_instrument
       , sample_mean                                                as data_controlled_value
       , center_line                                                as data_center_line
       , upper_limit                                                as data_upper_limit
       , lower_limit                                                as data_lower_limit
       , upper_limit is not null and lower_limit is not null        as rule_valid_sample_size
       , sample_mean < upper_limit and sample_mean > lower_limit    as rule_in_control
       , sample_mean > upper_limit                                  as rule_out_of_control_upper
       , sample_mean < lower_limit                                  as rule_out_of_control_lower
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.window_id = control_w.id
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                       i on control_w.instrument_id = i.id
       join spc_intermediates.x_bar_s_limits on limits_w.id = x_bar_s_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in s_limits to matching control windows, showing which sample ranges were
-- in-control and out-of-control according the s̄ limits on s. These signals are more effective than r_rules when sample
-- size > 10.
--
-- S̄ rules are meaningless when sample size = 1 because there is no range when the sample size is 1. This is
-- indicated by rule_valid_sample_size being set to 'false'. When sample size is 1, use xmr_mr_rules instead. If you get
-- a null in any rule, it is because your sample size = 1. This case is a bug: it indicates that you should not be using
-- this view with that sample.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the mean of all sample standard
--   deviations.
-- * `data_controlled_value`. The value under control. In this case it is the sample standard deviation.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row. Null when sample size = 1.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Is
--   identical for every row. Null when sample size = 1.
-- * `rule_valid_sample_size`. False if the sample size is 1, true otherwise. If you don't know in advance whether all
--   your samples will have sample size > 1, ensure that this is true before relying on the values of the other rules in
--   this view.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise. Null when sample
--   size = 1.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit. Null when sample
--   size = 1.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit. Null when sample
--   size = 1.
create view spc_reports.s_rules as
  select ss.id                                                          as id_sample
       , control_w.id                                                   as id_control_window
       , limits_w.id                                                    as id_limit_establishment_window
       , i.id                                                           as id_instrument
       , center_line                                                    as data_center_line
       , sample_stddev                                                  as data_controlled_value
       , upper_limit                                                    as data_upper_limit
       , lower_limit                                                    as data_lower_limit
       , upper_limit is not null and lower_limit is not null            as rule_valid_sample_size
       , sample_stddev < upper_limit and sample_stddev > lower_limit    as rule_in_control
       , sample_stddev > upper_limit                                    as rule_out_of_control_upper
       , sample_stddev < lower_limit                                    as rule_out_of_control_lower
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.window_id = control_w.id
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                       i on control_w.instrument_id = i.id
       join spc_intermediates.s_limits on limits_w.id = s_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in p_limits_non_conformant to matching control windows, showing which sample
-- fractions non-conforming were in-control and out-of-control according to the limits on the fraction non-conforming.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the grand mean of all fractions
--   non-conforming in the limit establishment window.
-- * `data_controlled_value`. The value under control. In this case it is the mean fraction non-conforming in the
--   control window.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit.
create view spc_reports.p_non_conformant_rules as
  select ss.sample_id                                                                   as id_sample
       , control_w.id                                                                   as id_control_window
       , limits_w.id                                                                    as id_limit_establishment_window
       , i.id                                                                           as id_instrument
       , center_line                                                                    as data_center_line
       , mean_fraction_non_conforming                                                   as data_controlled_value
       , upper_limit                                                                    as data_upper_limit
       , lower_limit                                                                    as data_lower_limit
       , mean_fraction_non_conforming < upper_limit and mean_fraction_non_conforming > lower_limit as rule_in_control
       , mean_fraction_non_conforming > upper_limit                                     as rule_out_of_control_upper
       , mean_fraction_non_conforming < lower_limit                                     as rule_out_of_control_lower
  from spc_intermediates.fraction_conforming_sample_statistics ss
       join spc_data.windows                                   control_w on ss.window_id = control_w.id
       join spc_data.window_relationships                      wr on control_w.id = wr.control_window_id
       join spc_data.windows                                   limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                               i on control_w.instrument_id = i.id
       join spc_intermediates.p_limits_non_conformant
            on limits_w.id = p_limits_non_conformant.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in np_limits_non_conformant to matching control windows, showing which sample
-- counts non-conforming were in-control and out-of-control according to the limits on the counts non-conforming.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the grand mean of all fractions
--   non-conforming in the limit establishment window multiplied by the mean sample size.
-- * `data_controlled_value`. The value under control. In this case it is the mean fraction non-conforming in the
--   control window multiplied by the mean sample size.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit.
create view spc_reports.np_non_conformant_rules as
  select ss.sample_id                                                           as id_sample
       , control_w.id                                                           as id_control_window
       , limits_w.id                                                            as id_limit_establishment_window
       , i.id                                                                   as id_instrument
       , center_line                                                            as data_center_line
       , mean_fraction_non_conforming * sample_size                             as data_controlled_value
       , upper_limit                                                            as data_upper_limit
       , lower_limit                                                            as data_lower_limit
       , (mean_fraction_non_conforming * sample_size) < upper_limit
             and (mean_fraction_non_conforming * sample_size) > lower_limit     as rule_in_control
       , (mean_fraction_non_conforming * sample_size) > upper_limit             as rule_out_of_control_upper
       , (mean_fraction_non_conforming * sample_size) < lower_limit             as rule_out_of_control_lower
  from spc_intermediates.fraction_conforming_sample_statistics ss
       join spc_data.windows                                   control_w on ss.window_id = control_w.id
       join spc_data.window_relationships                      wr on control_w.id = wr.control_window_id
       join spc_data.windows                                   limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                               i on control_w.instrument_id = i.id
       join spc_intermediates.np_limits_non_conformant
            on limits_w.id = np_limits_non_conformant.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in c_limits to the matching control windows, showing which sample non-conformity
-- counts were in-control and out-of-control according to the limits.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the mean of non-conformities in the
--   limit establishment window.
-- * `data_controlled_value`. The value under control. In this case it is the count of non-conformities in the sample.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit.
create view spc_reports.c_rules as
  select ncss.sample_id                                                         as id_sample
       , control_w.id                                                           as id_control_window
       , limits_w.id                                                            as id_limit_establishment_window
       , i.id                                                                   as id_instrument
       , center_line                                                            as data_center_line
       , non_conformities                                                       as data_controlled_value
       , upper_limit                                                            as data_upper_limit
       , lower_limit                                                            as data_lower_limit
       , non_conformities < upper_limit and non_conformities > lower_limit      as rule_in_control
       , non_conformities > upper_limit                                         as rule_out_of_control_upper
       , non_conformities < lower_limit                                         as rule_out_of_control_lower
  from spc_intermediates.non_conformities_sample_statistics ncss
       join spc_data.windows                                control_w on ncss.window_id = control_w.id
       join spc_data.window_relationships                   wr on control_w.id = wr.control_window_id
       join spc_data.windows                                limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                            i on control_w.instrument_id = i.id
       join spc_intermediates.c_limits on limits_w.id = c_limits.limit_establishment_window_id
  where ncss.include_in_limit_calculations;

-- This view applies the limits derived in xmr_x_limits to the matching control windows, showing which individual
-- measurements were in-control and out-of-control according to the natural process limits.
--
-- This rule is more sensitive to shifts in the mean than an ordinary Shewhart chart that groups together measurements
-- into samples, but on the other hand it is more vulnerable to departures from normality in the data. Montgomery
-- recommends Cusum and EWMA charts over the chart for individual values.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the mean of measurement values in the
--   limit establishment window.
-- * `data_controlled_value`. The value under control. In this case it is the measured value.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit.
create view spc_reports.xmr_x_rules as
  select immr.sample_id                                                 as id_sample
       , control_w.id                                                   as id_control_window
       , limits_w.id                                                    as id_limit_establishment_window
       , i.id                                                           as id_instrument
       , immr.performed_at                                              as data_performed_at
       , center_line                                                    as data_center_line
       , measured_value                                                 as data_controlled_value
       , upper_limit                                                    as data_upper_limit
       , lower_limit                                                    as data_lower_limit
       , measured_value < upper_limit and measured_value > lower_limit  as rule_in_control
       , measured_value > upper_limit                                   as rule_out_of_control_upper
       , measured_value < lower_limit                                   as rule_out_of_control_lower
  from spc_intermediates.individual_measurements_and_moving_ranges immr
       join spc_data.windows                                       control_w on immr.window_id = control_w.id
       join spc_data.window_relationships                          wr on control_w.id = wr.control_window_id
       join spc_data.windows                                       limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                                   i on control_w.instrument_id = i.id
       join spc_intermediates.xmr_x_limits on limits_w.id = xmr_x_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in xmr_mr_limits to the matching control windows, showing which moving ranges
-- were in-control and out-of-control according to the upper range limit.
--
-- As with the individual value rule in xmr_x_rules, this rule is more sensitive to shifts in moving range but also more
-- vulnerable to departures from normality in the data.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_control_window`. The control window ID. You will typically use this in a where clause.
-- * `id_limit_establishment_window`. The ID of the limit establishment window associated with the control window.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_center_line`. The center line of the Shewhart chart. In this case it is the mean of moving ranges in the
--   limit establishment window.
-- * `data_controlled_value`. The value under control. In this case it is the moving range between this sample and the
--   previous sample. For the first sample this value is null because there is no previous value to compare to. It is
--   not a bug to receive a null value in this field.
-- * `data_upper_limit`. The upper control limit for the control window, based on the limit establishment window. Is
--   identical for every row.
-- * `data_lower_limit`. The lower control limit for the control window, based on the limit establishment window. Always
--   zero, because it is impossible to have a negative moving range.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise. Null if
--   data_controlled_value is null.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit. Null if
--   data_controlled_value is null.
-- * `rule_out_of_control_lower`. Always false because no moving range can drop below zero.
create view spc_reports.xmr_mr_rules as
  select immr.sample_id                                     as id_sample
       , control_w.id                                       as id_control_window
       , limits_w.id                                        as id_limit_establishment_window
       , i.id                                               as id_instrument
       , immr.performed_at                                  as data_performed_at
       , center_line                                        as data_center_line
       , moving_range                                       as data_controlled_value
       , upper_limit                                        as data_upper_limit
       , 0                                                  as data_lower_limit
       , moving_range < upper_limit and moving_range > 0    as rule_in_control
       , moving_range > upper_limit                         as rule_out_of_control_upper
       , false                                              as rule_out_of_control_lower
  from spc_intermediates.individual_measurements_and_moving_ranges immr
       join spc_data.windows                                       control_w on immr.window_id = control_w.id
       join spc_data.window_relationships                          wr on control_w.id = wr.control_window_id
       join spc_data.windows                                       limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_data.instruments                                   i on control_w.instrument_id = i.id
       join spc_intermediates.xmr_mr_limits on limits_w.id = xmr_mr_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- For each measurement and EWMA value, this rule applies the per-measurement limits to determine if a EWMA value is
-- in-control or out-of-control. Note that unlike conventional Shewhart charts, the limits for each measurement vary
-- according to the value of the measurement and values of previous measurements, represented by the EWMA.
--
-- Because limits are per-measurement, there is no meaningful distinction between limit establishment and control
-- windows in EWMA. Just use control windows.
--
-- The rule is parameterized because EWMA is configurable (unlike the fixed values used in Shewhart rules).
--
-- The parameters are:
--
-- * `p_weighting` represents how rapidly older values are weighted into insignificance. High values cause faster decay,
--   meaning that the EWMA is more reactive to new values. Low values retain older values longer, reducing sensitivity
--   to noise. In literature this parameter is called λ (typical of SPC literature) or α (typical of data science /
--   forecasting literature). Acceptable values are 0.0 to 1.0. According to Montgomery (§9.2.2) typical values chosen
--   for λ are between 0.05 and 0.25.
-- * `p_limits_width` represents the limit widths. In other Shewhart charts this is typically set to 3 and that is the
--   default for this function. EWMA limits are adjustable to allow for sensitivity to small shifts to be configured.
--   Montgomery says that as λ becomes smaller, limits should also become smaller.
-- * `p_target_mean` represents a fixed, predefined target value, which will be input into the first iteration of the
--   EWMA calculation. If not provided this value will be derived from the mean value of the limit establishment window.
-- * `p_target_std_dev` represents a fixed, predefined target value for standard deviation. If not provided this value
--   will be derived from the standard deviation of the limit establishment window.
--
-- The fields are:
--
-- * `id_sample`. The sample ID.
-- * `id_window`. The window ID. You will typically use this in a where clause.
-- * `id_instrument`. The instrument ID. Use this carefully as calculations can be incorrect if there are more than one
--    control window per instrument.
-- * `data_window_type`. Whether the window is limit establishment or control. In general, you should not use or rely on
--   this value, because in a EWMA setting there is no limit establishment concept.
-- * `data_center_line`. The center line of the Shewhart chart. If p_target_mean is provided, this field will have that
--   value. Otherwise it will be the mean of all values in the window.
-- * `data_controlled_value`. The value under control. In this case it is the measured value for the sample.
-- * `data_exponentially_weighted_moving_average`. The EWMA of values up to this sample.
-- * `data_upper_limit`. The upper control limit for the control window, based on the EWMA. The value varies sample to
--   sample.
-- * `data_lower_limit`. The lower control limit for the control window, based on the EWMA. The value varies sample to
--   sample.
-- * `rule_in_control`. True if the controlled value is within control limits, false otherwise.
-- * `rule_out_of_control_upper`. True if the controlled value is above the upper control limit.
-- * `rule_out_of_control_lower`. True if the controlled value is below the lower control limit.
create function spc_reports.ewma_rules(
    p_weighting decimal,
    p_limits_width decimal default 3.0,
    p_target_mean decimal default null,
    p_target_std_dev decimal default null
) returns table (
    id_sample                                       bigint,
    id_window                                       bigint,
    id_instrument                                   bigint,
    data_window_type                                spc_data.window_type,
    data_performed_at                               timestamptz,
    data_center_line                                decimal,
    data_controlled_value                           decimal,
    data_exponentially_weighted_moving_average      decimal,
    data_upper_limit                                decimal,
    data_lower_limit                                decimal,
    rule_in_control                                 boolean,
    rule_out_of_control_upper                       boolean,
    rule_out_of_control_lower                       boolean
) language sql as
$$
  select eim.sample_id      as id_sample
       , window_id          as id_window
       , eim.instrument_id  as id_instrument
       , eim.window_type    as data_window_type
       , eim.performed_at   as data_performed_as
       , center_line        as data_center_line
       , measured_value     as data_controlled_value
       , ewma               as data_exponentially_weighted_moving_average
       , upper_limit        as data_upper_limit
       , lower_limit        as data_lower_limit
       , ewma < upper_limit and ewma > lower_limit as rule_in_control
       , ewma > upper_limit as rule_out_of_control_upper
       , ewma < lower_limit as rule_out_of_control_lower
  from  spc_intermediates.ewma_individual_measurements(
                p_weighting,
                p_limits_width,
                p_target_mean,
                p_target_std_dev
        ) eim;
$$;

-- Cumulative Sum aka Cusum

-- cusum_rules() provides the entrypoint for Cusum calculations of net (Cₙ), positive (C⁺) and negative (C⁻) deviations
-- from a mean. This is the asymmetric function that implements the bulk of the logic for Cusum reports. "Asymmetry"
-- here simply means that you can choose different values for upper and lower allowances or decision intervals.
--
--  Parameters:
--
-- * `p_upper_allowance` is the "allowance" for C⁺, known also in literature as K. The allowance should be set to a
--    value which represents half of the difference from the mean that is acceptable or normal. So for example, if you
--    want to detect shifts of 10 units, set `p_upper_allowance` to 5.
-- * `p_upper_decision_interval` is the "decision interval" for C⁺, known also in literature as H. The decision interval
--    represents the limits of deviation at which C⁺ is considered to have grown large enough that it's considered to be
--    out-of-control. The units are standard deviations, not the underlying measurement units. Typically set to 4 or 5,
--    depending on sensitivity requirements. See Montgomery §9.1.3 for a discussion of selecting K and H based on the
--    desired Average Run Length (how long, on average, between false alarms).
-- * `p_lower_allowance`. Same as `p_upper_allowance`, but for C⁻.
-- * `p_lower_decision_interval`. Same as `p_upper_decision_interval`, but for C⁻.
-- * `p_target_mean` represents a fixed, known value for the mean of the process. If not provided this will be derived
--    from the limit establishment window.
--
-- Note that the function will not focus its calculations on a particular window, instrument etc unless you include a
-- `where window_id = 999` or similar in your query. Leaving off such a where clause will cause the calculation to run
-- over all samples from all windows, instruments etc. Slow and basically useless.
--
--  The fields are:
--
-- * `id_sample`, `id_window` and `id_instrument`. For filtering by these values. It is recommended to use
--   `where id_window = <some ID>` when using this function.
-- * `data_measured_value`. As the name suggests.
-- * `data_deviation`. The net amount by which the measured value differs from the mean.
-- * `data_deviation_plus`. The amount by which the measured value differs from the mean + the upper allowance.
-- * `data_deviation_minus`. The amount by which the measured value differs from the mean - the lower allowance.
-- * `data_C_n`. The calculated Cₙ value for this measurement.
-- * `data_C_plus`. The calculated C⁺ for this measurement.
-- * `data_C_minus`. The calculated C⁻ for this measurement.
-- * `rule_breached_upper_decision_interval`. Signals whether C⁺ has gone above the upper decision interval.
-- * `rule_breached_lower_decision_interval`. Signals whether C⁻ has gone below the lower decision interval.
create function spc_reports.cusum_rules(
      p_upper_allowance         decimal
    , p_upper_decision_interval decimal
    , p_lower_allowance         decimal
    , p_lower_decision_interval decimal
    , p_target_mean             decimal default null
)
returns table (
    id_measurement                          bigint,
    id_sample                               bigint,
    id_window                               bigint,
    id_instrument                           bigint,
    data_measured_value                     decimal,
    data_deviation                          decimal,
    data_deviation_plus                     decimal,
    data_deviation_minus                    decimal,
    data_C_n                                decimal,
    data_C_plus                             decimal,
    data_C_minus                            decimal,
    rule_breached_upper_decision_interval   boolean,
    rule_breached_lower_decision_interval   boolean
)
immutable language sql as
$$
      select m.id           as id_measurement
    , m.sample_id           as id_sample
    , w.id                  as id_window
    , w.instrument_id       as id_instrument
    , m.measured_value      as data_measured_value
    , m.measured_value - coalesce(p_target_mean, mean_measured_value)               as data_deviation
    , m.measured_value - coalesce(p_target_mean, mean_measured_value) - p_upper_allowance as data_deviation_plus
    , m.measured_value - coalesce(p_target_mean, mean_measured_value) + p_lower_allowance as data_deviation_minus
    , sum(m.measured_value - coalesce(p_target_mean, mean_measured_value))
        over (partition by w.id order by m.id)                                      as data_C_n
    , spc_intermediates.cusum_c_plus(m.measured_value, p_upper_allowance, coalesce(p_target_mean, mean_measured_value))
        over window_sample                                                          as data_C_plus
    , spc_intermediates.cusum_c_minus(m.measured_value, p_lower_allowance, coalesce(p_target_mean, mean_measured_value))
        over window_sample                                                          as data_C_minus
    , spc_intermediates.cusum_c_plus(m.measured_value, p_upper_allowance, coalesce(p_target_mean, mean_measured_value))
        over window_sample > p_upper_decision_interval                              as rule_breached_upper_decision_interval
    , spc_intermediates.cusum_c_minus(m.measured_value, p_lower_allowance, coalesce(p_target_mean, mean_measured_value))
        over window_sample < p_lower_decision_interval                              as rule_breached_lower_decision_interval
from spc_data.measurements m
         join spc_data.samples s on s.id = m.sample_id
         join spc_data.windows w on s.window_id = w.id
         join spc_data.instruments i on i.id = w.instrument_id
         join spc_intermediates.individual_measurement_statistics_window imsw on w.id = imsw.window_id
window window_sample as (partition by w.id order by m.sample_id);
$$;

-- This is the symmetric form of cusum_rules(), provided for convenience. That is, it only takes a single value for
-- allowance and decision interval and applies these for both upper and lower calculations. It delegates to the fully
-- asymmetric version of cusum_rules(); see that function for a discussion of parameters and returned fields.
create function spc_reports.cusum_rules(
      p_allowance           decimal
    , p_decision_interval   decimal
    , p_target_mean         decimal default null
)
returns table (
    id_measurement                          bigint,
    id_sample                               bigint,
    id_window                               bigint,
    id_instrument                           bigint,
    data_measured_value                     decimal,
    data_deviation                          decimal,
    data_deviation_plus                     decimal,
    data_deviation_minus                    decimal,
    data_C_n                                decimal,
    data_C_plus                             decimal,
    data_C_minus                            decimal,
    rule_breached_upper_decision_interval   boolean,
    rule_breached_lower_decision_interval   boolean
)
immutable language sql as
$$
select *
from spc_reports.cusum_rules(
        p_allowance
    , p_decision_interval
    , p_allowance
    , p_decision_interval
    , p_target_mean
     );
$$;