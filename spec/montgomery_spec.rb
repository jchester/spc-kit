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

  describe "x̄R rules" do
    describe "Flow Width example" do
      subject do
        DB[:x_bar_r_rules].where(instrument_id: 1)
      end

      it "has two upper out-of-control points" do
        control_count = subject.where(control_status: "out_of_control_upper").count
        assert_equal 2, control_count
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
  end
end