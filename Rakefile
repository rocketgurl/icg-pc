#!/usr/bin/env ruby -wKU
#
# Policy Central 2.0 Build Scripts
# ================================
# 
# @author Alec Munro
# @author Darren Newton
#
require "bundler"
require "fileutils"
require "nokogiri"

# Path to RquireJS build config
RJS_CONFIG = File.join('source', 'js', 'app.build.js').gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)

# Build command for RequireJS / Uglify.js
RJS_BUILD = "#{ENV['REQUIRE_JS_PATH']} -o #{RJS_CONFIG}"

# Build location
BUILD_DIR = "build"

# Directories to prune from build
PRUNE = {
  :dirs => [
    'coffee',
    'docs',
    # 'mocks',
    'tests'
  ],
  :files => [
    'build.txt',
    'config.rb'
  ]
}

# Default task runs :build
task :default => [:build]

# Build task
task :build => [:compile, :prune_build, :version]

# Compile and build project with RequireJS
task :compile do
  puts yellow "-> Compiling and moving to build directory..."
  unless system "#{RJS_BUILD}"
    puts red "  !!! Compile and move failed! Run manually with verbose mode on. !!!"
  else
    puts green "  >> Compile and move was a success"
  end
end

# Remove unecessary directories from build
task :prune_build do
  # Ensure we can find the build directory
  unless File.directory?(BUILD_DIR)
    puts red "  !!! Could not find build directory"
    break
  end

  # Remove directories
  dirs = PRUNE[:dirs].map { |d| safe_path(File.join(BUILD_DIR, d)) }
  unless FileUtils.rm_rf dirs
    puts red "  !!! Could not prune directories !!!"
  else
    puts green "  >> Pruned build directories"
  end

  # Remove files
  files = PRUNE[:files].map { |f| safe_path(File.join(BUILD_DIR, f)) }
  unless FileUtils.rm files, :force => true
    puts red "  !!! Could not prune files !!!"
  else
    puts green "  >> Pruned build files"
  end

end

# Append the latest commit hash to the footer of index.html
task :version do
  version = `git describe --tags --always HEAD`
  append_version_number version.chomp!, "index.html"
end

# Return File.join() in a manner safe for Windows
def file_join_safe(path_a, path_b)
  File.join(path_a, path_b).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
end

# Update the version number in index.html
def append_version_number(version, file)
  prefix      = File.dirname(__FILE__)
  target_file = file_join_safe(prefix, BUILD_DIR)
  target_file = file_join_safe(target_file, file)

  f = File.open(target_file)
  doc = Nokogiri::HTML(f)
  f.close

  span = doc.css "#version-number"
  span.each do |s|
    s.content = "#{version}"
  end

  File.open(target_file, 'w') { |f| 
    f.puts doc.to_html
  }
  puts ">> VERSION #{version} APPENDED"
end

# Return File.join() in a manner safe for Windows
# @params [String] filepath
def safe_path(path)
  path.gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
end

# Color output functions - for legibility
#
# @param text [String]
# @param color_code [Integer]
def colorize(text, color_code)
"\e[#{color_code}m#{text}\e[0m"
end

# Define colors for STDOUT
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end