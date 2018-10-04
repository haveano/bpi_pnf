#!/bin/bash

start_t=$(date +%s)
echo -e "\nCzas rozpoczęcia skryptu: $(date +%F_%H:%M:%S)"

GPATH=/root/gielda3
WWWPATH=/usr/share/nginx/html/stock/gielda3

# source: http://bencane.com/2015/09/22/preventing-duplicate-cron-job-executions/
PIDFILE=$GPATH/lockfile.pid
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

#sleep 2m

#LAST_TIME to godzina np 23:55, zapisana w formacie 2355
#zmienna LAST_TIME, ma byc ustawione na tyle samo lub  1 min mniej niz ostatnie uruchmienie
#w crontabie. Teraz ustaione jest w crontabie aby uruchamiac sie
# 5 minut, 20, 35 i 50 po godzinach 16, 17, 18, 19, 20, 21, 22 i 23
# Ostatnie uruchomienie z crontab jest wiec o 23:55.
# W skrypcie data jest wyswietlana jako "-%H%M", z minusem
# czyli bez zera na poczatku, 8:05 to 805
LAST_TIME=2034

TODAY=$(date +%F)
#TODAY=2018-01-31
#TODAY=2017-07-17
#zamienia date z formatu YYYY-MM-DD na DD-MM-YYYY:
TODAY_2=$(awk -F- '{ print $3"-"$2"-"$1 }' <<< "$TODAY")

NOW=$(date +%H-%M)

#KOMUNIKAT1="$0: wywołanie skryptu: ./d1.sh (sendemail|notsendemail) (first|notfirst) (y|n)"
KOMUNIKAT1="$0: wywołanie skryptu: ./d1.sh (sendemail|notsendemail) (first|notfirst)"

COMM="-------------------------------------------"
COMM2="++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


ERR1_L1="----1--dates.txt.diff"
ERR1_L2="----1--Plik dates.txt.diff ma nieoczekiwany rozmiar. Sprawdzić czy jest w nim data, oraz czy data jest poprawna."
ERR1_L3="----1--Zawartość dates.txt.diff:"

SUB_MAIL1="Plik dates.txt.diff ma nieoczekiwany rozmiar"
TRESC_MAIL1="Plik dates.txt.diff ma nieoczekiwany rozmiar. Sprawdzić czy jest w nim data, oraz czy data jest poprawna."
SUB_MAIL2="Plik dates.txt.diff ma zerowy rozmiar"
TRESC_MAIL2="Plik dates.txt.diff ma zerowy rozmiar. To było ostatnie sprawdzenie. Nie ma dzisiejszych notowań. Moze tego dnia nie było sesji (np. świeto)."
SUB_MAIL3="Nie ma jeszcze dzisiejszych notowań"
TRESC_MAIL3="Plik dates.txt.diff ma zerowy rozmiar. Nie ma jeszcze dzisiejszych notowań. Nie jest to dzisiaj ostatnie sprawdzenie notowań."
SUB_MAIL4="Plik ls_curr_spolki.txt.diff ma rozmiar wikeszy niz zero"
TRESC_MAIL4="Plik ls_curr_spolki.txt.diff ma rozmiar wikeszy niz zero. To znaczy, że zmieniła sie liczba spólek (nowa spółka lub usunięta) lub spółka zmieniła nazwę. Jesli zmienila sie tez liczba ISIN to zmieniła sie liczba spółek. Jesli nie to pewnie spółka zmieniła nazwę (przykład: Qumak-Sekom -> Qumak, a ISIN został ten sam)."
SUB_MAIL5="Plik ls_curr_isin.txt.diff ma rozmiar wikeszy niz zero"
TRESC_MAIL5="Plik ls_curr_isin.txt.diff ma rozmiar wikeszy niz zero. To znaczy, że zmieniła sie liczba spólek (nowa spółka lub usunieta)."

sender1=root@katkat.tk
receiver1=cezary.wysocki+notowania@gmail.com

