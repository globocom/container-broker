# frozen_string_literal: true

class NodesHealthcheckController < ApplicationController
  def index
    render json: {
      status: status,
      failed_nodes: failed_nodes.map{ |node| NodeHealthcheckSerializer.new(node) }
    }
  end

  private

  def failed_nodes
    @failed_nodes ||= Node.unavailable
  end

  def nodes_failed?
    failed_nodes.to_a.any?
  end

  def status
    if nodes_failed?
      "FAILING"
    else
      "WORKING"
    end
  end
end
