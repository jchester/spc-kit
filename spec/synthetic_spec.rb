require 'minitest/autorun'
require 'sequel'
require 'logger'
require_relative 'spc_spec'

class SyntheticSpec < SpcSpec
  before do
    DB.rollback_on_exit(savepoint: true)

    DB.copy_into(:observed_systems, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/observed_systems.csv"))
    DB.copy_into(:instruments, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/instruments.csv"))
    DB.copy_into(:samples, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/samples.csv"))
    DB.copy_into(:measurements, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/measurements.csv"))
    DB.copy_into(:windows, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/windows.csv"))
    DB.copy_into(:window_relationships, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/window_relationships.csv"))
  end

  describe "Shewhart charts" do
    describe "Limit in-control / Control in-control" do
      instrument_id = 1

      describe "x̄R rules" do
        subject do
          DB[:x_bar_r_rules].where(instrument_id:)
        end

        it_has_params(mean: 2, upper: 4.046, lower: -0.046)

        it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)
      end

      describe "R̄ rules" do
        subject do
          DB[:r_rules].where(instrument_id:)
        end

        it_has_params(mean: 2, upper: 5.148, lower: 0)

        it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)
      end

      describe "x̄s rules" do
        subject do
          DB[:x_bar_s_rules].where(instrument_id:)
        end

        it_has_params(mean: 2, upper: 3.954, lower: 0.046)

        it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)
      end

      describe "s̄ rules" do
        subject do
          DB[:s_rules].where(instrument_id:)
        end

        it_has_params(mean: 1, upper: 2.568, lower: 0)

        it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)
      end
    end

    describe "Limit in-control / Control out-of-control" do
      instrument_id = 2

      describe "x̄R rules" do
        subject do
          DB[:x_bar_r_rules].where(instrument_id:)
        end

        it_has_params(mean: 4, upper: 6.514, lower: 1.486)

        it_has_status_counts_of(in_control: 27, out_of_control_upper: 1, out_of_control_lower: 1)

        it_is_out_of_control_at(upper_samples: [56], lower_samples: [57])
      end

      describe "R̄ rules" do
        subject do
          DB[:r_rules].where(instrument_id:)
        end

        it_has_params(mean: 6, upper: 11.544, lower: 0.456)

        it_has_status_counts_of(in_control: 27, out_of_control_upper: 1, out_of_control_lower: 1)

        it_is_out_of_control_at(upper_samples: [58], lower_samples: [59])
      end

      describe "x̄s rules" do
        subject do
          DB[:x_bar_s_rules].where(instrument_id:)
        end

        it_has_params(mean: 4, upper: 6.553, lower: 1.446)

        it_has_status_counts_of(in_control: 27, out_of_control_upper: 1, out_of_control_lower: 1)

        it_is_out_of_control_at(upper_samples: [56], lower_samples: [57])
      end

      describe "s̄ rules" do
        subject do
          DB[:s_rules].where(instrument_id:)
        end

        it_has_params(mean: 2.16, upper: 4.066, lower: 0.255)

        it_has_status_counts_of(in_control: 27, out_of_control_upper: 1, out_of_control_lower: 1)

        it_is_out_of_control_at(upper_samples: [58], lower_samples: [59])
      end
    end

    describe "Limit out-of-control / Control in-control" do
      instrument_id = 3

      describe "x̄R rules" do
        subject do
          DB[:x_bar_r_rules].where(instrument_id:)
        end

        it_has_params(mean: 3.695, upper: 6.237, lower: 1.152)

        it_has_status_counts_of(in_control: 32, out_of_control_upper: 1, out_of_control_lower: 1)

        it_is_out_of_control_at(upper_samples: [85], lower_samples: [86])
      end

      describe "R̄ rules" do
        subject do
          DB[:r_rules].where(instrument_id:)
        end

        it_has_params(mean: 6.069, upper: 11.677, lower: 0.461)

        it_has_status_counts_of(in_control: 32, out_of_control_upper: 1, out_of_control_lower: 1)

        it_is_out_of_control_at(upper_samples: [87], lower_samples: [88])
      end

      describe "x̄s rules" do
        subject do
          DB[:x_bar_s_rules].where(instrument_id:)
        end

        it_has_params(mean: 3.695, upper: 6.260, lower: 1.128)

        it_has_status_counts_of(in_control: 32, out_of_control_upper: 1, out_of_control_lower: 1)

        it_is_out_of_control_at(upper_samples: [85], lower_samples: [86])
      end

      describe "s̄ rules" do
        subject do
          DB[:s_rules].where(instrument_id:)
        end

        it_has_params(mean: 2.171, upper: 4.086, lower: 0.256)

        it_has_status_counts_of(in_control: 32, out_of_control_upper: 1, out_of_control_lower: 1)

        it_is_out_of_control_at(upper_samples: [87], lower_samples: [88])
      end
    end

    describe "Limit out-of-control / Control out-of-control" do
      instrument_id = 4

      describe "x̄R rules" do
        subject do
          DB[:x_bar_r_rules].where(instrument_id:)
        end

        it_has_params(mean: 3.695, upper: 6.237, lower: 1.152)

        it_has_status_counts_of(in_control: 29, out_of_control_upper: 2, out_of_control_lower: 2)

        it_is_out_of_control_at(upper_samples: [119, 123], lower_samples: [120, 124])
      end

      describe "R̄ rules" do
        subject do
          DB[:r_rules].where(instrument_id:)
        end

        it_has_params(mean: 6.069, upper: 11.677, lower: 0.461)

        it_has_status_counts_of(in_control: 29, out_of_control_upper: 2, out_of_control_lower: 2)

        it_is_out_of_control_at(upper_samples: [121, 125], lower_samples: [122, 126])
      end

      describe "x̄s rules" do
        subject do
          DB[:x_bar_s_rules].where(instrument_id:)
        end

        it_has_params(mean: 3.695, upper: 6.260, lower: 1.128)

        it_has_status_counts_of(in_control: 29, out_of_control_upper: 2, out_of_control_lower: 2)

        it_is_out_of_control_at(upper_samples: [119, 123], lower_samples: [120, 124])
      end

      describe "s̄ rules" do
        subject do
          DB[:s_rules].where(instrument_id:)
        end

        it_has_params(mean: 2.171, upper: 4.086, lower: 0.256)

        it_has_status_counts_of(in_control: 29, out_of_control_upper: 2, out_of_control_lower: 2)

        it_is_out_of_control_at(upper_samples: [121,125], lower_samples: [122, 126])
      end
    end

    describe "With exclusions / Limit out-of-control / Control in-control" do
      instrument_id = 5

      describe "x̄R rules" do
        subject do
          DB[:x_bar_r_rules].where(instrument_id:)
        end

        it_has_params(mean: 4, upper: 6.514, lower: 1.486)

        it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)
      end

      describe "R̄ rules" do
        subject do
          DB[:r_rules].where(instrument_id:)
        end

        it_has_params(mean: 6, upper: 11.544, lower: 0.456)

        it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)
      end

      describe "x̄s rules" do
        subject do
          DB[:x_bar_s_rules].where(instrument_id:)
        end

        it_has_params(mean: 4, upper: 6.553, lower: 1.447)

        it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)
      end

      describe "s̄ rules" do
        subject do
          DB[:s_rules].where(instrument_id:)
        end

        it_has_params(mean: 2.160, upper: 4.066, lower: 0.255)

        it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)
      end
    end
  end

  describe "EWMA charts" do
    describe "in-control / computed mean & std dev" do
      instrument_id = 6

      subject do
        DB.from(
          Sequel.lit('spc_reports.ewma_rules(?, ?)',
                     0.1, # weighting
                     3 # limits
          )
        ).where(instrument_id:).order_by(:sample_id)
      end

      it_has_params(mean: 10, upper: 10.253, lower: 9.746)

      it_has_status_counts_of(in_control: 15, out_of_control_upper: 0, out_of_control_lower: 0)

      # @formatter:off
      it_has_correct_ewma_values([
         9.9000,  9.9100,  10.0190, 9.9171,  9.9253,
         10.0328, 9.9295,  9.9366,  10.0429, 9.9386,
         9.94478, 10.0503, 9.9452,  9.9507,  10.0556
      ])
      # @formatter:on

      it "has the correct EWMA values" do
        # @formatter:off
        ewma_values = [
          9.9000,  9.9100,  10.0190, 9.9171,  9.9253,
          10.0328, 9.9295,  9.9366,  10.0429, 9.9386,
          9.94478, 10.0503, 9.9452,  9.9507,  10.0556
        ]
        # @formatter:on

        paired_array = ewma_values.zip(subject.select_map(:exponentially_weighted_moving_average))

        paired_array.each do |value1, value2|
          assert_in_delta value1, value2
        end
      end
    end

    describe "out-of-control upper / target mean & std dev" do
      instrument_id = 7

      subject do
        DB.from(
          Sequel.lit('spc_reports.ewma_rules(?, ?, ?, ?)',
                     0.1, # weighting
                     3, # limits
                     0, # target mean
                     1# target std dev

          )
        ).where(instrument_id:).order_by(:sample_id)
      end

      it_has_params(mean: 0, upper: 0.299, lower: -0.299)

      it_has_status_counts_of(in_control: 131, out_of_control_upper: 4, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [311, 312, 313, 315], lower_samples: [])

      # @formatter:off
      it_has_correct_ewma_values([
        -0.02265, 0.031169, -0.10190, -0.03014, -0.06845, -0.15743, -0.22870, -0.29335, -0.23038, -0.08910,
        -0.06474, -0.08544, 0.037422, 0.108123, -0.05295, 0.130413, 0.070408, -0.06630, -0.11573, -0.17563,
        -0.20404, -0.27729, -0.18360, -0.24396, -0.04197, -0.07127, -0.17527, -0.07431, -0.01900, -0.09254,
        -0.36736, -0.24025, -0.22303, -0.17260, -0.20438, -0.12356, -0.20429, -0.11701, -0.21369, -0.16209,
        -0.41400, -0.30354, -0.25923, -0.26624, -0.31175, -0.22539, -0.22473, -0.37014, -0.24088, -0.22538,
        -0.36270, -0.41978, -0.30720, -0.18316, -0.24316, -0.19105, -0.22476, -0.16702, 0.059271, 0.229172,
        0.161270, 0.144998, 0.155202, 0.119894, -0.00599, 0.087746, 0.135960, 0.058242, 0.139204, 0.264348,
        0.213046, 0.220014, 0.082393, 0.145157, 0.080426, -0.01415, -0.04508, 0.041989, 0.052588, 0.064464,
        0.142222, 0.091996, -0.01418, 0.098557, 0.125241, -0.02418, -0.11307, -0.18795, -0.32962, -0.38153,
        -0.36146, -0.37938, -0.33188, -0.21999, -0.23885, -0.27771, -0.29093, -0.34509, -0.21611, -0.09532,
        -0.10194, -0.00729, 0.016625, 0.033020, -0.01189, -0.06107, -0.12593, -0.16777, -0.09239, -0.21698,
        0.158762, 0.033306, 0.088973, 0.096160, 0.008934, 0.033248, -0.02712, 0.140288, -0.06270, -0.15465,
        -0.09674, -0.17752, -0.02845, -0.20199, -0.09292, 0.169679, 0.351070, 0.490393, 0.374173, 0.427495,
        0.703387, 0.898720, 0.718259, 0.621815, 0.710886
      ])
      # @formatter:on
    end

    describe "out-of-control lower / target mean & std dev" do
      instrument_id = 8

      subject do
        DB.from(
          Sequel.lit('spc_reports.ewma_rules(?, ?, ?, ?)',
                     0.1, # weighting
                     3, # limits
                     0, # target mean
                     1# target std dev

          )
        ).where(instrument_id:).order_by(:sample_id)
      end

      it_has_params(mean: 0, upper: 0.299, lower: -0.299)

      it_has_status_counts_of(in_control: 137, out_of_control_upper: 0, out_of_control_lower: 3)

      it_is_out_of_control_at(upper_samples: [], lower_samples: [450, 454, 455])

      # @formatter:off
      it_has_correct_ewma_values([
        -0.02265, 0.031169, -0.10190, -0.03014, -0.06845, -0.32973, -0.22770, -0.19097, -0.20481, -0.25646,
        -0.27679, -0.34276, -0.24253, -0.29699, -0.08970, -0.06527, -0.08593, 0.036986, 0.107731, -0.05330,
        -0.08147, -0.18446, -0.08258, -0.02643, -0.09923, -0.03412, -0.05259, -0.21521, -0.10145, -0.09989,
        -0.18572, -0.25417, -0.31626, -0.25100, -0.10766, 0.081171, 0.026090, -0.10618, -0.15163, -0.20794,
        -0.12675, -0.20717, -0.11960, -0.21602, -0.16418, -0.30762, -0.37021, -0.26259, -0.14301, -0.20703,
        -0.21119, -0.16180, -0.26124, -0.16411, -0.19791, -0.08498, -0.01949, -0.08166, 0.013285, 0.151021,
        0.090934, 0.081696, 0.098230, 0.068619, -0.05214, -0.33101, -0.20752, -0.19358, -0.14610, -0.18053,
        -0.24902, -0.25646, -0.14825, -0.11862, -0.08963, -0.05286, -0.10040, -0.05509, 0.160006, 0.319834,
        0.372055, 0.298846, 0.171980, 0.266106, 0.276035, 0.111530, 0.009070, -0.07802, -0.23068, -0.29249,
        -0.32597, -0.33437, -0.38418, -0.25130, -0.12699, -0.13237, -0.17321, -0.14632, -0.05298, -0.08855,
        -0.09584, -0.00180, 0.021558, 0.037460, -0.00789, 0.035338, -0.05864, 0.078539, -0.10570, -0.00626,
        0.348409, 0.203988, 0.242586, 0.234412, 0.133361, 0.069650, -0.00828, -0.06188, 0.002904, -0.13121,
        -0.09288, -0.14064, 0.038123, -0.15465, -0.23741, -0.39239, -0.29935, -0.30228, -0.31655, -0.33266,
        -0.30901, -0.58158, -0.53192, -0.53070, -0.70113, -0.47180, -0.51909, -0.51607, -0.79323, -0.89869
      ])
      # @formatter:on
    end
  end
end