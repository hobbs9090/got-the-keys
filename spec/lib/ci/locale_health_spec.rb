require "rails_helper"
require "fileutils"
require "tmpdir"

RSpec.describe Ci::LocaleHealth do
  def write_locale(root, relative_path, payload)
    path = File.join(root, "config", "locales", relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, Psych.dump(payload, line_width: -1))
  end

  it "writes missing English keys into generated locale overlays" do
    Dir.mktmpdir do |dir|
      write_locale(dir, "en.yml", { "en" => { "ui" => { "common" => { "save" => "Save" } } } })
      write_locale(dir, "de.yml", { "de" => { "ui" => { "common" => { "cancel" => "Abbrechen" } } } })

      health = described_class.new(root: dir, target_locales: %w[de])
      summary = health.sync_generated!

      expect(summary).to eq("de" => ["ui.common.save"])
      expect(health.missing_keys).to eq("de" => [])

      generated_file = File.join(dir, "config", "locales", "generated", "de.yml")
      expect(File).to exist(generated_file)
      expect(Psych.load_file(generated_file)).to eq(
        "de" => { "ui" => { "common" => { "save" => "Save" } } }
      )
    end
  end

  it "reports interpolation mismatches against the English source" do
    Dir.mktmpdir do |dir|
      write_locale(dir, "en.yml", { "en" => { "mail" => { "subject" => "Hello %{name}" } } })
      write_locale(dir, "de.yml", { "de" => { "mail" => { "subject" => "Hallo %{email}" } } })

      health = described_class.new(root: dir, target_locales: %w[de])
      report = health.inconsistent_interpolations

      expect(report["de"]).to contain_exactly(
        include(key: "mail.subject", expected: ["name"], actual: ["email"])
      )
    end
  end
end
