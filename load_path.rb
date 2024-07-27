require_relative 'gems/gems_init'

lib_parent_dir = __dir__

reference_dir = File.dirname(caller[0] || __FILE__)
if File.directory?(reference_dir)
  is_local = File.expand_path(reference_dir).start_with?(__dir__)
  if is_local
    lib_parent_dir = reference_dir
  end
end

lib_dir = File.expand_path("lib", reference_dir)
if File.directory?(lib_dir)
  if not $LOAD_PATH.include?(lib_dir)
    $LOAD_PATH.unshift(lib_dir)
  end
else
  warn "No lib directory under #{reference_dir}"
end

libraries_dir = ENV["LIBRARIES_HOME"]
return if libraries_dir.nil?

libraries_dir = File.expand_path(libraries_dir)

Dir.glob("#{libraries_dir}/*/lib") do |library_dir|
  if not $LOAD_PATH.include?(library_dir)
    $LOAD_PATH.unshift(library_dir)
  end
end
