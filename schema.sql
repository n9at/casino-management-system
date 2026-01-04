CREATE TABLE gra (
    id_gry SERIAL PRIMARY KEY,
    nazwa VARCHAR(50) NOT NULL,
    typ VARCHAR(50) NOT NULL,
    min_stawka DECIMAL(10, 2 ) NOT NULL CHECK (min_stawka >0)
);

CREATE TABLE pracownik (
    id_pracownika SERIAL PRIMARY KEY,
    id_managera INTEGER REFERENCES pracownik(id_pracownika),
    imie VARCHAR(50) NOT NULL,
    nazwisko VARCHAR(50) NOT NULL,
    rola VARCHAR(50) NOT NULL
);

CREATE TABLE stol (
    id_stolu SERIAL PRIMARY KEY,
    id_gry INTEGER REFERENCES gra(id_gry),
    numer_stolu INTEGER NOT NULL UNIQUE,
    CONSTRAINT fk_stol_gra FOREIGN KEY (id_gry) REFERENCES gra(id_gry)
);

CREATE TABLE gosc (
    id_goscia SERIAL PRIMARY KEY,
    imie VARCHAR(50) NOT NULL,
    nazwisko VARCHAR(50) NOT NULL,
    saldo DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (saldo >= 0),
    status_vip CHAR(1) DEFAULT 'N' CHECK (status_vip IN ('Y', 'N'))
);

CREATE TABLE sesja (
    id_sesji SERIAL PRIMARY KEY,
    id_stolu INTEGER NOT NULL,
    id_krupiera INTEGER NOT NULL,
    czas_startu TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    czas_konca TIMESTAMP, -- pole opcjonalne (zgodnie z UML)
    CONSTRAINT fk_sesja_stol FOREIGN KEY (id_stolu) REFERENCES stol(id_stolu),
    CONSTRAINT fk_sesja_krupier FOREIGN KEY (id_krupiera) REFERENCES pracownik(id_pracownika)
);

CREATE TABLE transakcja (
    id_transakcji SERIAL PRIMARY KEY,
    id_sesji INTEGER NOT NULL,
    id_goscia INTEGER NOT NULL,
    kwota DECIMAL(10, 2) NOT NULL CHECK (kwota > 0),
    typ_transakcji VARCHAR(20) NOT NULL CHECK (typ_transakcji IN ('ZAKLAD', 'WYGRANA')),
    CONSTRAINT fk_transakcja_sesja FOREIGN KEY (id_sesji) REFERENCES sesja(id_sesji),
    CONSTRAINT fk_transakcja_gosc FOREIGN KEY (id_goscia) REFERENCES gosc(id_goscia)
);