-- Olist E-Commerce analysis: create database and tables (MySQL 8)
-- Source data: Brazilian E-Commerce Public Dataset by Olist (Kaggle)

CREATE DATABASE IF NOT EXISTS olist_project;
USE olist_project;

-- One row per order. customer_id is generated per order;
-- customer_unique_id identifies the actual person.
CREATE TABLE customers (
    customer_id               VARCHAR(50) PRIMARY KEY,
    customer_unique_id        VARCHAR(50),
    customer_zip_code_prefix  INT,
    customer_city             VARCHAR(100),
    customer_state            CHAR(2)
);

CREATE TABLE orders (
    order_id                       VARCHAR(50) PRIMARY KEY,
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME
);

CREATE TABLE order_items (
    order_id             VARCHAR(50),
    order_item_id        INT,
    product_id           VARCHAR(50),
    seller_id            VARCHAR(50),
    shipping_limit_date  DATETIME,
    price                DECIMAL(10,2),
    freight_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id              VARCHAR(50),
    payment_sequential    INT,
    payment_type          VARCHAR(20),
    payment_installments  INT,
    payment_value         DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- review_id is not unique in the source data, so no primary key
CREATE TABLE order_reviews (
    review_id                VARCHAR(50),
    order_id                 VARCHAR(50),
    review_score             INT,
    review_comment_title     VARCHAR(255),
    review_comment_message   TEXT,
    review_creation_date     DATETIME,
    review_answer_timestamp  DATETIME
);

-- Column names keep the original spelling ("lenght") from the source file
CREATE TABLE products (
    product_id                  VARCHAR(50) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_lenght         INT,
    product_description_lenght  INT,
    product_photos_qty          INT,
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT
);

CREATE TABLE category_translation (
    product_category_name          VARCHAR(100) PRIMARY KEY,
    product_category_name_english  VARCHAR(100)
);
