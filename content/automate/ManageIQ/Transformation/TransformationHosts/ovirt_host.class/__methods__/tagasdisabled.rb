#
# 
#

module MigrationFactory
  module ConversionHost
    class TagAsDisabled
      def initialize(handle = $evm)
        @debug = true
        @handle = handle
      end
      
      def main
        host = @handle.root['host']
        raise "No host found. Aborting." if host.nil?
        host.tag_assign('mf_conversion_host/false')
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  MigrationFactory::ConversionHost::TagAsDisabled.new.main
end
