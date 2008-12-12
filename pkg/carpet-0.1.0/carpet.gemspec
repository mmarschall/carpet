Gem::Specification.new do |s|
  s.name = %q{carpet}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matthias Marschall"]
  s.cert_chain = ["/Users/mm/.gem/gem-public_cert.pem"]
  s.date = %q{2008-12-12}
  s.description = %q{Weave your infrastructure with capistrano}
  s.email = %q{mm@agileweboperations.com}
  s.extra_rdoc_files = ["CHANGELOG", "lib/appliances/apache_lb.rb", "lib/appliances/memcached.rb", "lib/appliances/mysql.rb", "lib/appliances/rails.rb", "lib/appliances/sax_parser_callbacks.inc", "lib/capistrano/deploy/remote_dependency.rb", "lib/carpet.rb", "lib/infrastructure/zones.rb", "lib/plugins/adm.rb", "lib/plugins/nfs.rb", "lib/plugins/pkg.rb", "lib/plugins/src.rb", "lib/plugins/svc.rb", "lib/plugins/zfs.rb", "lib/plugins/zone.rb", "README"]
  s.files = ["Capfile", "CHANGELOG", "lib/appliances/apache_lb.rb", "lib/appliances/memcached.rb", "lib/appliances/mysql.rb", "lib/appliances/rails.rb", "lib/appliances/sax_parser_callbacks.inc", "lib/capistrano/deploy/remote_dependency.rb", "lib/carpet.rb", "lib/infrastructure/zones.rb", "lib/plugins/adm.rb", "lib/plugins/nfs.rb", "lib/plugins/pkg.rb", "lib/plugins/src.rb", "lib/plugins/svc.rb", "lib/plugins/zfs.rb", "lib/plugins/zone.rb", "Manifest", "Rakefile", "README", "spec/appliances/apache_lb_spec.rb", "spec/appliances/rails_spec.rb", "spec/Capfile", "spec/capistrano/deploy/remote_dependency_spec.rb", "spec/carpet_spec.rb", "spec/infrastructure/zones_spec.rb", "spec/plugins/adm_spec.rb", "spec/plugins/nfs_spec.rb", "spec/plugins/pkg_spec.rb", "spec/plugins/src_spec.rb", "spec/plugins/svc_spec.rb", "spec/plugins/zfs_spec.rb", "spec/plugins/zone_spec.rb", "spec/spec_helper.rb", "carpet.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/webops/carpet/tree/master}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Carpet", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{carpet}
  s.rubygems_version = %q{1.2.0}
  s.signing_key = %q{/Users/mm/.gem/gem-private_key.pem}
  s.summary = %q{Weave your infrastructure with capistrano}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<capistrano>, [">= 2.5.0"])
      s.add_development_dependency(%q<rspec>, [">= 1.1.11"])
    else
      s.add_dependency(%q<capistrano>, [">= 2.5.0"])
      s.add_dependency(%q<rspec>, [">= 1.1.11"])
    end
  else
    s.add_dependency(%q<capistrano>, [">= 2.5.0"])
    s.add_dependency(%q<rspec>, [">= 1.1.11"])
  end
end
