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
-- by control_status being set to "na". When sample size is 1, use xmr_x_rules instead.
create view spc_reports.x_bar_r_rules as
  select ss.id        as sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.instrument_id
       , ss.period
       , center_line
       , sample_mean  as controlled_value
       , lower_limit
       , upper_limit
       , case
           when upper_limit is null and lower_limit is null then 'na'
           when sample_mean > upper_limit then 'out_of_control_upper'
           when sample_mean < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end          as control_status
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.period <@ control_w.period
                                                          and ss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.x_bar_r_limits on limits_w.id = x_bar_r_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in r_limits to matching control windows, showing which sample ranges where
-- in-control and out-of-control according the the R̄ limits on R. These signals are useful up until sample size = 10;
-- after that you should switch to using s_rules instead.
--
-- ̄̄R̄ rules are meaningless when sample size = 1 because there is no range when the sample size is 1. This is indicated
-- by control_status being set to "na". When sample size is 1, use xmr_mr_rules instead.
create view spc_reports.r_rules as
  select ss.id        as sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.instrument_id
       , ss.period
       , sample_range as controlled_value
       , center_line
       , lower_limit
       , upper_limit
       , case
           when upper_limit is null and lower_limit is null then 'na'
           when sample_range > upper_limit then 'out_of_control_upper'
           when sample_range < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end          as control_status
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.period <@ control_w.period
                                                          and ss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.r_limits on limits_w.id = r_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in x_bar_s_limits to matching control windows, showing which sample ranges are
-- in-control and out-of-control according to the x̄s limits on s.
--
-- x̄s rules are meaningless when sample size = 1 because there is no deviation when the sample size is 1. This is
-- indicated by control_status being set to "na". When sample size is 1, use xmr_x_rules instead.
create view spc_reports.x_bar_s_rules as
  select ss.id        as sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.instrument_id
       , ss.period
       , center_line
       , sample_mean  as controlled_value
       , lower_limit
       , upper_limit
       , case
           when upper_limit is null and lower_limit is null then 'na'
           when sample_mean > upper_limit then 'out_of_control_upper'
           when sample_mean < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end          as control_status
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.period <@ control_w.period
                                                          and ss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.x_bar_s_limits on limits_w.id = x_bar_s_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in s_limits to matching control windows, showing which sample ranges were
-- in-control and out-of-control according the s̄ limits on s. These signals are more effective than r_rules when sample
-- size > 10.
--
-- ̄S rules are meaningless when sample size = 1 because there is no range when the sample size is 1. This is indicated
-- by control_status being set to "na". When sample size is 1, use xmr_mr_rules instead.
create view spc_reports.s_rules as
  select ss.id         as sample_id
       , control_w.id  as control_window_id
       , limits_w.id   as limit_establishment_window_id
       , ss.instrument_id
       , ss.period
       , center_line
       , sample_stddev as controlled_value
       , lower_limit
       , upper_limit
       , case
           when upper_limit is null and lower_limit is null then 'na'
           when sample_stddev > upper_limit then 'out_of_control_upper'
           when sample_stddev < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end           as control_status
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.period <@ control_w.period
                                                          and ss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.s_limits on limits_w.id = s_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in p_limits_conformant to matching control windows, showing which sample
-- fractions conforming were in-control and out-of-control according to the limits on the fraction conforming.
--
-- This is a non-traditional application, the typical approach is to set rules on fraction non-conforming. This is
-- included for completeness.
create view spc_reports.p_conformant_rules as
  select ss.sample_id
       , control_w.id             as control_window_id
       , limits_w.id              as limit_establishment_window_id
       , ss.instrument_id
       , ss.period
       , center_line
       , mean_fraction_conforming as controlled_value
       , lower_limit
       , upper_limit
       , case
           when mean_fraction_conforming > upper_limit then 'out_of_control_upper'
           when mean_fraction_conforming < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end                      as control_status
  from spc_intermediates.fraction_conforming_sample_statistics ss
       join spc_data.windows                                   control_w on ss.period <@ control_w.period
                                                                  and ss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships                      wr on control_w.id = wr.control_window_id
       join spc_data.windows                                   limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.p_limits_conformant on limits_w.id = p_limits_conformant.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in p_limits_non_conformant to matching control windows, showing which sample
-- fractions non-conforming were in-control and out-of-control according to the limits on the fraction non-conforming.
create view spc_reports.p_non_conformant_rules as
  select ss.sample_id
       , control_w.id                 as control_window_id
       , limits_w.id                  as limit_establishment_window_id
       , ss.instrument_id
       , ss.period
       , center_line
       , mean_fraction_non_conforming as controlled_value
       , lower_limit
       , upper_limit
       , case
           when mean_fraction_non_conforming > upper_limit then 'out_of_control_upper'
           when mean_fraction_non_conforming < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end                          as control_status
  from spc_intermediates.fraction_conforming_sample_statistics ss
       join spc_data.windows                                   control_w on ss.period <@ control_w.period
                                                                  and ss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships                      wr on control_w.id = wr.control_window_id
       join spc_data.windows                                   limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.p_limits_non_conformant
            on limits_w.id = p_limits_non_conformant.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in np_limits_conformant to matching control windows, showing which sample counts
