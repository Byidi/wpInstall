# wpInstall

Collections de scripts pour wordpress.

wpInstall.sh :
    - Télécharge la dernière version de wordpress
    - Extrait l'archive et la déplace à l'emplacement indiqué
    - Crée la base de données
    - Génère le fichier wp-config.php

    ./wpInstall.sh [chemin d'installation]

    ex : ./wpInstall.sh /var/www/html/wordpress

wpChildTheme.sh :

    - Liste les thèmes installé
    - Crée un thème enfant du thème sélectionné
    - Génère les fichiers style.csse et functions.php

    ./wpChildTheme.sh [chemin du wordpress]

    ex : ./wpChildTheme.sh /var/www/html/wordpress
