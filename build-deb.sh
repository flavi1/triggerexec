#!/bin/sh
# build-deb.sh

set -e

PACKAGE_NAME="triggerexec"
BUILD_DIR="/tmp/triggerexec-build"

# Calcul automatique de la version basée sur Git (ex: 0.1.42)
GIT_COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "1")
VERSION="0.1.$GIT_COMMIT_COUNT"

echo "=== Construction du paquet .deb pour $PACKAGE_NAME (Version: $VERSION) ==="

# 1. Nettoyage et création de l'arborescence temporaire
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/etc/triggerexec.d"
mkdir -p "$BUILD_DIR/etc/systemd/system"

# 2. Copie des fichiers sources et du service systemd
cp -av triggerexec "$BUILD_DIR/usr/local/bin/"
chmod +x "$BUILD_DIR/usr/local/bin/triggerexec"

cat << 'EOF' > "$BUILD_DIR/etc/systemd/system/triggerexec.service"
[Unit]
Description=Triggerexec Daemon (Joystick & IR Event Manager)
After=network.target graphical.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/triggerexec
Restart=always
RestartSec=3

# Sécurité / Environnement de base
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-graphical.target
EOF

# 3. Génération dynamique du fichier control (ajout de python3-evdev dans les dépendances si besoin)
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: triggerexec
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: flavi1 <votre.email@domain.com>
Depends: python3, python3-pygame, python3-evdev
Description: Démon d'interception de manettes via SDL avec gestion par fenêtre active.
 Intercepte les événements de joystick/gamepad, gère les combinaisons de touches
 et exécute des commandes shell selon la classe de la fenêtre active.
EOF

# 4. Script postinst (activation et démarrage du service systemd)
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/sh
set -e
mkdir -p /etc/triggerexec.d

# Recharge systemd, active et démarre le service
if [ -d /run/systemd/system ]; then
    systemctl daemon-reload
    systemctl enable triggerexec.service
    systemctl restart triggerexec.service
fi

echo "triggerexec installé et service activé avec succès."
exit 0
EOF
chmod +x "$BUILD_DIR/DEBIAN/postinst"

# 5. Script prerm (arrêt propre du service avant désinstallation/mise à jour)
cat << 'EOF' > "$BUILD_DIR/DEBIAN/prerm"
#!/bin/sh
set -e
if [ -d /run/systemd/system ]; then
    systemctl stop triggerexec.service || true
    systemctl disable triggerexec.service || true
fi
exit 0
EOF
chmod +x "$BUILD_DIR/DEBIAN/prerm"

# 6. Script postrm (nettoyage systemd lors de la suppression définitive du paquet)
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postrm"
#!/bin/sh
set -e
if [ "$1" = "purge" ] || [ "$1" = "remove" ]; then
    if [ -d /run/systemd/system ]; then
        systemctl daemon-reload
    fi
fi
exit 0
EOF
chmod +x "$BUILD_DIR/DEBIAN/postrm"

# 7. Construction du paquet final avec l'option rootless
dpkg-deb --root-owner-group --build "$BUILD_DIR" .

# Nettoyage
rm -rf "$BUILD_DIR"

echo "=== Paquet généré avec succès ($VERSION) ! ==="
ls -l ${PACKAGE_NAME}_*.deb
