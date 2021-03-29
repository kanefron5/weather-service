# weather-service

Программа для записи текущей погоды в _/etc/update-motd.d/50-motd-news_. Содержимое данного файла отображается при подключении по ssh/открытии нового терминала в Ubuntu 20.04

При запуске с флагом --install программа создает systemd сервис, который запускается по таймеру раз в 10 минут и обновляет информацию

## Использование
`weather-service -[flag]`\
    `-i, --install`                    Install systemd service and timer\
    `-p, --print`                      Print current temperature\
    `-w, --write`                      Print current temperature and write it to /etc/update-motd.d/50-motd-news\
    `-c, --clean`                      Completely delete systemd service\
    `-h, --help `                      Show this help


## Contributors

- [Roman Zabolotskikh](https://github.com/kanefron5) - creator and maintainer
