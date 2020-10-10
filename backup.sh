info=$1
if ["$info" = ""]; then
  info=":pencil: update content"
fi
git add -A
git commit -m "$info"
git push origin hexo

cd ./themes/yun
git pull

cd ../../
hexo clean &&  hexo g && hexo d

rm -rf /root/www/blog/*
cp -rf ./public/. /root/www/blog

