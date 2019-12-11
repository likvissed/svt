# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171018041102) do

  create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", limit: 64
    t.string "short_description", limit: 64
    t.string "long_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "standard_discrepancies", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "item_id"
    t.integer "property_id"
    t.integer "property_value_id"
    t.integer "event"
    t.string "new_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_standard_discrepancies_on_item_id"
    t.index ["property_value_id"], name: "index_standard_discrepancies_on_property_value_id"
  end

  create_table "standard_log_details", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "log_id"
    t.integer "property_id"
    t.string "old_detail"
    t.string "new_detail"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["log_id"], name: "index_standard_log_details_on_log_id"
    t.index ["property_id"], name: "index_standard_log_details_on_property_id"
  end

  create_table "standard_logs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "item_id"
    t.string "username"
    t.integer "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_standard_logs_on_item_id"
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "id_tn", null: false
    t.integer "tn", null: false
    t.string "fullname"
    t.string "phone", limit: 10, default: ""
    t.string "encrypted_password", default: "", null: false
    t.integer "role_id"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id_tn"], name: "index_users_on_id_tn"
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["tn"], name: "index_users_on_tn"
  end

end
