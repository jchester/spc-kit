require_relative 'spc_spec'

class MontgomerySpec < SpcSpec
  before do
    DB.copy_into(:observed_systems, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/observed_systems.csv"))
    DB.copy_into(:instruments, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/instruments.csv"))
    DB.copy_into(:samples, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/samples.csv"))
    DB.copy_into(:measurements, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/measurements.csv"))
    DB.copy_into(:whole_unit_conformance_inspections, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/whole_unit_conformance_inspections.csv"))
    DB.copy_into(:per_unit_non_conformities_inspections, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/per_unit_non_conformities_inspections.csv"))
    DB.copy_into(:windows, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/windows.csv"))
    DB.copy_into(:window_relationships, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/window_relationships.csv"))
  end

  describe "Flow Width example" do
    instrument_id = 1

    describe "x̄R rules" do
      subject do
        DB[:x_bar_r_rules].where(instrument_id:)
      end

      it_has_params(mean: 1.506, upper: 1.693, lower: 1.318)

      it_has_status_counts_of(in_control: 43, out_of_control_upper: 2, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [43, 45], lower_samples: [])
    end

    describe "R̄ rules" do
      subject do
        DB[:r_rules].where(instrument_id:)
      end

      it_has_params(mean: 0.32521, upper: 0.68749, lower: 0)

      it_has_status_counts_of(in_control: 45, out_of_control_upper: 0, out_of_control_lower: 0)
    end
  end

  describe "Engine Piston Diameter example" do
    instrument_id = 2

    describe "x̄s rules" do
      subject do
        DB[:x_bar_s_rules].where(instrument_id:)
      end

      it_has_params(mean: 74.001, upper: 74.014, lower: 73.988)

      it_has_status_counts_of(in_control: 25, out_of_control_upper: 0, out_of_control_lower: 0)
    end

    describe "s̄ rules" do
      subject do
        DB[:s_rules].where(instrument_id:)
      end

      it_has_params(mean: 0.0094, upper: 0.0196, lower: 0)

      it_has_status_counts_of(in_control: 25, out_of_control_upper: 0, out_of_control_lower: 0)
    end
  end

  describe "Orange Juice Can Inspection" do
    instrument_id = 3

    describe "p non-conformant rules" do
      subject do
        DB[:p_non_conformant_rules].where(instrument_id:)
      end

      it_has_params(mean: 0.2313, upper: 0.4102, lower: 0.0524)

      it_has_status_counts_of(in_control: 28, out_of_control_upper: 2, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [85, 93], lower_samples: [])
    end

    describe "np non-conformant rules" do
      subject do
        DB[:np_non_conformant_rules].where(instrument_id:)
      end

      it_has_params(mean: 11.565, upper: 20.510, lower: 2.620)

      it_has_status_counts_of(in_control: 28, out_of_control_upper: 2, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [85, 93], lower_samples: [])
    end
  end

  describe "Printed Circuit Boards" do
    instrument_id = 4

    describe "c rules" do
      subject do
        DB[:c_rules].where(instrument_id:)
      end

      it_has_params(mean: 19.85, upper: 33.22, lower: 6.48)

      it_has_status_counts_of(in_control: 24, out_of_control_upper: 1, out_of_control_lower: 1)

      it_is_out_of_control_at(upper_samples: [120], lower_samples: [106])
    end
  end

  describe "Mortgage Loan Cost" do
    instrument_id = 5

    describe "XmR X rules" do
      subject do
        DB[:xmr_x_rules].where(instrument_id:)
      end

      it_has_params(mean: 300.5, upper: 321.22, lower: 279.78)

      it_has_status_counts_of(in_control: 38, out_of_control_upper: 2, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [165, 166], lower_samples: [])
    end

    describe "XmR MR rules" do
      subject do
        DB[:xmr_mr_rules].where(instrument_id:)
      end

      it_has_params(mean: 7.79, upper: 25.45, lower: 0)

      it_has_status_counts_of(in_control: 39, out_of_control_upper: 1, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [165], lower_samples: [])
    end
  end

  describe "Normal Distribution With Shifting Mean" do
    instrument_id = 6

    describe "EWMA with fixed targets" do
      subject do
        DB.from(
          Sequel.lit('spc_reports.ewma_rules(?, ?, ?, ?)',
                     0.1, # weighting
                     2.7, # limits
                     10, # target mean
                     1 # target std dev
          )
        ).where(instrument_id:).order_by(:sample_id)
      end

      it_has_params(mean: 10, upper: 10.27, lower: 9.73)

      it_has_status_counts_of(in_control: 28, out_of_control_upper: 2, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [195, 196], lower_samples: [])

      # @formatter:off
      it_has_correct_values(column: :exponentially_weighted_moving_average, values: [
        9.945,    9.7495, 9.70355,  9.8992, 10.1253, 10.1307, 9.92167, 10.0755, 9.98796, 10.0232,
        9.92384, 10.0785, 10.1216, 10.0495, 10.0525, 9.98426, 10.0478,  10.074, 9.91864, 10.0108,
        10.0997, 10.0227, 10.2495, 10.3745, 10.3971, 10.4654, 10.4568, 10.5731, 10.6468, 10.6341
      ])
      # @formatter:on
    end

    describe "EWMA with computed targets" do
      subject do
        DB.from(
          Sequel.lit('spc_reports.ewma_rules(?, ?)',
                     0.1, # weighting
                     2.7 # limits
          )
        ).where(instrument_id:).order_by(:sample_id)
      end

      it_has_params(mean: 10.315, upper: 10.626, lower: 10.004)

      it_has_status_counts_of(in_control: 30, out_of_control_upper: 0, out_of_control_lower: 0)

      # @formatter:off
      it_has_correct_values(column: :exponentially_weighted_moving_average, values: [
        10.2285, 10.0046, 9.93318, 10.1058, 10.3112, 10.2981, 10.0723, 10.2111, 10.1099, 10.1329,
        10.0226, 10.1674, 10.2016, 10.1215, 10.1173, 10.0426, 10.1003, 10.1213, 9.96119, 10.0490,
        10.1341, 10.0537, 10.2773, 10.3996, 10.4196, 10.4857, 10.4751, 10.5896, 10.6616, 10.6474
      ])
      # @formatter:on
    end

    describe "Cusum with fixed target" do
      subject do
        DB.from(
          Sequel.lit('spc_reports.cusum_rules(?, ?, ?)',
                     0.5, # allowance
                     5, # decision interval
                     10 # target mean
          )
        ).where(instrument_id:).order_by(:sample_id)
      end

      describe "Calculating net deviation" do
        it_has_correct_values(column: :deviation, values: [
          # @formatter:off
          -0.55,  -2.01,  -0.71,  1.66,   2.16,
          0.18,   -1.96,  1.46,   -0.8,   0.34,
          -0.97,  1.47,   0.51,   -0.6,   0.08,
          -0.63,  0.62,   0.31,   -1.48,  0.84,
          0.9,    -0.67,  2.29,   1.5,    0.6,
          1.08,   0.38,   1.62,   1.31,   0.52
          # @formatter:on
        ])
      end

      describe "Calculating Cₙ" do
        it_has_correct_values(column: :c_n, values: [
          # @formatter:off
          -0.55,  -2.56,  -3.27,  -1.61,  0.55,
          0.73,   -1.23,  0.23,   -0.57,  -0.23,
          -1.2,   0.27,   0.78,   0.18,   0.26,
          -0.37,  0.25,   0.56,   -0.92,  -0.08,
          0.82,   0.15,   2.44,   3.94,   4.54,
          5.62,   6,      7.62,   8.93,   9.45
          # @formatter:on
        ])
      end

      describe "Calculating positive deviation" do
        it_has_correct_values(column: :deviation_plus, values: [
          # @formatter:off
          -1.05,  -2.51,  -1.21,  1.16,   1.66,
          -0.32,  -2.46,  0.96,   -1.3,   -0.16,
          -1.47,  0.97,   0.01,   -1.1,   -0.42,
          -1.13,  0.12,   -0.19,  -1.98,  0.34,
          0.4,    -1.17,  1.79,   1.0,    0.1,
          0.58,   -0.12,  1.12,   0.81,   0.02
          # @formatter:on
        ])
      end

      describe "Calculating C⁺" do
        it_has_correct_values(column: :c_plus, values: [
          # @formatter:off
          0,      0,      0,      1.16,   2.82,
          2.50,   0.04,   1.00,   0,      0,
          0,      0.97,   0.98,   0,      0,
          0,      0.12,   0,      0,      0.34,
          0.74,   0,      1.79,   2.79,   2.89,
          3.47,   3.35,   4.47,   5.28,   5.30
          # @formatter:on
        ])
      end

      describe "Calculating negative deviation" do
        it_has_correct_values(column: :deviation_minus, values: [
          # @formatter:off
          -0.05,  -1.51,  -0.21,  2.16,   2.66,
          0.68,   -1.46,  1.96,   -0.3,   0.84,
          -0.47,  1.97,   1.01,   -0.1,   0.58,
          -0.13,  1.12,   0.81,   -0.98,  1.34,
          1.4,    -0.17,  2.79,   2.0,    1.1,
          1.58,   0.88,   2.12,   1.81,   1.02
          # @formatter:on
        ])
      end

      describe "Calculating C⁻" do
        it_has_correct_values(column: :c_minus, values: [
          # @formatter:off
          -0.05,  -1.56,    -1.77,  0,      0,
          0,      -1.46,    0,      -0.3,   0,
          -0.47,  0,        0,      -0.1,   0,
          -0.13,  0,        0,      -0.98,  0,
          0,      -0.17,    0,      0,      0,
          0,      0,        0,      0,      0
          # @formatter:on
        ])
      end
    end
  end
end