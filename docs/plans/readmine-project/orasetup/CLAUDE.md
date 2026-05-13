# Oracle PL/SQL Dev – Claude Code Instructions

Tento projekt používá Oracle PL/SQL s utPLSQL testy. Níže jsou pokyny jak pracovat s kódem.

## Prostředí

- DB připojení: vždy z `.env` – **neměnit `flyway.conf`**
- Aktuálně: Oracle XE 21c v Dockeru (`oracle-xe`), port 1521, PDB: `DEVPDB`
- Dev uživatel: `PORTAL` / heslo: viz `.env`
- Přepnutí na jinou DB = změna `DB_DSN` a `DB_URL` v `.env`, nic jiného
- `sudo` je vyžadováno pro `docker` příkazy
- Kompilace: **SQLcl** (`sqlcl` v PATH)
- Migrace: **Flyway 9.22.3** (`flyway` v PATH) – **ne Flyway 10+!**

## Soubory

- `.pks` = package specification (header)
- `.pkb` = package body (implementace)
- Vždy kompiluj spec před body

## Kompilace

```bash
# Jeden package
bash db/scripts/compile.sh <jmeno_package>
# Příklad: bash db/scripts/compile.sh contacts_pkg

# Všechny packages
bash db/scripts/compile_all.sh

# Zkontrolovat chyby
bash db/scripts/check_errors.sh
```

## Deploy (migrace + kompilace + validace)

```bash
cd test-app && bash db/scripts/deploy.sh
```

Kroky:
1. Flyway migrace (DDL změny)
2. Kompilace packages
3. Kompilace testovacích packages
4. Kontrola INVALID objektů

## Testy

```bash
# Spustit všechny testy aplikace
bash test-app/db/scripts/test.sh

# Spustit konkrétní package
source .env
echo "EXEC ut.run('ut_contacts_pkg');" | sqlcl -S "${DB_USER}/${DB_PASS}@${DB_DSN}"
```

## SQLcl interaktivně

```bash
bash db/scripts/sqlcl.sh
```

## Konvence kódu

- Package spec (`.pks`) – veřejné rozhraní + výjimky jako konstanty
- Package body (`.pkb`) – implementace
- Výjimky: `e_<nazev> EXCEPTION; PRAGMA EXCEPTION_INIT(e_<nazev>, -200XX);`
- Audit log: INSERT/UPDATE triggery zapsat do `audit_log` tabulky
- Každý package musí mít odpovídající test package `ut_<jmeno>.pks/.pkb`
- Test package anotace: `-- %suite(Název)`, `-- %suitepath(test_app)`, `-- %rollback(manual)`
- Setup procedura (beforeeach): DELETE audit_log, DELETE tasks, DELETE contacts, COMMIT

## Flyway migrace

- Soubory: `db/migrations/V{číslo}__{popis}.sql`
- Konfigurace: `flyway.conf` v adresáři aplikace
- `flyway.baselineVersion=0` je nutné (jinak Flyway přeskočí V1)

## Struktura test-app

```
test-app/
  db/
    migrations/   ← DDL (Flyway)
    packages/     ← produkční kód (.pks + .pkb)
    tests/        ← utPLSQL testy (ut_*.pks + ut_*.pkb)
    scripts/
      deploy.sh   ← plný deploy
      test.sh     ← spustí testy
```

## Časté chyby

| Chyba | Příčina | Řešení |
|-------|---------|--------|
| ORA-00942 | Tabulky neexistují | Spustit Flyway migrace (`deploy.sh`) |
| ORA-00904 UT3.xxx | Chybí grant na utPLSQL typy | Viz SETUP.md sekce utPLSQL |
| ORA-44001 invalid schema | `ut.run('test_app')` bez `:` | Použít `ut.run(':test_app')` |
| "Teams upgrade required" | Flyway 10+ | Používat Flyway 9.22.3 |
| Package INVALID | Chyba v kódu | `bash db/scripts/check_errors.sh` |
