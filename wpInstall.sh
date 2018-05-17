#! /bin/bash
#
dirExist=false
dirEmpty=true
bddExist=false
bddEmpty=true

if [[ -z "$1" ]]; then
	echo "wpInstall.sh [chemin d'installation]"
	exit 1
fi

read -e -p "Adresse base de donnée (127.0.0.1) : " bddAdress
read -e -p "Port base de donnée (3306) : " bddPort
read -e -p "Utilisateur base de donnée (root) : " bddUser
read -e -p "Mot de passe base de donnée (root) : " bddPass
read -e -p "Préfixe pour les tables (wp_): " bddPrefix

bddAdress="${bddAdress:=127.0.0.1}"
bddPort="${bddPort:=3306}"
bddUser="${bddUser:=root}"
bddPass="${bddPass:=root}"
bddPrefix="${bddPrefix:=wp_}"

path=${1%/}
name=${path##*/}
bddName=${name/ /_}

if [[ -d "$path" ]]; then
	dirExist=true
	if [[ ! -z "$(ls -A $path)" ]]; then
		dirEmpty=false
		echo "Le répertoire" $path "existe déjà et n'est pas vide"
		exit 1
	fi
else
	dirExist=false
fi

if [ $(mysql -u "$bddUser" -p"$bddPass" -h "$bddAdress" -P"$bddPort" -e 'use mysql' 2>&1 | grep -v "Warning*" | wc -l) -ge 1  ]; then
	echo "Impossible de se connecter au serveur de base de données"
	exit 1
fi

if [ $(mysql -u "$bddUser" -p"$bddPass" -h "$bddAdress" -P"$bddPort" -e 'use '"$bddName"'' 2>&1 | grep -v "Warning*" | wc -l) -eq 0 ]; then
	bddExist=true
	if [ $(mysql -u "$bddUser" -p"$bddPass" -h "$bddAdress" -P"$bddPort" -e 'use "$bddName";show tables' | wc -l)  -gt "0" ]; then
		bddEmpty=false
		echo "Une base de données "$bddname" existe déjà et n'est pas vide"
		exit 1
	fi
else
	bddExist=false
fi

if [ $dirExist == false ]; then
	mkdir $path
	dirExist=true
	dirEmpty=true
fi

if [ $dirExist == true -a $dirEmpty == true ]; then
	cd $path
	wget https://wordpress.org/latest.tar.gz
	tar -xf ./latest.tar.gz -C ./
	mv ./wordpress/* ./
	rm -rf ./wordpress/
	rm -rf ./latest.tar.gz

	cp wp-config-sample.php wp-config.php

	sed -i -e 's/votre_nom_de_bdd/'$bddName'/g' wp-config.php
	sed -i -e 's/database_name_here/'$bddName'/g' wp-config.php
	sed -i -e 's/votre_utilisateur_de_bdd/'$bddUser'/g' wp-config.php
	sed -i -e 's/username_here/'$bddUser'/g' wp-config.php
	sed -i -e 's/votre_mdp_de_bdd/'$bddPass'/g' wp-config.php
	sed -i -e 's/password_here/'$bddPass'/g' wp-config.php
	sed -i -e 's/localhost/'$bddAdress'/g' wp-config.php
	sed -i -e 's/utf8/utf8mb4/g' wp-config.php
	sed -i -e "s/table_prefix  = 'wp_';/table_prefix  = '"$bddPrefix"';/g" wp-config.php

	while true ; do
		if grep -q 'put your unique phrase here' wp-config.php ; then
			salt=$(cat /dev/urandom | tr -dc "a-zA-Z0-9!@#%*_+?><~;" | fold -w 64 | head -n 1)
			sed -i -e '0,/put your unique phrase here/s//'$salt'/g' wp-config.php
		else
			break
		fi
	done
fi

if [ $bddExist == false ]; then
	mysql -u "$bddUser" -p"$bddPass" -h "$bddAdress" -P"$bddPort" -e 'CREATE DATABASE '"$bddName"' CHARACTER SET utf8 COLLATE utf8_general_ci;'  2>&1 | grep -v "Warning*"
fi

echo "-----------------------------------------------"
echo "-----------------------------------------------"
echo "||                                           ||"
echo "|| \o/ Installation de wordpress réussie \o/ ||"
echo "||                                           ||"
echo "-----------------------------------------------"
echo "-----------------------------------------------"
