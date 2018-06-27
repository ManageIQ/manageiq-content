module ManageIQ
  module Automate
    module System
      module CommonMethods
        module MiqAe
          class AdvisoryLock
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
            end

            def acquire_lock(lock_name)
              hashcode = stable_hashcode(lock_name)
              result = connection.select_value("select pg_try_advisory_lock(#{hashcode});")
              (result == 't' || result == true)
            end

            def release_lock(lock_name)
              hashcode = stable_hashcode(lock_name)
              connection.execute("select pg_advisory_unlock(#{hashcode});")
            end

            private

            def stable_hashcode(lock_name)
              require 'zlib'
              Zlib.crc32(lock_name) & 0x7fffffff
            end
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ManageIQ::Automate::System::CommonMethods::MiqAe::AdvisoryLock.new.main
end
