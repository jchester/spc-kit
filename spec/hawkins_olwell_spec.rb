require_relative 'spc_spec'

class HawkinsOlwellSpec < SpcSpec
  before do
    DB.copy_into(:observed_systems, format: :csv, data: File.read("#{Dir.pwd}/data/hawkinsolwell/observed_systems.csv"))
    DB.copy_into(:instruments, format: :csv, data: File.read("#{Dir.pwd}/data/hawkinsolwell/instruments.csv"))
    DB.copy_into(:windows, format: :csv, data: File.read("#{Dir.pwd}/data/hawkinsolwell/windows.csv"))
    DB.copy_into(:window_relationships, format: :csv, data: File.read("#{Dir.pwd}/data/hawkinsolwell/window_relationships.csv"))
    DB.copy_into(:samples, format: :csv, data: File.read("#{Dir.pwd}/data/hawkinsolwell/samples.csv"))
    DB.copy_into(:measurements, format: :csv, data: File.read("#{Dir.pwd}/data/hawkinsolwell/measurements.csv"))
  end

  describe "Bolt Diameter example §2.2.4" do
    id_instrument = 1

    subject do
      DB.from(
        Sequel.lit('spc_reports.cusum_rules(?, ?, ?)',
                   0.05, # allowance
                   1.3467, # decision interval
                   5 # target mean
        )
      ).where(instrument_id:).order_by(:sample_id)
    end

    describe "Calculating C⁺" do
      it_has_correct_values(column: :c_plus, values: [
        # @formatter:off
        0,        0,        0,        0,        0,
        0,        0,        0,        0,        0,
        0,        0,        0,        0,        0,
        0,        0.087849, 0.023697, 0,        0,
        0,        0.082098, 0,        0,        0,
        0,        0.1603,   0,        0,        0,
        0,        0.443115, 0.574412, 0.395502, 0.478525,
        0.87418,  0.728289, 0.511685, 0.387747, 0.627845,
        0.380746, 0.633514, 0.601753, 0.806817, 1.148206,
        0.953768, 1.067542, 1.032842, 1.632435, 1.675285
        # @formatter:on
      ])
    end
  end
end

