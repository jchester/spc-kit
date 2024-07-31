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
    DB.copy_into(:windows, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/windows.csv"))
    DB.copy_into(:window_relationships, format: :csv, data: File.read("#{Dir.pwd}/data/montgomery/window_relationships.csv"))
  end

  describe "Flow Width example" do
    describe "x̄R rules" do
      subject do
        DB[:x_bar_r_rules].where(instrument_id: 1)
      end

      it "has the correct mean" do
        mean = subject.select(:center_line).first[:center_line]
        assert_in_delta 1.506, mean
      end

      it "has the correct upper limit" do
        upper_limit = subject.select(:upper_limit).first[:upper_limit]
        assert_in_delta 1.693, upper_limit
      end

      it "has the correct lower limit" do
        lower_limit = subject.select(:lower_limit).first[:lower_limit]
        assert_in_delta 1.318, lower_limit
      end

      it "is out of control at samples 43 and 45" do
        control_43 = subject.where(sample_id: 43).select(:control_status).first
        assert_equal "out_of_control_upper", control_43[:control_status]

        control_45 = subject.where(sample_id: 43).select(:control_status).first
        assert_equal "out_of_control_upper", control_45[:control_status]
      end

      it "has no out-of-control lower points" do
        control_count = subject.where(control_status: "out_of_control_lower").count
        assert_equal 0, control_count
      end

      it "has 43 in-control points" do
        control_count = subject.where(control_status: "in_control").count
        assert_equal 43, control_count
      end
    end

    describe "R̄ rules" do
      subject do
        DB[:r_rules].where(instrument_id: 1)
      end

      it "has the correct mean" do
        mean = subject.select(:center_line).first[:center_line]
        assert_in_delta 0.32521, mean
      end

      it "has the correct upper limit" do
        upper_limit = subject.select(:upper_limit).first[:upper_limit]
        assert_in_delta 0.68749, upper_limit
      end

      it "has the correct lower limit" do
        lower_limit = subject.select(:lower_limit).first[:lower_limit]
        assert_equal 0, lower_limit
      end

      it "has 45 in-control points out of 45" do
        control_count = subject.where(control_status: "in_control").count
        assert_equal 45, control_count
      end
    end
  end
end