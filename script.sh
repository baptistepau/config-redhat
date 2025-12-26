#!/bin/bash
while true; do
    echo "Menu de choix:"
    echo "1. Installer les depot"
    echo "2. Installer les application"
    echo "3. Mettre a jour le systeme"
    echo "4. Quitter"
    
    read -p "Entrez votre choix (1-4): " choix
    
    case $choix in
        1)
            
            if [ "$EUID" -ne 0 ]; then
                echo "Cette fonction dois etre lancer en root ."
                echo "Veuillez réessayer avec: sudo $0"
            else 
                echo "Installation des dépôts..."
                # Détecter la version majeure de RHEL (9/10)
                if RHEL_MAJOR=$(rpm -E %rhel 2>/dev/null); then
                    : # ok
                else
                    # Fallback via /etc/os-release
                    if [ -r /etc/os-release ]; then
                        . /etc/os-release
                        RHEL_MAJOR=${VERSION_ID%%.*}
                    fi
                fi
                if [ -z "$RHEL_MAJOR" ]; then
                    echo "Impossible de détecter la version RHEL, on suppose 9."
                    RHEL_MAJOR=9
                fi

                echo "Activation des dépôts Red Hat essentiels pour RHEL ${RHEL_MAJOR}..."
                if command -v subscription-manager >/dev/null 2>&1; then
                    CRB="codeready-builder-for-rhel-${RHEL_MAJOR}-x86_64-rpms"
                    SUPP="rhel-${RHEL_MAJOR}-for-x86_64-supplementary-rpms"
                    HA="rhel-${RHEL_MAJOR}-for-x86_64-highavailability-rpms"
                    subscription-manager repos --enable "$SUPP" --enable "$CRB" --enable "$HA"
                else
                    echo "subscription-manager introuvable, on saute l'activation RHEL spécifique."
                fi

                echo "Configuration du dépôt VSCode..."
                rpm --import https://packages.microsoft.com/keys/microsoft.asc
                echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
                
                echo "Installation des dépôts additionnels (EPEL, RPMFusion) pour EL ${RHEL_MAJOR}..."
                EPEL_URL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL_MAJOR}.noarch.rpm"
                RPMFUSION_URL="https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${RHEL_MAJOR}.noarch.rpm"
                dnf install -y -q "$EPEL_URL"
                # HA déjà activé plus haut si disponible
                dnf install -y -q --nogpgcheck "$RPMFUSION_URL"
                dnf install -y -q rpmfusion-nonfree-release-tainted || true
                
                echo "Nettoyage du cache..."
                dnf clean all
                echo "✓ Dépôts installés avec succès (RHEL ${RHEL_MAJOR}) !"
            fi
            exit 0
            ;;
        2)
            if [ "$EUID" -ne 0 ]; then
                echo "Cette fonction dois etre lancer en root ."
                echo "Veuillez réessayer avec: sudo $0"
                exit 1
            else 
                echo "=========================================="
                echo "Installation de l'environnement de compilation"
                echo "=========================================="
                apps=$(grep -v '^#' app.txt | tr '\n' ' ')
                remove=$(grep -v '^#' remove.txt | tr '\n' ' ')
                
                echo "Mise à jour du système..."
                dnf update -y -q 
                
                echo "Suppression des applications inutiles..."
                dnf remove -y -q $remove
                
                echo "Installation des applications et dépendances..."
                echo "- VSCode"
                echo "- Git" 
                echo "- Python 3.13"
                echo "- Dépendances de développement (GCC, Make, Autotools...)"
                echo "- Bibliothèques de développement"
                dnf install -y -q $apps
                
                echo "=========================================="
                echo "Installation terminée !"
                echo "=========================================="
                echo ""
                echo "Vérification des installations:"
                echo "Python 3.13: $(python3.13 --version 2>/dev/null || echo 'Non trouvé')"
                echo "Git: $(git --version 2>/dev/null || echo 'Non trouvé')"
                echo "GCC: $(gcc --version | head -1 2>/dev/null || echo 'Non trouvé')"
                echo ""
                echo "Redémarrage du système..."
                reboot
            fi 
            exit 0
            ;;
        3)
            if [ "$EUID" -ne 0 ]; then
                echo "Cette fonction dois etre lancer en root ."
                echo "Veuillez réessayer avec: sudo $0"
            else
                echo "Mise à jour du système..."
                dnf update -y -q
                echo "✓ Mise à jour terminée !"
            fi
            ;;
        4)
            echo "Au revoir!"
            exit 0
            ;;
        *)
            echo "Choix invalide. Veuillez entrer un nombre entre 1 et 4."
            ;;
    esac
    
    echo # Ligne vide pour la lisibilité
done