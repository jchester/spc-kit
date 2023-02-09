create or replace function spc.bulk_insert_example_data_measurements(
  p_instrument_name     text,
  p_control_window_desc text,
  p_window_period       tstzrange,
  p_window_type         text,
  p_measurements        decimal[][]
)
  returns void
as
$$
declare
  v_instrument_queried_id         bigint;
  v_limit_establishment_window_id bigint;
  v_sample_period                 tstzrange;
  v_measurement_period            timestamptz;
  v_sample_inserted_id            bigint;
  v_sample                        decimal[];
  v_measurement                   decimal;
begin
  select id from spc.instruments where name = p_instrument_name into v_instrument_queried_id;

  case p_window_type
    when 'limit_establishment' then
      insert into spc.limit_establishment_windows (instrument_id, period, description)
      values (v_instrument_queried_id, p_window_period, p_control_window_desc);
    when 'control' then
      select lew.id
      from spc.limit_establishment_windows lew
           join spc.instruments            i on i.id = lew.instrument_id
      into v_limit_establishment_window_id;

      insert into spc.control_windows (limit_establishment_window_id, period, description)
      values (v_limit_establishment_window_id, p_window_period, p_control_window_desc)
      returning id into v_limit_establishment_window_id;
  end case;

  select tstzrange(lower(p_window_period), lower(p_window_period) + interval '1 minute')
  into v_sample_period;

  foreach v_sample slice 1 in array p_measurements loop
    insert into spc.samples (instrument_id, period)
    values (v_instrument_queried_id, v_sample_period)
    returning id into v_sample_inserted_id;

    select timestamptz(lower(v_sample_period)) into v_measurement_period;

    foreach v_measurement in array v_sample loop
      insert into spc.measurements(sample_id, taken_at, measured_value)
      values (v_sample_inserted_id, v_measurement_period, v_measurement);

      select timestamptz(v_measurement_period + interval '1 second')
      into v_measurement_period;
    end loop;

    select tstzrange(upper(v_sample_period), upper(v_sample_period) + interval '1 minute') into v_sample_period;
  end loop;
end
$$ language plpgsql;