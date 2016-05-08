class RequestModelsController < ApplicationController
  def new
    @spec = Specification.find(params[:specification_id])
    @path = Path.find(params[:path_id])
    @verb = Verb.find(params[:verb_id])
  end

  def create
    reqm = RequestModel.new(reqm_params)
    reqm.save!
    spec = Specification.find(params[:specification_id])
    path = Path.find(params[:path_id])
    verb = Verb.find(params[:verb_id])
    redirect_to specification_path_verb_url(spec, path, verb, anchor: 'request_body')
  end

  def edit
    @spec = Specification.find(params[:specification_id])
    @path = Path.find(params[:path_id])
    @verb = Verb.find(params[:verb_id])
    @reqm = RequestModel.find(params[:id])
  end

  def update
    reqm = RequestModel.find(params[:id])
    reqm.update_attributes(reqm_params)
    spec = Specification.find(params[:specification_id])
    path = Path.find(params[:path_id])
    verb = Verb.find(params[:verb_id])
    redirect_to specification_path_verb_url(spec, path, verb, anchor: 'request_body')
  end

  def destroy
    RequestModel.find(params[:id]).destroy
    spec = Specification.find(params[:specification_id])
    path = Path.find(params[:path_id])
    verb = Verb.find(params[:verb_id])
    redirect_to specification_path_verb_url(spec, path, verb, anchor: 'request_body')
  end

  private

  def reqm_params
    params.permit(:name, :properties_text, :verb_id)
  end
end