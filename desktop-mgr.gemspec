# encoding: utf-8
require File.expand_path("../lib/desktop/version", __FILE__)

Gem::Specification.new do |s|
    #Metadata
    s.name = "desktop-mgr"
    s.version = Desktop::VERSION
    s.authors = ["Sean Gillespie"]
    s.email = ["sean.william.g@gmail.com"]
    s.homepage = "https://github.com/swgillespie/desktop"
    s.summary = %q{A simple workspace manager.}
    s.description = %q{A simple workspace manager.}
    s.licenses = ['MIT']

    #Manifest
    s.files = `git ls-files`.split("\n")
    s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.require_paths = ['lib']

    
    s.add_runtime_dependency 'thor', '~> 0.19'
    s.add_runtime_dependency 'sequel', '~> 4.38'
    s.add_runtime_dependency 'terminal-table', '~> 1.7', '>= 1.7.1'
end
