require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "health_monitor"
    gem.summary = %Q{Monitor all aspects of your applications health.}
    gem.email = "blythe@snowgiraffe.com"
    gem.homepage = "http://github.com/blythedunham/health_monitor"
    gem.authors = ["Blythe Dunham"]
    
    gem.add_dependency('activesupport', '>= 2.1')
    gem.add_dependency('actionpack', '>=2.1')
    
    #gem.add_development_dependency('timecop', '0.3.1')
    gem.add_development_dependency('mocha', '>=0.9.8')
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"

    gem.extra_rdoc_files = ["README.rdoc", "LICENSE"]

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "health_monitor #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
