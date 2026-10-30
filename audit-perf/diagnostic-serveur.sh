#!/usr/bin/env bash
# =============================================================================
# EPAVIE / SENDRA — diagnostic serveur (LECTURE SEULE)
# -----------------------------------------------------------------------------
# Ne modifie rien, ne redémarre rien, n'affiche aucun mot de passe ni secret.
# Usage (en root sur le serveur) :
#     bash diagnostic-serveur.sh
# Résultat : /root/diag-epavie-AAAAMMJJ-HHMM.txt  (à rapatrier par scp)
# Optionnel : MYSQL_OPTS="-u root -p" bash diagnostic-serveur.sh
#             (sinon le script essaie ~/.my.cnf / socket root sans mot de passe)
# =============================================================================
set -u
OUT="/root/diag-epavie-$(date +%Y%m%d-%H%M).txt"
MYSQL_OPTS="${MYSQL_OPTS:-}"
exec > >(tee "$OUT") 2>&1

sec() { printf '\n\n==================== %s ====================\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; timeout 60 bash -c "$*" 2>&1 | head -n "${LIMIT:-200}"; }
my()  { timeout 60 mysql $MYSQL_OPTS -N -B -e "$1" 2>&1 | head -n "${LIMIT:-200}"; }

sec "1. MACHINE"
run "date; hostname; cat /etc/os-release | head -4; uname -r"
run "uptime"
run "nproc; lscpu | grep -E 'Model name|Socket|Thread|Core|MHz' "
run "free -m"
run "swapon --show"
run "df -hT -x tmpfs -x devtmpfs"
run "vmstat 2 6"
run "cat /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io 2>/dev/null"

sec "2. QUI CONSOMME (RAM / CPU)"
LIMIT=25 run "ps -eo pid,user,%cpu,%mem,rss,etime,comm --sort=-rss | head -25"
LIMIT=25 run "ps -eo pid,user,%cpu,%mem,rss,etime,comm --sort=-%cpu | head -25"
run "ps -eo rss,comm | awk '{m[\$2]+=\$1; n[\$2]++} END {for (c in m) printf \"%8.0f Mo  %4d proc  %s\n\", m[c]/1024, n[c], c}' | sort -rn | head -20"
run "command -v docker >/dev/null && docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' && docker stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'"
run "systemctl list-units --type=service --state=running --no-pager | grep -E -i 'httpd|apache|nginx|php|mysql|maria|odoo|redis|docker|supervisor|fail2ban|firewalld|cron'"

sec "3. ALERTES PASSEES : OOM / CRASH / REDEMARRAGES"
run "journalctl -k --since '-30 days' --no-pager | grep -i -E 'out of memory|oom-kill|killed process' | tail -30"
run "dmesg -T 2>/dev/null | grep -i -E 'oom|killed process' | tail -20"
run "last -x reboot shutdown | head -10"
run "journalctl --since '-7 days' --no-pager -p err | grep -v -i 'sshd' | tail -40"
run "command -v sar >/dev/null && sar -r -f /var/log/sa/sa\$(date -d yesterday +%d) 2>/dev/null | tail -5; command -v sar >/dev/null && sar -u 2>/dev/null | tail -5"

sec "4. APACHE"
run "httpd -V 2>/dev/null || apache2 -V"
run "(httpd -M 2>/dev/null || apache2ctl -M) | grep -E -i 'mpm|php|proxy_fcgi|http2|deflate|expires|headers|ssl|security|evasive|qos'"
run "grep -R -h -i -E '^\s*(ServerLimit|MaxRequestWorkers|MaxClients|StartServers|MinSpareServers|MaxSpareServers|ThreadsPerChild|MaxConnectionsPerChild|KeepAlive|KeepAliveTimeout|MaxKeepAliveRequests|Timeout|LoadModule mpm)' /etc/httpd/ /etc/apache2/ 2>/dev/null | sort | uniq"
run "grep -R -l -i -E 'ServerName' /etc/httpd/conf.d/ /etc/apache2/sites-enabled/ 2>/dev/null"
run "grep -R -h -i -E '^\s*(ServerName|ServerAlias|DocumentRoot|CustomLog|ErrorLog|SetHandler|ProxyPass|<VirtualHost)' /etc/httpd/conf.d/ /etc/apache2/sites-enabled/ 2>/dev/null"
run "pgrep -c httpd; pgrep -c apache2"

sec "5. PHP"
run "php -v"
run "php -m | tr '\n' ' '"
run "php -i | grep -E -i '^(memory_limit|max_execution_time|upload_max_filesize|post_max_size|max_input_time|realpath_cache_size|opcache.enable |opcache.enable_cli|opcache.memory_consumption|opcache.max_accelerated_files|opcache.validate_timestamps|opcache.revalidate_freq|opcache.jit|display_errors|expose_php|session.save_handler)'"
run "ls /etc/php-fpm.d/ /etc/php/*/fpm/pool.d/ /etc/opt/remi/*/php-fpm.d/ 2>/dev/null"
run "grep -h -E '^\s*(pm|pm\.max_children|pm\.start_servers|pm\.min_spare_servers|pm\.max_spare_servers|pm\.max_requests|request_terminate_timeout|listen|user|php_admin_value\[memory_limit\]|slowlog|request_slowlog_timeout)\s*=' /etc/php-fpm.d/*.conf /etc/php/*/fpm/pool.d/*.conf /etc/opt/remi/*/php-fpm.d/*.conf 2>/dev/null"
run "grep -i -h -E 'max_children|server reached|slow' /var/log/php-fpm/*.log /var/log/php*-fpm.log 2>/dev/null | tail -20"
run "ps -C php-fpm -o rss= 2>/dev/null | awk '{s+=\$1;n++} END {if(n) printf \"php-fpm : %d process, %.0f Mo au total, %.0f Mo en moyenne\n\", n, s/1024, s/1024/n}'"
run "ps -C httpd -o rss= 2>/dev/null | awk '{s+=\$1;n++} END {if(n) printf \"httpd : %d process, %.0f Mo au total, %.0f Mo en moyenne\n\", n, s/1024, s/1024/n}'"

sec "6. LARAVEL (backend, back-office, préprod) — sans secrets"
for d in /var/www/backendSendra /var/www/sendraApp $(ls -d /var/www/*preprod* /var/www/*Preprod* 2>/dev/null); do
  [ -f "$d/.env" ] || continue
  echo; echo "---- $d"
  grep -E '^(APP_ENV|APP_DEBUG|APP_URL|LOG_CHANNEL|LOG_LEVEL|CACHE_DRIVER|CACHE_STORE|QUEUE_CONNECTION|SESSION_DRIVER|DB_HOST|DB_DATABASE|JWT_TTL|JWT_REFRESH_TTL|JWT_BLACKLIST_ENABLED|FILESYSTEM_DISK|MAIL_MAILER|REDIS_HOST)=' "$d/.env"
  grep -q '^JWT_TTL=' "$d/.env" || echo "JWT_TTL absent du .env"
  echo "config/route en cache :"; ls -la "$d/bootstrap/cache/" 2>/dev/null | grep -E 'config|routes|events|packages'
  echo "taille logs :"; du -sh "$d/storage/logs" 2>/dev/null; ls -la "$d/storage/logs" 2>/dev/null | tail -5
  echo "erreurs des 7 derniers jours (par type) :"
  find "$d/storage/logs" -name '*.log' -mtime -7 -exec grep -h -o -E 'local\.(ERROR|CRITICAL|ALERT|EMERGENCY): [^{]{0,90}|production\.(ERROR|CRITICAL|ALERT|EMERGENCY): [^{]{0,90}' {} + 2>/dev/null | sort | uniq -c | sort -rn | head -15
  echo "stockage :"; du -sh "$d/storage/app" 2>/dev/null
  echo "git :"; git -C "$d" --no-optional-locks log -1 --format='%h %cd %s' 2>/dev/null
done

sec "7. MYSQL / MARIADB"
run "mysql --version"
my "SELECT VERSION();"
my "SHOW GLOBAL VARIABLES WHERE Variable_name IN ('innodb_buffer_pool_size','max_connections','thread_cache_size','table_open_cache','tmp_table_size','max_heap_table_size','innodb_log_file_size','innodb_flush_log_at_trx_commit','slow_query_log','slow_query_log_file','long_query_time','query_cache_type','query_cache_size','wait_timeout','bind_address','skip_networking','performance_schema');"
my "SHOW GLOBAL STATUS WHERE Variable_name IN ('Uptime','Threads_connected','Threads_running','Max_used_connections','Aborted_connects','Slow_queries','Questions','Created_tmp_disk_tables','Created_tmp_tables','Innodb_buffer_pool_reads','Innodb_buffer_pool_read_requests','Select_full_join','Select_scan','Sort_merge_passes','Table_locks_waited');"
my "SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024,1) AS Mo FROM information_schema.tables GROUP BY table_schema ORDER BY Mo DESC;"
my "SELECT table_name, table_rows, ROUND((data_length+index_length)/1024/1024,2) AS Mo FROM information_schema.tables WHERE table_schema='sendra' ORDER BY (data_length+index_length) DESC LIMIT 20;"
my "SELECT table_name, index_name, GROUP_CONCAT(column_name ORDER BY seq_in_index) FROM information_schema.statistics WHERE table_schema='sendra' AND table_name IN ('car_positions','car_photos','signalement_status_history','users','user_verification_codes','missions','mission_vehicle','mission_removals') GROUP BY table_name, index_name;"
my "SELECT user, host FROM mysql.user;"
run "f=\$(mysql $MYSQL_OPTS -N -B -e \"SELECT @@slow_query_log_file\" 2>/dev/null); [ -n \"\$f\" ] && [ -f \"\$f\" ] && tail -60 \"\$f\""

sec "8. TRAFIC REEL (logs Apache, 7 derniers jours)"
for log in $(ls /var/log/httpd/*access*log /var/log/apache2/*access*log 2>/dev/null); do
  [ -s "$log" ] || continue
  echo; echo "---- $log ($(wc -l < "$log") lignes)"
  echo "pic de requêtes par minute (top 5) :"
  awk '{print substr($4,2,17)}' "$log" | sort | uniq -c | sort -rn | head -5
  echo "requêtes par jour :"
  awk '{print substr($4,2,11)}' "$log" | uniq -c | tail -7
  echo "IP distinctes par jour (≈ utilisateurs) :"
  awk '{print substr($4,2,11), $1}' "$log" | sort -u | awk '{print $1}' | uniq -c | tail -7
  echo "top endpoints :"
  awk '{print $6, $7}' "$log" | sed -E 's/\?.*//; s#/[0-9]+(/|$)#/{id}\1#g' | sort | uniq -c | sort -rn | head -15
  echo "codes HTTP :"
  awk '{print $9}' "$log" | sort | uniq -c | sort -rn | head -8
  echo "top IP (possibles robots / attaques) :"
  awk '{print $1}' "$log" | sort | uniq -c | sort -rn | head -8
  echo "scans suspects (wp-, .env, phpmyadmin, adminer) :"
  grep -c -i -E 'wp-login|wp-admin|/\.env|phpmyadmin|adminer|/\.git' "$log"
done

sec "9. SECURITE RESEAU"
run "ss -tlnp | awk 'NR==1 || /LISTEN/'"
run "firewall-cmd --state 2>/dev/null && firewall-cmd --list-all 2>/dev/null; command -v ufw >/dev/null && ufw status verbose; iptables -S 2>/dev/null | head -30"
run "command -v fail2ban-client >/dev/null && fail2ban-client status"
run "sshd -T 2>/dev/null | grep -E -i '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries|x11forwarding)'"
run "journalctl -u sshd --since '-7 days' --no-pager 2>/dev/null | grep -c -i 'failed password'"
run "getenforce 2>/dev/null"
run "ls -la /var/www/ | head -40"
run "crontab -l 2>/dev/null; ls /etc/cron.d/; crontab -u apache -l 2>/dev/null"
run "command -v certbot >/dev/null && certbot certificates 2>/dev/null | grep -E 'Domains|Expiry'"
run "dnf -q check-update --security 2>/dev/null | head -20 || yum -q check-update --security 2>/dev/null | head -20 || apt list --upgradable 2>/dev/null | head -20"

sec "FIN"
echo "Fichier : $OUT"
echo "A rapatrier depuis PowerShell :"
echo "  scp root@<serveur>:$OUT C:\\Projets\\sendrapp\\sendra\\audit-perf\\"
