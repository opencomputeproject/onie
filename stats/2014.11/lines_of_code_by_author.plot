set terminal png transparent size 640,240
set size 1.0,1.0

set terminal png transparent size 640,480
set output 'lines_of_code_by_author.png'
set key left top
set xdata time
set timefmt "%s"
set format x "%Y-%m-%d"
set grid y
set ylabel "Lines"
set xtics rotate
set bmargin 6
plot 'lines_of_code_by_author.dat' using 1:2 title "david_yang" w lines, 'lines_of_code_by_author.dat' using 1:3 title "Curt Brune" w lines, 'lines_of_code_by_author.dat' using 1:4 title "Mandeep Sandhu" w lines, 'lines_of_code_by_author.dat' using 1:5 title "Doron Tsur" w lines, 'lines_of_code_by_author.dat' using 1:6 title "Will Kuo" w lines, 'lines_of_code_by_author.dat' using 1:7 title "QuantaSwitchONIE" w lines, 'lines_of_code_by_author.dat' using 1:8 title "alvinyang07334" w lines, 'lines_of_code_by_author.dat' using 1:9 title "Ellen Wang" w lines, 'lines_of_code_by_author.dat' using 1:10 title "Nikolay Shopik" w lines
