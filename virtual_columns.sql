-- Let's create the `test` datavase, if it doesn't already exist,
-- and a site_user table. Examples will be based on that table.

CREATE DATABASE IF NOT EXISTS test
        DEFAULT CHARACTER SET utf8;

USE test;

-- OR REPLACE is a MariaDB syntax, which increases usability and
-- makes replication more robust.
CREATE OR REPLACE TABLE site_user
(
        id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
        email CHAR(200) NOT NULL,
        first_name CHAR(50) NOT NULL,
        last_name CHAR(50) NOT NULL,
        birth_date DATETIME NOT NULL,
        PRIMARY KEY (id)
)
        ENGINE = InnoDB
        DEFAULT CHARACTER SET utf8
;


-- sometimes we want to extract users fullname or birth year,
-- but we don't want to repeat the SQL expressions every time
ALTER TABLE site_user
        ADD COLUMN full_name CHAR(100)
                AS (CONCAT(first_name, ' ', last_name)) VIRTUAL;
ALTER TABLE site_user
        ADD COLUMN birth_year TINYINT UNSIGNED
                AS (YEAR(birth_date)) VIRTUAL;


-- users may not know how a last name is writte. for example:
-- dell'uomo or delluomo? digiovanni or di giovanni?
-- remove apostrophs and spaces and search normalized_name
ALTER TABLE site_user
        ADD COLUMN normalized_last_name CHAR(50) AS (
                REPLACE(REPLACE(last_name, ' ', ''), '''', '')
                ) PERSISTENT,
        ADD INDEX idx_normalized_last_name (normalized_last_name);

INSERT INTO site_user (email, first_name, last_name, birth_date)
        VALUES ('pico@paperopoli.it', 'Pico', 'de Paperis', DATE '1950-12-01');
SELECT * FROM site_user WHERE normalized_last_name LIKE 'depaperis';


-- make sure that email@email.com is recognized as a duplicate of EMAIL@EMAIL.COM
-- and thus rejected
ALTER TABLE site_user
        ADD COLUMN normalized_email CHAR (200) AS (LOWER(email)) PERSISTENT,
        ADD UNIQUE unq_normalized_email (normalized_email);

-- should return a duplicate key error (1062)
INSERT INTO site_user (email, first_name, last_name, birth_date)
        VALUES ('PICO@paperopoli.it', 'Pico', 'de Paperis', DATE '1950-12-01');


