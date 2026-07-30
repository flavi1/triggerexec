#!/bin/bash
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

# 2. Copie des fichiers sources
cp -av triggerexec "$BUILD_DIR/usr/local/bin/"
chmod +x "$BUILD_DIR/usr/local/bin/triggerexec"

# 3. Génération dynamique du fichier control avec la bonne version
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: triggerexec
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: flavi1 <votre.email@domain.com>
Depends: python3, python3-evdev, kdotool
Description: Démon d'interception d'événements input avec gestion par fenêtre active.
 Intercepte /dev/input/event*, gère les combinaisons de touches et exécute
 des commandes shell selon la classe de la fenêtre active.
EOF

# 4. Script postinst
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/sh
set -e
mkdir -p /etc/triggerexec.d
echo "triggerexec installé avec succès. Pensez à ajouter vos fichiers de configuration dans /etc/triggerexec.d/"
exit 0
EOF
chmod +x "$BUILD_DIR/DEBIAN/postinst"

# 5. Construction du paquet final avec l'option rootless
dpkg-deb --root-owner-group --build "$BUILD_DIR" .

# Nettoyage
rm -rf "$BUILD_DIR"

echo "=== Paquet généré avec succès ($VERSION) ! ==="
ls -l ${PACKAGE_NAME}_*.deb
