begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task :spec do
    abort "RSpec is not available. In order to run spec, you must: gem install rspec"
  end
end

