class CreateResponseBodyProperties < ActiveRecord::Migration
  def change
    create_table :response_body_properties do |t|
      t.integer :verb_id, null: false
      t.integer :position, default: 0
      t.string :name, null: false
      t.string :type, null: false
      t.string :description, null: false
      t.string :format, default: ''
      t.boolean :required, default: false
      t.timestamps null: false
    end
    add_index :response_body_properties, [:verb_id, :name], unique: true

    add_column :verbs, :response_body_text, :string, default: ''
  end
end
