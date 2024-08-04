require 'minitest/autorun'
require 'minitest/hooks/default'
require 'sequel'
require 'logger'
require 'testcontainers/postgres'

class SpcSpec < Minitest::Spec
  before(:all) do
    @postgres_container = Testcontainers::PostgresContainer.new
    @postgres_container.start

    @db = Sequel.connect(
      adapter: 'postgres',
      host: @postgres_container.host,
      port: @postgres_container.first_mapped_port,
      username: 'test',
      password: 'test',
      database: 'test',
      search_path: %w[spc_data spc_reports],
      logger: Logger.new('db.log', level: Logger::DEBUG)
    )

    @db.transaction(rollback: :always, auto_savepoint: true) {  }

    @db.run(File.read("#{Dir.pwd}/../sql/postgresql/01-data-schema.sql"))
    @db.run(File.read("#{Dir.pwd}/../sql/postgresql/02-spc-intermediates-schema.sql"))
    @db.run(File.read("#{Dir.pwd}/../sql/postgresql/03-spc-reports-schema.sql"))
  end

  after(:all) do
    @postgres_container.stop
    @postgres_container.delete
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

  def self.it_has_correct_ewma_values(values)
    it "has the correct EWMA values" do
      paired_array = values.zip(subject.select_map(:exponentially_weighted_moving_average))

      paired_array.each do |value1, value2|
        assert_in_delta value1, value2
      end
    end
  end
end