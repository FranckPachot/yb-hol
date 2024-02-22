{
    gp ports list | awk -F "|" '
BEGIN {
    print "## Public ports from current workshop\n\n"
}
$2 ~  re && /\(private\)/ {
    system("gp ports visibility "gensub(/ /,"","g",$2)":public")
}
$2 ~  re && / http / {
    print " - ", $2, $5
}
' re=" (15433|700.|900.|9090|3000) " > current-workshop-public-ports.md
git commit -m "public ports $(date)"   current-workshop-public-ports.md
git push 
} >/dev/null 2>&1                              
