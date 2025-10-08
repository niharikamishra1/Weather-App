# Weather App (Ruby on Rails)

Simple Rails 7 application that displays current weather by either:
- Entering a ZIP code, or
- Dragging/dropping a pin on a Google Map and fetching by latitude/longitude.

The app calls the OpenWeather API via `HTTParty`, caches responses for 30 minutes using `Rails.cache`, and renders the result server-side. Units are Fahrenheit.


## Tech Stack
- Ruby `3.1.2`
- Rails `~> 7.2.2` (exact: `7.2.2.1`)
- SQLite (development/test)
- HTTParty (HTTP client)
- Google Maps JavaScript API (map + draggable marker)
- dotenv-rails (environment variable management)
- RSpec (testing)


## Features
- Search weather by ZIP code/City Name
- Select location on an interactive map (draggable marker), then fetch weather for the pinned coordinates
- Caching of API responses for 30 minutes (shows whether data came from API vs cache)


## Prerequisites
- Ruby `3.1.2` (see `.ruby-version`)
- Bundler
- SQLite 3
- OpenWeather API key
- Google Maps JavaScript API key


## Setup (Development)
1) Install dependencies
```bash
bundle install
```

2) Configure environment variables

The current code has API keys hard-coded (for initial development). You should replace those with environment variables before running in a real environment.

- OpenWeather key used in `app/services/weather_service.rb`
- Google Maps key used in `app/views/weather/index.html.erb`

```erb
<!-- app/views/weather/index.html.erb -->
<script async defer src="https://maps.googleapis.com/maps/api/js?key=<%= ENV["GOOGLE_MAPS_API_KEY"] %>&callback=initMap"></script>
```

Then create a `.env` file in the project root (dotenv is included):

```bash
cp .env.example .env  # if you create an example file; otherwise create .env
```

And populate it with:

```dotenv
OPENWEATHER_API_KEY=your_openweather_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_js_api_key
```

3) Database

This app uses SQLite and does not define custom tables for basic functionality. You can still run standard Rails DB tasks safely:

```bash
bin/rails db:prepare
```

4) Run the server

```bash
bin/rails server
```

Visit `http://localhost:3000`.


## Usage
- Enter a ZIP code and click "Get Weather"; or
- Drag the map pin to a location and click "Get Weather For Pin".

If caching is active, the page will indicate whether the weather was "Fetched from cache" (green) or "Fetched from API" (blue). Cache entries expire after 30 minutes.


## Key Implementation Details
- Controller: `app/controllers/weather_controller.rb` (action: `index`)
- Service: `app/services/weather_service.rb` with two methods:
  - `get_weather_by_zip(zip_code)`
  - `get_weather_by_coords(latitude, longitude)`
- Routes: root path (`/`) and `GET /weather` go to `weather#index`
- Caching: `Rails.cache.write` with `expires_in: 30.minutes`
- Units: `imperial` (Fahrenheit)


## Testing
RSpec is included. Run tests with:

```bash
bundle exec rspec
```

If you add tests that hit the external API, prefer stubbing/mocking to avoid network calls and key requirements.


## Docker (Production-oriented image) && Docker Compose
The provided `Dockerfile` builds a production image. Example usage:
Run on localhost:3000 with a single command using the provided `docker-compose.yml`.

1) Build the image:

```bash
docker compose build
```

2) Start the app (binds to localhost:3000):

```bash
docker compose run web
```

3) Open: Host your 3000 port with nginx and start serving https requests

Optional:
- Follow logs: `docker compose logs -f web`
- Exec a shell: `docker compose exec web bash`
- Stop/remove: `docker compose down`


## Security and Configuration Notes
- Do NOT commit API keys to source control. Use environment variables
- Rotate any leaked keys immediately (both OpenWeather and Google APIs).


## Troubleshooting
- No weather data returned: Verify your API keys and network access.
- Map not loading: Check browser console for Google Maps JS API errors; ensure `GOOGLE_MAPS_API_KEY` is valid and enabled for Maps JavaScript API.
- Cache confusion: Clear cache with `rails c` then `Rails.cache.clear`.
