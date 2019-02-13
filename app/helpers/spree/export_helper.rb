require 'builder'

module Spree

  module ExportHelper
    extend CdataHelper

    DATE_FORMAT = '%m/%d/%Y %H:%M'.freeze

    # rubocop:disable all
    def self.address(xml, order, type)
      name = "#{type.to_s.titleize}To"
      address = order.send("#{type}_address")
      cdata = cdata_helper_for(xml)

      xml.__send__(name) {
        xml.Name         &cdata[address.full_name]
        xml.Company      &cdata[address.company]

        if type == :ship
          xml.Address1   &cdata[address.address1]
          xml.Address2   &cdata[address.address2]
          xml.City       &cdata[address.city]
          xml.State      &cdata[address.state ? address.state.abbr : address.state_name]
          xml.PostalCode &cdata[address.zipcode]
          xml.Country    &cdata[address.country.iso]
        end

        xml.Phone        &cdata[address.phone]
      }
    end
    # rubocop:enable all

  end

end
