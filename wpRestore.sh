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

if [[ -d "$installPath" ]]; then
	if [[ ! -z "$(ls -A $installPath)" ]]; then
		echo "Le répertoire" $installPath "existe déjà et n'est pas vide"
		exit 1
	fi
fi

echo -n "Récupération des informations : "
gbddName=$(cat "$extractPath""$extractDir"/"$name"/wp-config.php | grep "DB_NAME" | cut -d"'" -f 4)
gbddUser=$(cat "$extractPath""$extractDir"/"$name"/wp-config.php | grep "DB_USER" | cut -d"'" -f 4)
gbddPass=$(cat "$extractPath""$extractDir"/"$name"/wp-config.php | grep "DB_PASSWORD" | cut -d"'" -f 4)
gbddAddress=$(cat "$extractPath""$extractDir"/"$name"/wp-config.php | grep "DB_HOST" | cut -d"'" -f 4)
echo "Done"

echo "- Nom : "$gbddName
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

echo -n "Restoration des fichiers : "
mkdir -p "$installPath"
cp -R "$extractPath""$extractDir"/"$name"/* "$installPath"
cp "$extractPath""$extractDir"/"$name"/.htaccess "$installPath"
newName=${installPath##*/}
sed -i -E "s@RewriteBase /((.+))/@RewriteBase /$newName/@" "$installPath"/.htaccess
echo "Done"

oldSiteUrl=$(grep siteurl "$extractPath""$extractDir"/sql/wp_options.sql | sed -rn "s/.*?'siteurl','([^']*)/\1@/p" | cut -d"@" -f1)
siteUrl=$oldSiteUrl
echo "Le champs siteurl de la base de données indique : "$oldSiteUrl
while true; do
	read -e -p "Voulez vous conserver cette valeur ([o]/n): " keepUrl
	keepUrl="${keepUrl:=o}"
	if [[ $keepUrl == "n" ]]; then
		read -e -p "Nouvelle valeur pour siteurl (["$oldSiteUrl"]) : " siteUrl
		siteUrl="${siteUrl:=$oldSiteUrl}"
		break
	fi

	if [[ $keepUrl == "o" ]]; then
		siteUrl=$oldSiteUrl
		break
	fi
done


echo -n "Restoration de la base de donnée : "
if [[ $bddExist == false ]];then
	MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" -e 'CREATE DATABASE `'"$bddName"'` CHARACTER SET utf8 COLLATE utf8_general_ci;'  2>&1 | grep -v "Warning*"
fi

for sqlFile in "$extractPath""$extractDir"/sql/*; do
	if [[ $keepUrl == n ]]; then
		sed -i -e "s@$oldSiteUrl@$siteUrl@g" "$sqlFile"
	fi
	MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -P"$bddPort" "$bddName" < "$sqlFile"
done
echo "Done"

read -e -p "Gérer les droits d'accès des fichiers ? ([o]/n) : " fileMode
fileMode="${fileMode:=o}"

if [[ $fileMode == "o" ]]; then
	defaultGroup=$(groups | cut -d' ' -f1)
	read -e -p "Propriétaire des fichiers ([www-data]) : " fileUser
	read -e -p "Groupe des fichiers ([$defaultGroup]) : " fileGroup
	read -e -p "Droits des fichiers ([775]) : " fileValue
	read -e -p "Utiliser sudo ? ([o]/n) : " useSudo
	fileUser="${fileUser:=www-data}"
	fileGroup="${fileGroup:=$defaultGroup}"
	fileValue="${fileValue:=775}"
	useSudo="${useSudo:=o}"

	if [[ $useSudo == "o" ]]; then
		sudo chown -R "$fileUser":"$fileGroup" "$installPath"
		sudo chmod -R "$fileValue" "$installPath"
	else
		chown -R "$fileUser":"$fileGroup" "$installPath"
		chmod -R "$fileValue" "$installPath"
	fi
fi

echo "-----------------------------------------------"
echo "-----------------------------------------------"
echo "||                                           ||"
echo "|| \o/ Récupération de wordpress réussie \o/ ||"
echo "||                                           ||"
echo "-----------------------------------------------"
echo "-----------------------------------------------"
