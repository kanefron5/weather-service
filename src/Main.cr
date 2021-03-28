require "http/client"
require "json"
require "system/user"

class Main
  def start
    # https://ipwhois.app/json/?lang=ru
    ip_info = JSON.parse(HTTP::Client.get("https://ipwhois.app/json/?lang=ru").body)
    latitude = ip_info["latitude"]
    longitude = ip_info["longitude"]

    params = URI::Params.encode({
      "lat"   => latitude.to_s,
      "lon"   => longitude.to_s,
      "appid" => "e746f2e48db8bf0c70400e444525e6da",
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

    content = "Погода для текущего местоположения (#{city}): \n" +
              "\t\tТемпература: #{current}˚C\n" +
              "\t\tОщущается как: #{feels_like}˚C\n" +
              "\t\tДавление: #{pressure} мм рт. ст.\n" +
              "\t\tПоследнее обновление: #{current_time}\n"

    puts content

    {% if flag?(:linux) %}
      file_name = "/etc/update-motd.d/50-motd-news"
      formatted_content = "#!/bin/sh\n\n"
      content.each_line do |line|
        formatted_content += "printf \"\t   #{line}\\n\"\n"
      end
      begin
        File.write(file_name, formatted_content, mode: "w")
      rescue
        puts "Скрипт необходимо запускать с sudo!"
      end
    {% elsif flag?(:darwin) %}
      puts "Для дополнительной функциональности используйте Linux"
    {% end %}
  end
end
