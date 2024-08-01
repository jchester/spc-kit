-- Data generated by hand to provide test cases for key scenarios:
--   1. Limit establishment window (lew) in-control,     control window (cw) in-control
--   2. Limit establishment window (lew) in-control,     control window (cw) out-of-control
--   3. Limit establishment window (lew) out-of-control, control window (cw) in-control
--   4. Limit establishment window (lew) out-of-control, control window (cw) out-of-control
--   5. Limit establishment window (lew) out-of-control points excluded, control window (cw) in-control
--
-- In these scenarios we assume that the assignable causes of all the out-of-control signals in limit establishment can
-- be found, so we add entries to the excluded_samples table.

------------------------------------------------------------------
-- Shewhart XbarR charts
------------------------------------------------------------------

insert into spc_data.observed_systems (name)
values ('Shewhart Test System');

-- @formatter:off
insert into spc_data.instruments (observed_system_id, name)
values ((select id from spc_data.observed_systems where name = 'Shewhart Test System'), 'shewhart:lew-in-control:cw-in-control')
     , ((select id from spc_data.observed_systems where name = 'Shewhart Test System'), 'shewhart:lew-in-control:cw-out-control')
     , ((select id from spc_data.observed_systems where name = 'Shewhart Test System'), 'shewhart:lew-out-control:cw-in-control')
     , ((select id from spc_data.observed_systems where name = 'Shewhart Test System'), 'shewhart:lew-out-control:cw-out-control')
     , ((select id from spc_data.observed_systems where name = 'Shewhart Test System'), 'shewhart:lew-out-control:cw-in-control:with-exclusions');
-- @formatter:on

--   1. Limit establishment window (lew) in-control, control window (cw) in-control

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-in-control:cw-in-control',
               'shewhart:lew-in-control',
               '[2023-09-01 00:00:00,2023-09-01 00:25:00)',
               'limit_establishment',
               array [
                 array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3],
                 array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3],
                 array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3],
                 array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3],
                 array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3], array [1, 2, 3]
                 ]
         );

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-in-control:cw-in-control',
               'shewhart:cw-in-control',
               '[2023-09-01 00:25:00,2023-09-02 00:00:00)',
               'control',
               array [
                 array [1, 2, 3],
                 array [1, 2, 3],
                 array [1, 2, 3],
                 array [1, 2, 3],
                 array [1, 2, 3]
                 ]
         );

--   2. Limit establishment window (lew) in-control, control window (cw) out-of-control

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-in-control:cw-out-control',
               'shewhart:lew-in-control',
               '[2023-09-03 00:00:00,2023-09-03 00:25:00)',
               'limit_establishment',
               array [
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7]
                 ]
         );

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-in-control:cw-out-control',
               'shewhart:cw-out-control',
               '[2023-09-03 00:25:00,2023-09-04 00:00:00)',
               'control',
               array [
                 array [93, 94, 95, 96, 97, 98, 99], -- Xbar out of control upper
                 array [-99, -98, -97, -96, -95, -94, -93], -- Xbar out of control lower
                 array [-7, 4, 4, 4, 4, 6, 7], -- Rbar out of control upper
                 array [4, 4, 4, 4, 4, 4, 4] -- Rbar out of control lower
                 ]
         );

--   3. Limit establishment window (lew) out-of-control, control window (cw) in-control

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-out-control:cw-in-control',
               'lew-out-control',
               '[2023-09-06 00:00:00,2023-09-06 00:29:00)',
               'limit_establishment',
               array [
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [93, 94, 95, 96, 97, 98, 99], -- Xbar out of control upper
                 array [-99, -98, -97, -96, -95, -94, -93], -- Xbar out of control lower
                 array [-7, 4, 4, 4, 4, 6, 7], -- Rbar out of control upper
                 array [4, 4, 4, 4, 4, 4, 4] -- Rbar out of control lower
                 ]
         );

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-out-control:cw-in-control',
               'shewhart:cw-in-control',
               '[2023-09-06 00:29:00,2023-09-07 00:00:00)',
               'control',
               array [
                 array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7]
                 ]
         );
