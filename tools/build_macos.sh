#!/usr/bin/env bash
# Construit les executables macOS (application .app + CLI) depuis la racine du projet.
# A lancer sur un Mac, pas depuis Windows : PyInstaller ne cross-compile pas.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PYTHON="${PYTHON:-python3}"

echo "==> Installation des dependances"
"$PYTHON" -m pip install --upgrade pip
"$PYTHON" -m pip install -r requirements.txt
"$PYTHON" -m pip install pyinstaller

echo "==> Construction de l'application graphique (.app)"
"$PYTHON" -m PyInstaller tools/detecteur_similarite.spec --noconfirm

echo "==> Construction de la ligne de commande"
"$PYTHON" -m PyInstaller tools/cli_similarite.spec --noconfirm

echo "==> Ajout du jeu d'exemples dans les dossiers de distribution"
for target in DetecteurDeSimilarite CLI-Similarite; do
    rm -rf "dist/$target/samples"
    cp -R samples "dist/$target/samples"
done

echo "==> Termine"
echo "    dist/DetecteurDeSimilarite/DetecteurDeSimilarite.app"
echo "    dist/CLI-Similarite/CLI-Similarite"
echo
echo "Si macOS bloque l'ouverture :"
echo "    xattr -dr com.apple.quarantine dist/DetecteurDeSimilarite/DetecteurDeSimilarite.app"
