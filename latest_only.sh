	echo \
		DELETE\
		FROM \"$1\" e\
		'WHERE "Report_Num" < (SELECT MAX("Report_Num")' FROM \"$1\" m\
		'GROUP BY "Filer_ID", "From_Date"
		HAVING  e."Filer_ID" = m."Filer_ID" AND e."From_Date" = m."From_Date");' \
      | psql disclosure-backend
