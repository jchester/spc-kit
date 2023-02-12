create schema if not exists spc_reports;

comment on schema spc_reports is $$
This is where you read out the control status of individual samples, based on the application of Shewart rules. Control
status can be one of three conditions:

* in_control. There is nothing to do, the process is operating with common cause variability.
* out_of_control_upper. The process sample has exceeded the upper control limit for the process. Investigation is
  necessary to establish why the upper control limit has been exceeded.
* out_of_control_lower. As with out_of_control_upper, except that the lower control limit has been breached.

When using an ORM, you will typically join these views to the base tables in spc_data in order to attach control status
about samples to the sample object.
$$;

create view spc_reports.x_bar_r_rules as
  select ss.id        as sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.period
       , case
           when sample_mean > upper_control_limit then 'out_of_control_upper'
           when sample_mean < lower_control_limit then 'out_of_control_lower'
           else 'in_control'
         end          as shewart_control_status
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.period <@ control_w.period
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.x_bar_r_limits on limits_w.id = x_bar_r_limits.limit_establishment_window_id
  where include_in_limit_calculations;

comment on view spc_reports.x_bar_r_rules is $$
This view applies the limits derived in x_bar_r_limits to matching control windows, showing which sample averages were
in-control and out-of-control according to the x̄R limits on x̄.
$$;

create view spc_reports.r_rules as
  select ss.id        as sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.period
       , case
           when sample_range > upper_control_limit then 'out_of_control_upper'
           when sample_range < lower_control_limit then 'out_of_control_lower'
           else 'in_control'
         end          as shewart_control_status
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.period <@ control_w.period
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.r_limits on limits_w.id = r_limits.limit_establishment_window_id
  where include_in_limit_calculations;

comment on view spc_reports.r_rules is $$
This view applies the limits derived in r_limits to matching control windows, showing which sample ranges where
in-control and out-of-control according the the R̄ limits on R. These signals are useful up until sample size = 10; after
that you should switch to using s_rules instead.
$$;

create view spc_reports.x_bar_s_rules as
  select ss.id        as sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.period
       , case
           when sample_mean > upper_control_limit then 'out_of_control_upper'
           when sample_mean < lower_control_limit then 'out_of_control_lower'
           else 'in_control'
         end          as shewart_control_status
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.period <@ control_w.period
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.x_bar_s_limits on limits_w.id = x_bar_s_limits.limit_establishment_window_id
  where include_in_limit_calculations;

comment on view spc_reports.x_bar_s_rules is $$
This view applies the limits derived in x_bar_s_limits to matching control windows, showing
which sample ranges are in-control and out-of-control according to the x̄s limits on s.
$$;

create view spc_reports.s_rules as
  select ss.id        as sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.period
       , case
           when sample_stddev > upper_control_limit then 'out_of_control_upper'
           when sample_stddev < lower_control_limit then 'out_of_control_lower'
           else 'in_control'
         end          as shewart_control_status
  from spc_intermediates.measurement_sample_statistics ss
       join spc_data.windows                           control_w on ss.period <@ control_w.period
       join spc_data.window_relationships              wr on control_w.id = wr.control_window_id
       join spc_data.windows                           limits_w on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.s_limits on limits_w.id = s_limits.limit_establishment_window_id
  where include_in_limit_calculations;

comment on view spc_reports.s_rules is $$
This view applies the limits derived in s_limits to matching control windows, showing which sample ranges were
in-control and out-of-control according the s̄ limits on s. These signals are more effective than r_rules when sample
size > 10.
$$;

create view spc_reports.p_conformant_rules as
  select ss.sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.period
       , case
           when mean_fraction_conforming > upper_control_limit then 'out_of_control_upper'
           when mean_fraction_conforming < lower_control_limit then 'out_of_control_lower'
           else 'in_control'
         end          as p_control_status
  from spc_intermediates.fraction_conforming_sample_statistics ss
       join spc_data.windows                                   control_w on ss.period <@ control_w.period
       join spc_data.window_relationships                      wr on control_w.id = wr.control_window_id
       join spc_data.windows                                   limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.p_limits_conformant on limits_w.id = p_limits_conformant.limit_establishment_window_id
  where include_in_limit_calculations;

comment on view spc_reports.p_conformant_rules is $$
This view applies the limits derived in p_limits_conformant to matching control windows, showing which sample fractions
conforming where in-control and out-of-control according to the limits on the fraction conforming.

This is a non-traditional application, the typical approach is to set rules on fraction non-conforming. This is included
for completeness.
$$;

create view spc_reports.p_non_conformant_rules as
  select ss.sample_id
       , control_w.id as control_window_id
       , limits_w.id  as limit_establishment_window_id
       , ss.period
       , case
           when mean_fraction_non_conforming > upper_control_limit then 'out_of_control_upper'
           when mean_fraction_non_conforming < lower_control_limit then 'out_of_control_lower'
           else 'in_control'
         end          as p_control_status
  from spc_intermediates.fraction_conforming_sample_statistics ss
       join spc_data.windows                                   control_w on ss.period <@ control_w.period
       join spc_data.window_relationships                      wr on control_w.id = wr.control_window_id
       join spc_data.windows                                   limits_w
            on limits_w.id = wr.limit_establishment_window_id
       join spc_intermediates.p_limits_non_conformant
            on limits_w.id = p_limits_non_conformant.limit_establishment_window_id
  where include_in_limit_calculations;

comment on view spc_reports.p_non_conformant_rules is $$
This view applies the limits derived in p_limits_non_conformant to matching control windows, showing which sample
fractions non-conforming where in-control and out-of-control according to the limits on the fraction non-conforming.
$$;
