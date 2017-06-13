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

      # HACK: the datetimes seem to have a weird formatting string
      # ("mm/dd/yyy") in the XLSX spreadsheet which has an extra "y" at the end.
      row.each do |cell|
        if cell.type == :date
          cell.instance_variable_set(:@format, "yyyy-mm-dd")
        end
      end

      csv << row.map(&:to_s)
    end
  end
end
