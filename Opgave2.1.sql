-- Ændr kolonnenavn i cars-tabellen for konsistens
#ALTER TABLE cars RENAME COLUMN `Sys.time..` TO scrape_time;

-- Opret tabel: car_details (invariante oplysninger om biler)
CREATE TABLE car_details (
    carid INT PRIMARY KEY,                -- Unik bil-ID
    model VARCHAR(255),                   -- Bilmodel
    description TEXT,                     -- Beskrivelse
    specifikmodel VARCHAR(255),           -- Specifik model
    link VARCHAR(255),                    -- Link til bilen
    registrering VARCHAR(255),            -- Registreringsinformation
    kilometertal VARCHAR(255),            -- Kilometer kørt
    rækkevidde VARCHAR(255),              -- Rækkevidde (fx elbiler)
    brændstof VARCHAR(255)                -- Brændstoftype
);

-- Indsæt data i car_details fra cars
INSERT INTO car_details (carid, model, description, specifikmodel, link, registrering, kilometertal, rækkevidde, brændstof)
SELECT DISTINCT carid, model, description, specificmodel, link, registrering, kilometertal, rækkevidde, brændstof
FROM cars;

-- Opret tabel: dealer_details (invariante oplysninger om forhandlere)
CREATE TABLE dealer_details (
    forhandlerid VARCHAR(255) PRIMARY KEY, -- Unik forhandler-ID
    city TEXT,                             -- By
    region VARCHAR(255)                    -- Region
);

-- Indsæt data i dealer_details fra cars
INSERT INTO dealer_details (forhandlerid, city, region)
SELECT DISTINCT forhandlerid, cars.by AS city, region
FROM cars
WHERE forhandlerid IS NOT NULL;

-- Ændr carid i cars for at sikre NOT NULL for fremmednøgler
ALTER TABLE cars
MODIFY COLUMN carid INT NOT NULL;

-- Opret tabel: sales_details (tidsserie-data: Prisændringer og salg)
CREATE TABLE sales_details (
    prisid INT AUTO_INCREMENT PRIMARY KEY, -- Auto-incrementing ID
    carid INT NOT NULL,                    -- Link til car_details
    pris INT,                              -- Pris på bilen
    model TEXT,                            -- Bilmodel
    specifikmodel VARCHAR(255),            -- Specifik model
    link VARCHAR(255),                     -- Link til bilen
    registrering VARCHAR(255),             -- Registreringsinformation
    For_sale VARCHAR(255),                 -- Status for salg
    forhandlerid VARCHAR(255),             -- Link til dealer_details
    scrape_time DATETIME,                  -- Tidspunkt for scraping
    CONSTRAINT fk_carid FOREIGN KEY (carid) REFERENCES car_details(carid),
    CONSTRAINT fk_forhandlerid FOREIGN KEY (forhandlerid) REFERENCES dealer_details(forhandlerid)
);

-- Indsæt data i sales_details fra cars
INSERT INTO sales_details (carid, pris, model, specifikmodel, link, registrering, For_sale, forhandlerid, scrape_time)
SELECT carid, pris, model, specificmodel, link, registrering, 'For Sale', forhandlerid, scrape_time
FROM cars;

-- Valider dataindsættelse
SELECT * FROM car_details;
SELECT * FROM dealer_details;
SELECT * FROM sales_details;

ALTER TABLE sales_details
ADD COLUMN sold BOOLEAN DEFAULT FALSE;

DELETE from DKbil where pris like '%(%';

-- lololololololololololplol
-- 1. Opdater "sold" kolonnen i `sales_details` for biler, der ikke længere er til salg
UPDATE sales_details
SET sold = TRUE
WHERE carid NOT IN (
    SELECT carid
    FROM DKbil
);

-- 2. Indsæt nye biler i `car_details`, hvis de ikke allerede eksisterer
INSERT INTO car_details (carid, model, description, specificmodel, link, registrering, kilometertal, rækkevidde, brændstof)
SELECT DISTINCT d.carid, d.model, d.description, d.specificmodel, d.link, d.registrering, d.kilometertal, d.rækkevidde, d.brændstof
FROM DKbil d
WHERE d.carid NOT IN (
    SELECT carid
    FROM car_details
);

-- 3. Indsæt nye forhandlere i `dealer_details`, hvis de ikke allerede eksisterer
INSERT INTO dealer_details (forhandlerid, city, region)
SELECT DISTINCT d.forhandlerid, d.by AS city, d.region
FROM DKbil d
WHERE d.forhandlerid NOT IN (
    SELECT forhandlerid
    FROM dealer_details
);

-- 4. Indsæt nye prisændringer i `sales_details` for biler med en ny pris
INSERT INTO sales_details (carid, pris, model, specificmodel, link, registrering, For_sale, forhandlerid, scrape_time, sold)
SELECT d.carid, CAST(d.pris AS UNSIGNED), d.model, d.specificmodel, d.link, d.registrering, 'For Sale', d.forhandlerid, d.scrape_time, FALSE
FROM DKbil d
WHERE d.carid IN (
    SELECT carid
    FROM sales_details
)
AND d.pris NOT IN (
    SELECT pris
    FROM sales_details
    WHERE carid = d.carid
);

-- 5. Indsæt nye biler i `sales_details`, hvis de ikke allerede eksisterer
INSERT INTO sales_details (carid, pris, model, specificmodel, link, registrering, For_sale, forhandlerid, scrape_time, sold)
SELECT d.carid, CAST(d.pris AS UNSIGNED), d.model, d.specificmodel, d.link, d.registrering, 'For Sale', d.forhandlerid, d.scrape_time, FALSE
FROM DKbil d
WHERE d.carid NOT IN (
    SELECT carid
    FROM sales_details
);

-- Valider data
SELECT * FROM car_details;
SELECT * FROM dealer_details;
SELECT * FROM sales_details;
