#!/bin/bash

start_t=$(date +%s)
echo -e "\nCzas rozpoczęcia skryptu: $(date +%F_%H:%M:%S)"

RPATH=/root/bpi
G_PATH=/root/gielda3
WWW_PATH=/usr/share/nginx/html/stock
#plik z datami, dla których ma być wykonywane obliczenie bpi:
#FDATES=/root/bpi/dates.txt
FDATES=$G_PATH/dates.txt.diff
WIG20=$RPATH/wig20/wig20_sklad.txt

PIDFILE=$RPATH/lockfile.pid

if [ -f $PIDFILE ]
then
  PID=$(cat $PIDFILE)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    echo $$ > $PIDFILE
    if [ $? -ne 0 ]
    then
      echo "Could not create PID file"
      exit 1
    fi
  fi
else
  echo $$ > $PIDFILE
  if [ $? -ne 0 ]
  then
    echo "Could not create PID file"
    exit 1
  fi
fi

SUB_MAIL11="Bledna zawartosc pliku spolki w katalogu LAST"
TRESC_MAIL11="W LAST jest plik spolki $y ale zawartosc nie jest ani B ani S !!!"

SUB_MAIL12="Bledna zawartosc pliku spolki w katalogu LAST"
TRESC_MAIL12="W LAST jest plik spolki $y ale zawartosc nie jest ani BU, anie BE ani NA !!!"

SUB_MAIL2="Zmienil sie sygnal dla BPI"
TRESC_MAIL2="Zmienil sie sygnal dla BPI z X na O lub z O na X. Najnowszy sygnal jest w zał."

SUB_MAIL3="Zmienil sie sygnal dla BPI TREND !!!"
TRESC_MAIL3="Zmienil sie sygnal dla BPI TREND (TREND, nie samo BPI!!!) z X na O lub z O na X. Najnowszy sygnal jest w zał."

SUB_MAIL4="Zmienil sie sygnal Buy/Sell dla BPI"
TRESC_MAIL4="Zmienil sie sygnal Buy/Sell dla BPI z Buy na Sell lub z Sell na Buy. Najnowszy sygnal jest w zał."

SUB_MAIL5="Zmienil sie sygnal Buy/Sell dla BPI TREND !!!"
TRESC_MAIL5="Zmienil sie sygnal dla BPI TREND (TREND, nie samo BPI!!!) z Buy na Sell lub z Sell na Buy. Najnowszy sygnal jest w zał."

sender1=root@katkat.tk
receiver1=@gmail.com


KOMUNIKAT1="$0: wywołanie skryptu: ./bpi.sh (normal|2proc) (close|high-low) (sendemail|notsendemail) (first|notfirst)"

COMM="-------------------------------------------"
COMM2="++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

function quit_script {
        echo "Czas zakończenia skryptu: $(date +%F_%H:%M:%S)"
        end_t=$(date +%s)
        echo "Skrypt wykonywał się $(expr $end_t - $start_t) sekund"
        echo -e "\n######################################################################################\n"
}

cd $RPATH

if [ $# -ne 4 ]
then
        echo $KOMUNIKAT1
        quit_script
        exit 1
else
        case "$1" in
          normal)
                skala="normal"
                echo "PARAMETR1: $1"
                ;;
          2proc)
                skala="2proc"
                echo "PARAMETR1: $1"
                ;;
          *)
                echo $KOMUNIKAT1
                quit_script
                exit 1
        esac

        case "$2" in
          close)
                tryb="-bez-zer"		#bez 4 zer, tzn "grep -v "PLN,0,0,0,0,""
		tryb2="close"
                echo "PARAMETR2: $2"
                ;;
	  high-low)
		tryb=""			# bez 3 zer, tzn "grep -v "PLN,0,0,0,""
		tryb2="high-low"
		echo "PARAMETR2: $2"
		;;
          *)
                echo $KOMUNIKAT1
                quit_script
                exit 1
        esac

        case "$3" in
          sendemail|notsendemail)
                ifsend=$3
                echo "PARAMETR3: $3"
                ;;
          *)
                echo $KOMUNIKAT1
                quit_script
                exit 1
        esac

        case "$4" in
          first|notfirst)
                iffirst=$4
                echo "PARAMETR4: $4"
                ;;
          *)
                echo $KOMUNIKAT1
                quit_script
                exit 1
        esac
