CREATE TABLE gra (
    id_gry SERIAL PRIMARY KEY,
    nazwa VARCHAR(50) NOT NULL,
    typ VARCHAR(50) NOT NULL,
    min_stawka DECIMAL(10, 2) NOT NULL CHECK (min_stawka > 0)
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
    numer_stolu INTEGER NOT NULL UNIQUE
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
    id_stolu INTEGER NOT NULL REFERENCES stol(id_stolu),
    id_krupiera INTEGER NOT NULL REFERENCES pracownik(id_pracownika),
    czas_startu TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    czas_konca TIMESTAMP
);

CREATE TABLE transakcja (
    id_transakcji SERIAL PRIMARY KEY,
    id_sesji INTEGER NOT NULL REFERENCES sesja(id_sesji),
    id_goscia INTEGER NOT NULL REFERENCES gosc(id_goscia),
    kwota DECIMAL(10, 2) NOT NULL CHECK (kwota > 0),
    typ_transakcji VARCHAR(20) NOT NULL CHECK (typ_transakcji IN ('ZAKLAD', 'WYGRANA'))
);

CREATE OR REPLACE PROCEDURE RealizujZaklad(
    p_id_gosc INTEGER,
    p_id_sesja INTEGER,
    p_kwota DECIMAL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo DECIMAL;
    v_czy_otwarta INTEGER;
BEGIN

    SELECT COUNT(*) INTO v_czy_otwarta FROM sesja 
    WHERE id_sesji = p_id_sesja AND czas_konca IS NULL;
    
    IF v_czy_otwarta = 0 THEN
        RAISE EXCEPTION 'Nie mozna postawic zakladu w zamknietej sesji.';
    END IF;

    SELECT saldo INTO v_saldo FROM gosc WHERE id_goscia = p_id_gosc FOR UPDATE;
    
    IF v_saldo < p_kwota THEN
        RAISE EXCEPTION 'Niewystarczajace srodki na koncie gracza.';
    END IF;

    INSERT INTO transakcja (id_sesji, id_goscia, kwota, typ_transakcji)
    VALUES (p_id_sesja, p_id_gosc, p_kwota, 'ZAKLAD');

    UPDATE gosc SET saldo = saldo - p_kwota WHERE id_goscia = p_id_gosc;
END;
$$;

CREATE OR REPLACE FUNCTION func_aktualizuj_vip()
RETURNS TRIGGER AS $$
DECLARE
    v_suma_zakladow DECIMAL;
BEGIN
    SELECT SUM(kwota) INTO v_suma_zakladow 
    FROM transakcja 
    WHERE id_goscia = NEW.id_goscia AND typ_transakcji = 'ZAKLAD';

    IF v_suma_zakladow >= 5000 THEN
        UPDATE gosc SET status_vip = 'Y' WHERE id_goscia = NEW.id_goscia;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Aktualizuj_VIP
AFTER INSERT ON transakcja
FOR EACH ROW
WHEN (NEW.typ_transakcji = 'ZAKLAD')
EXECUTE FUNCTION func_aktualizuj_vip();