require "http/client"
require "json"
require "option_parser"
require "./Constants.cr"
require "./Templates.cr"
require "colorize"

class Main
  @SERVICE_NAME = "update-motd.service"
  @TIMER_NAME = "update-motd.timer"

  def start
    parser = OptionParser.new do |parser|
      parser.banner = "Usage: weather-service -[flag]"
      parser.on("-i", "--install", "Install systemd service and timer") {
        install
        exit
      }
      parser.on("-p", "--print", "Print current temperature") {
        puts getWeather
        exit
      }
      parser.on("-w", "--write", "Print current temperature and write it to /etc/update-motd.d/50-motd-news") {
        content = getWeather
        puts content
        writeFile(content)
        exit
      }
      parser.on("-c", "--clean", "Completely delete systemd service") {
        clean
        exit
      }
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
      parser.invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} is not a valid option.".colorize(:red)
        STDERR.puts parser
        exit(1)
      end
    end
    parser.parse
    puts parser
  end

  def getWeather : String
    # https://ipwhois.app/json/?lang=ru
    ip_info = JSON.parse(HTTP::Client.get("https://ipwhois.app/json/?lang=ru").body)
    latitude = ip_info["latitude"]
    longitude = ip_info["longitude"]

    params = URI::Params.encode({
      "lat"   => latitude.to_s,
      "lon"   => longitude.to_s,
      "appid" => API_TOKEN,
      "lang"  => "ru",
      "units" => "metric",
    })
    json_weather = JSON.parse(HTTP::Client.get(URI.new(
      "http",
      "api.openweathermap.org",
      path: "/data/2.5/weather",
      query: params
    )).body)

    current_time = Time.local
    city = ip_info["city"]
    json_main = json_weather["main"]
    current = json_main["temp"].as_f.ceil.to_i
    feels_like = json_main["feels_like"].as_f.ceil.to_i
    pressure = (json_main["pressure"].as_i * 0.750062).ceil.to_i

    "\n\nПогода для текущего местоположения (#{city}): \n" +
      "Температура: #{current}˚C\n" +
      "Ощущается как: #{feels_like}˚C\n" +
      "Давление: #{pressure} мм рт. ст.\n" +
      "Последнее обновление: #{current_time}\n"
  end

  def writeFile(content : String)
    {% if flag?(:linux) %}
      file_name = "/etc/update-motd.d/50-motd-news"
      formatted_content = "#!/bin/sh\n\n"
      content.each_line do |line|
        formatted_content += "printf \"  #{line}\\n\"\n"
      end
      begin
        File.write(file_name, formatted_content, mode: "w")
      rescue
        STDERR.puts "Скрипт необходимо запускать с sudo!".colorize(:red)
        exit -1
      end
    {% else %}
      STDERR.puts "Для дополнительной функциональности используйте Linux".colorize(:red)
    {% end %}
  end

  def install
    {% if flag?(:linux) %}
      begin
        bin_file_path = Dir.current + "/weather-service"
        if (!File.exists?(bin_file_path))
          STDERR.puts "Запуск программы должен производиться из директории, в которой она находится!".colorize(:red)
          exit -1
        end

        systemd_path = "/etc/systemd/system/"
        if (!File.exists?(systemd_path))
          STDERR.puts "В системе отсутсвует systemd"
          exit -1
        end
        if (File.exists?(systemd_path + @SERVICE_NAME))
          File.delete(systemd_path + @SERVICE_NAME)
        end
        File.touch(systemd_path + @SERVICE_NAME)
        File.write(systemd_path + @SERVICE_NAME, SERVICE_TEMPLATE.sub("[PATH_TO_BINARY]", bin_file_path), "w")

        if (File.exists?(systemd_path + @TIMER_NAME))
          File.delete(systemd_path + @TIMER_NAME)
        end
        File.touch(systemd_path + @TIMER_NAME)
        File.write(systemd_path + @TIMER_NAME, TIMER_TEMPLATE, "w")

        Process.new("sudo", ["systemctl", "enable", @SERVICE_NAME]).wait
        Process.new("sudo", ["systemctl", "enable", @TIMER_NAME]).wait
        Process.new("sudo", ["systemctl", "start", @SERVICE_NAME]).wait
        Process.new("sudo", ["systemctl", "start", @TIMER_NAME]).wait

        puts "Успешно установлено!".colorize(:green)
      rescue
        STDERR.puts "Скрипт необходимо запускать с sudo!".colorize(:red)
        exit -1
      end
    {% else %}
      STDERR.puts "Данный функционал доступен только в ОС Linux".colorize(:red)
    {% end %}
  end

  def clean
    {% if flag?(:linux) %}
      begin
        systemd_path = "/etc/systemd/system/"
        if (!File.exists?(systemd_path))
          STDERR.puts "В системе отсутсвует systemd".colorize(:red)
          exit -1
        end
        Process.new("sudo", ["systemctl", "stop", @SERVICE_NAME]).wait
        Process.new("sudo", ["systemctl", "stop", @TIMER_NAME]).wait
        Process.new("sudo", ["systemctl", "disable", @SERVICE_NAME]).wait
        Process.new("sudo", ["systemctl", "disable", @TIMER_NAME]).wait

        if (File.exists?(systemd_path + @SERVICE_NAME))
          File.delete(systemd_path + @SERVICE_NAME)
        end
        if (File.exists?(systemd_path + @TIMER_NAME))
          File.delete(systemd_path + @TIMER_NAME)
        end
        if (File.exists?("/usr/lib/systemd/system/" + @TIMER_NAME))
          File.delete("/usr/lib/systemd/system/" + @TIMER_NAME)
        end
        if (File.exists?("/usr/lib/systemd/system/" + @SERVICE_NAME))
          File.delete("/usr/lib/systemd/system/" + @SERVICE_NAME)
        end
        Process.new("sudo", ["systemctl", "daemon-reload"]).wait

        writeFile("")
        puts "Все сервисы удалены!".colorize(:green)
      rescue
        STDERR.puts "Скрипт необходимо запускать с sudo!".colorize(:red)
        exit -1
      end
    {% else %}
      STDERR.puts "Данный функционал доступен только в ОС Linux".colorize(:red)
    {% end %}
  end
end
