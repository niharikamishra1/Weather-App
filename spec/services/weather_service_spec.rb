require 'rails_helper'

RSpec.describe WeatherService, type: :service do
  let(:zip_code) { '90210' } # Example ZIP code (Beverly Hills)
  let(:lat) { 34.0901 }
  let(:lon) { -118.4053 }
  let(:weather_data) do
    {
      "coord" => { "lon" => -118.4053, "lat" => 34.0901 },
      "weather" => [{ "id" => 800, "main" => "Clear", "description" => "clear sky", "icon" => "01d" }],
      "main" => { "temp" => 75.23, "feels_like" => 74.08, "temp_min" => 73.41, "temp_max" => 77.02, "pressure" => 1015, "humidity" => 48 },
      "wind" => { "speed" => 4.47, "deg" => 230 },
      "clouds" => { "all" => 0 },
      "dt" => 1633625300,
      "sys" => { "type" => 1, "id" => 4622, "country" => "US", "sunrise" => 1633600801, "sunset" => 1633642494 },
      "timezone" => -25200,
      "id" => 5332921,
      "name" => "Beverly Hills",
      "cod" => 200
    }
  end

  subject { described_class.new() }

  describe '#get_weather_by_zip' do
    context 'when data is not cached' do
      before { Rails.cache.delete("weather_#{zip_code}") }

      it 'fetches weather data from the API' do
        http_response = instance_double(HTTParty::Response, success?: true, parsed_response: weather_data)
        allow(WeatherService).to receive(:get).with("/weather", query: { q: zip_code, appid: anything, units: 'imperial' }).and_return(http_response)

        result = subject.get_weather_by_zip(zip_code)
        
        expect(result[:data]).to eq(weather_data)
        expect(result[:from_cache]).to eq(false)
      end

      it 'stores the fetched data in the cache' do
        http_response = instance_double(HTTParty::Response, success?: true, parsed_response: weather_data)
        allow(WeatherService).to receive(:get).and_return(http_response)

        subject.get_weather_by_zip(zip_code)
        expect(Rails.cache.read("weather_#{zip_code}")).to eq(weather_data)
      end
    end

    context 'when data is fetched from the cache' do
      before do
        Rails.cache.write("weather_#{zip_code}", weather_data, expires_in: 30.minutes)
      end

      it 'fetches weather data from cache' do
        result = subject.get_weather_by_zip(zip_code)

        expect(result[:data]).to eq(weather_data)
        expect(result[:from_cache]).to eq(true)
      end
    end

    context 'when the API returns an error' do
      it 'handles API failure gracefully' do
        http_response = instance_double(HTTParty::Response, success?: false)
        allow(WeatherService).to receive(:get).and_return(http_response)

        result = subject.get_weather_by_zip("99999")

        expect(result[:error]).to eq("Failed to retrieve weather data.")
      end
    end
  end

  describe '#get_weather_by_coords' do
    context 'when data is not cached' do
      before { Rails.cache.delete("weather_#{lat}_#{lon}") }

      it 'fetches weather data from the API' do
        http_response = instance_double(HTTParty::Response, success?: true, parsed_response: weather_data)
        allow(WeatherService).to receive(:get).with("/weather", query: { lat: lat, lon: lon, appid: anything, units: 'imperial' }).and_return(http_response)

        result = subject.get_weather_by_coords(lat, lon)

        expect(result[:data]).to eq(weather_data)
        expect(result[:from_cache]).to eq(false)
      end

      it 'stores the fetched data in the cache' do
        http_response = instance_double(HTTParty::Response, success?: true, parsed_response: weather_data)
        allow(WeatherService).to receive(:get).and_return(http_response)

        subject.get_weather_by_coords(lat, lon)
        expect(Rails.cache.read("weather_#{lat}_#{lon}")).to eq(weather_data)
      end
    end

    context 'when data is fetched from the cache' do
      before do
        Rails.cache.write("weather_#{lat}_#{lon}", weather_data, expires_in: 30.minutes)
      end

      it 'fetches weather data from cache' do
        result = subject.get_weather_by_coords(lat, lon)

        expect(result[:data]).to eq(weather_data)
        expect(result[:from_cache]).to eq(true)
      end
    end

    context 'when the API returns an error' do
      it 'handles API failure gracefully' do
        Rails.cache.delete("weather_#{lat}_#{lon}")
        http_response = instance_double(HTTParty::Response, success?: false)
        allow(WeatherService).to receive(:get).and_return(http_response)

        result = subject.get_weather_by_coords(lat, lon)

        expect(result[:error]).to eq("Failed to retrieve weather data.")
      end
    end
  end

  describe '#get_forecast_by_coords' do
    context 'when data is not cached' do
      before { Rails.cache.delete("forecast_#{lat}_#{lon}") }

      it 'fetches forecast data from the API' do
        forecast_stub = { "list" => [{ "dt" => 1, "main" => { "temp" => 70 }, "weather" => [{"icon" => "10d", "description" => "light rain"}] }] }
        http_response = instance_double(HTTParty::Response, success?: true, parsed_response: forecast_stub)
        allow(WeatherService).to receive(:get).with("/forecast", query: { lat: lat, lon: lon, appid: anything, units: 'imperial' }).and_return(http_response)

        result = subject.get_forecast_by_coords(lat, lon)

        expect(result[:data]).to eq(forecast_stub)
        expect(result[:from_cache]).to eq(false)
      end

      it 'stores the fetched forecast data in the cache' do
        forecast_stub = { "list" => [] }
        http_response = instance_double(HTTParty::Response, success?: true, parsed_response: forecast_stub)
        allow(WeatherService).to receive(:get).and_return(http_response)

        subject.get_forecast_by_coords(lat, lon)
        expect(Rails.cache.read("forecast_#{lat}_#{lon}")).to eq(forecast_stub)
      end
    end

    context 'when data is fetched from the cache' do
      before do
        Rails.cache.write("forecast_#{lat}_#{lon}", { "list" => [] }, expires_in: 30.minutes)
      end

      it 'fetches forecast data from cache' do
        result = subject.get_forecast_by_coords(lat, lon)

        expect(result[:data]).to eq({ "list" => [] })
        expect(result[:from_cache]).to eq(true)
      end
    end

    context 'when the API returns an error' do
      it 'handles API failure gracefully' do
        Rails.cache.delete("forecast_#{lat}_#{lon}")
        http_response = instance_double(HTTParty::Response, success?: false)
        allow(WeatherService).to receive(:get).and_return(http_response)

        result = subject.get_forecast_by_coords(lat, lon)

        expect(result[:error]).to eq("Failed to retrieve forecast data.")
      end
    end
  end

  describe '#get_forecast_by_zip' do
    context 'when data is not cached' do
      before { Rails.cache.delete("forecast_#{zip_code}") }

      it 'fetches forecast data from the API' do
        forecast_stub = { "list" => [] }
        http_response = instance_double(HTTParty::Response, success?: true, parsed_response: forecast_stub)
        allow(WeatherService).to receive(:get).with("/forecast", query: { q: zip_code, appid: anything, units: 'imperial' }).and_return(http_response)

        result = subject.get_forecast_by_zip(zip_code)

        expect(result[:data]).to eq(forecast_stub)
        expect(result[:from_cache]).to eq(false)
      end

      it 'stores the fetched forecast data in the cache' do
        forecast_stub = { "list" => [] }
        http_response = instance_double(HTTParty::Response, success?: true, parsed_response: forecast_stub)
        allow(WeatherService).to receive(:get).and_return(http_response)

        subject.get_forecast_by_zip(zip_code)
        expect(Rails.cache.read("forecast_#{zip_code}")).to eq(forecast_stub)
      end
    end

    context 'when data is fetched from the cache' do
      before do
        Rails.cache.write("forecast_#{zip_code}", { "list" => [] }, expires_in: 30.minutes)
      end

      it 'fetches forecast data from cache' do
        result = subject.get_forecast_by_zip(zip_code)

        expect(result[:data]).to eq({ "list" => [] })
        expect(result[:from_cache]).to eq(true)
      end
    end

    context 'when the API returns an error' do
      it 'handles API failure gracefully' do
        http_response = instance_double(HTTParty::Response, success?: false)
        allow(WeatherService).to receive(:get).and_return(http_response)

        result = subject.get_forecast_by_zip("99999")

        expect(result[:error]).to eq("Failed to retrieve forecast data.")
      end
    end
  end
end
