gp ports list | awk -F "|" '
$2 !~  "543." && /private/ {
    gsub(/ /,"")
    system("gp ports visibility "$2":public")
}
$2 !~  "543." && /http/ {
    print $2, $5
}
' > public-ports.md
git commit -m "public ports $(date)" public-ports.md
git push
