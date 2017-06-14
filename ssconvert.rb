require 'roo'

def output_filename(sheet)
  "inputs/efile_COAK_2016_#{sheet}.csv"
end

xlsx = Roo::Spreadsheet.open(ARGV[0])

$stderr.puts "Converting #{ARGV[0]} to a series of CSV files..."

xlsx.sheets.each do |sheet|
  out = output_filename(sheet)

  $stderr.puts "  -> #{out}"
  file = xlsx.sheet(sheet).to_enum(:each_row_streaming)

  headers = file.next

  CSV.open(out, 'wb') do |csv|
    csv << headers

    loop do
      row = file.next

      # HACK: the datetimes in the XLSX spreadsheet seem to have a weird
      # formatting string ("mm/dd/yyy") which has an extra "y" at the end. By
      # converting the format string to "yyyy-mm-dd" we can get a date formatted
      # properly for import into the database.
      row.each do |cell|
        if cell.type == :date
          cell.instance_variable_set(:@format, "yyyy-mm-dd")
        end
      end

      csv << row.map(&:to_s)
    end
  end
end
