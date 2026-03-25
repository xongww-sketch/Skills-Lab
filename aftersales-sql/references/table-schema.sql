CREATE TABLE "public"."activation_records" (
  "id" int4 NOT NULL DEFAULT nextval('"ActivationRecords_ID_seq"'::regclass),
  "activatetime" int8,
  "city" text COLLATE "pg_catalog"."default",
  "country_code" text COLLATE "pg_catalog"."default",
  "email" text COLLATE "pg_catalog"."default",
  "expirestime" date,
  "firmware_type" text COLLATE "pg_catalog"."default",
  "ip_address" text COLLATE "pg_catalog"."default",
  "remain_warranty_days" numeric,
  "user_id" text COLLATE "pg_catalog"."default",
  "deactivestatus" text COLLATE "pg_catalog"."default",
  "retroid" varchar COLLATE "pg_catalog"."default",
  "uuid" varchar COLLATE "pg_catalog"."default",
  CONSTRAINT "ActivationRecords_pkey" PRIMARY KEY ("id")
);

-- deactivestatus: '1' 为已删除激活记录
-- 索引: activatetime, country_code, firmware_type, retroid
