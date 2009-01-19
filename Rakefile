begin
  require 'echoe'
rescue LoadError
  abort "You'll need to have `echoe' installed to use Carpet's Rakefile"
end

Echoe.new('carpet', '0.1.0') do |p|
  p.changelog        = "CHANGELOG"

  p.author           = "Matthias Marschall"
  p.email            = "mm@agileweboperations.com"

  p.summary = "Weave your infrastructure with capistrano"

  p.url              = "http://github.com/webops/carpet/tree/master"
  p.require_signed   = false
  p.dependencies     = ["capistrano      >=2.5.0"]
  p.development_dependencies = ["rspec >=1.1.11"]
  p.use_sudo = false if ENV['SUDOLESS']
end

require 'spec/rake/spectask'

desc "Run all specs in spec directory (excluding plugin specs)"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

