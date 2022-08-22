FROM archlinux:base-devel

#Enable Multilib on image
RUN echo "[multilib]" | tee -a /etc/pacman.conf
RUN echo "Include = /etc/pacman.d/mirrorlist" | tee -a /etc/pacman.conf

#Install Wine and dependencies
RUN pacman -Syu wine-staging samba lib32-gnutls xorg-server-xvfb unzip --noconfirm && pacman -Scc --noconfirm

#Copy dotnet alias
COPY dotnet /usr/local/bin
RUN chmod +x /usr/local/bin/dotnet

# Install Winetricks
RUN curl -o winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
RUN chmod +x winetricks
RUN cp winetricks /usr/local/bin

#Add non root user as wine really hates running as root
RUN groupadd --gid 1000 wine && useradd -m --uid 1000 --gid 1000 wine
USER wine

#Create prefix
RUN wine wineboot & xvfb-run winetricks -q --force vcrun2019

#Install .NET 6 SDK
WORKDIR /tmp
RUN curl https://download.visualstudio.microsoft.com/download/pr/8686fa48-b378-424e-908b-afbd66d6e120/2d75d5c3574fb5d917c5a3cd3f624287/dotnet-sdk-6.0.400-win-x64.zip \
    -o dotnet-sdk-6.0.400-win-x64.zip \
    && unzip dotnet-sdk-6.0.400-win-x64.zip -d "/home/wine/.wine/drive_c/Program Files/dotnet" && rm -rf /tmp/* 

#Disable Crash dialog
RUN wine64 reg add "HKEY_CURRENT_USER\Software\Wine\WineDbg" /v ShowCrashDialog /t REG_DWORD /d 0

ENV WINEPATH="C:\windows\system32;C:\windows;C:\windows\system32\wbem;C:\Program Files\dotnet\;C:\users\wine\.dotnet\tools"
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1

COPY .dotnet /home/wine/.wine/drive_c/users/wine/.dotnet
COPY NuGet /home/wine/.wine/drive_c/users/wine/AppData/Roaming/NuGet

RUN mkdir "/home/wine/.wine/drive_c/users/wine/.nuget"

WORKDIR /

#Silence fixme warnings
ENV WINEDEBUG=fixme-all

SHELL ["/bin/bash", "-c"]