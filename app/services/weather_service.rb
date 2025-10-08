# app/services/weather_service.rb
class WeatherService
  include HTTParty
  base_uri 'http://api.openweathermap.org/data/2.5'

  def initialize
    @api_key = ENV['OPENWEATHER_API_KEY']
  end

  def get_weather_by_zip(zip_code)
    cache_key = "weather_#{zip_code}"

    if (cached_data = Rails.cache.read(cache_key))
      return { data: cached_data, from_cache: true }
    end
    response = self.class.get("/weather", query: {
      q: "#{zip_code}",
      appid: @api_key,
      units: 'imperial'
    })

    if response.success?
      Rails.cache.write(cache_key, response.parsed_response, expires_in: 30.minutes)
      { data: response.parsed_response, from_cache: false }
    else
      { error: "Failed to retrieve weather data." }
    end
  end

  def get_weather_by_coords(latitude, longitude)
    lat = latitude.to_f
    lon = longitude.to_f

    cache_key = "weather_#{lat}_#{lon}"

    if (cached_data = Rails.cache.read(cache_key))
      return { data: cached_data, from_cache: true }
    end

    response = self.class.get("/weather", query: {
      lat: lat,
      lon: lon,
      appid: @api_key,
      units: 'imperial'
    })

    if response.success?
      Rails.cache.write(cache_key, response.parsed_response, expires_in: 30.minutes)
      { data: response.parsed_response, from_cache: false }
    else
      { error: "Failed to retrieve weather data." }
    end
  end

  def get_forecast_by_coords(latitude, longitude)
    lat = latitude.to_f
    lon = longitude.to_f

    cache_key = "forecast_#{lat}_#{lon}"

    if (cached_data = Rails.cache.read(cache_key))
      return({ data: cached_data, from_cache: true })
    end

    response = self.class.get("/forecast", query: {
      lat: lat,
      lon: lon,
      appid: @api_key,
      units: 'imperial'
    })

    if response.success?
      Rails.cache.write(cache_key, response.parsed_response, expires_in: 30.minutes)
      { data: response.parsed_response, from_cache: false }
    else
      { error: "Failed to retrieve forecast data." }
    end
  end

  def get_forecast_by_zip(zip_code)
    cache_key = "forecast_#{zip_code}"

    if (cached_data = Rails.cache.read(cache_key))
      return({ data: cached_data, from_cache: true })
    end

    response = self.class.get("/forecast", query: {
      q: "#{zip_code}",
      appid: @api_key,
      units: 'imperial'
    })

    if response.success?
      Rails.cache.write(cache_key, response.parsed_response, expires_in: 30.minutes)
      { data: response.parsed_response, from_cache: false }
    else
      { error: "Failed to retrieve forecast data." }
    end
  end
end
  