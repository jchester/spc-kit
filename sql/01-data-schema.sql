-- Copyright (C) 2024 Jacques Chester. See LICENSE.

-- This schema is where you add your data. Just tables. When using ORM these will be your base objects.
create schema if not exists spc_data;

-- observed_systems represents a single system under observation, which may have multiple associated streams of
-- measurement samples via instruments. Example systems would include a widget manufacturing production line, or a
-- website server. Each system may have many instruments.
create table spc_data.observed_systems (
  id   bigint generated always as identity primary key,
  name text not null,

  unique (name)
);

-- Instruments are the sources of measurements. Each instrument belongs to one system. Examples of instruments include a
-- widget diameter gauge or webpage time-to-first-byte.
create table spc_data.instruments (
  id                 bigint generated always as identity primary key,
  observed_system_id bigint references spc_data.observed_systems (id) not null,
  name               text                                             not null,

  unique (name, observed_system_id)
);


create type spc_data.window_type as enum ('limit_establishment', 'control');

-- Windows are essentially ranges of samples, belonging to one instrument, that are collected for a given instrument on
-- a given system. There are two window types: limit establishment windows and control windows.
--
-- Limit establishment windows are the period of samples used to establish Shewhart chart control limits, which are then
-- applied during a control window. Typical guidance is that limit establishment windows should contain at least 20 to
-- 25 samples.
--
-- Limit establishment is also known as "Phase I" of control chart usage.
--
-- Importantly, all figures calculated using these windows are "trial limits". At the moment this project does not
-- perform the full Phase I process of recursively eliminating out-of-control samples from the calculated set until all
-- remaining values are in-control values. This is a future goal.
--
-- Control windows are periods during which calculated limits are to be applied. Every control window has one limit
-- establishment window to which it belongs and from which control limits can be calculated and applied to the control
-- window.
create table spc_data.windows (
  id            bigint generated always as identity primary key,
  instrument_id bigint references spc_data.instruments (id) not null,
  type          spc_data.window_type                        not null,
  description   text
);

-- A single limit establishment window may have zero to many control windows, but each control window may only have a
-- single limit establishment window. Notably, limit establishment windows may be applied to themselves, allowing for
-- out-of-control points in the limit establishment window to be identified.
--
-- These needs are why the relationships are represented in a separate 1:many join table, rather than as separate tables
-- or as foreign keys from the windows table into itself.
create table spc_data.window_relationships (
  limit_establishment_window_id bigint references spc_data.windows not null,
  control_window_id             bigint references spc_data.windows not null,

  primary key (limit_establishment_window_id, control_window_id),
  unique (control_window_id)
);

-- Samples are periodic occasions on which one or more measurements are collected from an instrument. Each sample
-- belongs to one window but may have many measurements.
--
-- An annotation field is included so that analysts and operators can add freeform notes on particular samples. This
-- would mostly be useful in marking up out-of-control samples with any discovered assignable cause(s).
--
-- During the limit establishment (aka Phase I) process (see "windows" below), the idea is to:
--
-- 1. Calculate limits for the limit establishment window from the preliminary samples
-- 2. Identify out-of-control points in the window.
-- 3. Investigate to identify assignable causes for each out-of-control point.
-- 4. As causes are identified, exclude the sample from the window and recalculate limits.
-- 5. This process repeats until either there are no out-of-control samples, or until no further assignable causes can
--    be found for remaining out-of-control points.
--
-- The 'include_in_limit_calculations' field is for tracking which samples are to be included or excluded from
-- calculations by the above process.
--
-- When excluding samples, the assignable cause discovered should be noted in 'annotation', so that future analysts and
-- operators can understand what causes have previously been discovered.
--
-- Points that have been excluded are no longer included in calculations of limits. This is intended to ensure that the
-- calculated limits fit closely around the common cause variation, rather than including common cause variation and
-- assignable cause variation.
create table spc_data.samples (
  id                            bigint generated always as identity primary key,
  window_id                     bigint references spc_data.windows (id)     not null,
  include_in_limit_calculations bool default true                           not null,
  annotation                    text
);

-- A measurement represents a single value collected from a single instrument at a single point in time, as part of a
-- sample. Each measurement belongs to a single sample.
--
-- Measurements are assumed to take zero time, or to at least have a logically-assigned time at which they occurred.
-- They store a timestamp 'performed_at' to represent this time.
create table spc_data.measurements (
  id             bigint generated always as identity primary key,
  sample_id      bigint references spc_data.samples (id) not null,
  performed_at   timestamptz                             not null,
  measured_value decimal                                 not null,

  unique (performed_at, sample_id)
);

-- An item conformance inspection happens when a single unit or item is inspected by an instrument and classified as
-- being either conformant (aka passing, accepted, yield, etc) or non-conformant (aka failed, defective, broken,
-- rejected, fallout etc) at a single point in time, as part of a sample of items.
--
-- Item conformance data is used in fraction of non-conforming items charts (aka p charts; the inversion is called a
-- yield chart) and count of non-conforming items charts (aka np charts). Note that the data stored here is that the
-- item was accepted or rejected as whole. No specific data is kept about individual defects or non-conformities that
-- led to rejection; see unit_conformities_inspections for that kind of data.
--
-- As with measurements, inspections are assumed to happen instantaneously and this time is stored as a timestamp.
create table spc_data.whole_unit_conformance_inspections (
  id           bigint generated always as identity primary key,
  sample_id    bigint references spc_data.samples (id) not null,
  performed_at timestamptz                             not null,
  conformant   bool                                    not null,

  unique (performed_at, sample_id)
);

-- An item conformities inspection happens when a set of multiple inspections is applied to a single unit. The unit does
-- not pass/fail as a whole, instead the count of conformities (aka passes, acceptables, successes) and non-conformities
-- (aka failures, defects, bugs, mistakes, errors) is kept for each unit.
--
-- This means that conformities/non-conformities inspections carry more fine-grained information than accepting or
-- rejecting an entire unit by itself, as is done in whole_unit_conformance_inspections. Importantly, an item may have
-- non-*conformities* but still be *conformant* as a whole. That is, sometimes we allow slightly imperfect items to be
-- released. In such cases it is still useful to track non-conformities.
--
-- This data is used in the chart for counts for non-conformities (aka c charts) and average non-conformities over a
-- range (aka area of opportunity, span, interval, batch size, group size) of inspections on multiple items (aka u
-- charts).
--
-- As with measurements, inspections are assumed to happen instantaneously and this time is stored as a timestamp.
create table spc_data.per_unit_non_conformities_inspections (
  id               bigint generated always as identity primary key,
  sample_id        bigint references spc_data.samples (id) not null,
  performed_at     timestamptz                             not null,
  non_conformities int                                     not null,

  unique (performed_at, sample_id)
);