INF1_L1="----2--ls_curr_spolki.txt.diff"
INF1_L2="----2--Plik ls_curr_spolki.txt.diff ma rozmiar wikeszy niz zero. To znaczy, że zmieniła sie liczba spólek (nowa spółka lub usunięta) lub spółka zmieniła nazwę.\n----2--Jesli zmienila sie tez liczba ISIN to zmieniła sie liczba spółek. Jesli nie to pewnie spółka zmieniła nazwę (przykład: Qumak-Sekom -> Qumak)."
INF1_L3="----2--Plik ls_curr_spolki.txt.diff nie jest zerowy. Kopiuję go do katalogu logs."
INF1_L4="----2--Zawartość ls_curr_spolki.txt.diff:"

INF2_L1="----3--ls_curr_isin.txt.diff"
INF2_L2="----3--Plik ls_curr_isin.txt.diff ma rozmiar wikeszy niz zero. To znaczy, że zmieniła sie liczba spólek (nowa spółka lub usunieta)."
INF2_L3="----2--Plik ls_curr_isin.txt.diff nie jest zerowy. Kopiuję go do katalogu logs."
INF2_L4="----3--Zawartość ls_curr_isin.txt.diff:"

function quit_script {
	echo "Czas zakończenia skryptu: $(date +%F_%H:%M:%S)"
	end_t=$(date +%s)
	echo "Skrypt wykonywał się $(expr $end_t - $start_t) sekund"
	echo -e "\n######################################################################################\n"
	rm -f $PIDFILE
}

function delete_trash {
	echo "Usuwam śmieci z katalogu trash:"
	ls -la $GPATH/trash/wget_output.$(date +%F -d "35 days ago")*
	ls -la $GPATH/trash/$(date +%F -d "35 days ago")*.csv
	ls -la $GPATH/trash/$(date +%F -d "35 days ago")*.xls

	rm -f $GPATH/trash/wget_output.$(date +%F -d "35 days ago")*
	rm -f $GPATH/trash/$(date +%F -d "35 days ago")*.csv
	rm -f $GPATH/trash/$(date +%F -d "35 days ago")*.xls
}

if [ $# -ne 2 ]
then
        echo $KOMUNIKAT1
	quit_script
        exit 1
else
        case "$1" in
          sendemail|notsendemail)
                ifsend=$1
                echo "PARAMETR1: $1"
                ;;
          *)
                echo $KOMUNIKAT1
		quit_script
                exit 1
        esac

        case "$2" in
          notfirst)
                iffirst=$2
                echo "PARAMETR2: $2"
                ;;
	  first)
		iffirst=$2
		echo "PARAMETR2: $2"
#		echo -e "\nJesteś pewny, że zainicjować od nowa i wyczyścić katalog\n\n\t$GPATH?\n\nOdpowiedz: y lub n\n"
#		read sure
#		if [[ $sure == "y" ]]
#		then
#			echo "Ok. Idziemy dalej..."
#		elif [ $sure == "n" ]
#		then
#			echo "\nOk. Wychodzę...\n"
#			quit_script
#			exit 1
#		else
#			echo -e "\nOdpowiedź y lub n\n"
#			quit_script
#			exit 1
#		fi
		;;
          *)
                echo $KOMUNIKAT1
		quit_script
                exit 1
        esac
fi
cd $GPATH

if [[ $iffirst == "first" ]]
then
	cd $GPATH
        echo $COMM2
	echo -e "Sprzątam zawartość katalogu $GPATH:"
	ls -l

	rm -rf isin
	rm -rf isin_curr
	rm -rf isin-z-zerami
	rm -rf logs
	rm -rf not-bez-zer
	rm -rf notowania
	rm -rf spolki
	rm -rf spolki_curr
	rm -rf spolki-z-zerami
	rm -rf wig
	rm -rf trash
	#rm -f dates*
	rm -f dates.txt.diff
	rm -f ls_*
	#rm -f site
	rm -f WIG.csv
	rm -f znacznik

        echo $COMM2
	echo -e "Posprzatane:"
	ls -l

        mkdir $GPATH/isin
        mkdir $GPATH/isin_curr
	mkdir $GPATH/isin-z-zerami
	mkdir $GPATH/isin-bez-zer
        mkdir $GPATH/logs
        mkdir $GPATH/not-bez-zer
        mkdir $GPATH/notowania
        mkdir $GPATH/spolki
        mkdir $GPATH/spolki_curr
	mkdir $GPATH/spolki-z-zerami
	mkdir $GPATH/spolki-bez-zer
        mkdir $GPATH/wig
	mkdir $GPATH/trash
	
	touch $GPATH/dates.txt.diff
	touch $GPATH/dates.txt.old

	touch $GPATH/ls_curr_spolki.txt
	touch $GPATH/ls_spolki_all.txt
	touch $GPATH/ls_curr_spolki.txt.diff
	
	touch $GPATH/ls_curr_isin.txt
	touch $GPATH/ls_isin_all.txt
	touch $GPATH/ls_curr_isin.txt.diff
	
	echo $COMM2
	echo -e "Przygotowane:"
	ls -l
