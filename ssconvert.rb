# Usage:
# ./ssconvert.rb [input xlsx] [output filename]
#
# For example:
# ./ssconvert.rb stuff.xlsx out_%{sheet}.csv
#
# The '%{sheet}' will be interpolated with the name of the sheet.
require 'roo'

xlsx = Roo::Spreadsheet.open(ARGV[0])

$stderr.puts "Converting #{ARGV[0]} to a series of CSV files..."

xlsx.sheets.each do |sheet|
  output_filename = ARGV[1] % { sheet: sheet }

  $stderr.puts "  -> #{output_filename}"
  file = xlsx.sheet(sheet).to_enum(:each_row_streaming)

  headers = file.next

  CSV.open(output_filename, 'wb') do |csv|
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
