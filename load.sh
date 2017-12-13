 # Find all the csv files containing the passed table name.
 # Strip the header from the 2nd and following files.
 # Load the data into the table.

start="+1";
for file  in downloads/csv/efile_COAK_*$@.csv ; do
    tail -n $start $file
    start="+2";
done | \
    csvsql --db postgresql:///disclosure-backend --tables $@ --insert
