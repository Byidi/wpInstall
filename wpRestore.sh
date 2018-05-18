#! /bin/bash
#

extractPath="/tmp/wpt/wpRestore/"

clear

if [[ -z "$2" ]]; then
	echo "wpRestore.sh [chemin de la sauvegarde] [chemin d'installation]"
	exit 1
fi

installPath=${2%/}
savePath=${1%/}

echo -n "Extraction de la sauvegarde : "
rm -rf "$extractPath"
mkdir -p "$extractPath"
extract=$(tar -xvzf "$savePath" -C "$extractPath")
extractDir=$(echo $extract | head -1 | cut -f1 -d"/")
name=$(ls "$extractPath""$extractDir" | grep -v "sql")
echo "Done"

if [[ $name == ${installPath##*/} ]]; then
	copyPath=$installPath
else
	copyPath=$installPath"/"$name
fi

if [[ -d "$copyPath" ]]; then
	if [[ ! -z "$(ls -A $copyPath)" ]]; then
		echo "Le répertoire" $copyPath "existe déjà et n'est pas vide"
		exit 1
	fi
fi

echo $name
echo $extractDir

echo -n "Récupération des informations : "
gbddName=$(cat "$extractPath""$extractDir"/"$name"/wp-config.php | grep "DB_NAME" | cut -d"'" -f 4)
gbddUser=$(cat "$extractPath""$extractDir"/"$name"/wp-config.php | grep "DB_USER" | cut -d"'" -f 4)
gbddPass=$(cat "$extractPath""$extractDir"/"$name"/wp-config.php | grep "DB_PASSWORD" | cut -d"'" -f 4)
gbddAddress=$(cat "$extractPath""$extractDir"/"$name"/wp-config.php | grep "DB_HOST" | cut -d"'" -f 4)
echo "Done"

echo "- Adress : "$gbddAddress
echo "- User : "$gbddUser
echo "- Pass : ************"

while true; do
	read -e -p "Utiser c'est informations pour la base de données ([o]/n): " keepInfo
	keepInfo="${keepInfo:=o}"
	if [[ $keepInfo == "n" ]]; then
		keepInfo=false
		break
	fi
	if [[ $keepInfo == "o" ]]; then
		keepInfo=true
		break
	fi
done

if [[ $keepInfo == false ]]; then
	read -e -p "Nom base de donnée (["$gbddName"]) : " bddName
	read -e -p "Adresse base de donnée (["$gbddAddress"]) : " bddAddress
	read -e -p "Port base de donnée ([3306]) : " bddPort
	read -e -p "Utilisateur base de donnée (["$gbddUser"]) : " bddUser
	read -e -p "Mot de passe base de donnée (["$gbddPass"]) : " bddPass

	bddName="${bddName:=$gbddName}"
	bddAddress="${bddAddress:=$gbddAddress}"
	bddPort="${bddPort:=3306}"
	bddUser="${bddUser:=$gbddUser}"
	bddPass="${bddPass:=$gbddPass}"

	sed -i -E "s/(define\('DB_NAME', ')(.+)('\))/\1"$bddName"\3/" "$extractPath""$extractDir"/"$name"/wp-config.php
	sed -i -E "s/(define\('DB_USER', ')(.+)('\))/\1"$bddUser"\3/" "$extractPath""$extractDir"/"$name"/wp-config.php
	sed -i -E "s/(define\('DB_PASSWORD', ')(.+)('\))/\1"$bddPass"\3/" "$extractPath""$extractDir"/"$name"/wp-config.php
	sed -i -E "s/(define\('DB_HOST', ')(.+)('\))/\1"$bddAddress"\3/" "$extractPath""$extractDir"/"$name"/wp-config.php
else
	bddName=$gbddName
	bddAddress=$gbddAddress
	bddPort=3306
	bddUser=$gbddUser
	bddPass=$gbddPass
fi

if [ $(MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'use mysql' 2>&1 | grep -v "Warning*" | wc -l) -ge 1  ]; then
	echo "Impossible de se connecter au serveur de base de données"
	exit 1
fi

if [ $(MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'use '"$bddName"'' 2>&1 | grep -v "Warning*" | wc -l) -eq 0 ]; then
	bddExist=true
	if [ $(MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'use '"$bddName"';show tables' | wc -l)  -gt "0" ]; then
		echo "Une base de données "$bddname" existe déjà et n'est pas vide"
		exit 1
	fi
else
	bddExist=false
fi
echo $bddExist
echo -n "Restoration de la base de donnée : "
if [[ $bddExist == false ]];then
	MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'CREATE DATABASE `'"$bddName"'` CHARACTER SET utf8 COLLATE utf8_general_ci;'  2>&1 | grep -v "Warning*"
fi

for sqlFile in "$extractPath""$extractDir"/sql/*; do
	MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" "$bddName" < "$sqlFile"
done
echo "Done"

echo -n "Restoration des fichiers : "
mkdir -p "$copyPath"
cp -R "$extractPath""$extractDir"/"$name"/* "$copyPath"
echo "Done"

oldSiteUrl=$(MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'use wpinstall4;SELECT option_value FROM wp_options WHERE option_name="siteurl";' | grep -v option_value)
echo "Le champs siteurl de la base de données indique : "$oldSiteUrl
while true; do
	read -e -p "Voulez vous conserver cette valeur ([o]/n): " keepUrl
	keepUrl="${keepUrl:=o}"
	if [[ $keepUrl == "n" ]]; then
		keepUrl=false
		break
	fi
	if [[ $keepUrl == "o" ]]; then
		keepUrl=true
		break
	fi
done
if [[ $keepUrl == false ]]; then
	read -e -p "Nouvelle valeur pour siteurl (["$oldSiteUrl"]) : " siteUrl
	siteUrl="${siteUrl:=$oldSiteUrl}"
	MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'use wpinstall4; UPDATE wp_options SET option_value="'$siteUrl'" WHERE option_name="siteurl";'
fi

oldHome=$(MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'use wpinstall4;SELECT option_value FROM wp_options WHERE option_name="home";' | grep -v option_value)
echo "Le champs home de la base de données indique : "$oldHome
while true; do
	read -e -p "Voulez vous conserver cette valeur ([o]/n): " keepHome
	keepHome="${keepHome:=o}"
	if [[ $keepHome == "n" ]]; then
		keepHome=false
		break
	fi
	if [[ $keepHome == "o" ]]; then
		keepHome=true
		break
	fi
done
if [[ $keepHome == false ]]; then
	read -e -p "Nouvelle valeur pour home (["$oldHome"]) : " home
	home="${home:=$oldHome}"
	MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'use wpinstall4; UPDATE wp_options SET option_value="'$home'" WHERE option_name="home";'
fi

echo "-----------------------------------------------"
echo "-----------------------------------------------"
echo "||                                           ||"
echo "|| \o/ Récupération de wordpress réussie \o/ ||"
echo "||                                           ||"
echo "-----------------------------------------------"
echo "-----------------------------------------------"
