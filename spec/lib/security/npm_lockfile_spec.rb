# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'rubygems'

# Keeps transitive npm dependencies at or above the versions that fix the
# advisories listed in doc/security_advisories.md. These packages are not in
# package.json, so nothing else stops a lockfile regeneration from regressing.
RSpec.describe 'package-lock.json' do
  root = File.expand_path('../../..', __dir__)
  lockfile = JSON.parse(File.read(File.join(root, 'package-lock.json')))
  packages = lockfile.fetch('packages')

  # package => list of [vulnerable range, first patched version]
  patched = {
    'minimist' => [['>= 1.0.0', '1.2.6']],
    'loader-utils' => [['< 2.0.0', '1.4.1'], ['>= 2.0.0', '2.0.3']],
    'tar' => [['>= 0', '7.5.19']],
    'websocket-driver' => [['>= 0', '0.7.5']],
    'sha.js' => [['>= 0', '2.4.12']],
    'pbkdf2' => [['>= 1.0.0', '3.1.3']],
    'proxy-addr' => [['>= 1.1.0', '2.0.8']]
  }

  patched.each do |name, ranges|
    installed = packages.select { |path, _| path == "node_modules/#{name}" || path.end_with?("/node_modules/#{name}") }

    it "locks #{name} at a patched version" do
      expect(installed).not_to be_empty, "#{name} is no longer installed; drop it from this spec"

      installed.each do |path, meta|
        version = Gem::Version.new(meta.fetch('version'))
        ranges.each do |range, minimum|
          next unless Gem::Requirement.new(range).satisfied_by?(version)

          expect(version).to be >= Gem::Version.new(minimum), "#{path} is #{version}, needs >= #{minimum}"
        end
      end
    end
  end
end
