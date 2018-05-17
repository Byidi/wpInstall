#! /bin/bash
#

if [[ -z "$1" ]]; then
	echo "wpChildTheme.sh [chemin du wordpress]"
	exit 1
fi
path=${1%/}

parentSelected=false

while [ "$parentSelected" == false ]; do
	clear
	
	if [ ! -z "$themeParent" ]; then
		echo "/!\\ "$themeParent" n'est pas une option valide /!\\"
	fi
	
	nbTheme=$(ls -d "$path"/wp-content/themes/*/ | wc -l)
	echo "Theme installés : "$nbTheme

	cmp=0
	dirArray=()
	for D in `find "$path"/wp-content/themes/ -maxdepth 1 -type d`; do
		tmp=${D%/}
		dirName=${tmp##*/}
		if [ $dirName != "themes" ]; then
			echo $cmp")" $dirName
		fi 
		dirArray[$cmp]="$dirName"
		cmp=$((cmp+1))
	done

	read -e -p "Numéro du theme parent : " themeParent
	
	if [ "$themeParent" -ge 1 -a "$themeParent" -le "$nbTheme" ]; then
		parentSelected=true
		parentName=${dirArray[(($themeParent))]}
		childName=$parentName"-child"
	fi
done


mkdir $path"/wp-content/themes/"$childName
echo -e "/*\nTheme Name: "$childName"\nDescription: \nAuthor: "$(whoami)"\nAuthor URI:\nTemplate: "$parentName"\nVersion: 1.0\n*/" > $path"/wp-content/themes/"$childName"/style.css"
echo -e "<?php\nadd_action( 'wp_enqueue_scripts', 'theme_enqueue_styles' );\nfunction theme_enqueue_styles() {\n\twp_enqueue_style( 'parent-style', get_template_directory_uri() . '/style.css' );\n}" > $path"/wp-content/themes/"$childName"/functions.php"

echo "----------------------------------------------"
echo "----------------------------------------------"
echo "||                                          ||"
echo "|| \o/ Création du thème enfant réussie \o/ ||"
echo "||                                          ||"
echo "----------------------------------------------"
echo "----------------------------------------------"