--   4. Limit establishment window (lew) out-of-control, control window (cw) out-of-control

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-out-control:cw-out-control',
               'lew-out-control',
               '[2023-09-08 00:00:00,2023-09-08 00:29:00)',
               'limit_establishment',
               array [
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [93, 94, 95, 96, 97, 98, 99], -- Xbar out of control upper
                 array [-99, -98, -97, -96, -95, -94, -93], -- Xbar out of control lower
                 array [-7, 4, 4, 4, 4, 6, 7], -- Rbar out of control upper
                 array [4, 4, 4, 4, 4, 4, 4] -- Rbar out of control lower
                 ]
         );

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-out-control:cw-out-control',
               'shewhart:cw-out-control',
               '[2023-09-08 00:29:00,2023-09-09 00:00:00)',
               'control',
               array [
                 array [93, 94, 95, 96, 97, 98, 99], -- Xbar out of control upper
                 array [-99, -98, -97, -96, -95, -94, -93], -- Xbar out of control lower
                 array [-7, 4, 4, 4, 4, 6, 7], -- Rbar out of control upper
                 array [4, 4, 4, 4, 4, 4, 4] -- Rbar out of control lower
                 ]
         );

--   5. Limit establishment window (lew) out-of-control points excluded, control window (cw) in-control

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-out-control:cw-in-control:with-exclusions',
               'shewhart:lew-out-control:with-exclusions',
               '[2023-09-10 00:00:00,2023-09-10 00:29:00)',
               'limit_establishment',
               array [
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7], array [1, 2, 3, 4, 5, 6, 7],
                 array [93, 94, 95, 96, 97, 98, 99], -- Xbar out of control upper
                 array [-99, -98, -97, -96, -95, -94, -93], -- Xbar out of control lower
                 array [-7, 4, 4, 4, 4, 6, 7], -- Rbar out of control upper
                 array [4, 4, 4, 4, 4, 4, 4] -- Rbar out of control lower
                 ]
         );

update spc_data.samples
set include_in_limit_calculations = false
  , annotation                    = 'X bar example data exclusion'
where id in
      (select sample_id as reason_for_exclusion
       from spc_reports.x_bar_r_rules
       where control_status != 'in_control'
       order by lower(period) desc
       limit 2);

update spc_data.samples
set include_in_limit_calculations = false
  , annotation                    = 'R example data exclusion'
where id in
      (select sample_id as reason_for_exclusion
       from spc_reports.r_rules
       where control_status != 'in_control'
       order by lower(period) desc
       limit 2);

update spc_data.samples
set include_in_limit_calculations = false
  , annotation                    = 'X bar example data exclusion'
where id in
      (select sample_id as reason_for_exclusion
       from spc_reports.x_bar_s_rules
       where control_status != 'in_control'
       order by lower(period) desc
       limit 2);

update spc_data.samples
set include_in_limit_calculations = false
  , annotation                    = 'R example data exclusion'
where id in
      (select sample_id as reason_for_exclusion
       from spc_reports.s_rules
       where control_status != 'in_control'
       order by lower(period) desc
       limit 2);

select spc_data.bulk_insert_example_data_measurements(
               'shewhart:lew-out-control:cw-in-control:with-exclusions',
               'shewhart:cw-in-control:with-exclusions',
               '[2023-09-10 00:29:00,2023-09-11 00:00:00)',
               'control',
               array [
                 array [1, 2, 3],
                 array [1, 2, 3],
                 array [1, 2, 3],
                 array [1, 2, 3],
                 array [1, 2, 3]
                 ]
         );

------------------------------------------------------------------
-- EWMA charts
------------------------------------------------------------------

insert into spc_data.observed_systems (name)
values ('EWMA Test System');

