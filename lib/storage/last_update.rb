require 'mongoid'

class LastUpdate
  include Mongoid::Document
  field :job_name, type: String
  field :last_runtime, type: DateTime
  field :last_data, type: Hash
end