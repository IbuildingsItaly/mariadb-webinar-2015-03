-- Let's create the `test` datavase, if it doesn't already exist,
-- and a site_user table. Examples will be based on that table.

CREATE DATABASE IF NOT EXISTS test
        DEFAULT CHARACTER SET utf8;

USE test;

-- `product` will contain all kinds of products.
-- attributes that are common to all products are regular columns.
-- attributed that are specific to a product type are in the dynamic column.
CREATE OR REPLACE TABLE product
(
        id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
        name CHAR(50) NOT NULL,
        quantity SMALLINT UNSIGNED NOT NULL,
        price DECIMAL(6, 2) NOT NULL,
        characteristics LONGBLOB NOT NULL COMMENT 'Dynamic column',
        description TEXT NOT NULL,
        UNIQUE INDEX unq_name (name),
        INDEX idx_price (price),
        PRIMARY KEY (id)
)
        ENGINE = InnoDB
        DEFAULT CHARACTER SET utf8
;


-- let's insert different types of products:
-- 2 shirts and 1 laptop.

INSERT INTO product SET
        name = 'Red shirt',
        quantity = 30,
        price = '19.90',
        characteristics = COLUMN_CREATE(
                'size', 'XL' AS CHAR,
                'color', 'red' AS CHAR
        ),
        description = 'Red T-shirt';

INSERT INTO product SET
        name = 'Black shirt',
        quantity = 50,
        price = '19.90',
        characteristics = COLUMN_CREATE(
                'size', 'L' AS CHAR,
                'color', 'black' AS CHAR
        ),
        description = 'Black T-shirt';

INSERT INTO product SET
        name = 'XY Laptop',
        quantity = 10,
        price = '650.00',
        characteristics = COLUMN_CREATE(
                'brand', 'XY' AS CHAR,
                'ram', 4 AS INTEGER,
                'storage_type', 'SSD' AS CHAR,
                'storage_size', 500 AS INTEGER
        ),
        description = 'Red T-shirt';


-- but we don't have a column which indicates the product type.
-- this complicates some queries. bad idea.
-- let's add that value.

UPDATE product
        SET characteristics = COLUMN_ADD(characteristics, 'type', 't-shirt' AS CHAR)
        WHERE COLUMN_EXISTS(characteristics, 'size');

UPDATE product
        SET characteristics = COLUMN_ADD(characteristics, 'type', 'laptop' AS CHAR)
        WHERE COLUMN_EXISTS(characteristics, 'ram');

SELECT COLUMN_GET(characteristics, 'type' AS CHAR), COLUMN_LIST(characteristics)
        FROM product
        WHERE COLUMN_GET(characteristics, 'type' AS CHAR) = 't-shirt';


-- queries on the 'type' property cannot use indexes.
-- putting the type value into the dyncol was another bad idea.
-- let's convert it to a regular column.

ALTER TABLE product
        ADD COLUMN type TINYINT UNSIGNED DEFAULT NULL,
        ADD INDEX idx_type (type);

CREATE TABLE product_type
(
        id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
        description CHAR(20),
        PRIMARY KEY (id)
)
        ENGINE = InnoDB
        DEFAULT CHARACTER SET utf8
;

INSERT INTO product_type (id, description) VALUES
        (1, 't-shirt'),
        (2, 'laptop');

UPDATE product SET type = (
        SELECT id FROM product_type
        WHERE description = COLUMN_GET(characteristics, 'type' AS CHAR)
);

UPDATE product SET characteristics = COLUMN_DELETE(characteristics, 'type');

-- let's check if everything's ok...
SELECT p.name, pt.description, COLUMN_JSON(p.characteristics)
        FROM product_type pt
        INNER JOIN product p
                ON pt.id = p.description
        ORDER BY p.type;


-- dynamic columns syntax is quite verbose.
-- we can build VIRTUAL columns to avoid repeating
-- the expressions we will frequently need

ALTER TABLE product
        ADD COLUMN size CHAR (2) AS
                (COLUMN_GET(characteristics, 'size' AS CHAR)) VIRTUAL;
SELECT name, size FROM product;

ALTER TABLE product
        ADD COLUMN storage CHAR(15) AS (
                CONCAT(COLUMN_GET(characteristics, 'storage_size' AS CHAR),
                'GB (', COLUMN_GET(characteristics, 'storage_type' AS CHAR), ')')
        ) VIRTUAL;
SELECT name, storage FROM product;


/*
        A dynamic property cannot be directly indexed.
        Indexing a whole dynamic column (BLOB) is useless.
        So, in order to index a property, we have to:
        * Create a PERSISTENT column on the property we want to index
        * Index the PERSISTENT column
*/

ALTER TABLE product
        ADD COLUMN color CHAR (10) AS (
                COLUMN_GET(characteristics, 'color' AS CHAR)
        ) PERSISTENT,
        ADD INDEX idx_color (color);
SELECT name, color FROM product;




