require 'minitest/autorun'
require 'sequel'
require 'logger'

DB = Sequel.connect(
  adapter: 'postgres',
  host: 'localhost',
  port: 5432,
  database: 'spc',
  search_path: %w[spc_data spc_reports],
  logger: Logger.new('db.log', level: Logger::DEBUG),
  max_connections: 20
)

class SpcSpec < Minitest::Spec
  def run(*args, &block)
    DB.transaction(rollback: :always, auto_savepoint: true) { super }
  end

  def self.it_has_params(mean:, upper:, lower:)
    it "has the correct mean" do
      assert_in_delta mean, subject.first[:data_center_line], 0.01
    end

    it "has the correct upper limit" do
      assert_in_delta upper, subject.first[:data_upper_limit], 0.01
    end

    it "has the correct lower limit" do
      assert_in_delta lower, subject.first[:data_lower_limit], 0.01
    end
  end

  def self.it_has_status_counts_of(in_control:, out_of_control_upper:, out_of_control_lower:)
    it "has the correct number of in-control points" do
      assert_equal in_control, subject.where(rule_in_control: true).count
    end

    it "has the correct number of out-of-control-upper points" do
      assert_equal out_of_control_upper, subject.where(rule_out_of_control_upper: true).count
    end

    it "has the correct number of out-of-control-lower points" do
      assert_equal out_of_control_lower, subject.where(rule_out_of_control_lower: true).count
    end
  end

  def self.it_is_out_of_control_at(upper_samples:, lower_samples:)
    upper_samples.each do |id_sample|
      it "it is out-of-control-upper at sample #{id_sample}" do
        control_status = subject.where(id_sample:).select(:rule_out_of_control_upper).first
        refute_nil control_status, "no matching out-of-control-upper sample was found for #{id_sample}"
        assert_equal true, control_status[:rule_out_of_control_upper]
      end
    end

    lower_samples.each do |id_sample|
      it "it is out-of-control-lower at sample #{id_sample}" do
        control_status = subject.where(id_sample:).select(:rule_out_of_control_lower).first
        refute_nil control_status, "no matching out-of-control-lower sample was found for #{id_sample}"
        assert_equal true, control_status[:rule_out_of_control_lower]
      end
    end
  end

  def self.it_has_correct_values(column:, values:)
    it "has the correct values for #{column}" do
      paired_array = values.zip(subject.select_map(column))

      paired_array.each do |value1, value2|
        assert_in_delta value1, value2
      end
    end
  end
end