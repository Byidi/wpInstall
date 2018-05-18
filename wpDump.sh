#! /bin/bash
#

clear

if [[ -z "$2" ]]; then
	echo "wpDump.sh [chemin du wordpress] [chemin de sauvegarde]"
	exit 1
fi

path=${1%/}
savePath=${2%/}
name=${path##*/}
bddName=${name/ /_}
saveDate=$(date +%Y%m%d_%H%M%S)


echo -n "Récupération des informations : "
bddName=$(cat "$path"/wp-config.php | grep "DB_NAME" | cut -d"'" -f 4)
bddUser=$(cat "$path"/wp-config.php | grep "DB_USER" | cut -d"'" -f 4)
bddPass=$(cat "$path"/wp-config.php | grep "DB_PASSWORD" | cut -d"'" -f 4)
bddAddress=$(cat "$path"/wp-config.php | grep "DB_HOST" | cut -d"'" -f 4)
echo "Done"
echo "- Database name : "$bddName
echo "- User : "$bddUser
echo "- Pass : ************"
echo "- Adress : "$bddAddress

echo -n "Création des répertoires : "
mkdir -p "$savePath"/"$name"/"$name"_"$saveDate"/sql
echo "Done"

echo -n "Exportation des tables : "
tables=$(MYSQL_PWD="$bddPass" mysql -u "$bddUser" -h "$bddAddress" -e "use "$bddName";show tables;" | tr -d "| " | grep -v "Tables_in_")

for table in $tables; do
	MYSQL_PWD="$bddPass" mysqldump -u "$bddUser"  "$bddName" --single-transaction --skip-lock-tables "$table" > "$savePath"/"$name"/"$name"_"$saveDate"/sql/"$table".sql
done
echo "Done"

echo -n "Copie des fichiers : "
cp -R $path "$savePath"/"$name"/"$name"_"$saveDate"/
echo "Done"

echo -n "Compression de la sauvegarde : "
cd "$savePath"/"$name"/
tar -czf "$name"_"$saveDate".tar.gz "$name"_"$saveDate"/
echo "Done"

echo -n "Nettoyage : "
cd "$savePath"
rm -r "$name"/"$name"_"$saveDate"/
echo "Done"
