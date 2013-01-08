class CreateEntries < ActiveRecord::Migration
  def self.up
    create_table :entries do |t|
      t.string :type_name, :null => false
      t.string :description, :null => false
      t.string :version, :null => false
      t.string :uri, :null => false

      t.timestamps
    end
    add_index :entries, [ :type_name, :version, :uri ], \
      :unique => true, :type_name => 'unique_key_on_type_name_version_uri'
    add_index :entries, [ :type_name ]
  end

  def self.down
    remove_index :entries, [ :type_name ]
    remove_index :entries, :type_name => 'unique_key_on_type_name_version_uri'
    drop_table :entries
  end
end
