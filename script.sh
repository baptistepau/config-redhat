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
                echo "Installation de depot"
                subscription-manager repos --enable "rhel-9-for-x86_64-supplementary-rpms" --enable "codeready-builder-for-rhel-9-x86_64-rpms" --enable "rhel-9-for-x86_64-highavailability-rpms" 
                dnf install flatpak -y -q
                flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
                rpm --import https://packages.microsoft.com/keys/microsoft.asc
                echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
                dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
                subscription-manager repos --enable "rhel-9-for-x86_64-highavailability-rpms" 
                dnf  install --nogpgcheck https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm
                dnf install rpmfusion-nonfree-release-tainted
                dnf clean all
                echo "Depot installer"
            fi
            exit 0
            ;;
        2)
            if [ "$EUID" -ne 0 ]; then
                echo "Cette fonction dois etre lancer en root ."
                echo "Veuillez réessayer avec: sudo $0"
                exit 1
            else 
                apps=$(grep -v '^#' app.txt | tr '\n' ' ')
                remove=$(grep -v '^#' remove.txt | tr '\n' ' ')
                appflatpack=$(grep -v '^#' flapack.txt | tr '\n' ' ')
                dnf update -y -q 
                dnf remove -y -q $remove
                dnf install -y -q $apps
                flatpak install flathub $appflatpack -y > /dev/null 2>&1
                reboot
            fi 
            exit 0
            ;;
        3)
            echo "Mise en place des mise a jour"
            dnf update -y -q
            flatpak update -y > /dev/null 2>&1

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