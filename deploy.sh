bundle exec rake generate
rm -fR /tmp/blog
mkdir /tmp/blog
cp -R ./public/* /tmp/blog/.
git checkout master
cp -R /tmp/blog/* .
git add .
git commit -m 'deploying posts'
git push origin
git checkout source
