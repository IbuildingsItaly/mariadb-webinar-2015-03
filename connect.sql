-- Let's create the `test` datavase, if it doesn't already exist,
-- and a site_user table. Examples will be based on that table.

CREATE DATABASE IF NOT EXISTS test
        DEFAULT CHARACTER SET utf8;

USE test;


-- file downloaded from http://www.sviluppoeconomico.gov.it/index.php/it/open-data/elenco-dataset/2032336-carburanti-prezzi-praticati-e-anagrafica-degli-impianti
CREATE OR REPLACE TABLE prezzo_carburanti
(
        id_impianto INTEGER UNSIGNED NOT NULL,
        desc_carburante CHAR(50) NOT NULL,
        prezzo DECIMAL(5, 3) NOT NULL,
        is_self_service BOOLEAN NOT NULL,
        data DATETIME NOT NULL
)
        ENGINE = CONNECT
        TABLE_TYPE = 'CSV'
        FILE_NAME = '/home/federico/MARIADB_WEBINAR/mariadb-webinar-2015-03/prezzo_alle_8.csv'
        HEADER = 2
        SEP_CHAR = ';'
        QUOTED = 0
        COMMENT 'Prezzo carburanti alle 8 di mattina'
;


CREATE OR REPLACE TABLE prezzo_carburanti_pivot
        ENGINE = CONNECT
        TABLE_TYPE = 'PIVOT'
        TABNAME = 'prezzo_carburanti'
        OPTION_LIST = 'PivotCol=desc_carburante,FncCol=prezzo,Function=AVG,Accept=0';


