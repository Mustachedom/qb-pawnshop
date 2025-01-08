CREATE TABLE smelting (
    citizenid VARCHAR(255) NOT NULL,
    item VARCHAR(255) NOT NULL,
    time text DEFAULT NOT NULL,
    PRIMARY KEY (citizenid),
    CONSTRAINT fk_smelting_citizenid
        FOREIGN KEY (citizenid) REFERENCES players (citizenid)
        ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;