-------------------------------------------------------------------------

wpTools : Collection de scripts pour wordpress.

-------------------------------------------------------------------------

<h2>wpInstall :</h2>
- Télécharge la dernière version de wordpress
- Extrait l'archive et la déplace à l'emplacement indiqué
- Crée la base de données
- Génère le fichier wp-config.php

    ./wpInstall.sh [chemin d'installation]

    ex : $ ./wpInstall.sh /var/www/html/wordpress

-------------------------------------------------------------------------

<h2>wpChildTheme :</h2>

- Liste les thèmes installé
- Crée un thème enfant du thème sélectionné
- Génère les fichiers style.csse et functions.php
    
    ./wpChildTheme.sh [chemin du wordpress]

    ex : ./wpChildTheme.sh /var/www/html/wordpress

-------------------------------------------------------------------------

<h2>wpDump :</h2>

- Exporte les tables de la base de données 
- Copie les fichiers du wordpress
- Compresse le tout
    
    ./wpDump.sh [chemin du wordpress] [chemin de sauvegarde]

    ex : ./wpDump.sh ~/backup/
    
-------------------------------------------------------------------------

<h2>wpRestore :</h2>

- Extrait une sauvegarde effectuée avec wpDump.sh
- Restaure les tables de la base de données 
- Restaure les fichiers du wordpress
- Changement des informations de la base de donnée possible
    
    ./wpRestore.sh [chemin de la sauvegarde] [chemin d'installation]

    ex : ./wpRestore.sh ~/backup/wordpress_20180518_091853.tar.gz /var/www/html/
