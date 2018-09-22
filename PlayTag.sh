#!/bin/bash
# Author           : Michał Hajdasz ( brinkorpl@gmail.com )
# Created On       : 26.05.2018
# Last Modified By : Michał Hajdasz ( brinkorpl@gmail.com )
# Last Modified On : 26.05.2018
# Version          : 1.00
#
# Description      :
# PlayTag jest skryptem służącym do tworzenia własnych playlist z utworów wyszukanych 
# po tagach. Dodatkowo posiada możliwość edytowania tagów pojedynczego utworu oraz
# edycji wcześniej utworzonej playlisy w formacie m3u. Korzystanie ze skryptu odbywa się
# w całości za pomocą interfejsu graficznego Zenity.
# Skrypt do poprawnego działania wymaga instalacji mp3info.
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact the Free Software Foundation for a copy)

VERSION=1.00

while getopts ":hv" opt; do
	case ${opt} in
	h )  
	echo "help:"
	echo "You can use only two parametrs with this script."
	echo "That is:" 
    	echo "-v for info about author and version"
    	echo "-h for help"
    	echo "Whole script is in Zenity graphical interface written in polish."
    	echo "If something doesn't work then it's propably because you don't have mp3info."
    	echo "You can install it by your own using a command: sudo apt-get install mp3info."
    	echo "or at the beggining of my script."
    	exit
	;;
	v ) 
	echo "PlayTag $VERSION" 
    	echo "Author: Michał Hajdasz (brinkorpl@gmail.com)"
    	exit
	;;
	\? ) echo "Usage: cmd [-h] [-v]"
	exit
	;;
	esac
done

zenity --question --title "Instalacja" --text "Czy chcesz zainstalowac mp3info?" 2> /dev/null
if [[ $? == 0 ]]; then
    sudo apt-get install mp3info
else
    zenity --warning --text "Mp3info jest wymagane do poprawnego dzialania skryptu" 2> /dev/null
