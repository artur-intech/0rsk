# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

require 'yaml'
require 'minitest/autorun'
require 'pgtk/pool'
require 'loog'

module Minitest
  class Test
    def test_pgsql
      # rubocop:disable Style/ClassVars
      @@test_pgsql ||= Pgtk::Pool.new(
        Pgtk::Wire::Yaml.new(File.join(__dir__, '../target/pgsql-config.yml')),
        log: Loog::VERBOSE
      ).start
      # rubocop:enable Style/ClassVars
    end
  end
end
