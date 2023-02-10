create or replace function spc_data.bulk_insert_example_data_measurements(
  p_instrument_name text,
  p_window_desc     text,
  p_window_period   tstzrange,
  p_window_type     spc_data.window_type,
  p_measurements    decimal[][]
)
  returns void
as
$$
declare
  v_instrument_queried_id         bigint;
  v_limit_establishment_window_id bigint;
  v_control_window_id             bigint;
  v_sample_period                 tstzrange;
  v_measurement_period            timestamptz;
  v_sample_inserted_id            bigint;
  v_sample                        decimal[];
  v_measurement                   decimal;
begin
  select id from spc_data.instruments where name = p_instrument_name into v_instrument_queried_id;

  case p_window_type
    when 'limit_establishment' then
      insert into spc_data.windows (instrument_id, period, type, description)
      values (v_instrument_queried_id, p_window_period, p_window_type, p_window_desc)
      returning id into v_limit_establishment_window_id;

      -- allow limit establishment windows to be applied to themselves
      insert into spc_data.window_relationships (limit_establishment_window_id, control_window_id)
      values (v_limit_establishment_window_id, v_limit_establishment_window_id);
    when 'control' then
      select w.id
      from spc_data.windows          w
           join spc_data.instruments i on i.id = w.instrument_id
      where w.type = 'limit_establishment'
      and i.id = v_instrument_queried_id
      into v_limit_establishment_window_id;

      insert into spc_data.windows (instrument_id, period, type, description)
      values (v_instrument_queried_id, p_window_period, p_window_type, p_window_desc)
      returning id into v_control_window_id;

      insert into spc_data.window_relationships(limit_establishment_window_id, control_window_id)
      values (v_limit_establishment_window_id, v_control_window_id);
  end case;

  select tstzrange(lower(p_window_period), lower(p_window_period) + interval '1 minute')
  into v_sample_period;

  foreach v_sample slice 1 in array p_measurements loop
    insert into spc_data.samples (instrument_id, period)
    values (v_instrument_queried_id, v_sample_period)
    returning id into v_sample_inserted_id;

    select timestamptz(lower(v_sample_period)) into v_measurement_period;

    foreach v_measurement in array v_sample loop
      insert into spc_data.measurements(sample_id, taken_at, measured_value)
      values (v_sample_inserted_id, v_measurement_period, v_measurement);

      select timestamptz(v_measurement_period + interval '1 second')
      into v_measurement_period;
    end loop;

    select tstzrange(upper(v_sample_period), upper(v_sample_period) + interval '1 minute') into v_sample_period;
  end loop;
end
$$ language plpgsql;

comment on function spc_data.bulk_insert_example_data_measurements is $$
This function is used to quickly load data tables in the data/ directory.

Do not use it to insert your data. It is not designed for general use.
$$;