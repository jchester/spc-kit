# SPC Kit

Very much a work-in-progress, but here's the basic idea: perform statistical process control calculations _in SQL_. Why?

1. The database is closest to the data and will be the fastest place to manipulate it.
2. SQL is a lingua franca that any language and framework can interoperate with easily.

But by all that's holy take note of the LICENSE, in which I disclaim all warranties. If you use this for something
involving real consequences, that's on you.

### What the heck is statistical process control?

The short version is:

* A process shows two kinds of variability
  1. Common or ordinary variability, which can be seen all the time and is statistically predictable.
  2. Special or assignable variability, which is out of the ordinary.
* You can use some simple rules to detect the special/assignable events, so you can investigate what is going wrong.
* You can use some simple rules to compare common variability to your target performance, so you can figure out whether
  improvement is necessary (and afterwards whether you've managed to improve things).

Because statistical process control is based on simple data and simple rules, it doesn't require a PhD to apply
successfully. Folks were doing this stuff by hand in the 50s without fuss. Turning it into SQL makes it even easier to
apply in a modern context.

See [References and Further Reading](#references-and-further-reading) for some more detailed reading.

## What it can do

* Report out-of-control samples on _variables_ using:
    * x̄R (aka XbarR) limits. These detect out-of-control sample averages, based on the variability of ranges of samples. 
      (See: Montgomery §6.2.1, Eqn 6.4)
    * R̄ (aka Rbar) limits. These detect out-of-control sample ranges. (See: Montgomery §6.2.1, Eqn 6.5)
    * x̄s (aka XbarS) limits. These detect out-of-control sample averages, based on the variability of the standard
      deviation of samples. (See: Montgomery §6.3, Eqn 6.28)
    * s̄ (aka Sbar) limits. These detect out-of-control sample standard deviations. (See: Montgomery §6.3, Eqns 6.25 & 
      6.27)
    * Limits for individual measurements (aka XmR). These are applied to samples with a single measurement and track
      measurement-to-measurement changes in means (X) and moving ranges (mR). Sensitive to departure from normality.
      (See: Montgomery §6.4, Eqn 6.33; Wheeler & Chambers §3.6)
    * Limits for Exponentially-Weighted Moving Averages (EWMA). These track shifts in the mean. Useful adjunct to the
      usual Shewhart charts. (See: Montgomery §9.2, Eqns 9.25 & 9.26)
* Report out-of-control samples on _attributes_ using:
    * p limits, available in both conformant (aka yield chart) and non-conformant (aka fallout chart) flavors. (See:
      Montgomery §7.2, Eqn 7.8)
    * np limits, available in both conformant and non-conformant flavors. (See: Montgomery §7.2.1, Eqn 7.13)
    * c limits. (See: Montgomery §7.3.1, Eqn 7.17)

Sample sizes are assumed to be equal throughout a window.

## What it cannot do

Everything else. No variable sample sizes. No sensitizing rules. No u charts. No Cusum. No Hotelling T². Etc.

## Alternatives

SQL not your style? Not a problem.

Here are some alternative packages I found with some light searching. Most of them include inbuilt plotting capability,
unlike SPC Kit. I have chosen examples where there are tests and some activity in the past few years (not always fair,
it is possible to "finish" an SPC package if you don't bother with exotic charts). I have not tried out these packages,
so _caveat emptor_.

* Python: [SPC](https://github.com/hviidhenrik/SPC) by Henrik Hviid Hansen.
* Julia: [StatisticalProcessMonitoring.jl](https://github.com/DedZago/StatisticalProcessMonitoring.jl) by Daniele Zago.
* R: a very active community. These looked most promising:
  * [qicharts2](https://github.com/anhoej/qicharts2/) by Jacob Anhøj.
  * [runcharter](https://github.com/johnmackintosh/runcharter),
    [spccharter](https://github.com/johnmackintosh/spccharter) and
    [cusumcharter](https://github.com/johnmackintosh/cusumcharter) by John MacKintosh.
  * [NHSRplotthedots](https://github.com/nhs-r-community/NHSRplotthedots) by NHS-r-community.

## Installation

The SQL dialect used is unapologetically PostgreSQL, so you need that running first.

Then apply the `sql/postgresql` files in alphanumeric order. They are prefixed with numbers for your convenience.

You can optionally add sample data from the `data` directory. I mostly used these to check my calculations and rule
queries.

## Usage

A lot of the details of what's what and how it works lives in PostgreSQL comments. However, to help you to get started,
here is a short walkthrough of adding data and retrieving rule results. We will use data taken from Montgomery (see
[References and Further Reading](#references-and-further-reading)).

### Establish systems and instruments.

Data is collected about _Observed Systems_ using _Instruments_. For example, an observed system might be a process for
manufacturing screws. Instruments in this example would include screw length, screw head diameter and so on. Instruments
need not be physical measurement devices. Any kind of timeseries that can be observed from an Observed System can be an
Instrument.

For our first example we will use Tables 6.1 and 6.2 from Montgomery. Our Observed System will be the photolithography
process in a semiconductor factory:

```sql
insert into spc_data.observed_systems(id, name) overriding system value
values (1, 'Photolithography Process from Montgomery');
```

Montgomery's example is to measure the flow width of the resist in microns. "Flow width of the resist" refers to the
spreading out of special photoresistant chemicals on the mask that is being made for the semiconductor. If they are too
narrow or too wide, the resulting circuit may be faulty.

Let's add the instrument:

```sql
insert into spc_data.instruments(id, observed_system_id, name) overriding system value
values (1, 1, 'Flow Resist Width (Tables 6.1 and 6.2)');
```
### Windows

Windows are spans of Samples that belong to an Instrument.

Montgomery gives two tables of data (6.1 and 6.2). Table 6.1 is intended for establishing the process control limits of
the current process; 6.2 is for when the process is operating under control. These are distinct uses for data. Most
importantly, the limits established with the first set of samples (traditionally 20 samples is considered the minimum
acceptable number) is then used in subsequent samples to detect out-of-control conditions.

Therefore, SPC-kit allows you to group together Samples into _Windows_, which express the purpose for which the Samples
are to be used. Let's add two windows for the Tables 6.1 (limit establishment) and 6.2 (control):

```sql
insert into spc_data.windows(id, instrument_id, type, description) overriding system value
values (1, 1, 'limit_establishment', 'Table 6.1');
insert into spc_data.windows(id, instrument_id, type, description) overriding system value
values (2, 1, 'control', 'Table 6.2');
```

Each control window belongs to one limit establishment window. This relationship does not rely on time ranges, but is
explicitly recorded in `spc_data.window_relationships`. Let us connect our two windows together:

```sql
insert into spc_data.window_relationships (limit_establishment_window_id, control_window_id) values (1, 2);
```

Note that you may link a limit-establishment window to itself. This is useful for cases (like XmR) where the distinction
between limit establishment and control is unimportant. For completeness we will do so for the window established based
on Table 6.1:

```sql
insert into spc_data.window_relationships (limit_establishment_window_id, control_window_id) values (1, 1);
```

### Samples and Measurements

Each Window contains _Samples_, which in turn have one or more _Measurements_. Let us add some data for the two tables,
starting with establishing the samples within each window:

```sql
-- @formatter:off
insert into spc_data.samples (id, window_id, include_in_limit_calculations) overriding system value
-- Table 6.1
values (1,  1, true),  (2,  1, true),  (3,  1, true),  (4,  1, true),  (5,  1, true),
       (6,  1, true),  (7,  1, true),  (8,  1, true),  (9,  1, true),  (10, 1, true),
       (11, 1, true),  (12, 1, true),  (13, 1, true),  (14, 1, true),  (15, 1, true),
       (16, 1, true),  (17, 1, true),  (18, 1, true),  (19, 1, true),  (20, 1, true),
       (21, 1, true),  (22, 1, true),  (23, 1, true),  (24, 1, true),  (25, 1, true),
-- Table 6.2
       (26, 2, true),  (27, 2, true),  (28, 2, true),  (29, 2, true),  (30, 2, true),
       (31, 2, true),  (32, 2, true),  (33, 2, true),  (34, 2, true),  (35, 2, true),
       (36, 2, true),  (37, 2, true),  (38, 2, true),  (39, 2, true),  (40, 2, true),
       (41, 2, true),  (42, 2, true),  (43, 2, true),  (44, 2, true),  (45, 2, true);
-- @formatter:on
```

Now we add data. Five measurements are taken per sample, yielding 125 measurements for Table 6.1 and another 100 for
Table 6.2, for a total of 225 measurements:

```sql
-- @formatter:off
insert into spc_data.measurements (id, sample_id, performed_at, measured_value) overriding system value
values (1,   1,  '2023-01-01 00:00:00.000000 +00:00', 1.3235),  (2,   1,  '2023-01-01 00:00:01.000000 +00:00', 1.4128),  (3,   1,  '2023-01-01 00:00:02.000000 +00:00', 1.6744),  (4,   1,  '2023-01-01 00:00:03.000000 +00:00', 1.4573),
       (5,   1,  '2023-01-01 00:00:04.000000 +00:00', 1.6914),  (6,   2,  '2023-01-01 00:01:00.000000 +00:00', 1.4314),  (7,   2,  '2023-01-01 00:01:01.000000 +00:00', 1.3592),  (8,   2,  '2023-01-01 00:01:02.000000 +00:00', 1.6075),
       (9,   2,  '2023-01-01 00:01:03.000000 +00:00', 1.4666),  (10,  2,  '2023-01-01 00:01:04.000000 +00:00', 1.6109),  (11,  3,  '2023-01-01 00:02:00.000000 +00:00', 1.4284),  (12,  3,  '2023-01-01 00:02:01.000000 +00:00', 1.4871),
       (13,  3,  '2023-01-01 00:02:02.000000 +00:00', 1.4932),  (14,  3,  '2023-01-01 00:02:03.000000 +00:00', 1.4324),  (15,  3,  '2023-01-01 00:02:04.000000 +00:00', 1.5674),  (16,  4,  '2023-01-01 00:03:00.000000 +00:00', 1.5028),
       (17,  4,  '2023-01-01 00:03:01.000000 +00:00', 1.6352),  (18,  4,  '2023-01-01 00:03:02.000000 +00:00', 1.3841),  (19,  4,  '2023-01-01 00:03:03.000000 +00:00', 1.2831),  (20,  4,  '2023-01-01 00:03:04.000000 +00:00', 1.5507),
       (21,  5,  '2023-01-01 00:04:00.000000 +00:00', 1.5604),  (22,  5,  '2023-01-01 00:04:01.000000 +00:00', 1.2735),  (23,  5,  '2023-01-01 00:04:02.000000 +00:00', 1.5265),  (24,  5,  '2023-01-01 00:04:03.000000 +00:00', 1.4363),
       (25,  5,  '2023-01-01 00:04:04.000000 +00:00', 1.6441),  (26,  6,  '2023-01-01 00:05:00.000000 +00:00', 1.5955),  (27,  6,  '2023-01-01 00:05:01.000000 +00:00', 1.5451),  (28,  6,  '2023-01-01 00:05:02.000000 +00:00', 1.3574),
       (29,  6,  '2023-01-01 00:05:03.000000 +00:00', 1.3281),  (30,  6,  '2023-01-01 00:05:04.000000 +00:00', 1.4198),  (31,  7,  '2023-01-01 00:06:00.000000 +00:00', 1.6274),  (32,  7,  '2023-01-01 00:06:01.000000 +00:00', 1.5064),
       (33,  7,  '2023-01-01 00:06:02.000000 +00:00', 1.8366),  (34,  7,  '2023-01-01 00:06:03.000000 +00:00', 1.4177),  (35,  7,  '2023-01-01 00:06:04.000000 +00:00', 1.5144),  (36,  8,  '2023-01-01 00:07:00.000000 +00:00', 1.419 ),
       (37,  8,  '2023-01-01 00:07:01.000000 +00:00', 1.4303),  (38,  8,  '2023-01-01 00:07:02.000000 +00:00', 1.6637),  (39,  8,  '2023-01-01 00:07:03.000000 +00:00', 1.6067),  (40,  8,  '2023-01-01 00:07:04.000000 +00:00', 1.5519),
       (41,  9,  '2023-01-01 00:08:00.000000 +00:00', 1.3884),  (42,  9,  '2023-01-01 00:08:01.000000 +00:00', 1.7277),  (43,  9,  '2023-01-01 00:08:02.000000 +00:00', 1.5355),  (44,  9,  '2023-01-01 00:08:03.000000 +00:00', 1.5176),
       (45,  9,  '2023-01-01 00:08:04.000000 +00:00', 1.3688),  (46,  10, '2023-01-01 00:09:00.000000 +00:00', 1.4039),  (47,  10, '2023-01-01 00:09:01.000000 +00:00', 1.6697),  (48,  10, '2023-01-01 00:09:02.000000 +00:00', 1.5089),
       (49,  10, '2023-01-01 00:09:03.000000 +00:00', 1.4627),  (50,  10, '2023-01-01 00:09:04.000000 +00:00', 1.522 ),  (51,  11, '2023-01-01 00:10:00.000000 +00:00', 1.4158),  (52,  11, '2023-01-01 00:10:01.000000 +00:00', 1.7667),
       (53,  11, '2023-01-01 00:10:02.000000 +00:00', 1.4278),  (54,  11, '2023-01-01 00:10:03.000000 +00:00', 1.5928),  (55,  11, '2023-01-01 00:10:04.000000 +00:00', 1.4181),  (56,  12, '2023-01-01 00:11:00.000000 +00:00', 1.5821),
       (57,  12, '2023-01-01 00:11:01.000000 +00:00', 1.3355),  (58,  12, '2023-01-01 00:11:02.000000 +00:00', 1.5777),  (59,  12, '2023-01-01 00:11:03.000000 +00:00', 1.3908),  (60,  12, '2023-01-01 00:11:04.000000 +00:00', 1.7559),
       (61,  13, '2023-01-01 00:12:00.000000 +00:00', 1.2856),  (62,  13, '2023-01-01 00:12:01.000000 +00:00', 1.4106),  (63,  13, '2023-01-01 00:12:02.000000 +00:00', 1.4447),  (64,  13, '2023-01-01 00:12:03.000000 +00:00', 1.6398),
       (65,  13, '2023-01-01 00:12:04.000000 +00:00', 1.1928),  (66,  14, '2023-01-01 00:13:00.000000 +00:00', 1.4951),  (67,  14, '2023-01-01 00:13:01.000000 +00:00', 1.4036),  (68,  14, '2023-01-01 00:13:02.000000 +00:00', 1.5893),
       (69,  14, '2023-01-01 00:13:03.000000 +00:00', 1.6458),  (70,  14, '2023-01-01 00:13:04.000000 +00:00', 1.4969),  (71,  15, '2023-01-01 00:14:00.000000 +00:00', 1.3589),  (72,  15, '2023-01-01 00:14:01.000000 +00:00', 1.2863),
       (73,  15, '2023-01-01 00:14:02.000000 +00:00', 1.5996),  (74,  15, '2023-01-01 00:14:03.000000 +00:00', 1.2497),  (75,  15, '2023-01-01 00:14:04.000000 +00:00', 1.5471),  (76,  16, '2023-01-01 00:15:00.000000 +00:00', 1.5747),
       (77,  16, '2023-01-01 00:15:01.000000 +00:00', 1.5301),  (78,  16, '2023-01-01 00:15:02.000000 +00:00', 1.5171),  (79,  16, '2023-01-01 00:15:03.000000 +00:00', 1.1839),  (80,  16, '2023-01-01 00:15:04.000000 +00:00', 1.8662),
       (81,  17, '2023-01-01 00:16:00.000000 +00:00', 1.368 ),  (82,  17, '2023-01-01 00:16:01.000000 +00:00', 1.7269),  (83,  17, '2023-01-01 00:16:02.000000 +00:00', 1.3957),  (84,  17, '2023-01-01 00:16:03.000000 +00:00', 1.5014),
       (85,  17, '2023-01-01 00:16:04.000000 +00:00', 1.4449),  (86,  18, '2023-01-01 00:17:00.000000 +00:00', 1.4163),  (87,  18, '2023-01-01 00:17:01.000000 +00:00', 1.3864),  (88,  18, '2023-01-01 00:17:02.000000 +00:00', 1.3057),
       (89,  18, '2023-01-01 00:17:03.000000 +00:00', 1.621 ),  (90,  18, '2023-01-01 00:17:04.000000 +00:00', 1.5573),  (91,  19, '2023-01-01 00:18:00.000000 +00:00', 1.5796),  (92,  19, '2023-01-01 00:18:01.000000 +00:00', 1.4185),
       (93,  19, '2023-01-01 00:18:02.000000 +00:00', 1.6541),  (94,  19, '2023-01-01 00:18:03.000000 +00:00', 1.5116),  (95,  19, '2023-01-01 00:18:04.000000 +00:00', 1.7247),  (96,  20, '2023-01-01 00:19:00.000000 +00:00', 1.7106),
       (97,  20, '2023-01-01 00:19:01.000000 +00:00', 1.4412),  (98,  20, '2023-01-01 00:19:02.000000 +00:00', 1.2361),  (99,  20, '2023-01-01 00:19:03.000000 +00:00', 1.382 ),  (100, 20, '2023-01-01 00:19:04.000000 +00:00', 1.7601),
       (101, 21, '2023-01-01 00:20:00.000000 +00:00', 1.4371),  (102, 21, '2023-01-01 00:20:01.000000 +00:00', 1.5051),  (103, 21, '2023-01-01 00:20:02.000000 +00:00', 1.3485),  (104, 21, '2023-01-01 00:20:03.000000 +00:00', 1.567 ),
       (105, 21, '2023-01-01 00:20:04.000000 +00:00', 1.488 ),  (106, 22, '2023-01-01 00:21:00.000000 +00:00', 1.4738),  (107, 22, '2023-01-01 00:21:01.000000 +00:00', 1.5936),  (108, 22, '2023-01-01 00:21:02.000000 +00:00', 1.6583),
       (109, 22, '2023-01-01 00:21:03.000000 +00:00', 1.4973),  (110, 22, '2023-01-01 00:21:04.000000 +00:00', 1.472 ),  (111, 23, '2023-01-01 00:22:00.000000 +00:00', 1.5917),  (112, 23, '2023-01-01 00:22:01.000000 +00:00', 1.4333),
       (113, 23, '2023-01-01 00:22:02.000000 +00:00', 1.5551),  (114, 23, '2023-01-01 00:22:03.000000 +00:00', 1.5295),  (115, 23, '2023-01-01 00:22:04.000000 +00:00', 1.6866),  (116, 24, '2023-01-01 00:23:00.000000 +00:00', 1.6399),
       (117, 24, '2023-01-01 00:23:01.000000 +00:00', 1.5243),  (118, 24, '2023-01-01 00:23:02.000000 +00:00', 1.5705),  (119, 24, '2023-01-01 00:23:03.000000 +00:00', 1.5563),  (120, 24, '2023-01-01 00:23:04.000000 +00:00', 1.553 ),
       (121, 25, '2023-01-01 00:24:00.000000 +00:00', 1.5797),  (122, 25, '2023-01-01 00:24:01.000000 +00:00', 1.3663),  (123, 25, '2023-01-01 00:24:02.000000 +00:00', 1.624 ),  (124, 25, '2023-01-01 00:24:03.000000 +00:00', 1.3732),
       (125, 25, '2023-01-01 00:24:04.000000 +00:00', 1.6877),  (126, 26, '2023-01-01 00:25:00.000000 +00:00', 1.4483),  (127, 26, '2023-01-01 00:25:01.000000 +00:00', 1.5458),  (128, 26, '2023-01-01 00:25:02.000000 +00:00', 1.4538),
       (129, 26, '2023-01-01 00:25:03.000000 +00:00', 1.4303),  (130, 26, '2023-01-01 00:25:04.000000 +00:00', 1.6206),  (131, 27, '2023-01-01 00:26:00.000000 +00:00', 1.5435),  (132, 27, '2023-01-01 00:26:01.000000 +00:00', 1.6899),
       (133, 27, '2023-01-01 00:26:02.000000 +00:00', 1.583 ),  (134, 27, '2023-01-01 00:26:03.000000 +00:00', 1.3358),  (135, 27, '2023-01-01 00:26:04.000000 +00:00', 1.4187),  (136, 28, '2023-01-01 00:27:00.000000 +00:00', 1.5175),
       (137, 28, '2023-01-01 00:27:01.000000 +00:00', 1.3446),  (138, 28, '2023-01-01 00:27:02.000000 +00:00', 1.4723),  (139, 28, '2023-01-01 00:27:03.000000 +00:00', 1.6657),  (140, 28, '2023-01-01 00:27:04.000000 +00:00', 1.6661),
       (141, 29, '2023-01-01 00:28:00.000000 +00:00', 1.5454),  (142, 29, '2023-01-01 00:28:01.000000 +00:00', 1.1093),  (143, 29, '2023-01-01 00:28:02.000000 +00:00', 1.4072),  (144, 29, '2023-01-01 00:28:03.000000 +00:00', 1.5039),
       (145, 29, '2023-01-01 00:28:04.000000 +00:00', 1.5264),  (146, 30, '2023-01-01 00:29:00.000000 +00:00', 1.4418),  (147, 30, '2023-01-01 00:29:01.000000 +00:00', 1.5059),  (148, 30, '2023-01-01 00:29:02.000000 +00:00', 1.5124),
       (149, 30, '2023-01-01 00:29:03.000000 +00:00', 1.462 ),  (150, 30, '2023-01-01 00:29:04.000000 +00:00', 1.6263),  (151, 31, '2023-01-01 00:30:00.000000 +00:00', 1.4301),  (152, 31, '2023-01-01 00:30:01.000000 +00:00', 1.2725),
       (153, 31, '2023-01-01 00:30:02.000000 +00:00', 1.5945),  (154, 31, '2023-01-01 00:30:03.000000 +00:00', 1.5397),  (155, 31, '2023-01-01 00:30:04.000000 +00:00', 1.5252),  (156, 32, '2023-01-01 00:31:00.000000 +00:00', 1.4981),
       (157, 32, '2023-01-01 00:31:01.000000 +00:00', 1.4506),  (158, 32, '2023-01-01 00:31:02.000000 +00:00', 1.6174),  (159, 32, '2023-01-01 00:31:03.000000 +00:00', 1.5837),  (160, 32, '2023-01-01 00:31:04.000000 +00:00', 1.4962),
       (161, 33, '2023-01-01 00:32:00.000000 +00:00', 1.3009),  (162, 33, '2023-01-01 00:32:01.000000 +00:00', 1.506 ),  (163, 33, '2023-01-01 00:32:02.000000 +00:00', 1.6231),  (164, 33, '2023-01-01 00:32:03.000000 +00:00', 1.5831),
       (165, 33, '2023-01-01 00:32:04.000000 +00:00', 1.6454),  (166, 34, '2023-01-01 00:33:00.000000 +00:00', 1.4132),  (167, 34, '2023-01-01 00:33:01.000000 +00:00', 1.4603),  (168, 34, '2023-01-01 00:33:02.000000 +00:00', 1.5808),
       (169, 34, '2023-01-01 00:33:03.000000 +00:00', 1.7111),  (170, 34, '2023-01-01 00:33:04.000000 +00:00', 1.7313),  (171, 35, '2023-01-01 00:34:00.000000 +00:00', 1.3817),  (172, 35, '2023-01-01 00:34:01.000000 +00:00', 1.3135),
       (173, 35, '2023-01-01 00:34:02.000000 +00:00', 1.4953),  (174, 35, '2023-01-01 00:34:03.000000 +00:00', 1.4894),  (175, 35, '2023-01-01 00:34:04.000000 +00:00', 1.4596),  (176, 36, '2023-01-01 00:35:00.000000 +00:00', 1.5765),
       (177, 36, '2023-01-01 00:35:01.000000 +00:00', 1.7014),  (178, 36, '2023-01-01 00:35:02.000000 +00:00', 1.4026),  (179, 36, '2023-01-01 00:35:03.000000 +00:00', 1.2773),  (180, 36, '2023-01-01 00:35:04.000000 +00:00', 1.4541),
       (181, 37, '2023-01-01 00:36:00.000000 +00:00', 1.4936),  (182, 37, '2023-01-01 00:36:01.000000 +00:00', 1.4373),  (183, 37, '2023-01-01 00:36:02.000000 +00:00', 1.5139),  (184, 37, '2023-01-01 00:36:03.000000 +00:00', 1.4808),
       (185, 37, '2023-01-01 00:36:04.000000 +00:00', 1.5293),  (186, 38, '2023-01-01 00:37:00.000000 +00:00', 1.5729),  (187, 38, '2023-01-01 00:37:01.000000 +00:00', 1.6738),  (188, 38, '2023-01-01 00:37:02.000000 +00:00', 1.5048),
       (189, 38, '2023-01-01 00:37:03.000000 +00:00', 1.5651),  (190, 38, '2023-01-01 00:37:04.000000 +00:00', 1.7473),  (191, 39, '2023-01-01 00:38:00.000000 +00:00', 1.8089),  (192, 39, '2023-01-01 00:38:01.000000 +00:00', 1.5513),
       (193, 39, '2023-01-01 00:38:02.000000 +00:00', 1.825 ),  (194, 39, '2023-01-01 00:38:03.000000 +00:00', 1.4389),  (195, 39, '2023-01-01 00:38:04.000000 +00:00', 1.6558),  (196, 40, '2023-01-01 00:39:00.000000 +00:00', 1.6236),
       (197, 40, '2023-01-01 00:39:01.000000 +00:00', 1.5393),  (198, 40, '2023-01-01 00:39:02.000000 +00:00', 1.6738),  (199, 40, '2023-01-01 00:39:03.000000 +00:00', 1.8698),  (200, 40, '2023-01-01 00:39:04.000000 +00:00', 1.5036),
       (201, 41, '2023-01-01 00:40:00.000000 +00:00', 1.412 ),  (202, 41, '2023-01-01 00:40:01.000000 +00:00', 1.7931),  (203, 41, '2023-01-01 00:40:02.000000 +00:00', 1.7345),  (204, 41, '2023-01-01 00:40:03.000000 +00:00', 1.6391),
       (205, 41, '2023-01-01 00:40:04.000000 +00:00', 1.7791),  (206, 42, '2023-01-01 00:41:00.000000 +00:00', 1.7372),  (207, 42, '2023-01-01 00:41:01.000000 +00:00', 1.5663),  (208, 42, '2023-01-01 00:41:02.000000 +00:00', 1.491 ),
       (209, 42, '2023-01-01 00:41:03.000000 +00:00', 1.7809),  (210, 42, '2023-01-01 00:41:04.000000 +00:00', 1.5504),  (211, 43, '2023-01-01 00:42:00.000000 +00:00', 1.5971),  (212, 43, '2023-01-01 00:42:01.000000 +00:00', 1.7394),
       (213, 43, '2023-01-01 00:42:02.000000 +00:00', 1.6832),  (214, 43, '2023-01-01 00:42:03.000000 +00:00', 1.6677),  (215, 43, '2023-01-01 00:42:04.000000 +00:00', 1.7974),  (216, 44, '2023-01-01 00:43:00.000000 +00:00', 1.4295),
       (217, 44, '2023-01-01 00:43:01.000000 +00:00', 1.6536),  (218, 44, '2023-01-01 00:43:02.000000 +00:00', 1.9134),  (219, 44, '2023-01-01 00:43:03.000000 +00:00', 1.7272),  (220, 44, '2023-01-01 00:43:04.000000 +00:00', 1.437 ),
       (221, 45, '2023-01-01 00:44:00.000000 +00:00', 1.6217),  (222, 45, '2023-01-01 00:44:01.000000 +00:00', 1.822 ),  (223, 45, '2023-01-01 00:44:02.000000 +00:00', 1.7915),  (224, 45, '2023-01-01 00:44:03.000000 +00:00', 1.6744),
       (225, 45, '2023-01-01 00:44:04.000000 +00:00', 1.9404);
-- @formatter:on
```

### Reading back rule results

Data inserted into `spc_data` is processed through `spc_intermediate` and then assembled into per-measurement _Rules_.
Each row in a Rule view tells you whether a Sample was within control limits, or whether it exceeded control limits.

Let's look at Table 6.2 and see if we can find out-of-control Samples:

```sql
select id_sample                    as "Sample ID",
       data_controlled_value        as "Sample Average",
       data_upper_limit             as "Upper Limit",
       rule_in_control              as "In Control?",
       rule_out_of_control_upper    as "Out of Control Upper?"
from spc_reports.x_bar_r_rules
where id_control_window = 2
  and not rule_in_control
order by id_sample;
```

Giving:

| Sample ID | Sample Average | Upper Limit | In Control? | Out of Control Upper? |
|-----------|----------------|-------------|-------------|-----------------------|
| 43        | 1.69696        | 1.693224336 | false       | true                  |
| 45        | 1.77           | 1.693224336 | false       | true                  |

We can see that samples 43 and 45 are unusually high: they are out of control. This means we need to perform an
investigation to establish what has occurred to cause the unusual sample average.

You may have noticed the prefixes for each column. They follow a consistent pattern across different views and
functions: `id_` refers to an ID from another table, `data_` represents some value as of that sample and `rule_` is
whether a particular rule has been matched or not.

## You Read The License, Right?

SPC Kit is Copyright (C) 2024 Jacques Chester.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.


## References and Further Reading

Listed in suggested order of priority.

* Stjernlöf, C. ["Statistical Process Control: A Practitioner's Guide"](https://entropicthoughts.com/statistical-process-control-a-practitioners-guide),
  _Entropic Thoughts_.
* Chin, C. ["Becoming Data Driven, From First Principles"](https://commoncog.com/becoming-data-driven-first-principles/),
  _Commoncog_.
* Montgomery, Douglas C. _Introduction to Statistical Quality Control_, 8th EMEA Ed.
* Wheeler, Donald J and Chambers, David S. _Understanding Statistical Process Control_, 3rd Ed.
