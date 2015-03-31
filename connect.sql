-- Let's create the `test` datavase, if it doesn't already exist,
-- and a site_user table. Examples will be based on that table.

CREATE DATABASE IF NOT EXISTS test
        DEFAULT CHARACTER SET utf8;

USE test;


-- open data by Ministero Economia e Sviluppo.
-- file downloaded from http://www.sviluppoeconomico.gov.it/index.php/it/open-data/elenco-dataset/2032336-carburanti-prezzi-praticati-e-anagrafica-degli-impianti
-- copy that file into MariaDB data directory (@@datadir)
CREATE OR REPLACE TABLE prezzo_carburanti
(
        id_impianto INTEGER UNSIGNED NOT NULL,
        desc_carburante CHAR(50) NOT NULL,
        prezzo DECIMAL(5, 3) NOT NULL,
        is_self_service BOOLEAN NOT NULL,
        data DATETIME NOT NULL,
        INDEX idx_carburante (desc_carburante)
)
        ENGINE = CONNECT
        TABLE_TYPE = 'CSV'
        FILE_NAME = '/var/mariadbwebinar/prezzo_alle_8.csv'
        HEADER = 1
        SEP_CHAR = ';'
        QUOTED = 0
        COMMENT 'Prezzo carburanti alle 8 di mattina'
;


-- SQL allows to aggregate calculations by desc_carburante...
SELECT carburante, AVG(prezzo) AS avg, STDDEV(prezzo) AS standard_deviation
        FROM prezzo_carburanti
        GROUP BY desc_carburante;


-- ...but no SQL statement allows to turn values (desc_carburante) to columns,
-- because that is not a valid relational operation.
-- however, with CONNECT, we can build a pivot table: fuel types become columns
CREATE OR REPLACE TABLE prezzo_carburanti_pivot
        ENGINE = CONNECT
        TABLE_TYPE = 'PIVOT'
        TABNAME = 'prezzo_carburanti'
        OPTION_LIST = 'PivotCol=desc_carburante,FncCol=prezzo,Function=AVG,Accept=0';


-- to turn our CONNECT table to an InnoDB table:
ALTER TABLE prezzo_carburanti ENGINE = InnoDB;

