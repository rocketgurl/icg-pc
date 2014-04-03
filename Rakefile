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

# Return File.join() in a manner safe for Windows
def file_join_safe(*paths)
  File.join(paths).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
end

# Version Number information
hash = `git rev-list --tags --max-count=1`
VERSION = `git describe --tags #{hash.chomp!}`
VERSION.chomp! # remove line breaks

# Path to RquireJS build config
RJS_CONFIG = file_join_safe('source', 'js', 'app.build.js')

# Build command for RequireJS / Uglify.js
RJS_BUILD = "#{ENV['REQUIRE_JS_PATH']} -o #{RJS_CONFIG}"

# CoffeeScript Compilation commands
COFFEE_SOURCE = file_join_safe('source', 'coffee')
COFFEE_OUTPUT = file_join_safe('source', 'js')
COFFEE_BUILD = "#{ENV['COFFEE_SCRIPT_PATH']} -o #{COFFEE_OUTPUT} -c #{COFFEE_SOURCE}"

# Build location
BUILD_DIR = "build"

# Directories to prune from build
PRUNE = {
  :dirs => [
    '.sass-cache',
    'coffee',
    'docs',
    'mocks',
    'tests',
    'scss',
    'mxadmin'
  ],
  :files => [
    'build.txt',
    'config.rb',
    'index.bak.html',
    'app.build'
  ]
}


# Update the version number in index.html
def append_version_number(version, file)
  prefix      = File.dirname(__FILE__)
  target_file = file_join_safe(prefix, file)
  tmp_file    = file_join_safe(prefix, 'source', 'index.bak.html')

  # make copy of original index.html (which is nice and clean)
  FileUtils.cp target_file, tmp_file

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

# Set the urlArgs param in main.js before compilation. We set it to the current commit
# so we can have build specific caching
def set_urlargs(version, file)
  target_file = file_join_safe(File.dirname(__FILE__), file)
  new = []
  f = File.open(target_file, 'r')
  f.each do |l|
    if l.match /urlArgs: '.*?',/
      new << "    urlArgs: '#{version}',"
    else
      new << l
    end
  end
  File.open(target_file, 'w') { |f|
    f.puts new
  }
  puts ">> URLARGS SET TO #{version}"
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

# Default task runs :build
task :default => [:build]

# Build task
task :build => [:coffee, :version, :compile, :prune_build, :cleanup, :liverebel]

# If CoffeeScript is present in the ENV then compile .coffee to .js
task :coffee do
  unless ENV['COFFEE_SCRIPT_PATH'].nil?
    unless system "#{COFFEE_BUILD}"
      puts red "!!! CoffeeScript compile FAILED!"
    else
      puts green "  >> CoffeeScript compile a success"
    end
  end
end

# Compile and build project with RequireJS
task :compile do
  # Move app.build into js folder
  app_build = file_join_safe(File.dirname(__FILE__),'source','app.build')
  app_js = file_join_safe(File.dirname(__FILE__),'source','js','app.build.js')
  FileUtils.cp app_build, app_js

  # Optimize with r.js
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
  append_version_number VERSION, "source/index.html"
  set_urlargs VERSION, "source/js/main.js"
end

task :cleanup do
  prefix      = File.dirname(__FILE__)
  index_munge = file_join_safe(prefix, 'source', 'index.html')
  index_clean = file_join_safe(prefix, 'source', 'index.bak.html')
  FileUtils.rm index_munge
  FileUtils.mv index_clean, index_munge
  set_urlargs '', "source/js/main.js"
end

task :liverebel do
  prefix      = File.dirname(__FILE__)
  lr_dir      = file_join_safe(prefix, 'liverebel')
  unless File.directory?(BUILD_DIR)
    FileUtils.mkdir BUILD_DIR
  end
  FileUtils.cp_r lr_dir, BUILD_DIR
end