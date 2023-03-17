#! /usr/bin/env ruby
require 'fileutils'
require 'pp'

DEBUG = ENV['DEBUG'] || false
REPO_DIR = ENV['REPO_DIR'] || "/gv0/repo/snapshots/ro/editii/scriptorium-masters"
raise "repo dir #{REPO_DIR} does not exist" unless Dir.exist?(REPO_DIR)

SCRIPTORIUM_TEI_DIR = File.expand_path(ENV["TEI_REPO"] || "~/products/teirepo")

LATEST_BUILD_INSTALLED_MARKER="#{SCRIPTORIUM_TEI_DIR}/latest_build_installed_marker"

listing = Dir.glob("#{REPO_DIR}/tei*.zip").sort_by { |f| File.mtime(f) }.reverse()
raise "no tei zips found under repo #{REPO_DIR} " if (listing.length == 0)
most_recent_tei_build_zip = listing.first

puts "found most recent build #{most_recent_tei_build_zip}" if DEBUG

latest_installed_build_from_marker = 
    if File.exist?(LATEST_BUILD_INSTALLED_MARKER)
        File.read(LATEST_BUILD_INSTALLED_MARKER)
    else
        nil
    end

# puts "marker indicates : '#{latest_installed_build_from_marker}''"

CURRENT_SYMBOLIC_LINK_FILENAME="#{SCRIPTORIUM_TEI_DIR}/latest"

if most_recent_tei_build_zip != latest_installed_build_from_marker then

    # unzip
    FileUtils.mkdir_p SCRIPTORIUM_TEI_DIR unless Dir.exist? SCRIPTORIUM_TEI_DIR

    # FileUtils.cp most_recent_tei_build_zip, SCRIPTORIUM_TEI_DIR
    # unzip(most_recent_tei_build_zip, SCRIPTORIUM_TEI_DIR)
    cmd = "unzip -d #{SCRIPTORIUM_TEI_DIR} #{most_recent_tei_build_zip}"
    puts "will run #{cmd}"
    %x{#{cmd}}
    raise "unzip command '#{cmd}' did not end well: code #{$?.exitstatus} " if $?.exitstatus != 0

    File.write(LATEST_BUILD_INSTALLED_MARKER, most_recent_tei_build_zip)

    basename = File.basename(most_recent_tei_build_zip, ".zip")
    File.symlink?(CURRENT_SYMBOLIC_LINK_FILENAME) && File.delete(CURRENT_SYMBOLIC_LINK_FILENAME)
    FileUtils.ln_s File.join(SCRIPTORIUM_TEI_DIR, basename), CURRENT_SYMBOLIC_LINK_FILENAME

else
     puts "! will not unzip again #{most_recent_tei_build_zip}" if DEBUG
end
