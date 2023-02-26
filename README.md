# SPC Kit

Very much a work-in-progress, but here's the basic idea: perform statistical process
control calculations _in SQL_. Why?

1. The database is closest to the data and will be the fastest place to manipulate it.
2. SQL is a lingua franca that any language and framework can interoperate with easily.

But by all that's holy take note of the LICENSE, in which I disclaim all warranties.
If you use this for something involving real consequences, that's on you.

## Installation

The SQL dialect used is unapologetically PostgreSQL, so you need that running first.

Then apply the `sql/postgresql` files in alphanumeric order. They are prefixed with
numbers for your convenience.

You can optionally add sample data from the `data` directory. I mostly used these to
check my calculations and rule queries.

## Usage

A lot of the details of what's what and how it works lives in PostgreSQL comments.
But as a summary:

1. Add your data to tables in `spc_data`.
  * Create entries in observed_systems for each system you wish to observe.
  * Create instruments under each system.
  * Create samples under each instrument for each sampling period.
  * Create measurements under each sample. The number of measurements for each sample must be the same.
2. Then establish your limits.
  * Identify which time periods are your limit establishment windows - the samples you will
    use to calculate limits for subsequent control. Add to data.
  * Add control windows that immediately follow a limit establishment window and finish before
  the next limit establishment window.
3. Read back rules applied to samples from `spc_reports`.
3. Ignore `spc_intermediates`, unless you want to understand the calculations from end to end.

## What it can do

* Report out-of-control samples on _variables_ using:
    * x̄R (aka XbarR) limits. These detect out-of-control sample averages, based on the variability of ranges of samples. 
      (See: Montgomery §6.2.1, Eqn 6.4)
    * R̄ (aka Rbar) limits. These detect out-of-control sample ranges. (See: Montgomery §6.2.1, Eqn 6.5)
    * x̄s (aka XbarS) limits. These detect out-of-control sample averages, based on the variability of the standard
      deviation of samples. (See: Montgomery §6.3, Eqn 6.28)
    * s̄ (aka Sbar) limits. These detect out-of-control sample standard deviations. (See: Montgomery §6.3, Eqns 6.25 & 
      6.27)
    * XmR limits. These are applied to samples with a single measurement and track measurement-to-measurement changes in
      means and ranges. Sensitive to deviation from normality. (See: Montgomery §6.4, Eqn 6.33; Wheeler & Chambers §3.6)
* Report out-of-control samples on _attributes_ using:
    * p limits, available in both conformant (aka yield chart) and non-conformant (aka fallout chart) flavors. (See:
      Montgomery §7.2, Eqn 7.8)
    * np limits, available in both conformant and non-conformant flavors. (See: Montgomery §7.2.1, Eqn 7.13)
    * c limits. (See: Montgomery §7.3.1, Eqn 7.17)

Sample sizes are assumed to be equal throughout a window.

## What it cannot do

Everything else. No variable sample sizes. No sensitizing rules. No u charts. No Cusum or EWMA. No Hotelling T². Etc.

## References

* Stjernlöf, C. ["Statistical Process Control: A Practitioner's Guide"](https://two-wrongs.com/statistical-process-control-a-practitioners-guide.html),
  _Two Wrongs_. 
* Montgomery, Douglas C. _Introduction to Statistical Quality Control_, 8th EMEA Ed.
* Wheeler, Donald J and Chambers, David S. _Understanding Statistical Process Control_, 3rd Ed.
