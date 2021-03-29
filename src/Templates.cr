SERVICE_TEMPLATE = "
[Unit]
Description=Обновляет погоду, отображаему при подключении терминала

[Service]
Type=simple
ExecStart=[PATH_TO_BINARY] -w &

[Install]
WantedBy=multi-user.target 
"

TIMER_TEMPLATE = "
[Unit]
Description=Запускает скрипт для обновления погоды раз в 10мин

[Timer]
OnBootSec=1min
OnUnitActiveSec=10min
Unit=update-motd.service

[Install]
WantedBy=timers.target 
"