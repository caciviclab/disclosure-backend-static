class CalculatorRunner
  def initialize
    @calculators = []
  end

  def fetch_all!
    @calculators.each do |calculator_class|
      calculator_class
        .new(
          candidates: Candidate.all,
          ballot_measures: Referendum.all,
          committees: Committee.all
        )
        .fetch
    end
  end

  def load_calculators(calculator_directory)
    # load calculators dynamically, assume each one defines a class given by its
    # filename. E.g. calculators/foo_calculator.rb would define "FooCalculator"
    Dir.glob(calculator_directory).each do |calculator_file|
      puts calculator_file
      basename = File.basename(calculator_file.chomp('.rb'))
      class_name = ActiveSupport::Inflector.classify(basename)
      begin
        calculator_class = class_name.constantize
        @calculators << calculator_class
      rescue NameError => ex
        if ex.message =~ /uninitialized constant #{class_name}/
          $stderr.puts "ERROR: Undefined constant #{class_name}, expected it to be "\
            "defined in #{calculator_file}"
          puts ex.message
          exit 1
        else
          raise
        end
      end
    end

    self
  end
end
