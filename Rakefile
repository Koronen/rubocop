# encoding: utf-8

require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'Run RSpec with code coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].execute
end

desc 'Run RuboCop over itself'
RuboCop::RakeTask.new(:internal_investigation)

task default: [:spec, :internal_investigation]

require 'yard'
YARD::Rake::YardocTask.new

task :console do
  require 'irb'
  require 'irb/completion'
  require 'rubocop'
  ARGV.clear
  IRB.start
end

desc 'Benchmark a cop on given source file/dir'
task :bench_cop, [:cop, :srcpath, :times] do |_task, args|
  require 'benchmark'
  require 'rubocop'
  include RuboCop
  include RuboCop::Formatter::TextUtil

  cop_name = args[:cop]
  src_path = args[:srcpath]
  iterations = args[:times] ? args[:times].to_i : 1

  cop_class = if cop_name.include?('/')
                Cop::Cop.all.find { |klass| klass.cop_name == cop_name }
              else
                Cop::Cop.all.find do |klass|
                  klass.cop_name[/[a-zA-Z]+$/] == cop_name
                end
              end
  fail "No such cop: #{cop_name}" if cop_class.nil?

  config = ConfigLoader.load_file(ConfigLoader::DEFAULT_FILE)
  cop = cop_class.new(config)

  puts "Benchmarking #{cop.cop_name} on #{src_path} (using default config)"

  files = if File.directory?(src_path)
            Dir[File.join(src_path, '**', '*.rb')]
          else
            [src_path]
          end

  puts "(#{pluralize(iterations, 'iteration')}, " \
    "#{pluralize(files.size, 'file')})"

  srcs = files.map { |file| ProcessedSource.from_file(file) }

  puts 'Finished parsing source, testing inspection...'
  puts(Benchmark.measure do
    iterations.times do
      commissioner = Cop::Commissioner.new([cop], [])
      srcs.each { |src| commissioner.investigate(src) }
    end
  end)
end
