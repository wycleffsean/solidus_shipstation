xml = Builder::XmlMarkup.new
cdata = cdata_helper_for(xml)
xml.instruct!
xml.Orders(pages: (@shipments.total_count/50.0).ceil) {
  @shipments.each do |shipment|
    order = shipment.order

    xml.Order {
      xml.OrderID        shipment.id
      xml.OrderNumber    &cdata[shipment.number] # do not use shipment.order.number as this presents lookup issues
      xml.OrderDate      order.completed_at.strftime(Spree::ExportHelper::DATE_FORMAT)
      xml.OrderStatus    &cdata[shipment.state]
      xml.LastModified   [order.completed_at, shipment.updated_at].max.strftime(Spree::ExportHelper::DATE_FORMAT)
      xml.ShippingMethod &cdata[shipment.shipping_method.try(:name)]
      xml.OrderTotal     order.total
      xml.TaxAmount      order.tax_total
      xml.ShippingAmount order.ship_total
      xml.CustomField1   &cdata[order.number]

=begin
      if order.gift?
        xml.Gift
        xml.GiftMessage
      end
=end

      xml.Customer {
        xml.CustomerCode &cdata[order.email.slice(0, 50)]
        Spree::ExportHelper.address(xml, order, :bill)
        Spree::ExportHelper.address(xml, order, :ship)
      }
      xml.Items {
        shipment.manifest.each do |item|
          variant = item.variant
          xml.Item {
            xml.SKU         &cdata[variant.sku]
            xml.Name        &cdata[[variant.product.name, variant.options_text].join(' ')]
            xml.ImageUrl    &cdata[variant.images.first.try(:attachment).try(:url)]
            xml.Weight      variant.weight.to_f
            xml.WeightUnits Spree::Config.shipstation_weight_units
            xml.Quantity    item.quantity
            xml.UnitPrice   item.line_item.price

            if variant.option_values.present?
              xml.Options {
                variant.option_values.each do |value|
                  xml.Option {
                    xml.Name  &cdata[value.option_type.presentation]
                    xml.Value &cdata[value.name]
                  }
                end
              }
            end
          }
        end
      }
    }
  end
}
