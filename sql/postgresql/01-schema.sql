create schema if not exists spc;

create table spc.observed_systems (
  id   bigserial primary key,
  name text not null,

  unique (name)
);

create type spc.instrument_type as enum ('variable', 'attribute');

create table spc.instruments (
  id                 bigserial primary key,
  observed_system_id bigint references spc.observed_systems (id) not null,
  name               text                                        not null,
  type               spc.instrument_type                         not null,

  unique (name, observed_system_id)
);

create table spc.control_windows (
  id            bigserial primary key,
  instrument_id bigint references spc.instruments (id) not null,
  period        tstzrange                              not null,
  description   text,

  unique (period, instrument_id),
  exclude using gist(period with &&)
);

create table spc.samples (
  id                bigserial primary key,
  control_window_id bigint references spc.control_windows (id) not null,
  period            tstzrange                                  not null,

  unique (period, control_window_id),
  exclude using gist (period with &&)
);

create table spc.measurements (
  id             bigserial primary key,
  sample_id      bigint references spc.samples (id) not null,
  period         tstzrange                          not null,
  measured_value decimal                            not null,

  exclude using gist (period with &&)
);

create view spc.sample_statistics as
  select sample_id
       , avg(measured_value)                       as sample_mean
       , stddev_pop(measured_value)                as sample_stddev
       , max(measured_value) - min(measured_value) as sample_range
       , count(1)                                  as sample_size
  from spc.measurements
  group by sample_id;

-- https://qualityamerica.com/LSS-Knowledge-Center/statisticalprocesscontrol/control_chart_constants.php
-- and Appendix VI of Montgomery
-- @formatter:off
create view spc.scaling_factors(sample_size, a, a2, a3, c4, c4_reciprocal, b3, b4, b5, b6, lower_d2, lower_d2_reciprocal, lower_d3, upper_d1, upper_d2, upper_d3, upper_d4) as
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
, (25,    0.6,    0.153,  0.606,  0.9896,   1.0/0.9896,   0.565,  1.435,  0.559,    1.420,  3.931,     1.0/3.931,            0.708,      1.806,    6.056,       0.459,    1.541)
;
