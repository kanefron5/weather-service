# weather-service

Программа для записи текущей погоды в _/etc/update-motd.d/50-motd-news_. Содержимое данного файла отображается при подключении по ssh/открытии нового терминала в Ubuntu 20.04

## Installation

Для корректной работы необходимо создать systemd сервис, запускающийся по таймеру

`sudo nano /etc/systemd/system/update-motd.service`\
[Unit]\
Description=Обновляет погоду, отображаему при подключении терминала

[Service]\
Type=simple\
ExecStart=**[PATH_TO_weather-service]** &

[Install]\
WantedBy=multi-user.target
\
\
\
`sudo nano /etc/systemd/system/update-motd.service`\
[Unit]\
Description=Запускает скрипт для обновления погоды раз в 10мин

[Timer]\
OnBootSec=1min\
OnUnitActiveSec=10min\
Unit=update-motd.service

[Install]\
WantedBy=timers.target
\
\
\
\
\
\
`sudo systemctl enable update-motd.service`\
`sudo systemctl enable update-motd.timer`\
`sudo systemctl start update-motd.service`\
`sudo systemctl start update-motd.timer`


## Contributors

- [Roman Zabolotskikh](https://github.com/kanefron5) - creator and maintainer
