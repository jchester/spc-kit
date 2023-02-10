# SPC Kit

Very much a work-in-progress, but here's the basic idea: perform statistical process
control calculations _in SQL_. Why?

1. The database is closest to the data and will be the fastest place to manipulate it.
2. SQL is a lingua franca that any language and framework can interoperate with easily.

But by all that's holy take note of the LICENSE, in which I disclaim all warranties.
If you use this for something involving real consequences, that's on you.

A lot of the details of what's what and how it works lives in PostgreSQL comments.

### What it can do:

* Report out-of-control samples on _variables_ using:
    * x̄R (aka XbarR) limits
    * R̄ (aka Rbar) limits
    * x̄s (aka XbarS) limits
    * s̄ (aka s) limits

### What it cannot do:

Everything else. No attribute charts. No XmR charts. No Cusum or EWMA. No Hotelling T². Etc.