-- conforming were in-control and out-of-control according to the limits on the count conforming.
--
-- This is a non-traditional application, the typical approach is to set rules on fraction non-conforming. This is
-- included for completeness.
create view spc_reports.np_conformant_rules as
  select ss.sample_id
       , control_w.id                           as control_window_id
       , limits_w.id                            as limit_establishment_window_id
       , ss.instrument_id
       , ss.period
       , center_line
       , mean_fraction_conforming * sample_size as controlled_value
       , lower_limit
       , upper_limit
       , case
           when (mean_fraction_conforming * sample_size) > upper_limit then 'out_of_control_upper'
           when (mean_fraction_conforming * sample_size) < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end                                    as control_status
  from spc_intermediates.fraction_conforming_sample_statistics ss
       join spc_data.windows                                   control_w on ss.period <@ control_w.period
                                                                  and ss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships                      wr on control_w.id = wr.control_window_id
       join spc_data.windows                                   limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.np_limits_conformant on limits_w.id = np_limits_conformant.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in np_limits_non_conformant to matching control windows, showing which sample
-- counts non-conforming were in-control and out-of-control according to the limits on the counts non-conforming.
create view spc_reports.np_non_conformant_rules as
  select ss.sample_id
       , control_w.id                               as control_window_id
       , limits_w.id                                as limit_establishment_window_id
       , ss.instrument_id
       , ss.period
       , center_line
       , mean_fraction_non_conforming * sample_size as controlled_value
       , lower_limit
       , upper_limit
       , case
           when (mean_fraction_non_conforming * sample_size) > upper_limit then 'out_of_control_upper'
           when (mean_fraction_non_conforming * sample_size) < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end                                        as control_status
  from spc_intermediates.fraction_conforming_sample_statistics ss
       join spc_data.windows                                   control_w on ss.period <@ control_w.period
                                                                  and ss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships                      wr on control_w.id = wr.control_window_id
       join spc_data.windows                                   limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.np_limits_non_conformant
            on limits_w.id = np_limits_non_conformant.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in c_limits to the matching control windows, showing which sample non-conformity
-- counts were in-control and out-of-control according to the limits.
create view spc_reports.c_rules as
  select ncss.sample_id
       , control_w.id     as control_window_id
       , limits_w.id      as limit_establishment_window_id
       , ncss.instrument_id
       , ncss.period
       , center_line
       , non_conformities as controlled_value
       , lower_limit
       , upper_limit
       , case
           when (non_conformities) > upper_limit then 'out_of_control_upper'
           when (non_conformities) < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end              as control_status
  from spc_intermediates.non_conformities_sample_statistics ncss
       join spc_data.windows                                control_w on ncss.period <@ control_w.period
                                                                and ncss.instrument_id = control_w.instrument_id
       join spc_data.window_relationships                   wr on control_w.id = wr.control_window_id
       join spc_data.windows                                limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.c_limits on limits_w.id = c_limits.limit_establishment_window_id
  where ncss.include_in_limit_calculations;

-- This view applies the limits derived in xmr_x_limits to the matching control windows, showing which individual
-- measurements were in-control and out-of-control according to the natural process limits.
--
-- This rule is more sensitive to shifts in the mean than an ordinary Shewhart chart that groups together measurements
-- into samples, but on the other hand it is more vulnerable to departures from normality in the data. Montgomery
-- recommends Cusum and EWMA charts over the chart for individual values.
create view spc_reports.xmr_x_rules as
  select immr.sample_id
       , control_w.id   as control_window_id
       , limits_w.id    as limit_establishment_window_id
       , immr.instrument_id
       , immr.period
       , immr.performed_at
       , center_line
       , measured_value as controlled_value
       , lower_limit
       , upper_limit
       , case
           when measured_value > upper_limit then 'out_of_control_upper'
           when measured_value < lower_limit then 'out_of_control_lower'
           else 'in_control'
         end            as control_status
  from spc_intermediates.individual_measurements_and_moving_ranges immr
       join spc_data.windows                                       control_w on immr.period <@ control_w.period
                                                                      and immr.instrument_id = control_w.instrument_id
       join spc_data.window_relationships                          wr on control_w.id = wr.control_window_id
       join spc_data.windows                                       limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.xmr_x_limits on limits_w.id = xmr_x_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- This view applies the limits derived in xmr_mr_limits to the matching control windows, showing which moving ranges
-- were in-control and out-of-control according to the upper range limit.
--
-- As with the individual value rule in xmr_x_rules, this rule is more sensitive to shifts in moving range but also more
-- vulnerable to departures from normality in the data.
create view spc_reports.xmr_mr_rules as
  select immr.sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , immr.instrument_id
       , immr.period
       , immr.performed_at
       , center_line
       , moving_range as controlled_value
       , upper_limit
       , case
           when moving_range > upper_limit then 'out_of_control_upper'
           else 'in_control'
         end          as control_status
  from spc_intermediates.individual_measurements_and_moving_ranges immr
       join spc_data.windows                                       control_w on immr.period <@ control_w.period
                                                                        and immr.instrument_id = control_w.instrument_id
       join spc_data.window_relationships                          wr on control_w.id = wr.control_window_id
       join spc_data.windows                                       limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.xmr_mr_limits on limits_w.id = xmr_mr_limits.limit_establishment_window_id
  where include_in_limit_calculations;

-- For each measurement and EWMA value, this rule applies the per-measurement limits to determine if a EWMA value is
-- in-control or out-of-control. Note that unlike conventional Shewhart charts, the limits for each measurement vary
-- according to the value of the measurement and values of previous measurements, represented by the EWMA.
--
-- Because limits are per-measurement, there is no meaningful distinction between limit establishment and control
-- windows in EWMA. Just use control windows.
create view spc_reports.ewma_rules as
  select eim.sample_id
       , window_id
       , eim.instrument_id
       , eim.period
       , eim.performed_at
       , center_line
       , ewma as controlled_value
       , lower_limit
       , upper_limit
       , case
             when ewma > upper_limit then 'out_of_control_upper'
             when ewma < lower_limit then 'out_of_control_lower'
             else 'in_control'
         end  as control_status
  from  spc_intermediates.ewma_individual_measurements(0.1) eim;
