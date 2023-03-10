
require 'getoptlong'
require 'fileutils'

## Get OS
module OS
  def OS.is_windows
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end
  def OS.is_mac
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end
  def OS.is_linux
    !OS.is_windows and not OS.is_mac
  end
end

def check_plugins(dependencies)
  skip_dependency_manager = false

  ARGV.each_with_index do |value, index|
    case value
    when '--skip-dependency-manager'
      skip_dependency_manager = true
    end
  end

  if ['up', 'reload'].include?(ARGV[0]) && !skip_dependency_manager
    installed_dependencies = []

    puts "\033[0m" << "==> Checking dependencies..." << "\e[0m"

    raw_output = `vagrant plugin list`
    raw_list = raw_output.split("\n")

    raw_list.each do |plugin|
      if plugin.index("\e[0m") != nil
        first = plugin.index("\e[0m")  + 4
      else
        first = 0
      end
      installed_dependencies.push plugin.slice((first)..(plugin.index("(").to_i-1)).strip
    end

    dependencies_already_satisfied = true

    dependencies.each_with_index do |dependency, index|
      if not installed_dependencies.include? dependency
        dependencies_already_satisfied = false
        puts "\033[0m" << "==> Missing '#{dependency}'!" << "\e[0m"
        if not system "vagrant plugin install #{dependency}"
          puts "\n\033[0m" << "==> Could not install plugin '#{dependency}'. " << "\e[0m\033[41m" <<"Stopped." << "\e[0m"
          exit -1
        end
      end
    end
    if dependencies_already_satisfied
      puts "\033[0m" << "==> All dependencies are satisfied" << "\e[0m"
    else
      puts "\033[0m" << "==> Dependencies installed" << "\e[0m"
      exec "vagrant " << "--skip-dependency-manager " << ARGV.join(" ")
      exit
    end
  end
  if ARGV.include?('--skip-dependency-manager')
    ARGV.delete_at(ARGV.index('--skip-dependency-manager'))
  end
end

def process_extra_file(config, file)
  if File.file?(file)
    config.vm.provision 'file', source: file, destination: '/home/vagrant/' + file, run: 'always'
  end
end

def rsync_exclude
  return [
    'generated/code/*', 'var/page_cache/*', 'var/view_preprocessed/*',
    'pub/static/adminhtml/*', 'pub/static/base/*', 'pub/static/frontend/*',
    'dev', 'node_modules', 'phpserver', 'update'
  ]
end


def triggers(config, mount, hostName, hostDirectory)
  if mount == 'rsync'
    rsync_back = false
    config.trigger.after :up, :reload, :provision do |trigger|
      # Run rsync back
      trigger.ruby do |env,machine|
        if !File.exist?("#{hostDirectory}/app/etc/di.xml")
          rsync_back = true
        end
      end
      # Add post-up message
      trigger.info = config.vm.post_up_message
      trigger.info+= '---------------------------------------------------------'
      if rsync_back;
        trigger.warn = "\r\nRsync-back duration: ~10min. Once rsync-back is complete, run 'vagrant reload'"
        trigger.run = {inline: "vagrant rsync-back #{hostName}"}
      else
        # Run rsync auto
        trigger.warn = "\r\nRsync-auto is running... Do not close this terminal."
        trigger.run = {inline: "vagrant rsync-auto --rsync-chown #{hostName}"}
      end
    end
    config.trigger.after :destroy do |trigger|
      trigger.ruby do |env,machine|
        File.delete("#{hostDirectory}/app/etc/di.xml") if File.file?("#{hostDirectory}/app/etc/di.xml")
      end
    end
  end
end