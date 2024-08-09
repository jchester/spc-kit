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
       , 0 as lower_limit -- this is always the case
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
--
-- The rule is parameterized because EWMA is configurable (unlike the fixed values used in Shewhart rules).
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
create function spc_reports.ewma_rules(
    p_weighting decimal,
    p_limits_width decimal default 3.0,
    p_target_mean decimal default null,
    p_target_std_dev decimal default null
) returns table (
    sample_id bigint,
    window_id bigint,
    instrument_id bigint,
    period tstzrange,
    performed_at timestamptz,
    center_line decimal,
    controlled_value decimal,
    exponentially_weighted_moving_average decimal,
    lower_limit decimal,
    upper_limit decimal,
    control_status text
) language sql as
$$
  select eim.sample_id
       , window_id
       , eim.instrument_id
       , eim.period
       , eim.performed_at
       , center_line
       , measured_value as controlled_value
       , ewma as exponentially_weighted_moving_average
       , lower_limit
       , upper_limit
       , case
             when ewma > upper_limit then 'out_of_control_upper'
             when ewma < lower_limit then 'out_of_control_lower'
             else 'in_control'
         end  as control_status
  from  spc_intermediates.ewma_individual_measurements(
                p_weighting,
                p_limits_width,
                p_target_mean,
                p_target_std_dev
        ) eim;
$$;

-- Cumulative Sum aka Cusum

create function spc_reports.cusum_rules(
    p_target_mean     decimal default null
)
returns table (
    measurement_id  bigint,
    sample_id       bigint,
    window_id       bigint,
    instrument_id   bigint,
    measured_value  decimal,
    error           decimal,
    C_n             decimal
)
immutable language sql as
$$
      select m.id as measurement_id
    , m.sample_id
    , w.id                                                                      as window_id
    , s.instrument_id
    , m.measured_value
    , m.measured_value - coalesce(p_target_mean, mean_measured_value)           as error
    , sum(m.measured_value - coalesce(p_target_mean, mean_measured_value))
        over (partition by w.id order by m.id)                                  as C_n
from spc_data.measurements m
         join spc_data.samples s on s.id = m.sample_id
         join spc_data.instruments i on i.id = s.instrument_id
         join spc_data.windows w on i.id = w.instrument_id
         join spc_intermediates.individual_measurement_statistics_ewma imse on w.id = imse.window_id;
$$;