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

class MontgomerySpec < Minitest::Spec
  def run(*args, &block)
    DB.transaction(rollback: :always, auto_savepoint: true) { super }
  end

  before do
    DB.rollback_on_exit(savepoint: true)

    DB.copy_into(:observed_systems, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/observed_systems.csv"))
    DB.copy_into(:instruments, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/instruments.csv"))
    DB.copy_into(:samples, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/samples.csv"))
    DB.copy_into(:measurements, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/measurements.csv"))
    DB.copy_into(:whole_unit_conformance_inspections, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/whole_unit_conformance_inspections.csv"))
    DB.copy_into(:per_unit_non_conformities_inspections, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/per_unit_non_conformities_inspections.csv"))
    DB.copy_into(:windows, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/windows.csv"))
    DB.copy_into(:window_relationships, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/window_relationships.csv"))
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

  describe "Flow Width example" do
    describe "x̄R rules" do
      subject do
        DB[:x_bar_r_rules].where(instrument_id: 1)
      end

      it_has_params(mean: 1.506, upper: 1.693, lower: 1.318)

      it_has_status_counts_of(in_control: 43, out_of_control_upper: 2, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [43, 45], lower_samples: [])
    end

    describe "R̄ rules" do
      subject do
        DB[:r_rules].where(instrument_id: 1)
      end

      it_has_params(mean: 0.32521, upper: 0.68749, lower: 0)

      it_has_status_counts_of(in_control: 45, out_of_control_upper: 0, out_of_control_lower: 0)
    end
  end

  describe "Engine Piston Diameter example" do
    describe "x̄s rules" do
      subject do
        DB[:x_bar_s_rules].where(instrument_id: 2)
      end

      it_has_params(mean: 74.001, upper: 74.014, lower: 73.988)

      it_has_status_counts_of(in_control: 25, out_of_control_upper: 0, out_of_control_lower: 0)
    end

    describe "s̄ rules" do
      subject do
        DB[:s_rules].where(instrument_id: 2)
      end

      it_has_params(mean: 0.0094, upper: 0.0196, lower: 0)

      it_has_status_counts_of(in_control: 25, out_of_control_upper: 0, out_of_control_lower: 0)
    end
  end

  describe "Orange Juice Can Inspection" do
    describe "p non-conformant rules" do
      subject do
        DB[:p_non_conformant_rules].where(instrument_id: 3)
      end

      it_has_params(mean: 0.2313, upper: 0.4102, lower: 0.0524)

      it_has_status_counts_of(in_control: 28, out_of_control_upper: 2, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [85, 93], lower_samples: [])
    end

    describe "np non-conformant rules" do
      subject do
        DB[:np_non_conformant_rules].where(instrument_id: 3)
      end

      it_has_params(mean: 11.565, upper: 20.510, lower: 2.620)

      it_has_status_counts_of(in_control: 28, out_of_control_upper: 2, out_of_control_lower: 0)

      it_is_out_of_control_at(upper_samples: [85, 93], lower_samples: [])
    end
  end

  describe "Printed Circuit Boards" do
    describe "c rules" do
      subject do
        DB[:c_rules].where(instrument_id: 4)
      end

      it_has_params(mean: 19.85, upper: 33.22, lower: 6.48)

      it_has_status_counts_of(in_control: 24, out_of_control_upper: 1, out_of_control_lower: 1)

      it_is_out_of_control_at(upper_samples: [120], lower_samples: [106])
    end
  end
end