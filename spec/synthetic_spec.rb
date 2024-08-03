require 'minitest/autorun'
require 'sequel'
require 'logger'

DB = Sequel.connect(
  adapter: 'postgres',
  host: 'localhost',
  port: 5432,
  database: 'spc',
  search_path: %w[spc_data spc_reports],
  logger: Logger.new('db.log', level: Logger::DEBUG)
)

class SyntheticSpec < Minitest::Spec
  def run(*args, &block)
    DB.transaction(rollback: :always, auto_savepoint: true) { super }
  end

  before do
    DB.rollback_on_exit(savepoint: true)

    DB.copy_into(:observed_systems, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/observed_systems.csv"))
    DB.copy_into(:instruments, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/instruments.csv"))
    DB.copy_into(:samples, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/samples.csv"))
    DB.copy_into(:measurements, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/measurements.csv"))
    DB.copy_into(:windows, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/windows.csv"))
    DB.copy_into(:window_relationships, format: :csv, data: File.read("#{Dir.pwd}/data/synthetic/window_relationships.csv"))
  end

  def self.it_has_params(mean:, upper:, lower:)
    it "has the correct mean" do
      assert_in_delta mean, subject.first[:center_line], 0.01
    end

    it "has the correct upper limit" do
      assert_in_delta upper, subject.first[:upper_limit], 0.01
    end

    it "has the correct lower limit" do
      assert_in_delta lower, subject.first[:lower_limit], 0.01
    end
  end

  def self.it_has_status_counts_of(in_control:, out_of_control_upper:, out_of_control_lower:)
    it "has the correct number of in-control points" do
      assert_equal in_control, subject.where(control_status: "in_control").count
    end

    it "has the correct number of out-of-control-upper points" do
      assert_equal out_of_control_upper, subject.where(control_status: "out_of_control_upper").count
    end

    it "has the correct number of out-of-control-lower points" do
      assert_equal out_of_control_lower, subject.where(control_status: "out_of_control_lower").count
    end
  end

  def self.it_is_out_of_control_at(upper_samples:, lower_samples:)
    upper_samples.each do |sample_id|
      it "it is out-of-control-upper at sample #{sample_id}" do
        control_status = subject.where(sample_id: sample_id).select(:control_status).first
        refute_nil control_status, "no matching out-of-control-upper sample was found for #{sample_id}"
        assert_equal "out_of_control_upper", control_status[:control_status]
      end
    end

    lower_samples.each do |sample_id|
      it "it is out-of-control-lower at sample #{sample_id}" do
        control_status = subject.where(sample_id: sample_id).select(:control_status).first
        refute_nil control_status, "no matching out-of-control-lower sample was found for #{sample_id}"
        assert_equal "out_of_control_lower", control_status[:control_status]
      end
    end
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
  end
end