-- @formatter:off
insert into spc_data.instruments (observed_system_id, name)
values ((select id from spc_data.observed_systems where name = 'EWMA Test System'), 'ewma:in-control')
     , ((select id from spc_data.observed_systems where name = 'EWMA Test System'), 'ewma:out-control-upper')
     , ((select id from spc_data.observed_systems where name = 'EWMA Test System'), 'ewma:out-control-lower');
-- @formatter:on

--   1. In-control

select spc_data.bulk_insert_example_data_ewma(
               'ewma:in-control',
               'ewma:in-control',
               '[2023-09-12 00:00:00,2023-09-12 00:15:00)',
               array [
                 array [9], array [10], array [11],
                 array [9], array [10], array [11],
                 array [9], array [10], array [11],
                 array [9], array [10], array [11],
                 array [9], array [10], array [11],
                 array [9.5],
                 array [10],
                 array [10.5],
                 array [10],
                 array [9.5]
                 ]
         );

--   2. Out-of-control upper

select spc_data.bulk_insert_example_data_ewma(
               'ewma:out-control-upper',
               'ewma:lew-out-control-upper',
               '[2023-09-19 00:00:00,Infinity)',
               array [
                 -- Mean = 0, Std dev = 1
                 array [-0.226503044], array [0.515544019], array [-1.299524220], array [0.615632103], array [-0.413264723],
                 array [-0.958233345], array [-0.870160641], array [-0.875143960], array [0.336338061], array [1.182390487],
                 array [0.154547103], array [-0.271821480], array [1.143258222], array [0.744432838], array [-1.502663227],
                 array [1.780735186], array [-0.469636590], array [-1.296702429], array [-0.560607931], array [-0.714731503],
                 array [-0.459721114], array [-0.936531929], array [0.659531213], array [-0.787126915], array [1.775942746],
                 array [-0.335021813], array [-1.111294538], array [0.834301613], array [0.478865776], array [-0.754425094],
                 array [-2.840797910], array [0.903805097], array [-0.068090570], array [0.281252714], array [-0.490436190],
                 array [0.603903476], array [-0.930956779], array [0.668559913], array [-1.083806123], array [0.302314837],
                 array [-2.681239985], array [0.690624860], array [0.139556238], array [-0.329376693], array [-0.721355665],
                 array [0.551884348], array [-0.218799056], array [-1.678802296], array [0.922390385], array [-0.085866105],
                 array [-1.598566040], array [-0.933526276], array [0.706035292], array [0.933216085], array [-0.783221867],
                 array [0.278005572], array [-0.528214495], array [0.352641207], array [2.095948162], array [1.758281598],
                 array [-0.449842556], array [-0.001448431], array [0.247038864], array [-0.197878395], array [-1.139036886],
                 array [0.931454850], array [0.569885036], array [-0.641221649], array [0.867864026], array [1.390640481],
                 array [-0.248665816], array [0.282722200], array [-1.156192759], array [0.710036581], array [-0.502159461],
                 array [-0.865395209], array [-0.323435839], array [0.825648394], array [0.147982031], array [0.171343399],
                 array [0.842049290], array [-0.360033390], array [-0.969813366], array [1.113235325], array [0.365394045],
                 array [-1.369009850], array [-0.913072626], array [-0.861906419], array [-1.604600127], array [-0.848742638],
                 array [-0.180871802], array [-0.540695472], array [0.095614070], array [0.787067023], array [-0.408638833],
                 array [-0.627380428], array [-0.409950098], array [-0.832506111], array [0.944662227], array [0.991823877],
                 array [-0.161513581], array [0.844567642], array [0.231863519], array [0.180579358], array [-0.416120069],
                 array [-0.503748973], array [-0.709673337], array [-0.544350810], array [0.586049189], array [-1.338245135],
                 array [3.540464975], array [-1.095797762], array [0.589968676], array [0.160848322], array [-0.776101413],
                 array [0.252076374], array [-0.570469778], array [1.646998666], array [-1.889633769], array [-0.982266945],
                 array [0.424455726], array [-0.904482234], array [1.313186082], array [-1.763930266], array [0.888734243],

                 -- Mean = 1, Std dev = 1
                 array [2.533123343], array [1.983585266], array [1.744301077], array [-0.671800839], array [0.907393162],
                 array [3.186416953], array [2.656718998], array [-0.905897921], array [-0.2461766], array [1.5125216]
                 ]
         );

