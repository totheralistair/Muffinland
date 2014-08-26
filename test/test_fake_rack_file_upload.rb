##!/usr/bin/env ruby

#require 'bundler/setup'
require 'rack'
require_relative '../src/fake_rack_upload'

def request_via_API app, method, path, params={}
  env = Rack::MockRequest.env_for path, method: method, params: params
  app.call env
end

res = request_via_API( FakeRackUpload.new,
                       'POST',
                       '/',
                      description: 'A README file',
                      text_source: Rack::Multipart::UploadedFile.new('/Users/alistaircockburn/Desktop/README.txt') )

if res[2][0] == File.read('/Users/alistaircockburn/Desktop/README.txt')
  print '.'
else
  print 'F'
end
puts
