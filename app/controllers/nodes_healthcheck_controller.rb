class NodesHealthcheckController < ApplicationController
  before_action only: %i[index]

  def index
    render json: {
      status: status,
      failed_nodes: invalid_nodes.map{ |nodes| NodeHealthcheckSerializer.new(nodes) }
    }
  end

  private

  def invalid_nodes
    @invalid_nodes ||= Node.not.available
  end

  def nodes_invalid?
    invalid_nodes.to_a.any?
  end

  def status
    if nodes_invalid?
      "FAILING"
    else
      "WORKING"
    end
  end
end
