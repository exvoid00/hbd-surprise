#!/usr/bin/env bash
# Hosting web ultah ke GitHub Pages (gratis, HTTPS).
# Jalankan dari Claude Code dengan:  ! bash "C:/Project/hbd-ultah/deploy_pages.sh"
# Repo yang dibuat = PUBLIK (syarat Pages gratis).
set -e
# pastikan tool dasar (curl, dll) kebaca walau dijalankan dari bash yang PATH-nya minim
export PATH="/usr/bin:/mingw64/bin:/mingw32/bin:/bin:$PATH"
cd "C:/Project/hbd-ultah"

REPO="${1:-hbd-surprise}"

# ambil kredensial github yang udah tersimpan (tanpa sed, pakai bash murni)
USER=""; TOKEN=""
while IFS='=' read -r k v; do
  [ "$k" = "username" ] && USER="$v"
  [ "$k" = "password" ] && TOKEN="$v"
done < <(printf "protocol=https\nhost=github.com\n\n" | git credential fill 2>/dev/null)
[ -z "$TOKEN" ] && { echo "!! Kredensial GitHub tidak ditemukan. Login dulu."; exit 1; }
echo ">> akun: $USER   repo: $REPO"

# 1) buat repo publik (kalau udah ada, dilewati)
CODE=$(curl -s -o /tmp/_gh.json -w "%{http_code}" \
  -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$REPO\",\"private\":false,\"has_issues\":false,\"has_wiki\":false,\"has_projects\":false}")
if [ "$CODE" = "201" ]; then echo ">> repo dibuat";
elif grep -q "name already exists" /tmp/_gh.json; then echo ">> repo sudah ada, lanjut push";
else echo ">> respon buat-repo ($CODE):"; cat /tmp/_gh.json; fi

# 2) push
git branch -M main
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$USER/$REPO.git"
git push -u origin main

# 3) nyalain GitHub Pages (sumber: branch main, root)
curl -s -X POST \
  -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$USER/$REPO/pages" \
  -d "{\"source\":{\"branch\":\"main\",\"path\":\"/\"}}" >/dev/null || true

echo ""
echo "=============================================="
echo " SELESAI! Tunggu ~1-2 menit, lalu buka:"
echo "   https://$USER.github.io/$REPO/"
echo "   Rundown:  https://$USER.github.io/$REPO/rundown.html"
echo "=============================================="
