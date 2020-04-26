class CalculatorRunner
  def initialize
    @calculators = []
  end

  def fetch_all!
    while (calculator_class = next_calculator_with_dependencies_met)
      puts "Running calculator: #{calculator_class}"
      calculator_class
        .new(
          candidates: Candidate.all,
          ballot_measures: Referendum.all,
          committees: Committee.all
        )
        .fetch
      @calculators.delete(calculator_class)
    end

    if @calculators.any?
      error = "Could not meet dependencies for calculators:\n" +
        @calculators.map do |c|
          "  #{c} (Unmet dependencies: " + unmet_dependencies(c).map do |d|
            "#{d[:model].name} #{d[:calculation]}"
          end.join(", ") + ")"
        end.join("\n")
      raise error
    end
  end

  def load_calculators(calculator_directory)
    # load calculators dynamically, assume each one defines a class given by its
    # filename. E.g. calculators/foo_calculator.rb would define "FooCalculator"
    Dir.glob(calculator_directory).each do |calculator_file|
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

  private

  def next_calculator_with_dependencies_met
    @calculators.find do |calculator_class|
      if calculator_class.respond_to?(:dependencies)
        # If the calculator has defined dependencies, don't run the calculator
        # until its dependencies have been met.
        unmet_dependencies(calculator_class).none?
      else
        # If the calculator has no defined dependencies, assume that it can be
        # run in any order.
        calculator_class
      end
    end
  end

  def unmet_dependencies(calculator_class)
    calculator_class.dependencies.find_all do |dependency|
      dependency[:model].processed_calculations.exclude?(dependency[:calculation])
    end
  end
end
