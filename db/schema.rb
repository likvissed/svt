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

ActiveRecord::Schema.define(version: 20170814065247) do

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name",              limit: 64
    t.string   "short_description", limit: 64
    t.string   "long_description"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "standart_discrepancies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "item_id"
    t.integer  "property_id"
    t.integer  "property_value_id"
    t.integer  "event"
    t.string   "new_value"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["item_id"], name: "index_standart_discrepancies_on_item_id", using: :btree
    t.index ["property_id"], name: "fk_rails_d1c19a836e", using: :btree
    t.index ["property_value_id"], name: "index_standart_discrepancies_on_property_value_id", using: :btree
  end

  create_table "standart_log_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "log_id"
    t.integer  "property_id"
    t.string   "old_detail"
    t.string   "new_detail"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["log_id"], name: "index_standart_log_details_on_log_id", using: :btree
    t.index ["property_id"], name: "index_standart_log_details_on_property_id", using: :btree
  end

  create_table "standart_logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "item_id"
    t.integer  "user_id"
    t.integer  "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_standart_logs_on_item_id", using: :btree
    t.index ["user_id"], name: "index_standart_logs_on_user_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "id_tn",                                       null: false
    t.integer  "tn",                                          null: false
    t.string   "fullname"
    t.string   "phone",               limit: 10, default: ""
    t.string   "encrypted_password",             default: "", null: false
    t.integer  "role_id"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                  default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.index ["id_tn"], name: "index_users_on_id_tn", using: :btree
    t.index ["role_id"], name: "index_users_on_role_id", using: :btree
    t.index ["tn"], name: "index_users_on_tn", using: :btree
  end

  add_foreign_key "standart_discrepancies", "invent_property", column: "property_id", primary_key: "property_id"
end
