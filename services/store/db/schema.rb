# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_07_18_220140) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_variant_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_variant_id"], name: "index_cart_items_on_cart_id_and_product_variant_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_variant_id"], name: "index_cart_items_on_product_variant_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "chat_id"
    t.string "session_id"
    t.string "customer_name"
    t.string "customer_phone"
    t.string "customer_email"
    t.string "status", default: "active"
    t.string "channel", null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "shipping_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.string "currency", default: "USD"
    t.text "shipping_address"
    t.text "billing_address"
    t.text "notes"
    t.datetime "expires_at"
    t.datetime "last_activity_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_carts_on_channel"
    t.index ["chat_id"], name: "index_carts_on_chat_id"
    t.index ["customer_phone"], name: "index_carts_on_customer_phone"
    t.index ["expires_at"], name: "index_carts_on_expires_at"
    t.index ["last_activity_at"], name: "index_carts_on_last_activity_at"
    t.index ["session_id"], name: "index_carts_on_session_id"
    t.index ["status"], name: "index_carts_on_status"
  end

  create_table "cash_register_sessions", force: :cascade do |t|
    t.string "session_number", null: false
    t.string "cashier_name", null: false
    t.string "status", default: "open"
    t.decimal "opening_cash", precision: 10, scale: 2, null: false
    t.decimal "closing_cash", precision: 10, scale: 2
    t.decimal "cash_sales", precision: 10, scale: 2, default: "0.0"
    t.decimal "card_sales", precision: 10, scale: 2, default: "0.0"
    t.decimal "other_sales", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_sales", precision: 10, scale: 2, default: "0.0"
    t.decimal "cash_deposits", precision: 10, scale: 2, default: "0.0"
    t.decimal "cash_withdrawals", precision: 10, scale: 2, default: "0.0"
    t.decimal "expected_cash", precision: 10, scale: 2
    t.decimal "actual_cash", precision: 10, scale: 2
    t.decimal "cash_difference", precision: 10, scale: 2
    t.datetime "opened_at", null: false
    t.datetime "closed_at"
    t.text "opening_notes"
    t.text "closing_notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cashier_name"], name: "index_cash_register_sessions_on_cashier_name"
    t.index ["closed_at"], name: "index_cash_register_sessions_on_closed_at"
    t.index ["opened_at"], name: "index_cash_register_sessions_on_opened_at"
    t.index ["session_number"], name: "index_cash_register_sessions_on_session_number", unique: true
    t.index ["status"], name: "index_cash_register_sessions_on_status"
  end

  create_table "chats", force: :cascade do |t|
    t.string "wa_id", null: false, comment: "WhatsApp chat JID (phone@c.us)"
    t.string "name", comment: "Contact or group name if available"
    t.datetime "last_message_at", comment: "Timestamp of last message processed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "waha_session_id"
    t.string "profile_pic_url"
    t.datetime "pinned_at"
    t.index ["pinned_at"], name: "index_chats_on_pinned_at"
    t.index ["wa_id"], name: "index_chats_on_wa_id", unique: true
    t.index ["waha_session_id"], name: "index_chats_on_waha_session_id"
  end

  create_table "inventory_lots", force: :cascade do |t|
    t.bigint "product_variant_id", null: false
    t.string "lot_number", null: false
    t.integer "quantity_received", null: false
    t.integer "quantity_remaining", null: false
    t.decimal "unit_cost", precision: 10, scale: 4, null: false
    t.decimal "total_cost", precision: 10, scale: 2, null: false
    t.decimal "landed_cost_per_unit", precision: 10, scale: 4
    t.decimal "total_landed_cost", precision: 10, scale: 2
    t.date "received_date", null: false
    t.date "expiry_date"
    t.string "supplier_name"
    t.string "purchase_order_number"
    t.string "status", default: "active"
    t.jsonb "cost_breakdown", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expiry_date"], name: "index_inventory_lots_on_expiry_date"
    t.index ["lot_number"], name: "index_inventory_lots_on_lot_number", unique: true
    t.index ["product_variant_id"], name: "index_inventory_lots_on_product_variant_id"
    t.index ["purchase_order_number"], name: "index_inventory_lots_on_purchase_order_number"
    t.index ["received_date"], name: "index_inventory_lots_on_received_date"
    t.index ["status"], name: "index_inventory_lots_on_status"
    t.index ["supplier_name"], name: "index_inventory_lots_on_supplier_name"
  end

  create_table "marketing_campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.string "platform", null: false
    t.string "campaign_id", null: false
    t.string "campaign_type"
    t.string "status", default: "active"
    t.decimal "budget", precision: 10, scale: 2
    t.decimal "spent", precision: 10, scale: 2, default: "0.0"
    t.decimal "cost_per_click", precision: 10, scale: 4
    t.decimal "cost_per_conversion", precision: 10, scale: 4
    t.integer "impressions", default: 0
    t.integer "clicks", default: 0
    t.integer "conversions", default: 0
    t.date "start_date"
    t.date "end_date"
    t.text "targeting_criteria"
    t.text "creative_content"
    t.jsonb "performance_metrics", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_marketing_campaigns_on_campaign_id", unique: true
    t.index ["end_date"], name: "index_marketing_campaigns_on_end_date"
    t.index ["name"], name: "index_marketing_campaigns_on_name"
    t.index ["platform"], name: "index_marketing_campaigns_on_platform"
    t.index ["start_date"], name: "index_marketing_campaigns_on_start_date"
    t.index ["status"], name: "index_marketing_campaigns_on_status"
  end

  create_table "media_files", force: :cascade do |t|
    t.string "filename"
    t.string "mimetype"
    t.bigint "message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_media_files_on_message_id"
  end

  create_table "message_reactions", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "reaction", null: false
    t.string "user_wa_id", null: false, comment: "WhatsApp user ID who reacted"
    t.datetime "created_at", null: false
    t.index ["message_id", "user_wa_id"], name: "index_message_reactions_on_message_id_and_user_wa_id", unique: true
    t.index ["message_id"], name: "index_message_reactions_on_message_id"
    t.index ["user_wa_id"], name: "index_message_reactions_on_user_wa_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "wa_message_id", null: false, comment: "WhatsApp message ID"
    t.integer "direction", default: 0, null: false, comment: "0=incoming,1=outgoing"
    t.string "message_type", default: "text", null: false, comment: "WhatsApp message type (text,image,document,...)"
    t.text "body"
    t.jsonb "payload", default: {}, null: false, comment: "Raw WAHA payload"
    t.datetime "sent_at", comment: "Original timestamp from WhatsApp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "read_at"
    t.bigint "reply_to_message_id"
    t.datetime "pinned_at"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["read_at"], name: "index_messages_on_read_at"
    t.index ["reply_to_message_id"], name: "index_messages_on_reply_to_message_id"
    t.index ["wa_message_id"], name: "index_messages_on_wa_message_id", unique: true
  end

  create_table "order_attributions", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "marketing_campaign_id", null: false
    t.string "attribution_type", null: false
    t.decimal "attribution_weight", precision: 5, scale: 4, default: "1.0"
    t.decimal "attributed_revenue", precision: 10, scale: 2
    t.decimal "attributed_cost", precision: 10, scale: 2
    t.datetime "click_timestamp"
    t.datetime "conversion_timestamp"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_campaign"
    t.string "utm_term"
    t.string "utm_content"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attribution_type"], name: "index_order_attributions_on_attribution_type"
    t.index ["click_timestamp"], name: "index_order_attributions_on_click_timestamp"
    t.index ["conversion_timestamp"], name: "index_order_attributions_on_conversion_timestamp"
    t.index ["marketing_campaign_id"], name: "index_order_attributions_on_marketing_campaign_id"
    t.index ["order_id"], name: "index_order_attributions_on_order_id"
    t.index ["utm_campaign"], name: "index_order_attributions_on_utm_campaign"
    t.index ["utm_source"], name: "index_order_attributions_on_utm_source"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_variant_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.decimal "unit_cost", precision: 10, scale: 4
    t.decimal "total_cost", precision: 10, scale: 2
    t.string "fulfillment_status", default: "pending"
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fulfillment_status"], name: "index_order_items_on_fulfillment_status"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_variant_id"], name: "index_order_items_on_product_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_number", null: false
    t.string "short_link_token", null: false
    t.string "status", default: "pending"
    t.string "channel", null: false
    t.string "customer_name"
    t.string "customer_phone"
    t.string "customer_email"
    t.text "customer_notes"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "shipping_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "cost_of_goods", precision: 10, scale: 2, default: "0.0"
    t.string "currency", default: "USD"
    t.datetime "order_date"
    t.datetime "shipped_date"
    t.datetime "delivered_date"
    t.text "shipping_address"
    t.text "billing_address"
    t.string "shipping_method"
    t.string "tracking_number"
    t.boolean "gift_wrap", default: false
    t.decimal "gift_wrap_cost", precision: 10, scale: 2, default: "0.0"
    t.text "gift_message"
    t.datetime "delivery_window_start"
    t.datetime "delivery_window_end"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customer_surname"
    t.string "shipping_city"
    t.text "shipping_notes"
    t.string "payment_method"
    t.date "delivery_date"
    t.time "delivery_time_start"
    t.time "delivery_time_end"
    t.index ["channel"], name: "index_orders_on_channel"
    t.index ["customer_email"], name: "index_orders_on_customer_email"
    t.index ["customer_phone"], name: "index_orders_on_customer_phone"
    t.index ["delivered_date"], name: "index_orders_on_delivered_date"
    t.index ["order_date"], name: "index_orders_on_order_date"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["shipped_date"], name: "index_orders_on_shipped_date"
    t.index ["short_link_token"], name: "index_orders_on_short_link_token", unique: true
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "packaging_materials", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "sku"
    t.string "category"
    t.string "unit_type", null: false
    t.decimal "unit_cost", precision: 10, scale: 4, null: false
    t.integer "quantity_on_hand", default: 0
    t.integer "reorder_point", default: 0
    t.decimal "weight_per_unit", precision: 8, scale: 3
    t.string "weight_unit", default: "kg"
    t.decimal "length", precision: 8, scale: 3
    t.decimal "width", precision: 8, scale: 3
    t.decimal "height", precision: 8, scale: 3
    t.string "dimension_unit", default: "cm"
    t.string "supplier_name"
    t.string "supplier_sku"
    t.boolean "active", default: true
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_packaging_materials_on_active"
    t.index ["category"], name: "index_packaging_materials_on_category"
    t.index ["name"], name: "index_packaging_materials_on_name"
    t.index ["sku"], name: "index_packaging_materials_on_sku", unique: true
    t.index ["supplier_name"], name: "index_packaging_materials_on_supplier_name"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "payment_method", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", default: "USD"
    t.string "status", default: "pending"
    t.string "reference_number"
    t.string "transaction_id"
    t.text "notes"
    t.datetime "payment_date"
    t.datetime "processed_at"
    t.string "processor"
    t.jsonb "processor_response", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["payment_method"], name: "index_payments_on_payment_method"
    t.index ["processor"], name: "index_payments_on_processor"
    t.index ["reference_number"], name: "index_payments_on_reference_number"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["transaction_id"], name: "index_payments_on_transaction_id"
  end

  create_table "product_variants", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "sku", null: false
    t.string "barcode"
    t.string "name"
    t.decimal "price", precision: 10, scale: 2
    t.decimal "cost_price", precision: 10, scale: 2
    t.decimal "weight", precision: 8, scale: 3
    t.string "weight_unit", default: "kg"
    t.integer "position", default: 1
    t.boolean "active", default: true
    t.boolean "requires_shipping", default: true
    t.boolean "track_inventory", default: true
    t.integer "inventory_quantity", default: 0
    t.string "inventory_policy", default: "deny"
    t.string "fulfillment_service", default: "manual"
    t.decimal "compare_at_price", precision: 10, scale: 2
    t.jsonb "option_values", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_product_variants_on_active"
    t.index ["barcode"], name: "index_product_variants_on_barcode", unique: true
    t.index ["option_values"], name: "index_product_variants_on_option_values", using: :gin
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "category"
    t.string "brand"
    t.decimal "base_price", precision: 10, scale: 2
    t.decimal "cost_price", precision: 10, scale: 2
    t.string "status", default: "active"
    t.boolean "track_inventory", default: true
    t.decimal "weight", precision: 8, scale: 3
    t.string "weight_unit", default: "kg"
    t.decimal "length", precision: 8, scale: 3
    t.decimal "width", precision: 8, scale: 3
    t.decimal "height", precision: 8, scale: 3
    t.string "dimension_unit", default: "cm"
    t.string "tax_category"
    t.jsonb "custom_attributes", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand"], name: "index_products_on_brand"
    t.index ["category"], name: "index_products_on_category"
    t.index ["custom_attributes"], name: "index_products_on_custom_attributes", using: :gin
    t.index ["name"], name: "index_products_on_name"
    t.index ["status"], name: "index_products_on_status"
  end

  create_table "shipments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "tracking_number", null: false
    t.string "carrier_name"
    t.string "carrier_service"
    t.string "status", default: "pending"
    t.decimal "cost", precision: 10, scale: 2
    t.decimal "weight", precision: 8, scale: 3
    t.string "weight_unit", default: "kg"
    t.text "origin_address"
    t.text "destination_address"
    t.datetime "shipped_at"
    t.datetime "delivered_at"
    t.datetime "estimated_delivery"
    t.text "delivery_instructions"
    t.string "proof_of_delivery"
    t.text "notes"
    t.jsonb "tracking_events", default: [], null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrier_name"], name: "index_shipments_on_carrier_name"
    t.index ["delivered_at"], name: "index_shipments_on_delivered_at"
    t.index ["estimated_delivery"], name: "index_shipments_on_estimated_delivery"
    t.index ["order_id"], name: "index_shipments_on_order_id"
    t.index ["shipped_at"], name: "index_shipments_on_shipped_at"
    t.index ["status"], name: "index_shipments_on_status"
    t.index ["tracking_number"], name: "index_shipments_on_tracking_number", unique: true
  end

  create_table "sourcing_order_items", force: :cascade do |t|
    t.bigint "sourcing_order_id", null: false
    t.bigint "product_variant_id", null: false
    t.integer "quantity_ordered", null: false
    t.integer "quantity_received", default: 0
    t.decimal "unit_cost", precision: 10, scale: 4, null: false
    t.decimal "total_cost", precision: 10, scale: 2, null: false
    t.string "status", default: "pending"
    t.date "expected_date"
    t.date "received_date"
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expected_date"], name: "index_sourcing_order_items_on_expected_date"
    t.index ["product_variant_id"], name: "index_sourcing_order_items_on_product_variant_id"
    t.index ["received_date"], name: "index_sourcing_order_items_on_received_date"
    t.index ["sourcing_order_id"], name: "index_sourcing_order_items_on_sourcing_order_id"
    t.index ["status"], name: "index_sourcing_order_items_on_status"
  end

  create_table "sourcing_orders", force: :cascade do |t|
    t.string "po_number", null: false
    t.string "supplier_name", null: false
    t.string "supplier_contact"
    t.string "supplier_email"
    t.string "status", default: "draft"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "shipping_cost", precision: 10, scale: 2, default: "0.0"
    t.decimal "customs_duty", precision: 10, scale: 2, default: "0.0"
    t.decimal "marketplace_fees", precision: 10, scale: 2, default: "0.0"
    t.decimal "handling_fees", precision: 10, scale: 2, default: "0.0"
    t.decimal "other_costs", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_cost", precision: 10, scale: 2, default: "0.0"
    t.string "currency", default: "USD"
    t.date "order_date"
    t.date "expected_delivery_date"
    t.date "actual_delivery_date"
    t.text "terms_and_conditions"
    t.text "notes"
    t.jsonb "cost_breakdown", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actual_delivery_date"], name: "index_sourcing_orders_on_actual_delivery_date"
    t.index ["expected_delivery_date"], name: "index_sourcing_orders_on_expected_delivery_date"
    t.index ["order_date"], name: "index_sourcing_orders_on_order_date"
    t.index ["po_number"], name: "index_sourcing_orders_on_po_number", unique: true
    t.index ["status"], name: "index_sourcing_orders_on_status"
    t.index ["supplier_name"], name: "index_sourcing_orders_on_supplier_name"
  end

  create_table "waha_events", force: :cascade do |t|
    t.string "session_name", comment: "WAHA session name"
    t.string "event_name", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_waha_events_on_created_at"
  end

  create_table "waha_sessions", force: :cascade do |t|
    t.string "name", null: false
    t.string "status", default: "inactive", null: false
    t.datetime "last_qr_generated_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "profile_pic_url"
    t.index ["name"], name: "index_waha_sessions_on_name", unique: true
    t.index ["status"], name: "index_waha_sessions_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "product_variants"
  add_foreign_key "carts", "chats"
  add_foreign_key "chats", "waha_sessions"
  add_foreign_key "inventory_lots", "product_variants"
  add_foreign_key "media_files", "messages"
  add_foreign_key "message_reactions", "messages"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "messages", column: "reply_to_message_id"
  add_foreign_key "order_attributions", "marketing_campaigns"
  add_foreign_key "order_attributions", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants"
  add_foreign_key "payments", "orders"
  add_foreign_key "product_variants", "products"
  add_foreign_key "shipments", "orders"
  add_foreign_key "sourcing_order_items", "product_variants"
  add_foreign_key "sourcing_order_items", "sourcing_orders"
end
