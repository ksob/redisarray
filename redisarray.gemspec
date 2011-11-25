# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redisarray/version"

Gem::Specification.new do |s|
  s.name        = "redisarray"
  s.version     = RedisArray::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kamil Sobieraj"]
  s.email       = ["ksobej@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Simplifies storing two dimensional arrays inside Redis}
  s.description = %q{Implements memory efficient algorithm allowing to store tables or two dimensional arrays inside Redis.}

  s.rubyforge_project = "redisarray"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency('redis', '~> 2.2.2')
  s.add_development_dependency("rake", ["~> 0.9"])
  s.add_development_dependency("rspec", ["~> 2.7.0"])
end
