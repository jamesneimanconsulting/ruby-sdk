# frozen_string_literal: true

#
#    Copyright 2016-2018, Optimizely and contributors
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
require_relative 'constants'
require_relative '../exceptions'
require 'json'
require 'json-schema'

module Optimizely
  module Helpers
    module Validator
      module_function

      def attributes_valid?(attributes)
        # Determines if provided attributes are valid.
        #
        # attributes - User attributes to be validated.
        #
        # Returns boolean depending on validity of attributes.

        return true if attributes.nil? || attributes.is_a?(Hash)

        false
      end

      def event_tags_valid?(event_tags)
        # Determines if provided event tags are valid.
        #
        # event_tags - Event tags to be validated.
        #
        # Returns boolean depending on validity of event tags.

        return true if event_tags.nil? || event_tags.is_a?(Hash)

        false
      end

      def datafile_valid?(datafile)
        # Determines if a given datafile is valid.
        #
        # datafile - String JSON representing the project.
        #
        # Returns boolean depending on validity of datafile.

        begin
          datafile = JSON.parse(datafile)
        rescue
          return false
        end

        JSON::Validator.validate(Helpers::Constants::JSON_SCHEMA_V2, datafile)
      end

      def error_handler_valid?(error_handler)
        # Determines if a given error handler is valid.
        #
        # error_handler - error_handler to be validated.
        #
        # Returns boolean depending on whether error_handler has a handle_error method.

        error_handler.respond_to?(:handle_error)
      end

      def event_dispatcher_valid?(event_dispatcher)
        # Determines if a given event dispatcher is valid.
        #
        # event_dispatcher - event_dispatcher to be validated.
        #
        # Returns boolean depending on whether event_dispatcher has a dispatch_event method.

        event_dispatcher.respond_to?(:dispatch_event)
      end

      def logger_valid?(logger)
        # Determines if a given logger is valid.
        #
        # logger - logger to be validated.
        #
        # Returns boolean depending on whether logger has a log method.

        logger.respond_to?(:log)
      end

      def string_numeric?(str)
        !Float(str).nil?
      rescue
        false
      end

      def inputs_valid?(variables, logger = NoOpLogger.new, level = Logger::ERROR, error_handler = NoOpErrorHandler.new)
        # Determines if values of variables in given array are non empty string.
        #
        # variables - array values to validate.
        #
        # logger - logger.
        #
        # Returns boolean True if all of the values are valid, False otherwise.

        return false unless variables.respond_to?(:each) && !variables.empty?

        unless attributes_valid?(variables[:attributes])
          logger.log(Logger::ERROR, 'Provided attributes are in an invalid format.')
          error_handler.handle_error(InvalidAttributeFormatError)
          return false
        end

        unless event_tags_valid?(variables[:event_tags])
          logger.log(Logger::ERROR, 'Provided event tags are in an invalid format.')
          error_handler.handle_error(InvalidEventTagFormatError)
          return false
        end

        is_valid = true
        if variables.include? :user_id
          # Empty str is a valid user ID.
          unless variables[:user_id].is_a?(String)
            is_valid = false
            logger.log(level, "#{Constants::INPUT_VARIABLES['USER_ID']} is invalid")
          end
        end

        variables.delete_if { |key, _value| %w[attributes event_tags user_id].include? key.to_s }

        variables.each do |key, value|
          next if value.is_a?(String) && !value.empty?

          is_valid = false
          next unless logger_valid?(logger) && level

          logger.log(level, "#{Constants::INPUT_VARIABLES[key.to_s.upcase]} is invalid")
        end
        is_valid
      end
    end
  end
end
