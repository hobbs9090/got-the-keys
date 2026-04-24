#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "time"
require_relative "../../lib/ci/rspec_performance_report"

module RspecPagesSite
  module_function

  def run
    report_json = Pathname(ENV.fetch("RSPEC_REPORT_JSON", "tmp/rspec-report.json"))
    report_markdown = Pathname(ENV.fetch("RSPEC_REPORT_MARKDOWN", "tmp/rspec-report.md"))
    allure_report = Pathname(ENV.fetch("ALLURE_REPORT_DIR", "tmp/allure-report"))
    output_dir = Pathname(ENV.fetch("PAGES_OUTPUT_DIR", "tmp/ci-report-site"))

    report_data = read_json(report_json)
    performance_report = Ci::RspecPerformanceReport.new(
      report_data: report_data,
      baseline: Ci::RspecPerformanceBaseline.load("config/rspec_performance_baseline.yml")
    )

    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)

    copy_tree(allure_report, output_dir.join("allure")) if allure_report.directory?
    FileUtils.cp(report_json, output_dir.join("rspec-report.json")) if report_json.file?
    FileUtils.cp(report_markdown, output_dir.join("rspec-report.md")) if report_markdown.file?

    write_file(output_dir.join(".nojekyll"), "")
    write_file(output_dir.join("index.html"), build_index_html(report_data, performance_report, allure_report.directory?))
  end

  def read_json(path)
    return {"summary" => {}, "examples" => [], "summary_line" => "RSpec report was not generated."} unless path.file?

    JSON.parse(path.read)
  end

  def copy_tree(source, destination)
    FileUtils.mkdir_p(destination)
    Dir.glob(source.join("**", "*").to_s, File::FNM_DOTMATCH).sort.each do |entry|
      next if [".", ".."].include?(File.basename(entry))

      source_path = Pathname(entry)
      target = destination.join(source_path.relative_path_from(source))

      if source_path.directory?
        FileUtils.mkdir_p(target)
      else
        FileUtils.mkdir_p(target.dirname)
        FileUtils.cp(source_path, target)
      end
    end
  end

  def build_index_html(report_data, performance_report, allure_present)
    summary = report_data.fetch("summary", {})
    examples = Array(report_data["examples"])
    failures = examples.select { |example| example["status"] == "failed" }
    pending = examples.select { |example| example["status"] == "pending" }
    slow_examples = performance_report.slow_examples
    generated_at = Time.now.utc.iso8601

    failure_rows = if failures.empty?
                     "<tr><td colspan=\"3\">No failing examples in the latest run.</td></tr>"
                   else
                     failures.first(12).map do |example|
                       [
                         "<tr>",
                         "  <th scope=\"row\">#{escape_html(truncate(example["full_description"] || example["description"], 130))}</th>",
                         "  <td><code>#{escape_html(format_location(example))}</code></td>",
                         "  <td>#{escape_html(truncate(example.dig("exception", "message") || "Example failed.", 180))}</td>",
                         "</tr>"
                       ].join("\n")
                     end.join("\n")
                   end

    slow_rows = if slow_examples.empty?
                  "<tr><td colspan=\"3\">No timing data was available.</td></tr>"
                else
                  slow_examples.map do |example|
                    [
                      "<tr>",
                      "  <th scope=\"row\">#{escape_html(truncate(example.full_description, 150))}</th>",
                      "  <td><code>#{escape_html(example.location)}</code></td>",
                      "  <td>#{escape_html(format_duration(example.run_time))}</td>",
                      "</tr>"
                    ].join("\n")
                  end.join("\n")
                end

    links = []
    links << link_chip("Open Allure report", "allure/index.html") if allure_present
    links << link_chip("Open RSpec JSON", "rspec-report.json")
    links << link_chip("Open Markdown summary", "rspec-report.md")

    <<~HTML
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>GotTheKeys CI Report</title>
          <style>
            :root {
              color-scheme: light;
              --bg: #f4f5ef;
              --panel: #ffffff;
              --ink: #1d241f;
              --muted: #5f6d63;
              --line: #d7dbcf;
              --accent: #205f3d;
              --accent-soft: #e2f0e7;
              --danger: #9f2f2f;
              --shadow: 0 20px 48px rgba(39, 58, 45, 0.1);
            }

            * { box-sizing: border-box; }

            body {
              margin: 0;
              font-family: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", Georgia, serif;
              background: radial-gradient(circle at top, #faf8f0 0%, var(--bg) 60%);
              color: var(--ink);
            }

            main {
              max-width: 1240px;
              margin: 0 auto;
              padding: 48px 20px 72px;
            }

            h1, h2 {
              margin: 0;
              line-height: 1.08;
            }

            h1 {
              font-size: clamp(2.2rem, 4.3vw, 3.5rem);
              margin-bottom: 12px;
            }

            h2 {
              font-size: clamp(1.45rem, 2vw, 2rem);
              margin-bottom: 16px;
            }

            p {
              margin: 0;
              color: var(--muted);
              line-height: 1.65;
            }

            section { margin-top: 32px; }

            .hero {
              display: grid;
              gap: 18px;
              margin-bottom: 12px;
            }

            .meta,
            .links {
              display: flex;
              flex-wrap: wrap;
              gap: 12px;
            }

            .pill,
            .link-chip {
              display: inline-flex;
              align-items: center;
              gap: 8px;
              padding: 8px 12px;
              border: 1px solid var(--line);
              border-radius: 999px;
              background: rgba(255, 255, 255, 0.78);
              color: var(--muted);
              font-size: 0.92rem;
            }

            .link-chip {
              color: var(--accent);
              text-decoration: none;
            }

            .cards {
              display: grid;
              grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
              gap: 14px;
            }

            .card {
              padding: 18px;
              border-radius: 18px;
              background: var(--panel);
              border: 1px solid var(--line);
              box-shadow: 0 12px 30px rgba(39, 58, 45, 0.08);
            }

            .card h3 {
              margin: 0 0 8px;
              font-size: 0.95rem;
              color: var(--muted);
            }

            .card strong {
              font-size: 2.1rem;
              line-height: 1;
            }

            .card--danger strong { color: var(--danger); }

            .panel {
              border: 1px solid var(--line);
              border-radius: 22px;
              background: var(--panel);
              box-shadow: var(--shadow);
              overflow: hidden;
            }

            .table-wrap { overflow-x: auto; }

            table {
              width: 100%;
              border-collapse: collapse;
            }

            thead th {
              background: #f0f4ec;
              color: var(--muted);
              font-size: 0.82rem;
              letter-spacing: 0.06em;
              text-transform: uppercase;
            }

            th,
            td {
              padding: 14px 16px;
              border-bottom: 1px solid var(--line);
              text-align: left;
              vertical-align: top;
            }

            tbody tr:last-child th,
            tbody tr:last-child td { border-bottom: 0; }

            a {
              color: var(--accent);
              text-decoration-thickness: 0.08em;
              text-underline-offset: 0.14em;
            }

            code {
              font-family: "SFMono-Regular", ui-monospace, Consolas, monospace;
              font-size: 0.92em;
              background: var(--accent-soft);
              padding: 0.15em 0.4em;
              border-radius: 6px;
            }

            .section-copy { margin-bottom: 18px; }

            @media (max-width: 720px) {
              main { padding-inline: 14px; }
              th, td { padding: 12px; }
            }
          </style>
        </head>
        <body>
          <main>
            <section class="hero">
              <div>
                <p>Published from GitHub Actions</p>
                <h1>GotTheKeys CI Report</h1>
                <p>The latest main-branch RSpec run, performance snapshot, and full Allure report published together.</p>
              </div>
              <div class="meta">
                <span class="pill">Generated: <time datetime="#{escape_attr(generated_at)}">#{escape_html(format_timestamp(generated_at))}</time></span>
                <span class="pill">Summary: <code>#{escape_html(report_data["summary_line"] || "RSpec completed.")}</code></span>
              </div>
              <div class="links">
                #{links.join("\n                ")}
              </div>
            </section>

            <section>
              <div class="section-copy">
                <h2>RSpec Summary</h2>
                <p>The headline test metrics from the JSON formatter, with the full Allure experience one click away.</p>
              </div>
              <div class="cards">
                #{build_card("Examples", summary.fetch("example_count", 0))}
                #{build_card("Failures", summary.fetch("failure_count", 0), danger: summary.fetch("failure_count", 0).to_i.positive?)}
                #{build_card("Pending", summary.fetch("pending_count", 0))}
                #{build_card("Duration", format_duration(summary.fetch("duration", 0)))}
              </div>
            </section>

            <section>
              <div class="section-copy">
                <h2>Failures</h2>
                <p>Failing examples are surfaced here for quick triage before opening the deeper report.</p>
              </div>
              <div class="panel">
                <div class="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>Example</th>
                        <th>Location</th>
                        <th>Details</th>
                      </tr>
                    </thead>
                    <tbody>
      #{failure_rows}
                    </tbody>
                  </table>
                </div>
              </div>
            </section>

            <section>
              <div class="section-copy">
                <h2>Slowest Examples</h2>
                <p>The existing performance baseline remains visible in the GitHub summary and in this published dashboard.</p>
              </div>
              <div class="panel">
                <div class="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>Example</th>
                        <th>Location</th>
                        <th>Run Time</th>
                      </tr>
                    </thead>
                    <tbody>
      #{slow_rows}
                    </tbody>
                  </table>
                </div>
              </div>
            </section>
          </main>
        </body>
      </html>
    HTML
  end

  def build_card(label, value, danger: false)
    class_name = danger ? "card card--danger" : "card"
    <<~HTML
      <article class="#{class_name}">
        <h3>#{escape_html(label)}</h3>
        <strong>#{escape_html(value)}</strong>
      </article>
    HTML
  end

  def format_location(example)
    line = example["line_number"] || failure_line(example)
    [example["file_path"].to_s.sub(%r{\A\./}, ""), line].compact.map(&:to_s).reject(&:empty?).join(":")
  end

  def failure_line(example)
    Array(example.dig("exception", "backtrace")).each do |entry|
      return Regexp.last_match(2) if entry.match(/\A\.?\/?([^:]+):(\d+)/)
    end

    nil
  end

  def format_duration(seconds)
    format("%.2fs", seconds.to_f)
  end

  def format_timestamp(timestamp)
    Time.parse(timestamp).utc.strftime("%a, %d %b %Y %H:%M:%S UTC")
  rescue ArgumentError
    timestamp.to_s
  end

  def truncate(text, limit)
    value = text.to_s.strip
    return value if value.length <= limit

    "#{value[0, limit - 3]}..."
  end

  def link_chip(label, href)
    "<a class=\"link-chip\" href=\"#{escape_attr(href)}\">#{escape_html(label)}</a>"
  end

  def escape_html(value)
    value.to_s
      .gsub("&", "&amp;")
      .gsub("<", "&lt;")
      .gsub(">", "&gt;")
      .gsub('"', "&quot;")
      .gsub("'", "&#39;")
  end

  def escape_attr(value)
    escape_html(value)
  end

  def write_file(path, content)
    FileUtils.mkdir_p(path.dirname)
    path.write(content)
  end
end

RspecPagesSite.run