fi
declare -A OPCJE
declare -A MAIN
MENU=("Katalog" "Tytul" "Artysta" "Gatunek" "Album" "Utworz playliste" "Menu glowne")
DZIALANIA=("Utworz playliste" "Edytuj playliste" "Edytuj tagi" "Zakoncz")
ScriptDir=$(pwd)
while MAIN=`zenity --title="PlayTag" --text="Menu Glowne" --list --column=Dzialania "${DZIALANIA[@]}" --height 240 --width 240` 2> /dev/null; do #main loop of script (main menu)
	case "$MAIN" in
	"${DZIALANIA[0]}" ) #submenu that allows creating new list based on mp3 tags
		while OPCJA=`zenity --title="PlatTag" --text="Wprowadz opcje do wyszukania plikow" --list --column=Opcje "${MENU[@]}" --height 300 --width 250` 2> /dev/null; do
			if [[ "${OPCJE[Katalog]}" == "" ]]; then
				OPCJE[Katalog]=$ScriptDir
			fi
			case "$OPCJA" in
			"${MENU[0]}" ) OPCJE[Katalog]=$(zenity --file-selection --title="Podaj sciezke do katalogu z muzyka" --directory);;
			"${MENU[1]}" ) OPCJE[Tytul]=$(zenity --entry --title "Tytul" --text "Podaj tytul utworu");;
			"${MENU[2]}" ) OPCJE[Artysta]=$(zenity --entry --title "Artysta" --text "Podaj autora utworow");;
			"${MENU[3]}" ) OPCJE[Gatunek]=$(zenity --entry --title "Gatunek" --text "Podaj gatunek");;
			"${MENU[4]}" ) OPCJE[Album]=$(zenity --entry --title "Album" --text "Podaj album");;
			"${MENU[5]}" )
				while [[ $PlaylistName == "" ]]; do
					ScriptDir=$(zenity --file-selection --title="Wybierz miejsce zapisu playlisty" --directory)
					if [[ "$ScriptDir" == "" ]]; then
						break
					fi
					cd "$ScriptDir"
					PlaylistName=$(zenity --entry --title "Nazwa playlisty" --text "Podaj nazwe nowej playlisty")
					if [[ "$PlaylistName" == "" ]]; then
						ScriptDir=""
						break
					fi
					PlaylistName="$PlaylistName.m3u"
                    #checking if file already exists
					for file in *.m3u; do
						if [[ "$file" == "$PlaylistName" ]]; then
							zenity --warning --text "Istnieje juz playlista o takiej nazwie"
							zenity --question --title "Nadpisac?" --text "Czy nadpisac istniejaca playliste?"
							Nadpisac=$?
							if [[ $Nadpisac == 0  ]]; then
								rm "$PlaylistName"
							else
								PlaylistName=""
							fi
						fi
					done
				done
				if [[ "$ScriptDir" == "" ]]; then
					break
				fi
				cd "${OPCJE[Katalog]}"
				echo "#EXTM3U" >> $ScriptDir/$PlaylistName
                #getting tags for all files in given directory
				for file in *.mp3; do
					Artist=$(mp3info -p %a "$file")
					Title=$(mp3info -p %t "$file")
					Genre=$(mp3info -p %g "$file")
					Album=$(mp3info -p %l "$file")
					Time=$(mp3info -p %S "$file")
                    #checking if mp3 tags are the same as given by user
					if [[ "${OPCJE[Tytul]}" == "$Title" || "${OPCJE[Tytul]}" == "" ]]; then
						if [[ "${OPCJE[Artysta]}" == "$Artist" || "${OPCJE[Artysta]}" == "" ]]; then
							if [[ "${OPCJE[Gatunek]}" == "$Genre" || "${OPCJE[Gatunek]}" == "" ]]; then
								if [[ "${OPCJE[Album]}" == "$Album" || "${OPCJE[Album]}" == "" ]]; then
                                    #add mp3 to playlist
									echo "#EXTINF:$Time,$Artist - $Title" >> $ScriptDir/$PlaylistName
									echo "${OPCJE[Katalog]}/$file" >> $ScriptDir/$PlaylistName
								fi
							fi
						fi
					fi
				done
				PlaylistName=""
				unset OPCJE
				declare -A OPCJE;;
			"${MENU[6]}" ) 
				#echo "${OPCJE[Artysta]}"
				unset OPCJE
				declare -A OPCJE
				#OPCJE[Katalog]=""
				#OPCJE[Artysta]=""
				#OPCJE[Tytul]=""
				#OPCJE[Gatunek]=""				
				#OPCJE[Alubm]=""
				break;;
			*) echo "$OPCJA";;
			esac
		done
		unset OPCJE
		declare -A OPCJE
		#OPCJE[Katalog]=""
		#OPCJE[Artysta]=""
		#OPCJE[Tytul]=""
		#OPCJE[Gatunek]=""				
		#OPCJE[Alubm]=""
		;;
	"${DZIALANIA[1]}" ) #submenu that allows you choose m3u playlist and edit it (adding and removing songs)
		Playlist=$(zenity --file-selection --title="Wybierz playliste do edycji" --file-filter=*.m3u)
		if [[ "$Playlist" != "" ]]; then
            TMP=$(mktemp)
            #creating menu of songs from given playlist
			cat "$Playlist" | grep ".mp3" | rev | cut -d"/" -f 1 | cut -d"." -f 2 | rev > "$TMP"
			Licznik=0
			while read line
			do
				MUSIC_LIST[Licznik]="$line"
				#echo $line
				#echo ${MUSIC_LIST[Licznik]}
				#echo $Licznik
				((Licznik++))
			done < <(cat "$TMP")
			#echo $Licznik
			MUSIC_LIST[Licznik]="Dodaj nowy"
			AllLicznik=$Licznik+1
			MUSIC_LIST[AllLicznik]="Zapisz"
			while EDIT=`zenity --title="Edycja playlisty" --text="Wybierz utwor, ktory chcesz usunac z playlisty lub dodaj nowy" --list --column=Dzialania "${MUSIC_LIST[@]}" --height 300 --width 300`; do
				if [[ "$EDIT" == "Dodaj nowy" ]]; then
					NewSong=$(zenity --file-selection --title="Wybierz utwor do dodania" --file-filter=*.mp3)
					if [[ "$NewSong" == "" ]]; then
						continue;
					fi
					NewSongPos=$(echo "$NewSong" | rev | cut -d"/" -f 1 | cut -d"." -f 2 | rev)
					for song in "${MUSIC_LIST[@]}"; do
						if [[ "$song" == "$NewSongPos" ]]; then
							NewSong=""
							break
						fi
					done
					if [[ "$NewSong" == "" ]]; then
						continue;
					fi
					NewSongTitle=$(mp3info -p %t "$NewSong")
					NewSongAutor=$(mp3info -p %a "$NewSong")
					NewSongTime=$(mp3info -p %S "$NewSong")
					echo "#EXTINF:$NewSongTime,$NewSongAutor - $NewSongTitle" >> "$Playlist"
					echo "$NewSong" >> "$Playlist"
					NewPos=$Licznik+1
					SavePos=$Licznik+2
					MUSIC_LIST[$Licznik]="$NewSongPos"
					MUSIC_LIST[$NewPos]="Dodaj nowy"
					MUSIC_LIST[$SavePos]="Zapisz"
					((Licznik++))
                #save tmp to given playlist
				elif [[ "$EDIT" == "Zapisz" ]]; then
                    TMP_PL=$(mktemp)
					echo "#EXTM3U" > "$TMP_PL"
					for song in "${MUSIC_LIST[@]}"; do
						if [[ "$song" == "Zapisz" || "$song" == "Dodaj nowy" ]]; then
							continue	
						fi
						SongFile="$song.mp3"
						cat "$Playlist" | grep -B 1 "$SongFile" >> "$TMP_PL"
					done
					cat "$TMP_PL" > "$Playlist"
					rm "$TMP_PL"
					break
                #remove selected file (changes are not saving yet in playlist)
				else
					#MUSIC_LIST=( "${MUSIC_LIST[@]/$EDIT}" )
					for (( i=0; i<Licznik; i++ )); do
						if [[ "$EDIT" == "${MUSIC_LIST[i]}" ]]; then
							unset 'MUSIC_LIST[i]'
						fi
					done
				fi
			done
			unset 'MUSIC_LIST'
			rm "$TMP"
		fi;;
	"${DZIALANIA[2]}" ) #another submenu, this one allows you to choose single mp3 file and edit its tags
		File=$(zenity --file-selection --title="Wybierz plik do edycji" --file-filter=*.mp3)
		if [[ "$File" != "" ]]; then
			Tags=$(zenity --forms --title="Edytor tagow" --text="Wprowadz tylko te tagi, ktore chcesz zmienic" --separator="," --add-entry="Tytul" --add-entry="Autor" --add-entry="Gatunek" --add-entry="Album")
            #Getting written tags form zenity form
			Tytul=$(echo "$Tags" | cut -d"," -f 1)
			Autor=$(echo "$Tags" | cut -d"," -f 2)
			Gatunek=$(echo "$Tags" | cut -d"," -f 3)
			NAlbum=$(echo "$Tags" | cut -d"," -f 4)
            #setting new tags to mp3 file			
            if [[ "$Tytul" != "" ]]; then
				mp3info -t "$Tytul" "$File"
			fi
			if [[ "$Autor" != "" ]]; then
				mp3info -a "$Autor" "$File"
			fi
			if [[ "$Gatunek" != "" ]]; then
				mp3info -g "$Gatunek" "$File"
			fi
			if [[ "$NAlbum" != "" ]]; then
				mp3info -l "$NAlbum" "$File"
			fi
		fi;;
	"${DZIALANIA[3]}" )exit;; # ends script
	esac
done
