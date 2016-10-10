class Disclosure
  include Mongoid::Document
  field :company_code, type: String
  field :company_name, type: String
  field :disclosure_date, type: Date
  field :disclosure_title, type: String
  field :disclosure_link, type: String
  field :disclosure_content, type: String
  field :disc_cont_date, type: DateTime
  
  index({ disclosure_link: 1 }, { unique: true, name: "disc_link_index" })
  index({ disclosure_date: 1 }, { name: "disc_date_index" })
  index({ disc_cont_date: 1 }, { name: "disc_cont_date_index" })
end

Disclosure.create_indexes