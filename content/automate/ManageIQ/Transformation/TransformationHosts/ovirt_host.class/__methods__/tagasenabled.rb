#
# 
#

module MigrationFactory
  module ConversionHost
    class TagAsEnabled
      def initialize(handle = $evm)
        @debug = true
        @handle = handle
      end
      
      def main
        if @debug
          ManageIQ::Automate::System::CommonMethods::MIQ_AE::Debug.new.dump_object
          ManageIQ::Automate::System::CommonMethods::MIQ_AE::Debug.new.dump_root
        end
        
        host = @handle.root['host']
        raise "No host found. Aborting." if host.nil?
        host.tag_assign('mf_conversion_host/true')
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  MigrationFactory::ConversionHost::TagAsEnabled.new.main
end
