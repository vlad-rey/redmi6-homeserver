# Выполняется внутри Termux (через `run-as com.termux sh`).
# Ожидает: /data/local/tmp/authorized_keys и /data/local/tmp/10-sshd.sh.
export PREFIX=/data/data/com.termux/files/usr HOME=/data/data/com.termux/files/home
export TMPDIR=$PREFIX/tmp LANG=en_US.UTF-8
export PATH=$PREFIX/bin LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
cd "$HOME" || exit 1

# Ключи: только те, что переданы с PC
mkdir -p .ssh && chmod 700 .ssh
cp /data/local/tmp/authorized_keys .ssh/authorized_keys
chmod 600 .ssh/authorized_keys

# Только вход по ключу
CFG=$PREFIX/etc/ssh/sshd_config
sed -i '/^#\?PasswordAuthentication/d;/^#\?KbdInteractiveAuthentication/d;/^#\?PubkeyAuthentication/d' "$CFG"
printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\nPubkeyAuthentication yes\n' >> "$CFG"

# Автозапуск через Termux:Boot
mkdir -p .termux/boot
cp /data/local/tmp/10-sshd.sh .termux/boot/10-sshd.sh
chmod 700 .termux/boot/10-sshd.sh

# Перезапуск sshd с новой конфигурацией
pkill sshd 2>/dev/null
sh .termux/boot/10-sshd.sh
sleep 1
pgrep -a sshd || echo "sshd НЕ запущен"
