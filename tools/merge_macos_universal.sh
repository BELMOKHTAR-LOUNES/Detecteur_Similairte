#!/usr/bin/env bash
# Fusionne les builds macOS Intel et Apple Silicon en binaires universels.
# A lancer sur un Mac (lipo et codesign sont necessaires).
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <dossier-intel> <dossier-arm64> <dossier-sortie>" >&2
    exit 1
fi

INTEL_DIR="$1"
ARM_DIR="$2"
OUT_DIR="$3"

merge_tree() {
    local intel="$1"
    local arm="$2"
    local out="$3"
    local src rel other

    echo "==> Fusion de $(basename "$arm")"
    rm -rf "$out"
    cp -R "$arm" "$out"

    # La signature ad-hoc de PyInstaller n'est plus valable apres lipo.
    rm -rf "$out/Contents/_CodeSignature"

    while IFS= read -r -d '' src; do
        rel="${src#$arm/}"
        other="$intel/$rel"

        if [ ! -f "$other" ]; then
            continue
        fi
        if ! file -b "$src" | grep -q "Mach-O"; then
            continue
        fi
        if ! file -b "$other" | grep -q "Mach-O"; then
            continue
        fi

        echo "    lipo $rel"
        lipo -create "$other" "$src" -output "$out/$rel"
        if [ -x "$src" ]; then
            chmod +x "$out/$rel"
        fi
    done < <(find "$arm" -type f -print0)
}

merge_tree "$INTEL_DIR/DetecteurDeSimilarite.app" \
           "$ARM_DIR/DetecteurDeSimilarite.app" \
           "$OUT_DIR/DetecteurDeSimilarite.app"

merge_tree "$INTEL_DIR/CLI-Similarite" \
           "$ARM_DIR/CLI-Similarite" \
           "$OUT_DIR/CLI-Similarite"

echo "==> Signature ad-hoc de l'application"
codesign --force --deep --sign - "$OUT_DIR/DetecteurDeSimilarite.app"

echo "==> Verification des architectures"
lipo -info "$OUT_DIR/DetecteurDeSimilarite.app/Contents/MacOS/DetecteurDeSimilarite"
lipo -info "$OUT_DIR/CLI-Similarite/CLI-Similarite"
