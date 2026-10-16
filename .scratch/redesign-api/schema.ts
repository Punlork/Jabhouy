// Draft for jabhouy-api #3 (Step 1 · Schema and backup).
// Replaces category/customer/item/loan in src/db/schema.ts; Better Auth tables stay as they are.
import { sql } from "drizzle-orm";
import {
  index,
  integer,
  primaryKey,
  sqliteTable,
  text,
} from "drizzle-orm/sqlite-core";

import { user } from "./schema";

const currency = () => text("currency", { enum: ["KHR", "USD"] }).notNull();

// Pulls read `WHERE shop_id = ? AND seq > ? ORDER BY seq` per table; the (shop_id, seq) indexes serve them.
// Every synced row: which Shop, its place in that Shop's change order, and who changed it last.
// The server sets these; request bodies never do.
const synced = () => ({
  shopId: text("shop_id")
    .notNull()
    .references(() => shop.id, { onDelete: "cascade" }),
  seq: integer("seq").notNull(),
  updatedAt: integer("updated_at", { mode: "timestamp_ms" }).notNull(),
  updatedBy: text("updated_by").references(() => user.id),
  deletedAt: integer("deleted_at", { mode: "timestamp_ms" }),
});

export const shop = sqliteTable("shop", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  ownerId: text("owner_id")
    .notNull()
    .references(() => user.id),
  // Last seq handed out in this Shop. Each write does `UPDATE shop SET seq = seq + 1 ... RETURNING seq`
  // in the same D1 batch as the row it stamps.
  seq: integer("seq").notNull().default(0),
  createdAt: integer("created_at", { mode: "timestamp_ms" })
    .notNull()
    .default(sql`(unixepoch() * 1000)`),
});

export const member = sqliteTable(
  "member",
  {
    ...synced(),
    userId: text("user_id")
      .notNull()
      .references(() => user.id, { onDelete: "cascade" }),
    role: text("role", { enum: ["owner", "editor", "viewer"] }).notNull(),
    joinedAt: integer("joined_at", { mode: "timestamp_ms" }).notNull(),
  },
  (t) => [primaryKey({ columns: [t.shopId, t.userId] }), index("member_user_idx").on(t.userId)],
);

export const shopSettings = sqliteTable("shop_settings", {
  ...synced(),
  shopId: text("shop_id")
    .primaryKey()
    .references(() => shop.id, { onDelete: "cascade" }),
  useWholesalePrice: integer("use_wholesale_price", { mode: "boolean" }).notNull().default(false),
  useCostPrice: integer("use_cost_price", { mode: "boolean" }).notNull().default(true),
  defaultCurrency: text("default_currency", { enum: ["KHR", "USD"] }).notNull().default("KHR"),
  khrPerUsd: integer("khr_per_usd").notNull().default(4000),
  showConverted: integer("show_converted", { mode: "boolean" }).notNull().default(true),
  rateUpdatedAt: integer("rate_updated_at", { mode: "timestamp_ms" }),
  rateUpdatedBy: text("rate_updated_by").references(() => user.id),
});

export const category = sqliteTable(
  "category",
  {
    id: text("id").primaryKey(),
    ...synced(),
    name: text("name").notNull(),
    sortOrder: integer("sort_order").notNull().default(0),
    hidden: integer("hidden", { mode: "boolean" }).notNull().default(false),
  },
  (t) => [index("category_shop_seq_idx").on(t.shopId, t.seq)],
);

// Child of category; travels inside it. Adding a unit (from a category or an item PUT)
// must also bump the category's seq so other phones pull it.
export const categoryUnit = sqliteTable(
  "category_unit",
  {
    categoryId: text("category_id")
      .notNull()
      .references(() => category.id, { onDelete: "cascade" }),
    unit: text("unit").notNull(),
    hidden: integer("hidden", { mode: "boolean" }).notNull().default(false),
  },
  (t) => [primaryKey({ columns: [t.categoryId, t.unit] })],
);

export const item = sqliteTable(
  "item",
  {
    id: text("id").primaryKey(),
    ...synced(),
    name: text("name").notNull(),
    categoryId: text("category_id").references(() => category.id),
    photoUrl: text("photo_url"),
    note: text("note"),
  },
  (t) => [index("item_shop_seq_idx").on(t.shopId, t.seq)],
);

// Child of item; the item PUT replaces the whole set.
export const itemPrice = sqliteTable(
  "item_price",
  {
    id: text("id").primaryKey(),
    itemId: text("item_id")
      .notNull()
      .references(() => item.id, { onDelete: "cascade" }),
    unit: text("unit").notNull(),
    packQty: integer("pack_qty"),
    currency: currency(),
    // Whole riel or cents. Null = no price yet, never 0.
    price: integer("price"),
    wholesale: integer("wholesale"),
    cost: integer("cost"),
    sortOrder: integer("sort_order").notNull().default(0),
  },
  (t) => [index("item_price_item_idx").on(t.itemId)],
);

export const customer = sqliteTable(
  "customer",
  {
    id: text("id").primaryKey(),
    ...synced(),
    name: text("name").notNull(),
    phone: text("phone"),
    note: text("note"),
  },
  (t) => [index("customer_shop_seq_idx").on(t.shopId, t.seq)],
);

export const credit = sqliteTable(
  "credit",
  {
    id: text("id").primaryKey(),
    ...synced(),
    customerId: text("customer_id")
      .notNull()
      .references(() => customer.id),
    currency: currency(),
    amount: integer("amount"), // null = no amount yet
    khrPerUsd: integer("khr_per_usd").notNull(), // rate when the credit was made
    status: text("status", { enum: ["unpaid", "paid"] }).notNull(),
    takenAt: integer("taken_at", { mode: "timestamp_ms" }).notNull(),
    dueDate: text("due_date"), // YYYY-MM-DD
    paidAt: integer("paid_at", { mode: "timestamp_ms" }),
    note: text("note"),
  },
  (t) => [
    index("credit_shop_seq_idx").on(t.shopId, t.seq),
    index("credit_customer_idx").on(t.customerId),
  ],
);

// Child of credit; the credit PUT replaces the whole set. A copy taken at the time.
export const creditItem = sqliteTable(
  "credit_item",
  {
    id: text("id").primaryKey(),
    creditId: text("credit_id")
      .notNull()
      .references(() => credit.id, { onDelete: "cascade" }),
    priceId: text("price_id"), // may point to a deleted item_price; no FK on purpose
    name: text("name").notNull(),
    unit: text("unit").notNull(),
    qty: integer("qty").notNull(),
    currency: currency(),
    unitPrice: integer("unit_price").notNull(),
    total: integer("total").notNull(),
  },
  (t) => [index("credit_item_credit_idx").on(t.creditId)],
);