select spc_data.bulk_insert_example_data_ewma(
               'ewma:out-control-lower',
               'ewma:lew-out-control-lower',
               '[2023-09-19 00:00:00,Infinity)',
               array [
                 -- Mean = 0, Std dev = 1
                 array [-0.226503044], array [0.515544019], array [-1.299524220], array [0.615632103], array [-0.413264723],
                 array [-2.681239985], array [0.690624860], array [0.139556238], array [-0.329376693], array [-0.721355665],
                 array [-0.459721114], array [-0.936531929], array [0.659531213], array [-0.787126915], array [1.775942746],
                 array [0.154547103], array [-0.271821480], array [1.143258222], array [0.744432838], array [-1.502663227],
                 array [-0.335021813], array [-1.111294538], array [0.834301613], array [0.478865776], array [-0.754425094],
                 array [0.551884348], array [-0.218799056], array [-1.678802296], array [0.922390385], array [-0.085866105],
                 array [-0.958233345], array [-0.870160641], array [-0.875143960], array [0.336338061], array [1.182390487],
                 array [1.780735186], array [-0.469636590], array [-1.296702429], array [-0.560607931], array [-0.714731503],
                 array [0.603903476], array [-0.930956779], array [0.668559913], array [-1.083806123], array [0.302314837],
                 array [-1.598566040], array [-0.933526276], array [0.706035292], array [0.933216085], array [-0.783221867],
                 array [-0.248665816], array [0.282722200], array [-1.156192759], array [0.710036581], array [-0.502159461],
                 array [0.931454850], array [0.569885036], array [-0.641221649], array [0.867864026], array [1.390640481],
                 array [-0.449842556], array [-0.001448431], array [0.247038864], array [-0.197878395], array [-1.139036886],
                 array [-2.840797910], array [0.903805097], array [-0.068090570], array [0.281252714], array [-0.490436190],
                 array [-0.865395209], array [-0.323435839], array [0.825648394], array [0.147982031], array [0.171343399],
                 array [0.278005572], array [-0.528214495], array [0.352641207], array [2.095948162], array [1.758281598],
                 array [0.842049290], array [-0.360033390], array [-0.969813366], array [1.113235325], array [0.365394045],
                 array [-1.369009850], array [-0.913072626], array [-0.861906419], array [-1.604600127], array [-0.848742638],
                 array [-0.627380428], array [-0.409950098], array [-0.832506111], array [0.944662227], array [0.991823877],
                 array [-0.180871802], array [-0.540695472], array [0.095614070], array [0.787067023], array [-0.408638833],
                 array [-0.161513581], array [0.844567642], array [0.231863519], array [0.180579358], array [-0.416120069],
                 array [0.424455726], array [-0.904482234], array [1.313186082], array [-1.763930266], array [0.888734243],
                 array [3.540464975], array [-1.095797762], array [0.589968676], array [0.160848322], array [-0.776101413],
                 array [-0.503748973], array [-0.709673337], array [-0.544350810], array [0.586049189], array [-1.338245135],
                 array [0.252076374], array [-0.570469778], array [1.646998666], array [-1.889633769], array [-0.982266945],

                 -- Mean = -1, Std dev = 1
                 array[-1.78724166], array[0.53805096], array[-0.32867207], array[-0.44495045], array[-0.47770706],
                 array[-0.09616005], array[-3.03472897], array[-0.08499412], array[-0.51974251], array[-2.23492205],
                 array[1.5921018], array[-0.9447232], array[-0.4888705], array[-3.2876349], array[-1.8479135]
                 ]
         );

