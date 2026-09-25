#!/data/data/com.termux/files/usr/bin/sh
# Termux:Boot: runs after the phone boots.
# The wake lock keeps Android from suspending the CPU while the server is running.
termux-wake-lock
sshd
