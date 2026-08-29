#!/bin/bash
# This script securely passes the FastShare IPA to AltServer without terminal line-break bugs

ALTSERVER_ANISETTE_SERVER="http://127.0.0.1:6969" /opt/altserver/AltServer -u 00008110-001C38840AEA201E -a "ritikthakur22@gmail.com" -p "$1" /home/crdy/testing/iPhone/FastShare.ipa
