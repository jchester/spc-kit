create schema if not exists spc_data;

comment on schema spc_data is $$
This schema is where you add your data. Just tables. When using ORM these will be your base objects.
$$;

create table spc_data.observed_systems (
  id   bigserial primary key,
  name text not null,

  unique (name)
);

comment on table spc_data.observed_systems is $$
This represents a single system under observation, which may have multiple associated streams of measurement samples via
instruments. Example systems would include a widget manufacturing production line, or a website server. Each system may
have many instruments.
$$;

create type spc_data.instrument_type as enum ('variable', 'attribute');

create table spc_data.instruments (
  id                 bigserial primary key,
  observed_system_id bigint references spc_data.observed_systems (id) not null,
  name               text                                             not null,
  type               spc_data.instrument_type                         not null,

  unique (name, observed_system_id)
);

comment on table spc_data.instruments is $$
Instruments are the sources of measurements. Each instrument belongs to one system. Examples of instruments include a
widget diameter gauge or webpage time-to-first-byte.
$$;

create table spc_data.samples (
  id                            bigserial primary key,
  instrument_id                 bigint references spc_data.instruments (id) not null,
  period                        tstzrange                                   not null,
  include_in_limit_calculations bool default true                           not null,
  annotation                    text,

  unique (period, instrument_id),
  exclude using gist (period with &&)
);

comment on table spc_data.samples is $$
Samples are periodic occasions on which multiple measurements are collected from an instrument. Each sample belongs to
one instrument but may have many measurements.

Because measurement takes place over time, samples store a period in which measurements were taken.

An annotation field is included so that analysts and operators can add freeform notes on particular samples. This would
mostly be useful in marking up out-of-control samples with any discovered assignable cause(s).

During the limit establishment (aka Phase I) process (see "windows" below), the idea is to:

1. Calculate limits for the limit establishment window from the preliminary samples
2. Identify out-of-control points in the window.
3. Investigate to identify assignable causes for each out-of-control point.
4. As causes are identified, exclude the sample from the window and recalculate limits.
5. This process repeats until either there are no out-of-control samples, or until no further assignable causes can be
   found for remaining out-of-control points.

The 'include_in_limit_calculations' field is for tracking which samples are to be included or excluded from calculations
by the above process.

When excluding samples, the assignable cause discovered should be noted in 'annotation', so that future analysts and
operators can understand what causes have previously been discovered.

Points that have been excluded are no longer included in calculations of limits. This is intended to ensure that the
calculated limits fit closely around the common cause variation, rather than including common cause variation and
assignable cause variation.
$$;

create table spc_data.measurements (
  id             bigserial primary key,
  sample_id      bigint references spc_data.samples (id) not null,
  taken_at       timestamptz                             not null,
  measured_value decimal                                 not null,

  unique (taken_at, sample_id)
);

comment on table spc_data.measurements is $$
A measurement represents a single value collected from a single instrument at a single point in time, as part of a
sample. Each measurement belongs to a single sample.

Measurements are assumed to take zero time, or to at least have a logically-assigned time at which they occurred. Hence
they store a timestamp 'taken_at' to represent this time. Importantly, this timestamp should fit within the 'period'
timestamp range stored on the parent sample. This constraint cannot be enforced within the database without writing a
trigger, so it is ignored for now and needs to be enforced by application code.
$$;

create type spc_data.window_type as enum ('limit_establishment', 'control');

create table spc_data.windows (
  id            bigserial primary key,
  instrument_id bigint references spc_data.instruments (id) not null,
  type          spc_data.window_type                        not null,
  period        tstzrange                                   not null,
  description   text,

  unique (period, instrument_id)
);

comment on table spc_data.windows is $$
Windows are essentially ranges of time during which samples are collected for a given instrument on a given system.
There are two window types: limit establishment windows and control wndows.

Limit establishment windows are the period of samples used to establish Shewart chart control limits, which are then
applied during a control window. Typical guidance is that limit establishment windows should contain at least 20 to 25
samples.

Limit establishment is also known as "Phase I" of control chart usage.

Importantly, all figures calculated using these windows are "trial limits". At the moment this project does not perform
the full Phase I process of recursively eliminating out-of-control samples from the calculated set until all remaining
values are in-control values. This is a future goal.

Control windows are periods during which calculated limits are to be applied. Every control window has one limit
establishment window to which it belongs and from which control limits can be calculated and applied to the control
window.
$$;

create table spc_data.window_relationships (
  limit_establishment_window_id bigint references spc_data.windows not null,
  control_window_id             bigint references spc_data.windows not null,

  primary key (limit_establishment_window_id, control_window_id),
  unique (control_window_id)
);

comment on table spc_data.window_relationships is $$
A single limit establishment window may have zero to many control windows, but each control window may only have a
single limit establishment window. Notably, limit establishment windows may be applied to themselves, allowing for
out-of-control points in the limit establishment window to be identified.

These needs are why the relationships are represented in a separate 1:many join table, rather than as separate tables
or as foreign keys from the windows table into itself.
$$;
