#!/bin/bash
flatpak remote-add -u --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -u -y it.mijorus.gearlever com.spotify.Client 1>./test.txt 2>./test.txt
