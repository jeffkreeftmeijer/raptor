require 'bundler/setup'

task :default => [:spec]

task :spec do
  load File.expand_path('../spec/raptor_spec.rb', __FILE__)
  Raptor.run
end
