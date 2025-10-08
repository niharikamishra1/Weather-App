require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  let(:zip_code) { '90210' }  # Use a valid zip code for the success case
  let(:coords) { { lat: 34.0901, lon: -118.4053 } }

  describe 'GET #index' do
    context 'when zip_code is provided' do
      context 'when weather data is fetched successfully' do
        before do
          # Stub the WeatherService to return mock successful data
          allow(WeatherService).to receive(:new).and_return(
            double(
              get_weather_by_zip: {
                data: {
                  "coord" => { "lat" => coords[:lat], "lon" => coords[:lon] },
                  "main" => { "temp" => 75 }
                },
                from_cache: false
              },
              get_forecast_by_zip: {
                data: { "list" => [] },
                from_cache: false
              }
            )
          )
          get :index, params: { zip_code: zip_code }
        end

        it 'assigns weather data to @weather_data' do
          expect(assigns(:weather_data)).to include("main" => { "temp" => 75 })
        end

        it 'assigns the cache status to @from_cache' do
          expect(assigns(:from_cache)).to eq(false)
        end

        it 'assigns latitude and longitude from the weather data' do
          expect(assigns(:latitude)).to eq(coords[:lat])
          expect(assigns(:longitude)).to eq(coords[:lon])
        end

        it 'does not set an error message in flash' do
          expect(flash.now[:alert]).to be_nil
        end
      end

      context 'when an error occurs while fetching weather data' do
        before do
          # Stub the WeatherService to return an error message
          allow(WeatherService).to receive(:new).and_return(
            double(
              get_weather_by_zip: { error: "Failed to retrieve weather data." },
              get_forecast_by_zip: { data: { "list" => [] }, from_cache: false }
            )
          )
          get :index, params: { zip_code: zip_code }
        end

        it 'does not assign weather data to @weather_data' do
          expect(assigns(:weather_data)).to be_nil
        end

        it 'does not assign a cache status to @from_cache' do
          expect(assigns(:from_cache)).to be_nil
        end

        it 'sets the error message in flash' do
          expect(flash.now[:alert]).to eq("Failed to retrieve weather data.")
        end
      end
    end

    context 'when lat and lng are provided' do
      context 'when weather data is fetched successfully' do
        before do
          allow(WeatherService).to receive(:new).and_return(
            double(
              get_weather_by_coords: {
                data: {
                  "coord" => { "lat" => coords[:lat], "lon" => coords[:lon] },
                  "main" => { "temp" => 70 }
                },
                from_cache: true
              },
              get_forecast_by_coords: {
                data: { "list" => [] },
                from_cache: true
              }
            )
          )
          get :index, params: { lat: coords[:lat], lng: coords[:lon] }
        end

        it 'assigns weather data to @weather_data' do
          expect(assigns(:weather_data)).to include("main" => { "temp" => 70 })
        end

        it 'assigns the cache status to @from_cache' do
          expect(assigns(:from_cache)).to eq(true)
        end

        it 'assigns latitude and longitude from the weather data' do
          expect(assigns(:latitude)).to eq(coords[:lat])
          expect(assigns(:longitude)).to eq(coords[:lon])
        end
      end

      context 'when an error occurs while fetching weather data' do
        before do
          allow(WeatherService).to receive(:new).and_return(
            double(
              get_weather_by_coords: { error: "Failed to retrieve weather data." },
              get_forecast_by_coords: { data: { "list" => [] }, from_cache: false }
            )
          )
          get :index, params: { lat: coords[:lat], lng: coords[:lon] }
        end

        it 'does not assign weather data to @weather_data' do
          expect(assigns(:weather_data)).to be_nil
        end

        it 'sets the error message in flash' do
          expect(flash.now[:alert]).to eq("Failed to retrieve weather data.")
        end
      end
    end

    context 'when zip_code is not provided' do
      before do
        get :index, params: { zip_code: nil }
      end

      it 'does not assign weather data to @weather_data' do
        expect(assigns(:weather_data)).to be_nil
      end

      it 'does not set an error message in flash' do
        expect(flash.now[:alert]).to be_nil
      end

      it 'assigns default latitude and longitude' do
        expect(assigns(:latitude)).to eq(39.8283)
        expect(assigns(:longitude)).to eq(-98.5795)
      end
    end
  end
end
