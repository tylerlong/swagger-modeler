class Specification < ActiveRecord::Base
  default_scope { order("title ASC") }

  validates :version, presence: true, uniqueness: { scope: :title}
  validates :title, presence: true
  has_many :definitions, dependent: :destroy
  has_many :common_models, dependent: :destroy
  has_many :paths, dependent: :destroy
  has_many :path_parameters, dependent: :destroy

  def display_name
    "#{title} #{version}"
  end

  def path_parameters_text
    self.path_parameters.collect{ |item| "#{item.name}\t#{item.type}\t#{item.description}" }.join("\n")
  end

  require_dependency 'util/properties_model'

  def path_parameters_text=(data)
    rows = data.split("\n").collect(&:strip).reject(&:blank?)
    items = rows.collect do |row|
      name, type, description = row.split("\t").collect(&:strip).reject(&:blank?)
      self.path_parameters.build({ name: name, type: type, description: description })
    end
    PropertiesModel.update_properties!(path_parameters, items)
  end

  # https://docs.google.com/spreadsheets/d/1Lne2Jz34J9mJ7shlVqglEy12JlmXtweeqHsHXTXHzaM/edit?ts=570c4d57#gid=1204854372
  # copy all and paste into lib/ringcentral-endpoints.csv
  # remove header line
  def load_rc_data! # load RingCentral data
    data = File.read(Rails.root.join('lib/ringcentral-endpoints.csv'))
    data = data.gsub('/{version}', '/v1.0')
      .gsub(%r</([^/]+)/(?:~|\{id\})>){ |m| "/#{$1}/{#{$1.gsub('-', '_').camelize(:lower)}Id}" }
      .gsub(%r</([^/]+)/\{key\}>){ |m| "/#{$1}/{#{$1.gsub('-', '_').camelize(:lower)}Key}" }
    rows = data.split(/[\r\n]+/).collect(&:strip).reject(&:blank?)
    rows.uniq.each do |row|
      method, uri, name, batch, user_plan_group, app_permission, user_permission, since, style, visibility, status, api_group, api_subgroup, name_for_reports, service_name, priority = row.split("\t").collect(&:strip)
      # create paths
      path = self.paths.find_by_uri(uri)
      if path.nil?
        path = self.paths.build(uri: uri)
        path.save!
      end
      # create verbs
      verb = path.verbs.find_by_name(name)
      if verb.nil?
        verb = path.verbs.build(method: method, name: name,
          batch: batch == 'Yes', visibility: visibility, status: status)
        verb.save!
      end
    end
  end

  def swagger
    result = {
      swagger: '2.0',
      info: {
        version: version,
        title: title,
        description: description,
        termsOfService: termsOfService,
      },
      host: host,
      basePath: basePath,
      schemes: schemes.split(/\s+/).reject(&:blank?),
      produces: produces.split(/\s+/).reject(&:blank?),
      consumes: consumes.split(/\s+/).reject(&:blank?),
      parameters: PathParameter.swagger,
      definitions: CommonModel.swagger,
      paths: {},
    }
    paths.each do |path|
      path_swagger = path.swagger
      if path_swagger.present?
        result[:paths][path.uri] = path_swagger
      end
    end
    result = JSON[result.to_json] # stringify_keys recursively: https://gist.github.com/mkuhnt/6815250
    result
  end
end
