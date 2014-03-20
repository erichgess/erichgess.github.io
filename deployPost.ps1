# deployPost.ps1

rm -r c:\temp\*
xcopy .\public\* c:\temp /E
git checkout master
xcopy c:\temp\* .\ /E /Y
git add .
git commit -m "deploying posts"
git push origin