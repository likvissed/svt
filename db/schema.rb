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

ActiveRecord::Schema.define(version: 20170127022132) do

  create_table "detail_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "type_name",  limit: 50, null: false
    t.string   "title",      limit: 50, null: false
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "etalon_changes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "system_unit_id"
    t.integer  "detail_type_id"
    t.string   "device",         null: false
    t.integer  "event",          null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["detail_type_id"], name: "index_etalon_changes_on_detail_type_id", using: :btree
    t.index ["system_unit_id"], name: "index_etalon_changes_on_system_unit_id", using: :btree
  end

  create_table "etalon_configs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "system_units_id"
    t.integer  "detail_types_id"
    t.string   "device",          null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["detail_types_id"], name: "index_etalon_configs_on_detail_types_id", using: :btree
    t.index ["system_units_id"], name: "index_etalon_configs_on_system_units_id", using: :btree
  end

  create_table "etalon_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "system_unit_id"
    t.integer  "detail_type_id"
    t.string   "device",         null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["detail_type_id"], name: "index_etalon_details_on_detail_type_id", using: :btree
    t.index ["system_unit_id"], name: "index_etalon_details_on_system_unit_id", using: :btree
  end

  create_table "log_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "log_id"
    t.integer  "detail_type_id"
    t.string   "old_detail"
    t.string   "new_detail"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["detail_type_id"], name: "index_log_details_on_detail_type_id", using: :btree
    t.index ["log_id"], name: "index_log_details_on_log_id", using: :btree
  end

  create_table "logs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "system_unit_id"
    t.integer  "event",          null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["system_unit_id"], name: "index_logs_on_system_unit_id", using: :btree
  end

  create_table "system_units", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "invnum",         limit: 50, null: false
    t.integer  "tn_responsible",                         unsigned: true
    t.integer  "division",                               unsigned: true
    t.boolean  "etalon_status",             null: false
    t.integer  "work_place_id",                          unsigned: true
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

end
