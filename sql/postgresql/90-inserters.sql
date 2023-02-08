create or replace function spc.bulk_insert_example_data_measurements(
  p_instrument_name     text,
  p_control_window_desc text,
  p_window_period       tstzrange,
  p_window_type         spc.window_type,
  p_measurements        decimal[][]
)
  returns void
as
$$
declare
  v_instrument_queried_id bigint;
  v_control_window_id     bigint;
  v_sample_period         tstzrange;
  v_measurement_period    tstzrange;
  v_sample_inserted_id    bigint;
  v_sample                decimal[];
  v_measurement           decimal;
begin
  select id from spc.instruments where name = p_instrument_name into v_instrument_queried_id;

  insert into spc.control_windows (instrument_id, period, type, description)
  values (v_instrument_queried_id, p_window_period, p_window_type, p_control_window_desc)
  returning id into v_control_window_id;

  select tstzrange(lower(p_window_period), lower(p_window_period) + interval '1 minute')
  into v_sample_period;

  foreach v_sample slice 1 in array p_measurements loop
    insert into spc.samples (control_window_id, period)
    values (v_control_window_id, v_sample_period)
    returning id into v_sample_inserted_id;

    select tstzrange(lower(v_sample_period), lower(v_sample_period) + interval '1 second') into v_measurement_period;

    foreach v_measurement in array v_sample loop
      insert into spc.measurements(sample_id, period, measured_value)
      values (v_sample_inserted_id, v_measurement_period, v_measurement);

      select tstzrange(upper(v_measurement_period), upper(v_measurement_period) + interval '1 second')
      into v_measurement_period;
    end loop;

    select tstzrange(upper(v_sample_period), upper(v_sample_period) + interval '1 minute') into v_sample_period;
  end loop;
end
$$ language plpgsql;