else	
	#jeśli nie pierwszy raz, to znaczy ze istnieje plik dates.txt i go przenosimy:
###	mv $GPATH/dates.txt $GPATH/dates.txt.old
	cp -f $GPATH/dates.txt $GPATH/dates.txt.old
fi

# sciagnij strone z notowaniami, w źrodle strony zapisane są daty w ktorych byly sesje gieldy:
# nastepnie trzeba wyekstrachowac same daty do pliku dates.txt
#/usr/bin/wget -q -O $GPATH/site https://www.gpw.pl/notowania_archiwalne

#
###
### /usr/bin/wget -O $GPATH/site https://www.gpw.pl/notowania_archiwalne 2> $GPATH/trash/wget_output.$(date +%F_%H:%M:%S)
### cp $GPATH/site $GPATH/trash/site.$(date +%F_%H:%M:%S)
### cat $GPATH/site | grep calendarEnabledDates | sed 's/.*{\(.*\)}.*/\1/' | sed 's/,/\n/g' | sed "s/:1$//" | sed "s/'//g" | sort > $GPATH/dates.txt
###
#

#jesli godzina jest mniejszsza niz, czyli ze NIE ostatni raz uruchamiany dzisiaj
#oraz istnieje plik znacznik, czyli ze notowania były juz dzisiaj ściągnięte
#to wyjdz
if [[ $(date +%-H%M) -lt $LAST_TIME ]] && [ -e $GPATH/znacznik ]
then
	echo $COMM2
        echo "Godzina (1): $(date +%H:%M)"
	echo "Juz dzisiejsze notowania ściągnięte. Koncze skrypt."
	quit_script
	exit 1

#jesli godzina jest wieksza lub rowna cośtam, czyli ze ostatni raz uruchamiany dzisiaj
#oraz istnieje plik znacznik, czyli ze notowania były juz dzisiaj ściągnięte
#to usun plik znacznik i wyjdz
elif [[ $(date +%-H%M) -ge $LAST_TIME ]] && [ -e $GPATH/znacznik ]
then
	echo $COMM2
        echo "Godzina (2): $(date +%H:%M)"
	echo "Juz dzisiejsze notowania sciagniete. Ostatni raz dzisiaj sprawdzam. Usuwam wiec znacznik, ze dzisiaj juz były sciagniete i wychodze."
	rm -f $GPATH/znacznik
	quit_script
	exit 1

#w przeciwnych wypadkach, (czyli jesli znacznika nie ma, czyli notowania jeszcze dzisiaj nie sciagniete)
else
#	# w pliku diff przechowywane będą tylko daty, dla których jeszcze nie zostały ściagniete notowania
#	#przesuwam plik dates.txt.diff bo następnie do niego dopisuje szukajac roznic, wiec ma byc pusty
#        mv $GPATH/dates.txt.diff $GPATH/dates.txt.diff.old
#        grep -vf $GPATH/dates.txt.old $GPATH/dates.txt >> $GPATH/dates.txt.diff
#        #grep -vf $GPATH/dates.txt $GPATH/dates.txt.old >> $GPATH/dates.txt.diff


##########################################

