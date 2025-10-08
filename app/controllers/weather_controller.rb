class WeatherController < ApplicationController
  def index
    service = WeatherService.new

    if params[:lat].present? && params[:lng].present?
      result = service.get_weather_by_coords(params[:lat], params[:lng])
      forecast_result = service.get_forecast_by_coords(params[:lat], params[:lng])
    elsif params[:zip_code].present?
      result = service.get_weather_by_zip(params[:zip_code])
      forecast_result = service.get_forecast_by_zip(params[:zip_code])
    end

    if defined?(result) && result
      if result[:error]
        flash.now[:alert] = result[:error]
      else
        @weather_data = result[:data]
        @from_cache = result[:from_cache]

        # Fetch latitude and longitude for the map
        @latitude = @weather_data["coord"]["lat"]
        @longitude = @weather_data["coord"]["lon"]

        if defined?(forecast_result) && forecast_result
          if forecast_result[:error]
            flash.now[:alert] = forecast_result[:error]
          else
            @forecast_data = forecast_result[:data]
            @forecast_from_cache = forecast_result[:from_cache]
          end
        end
      end
    else
      # Default center (e.g., USA center) when no query yet
      @latitude = 39.8283
      @longitude = -98.5795
    end
  end
end