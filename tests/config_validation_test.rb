# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "psych"

ROOT = File.expand_path("..", __dir__)
CONFIG_PATHS = Dir[
  File.join(ROOT, "Classic", "**", "*.{conf,yaml}"),
  File.join(ROOT, "Fleet", "**", "*.yaml")
].sort.freeze

class ConfigValidationTest < Minitest::Test
  def test_configuration_mappings_have_unique_keys
    CONFIG_PATHS.each do |path|
      duplicates = duplicate_mapping_keys(Psych.parse_stream(File.read(path)))
      assert_empty duplicates, "#{relative(path)} has duplicate mapping keys: #{duplicates.join(', ')}"
    end
  end

  def test_fleet_packs_have_valid_schedules
    yaml_paths.each do |path|
      documents = load_documents(path)
      query_names = documents.each_with_object([]) do |document, names|
        names << document.dig("spec", "name") if document["kind"] == "query"
      end

      assert_unique query_names, "#{relative(path)} query names"

      documents.select { |document| document["kind"] == "pack" }.each do |pack|
        scheduled_queries = pack.dig("spec", "queries") || []
        schedule_names = scheduled_queries.map { |query| query.fetch("name") }

        assert_unique schedule_names, "#{relative(path)} scheduled query names"

        scheduled_queries.each do |query|
          assert_includes query_names, query.fetch("query"),
                          "#{relative(path)} references an undefined query"
          assert_operator query.fetch("interval"), :>, 1,
                          "#{relative(path)} #{query.fetch('name')} interval must be greater than 1"
          assert_operator query.fetch("interval"), :<, 604_800,
                          "#{relative(path)} #{query.fetch('name')} interval must be less than 604800"
        end
      end
    end
  end

  def test_windows_wmi_script_consumers_keep_differential_and_snapshot_queries
    classic = JSON.parse(File.read(File.join(ROOT, "Classic", "Endpoints", "Windows", "osquery.conf")))
    classic_schedule = classic.fetch("schedule")

    assert_wmi_schedule classic_schedule.fetch("wmi_script_event_consumers"), 3_600, false
    assert_wmi_schedule classic_schedule.fetch("wmi_script_event_consumers_snapshot"), 28_800, true
    assert_equal "SELECT * FROM wmi_script_event_consumers;",
                 classic_schedule.dig("wmi_script_event_consumers", "query")
    assert_equal "SELECT * FROM wmi_script_event_consumers;",
                 classic_schedule.dig("wmi_script_event_consumers_snapshot", "query")

    fleet_path = File.join(ROOT, "Fleet", "Endpoints", "Windows", "osquery.yaml")
    documents = load_documents(fleet_path)
    fleet_pack = documents.find { |document| document["kind"] == "pack" }
    fleet_schedule = fleet_pack.dig("spec", "queries").each_with_object({}) do |query, schedule|
      schedule[query.fetch("name")] = query
    end
    fleet_queries = documents
                    .select { |document| document["kind"] == "query" }
                    .each_with_object({}) do |document, queries|
      queries[document.dig("spec", "name")] = document.dig("spec", "query")
    end

    assert_wmi_schedule fleet_schedule.fetch("wmi_script_event_consumers"), 3_600, false
    assert_wmi_schedule fleet_schedule.fetch("wmi_script_event_consumers_snapshot"), 28_800, true
    assert_equal "SELECT * FROM wmi_script_event_consumers;",
                 fleet_queries.fetch("wmi_script_event_consumers")
    assert_equal "SELECT * FROM wmi_script_event_consumers;",
                 fleet_queries.fetch("wmi_script_event_consumers_snapshot")
  end

  private

  def yaml_paths
    CONFIG_PATHS.select { |path| File.extname(path) == ".yaml" }
  end

  def load_documents(path)
    Psych.load_stream(File.read(path)).compact
  end

  def duplicate_mapping_keys(node, location = [], duplicates = [])
    if node.is_a?(Psych::Nodes::Mapping)
      seen = {}
      node.children.each_slice(2) do |key_node, value_node|
        key = key_node.respond_to?(:value) ? key_node.value : "<complex-key>"
        duplicates << (location + [key]).join(".") if seen[key]
        seen[key] = true
        duplicate_mapping_keys(value_node, location + [key], duplicates)
      end
    elsif node.respond_to?(:children)
      Array(node.children).each { |child| duplicate_mapping_keys(child, location, duplicates) }
    end

    duplicates
  end

  def assert_unique(values, label)
    duplicates = values.group_by { |value| value }
                       .select { |_value, occurrences| occurrences.length > 1 }
                       .keys
    assert_empty duplicates, "#{label} are duplicated: #{duplicates.join(', ')}"
  end

  def assert_wmi_schedule(query, interval, snapshot)
    assert_equal interval, query.fetch("interval")
    assert_equal snapshot, query.fetch("snapshot", false)
  end

  def relative(path)
    path.sub(/\A#{Regexp.escape(ROOT)}\//, "")
  end
end
