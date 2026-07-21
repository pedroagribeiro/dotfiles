# Shared boxed-card summary for the entity-seeding scripts.
# Usage: SeedSummary.print("Professional", { "Name" => pro.name, ... })
# The ordered hash decides row order; keys are labels, values are printed as-is.
#
# Color: enabled when SEED_SUMMARY_COLOR=1 (set by the zsh runner when the real
# terminal is a TTY), disabled when =0, otherwise auto-detected from $stdout.
# The runner passes the flag because `execute` redirects the script's stdout to
# a temp file, so a bare `$stdout.tty?` here would always be false.
module SeedSummary
  module_function

  STYLES = {
    border: "2",       # dim
    title:  "1;36",    # bold cyan
    label:  "2",       # dim
    value:  nil,       # default terminal color
    green:  "32",
    red:    "31",
    yellow: "33"
  }.freeze

  def print(entity_type, fields)
    rows        = fields.map { |label, value| [label.to_s, value] }
    label_width = rows.map { |label, _| label.length }.max || 0

    plain_lines = rows.map { |label, value| line_text(label, label_width, format_value(value)) }
    inner_width = ([entity_type.length + 1] + plain_lines.map(&:length)).max

    puts
    puts top_border(entity_type, inner_width)

    rows.each do |label, value|
      plain   = line_text(label, label_width, format_value(value))
      padding = " " * (inner_width - plain.length)
      body    = "#{paint(label.ljust(label_width), :label)}  #{paint(format_value(value), value_style(value))}"
      puts "#{paint('│', :border)} #{body}#{padding} #{paint('│', :border)}"
    end

    puts paint("╰" + ("─" * (inner_width + 2)) + "╯", :border)
  end

  # The plain (uncolored) text of a row, used only for width/padding math so
  # ANSI escape codes never throw the box alignment off.
  def line_text(label, label_width, value)
    "#{label.ljust(label_width)}  #{value}"
  end

  def top_border(entity_type, inner_width)
    dashes = "─" * (inner_width - entity_type.length - 1)
    paint("╭─ ", :border) + paint(entity_type, :title) + " " + paint(dashes, :border) + paint("╮", :border)
  end

  def value_style(value)
    case value
    when true               then :green
    when false              then :red
    when nil                then :border           # the "—" placeholder, dimmed
    when "created"          then :green
    when "reused", "skipped" then :yellow
    else :value
    end
  end

  def paint(text, style)
    return text unless color?

    code = STYLES[style]
    code ? "\e[#{code}m#{text}\e[0m" : text
  end

  def color?
    case ENV["SEED_SUMMARY_COLOR"]
    when "1" then true
    when "0" then false
    else $stdout.tty?
    end
  end

  def format_value(value)
    case value
    when nil         then "—"
    when true, false then value.to_s
    when Array       then value.empty? ? "—" : value.join(", ")
    else value.to_s
    end
  end
end