fi

if [[ $iffirst == "first" ]]
then
        cd $RPATH
        echo $COMM2
        echo -e "Sprzątam zawartość katalogu $RPATH:"
        ls -l

##################
# IF FIRST:
#
# usuwamy stare rzeczy:
#
	rm -rf $RPATH/ls_isin
	rm -rf $RPATH/buy
	rm -rf $RPATH/sell
	rm -rf $RPATH/bull
	rm -rf $RPATH/bear
	rm -rf $RPATH/zero
	rm -rf $RPATH/last_signal
	rm -rf $RPATH/diff
	timestamp=$(date +%F_%H:%M:%S)
	mkdir $RPATH/bkp-$timestamp
	mkdir $RPATH/bkp-$timestamp/logs
	mv $RPATH/logs/*	$RPATH/bkp-$timestamp/logs/
	mv $RPATH/000-bpi*.csv $RPATH/bkp-$timestamp/
	mv $WWW_PATH/wykresy/*.txt $RPATH/bkp-$timestamp/
	rm -rf $RPATH/temp
	rm -rf $RPATH/logs


        echo $COMM2
        echo -e "Posprzatane:"
        ls -l

# i tworzymy raz jeszcze:
#
	mkdir $RPATH/ls_isin
	mkdir $RPATH/buy
	mkdir $RPATH/sell
	mkdir $RPATH/bull
	mkdir $RPATH/bear
	mkdir $RPATH/zero
	mkdir $RPATH/last_signal
	mkdir $RPATH/temp
        mkdir $RPATH/logs
	mkdir $RPATH/diff

        echo $COMM2
        echo -e "Przygotowane:"
        ls -l
##################
fi

# sprawdzam czy plik z datami nie jest pusty:
if [ $(cat $FDATES | wc -l) -le 0 ]
then
        echo -e "\nPlik z datami pusty. Wychodze.\n"
        quit_script
	exit 0
fi


#jesli plik NIE istnieje to go utworz
# potrzebne do zainicjowania
if [ ! -e $RPATH/last_signal/000-bpi.$skala.$tryb2.XO ]
then
        echo "O" > $RPATH/last_signal/000-bpi.$skala.$tryb2.XO
fi

if [ ! -e $RPATH/last_signal/000-bpi_trend.$skala.$tryb2.XO ]
then
        echo "O" > $RPATH/last_signal/000-bpi_trend.$skala.$tryb2.XO
fi

if [ ! -e $RPATH/last_signal/000-bpi.$skala.$tryb2.BS ]
then
        echo "S" > $RPATH/last_signal/000-bpi.$skala.$tryb2.BS
fi

if [ ! -e $RPATH/last_signal/000-bpi_trend.$skala.$tryb2.BS ]
then
        echo "S" > $RPATH/last_signal/000-bpi_trend.$skala.$tryb2.BS
fi


#----------------------------------------------------------------------------------------------------------

j=1

# dla każdej nowej daty, która sie pojawiła podczas ostatniego sciagania notowań:
for x in `awk '{print $1}' $FDATES`
do
	b=0
	bull=0
	s=0
	bear=0
	na=0

	# sprawdzamy jakie spolki podczas daty 'x' byly obecne:
	cat $G_PATH/notowania/$x.csv | grep -v "Data,Nazwa,ISIN,Waluta," | awk -F, '{ print $3 }' | grep -v ^$ | sort | uniq > $RPATH/ls_isin/ls_isin.$x.$skala.$tryb2.txt
	# do k zapisujemy liczbe tych spolek:
	k=$(cat $RPATH/ls_isin/ls_isin.$x.$skala.$tryb2.txt | wc -l)
	# wyswietlamy komunikat:
	echo "w dniu $x - liczba spółek to $k"			# ZAKOMENTOWAC

	# dla kazdej spółki w tym dniu:
	for y in `awk '{print $1}' $RPATH/ls_isin/ls_isin.$x.$skala.$tryb2.txt`
	do
		# zapisujemy jej historyczne notowania OD TEJ DATY do początkowej skąd mamy jej notowania do pliku tymczasowego:
		cat $G_PATH/isin$tryb/$y.csv | grep -B 100000 $x > $RPATH/temp/$y.$x.$skala.$tryb2.csv
		spolka=$(tail -n 1 ../gielda3/isin$tryb/$y.csv | awk -F, '{ print $2}')

		/usr/bin/Rscript b3-$skala-$tryb2.R $RPATH/temp/$y.$x.$skala.$tryb2.csv > $WWW_PATH/wykresy/$spolka-$y-$skala-$tryb2.txt
#----------------------------------------------------------------------------------------------------------
		if [ $(head -c 1 $WWW_PATH/wykresy/$spolka-$y-$skala-$tryb2.txt) == "B" ]
		then
			#echo "Buy"	# zakomentować ?
			# zwiększamy o 1 do licznia spólek z sygnalem 'buy':
			echo "Liczba spolek z sygnalem BUY obecnie to: $((b=b+1)):"
			# do celów inforacyjnych zapisujemy jakie spolki w dniu $x maja sygnal 'buy':
			echo "$y - $spolka" >> $RPATH/buy/buy.$x.$skala.$tryb2.txt
		# analogicznie dla sygnalu 'sell'
		elif [ $(head -c 1 $WWW_PATH/wykresy/$spolka-$y-$skala-$tryb2.txt) == "S" ]
		then
			#echo "Sell"	# zakomentować ?
                        echo "Liczba spolek z sygnalem SELL obecnie to: $((s=s+1)):"
                        echo "$y - $spolka" >> $RPATH/sell/sell.$x.$skala.$tryb2.txt
		else
			echo "!!!"
			echo "!!!!!! nie BUY i nie SELL !!!!!!!!!!!"
			echo "!!!"
                        if [[ $ifsend == sendemail ]]
			then
                               	echo $TRESC_MAIL11 | mail -s "$SUB_MAIL11" \
				-a "$WWW_PATH/wykresy/$spolka-$y-$skala-$tryb2.txt" \
                                -r $sender1 \
                                $receiver1
			fi
		fi
#=============================================================================================================
		if [ $(head -n 2 $WWW_PATH/wykresy/$spolka-$y-$skala-$tryb2.txt | tail -c 3) == "BU" ]
                then
                        echo "Liczba spolek z sygnalem BULL obecnie to: $((bull=bull+1)):"
                        echo "$y - $spolka" >> $RPATH/bull/bull.$x.$skala.$tryb2.txt

                elif [ $(head -n 2 $WWW_PATH/wykresy/$spolka-$y-$skala-$tryb2.txt | tail -c 3) == "BE" ]
                then
                       echo "Liczba spolek z sygnalem BEAR obecnie to: $((bear=bear+1)):"
                       echo "$y - $spolka" >> $RPATH/bear/bear.$x.$skala.$tryb2.txt
                # jesli nie sell i buy to:
                elif [ $(head -n 2 $WWW_PATH/wykresy/$spolka-$y-$skala-$tryb2.txt | tail -c 3) == "NA" ]
                then
                       echo "Liczba spolek z sygnalem NA obecnie to: $((na=na+1)):"
                       echo "$y - $spolka - NA" >> $RPATH/bear/bear.$x.$skala.$tryb2.txt
                # jesli nie sell i buy to:

                else
                        echo "!!!"
                        echo "!!!!!! nie BULL i nie BEAR i nie NA !!!!!!!!!!!"
                        echo "!!!"
                        if [[ $ifsend == sendemail ]]
                        then
                                echo $TRESC_MAIL12 | mail -s "$SUB_MAIL12" \
				-a "$WWW_PATH/wykresy/$spolka-$y-$skala-$tryb2.txt" \
                                -r $sender1 \
                                $receiver1
                        fi
                fi

		echo "$y - $spolka"
		echo "------------------------"
		# usuwamy plik tymczasowy:
		rm -f $RPATH/temp/$y.$x.$skala.$tryb2.csv

	done

        echo "Liczba wszystkich spółek w dniu $x to: $k"
	
	# obliczamy i wyświetlamy wskaźnik BPI dla daty $x:
        echo "--- 5y ---"
	echo "Liczba spółek z sygnałem BUY w dniu $x to: $b"
	echo "Liczba spółek z sygnałem SELL w dniu $x to: $s"
	echo "Liczba spółek z sygnałem BULL w dniu $x to: $bull"
	echo "Liczba spółek z sygnałem BEAR w dniu $x to: $bear"
	echo "Liczba spółek bez sygnalu BULL lub BEAR w dniu $x to: $na"
	bpi=$(echo  "scale=2;$b*100/$k" | bc)
	bpi_trend=$(echo  "scale=2;$bull*100/$k" | bc)
	echo "BPI w dniu $x wynosi $bpi"
	echo "BPI Trend w dniu $x wynosi $bpi_trend"
	echo "$x,$bpi,$bpi" >> $RPATH/000-bpi.$skala.$tryb2.csv
	echo "$x,$bpi_trend,$bpi_trend" >> $RPATH/000-bpi_trend.$skala.$tryb2.csv

        buy_wig20=$(grep -f $RPATH/wig20/wig20_sklad.txt $RPATH/buy/buy.$x.2proc.close.txt | wc -l)
	bull_wig20=$(grep -f $RPATH/wig20/wig20_sklad.txt $RPATH/bull/bull.$x.2proc.close.txt | wc -l)
	bpi_wig20=$(echo  "scale=2;$buy_wig20*100/20" | bc)
	bpi_trend_wig20=$(echo  "scale=2;$bull_wig20*100/20" | bc)
        echo "BPI w dniu $x dla WIG20 wynosi $bpi_wig20"
	echo "BPI Trend w dniu $x dla WIG20 wynosi $bpi_trend_wig20"
	echo "$x,$bpi_wig20,$bpi_wig20" >> $RPATH/000-bpi_wig20.$skala.$tryb2.csv
	echo "$x,$bpi_trend_wig20,$bpi_trend_wig20" >> $RPATH/000-bpi_trend_wig20.$skala.$tryb2.csv

        buy_wig30=$(grep -f $RPATH/wig20/wig30_sklad.txt $RPATH/buy/buy.$x.2proc.close.txt | wc -l)
        bull_wig30=$(grep -f $RPATH/wig20/wig30_sklad.txt $RPATH/bull/bull.$x.2proc.close.txt | wc -l)
        bpi_wig30=$(echo  "scale=2;$buy_wig30*100/30" | bc)
        bpi_trend_wig30=$(echo  "scale=2;$bull_wig30*100/30" | bc)
        echo "BPI w dniu $x dla WIG30 wynosi $bpi_wig30"
        echo "BPI Trend w dniu $x dla WIG30 wynosi $bpi_trend_wig30"
        echo "$x,$bpi_wig30,$bpi_wig30" >> $RPATH/000-bpi_wig30.$skala.$tryb2.csv
        echo "$x,$bpi_trend_wig30,$bpi_trend_wig30" >> $RPATH/000-bpi_trend_wig30.$skala.$tryb2.csv

        buy_mwig40=$(grep -f $RPATH/wig20/mwig40_sklad.txt $RPATH/buy/buy.$x.2proc.close.txt | wc -l)
        bull_mwig40=$(grep -f $RPATH/wig20/mwig40_sklad.txt $RPATH/bull/bull.$x.2proc.close.txt | wc -l)
        bpi_mwig40=$(echo  "scale=2;$buy_mwig40*100/40" | bc)
        bpi_trend_mwig40=$(echo  "scale=2;$bull_mwig40*100/40" | bc)
        echo "BPI w dniu $x dla mWIG40 wynosi $bpi_mwig40"
        echo "BPI Trend w dniu $x dla mWIG40 wynosi $bpi_trend_mwig40"
        echo "$x,$bpi_mwig40,$bpi_mwig40" >> $RPATH/000-bpi_mwig40.$skala.$tryb2.csv
        echo "$x,$bpi_trend_mwig40,$bpi_trend_mwig40" >> $RPATH/000-bpi_trend_mwig40.$skala.$tryb2.csv

        buy_swig80=$(grep -f $RPATH/wig20/swig80_sklad.txt $RPATH/buy/buy.$x.2proc.close.txt | wc -l)
        bull_swig80=$(grep -f $RPATH/wig20/swig80_sklad.txt $RPATH/bull/bull.$x.2proc.close.txt | wc -l)
        bpi_swig80=$(echo  "scale=2;$buy_swig80*100/80" | bc)
        bpi_trend_swig80=$(echo  "scale=2;$bull_swig80*100/80" | bc)
        echo "BPI w dniu $x dla sWIG80 wynosi $bpi_swig80"
        echo "BPI Trend w dniu $x dla sWIG80 wynosi $bpi_trend_swig80"
        echo "$x,$bpi_swig80,$bpi_swig80" >> $RPATH/000-bpi_swig80.$skala.$tryb2.csv
        echo "$x,$bpi_trend_swig80,$bpi_trend_swig80" >> $RPATH/000-bpi_trend_swig80.$skala.$tryb2.csv


#----------------------------------------------------------------------------------------------------------------

done
Rscript bpi.R 000-bpi.$skala.$tryb2.csv > $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt
Rscript bpi.R 000-bpi_trend.$skala.$tryb2.csv > $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt

Rscript bpi.R 000-bpi_wig20.$skala.$tryb2.csv > $WWW_PATH/wykresy/0050-bpi_wig20.$skala.$tryb2.txt
Rscript bpi.R 000-bpi_trend_wig20.$skala.$tryb2.csv > $WWW_PATH/wykresy/0050-bpi_trend_wig20.$skala.$tryb2.txt
Rscript bpi.R 000-bpi_wig30.$skala.$tryb2.csv > $WWW_PATH/wykresy/0060-bpi_wig30.$skala.$tryb2.txt
Rscript bpi.R 000-bpi_trend_wig30.$skala.$tryb2.csv > $WWW_PATH/wykresy/0060-bpi_trend_wig30.$skala.$tryb2.txt
Rscript bpi.R 000-bpi_mwig40.$skala.$tryb2.csv > $WWW_PATH/wykresy/0070-bpi_mwig40.$skala.$tryb2.txt
Rscript bpi.R 000-bpi_trend_mwig40.$skala.$tryb2.csv > $WWW_PATH/wykresy/0070-bpi_trend_mwig40.$skala.$tryb2.txt
Rscript bpi.R 000-bpi_swig80.$skala.$tryb2.csv > $WWW_PATH/wykresy/0080-bpi_swig80.$skala.$tryb2.txt
Rscript bpi.R 000-bpi_trend_swig80.$skala.$tryb2.csv > $WWW_PATH/wykresy/0080-bpi_trend_swig80.$skala.$tryb2.txt

Rscript bpi_4box.R 000-bpi.$skala.$tryb2.csv > $WWW_PATH/wykresy/004-bpi_4box.txt
Rscript bpi_4box.R 000-bpi_trend.$skala.$tryb2.csv > $WWW_PATH/wykresy/004-bpi_trend_4box.txt

#Rscript bpi-plot.R 000-bpi_wig20.$skala.$tryb2.csv > $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt
#Rscript bpi-plot.R 000-bpi_trend_wig20.$skala.$tryb2.csv > $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt
#Rscript bpi-plot.R 000-bpi_wig30.$skala.$tryb2.csv > $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt
#Rscript bpi-plot.R 000-bpi_trend_wig30.$skala.$tryb2.csv > $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt
#Rscript bpi-plot.R 000-bpi_mwig40.$skala.$tryb2.csv > $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt
#Rscript bpi-plot.R 000-bpi_trend_mwig40.$skala.$tryb2.csv > $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt
#Rscript bpi-plot.R 000-bpi_swig80.$skala.$tryb2.csv > $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt
#Rscript bpi-plot.R 000-bpi_trend_swig80.$skala.$tryb2.csv > $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt

echo -e "\n--- WIG: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIGDIV: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIGDIV.csv >> $WWW_PATH/indexy/$x-WIG.txt
echo -e "\n--- WIG20: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG20.csv >> $WWW_PATH/indexy/$x-WIG.txt
echo -e "\n--- WIG20TR: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG20TR.csv >> $WWW_PATH/indexy/$x-WIG.txt
echo -e "\n--- WIG30: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG30.csv >> $WWW_PATH/indexy/$x-WIG.txt
echo -e "\n--- WIG30TR: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG30TR.csv >> $WWW_PATH/indexy/$x-WIG.txt
echo -e "\n--- MWIG40: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/MWIG40.csv >> $WWW_PATH/indexy/$x-WIG.txt
echo -e "\n--- MWIG40TR: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/MWIG40TR.csv >> $WWW_PATH/indexy/$x-WIG.txt
echo -e "\n--- SWIG80: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/SWIG80.csv >> $WWW_PATH/indexy/$x-WIG.txt
echo -e "\n--- SWIG80TR: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
Rscript b3-2proc-close-plot.R $G_PATH/indexy/SWIG80TR.csv >> $WWW_PATH/indexy/$x-WIG.txt

#echo -e "\n--- WIG-BANKI: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-BANKI.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-BUDOW: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-BUDOW.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-CEE: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-CEE.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-CHEMIA: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-CHEMIA.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-ENERG: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-ENERG.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-GORNIC: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-GORNIC.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-INFO: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-INFO.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-LEKI: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-LEKI.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-MEDIA: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-MEDIA.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-MOTO: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-MOTO.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-NRCHOM: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-NRCHOM.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-ODZIEZ: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-ODZIEZ.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-PALIWA: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-PALIWA.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-POLAND: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-POLAND.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-SPOZYW: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-SPOZYW.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-TELKOM: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-TELKOM.csv >> $WWW_PATH/indexy/$x-WIG.txt
#echo -e "\n--- WIG-UKRAIN: ----------------\n" >> $WWW_PATH/indexy/$x-WIG.txt
#Rscript b3-2proc-close-plot.R $G_PATH/indexy/WIG-UKRAIN.csv >> $WWW_PATH/indexy/$x-WIG.txt

#-WIG-----------------------------------------------------#
cat $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/001-bpi.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/001-bpi.txt
cat $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/001-bpi.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/001-bpi.txt
cat $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/001-bpi.txt
cat $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/001-bpi.txt
cat $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/001-bpi.txt

cat $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/001-bpi_trend.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/001-bpi_trend.txt
cat $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/001-bpi_trend.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/001-bpi_trend.txt
cat $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/001-bpi_trend.txt
cat $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/001-bpi_trend.txt
cat $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/001-bpi_trend.txt

#-WIG20-----------------------------------------------------#
cat $WWW_PATH/wykresy/0050-bpi_wig20.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0050-bpi_wig20.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0050-bpi_wig20.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0050-bpi_wig20.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0050-bpi_wig20.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt

cat $WWW_PATH/wykresy/0050-bpi_trend_wig20.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0050-bpi_trend_wig20.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0050-bpi_trend_wig20.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0050-bpi_trend_wig20.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0050-bpi_trend_wig20.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt

#-WIG30-----------------------------------------------------#
cat $WWW_PATH/wykresy/0060-bpi_wig30.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0060-bpi_wig30.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0060-bpi_wig30.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0060-bpi_wig30.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0060-bpi_wig30.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt

cat $WWW_PATH/wykresy/0060-bpi_trend_wig30.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0060-bpi_trend_wig30.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0060-bpi_trend_wig30.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0060-bpi_trend_wig30.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0060-bpi_trend_wig30.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt

#-mWIG40-----------------------------------------------------#
cat $WWW_PATH/wykresy/0070-bpi_mwig40.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0070-bpi_mwig40.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0070-bpi_mwig40.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0070-bpi_mwig40.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0070-bpi_mwig40.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt

cat $WWW_PATH/wykresy/0070-bpi_trend_mwig40.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0070-bpi_trend_mwig40.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0070-bpi_trend_mwig40.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0070-bpi_trend_mwig40.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0070-bpi_trend_mwig40.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt

#-sWIG80-----------------------------------------------------#
cat $WWW_PATH/wykresy/0080-bpi_swig80.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0080-bpi_swig80.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0080-bpi_swig80.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0080-bpi_swig80.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0080-bpi_swig80.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt

cat $WWW_PATH/wykresy/0080-bpi_trend_swig80.$skala.$tryb2.txt | grep "\(|\|+\)" > $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt
echo -e "\nZmiany z O na X:" >> $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0080-bpi_trend_swig80.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 O | grep X >> $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt
echo -e "\nZmiany z X na O:" >> $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0080-bpi_trend_swig80.$skala.$tryb2.txt | egrep [0-9]{4}-[0-9]{2}-[0-9]{2} | grep -A1 X | grep O >> $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0080-bpi_trend_swig80.$skala.$tryb2.txt | grep "status.bs" >> $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt
cat $WWW_PATH/wykresy/0080-bpi_trend_swig80.$skala.$tryb2.txt | grep -B 21 $x >> $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt

#------------------------------------------------------#

echo -e "\n--- WIG BPI: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/001-bpi.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- WIG BPI TREND: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/001-bpi_trend.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- WIG BPI (4box): ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/004-bpi_4box.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- WIG BPI TREND (4box): ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/004-bpi_trend_4box.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- WIG20 BPI: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/005-bpi_wig20.$skala.$tryb2.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- WIG20 BPI TREND: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/005-bpi_trend_wig20.$skala.$tryb2.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- WIG30 BPI: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/006-bpi_wig30.$skala.$tryb2.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- WIG30 BPI TREND: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/006-bpi_trend_wig30.$skala.$tryb2.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- mWIG40 BPI: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/007-bpi_mwig40.$skala.$tryb2.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- mWIG40 BPI TREND: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/007-bpi_trend_mwig40.$skala.$tryb2.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- sWIG80 BPI: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/008-bpi_swig80.$skala.$tryb2.txt >> $WWW_PATH/indexy/$x-BPI.txt
echo -e "\n--- sWIG80 BPI TREND: ----------------\n" >> $WWW_PATH/indexy/$x-BPI.txt
cat $WWW_PATH/wykresy/008-bpi_trend_swig80.$skala.$tryb2.txt >> $WWW_PATH/indexy/$x-BPI.txt


mv $WWW_PATH/indexy/$(date +%F -d "35 days ago")*.txt $WWW_PATH/indexy/old/ > /dev/null 2>&1

#----------------------------------------------------------------------------------------------------------------

if [ $(head -c 1 $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt) == $(head -c 1 $RPATH/last_signal/000-bpi.$skala.$tryb2.XO) ]
then
	echo "Sygnal XO dla BPI sie nie zmienił"
else
	echo "UWAGA: Sygnal XO dla BPI zmienił sie"
        head -c 1 $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt > $RPATH/last_signal/000-bpi.$skala.$tryb2.XO

	echo $TRESC_MAIL2 | mail -s "$SUB_MAIL2" \
	-a "$RPATH/last_signal/000-bpi.$skala.$tryb2.XO" \
	-r $sender1 \
	$receiver1
fi

if [ $(head -c 1 $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt) == $(head -c 1 $RPATH/last_signal/000-bpi_trend.$skala.$tryb2.XO) ]
then
        echo "Sygnal XO dla BPI Trend sie nie zmienił"
else
        echo "UWAGA: Sygnal XO dla BPI Trend zmienił sie"
        head -c 1 $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt > $RPATH/last_signal/000-bpi_trend.$skala.$tryb2.XO

        echo $TRESC_MAIL3 | mail -s "$SUB_MAIL3" \
        -a "$RPATH/last_signal/000-bpi_trend.$skala.$tryb2.XO" \
        -r $sender1 \
        $receiver1
fi
#----------------------------------------------------------------------------------------------------------------
#head -n 2 /usr/share/nginx/html/stock/wykresy/000-bpi.R.2proc.close.txt | tail -c 2

if [ $(head -n 2 $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt | tail -c 2) == $(head -c 1 $RPATH/last_signal/000-bpi.$skala.$tryb2.BS) ]
then
        echo "Sygnal Buy/Sell dla BPI sie nie zmienił"
else
        echo "UWAGA: Sygnal Buy/Sell dla BPI zmienił sie"
        head -n 2 $WWW_PATH/wykresy/000-bpi.R.$skala.$tryb2.txt | tail -c 2 > $RPATH/last_signal/000-bpi.$skala.$tryb2.BS

        echo $TRESC_MAIL4 | mail -s "$SUB_MAIL4" \
        -a "$RPATH/last_signal/000-bpi.$skala.$tryb2.BS" \
        -r $sender1 \
        $receiver1
fi

if [ $(head -n 2 $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt | tail -c 2) == $(head -c 1 $RPATH/last_signal/000-bpi_trend.$skala.$tryb2.BS) ]
then
        echo "Sygnal Buy/Sell dla BPI Trend sie nie zmienił"
else
        echo "UWAGA: Sygnal Buy/Sell dla BPI Trend zmienił sie"
        head -n 2 $WWW_PATH/wykresy/000-bpi_trend.R.$skala.$tryb2.txt | tail -c 2 > $RPATH/last_signal/000-bpi_trend.$skala.$tryb2.BS

        echo $TRESC_MAIL5 | mail -s "$SUB_MAIL5" \
        -a "$RPATH/last_signal/000-bpi_trend.$skala.$tryb2.BS" \
        -r $sender1 \
        $receiver1
fi

#----------------------------------------------------------------------------------------------------------------


echo "------------------------"

quit_script

rm -f $PIDFILE

