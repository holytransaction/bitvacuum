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

ActiveRecord::Schema.define(version: 20150328103341) do

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                      limit: 255
    t.string   "hmac_key",                   limit: 255
    t.string   "encrypted_password",         limit: 255,                          default: "",  null: false
    t.string   "reset_password_token",       limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",              limit: 4,                            default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",         limit: 255
    t.string   "last_sign_in_ip",            limit: 255
    t.string   "confirmation_token",         limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",          limit: 255
    t.string   "authentication_token",       limit: 255
    t.string   "permissions",                limit: 255
    t.integer  "parent_id",                  limit: 4
    t.decimal  "daily_withdrawal_total",                 precision: 16, scale: 8, default: 0.0
    t.decimal  "daily_deposit_total",                    precision: 16, scale: 8, default: 0.0
    t.decimal  "daily_exchange_total",                   precision: 16, scale: 8, default: 0.0
    t.decimal  "daily_withdrawal_limit",                 precision: 16, scale: 8, default: 0.0
    t.decimal  "daily_deposit_limit",                    precision: 16, scale: 8, default: 0.0
    t.decimal  "daily_exchange_limit",                   precision: 16, scale: 8, default: 0.0
    t.float    "withdrawal_fee",             limit: 24
    t.integer  "status",                     limit: 4
    t.string   "ripple_address",             limit: 255
    t.integer  "hmac_nonce",                 limit: 8
    t.string   "otp_secret",                 limit: 255
    t.float    "otp_free_daily_spend_limit", limit: 24
    t.integer  "confirm_password_change",    limit: 4
    t.string   "password_change_token",      limit: 255
    t.string   "invoice_callback_url",       limit: 255
    t.string   "transaction_callback_url",   limit: 255
    t.string   "exchange_callback_url",      limit: 255
    t.integer  "transactions_daily_limit",   limit: 4
    t.integer  "transactions_today",         limit: 4
    t.datetime "last_outgoing_transaction"
  end

  add_index "accounts", ["authentication_token"], name: "index_accounts_on_authentication_token", unique: true, using: :btree
  add_index "accounts", ["confirmation_token"], name: "index_accounts_on_confirmation_token", unique: true, using: :btree
  add_index "accounts", ["email", "parent_id"], name: "email_and_parent", unique: true, using: :btree
  add_index "accounts", ["reset_password_token"], name: "index_accounts_on_reset_password_token", unique: true, using: :btree

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body",          limit: 65535
    t.string   "resource_id",   limit: 255,   null: false
    t.string   "resource_type", limit: 255,   null: false
    t.integer  "author_id",     limit: 4
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "balances", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id",        limit: 4
    t.integer  "currency_id",       limit: 4
    t.decimal  "value",                       precision: 16, scale: 8, default: 0.0, null: false
    t.decimal  "unconfirmed_value",           precision: 16, scale: 8, default: 0.0, null: false
  end

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
  end

  create_table "currencies", force: :cascade do |t|
    t.string   "code",              limit: 255
    t.integer  "precision",         limit: 4
    t.integer  "display_precision", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",              limit: 255
    t.string   "website",           limit: 255
    t.integer  "confirmation_time", limit: 4
    t.integer  "currency_type",     limit: 4,   default: 0
    t.boolean  "default",           limit: 1,   default: false
  end

  create_table "exchange_orders", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",                     limit: 255
    t.integer  "invoice_id",               limit: 4
    t.integer  "from_currency_id",         limit: 4
    t.integer  "to_currency_id",           limit: 4
    t.string   "destination",              limit: 255
    t.integer  "account_id",               limit: 4
    t.decimal  "exchange_rate",                        precision: 16, scale: 8
    t.integer  "status",                   limit: 4
    t.datetime "expires"
    t.decimal  "ordered_amount",                       precision: 16, scale: 8
    t.integer  "refill_status",            limit: 4
    t.datetime "refill_status_updated_at"
    t.decimal  "refill_price",                         precision: 16, scale: 8
    t.string   "refill_method",            limit: 255
    t.string   "refill_order_id",          limit: 255
    t.integer  "out_transaction_id",       limit: 4
    t.decimal  "invoiced_amount",                      precision: 16, scale: 8
    t.decimal  "refill_price_usd",                     precision: 16, scale: 8
    t.decimal  "sale_price_usd",                       precision: 16, scale: 8
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.integer  "from_currency_id",                limit: 4
    t.integer  "to_currency_id",                  limit: 4
    t.decimal  "rate",                                        precision: 16, scale: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source",                          limit: 255
    t.float    "margin",                          limit: 24
    t.string   "api_key",                         limit: 255
    t.string   "secret",                          limit: 255
    t.string   "exchange_market_deposit_address", limit: 255
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",            limit: 255
    t.integer  "currency_id",     limit: 4
    t.string   "deposit_address", limit: 255
    t.integer  "status",          limit: 4
    t.datetime "expires"
    t.decimal  "invoiced_amount",             precision: 16, scale: 8, default: 0.0, null: false
    t.integer  "account_id",      limit: 4
    t.string   "type",            limit: 255
    t.decimal  "received_amount",             precision: 16, scale: 8, default: 0.0, null: false
    t.integer  "paid_with",       limit: 4
  end

  create_table "ofac_sdns", force: :cascade do |t|
    t.text     "name",                       limit: 65535
    t.string   "sdn_type",                   limit: 255
    t.string   "program",                    limit: 255
    t.string   "title",                      limit: 255
    t.string   "vessel_call_sign",           limit: 255
    t.string   "vessel_type",                limit: 255
    t.string   "vessel_tonnage",             limit: 255
    t.string   "gross_registered_tonnage",   limit: 255
    t.string   "vessel_flag",                limit: 255
    t.string   "vessel_owner",               limit: 255
    t.text     "remarks",                    limit: 65535
    t.text     "address",                    limit: 65535
    t.string   "city",                       limit: 255
    t.string   "country",                    limit: 255
    t.string   "address_remarks",            limit: 255
    t.string   "alternate_identity_type",    limit: 255
    t.text     "alternate_identity_name",    limit: 65535
    t.string   "alternate_identity_remarks", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ofac_sdns", ["sdn_type"], name: "index_ofac_sdns_on_sdn_type", using: :btree

  create_table "payeer_transactions", force: :cascade do |t|
    t.integer "m_operation_id",       limit: 4
    t.string  "m_operation_ps",       limit: 255
    t.string  "m_operation_date",     limit: 255
    t.string  "m_operation_pay_date", limit: 255
    t.integer "m_shop",               limit: 4
    t.integer "m_orderid",            limit: 4
    t.decimal "m_amount",                           precision: 10, scale: 2
    t.string  "m_curr",               limit: 255
    t.text    "m_desc",               limit: 65535
    t.string  "m_status",             limit: 255
    t.string  "m_sign",               limit: 255
  end

  create_table "pending_refills", force: :cascade do |t|
    t.integer "incoming_transaction_id", limit: 4,                          null: false
    t.integer "refill_transaction_id",   limit: 4
    t.decimal "price",                             precision: 16, scale: 8
  end

  create_table "queued_callbacks", force: :cascade do |t|
    t.string  "url",      limit: 255
    t.text    "body",     limit: 65535
    t.integer "status",   limit: 4
    t.integer "next_try", limit: 4
  end

  create_table "refill_prices", force: :cascade do |t|
    t.integer "currency_id", limit: 4,                          null: false
    t.decimal "usd_price",             precision: 16, scale: 8, null: false
  end

  create_table "statistics", force: :cascade do |t|
    t.datetime "date",                                                         null: false
    t.integer  "duration",                  limit: 4,                          null: false
    t.integer  "total_accounts",            limit: 4
    t.integer  "new_accounts",              limit: 4
    t.decimal  "revenue",                             precision: 16, scale: 8
    t.decimal  "total_user_deposits",                 precision: 16, scale: 8
    t.datetime "cohort_week_start"
    t.integer  "accounts_with_deposit",     limit: 4
    t.integer  "total_transactions",        limit: 4
    t.decimal  "total_transactions_volume",           precision: 16, scale: 8
  end

  create_table "transaction_servers", force: :cascade do |t|
    t.string   "currency",             limit: 255
    t.string   "authentication_token", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",                   limit: 255
    t.integer  "currency_id",            limit: 4
    t.string   "destination",            limit: 255
    t.decimal  "amount",                             precision: 16, scale: 8, default: 0.0, null: false
    t.integer  "status",                 limit: 4
    t.integer  "type",                   limit: 4,                            default: 0,   null: false
    t.string   "network_transaction_id", limit: 255
    t.integer  "from_account_id",        limit: 4
    t.integer  "to_account_id",          limit: 4
    t.integer  "invoice_id",             limit: 4
    t.decimal  "amount_in_usd",                      precision: 16, scale: 8
  end

  add_index "transactions", ["uuid"], name: "index_transactions_on_uuid", unique: true, using: :btree

  create_table "unused_addresses", force: :cascade do |t|
    t.integer "currency_id", limit: 4
    t.string  "address",     limit: 255
  end

  create_table "verification_requests", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
