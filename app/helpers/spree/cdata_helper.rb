require 'builder'

module Spree
  module CdataHelper
    def cdata_helper_for(xml)
      lambda do |data|
        proc { data.nil? ? data : xml.cdata!(data) }
      end
    end
  end
end