# testowe:

	if [ $iffirst == first ]
	then
		cp -f $GPATH/dates.txt $GPATH/dates.txt.diff
	else
	        /usr/bin/wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36" \
			-O $GPATH/trash/$TODAY-$NOW.xls --keep-session-cookies --post-data "type=10&date=$TODAY_2&fetch=1" https://www.gpw.pl/archiwum-notowan 2> $GPATH/trash/wget_output.$TODAY-$NOW
        	ssconvert $GPATH/trash/$TODAY-$NOW.xls $GPATH/trash/$TODAY-$NOW.csv > /dev/null 2>&1

	#       #sprawdzamy czy sciągniety plik z notowaniami ma liczbe wierszy wieksza od zera
	#       #jesli tak, to znaczy ze sa dzisiaj nowe notowania i wrzucamy date do pliku diff
	#       #jesli nie ma to, sprawiamy ze plik diff jest pusty
	#        if [ $(cat $GPATH/trash/$TODAY-$NOW.csv | wc -l) -ne 0 ]
		if [ $(cat $GPATH/trash/$TODAY-$NOW.csv | grep "Data,Nazwa,ISIN,Waluta" | wc -l) -ne 0 ]
	        then
			echo $COMM
        	        echo "Sa nowe notowania"
                	echo $TODAY > $GPATH/dates.txt.diff
	                #echo $TODAY >> $GPATH/dates.txt
        	else
			echo $COMM
                	echo "Jeszcze nie ma notowan"
	                rm -f $GPATH/dates.txt.diff
        	        touch $GPATH/dates.txt.diff
                	#quit_script
	                #exit 1
        	fi
	fi

