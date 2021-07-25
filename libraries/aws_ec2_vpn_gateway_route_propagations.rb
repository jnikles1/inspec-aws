# frozen_string_literal: true

require 'aws_backend'

class AWSEc2VPNGatewayRoutePropagations < AwsResourceBase
  name 'aws_ec2_vpn_gateway_route_propagations'
  desc 'List the properties.'

  example '
    describe aws_ec2_vpn_gateway_route_propagations do
      it { should exist }
    end
  '

  attr_reader :table

  FilterTable.create
             .register_column(:route_table_ids,                           field: :route_table_id)
             .register_column(:propagating_vgws_gateway_ids,                   field: :propagating_vgws_gateway_ids, style: :simple)
             .install_filter_methods_on_resource(self, :table)

  def initialize(opts = {})
    super(opts)
    validate_parameters
    @table = fetch_data
  end

  def fetch_data
    route_table_rows = []
    paginate_request do |api_response|
      route_table_rows += api_response.route_tables.map do |route_table|
        flat_hash_from(route_table)
      end
    end
    route_table_rows
  end

  private

  def paginate_request
    pagination_options = { max_results: 100 }
    loop do
      api_response = catch_aws_errors do
        @aws.compute_client.describe_route_tables(pagination_options)
      end
      return if api_response.nil? || api_response.empty?
      yield api_response
      break unless api_response.next_token
      pagination_options = { next_token: api_response.next_token }
    end
  end

  def flat_hash_from(route_table)
    propagating_vgws = route_table.propagating_vgws
    # propagation = propagating_vgws.select { |propagation| propagation.association_state.state == 'associated' }
    {
      route_table_id: route_table.route_table_id,
      propagating_vgws_gateway_ids: map(propagating_vgws, 'gateway_id'),
      # associated_gateway_ids: map(propagating_vgws, 'gateway_id'),
    }
  end

  def map(collection, attr)
    collection.map { |obj| obj.instance_eval(attr) }
  end
end
