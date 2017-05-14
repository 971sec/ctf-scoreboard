#!/bin/bash
# simple scoring bot for 971sec CTF

RED=$(tput setaf 1)
GRN=$(tput setaf 2)
YEL=$(tput setaf 3)
BLU=$(tput setaf 4)
NOC=$(tput sgr0)

# this array contains the IP's of the systems to be status polled
declare -a HOSTS=(10.0.1.50 10.0.4.50)

echo "${RED}Setting scoreboard files to ZERO${NOC}"
for HOST in "${HOSTS[@]}" ; do
  echo "0" > score_$HOST
done

scan_http(){
  echo "Scoring HTTP"
  SERVICE="HTTP"
  for HOST in "${HOSTS[@]}" ; do
    TOKEN=`wget --tries=1 --connect-timeout=1 -qO- http://$HOST/ctf/token.php`
    if [ "$TOKEN" = "0ecbc036bd561e8c661998c1e08b3882" ]; then
      score_up
    else
      score_dn
    fi
  done
}

scan_ftp(){
  echo "Scoring FTP"
  SERVICE="FTP"
  for HOST in "${HOSTS[@]}" ; do
    TOKEN=`wget --tries=1 --connect-timeout=1 --user=ftpbot --password="gwtd112uvn" -qO- ftp://$HOST/token | sed 's/\r$//g'`
    if [ "$TOKEN" = "baee2cffe52758faae5c0053b0d11997" ]; then
      score_up
    else
      score_dn
    fi
  done
}

scan_ssh(){
  echo "Scoring SSH"
  SERVICE="SSH"
  for HOST in "${HOSTS[@]}" ; do
    TOKEN=`sshpass -p 'xxxp8wo994' ssh -o ConnectTimeout=1 -q sshbot@$HOST "cat /etc/issue.net" | sed 's/\r$//g'`
    if [ "$TOKEN" = "d0daace804efef8a387f0eef544ecf2d" ]; then
      score_up
    else
      score_dn
    fi
  done
}

scan_dns(){
  echo "Scoring DNS"
  SERVICE="DNS"
  for HOST in "${HOSTS[@]}" ; do
    TOKEN=`dig 228a8a2f686c35ad87145acce850e2cd.ctf.com +short +time=1 +tries=1 @$HOST`
    if [ "$TOKEN" = "127.0.2.1" ]; then
      score_up
    else
      score_dn
    fi
  done
}

scan_imap(){
  echo "Scoring IMAP"
  SERVICE="IMAP"
  for HOST in "${HOSTS[@]}" ; do
    rm -f mail_$HOST &>/dev/null
    curl --silent --connect-timeout 1 --max-time 1 --url "imap://$HOST/INBOX;UID=1" --user "mailbot:49r9sg0zea" > mail_$HOST
    TOKEN=$(grep Subject mail_$HOST | sed 's/\r$//g' | sed 's/Subject: //g')
    if [[ $TOKEN = 02622df88be43c8fea763de7e8b963d8 ]]; then
      score_up
    else
      score_dn
    fi
  done
}

score_up(){
  OLDSCORE=`cut -d '=' -f2 score_$HOST`
  NEWSCORE=$((OLDSCORE+1))
  sed -i "s/$OLDSCORE/$NEWSCORE/g" score_$HOST
  echo "<span class=\"status_up\">${SERVICE}</span>" > ${SERVICE}_$HOST.shtml
  echo "${GRN}$HOST +1${NOC}"
}

score_dn(){
  echo "<span class=\"status_dn\">${SERVICE}</span>" > ${SERVICE}_$HOST.shtml
  echo "${RED}$HOST --${NOC}"
}

main(){
  scan_http
  scan_ftp
  scan_ssh
  scan_dns
  scan_imap
  sleep 5
  main
}

main
