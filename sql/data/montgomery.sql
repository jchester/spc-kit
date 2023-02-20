-- Data taken from:
--   Montgomery, Douglas. Introduction to Statistical Quality Control 8th EMEA edition.

insert into spc_data.observed_systems (name)
values ('Table 6.1 and Table 6.2');

insert into spc_data.instruments (observed_system_id, name)
values ((select id from spc_data.observed_systems where name = 'Table 6.1 and Table 6.2'), 'Flow Width');

select spc_data.bulk_insert_example_data_measurements(
               'Flow Width',
               'Table 6.1',
               '[2023-01-01 00:00:00,2023-01-02 00:00:00)'::tstzrange,
               'limit_establishment',
               array [
                 array [1.3235, 1.4128, 1.6744, 1.4573, 1.6914],
                 array [1.4314, 1.3592, 1.6075, 1.4666, 1.6109],
                 array [1.4284, 1.4871, 1.4932, 1.4324, 1.5674],
                 array [1.5028, 1.6352, 1.3841, 1.2831, 1.5507],
                 array [1.5604, 1.2735, 1.5265, 1.4363, 1.6441],
                 array [1.5955, 1.5451, 1.3574, 1.3281, 1.4198],
                 array [1.6274, 1.5064, 1.8366, 1.4177, 1.5144],
                 array [1.4190, 1.4303, 1.6637, 1.6067, 1.5519],
                 array [1.3884, 1.7277, 1.5355, 1.5176, 1.3688],
                 array [1.4039, 1.6697, 1.5089, 1.4627, 1.5220],
                 array [1.4158, 1.7667, 1.4278, 1.5928, 1.4181],
                 array [1.5821, 1.3355, 1.5777, 1.3908, 1.7559],
                 array [1.2856, 1.4106, 1.4447, 1.6398, 1.1928],
                 array [1.4951, 1.4036, 1.5893, 1.6458, 1.4969],
                 array [1.3589, 1.2863, 1.5996, 1.2497, 1.5471],
                 array [1.5747, 1.5301, 1.5171, 1.1839, 1.8662],
                 array [1.3680, 1.7269, 1.3957, 1.5014, 1.4449],
                 array [1.4163, 1.3864, 1.3057, 1.6210, 1.5573],
                 array [1.5796, 1.4185, 1.6541, 1.5116, 1.7247],
                 array [1.7106, 1.4412, 1.2361, 1.3820, 1.7601],
                 array [1.4371, 1.5051, 1.3485, 1.5670, 1.4880],
                 array [1.4738, 1.5936, 1.6583, 1.4973, 1.4720],
                 array [1.5917, 1.4333, 1.5551, 1.5295, 1.6866],
                 array [1.6399, 1.5243, 1.5705, 1.5563, 1.5530],
                 array [1.5797, 1.3663, 1.6240, 1.3732, 1.6877]
                 ]
         );

select spc_data.bulk_insert_example_data_measurements(
               'Flow Width',
               'Table 6.2',
               '[2023-01-02 00:00:00,2023-01-03 00:00:00)'::tstzrange,
               'control',
               array [
                 array [1.4483, 1.5458, 1.4538, 1.4303, 1.6206],
                 array [1.5435, 1.6899, 1.5830, 1.3358, 1.4187],
                 array [1.5175, 1.3446, 1.4723, 1.6657, 1.6661],
                 array [1.5454, 1.1093, 1.4072, 1.5039, 1.5264],
                 array [1.4418, 1.5059, 1.5124, 1.4620, 1.6263],
                 array [1.4301, 1.2725, 1.5945, 1.5397, 1.5252],
                 array [1.4981, 1.4506, 1.6174, 1.5837, 1.4962],
                 array [1.3009, 1.5060, 1.6231, 1.5831, 1.6454],
                 array [1.4132, 1.4603, 1.5808, 1.7111, 1.7313],
                 array [1.3817, 1.3135, 1.4953, 1.4894, 1.4596],
                 array [1.5765, 1.7014, 1.4026, 1.2773, 1.4541],
                 array [1.4936, 1.4373, 1.5139, 1.4808, 1.5293],
                 array [1.5729, 1.6738, 1.5048, 1.5651, 1.7473],
                 array [1.8089, 1.5513, 1.8250, 1.4389, 1.6558],
                 array [1.6236, 1.5393, 1.6738, 1.8698, 1.5036],
                 array [1.4120, 1.7931, 1.7345, 1.6391, 1.7791],
                 array [1.7372, 1.5663, 1.4910, 1.7809, 1.5504],
                 array [1.5971, 1.7394, 1.6832, 1.6677, 1.7974],
                 array [1.4295, 1.6536, 1.9134, 1.7272, 1.4370],
                 array [1.6217, 1.8220, 1.7915, 1.6744, 1.9404]
                 ]
         );


