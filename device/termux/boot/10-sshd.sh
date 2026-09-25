#!/data/data/com.termux/files/usr/bin/sh
# Termux:Boot: запускается после загрузки телефона.
# wake lock не даёт Android усыплять процессоры, пока работает сервер.
termux-wake-lock
sshd
