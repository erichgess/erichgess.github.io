# deployPost.ps1

rm -r c:\temp\*
xcopy .\public\* c:\temp /E
git checkout master
xcopy c:\temp\* .\public /E /Y