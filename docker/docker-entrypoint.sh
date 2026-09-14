#!/bin/sh
set -e

mkdir -p /etc/nginx/conf.d /var/www/tstat/rrd_images /var/www/tstat/rrd_gallery

AUTH_CONF=/etc/nginx/conf.d/auth.conf

if [ -n "$BASIC_AUTH_USER" ] && [ -n "$BASIC_AUTH_PASS" ]; then
    htpasswd -bc /etc/nginx/.htpasswd "$BASIC_AUTH_USER" "$BASIC_AUTH_PASS" >/dev/null
    cat > "$AUTH_CONF" <<EOF
auth_basic "Tstat RRD Viewer";
auth_basic_user_file /etc/nginx/.htpasswd;
EOF
    echo "[entrypoint] Basic auth ENABLED (user: $BASIC_AUTH_USER)"
else
    : > "$AUTH_CONF"
    echo "[entrypoint] Basic auth disabled (set BASIC_AUTH_USER and BASIC_AUTH_PASS to enable)"
fi

rm -f /run/fcgiwrap.socket
fcgiwrap -s unix:/run/fcgiwrap.socket &
FCGIWRAP_PID=$!

# wait for the socket to appear, then relax its permissions so the
# nginx worker (running as www-data) can connect to it
for i in $(seq 1 50); do
    [ -S /run/fcgiwrap.socket ] && break
    sleep 0.1
done
chmod 666 /run/fcgiwrap.socket

nginx -t

nginx -g "daemon off;" &
NGINX_PID=$!

term_handler() {
    kill -TERM "$NGINX_PID" 2>/dev/null
    kill -TERM "$FCGIWRAP_PID" 2>/dev/null
    wait "$NGINX_PID" 2>/dev/null
    wait "$FCGIWRAP_PID" 2>/dev/null
    exit 0
}
trap term_handler TERM INT

wait "$NGINX_PID"