##########################################


	#jesli diff ma rozmiar inny niz 11 lub 0 bajtów (czyli inny niz plik z pojedynczą datą lub pusty)
	# i NIE jest to pierwsze uruchomienie. to wyslij maila
	if [ $(cat $GPATH/dates.txt.diff | wc -c) -ne 11 ] && [ $(cat $GPATH/dates.txt.diff | wc -c) -ne 0 ] && [ $iffirst == notfirst ]
	then
		echo $COMM2
		echo $ERR1_L2
		echo $ERR1_L3
		cat $GPATH/dates.txt.diff
		if [[ $ifsend == sendemail ]]
		then
			echo $TRESC_MAIL1 | mail -s "$SUB_MAIL1" \
			-a "$GPATH/dates.txt.diff" \
			-r $sender1 \
			$receiver1
		fi
	#jesli diff ma rozmiar inny niz 11 lub 0 bajtów (czyli inny niz plik z pojedynczą datą lub pusty)
	# i JEST to pierwsze uruchomienie. to zaraportuj tylko komunikatem.
	elif [ $(cat $GPATH/dates.txt.diff | wc -c) -ne 11 ] && [ $(cat $GPATH/dates.txt.diff | wc -c) -ne 0 ] && [ $iffirst == first ]
	then
		echo $COMM
		echo -e "Plik dates.txt.diff ma nieoczekiwany rozmiar, bo to pierwsze uruchomienie."
		echo "W pliku dates.txt.diff powinny być wszystkie dotychczasowe daty"
		echo "Nie wysyłam maila. Nie wklejam pliku dates.txt.diff"
		#cat $GPATH/dates.txt.diff
	fi

	# Sprawdzenie czy plik jest zerowy, jesli jest zerowy to znaczy ze nie ma jeszcze notowań
	# oraz czy jest to ostatnie uruchomienie dzisiaj.
	#
	# Sprawdzenie gdy nie jest to ostatnie uruchomienie dzisiaj:
	if [ ! -s $GPATH/dates.txt.diff ] &&  [[ $(date +%-H%M) -lt $LAST_TIME ]]
	then
		echo $COMM2
                echo "Godzina (3): $(date +%H:%M)"
		echo $TRESC_MAIL3
	#	TE MAILE NIE SA WYSYLANE:
	#	if [[ $ifsend == sendemail ]]
	#	then
	#		echo $TRESC_MAIL3 | mail -s "$SUB_MAIL3" \
	#		-r $sender1 \
	#		$receiver1
	#	fi
		quit_script
		exit 1
	# Sprawdzenie gdy jest ostatnie sprawdzenie dzisiaj czy są notowania:
	elif [ ! -s $GPATH/dates.txt.diff ] &&  [[ $(date +%-H%M) -ge $LAST_TIME ]]
	then
		echo $COMM2
                echo "Godzina (4): $(date +%H:%M)"
	        echo $TRESC_MAIL2
		if [[ $ifsend == sendemail ]]
		then
			echo $TRESC_MAIL2 | mail -s "$SUB_MAIL2" \
			-r $sender1 \
			$receiver1
		fi
		delete_trash
		quit_script
		exit 1
	#Jesli zadne z powyższych, to znaczy, że są notowania i jedziemy z ich sciagnięciem:
	else
		echo $COMM2
		echo "Plik dates.txt.diff nie jest zerowy. Tzn. są nowe notowania. Kopiuję go do katalogu logs."
		cp $GPATH/dates.txt.diff $GPATH/logs/dates.txt.diff.$(date +%F_%H:%M)

		############################################################################
		# pobranie notowan dla dat z pliku dates.txt.diff:
		i=1
		# dla kazdego x (czyli dla kazdego pierwszego wyrazu w kazdej linii) w pliku dates.txt.diff wykonaj:
		for x in `awk '{print $1}' $GPATH/dates.txt.diff`
		do
			x_2=$(awk -F- '{ print $3"-"$2"-"$1 }' <<< "$x")

			#--------------------------------------------------------------------------------
			echo $COMM2
			echo "DATA: $((i++)) : $x"
			# sciagnij xls z notowaniamu sesji dla danej daty (danego x)
			#/usr/bin/wget -q -O $GPATH/notowania/$x.xls --keep-session-cookies --post-data "type=10&date=$x&fetch.x=19&fetch.y=14" https://www.gpw.pl/notowania_archiwalne
	                /usr/bin/wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36" \
				-q -O $GPATH/notowania/$x.xls --keep-session-cookies --post-data "type=10&date=$x_2&fetch=1" https://www.gpw.pl/archiwum-notowan
			# przekonwertuj plik xls na csv:
			ssconvert $GPATH/notowania/$x.xls $GPATH/notowania/$x.csv > /dev/null 2>&1
			#usun linie na których nie było ruchu ("Kurs otwarcia","Kurs max","Kurs min") a także urusn nagłówek:
			cat $GPATH/notowania/$x.csv | grep -v "PLN,0,0,0," | grep -v "Data,Nazwa,ISIN,Waluta," | grep -v ^$ > $GPATH/not-bez-zer/$x.csv

			# sprawdzamu czy plik nie jest zerowy:
			if [ -s $GPATH/not-bez-zer/$x.csv ]
			then
				echo "Nowe notowania z dnia $x"
			else
				rm -f $GPATH/not-bez-zer/$x.csv
			fi

			#---------------------------------------------------------------------------------
			echo $COMM
			echo "DATA-WIG: $((i-1)) : $x"
			# sciagnij xls z notowaniamu sesji dla danej daty (danego x)
			#/usr/bin/wget -q -O $GPATH/wig/$x.xls --keep-session-cookies --post-data "type=1&date=$x&fetch.x=19&fetch.y=14" https://www.gpw.pl/notowania_archiwalne
			/usr/bin/wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36" \
				-q -O $GPATH/wig/$x.xls --keep-session-cookies --post-data "type=1&date=$x_2&fetch=1" https://www.gpw.pl/archiwum-notowan
			# przekonwertuj plik xls na csv:
			ssconvert $GPATH/wig/$x.xls $GPATH/wig/$x.csv > /dev/null 2>&1
			# tylko wyniki WIG kopiuj do osobnego csv:
			cat $GPATH/wig/$x.csv | grep ",WIG," >> $GPATH/WIG.csv
                        cat $GPATH/wig/$x.csv | grep ",WIG," >> $GPATH/indexy/WIG.csv
			cat $GPATH/wig/$x.csv | grep ",MWIG40," >> $GPATH/indexy/MWIG40.csv
			cat $GPATH/wig/$x.csv | grep ",MWIG40TR," >> $GPATH/indexy/MWIG40TR.csv
			cat $GPATH/wig/$x.csv | grep ",SWIG80," >> $GPATH/indexy/SWIG80.csv
			cat $GPATH/wig/$x.csv | grep ",SWIG80TR," >> $GPATH/indexy/SWIG80TR.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-BANKI," >> $GPATH/indexy/WIG-BANKI.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-BUDOW," >> $GPATH/indexy/WIG-BUDOW.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-CEE," >> $GPATH/indexy/WIG-CEE.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-CHEMIA," >> $GPATH/indexy/WIG-CHEMIA.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-ENERG," >> $GPATH/indexy/WIG-ENERG.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-GORNIC," >> $GPATH/indexy/WIG-GORNIC.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-INFO," >> $GPATH/indexy/WIG-INFO.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-LEKI," >> $GPATH/indexy/WIG-LEKI.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-MEDIA," >> $GPATH/indexy/WIG-MEDIA.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-MOTO," >> $GPATH/indexy/WIG-MOTO.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-NRCHOM," >> $GPATH/indexy/WIG-NRCHOM.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-ODZIEZ," >> $GPATH/indexy/WIG-ODZIEZ.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-PALIWA," >> $GPATH/indexy/WIG-PALIWA.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-POLAND," >> $GPATH/indexy/WIG-POLAND.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-SPOZYW," >> $GPATH/indexy/WIG-SPOZYW.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-TELKOM," >> $GPATH/indexy/WIG-TELKOM.csv
			cat $GPATH/wig/$x.csv | grep ",WIG-UKRAIN," >> $GPATH/indexy/WIG-UKRAIN.csv
			cat $GPATH/wig/$x.csv | grep ",WIG20," >> $GPATH/indexy/WIG20.csv
			cat $GPATH/wig/$x.csv | grep ",WIG20TR," >> $GPATH/indexy/WIG20TR.csv
			cat $GPATH/wig/$x.csv | grep ",WIG30," >> $GPATH/indexy/WIG30.csv
			cat $GPATH/wig/$x.csv | grep ",WIG30TR," >> $GPATH/indexy/WIG30TR.csv
			cat $GPATH/wig/$x.csv | grep ",WIGDIV," >> $GPATH/indexy/WIGDIV.csv

			#--------------------------------------------------------------------------------
			# przenies plik z listą spólek 
			mv $GPATH/ls_curr_spolki.txt $GPATH/ls_curr_spolki.txt.old
			# stworz plik z lista spolek z obecnego notowania "$x.csv":
			cat $GPATH/notowania/$x.csv | grep -v "Data,Nazwa,ISIN,Waluta," | awk -F, '{ print $2 }' | grep -v ^$ | sort | uniq > $GPATH/ls_curr_spolki.txt

			# tworzenie listy wszystkich ISIN w całej hisorii giełdy (nie wiem po co :P )
			cat $GPATH/ls_spolki_all.txt $GPATH/ls_curr_spolki.txt | sort | uniq > $GPATH/ls_spolki_all.txt.temp
			mv $GPATH/ls_spolki_all.txt.temp $GPATH/ls_spolki_all.txt

			# jesli istnieje plik diff z lista spolek to go przesun
			mv $GPATH/ls_curr_spolki.txt.diff $GPATH/ls_curr_spolki.txt.diff.old
			grep -vf $GPATH/ls_curr_spolki.txt.old $GPATH/ls_curr_spolki.txt >> $GPATH/ls_curr_spolki.txt.diff
			grep -vf $GPATH/ls_curr_spolki.txt $GPATH/ls_curr_spolki.txt.old >> $GPATH/ls_curr_spolki.txt.diff

			# jesli lista spolek sie zmieniła, to wyswietl info i ew. wyslij maila z tym info i załącz plik:
			if [ $(cat $GPATH/ls_curr_spolki.txt.diff | wc -l) -ne 0 ]
			then
				echo $COMM
				echo -e $INF1_L2
				echo $INF1_L3
				echo $INF1_L4
				cat $GPATH/ls_curr_spolki.txt.diff
				cp $GPATH/ls_curr_spolki.txt.diff $GPATH/logs/ls_curr_spolki.txt.diff.$x
				if [[ $ifsend == sendemail ]]
				then
					echo $TRESC_MAIL4 | mail -s "$SUB_MAIL4" \
					-a $GPATH/ls_curr_spolki.txt.diff \
					-r $sender1 \
					$receiver1
				fi
			fi




			# dla kazdego notowania z dnia "$x" dodaj je do pliku kazdej ze spółek "$y.csv"":
			# przelatuje po liscie spółek i dodaje wyniki tej społki z notowan z daty "$x" do plik z notowaniami tej spółki ("$y"):
			j=1
			echo $COMM
			#for y in `awk '{print $1}' $GPATH/ls_curr_spolki.txt`
			#do
			#	echo "NAZWA: $((j++)) : $y"
			#	cat $GPATH/notowania/$x.csv | grep ",$y," | grep -v "PLN,0,0,0," >> $GPATH/spolki/$y.csv
			#done

			# przewaga ponizszego "for`a" nad powyzszym jest taka, ze iterujemy po kazdej linii pliku z nazwami spolek,
			# a nie po pierwszym wyrazie linii jak w powyzszym for`ze. Jesli wiec nazwa spolki miala spacje, to byla tylko jeden wyraz
			# Nazwy ze spacja mają cudzysłowy, wiec jeszcze trzeba bylo je usunac. Do tego:
			# loop splits when it sees any whitespace like space, tab, or newline. So, you should use IFS (Internal Field Separator)
			#IFS=$'\n' this make newlines the only separator
			IFS=$'\n'
			# dla kazdej linii w pliku 
			for y in `cat $GPATH/ls_curr_spolki.txt`
			do
				#usuwamy cudzysłowy z nazwy: ""
				yy=`echo "$y" | sed "s/\"//g"`
				echo "NAZWA: $((j++)) : $yy ( $y )"
				#plik nazywamy bez "
				cat $GPATH/notowania/$x.csv | grep ",$y," | grep -v "PLN,0,0,0," >> $GPATH/spolki/$yy.csv
                                cat $GPATH/notowania/$x.csv | grep ",$y," >> $GPATH/spolki-z-zerami/$yy.csv
                                cat $GPATH/notowania/$x.csv | grep ",$y," | grep -v "PLN,0,0,0,0," >> $GPATH/spolki-bez-zer/$yy.csv
			done




			#---------------------------------------------------------------------------------
			# przenies plik z listą spólek: 
			mv $GPATH/ls_curr_isin.txt $GPATH/ls_curr_isin.txt.old
			# stworz plik z lista spolek z obecnego notowania "$x.csv":
			cat $GPATH/notowania/$x.csv | grep -v "Data,Nazwa,ISIN,Waluta," | awk -F, '{ print $3 }' | grep -v ^$ | sort | uniq > $GPATH/ls_curr_isin.txt

			# tworzenie listy wszystkich ISIN w całej hisorii giełdy (nie wiem po co :P )
			cat $GPATH/ls_isin_all.txt $GPATH/ls_curr_isin.txt | sort | uniq > $GPATH/ls_isin_all.txt.temp
			mv $GPATH/ls_isin_all.txt.temp $GPATH/ls_isin_all.txt

			# jesli istnieje plik diff z lista spolek to go przesun
			mv $GPATH/ls_curr_isin.txt.diff $GPATH/ls_curr_isin.txt.diff.old
			grep -vf $GPATH/ls_curr_isin.txt.old $GPATH/ls_curr_isin.txt >> $GPATH/ls_curr_isin.txt.diff
			grep -vf $GPATH/ls_curr_isin.txt $GPATH/ls_curr_isin.txt.old >> $GPATH/ls_curr_isin.txt.diff

			# jesli lista spoek sie zmieniła, to wyslij maila z info i załącz plik:
			if [ $(cat $GPATH/ls_curr_isin.txt.diff | wc -l) -ne 0 ]
			then
				echo $COMM
				echo $INF2_L2
				echo $INF2_L3
				echo $INF2_L4
				cat $GPATH/ls_curr_isin.txt.diff
				cp $GPATH/ls_curr_isin.txt.diff $GPATH/logs/ls_curr_isin.txt.diff.$x
				if [[ $ifsend == sendemail ]]
				then
					echo $TRESC_MAIL5 | mail -s "$SUB_MAIL5" \
					-a $GPATH/ls_curr_isin.txt.diff \
					-r $sender1 \
					$receiver1
				fi
			fi
			
			# dla kazdego notowania z dnia "$x" dodaj je do pliku kazdej ze spółek "$y.csv"":
			# przelatuje po liscie spółek i dodaje wyniki tej społki z notowan z daty "$x" do plik z notowaniami tej spółki ("$y"):
			k=1
			# dla kazdego x (czyli dla kazdego pierwszego wyrazu w kazdej linii) w pliku dates.txt.diff wykonaj:
			echo $COMM
			for z in `awk '{print $1}' $GPATH/ls_curr_isin.txt`
			do
				echo "ISIN: $((k++)) : $z"
				cat $GPATH/notowania/$x.csv | grep ",$z," | grep -v "PLN,0,0,0," >> $GPATH/isin/$z.csv
				cat $GPATH/notowania/$x.csv | grep ",$z,"  >> $GPATH/isin-z-zerami/$z.csv
                                cat $GPATH/notowania/$x.csv | grep ",$z," | grep -v "PLN,0,0,0,0," >> $GPATH/isin-bez-zer/$z.csv
			done
			#--------------------------------------------------------------------------------
			#touch $GPATH/znacznik
			# znacznik - jesli first to nie będzie znacznika
			# jesli ostatnie uruchomienie dzisiaj to też nie:
			echo $COMM2
			echo "Godzina: $(date +%H:%M)"
			if [[ $(date +%-H%M) -ge $LAST_TIME ]] || [ $iffirst == first ]
			then
				echo "To było ostatnie uruchomienie dzisiaj, wiec nie będzie znacznika. Albo skrypt z parametrem 'first'."
			else
				echo "Ustawiam znacznik, ze notowania zostały dzisiaj ściągnięte."
				echo $x > $GPATH/znacznik
			fi
			
			echo $x >> $GPATH/dates.txt
			#echo $x_2 >> $GPATH/dates_2.txt

		done
		#------------------------------------------------------------------------------
		#
		#/usr/bin/tar -zcf $WWWPATH/spolki-all.tar.gz spolki
		#/usr/bin/tar -zcf $WWWPATH/isin-all.tar.gz isin

		rm -f $GPATH/isin_curr/*.csv
		rm -f $GPATH/spolki_curr/*.csv

		m=1
		echo $COMM2
		#Kopia notowan tylko bierzących spółek na gieldzie, w nazwie dodany znacznik zz1, aby mozna łatwo odroznic od innych i łatwo zaimportować
		# do BullsEyeBroker
		echo "Kopie z notowaniami spółek (nazwy) które są obecnie na gieldzie. Dodaje do nazwy pliku i w tresci znacznik 'zz1':"
		for p in `awk '{print $1}' $GPATH/ls_curr_spolki.txt`
		do
		        cat $GPATH/spolki/$p.csv | awk -F, '{$2="zz1_"$2}1' | awk  '{$3="zz1_"$3}1' | sed "s/ /,/g" > $GPATH/spolki_curr/zz1_$p.csv
		        echo "Społka: $((m++)) : $p"
		done
		#tar -czf $WWWPATH/spolki_curr.tar.gz spolki_curr

		n=1
		echo $COMM
		# to samo co wyzej ale po ISIN a nie po nazwie, znacznik 'zz2'
                echo "Kopie z notowaniami spółek (ISIN) które są obecnie na gieldzie. Dodaje do nazwy pliku i w tresci znacznik 'zz2':"
		for q in `awk '{print $1}' $GPATH/ls_curr_isin.txt`
		do
		        cat $GPATH/isin/$q.csv | awk -F, '{$2="zz2_"$2}1' | awk  '{$3="zz2_"$3}1' | sed "s/ /,/g" > $GPATH/isin_curr/zz2_$q.csv
		        echo "ISIN: $((n++)) : $q"
		done
		#tar -czf $WWWPATH/isin_curr.tar.gz isin_curr
	fi
fi
echo $COMM2
echo "Kopiowanie notowan. Czas rozpoczęcia operacji: $(date +%F_%H:%M:%S)"
/usr/bin/cp $GPATH/WIG.csv $WWWPATH/WIG.csv
/usr/bin/cp $GPATH/indexy/WIG20.csv $WWWPATH/WIG20.csv
/usr/bin/tar -zcf $WWWPATH/not-bez-zer.tar.gz not-bez-zer
#/usr/bin/tar -zcf $WWWPATH/spolki-all.tar.gz spolki
#/usr/bin/tar -zcf $WWWPATH/isin-all.tar.gz isin
/usr/bin/tar -czf $WWWPATH/spolki_curr.tar.gz spolki_curr
/usr/bin/tar -czf $WWWPATH/isin_curr.tar.gz isin_curr

delete_trash

quit_script

#ponizsze jest w funckji "quit_script"
#rm -f $PIDFILE

