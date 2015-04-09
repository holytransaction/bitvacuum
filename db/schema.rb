# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150409131338) do

  create_table "bitvacuum_runs", force: :cascade do |t|
    t.string   "currency",            limit: 255
    t.integer  "number_of_inputs",    limit: 4
    t.float    "total_amount",        limit: 24
    t.string   "address",             limit: 255
    t.datetime "created_at"
    t.string   "sent_transaction_id", limit: 255
  end

  create_table "bitvacuum_scans", force: :cascade do |t|
    t.integer  "number_of_inputs", limit: 4
    t.float    "total_amount",     limit: 24
    t.datetime "created_at"
    t.string   "currency",         limit: 255
  end

end
