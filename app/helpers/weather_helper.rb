module WeatherHelper
  def render_key_value_table(data)
    return content_tag(:p, 'No data available', class: 'empty-text') if data.blank?

    content_tag(:table, class: 'kv-table') do
      concat(content_tag(:thead) do
        content_tag(:tr) do
          concat content_tag(:th, 'Key')
          concat content_tag(:th, 'Value')
        end
      end)

      concat(content_tag(:tbody) do
        safe_join(render_rows_for(data))
      end)
    end
  end

  private

  def render_rows_for(value, parent_key = nil)
    case value
    when Hash
      value.map do |k, v|
        key_label = parent_key ? "#{parent_key}.#{k}" : k
        render_rows_for(v, key_label)
      end.flatten
    when Array
      if value.empty?
        [content_tag(:tr) do
          concat content_tag(:td, parent_key, class: 'kv-key')
          concat content_tag(:td, '[]', class: 'kv-value')
        end]
      else
        value.each_with_index.map do |v, idx|
          key_label = parent_key ? "#{parent_key}[#{idx}]" : "[#{idx}]"
          render_rows_for(v, key_label)
        end.flatten
      end
    else
      [content_tag(:tr) do
        concat content_tag(:td, parent_key, class: 'kv-key')
        concat content_tag(:td, format_scalar(value), class: 'kv-value')
      end]
    end
  end

  def format_scalar(value)
    case value
    when TrueClass, FalseClass
      value ? 'true' : 'false'
    when Numeric
      value
    when NilClass
      'null'
    else
      value.to_s
    end
  end

  def summarize_forecast(forecast_data)
    return [] if forecast_data.blank?

    entries = forecast_data["list"] || []
    by_day = entries.group_by do |e|
      Time.at(e["dt"]).in_time_zone.to_date
    end

    by_day.map do |date, items|
      temps = items.map { |i| i.dig("main", "temp") }.compact
      highs = items.map { |i| i.dig("main", "temp_max") }.compact
      lows  = items.map { |i| i.dig("main", "temp_min") }.compact
      icon  = (items.find { |i| i["weather"].is_a?(Array) && i["weather"].first }).to_h.dig("weather", 0, "icon")
      desc  = (items.find { |i| i["weather"].is_a?(Array) && i["weather"].first }).to_h.dig("weather", 0, "description")

      {
        date: date,
        temp_avg: temps.any? ? (temps.sum / temps.size.to_f) : nil,
        temp_high: highs.max,
        temp_low: lows.min,
        icon: icon,
        description: desc
      }
    end.sort_by { |h| h[:date] }
  end
end