insert into spc_data.observed_systems (name)
values ('Table 6.3');

insert into spc_data.instruments (observed_system_id, name)
values ((select id from spc_data.observed_systems where name = 'Table 6.3'), 'Engine Piston Diameter');

select spc_data.bulk_insert_example_data_measurements(
               'Engine Piston Diameter',
               'Table 6.3',
               '[2023-02-01 00:00:00,2023-02-02 00:00:00)',
               'limit_establishment',
               array [
                 array [74.030, 74.002, 74.019, 73.992, 74.008],
                 array [73.995, 73.992, 74.001, 74.011, 74.004],
                 array [73.998, 74.024, 74.021, 74.005, 74.002],
                 array [74.002, 73.996, 73.993, 74.015, 74.009],
                 array [73.992, 74.007, 74.015, 73.989, 74.014],
                 array [74.009, 73.994, 73.997, 73.985, 73.993],
                 array [73.995, 74.006, 73.994, 74.000, 74.005],
                 array [73.985, 74.003, 73.993, 74.015, 73.998],
                 array [74.008, 73.995, 74.009, 74.005, 74.004],
                 array [73.998, 74.000, 73.990, 74.007, 73.995],
                 array [73.994, 73.998, 73.994, 73.995, 73.990],
                 array [74.004, 74.000, 74.007, 74.000, 73.996],
                 array [73.983, 74.002, 73.998, 73.997, 74.012],
                 array [74.006, 73.967, 73.994, 74.000, 73.984],
                 array [74.012, 74.014, 73.998, 73.999, 74.007],
                 array [74.000, 73.984, 74.005, 73.998, 73.996],
                 array [73.994, 74.012, 73.986, 74.005, 74.007],
                 array [74.006, 74.010, 74.018, 74.003, 74.000],
                 array [73.984, 74.002, 74.003, 74.005, 73.997],
                 array [74.000, 74.010, 74.013, 74.020, 74.003],
                 array [73.982, 74.001, 74.015, 74.005, 73.996],
                 array [74.004, 73.999, 73.990, 74.006, 74.009],
                 array [74.010, 73.989, 73.990, 74.009, 74.014],
                 array [74.015, 74.008, 73.993, 74.009, 74.014],
                 array [73.982, 73.984, 73.995, 74.017, 74.013]
                 ]
         );

insert into spc_data.observed_systems (name)
values ('Table 7.1');

insert into spc_data.instruments (observed_system_id, name)
values ((select id from spc_data.observed_systems where name = 'Table 7.1'), 'Orange Juice Inspection');

select spc_data.bulk_insert_example_data_whole_item_conformities(
               'Orange Juice Inspection',
               'Table 7.1',
               '[2023-05-01 00:00:00,2023-05-02 00:00:00)',
               'limit_establishment',
               array [
                 array [38, 12],
                 array [35, 15],
                 array [42, 8],
                 array [40, 10],
                 array [46, 4],
                 array [43, 7],
                 array [34, 16],
                 array [41, 9],
                 array [36, 14],
                 array [40, 10],
                 array [45, 5],
                 array [44, 6],
                 array [33, 17],
                 array [38, 12],
                 array [28, 22],
                 array [42, 8],
                 array [40, 10],
                 array [45, 5],
                 array [37, 13],
                 array [39, 11],
                 array [30, 20],
                 array [32, 18],
                 array [26, 24],
                 array [35, 15],
                 array [41, 9],
                 array [38, 12],
                 array [43, 7],
                 array [37, 13],
                 array [41, 9],
                 array [44, 6]
                 ]
         );

insert into spc_data.observed_systems (name)
values ('Table 7.8');

insert into spc_data.instruments (observed_system_id, name)
values ((select id from spc_data.observed_systems where name = 'Table 7.8'), 'Printed Circuit Boards');

select spc_data.bulk_insert_example_data_per_unit_non_conformities(
               'Printed Circuit Boards',
               'Table 7.8',
               '[2023-05-03 00:00:00,2023-05-04 00:00:00)',
               'limit_establishment',
               array [
                 21, 24, 16, 12, 15,
                 5, 28, 20, 31, 25,
                 20, 24, 16, 19, 10,
                 17, 13, 22, 18, 39,
                 30, 24, 16, 19, 17,
                 15
                 ]
         )