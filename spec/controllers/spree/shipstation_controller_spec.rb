require 'spec_helper'

describe Spree::ShipstationController, type: :controller do
  render_views
  routes { Spree::Core::Engine.routes }

  before do
    Spree::Config.shipstation_ssl_encrypted = false # disable SSL for testing
    allow(described_class).to receive(:check_authorization).and_return(false)
    allow(described_class).to receive(:spree_current_user).and_return(FactoryBot.create(:user))
    @request.env['HTTP_ACCEPT'] = 'application/xml'
  end

  context 'logged in' do

    before { login }

    describe '#export' do
      let(:schema) { 'spec/fixtures/shipstation_xml_schema.xsd' }
      let(:order) { create(:order_ready_to_ship) }
      let!(:shipments) { order.shipments.to_a }
      let(:params) do
        {
          start_date: 1.day.ago.strftime('%m/%d/%Y %H:%M'),
          end_date: 1.day.from_now.strftime('%m/%d/%Y %H:%M'),
          format: 'xml'
        }
      end

      before { get :export, params: params }

      it 'renders successfully', :aggregate_failures do
        expect(response).to be_successful
        expect(response).to render_template(:export)
        expect(assigns(:shipments)).to match_array(shipments)
      end

      it 'generates valid ShipStation formatted xml' do
        expect(response.body).to pass_validation(schema)
      end
    end

    describe '#shipnotify' do
      # NOTE: Spree::Shipment factory creates new instances with tracking numbers,
      #   which might not reflect reality in practice
      let(:order_number) { 'ABC123' }
      let(:tracking_number) { '123456' }
      let(:order) { create(:order, payment_state: 'paid') }
      let!(:shipment) do
        shipment = create(:shipment, tracking: nil, number: order_number, order: order)
        if shipment.has_attribute?(:address_id)
          shipment.address_id = order.ship_address.id
        end
        shipment.save
        shipment
      end
      let!(:inventory_unit) { create(:inventory_unit, order: order, shipment: shipment) }

      context 'shipment found' do
        let(:params) do
          { order_number: order_number, tracking_number: tracking_number }
        end

        before do
          allow(order).to receive(:can_ship?) { true }
          allow(order).to receive(:paid?) { true }
          shipment.ready!

          post :shipnotify, params: params
        end

        it 'updates the shipment', :aggregate_failures do
          expect(shipment.reload.tracking).to eq(tracking_number)
          expect(shipment.state).to eq('shipped')
          expect(shipment.shipped_at).to be_present
        end

        it 'responds with success' do
          expect(response).to be_successful
        end
      end

      context 'shipment not found' do
        let(:invalid_params) do
          { order_number: 'JJ123456' }
        end
        before { post :shipnotify, params: invalid_params }

        it 'responds with failure' do
          expect(response.code).to eq('400')
        end
      end
    end
  end

  context 'not logged in' do
    it 'returns error' do
      get :export, params: { format: 'xml' }

      expect(response.code).to eq('401')
    end
  end

  def login
    config(username: 'mario', password: 'lemieux')

    user = 'mario'
    pw = 'lemieux'
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pw)
  end

  def config(options = {})
    options.each do |k, v|
      Spree::Config.send("shipstation_#{k}=", v)
    end
  end
end
