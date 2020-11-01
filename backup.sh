#!/bin/bash
# delete log
rm -rf *.log
# Get real path
BASEDIR=$(cd `dirname $0` && pwd)
cd ${BASEDIR}
# Log Location on Server.
LOG_LOCATION=${BASEDIR}
exec > >(tee -i $LOG_LOCATION/backup.`date +%Y%m%d%H%M%S`.log)
exec 2>&1

commit_() {
  echo 'commit begin..'
  info=$1
  if ["$info" = ""]; then
   info=":pencil: update content"
  fi
  git add -A
  git commit -m "$info"
  git push origin hexo
  echo 'commit done..'
}

update_() { 
  echo 'update begin'
  git pull origin hexo
  cd ./themes/yun
  git pull hexo
  cd ../../
  hexo clean &&  hexo g && hexo d
  rm -rf /root/www/blog/* && cp -rf ./public/. /root/www/blog
  echo 'update done'
}

type=$1
commit_msg=$2
shift

case $type in
c)
  commit_ "$commit_msg"
  ;;
u)
  update_
  ;;
*) echo '
  打包脚本说明

  Usage:
    sh ./backup.sh type
    ./backup.sh type

  type:
    c 提交git
    u 更新博客

  示例：
    安装: sh ./backup.sh c "hello world"
    重启: sh ./backup.sh u 
  '
  ;;
esac

exit 0

