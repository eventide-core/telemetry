#!/usr/bin/env bash

set -eEuo pipefail

trap 'printf "\n\e[31mError: Exit Status %s (%s)\e[m\n" $? "$(basename "$0")"' ERR

cd "$(dirname "$0")"

echo
echo "Start ($(basename "$0"))"

echo
echo "Install Gems"
echo "= = ="

if [ -z "${POSTURE:-}" ]; then
  echo "POSTURE is not set. Using \"operational\" by default."
  POSTURE="operational"
fi

gem_dir="gems"
gem_exec_dir="$gem_dir/exec"
ruby_platform_version="$(ruby -rrbconfig -e "puts RbConfig::CONFIG['ruby_version']")"
install_dir="$gem_dir/ruby/$ruby_platform_version"
export GEM_HOME="$(realpath .)/$install_dir"

echo
echo "Posture: $POSTURE"
echo "Gem Home: $GEM_HOME"
echo "Gem Executables Dir: $gem_exec_dir"

echo
echo "Removing installed gems"
echo "- - -"

cmd="rm -rf Gemfile.lock $gem_dir"
echo $cmd
eval "$cmd"

echo
echo "Installing gems"
echo "- - -"

cmd="gem install --no-user-install --bindir $gem_dir/exec --no-wrappers --file Gemfile --lock"
if [ "$POSTURE" != "operational" ]; then
  cmd="$cmd --development"
fi
echo $cmd
eval "$cmd"

project_gems=($(
  find . -maxdepth 2 -type f -name '*gemspec' |
    ruby -rrubygems -n -e 'spec = Gem::Specification.load($_.chomp); puts spec.name')
)
cmd="gem uninstall --no-user-install ${project_gems[@]}"
echo -e "\n$cmd"
eval "$cmd"

echo
echo "Generating gems/gems_init.rb"
echo "- - -"

ruby -rrubygems -rpathname -rrbconfig <<RUBY
gem_dir = Pathname('$gem_dir')
gem_home = Pathname('$GEM_HOME')

gem_dir.join('gems_init.rb').open('w') do |gems_init_rb|
  gems_init_rb.puts <<~RUBY
  # Generated by $0

  gem_home = File.expand_path('ruby/$ruby_platform_version', __dir__)

  RUBY

  Dir['$GEM_HOME/specifications/*.gemspec'].each do |gemspec|
    spec = Gem::Specification.load(gemspec)

    spec.full_require_paths.each do |full_require_path|
      require_path = Pathname(full_require_path).relative_path_from(gem_home.expand_path)

      append_load_path = "\$LOAD_PATH.push(File.expand_path('#{require_path}', gem_home))"

      gems_init_rb.puts append_load_path

      puts "Load path: #{gem_dir.join(require_path)}"
    end
  end

  gems_init_rb.puts <<~RUBY

  ENV['GEM_HOME'] ||= gem_home

  if ENV['AUTOLOAD_RUBYGEMS'] == 'on'
    if not Object.const_defined?(:Gem)
      Kernel.autoload(:Gem, 'rubygems')
    end
  end
  RUBY

  puts "Wrote #{gems_init_rb.path}"
end
RUBY

echo
echo "Generating Executables"
echo "- - -"
ruby -rrubygems -rpathname <<RUBY
gem_exec_dir = Pathname('$gem_exec_dir')
if not gem_exec_dir.directory?
  gem_exec_dir.mkdir
end

Dir['$GEM_HOME/specifications/*.gemspec'].each do |gemspec|
  spec = Gem::Specification.load(gemspec)

  spec.executables.each do |executable|
    gem_executable_path = Pathname(spec.full_gem_path).join(spec.bindir, executable)

    relative_executable_path = gem_executable_path.relative_path_from(gem_exec_dir.expand_path)

    executable_path = gem_exec_dir.join(executable)

    if executable_path.symlink?
      executable_path.unlink
      puts "Found symbolic link at #{executable_path}; it will be replaced by this script"
    else
      warn "Expected symbolic link at #{executable_path}"
    end

    executable_path.open('w', 0755) do |exec|
      exec.write(<<~RUBY)
#!/usr/bin/env ruby
require_relative '../gems_init.rb'
load File.expand_path('#{relative_executable_path}', __dir__)
      RUBY
    end

    puts "Wrote #{executable_path}"
  end
end
RUBY

echo
echo "Done ($(basename "$0"))"
