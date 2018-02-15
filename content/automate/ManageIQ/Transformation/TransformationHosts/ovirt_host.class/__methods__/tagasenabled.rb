#
#
#

module Transformation
  module TransformationHosts
    module OVirtHost
      class TagAsEnabled
        def initialize(handle = $evm)
          @handle = handle
        end

        def main
          host = @handle.root['host']
          raise "No host found. Aborting." if host.nil?
          host.tag_assign('v2v_transformation_host/true')
          host.tag_assign('v2v_transformation_method/vddk')
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Transformation::TransformationHosts::OVirtHost::TagAsEnabled.new.main
end
