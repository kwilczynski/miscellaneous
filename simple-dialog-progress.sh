(
  while :; do
    printf "%.0f\n" \
      $(echo "scale=4 ; \
        (( $(wc -l files-media*.csv_error | tail -1 | awk '{ print $1 }') + \
           $(wc -l files-media*.csv_ok | tail -1 | awk '{ print $1 }')) / \
             52341945) * 100" | bc) ; \
       sleep 60 ; done \
) | dialog --title "File verification" --gauge "Processing ..." 10 60 0