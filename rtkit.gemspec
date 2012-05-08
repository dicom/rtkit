# encoding: UTF-8

require File.expand_path('../lib/rtkit/version', __FILE__)

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'rtkit'
  s.version = RTKIT::VERSION
  s.date = Time.now
  s.summary = "Library for handling radiotherapy DICOM modalities."
  s.require_paths = ['lib']
  s.author = "Christoffer Lervag"
  s.email = "chris.lervag@gmail.com"
  s.homepage = "https://github.com/dicom/rtkit/"
  s.description = "DICOM is a standard widely used throughout the world to store and transfer medical image data. This library enables powerful ways of handling the radiotherapy DICOM modalities in Ruby, to the benefit of any student or professional who would like to go further with their radiotherapy data."
  s.files = Dir["{lib}/**/*", "[A-Z]*"]

  s.required_ruby_version = '>= 1.9.2'
  s.required_rubygems_version = '>= 1.8.6'

  s.add_dependency('dicom', '0.9.3')
  s.add_dependency('narray', '0.6.0.1')

  s.add_development_dependency('bundler', '>= 1.0.0')
  s.add_development_dependency('mocha', '>= 0.10.0')
  s.add_development_dependency('rake', '>= 0.9.2.2')
  s.add_development_dependency('rspec', '>= 2.9.0')
end