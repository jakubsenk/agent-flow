# Oracle PL/SQL Development Stack – Setup Guide

Tato dokumentace popisuje kompletní vývojový stack pro Oracle PL/SQL vývoj s Claude Code.
Dokumentace byla ověřena na Ubuntu 24.04 v prostředí VMware Workstation.

Stav k: 2026-04-09 (aktualizováno) | Verze nástrojů v sekci [Nainstalované verze](#nainstalované-verze)

---

## Obsah

1. [Přehled stacku](#přehled-stacku)
2. [Prerekvizity](#prerekvizity)
3. [Instalace nástrojů](#instalace-nástrojů)
   - [Java 21 (OpenJDK)](#java-21-openjdk)
   - [Docker](#docker)
   - [SQLcl](#sqlcl)
   - [Flyway 9](#flyway-9)
   - [DBeaver](#dbeaver)
4. [Oracle XE v Dockeru](#oracle-xe-v-dockeru)
   - [Spuštění kontejneru](#spuštění-kontejneru)
   - [Vytvoření vývojového uživatele](#vytvoření-vývojového-uživatele)
5. [Instalace utPLSQL](#instalace-utplsql)
6. [Konfigurace připojení k DB](#konfigurace-připojení-k-db)
7. [Oracle APEX (volitelné)](#oracle-apex-volitelné)
8. [Struktura projektu](#struktura-projektu)
9. [Vývojový workflow s Claude Code](#vývojový-workflow-s-claude-code)
10. [Testovací aplikace](#testovací-aplikace)
11. [Nainstalované verze](#nainstalované-verze)
12. [Řešení problémů](#řešení-problémů)

---

## Přehled stacku

```
┌─────────────────────────────────────────────────┐
│              Claude Code (AI IDE)                │
│  .pks/.pkb soubory → SQLcl → Oracle XE Docker   │
└────────────────┬────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
┌───▼───┐              ┌──────▼──────┐
│ SQLcl │              │   Flyway 9  │
│ 26.1  │              │   9.22.3    │
└───┬───┘              └──────┬──────┘
    │                         │
    └────────────┬────────────┘
                 │  JDBC / TCP 1521
    ┌────────────▼────────────┐
    │  Oracle XE 21c (Docker)  │
    │  gvenzl/oracle-xe:21     │
    │  Container: oracle-xe    │
    │  PDB: DEVPDB             │
    │  Dev user: PORTAL        │
    │  Test FW: utPLSQL 3.1.14 │
    └─────────────────────────┘
```

**Klíčové komponenty:**
- **SQLcl 26.1** – Oracle CLI (Java), náhrada za SQL*Plus, přímý run `.sql` souborů
- **Flyway 9.22.3** – správa DB migrací (DDL verze). Verze 9.x = poslední s Oracle Community support
- **gvenzl/oracle-xe:21** – Oracle XE 21c Docker image (plný, bez nutnosti Oracle účtu)
- **utPLSQL 3.1.14** – unit testing framework pro PL/SQL
- **DBeaver 26.0** – GUI DB browser (schema explorer, data editor, ER diagram)

---

## Prerekvizity

```bash
# Ověřit dostupné místo (doporučeno min. 15 GB volné)
df -h /

# Systémové balíčky
sudo apt update
sudo apt install -y curl wget unzip
```

---

## Instalace nástrojů

### Java 21 (OpenJDK)

SQLcl a Flyway vyžadují Java 11+. Doporučena Java 21 LTS.

```bash
sudo apt install -y openjdk-21-jdk
java -version
# openjdk version "21.0.x"
```

### Docker

```bash
# Instalace Docker Engine (oficiální postup)
curl -fsSL https://get.docker.com | sudo sh

# Přidat aktuálního uživatele do skupiny docker (volitelné, viz poznámku)
sudo usermod -aG docker $USER
# Nutné odhlásit se a přihlásit, nebo spustit: newgrp docker

# Ověření
sudo docker --version
# Docker version 29.x.x
```

> **Poznámka:** Na tomto stroji byl `docker` ponechán se `sudo`. Pokud vaše skripty volají `docker` bez `sudo`, přidejte uživatele do skupiny docker a restartujte session.

### SQLcl

SQLcl je Java-based CLI pro Oracle, kompatibilní s SQL*Plus syntaxí + navíc JSON, Liquibase, atd.

```bash
# Stáhnout z Oracle Technology Network (nevyžaduje přihlášení)
cd /tmp
wget https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip
sudo unzip sqlcl-latest.zip -d /opt/

# Opravit práva
sudo chmod -R a+rX /opt/sqlcl/

# Symlink pro PATH
sudo ln -s /opt/sqlcl/bin/sql /usr/local/bin/sqlcl

# Ověření
sqlcl -V
# SQLcl: Release 26.1.0.0 Production
```

> **Důležité:** SQLcl startup skript hledá `$SQL_HOME/../lib/modules/ojdbc11.jar`.
> Pokud tento adresář chybí, je nutné ho vytvořit a naplnit symlinky:
> ```bash
> sudo mkdir -p /opt/sqlcl/lib/modules
> for jar in /opt/sqlcl/lib/*.jar; do
>   sudo ln -sf "$jar" "/opt/sqlcl/lib/modules/$(basename $jar)"
> done
> ```

### Flyway 9

> **Kritická poznámka:** Flyway 10+ přesunul Oracle support do placené Teams/Enterprise edice.
> Flyway 9.22.3 je poslední verze s Oracle Community (free) support.

```bash
cd /tmp
wget https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/9.22.3/flyway-commandline-9.22.3-linux-x64.tar.gz

sudo tar -xzf flyway-commandline-9.22.3-linux-x64.tar.gz -C /opt/
sudo chmod +x /opt/flyway-9.22.3/flyway
sudo ln -sf /opt/flyway-9.22.3/flyway /usr/local/bin/flyway

# Ověření
flyway -v
# Flyway Community Edition 9.22.3
```

### DBeaver

DBeaver Community je GUI DB browser – zobrazuje schema, tabulky, data, ER diagramy.

```bash
sudo snap install dbeaver-ce --classic
# Spuštění:
dbeaver-ce &
```

**Připojení k Oracle XE:**
1. New Connection → Oracle
2. DBeaver stáhne JDBC driver automaticky
3. Vyplnit: Host=`localhost`, Port=`1521`, Database=`DEVPDB`, Connection type=**Service name**
4. Username=`portal`, Password=`portal123`
5. Test Connection → Finish

---

## Oracle XE v Dockeru

### Spuštění kontejneru

[gvenzl/oracle-xe](https://github.com/gvenzl/oci-oracle-xe) je community Oracle XE image – **nevyžaduje Oracle účet**.

> **Image varianty:**
> - `gvenzl/oracle-xe:21` – plný image (~8 GB), obsahuje `orapki` a další nástroje. **Doporučeno.**
> - `gvenzl/oracle-xe:21-slim` – odlehčený (~4 GB), chybí `orapki`. EM Express nefunguje.

```bash
sudo docker run -d \
  --name oracle-xe \
  --restart unless-stopped \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PASSWORD=DevPass123 \
  -e ORACLE_DATABASE=DEVPDB \
  -v oracle-xe-data:/opt/oracle/oradata \
  gvenzl/oracle-xe:21

# První spuštění trvá 3-5 minut (inicializace databáze)
# Sledovat log:
sudo docker logs -f oracle-xe
# Čekat na: "DATABASE IS READY TO USE!"
```

**Parametry:**
- `ORACLE_PASSWORD` – heslo pro uživatele SYS a SYSTEM
- `ORACLE_DATABASE=DEVPDB` – vytvoří PDB s tímto názvem (místo výchozího XEPDB1)
- Volume `oracle-xe-data` – perzistentní data přes restarty kontejneru
- Port 1521 – Oracle listener
- Port 5500 – Oracle EM Express (základní webový DB admin)

### Vytvoření vývojového uživatele

Každá aplikace dostane vlastního uživatele v PDB. Uživatel `PORTAL` je pro tento projekt:

```bash
sudo docker exec oracle-xe sqlplus -S sys/DevPass123@//localhost:1521/DEVPDB AS sysdba << 'EOF'
CREATE USER portal IDENTIFIED BY portal123
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

GRANT CONNECT, RESOURCE TO portal;
GRANT CREATE VIEW, CREATE SYNONYM, CREATE TRIGGER TO portal;
GRANT CREATE ANY DIRECTORY TO portal;
GRANT SELECT ANY DICTIONARY TO portal;
EOF
```

### .env soubor

```bash
# .env (nepřidávat do git!)
DB_USER=portal
DB_PASS=portal123
DB_DSN=localhost:1521/DEVPDB
DB_URL=jdbc:oracle:thin:@//localhost:1521/DEVPDB
SYS_PASS=DevPass123
```

---

## Instalace utPLSQL

utPLSQL 3.1.14 je unit testing framework pro PL/SQL (analogie k JUnit/pytest).

```bash
# Stáhnout release
cd /tmp
wget https://github.com/utPLSQL/utPLSQL/releases/download/v3.1.14/utPLSQL.zip
unzip utPLSQL.zip

# Instalace do DB (jako sysdba)
sudo docker exec oracle-xe bash -c "
  mkdir -p /tmp/utplsql
" 
sudo docker cp /tmp/utPLSQL/source/. oracle-xe:/tmp/utplsql/

# Krok 1: Vytvořit UT3 uživatele s potřebnými oprávněními
sudo docker exec oracle-xe bash -c "sqlplus -S sys/DevPass123@//localhost:1521/DEVPDB AS sysdba << 'EOF'
CREATE USER ut3 IDENTIFIED BY ut3pass
    DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION TO ut3;
GRANT CREATE PROCEDURE, CREATE TYPE, CREATE TABLE, CREATE SEQUENCE TO ut3;
GRANT CREATE VIEW, CREATE SYNONYM, CREATE TRIGGER TO ut3;
GRANT ALTER SESSION, ADMINISTER DATABASE TRIGGER TO ut3;
GRANT SELECT ANY DICTIONARY TO ut3;
GRANT EXECUTE ON SYS.DBMS_LOCK TO ut3;
GRANT EXECUTE ON SYS.DBMS_PIPE TO ut3;
GRANT EXECUTE ON SYS.DBMS_CRYPTO TO ut3;
GRANT CREATE ANY CONTEXT TO ut3;
EOF"

# Krok 2: Spustit instalaci přes wrapper skript (POZOR: přímý pipe nefunguje kvůli temp souborům)
sudo docker exec oracle-xe bash -c "
cat > /tmp/run_install.sql << 'EOF'
define ut3_owner=UT3
define ut3_tablespace=USERS
define ut3_temp_tablespace=TEMP
spool /tmp/utplsql_install.log
@/tmp/utplsql/install.sql
spool off
exit
EOF
cd /tmp/utplsql && sqlplus sys/DevPass123@//localhost:1521/DEVPDB AS sysdba @/tmp/run_install.sql
" 2>&1 | grep -E "Installing|completed|ERROR|ORA-"
```

> **Proč wrapper skript:** install.sql generuje dočasný soubor `params.sql.tmp` přes SPOOL.
> Při použití `echo "..." | sqlplus` Oracle nemůže zapsat tento soubor → instalace selže.
> Řešení: zapsat wrapper SQL soubor na disk kontejneru a spustit ho jako `@soubor`.

### Veřejné synonyma a oprávnění

Po instalaci je nutné jednou spustit (jinak `ut.expect` a `ut.run` nejsou dostupné):

```bash
sudo docker exec oracle-xe bash -c "sqlplus -S sys/DevPass123@//localhost:1521/DEVPDB AS sysdba << 'EOF'
-- Oprávnění na typy a balíčky
BEGIN
  FOR obj IN (
    SELECT object_name FROM all_objects
    WHERE owner = 'UT3'
    AND object_type IN ('PACKAGE','TYPE','FUNCTION','PROCEDURE')
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON UT3.' || obj.object_name || ' TO PUBLIC';
  END LOOP;
END;
/

-- Veřejná synonyma pro packages (ut.run, ut.expect, ...)
BEGIN
  FOR obj IN (
    SELECT object_name FROM all_objects
    WHERE owner = 'UT3' AND object_type = 'PACKAGE'
    AND NOT EXISTS (
      SELECT 1 FROM dba_synonyms WHERE table_owner='UT3' AND table_name=object_name
    )
  ) LOOP
    EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM ' || obj.object_name || ' FOR UT3.' || obj.object_name;
  END LOOP;
END;
/
-- Hlavní UT synonym (pokud chybí)
CREATE OR REPLACE PUBLIC SYNONYM ut FOR ut3.ut;
EOF"
```

> **Proč PUBLIC synonyma:** Při kompilaci test packages Oracle vyhledává `ut.expect`
> v aktuálním schématu. Bez public synonymu dostanete `PLS-00201: identifier 'UT.EXPECT' must be declared`.

---

## Oracle APEX (volitelné)

Oracle APEX (Application Express) je webový framework vestavěný do Oracle DB. Obsahuje
**SQL Workshop** – plnohodnotný webový SQL editor a schema browser.

### Stav v gvenzl image

**APEX není součástí `gvenzl/oracle-xe:21` image** – musí se nainstalovat manuálně do DB.
Platí stejně pro slim i plný image.

### Instalace APEX

> Požadavky: ~450 MB download, ~30-60 min instalace, ~2 GB místo v DB

```bash
# 1. Stáhnout APEX ze stránky Oracle (nevyžaduje Oracle účet)
cd /tmp
wget https://download.oracle.com/otn_software/apex/apex_latest.zip
unzip apex_latest.zip

# 2. Zkopírovat do kontejneru
sudo docker cp /tmp/apex/. oracle-xe:/tmp/apex/

# 3. Spustit instalaci (trvá 30-60 min)
sudo docker exec oracle-xe bash -c "
cd /tmp/apex
sqlplus sys/DevPass123@//localhost:1521/DEVPDB AS sysdba << 'EOF'
@apexins.sql SYSAUX SYSAUX TEMP /i/
EOF
"

# 4. Nastavit APEX admin heslo
sudo docker exec oracle-xe bash -c "
echo \"
EXEC APEX_UTIL.set_security_group_id(10);
EXEC APEX_UTIL.create_user(
  p_user_name    => 'ADMIN',
  p_email_address => 'admin@example.com',
  p_web_password => 'Welcome1#',
  p_developer_privs => 'ADMIN');
COMMIT;
\" | sqlplus -S sys/DevPass123@//localhost:1521/DEVPDB AS sysdba
"

# 5. Spustit ORDS (potřebný pro web přístup k APEX)
# Viz sekce ORDS níže
```

### APEX účty

| Účet | Heslo (výchozí) | Popis |
|------|-----------------|-------|
| ADMIN | `Welcome1#` (nastaví se při instalaci) | APEX správce workspace |
| APEX_PUBLIC_USER | – | Technický účet pro ORDS, nemenít |

> **Výchozí workspace pro SQL Workshop:** `INTERNAL`
> **URL po zprovoznění ORDS:** `http://localhost:8181/ords/apex`

### ORDS (Oracle REST Data Services)

ORDS je middleware mezi HTTP a Oracle DB. Potřebný pro APEX přes web.
Lze spustit jako standalone Java proces nebo jako Docker kontejner:

```bash
# ORDS standalone (vyžaduje Java 11+)
# 1. Stáhnout ORDS z oracle.com
# 2. Nakonfigurovat:
java -jar ords.war install \
  --admin-user SYS \
  --db-hostname localhost \
  --db-port 1521 \
  --db-servicename DEVPDB \
  --feature-db-api true \
  --feature-rest-enabled-sql true

# Spustit:
java -jar ords.war serve --port 8181
```

### Varianty přístupu bez APEX

Pro vývoj a prohlížení dat bez APEX:
- **DBeaver** (nainstalováno) – nejsnazší, GUI, offline
- **SQLcl** – CLI, pro scripting a Claude Code
- **Oracle EM Express** – port 5500, základní monitoring (vyžaduje konfiguraci SSL walletpri)

---

## Konfigurace připojení k DB

### Princip: jediný zdroj pravdy je `.env`

Všechna připojovací data jsou v souboru `.env` v kořeni projektu.
**Soubory `flyway.conf` neobsahují credentials** – vždy je přebírají skripty z `.env`.

```
oracle-plsql-dev/
├── .env              ← JEDINÉ místo kde se mění DB připojení
├── .env.example      ← Šablona s příklady pro různá prostředí
├── flyway.conf       ← Jen schema/tabulka/lokace, žádné heslo
└── test-app/
    └── flyway.conf   ← Totéž pro test-app
```

### Přepnutí na jiné prostředí

Stačí upravit `.env`:

```bash
# Lokální Docker XE (výchozí)
DB_USER=portal
DB_PASS=portal123
DB_DSN=localhost:1521/DEVPDB
DB_URL=jdbc:oracle:thin:@//localhost:1521/DEVPDB

# Dev server
DB_DSN=dev-oracle.firma.cz:1521/DEVPDB
DB_URL=jdbc:oracle:thin:@//dev-oracle.firma.cz:1521/DEVPDB

# Oracle RAC / scan listener
DB_DSN=scan-listener.firma.cz:1521/APPDB
DB_URL=jdbc:oracle:thin:@//scan-listener.firma.cz:1521/APPDB

# TNS alias (vyžaduje tnsnames.ora)
DB_DSN=DEVPDB_ALIAS
DB_URL=jdbc:oracle:thin:@DEVPDB_ALIAS
```

Po úpravě `.env` fungují všechny skripty bez dalších změn:

```bash
bash test-app/db/scripts/deploy.sh   # Flyway + kompilace
bash test-app/db/scripts/test.sh     # utPLSQL testy
bash db/scripts/sqlcl.sh             # Interaktivní SQL
```

### Jak to funguje technicky

**SQLcl** přijímá DSN ve formátu `user/pass@host:port/service`:
```bash
sqlcl -S "${DB_USER}/${DB_PASS}@${DB_DSN}"
```

**Flyway** přijímá JDBC URL + user + password jako CLI flagy:
```bash
flyway -configFiles="$APP_ROOT/flyway.conf" \
  -url="$DB_URL" -user="$DB_USER" -password="$DB_PASS" \
  migrate
```

Flyway conf obsahuje jen app-specifická nastavení:
```properties
# test-app/flyway.conf
flyway.schemas=PORTAL
flyway.locations=filesystem:db/migrations
flyway.baselineOnMigrate=true
flyway.baselineVersion=0
flyway.table=test_app_flyway_history
```

### Více prostředí (.env.local, .env.prod)

Pro přepínání mezi prostředími lze mít více env souborů:

```bash
# Výchozí: .env → lokální XE
# Dev server:
cp .env.example .env.dev
# (upravit .env.dev)

# Přepnout na dev server:
cp .env.dev .env
bash test-app/db/scripts/deploy.sh

# Nebo předat přímo (bez přepisu):
DB_USER=app DB_PASS=secret DB_DSN=devserver:1521/DB DB_URL=jdbc:oracle:thin:@//devserver:1521/DB \
  bash test-app/db/scripts/deploy.sh
```

### Poznámka k Oracle Wallet / SSL

Při připojení na cloud nebo produkci s Oracle Wallet:

```bash
# DB_URL pro wallet:
DB_URL=jdbc:oracle:thin:@(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.region.oraclecloud.com))(connect_data=(service_name=dbname_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))

# SQLcl wallet:
DB_DSN='(description=...)'  # TNS string nebo alias z tnsnames.ora
```

---

## Struktura projektu

```
oracle-plsql-dev/
├── .env                    # DB credentials (nesdílet!)
├── .env.example            # Šablona pro nové prostředí
├── flyway.conf             # Globální Flyway konfigurace
├── SETUP.md                # Tento soubor
├── CLAUDE.md               # Instrukce pro Claude Code
├── db/
│   └── scripts/
│       ├── compile.sh      # Kompiluje jeden package (spec + body)
│       ├── compile_all.sh  # Kompiluje všechny packages
│       ├── check_errors.sh # Zobrazí INVALID objekty a chyby
│       ├── run_tests.sh    # Spustí utPLSQL testy
│       └── sqlcl.sh        # Interaktivní SQLcl session
└── test-app/               # Ukázková aplikace (contacts + tasks)
    ├── .env -> ../.env     # Symlink na globální .env
    ├── flyway.conf         # App-specifická Flyway konfigurace
    └── db/
        ├── migrations/
        │   └── V1__schema.sql      # DDL: contacts, tasks, audit_log
        ├── packages/
        │   ├── contacts_pkg.pks    # Spec: správa kontaktů
        │   ├── contacts_pkg.pkb    # Body: validace emailu, audit log
        │   ├── tasks_pkg.pks       # Spec: správa úkolů
        │   └── tasks_pkg.pkb       # Body: stavový automat
        ├── tests/
        │   ├── ut_contacts_pkg.pks # utPLSQL spec (10 testů)
        │   ├── ut_contacts_pkg.pkb # utPLSQL body
        │   ├── ut_tasks_pkg.pks    # utPLSQL spec (9 testů)
        │   └── ut_tasks_pkg.pkb    # utPLSQL body
        └── scripts/
            ├── deploy.sh           # Flyway + compile + INVALID check
            └── test.sh             # Spustí ut.run(':test_app')
```

---

## Vývojový workflow s Claude Code

### CLAUDE.md

V kořeni projektu je soubor `CLAUDE.md` s instrukcemi pro Claude Code – jak kompilovat,
testovat a debugovat PL/SQL kód.

### Typický workflow

1. **Úprava kódu** – Claude Code upraví `.pks`/`.pkb` soubor

2. **Kompilace jednoho package:**
   ```bash
   bash db/scripts/compile.sh contacts_pkg
   # Výstup: "VALID" nebo seznam chyb s čísly řádků
   ```

3. **Kompilace všeho:**
   ```bash
   bash db/scripts/compile_all.sh
   ```

4. **Kontrola chyb:**
   ```bash
   bash db/scripts/check_errors.sh
   ```

5. **Spuštění testů:**
   ```bash
   bash test-app/db/scripts/test.sh
   # nebo filtrovaně:
   bash db/scripts/run_tests.sh ut_contacts_pkg
   ```

6. **Interaktivní SQL:**
   ```bash
   bash db/scripts/sqlcl.sh
   # Připojí se jako PORTAL uživatel
   ```

### Flyway migrace

Flyway spravuje verze schématu. Konfigurace:
- `flyway.baselineVersion=0` – nutné pro Oracle, aby se V1 skutečně spustila
- `flyway.table=<app>_flyway_history` – per-app tabulka, ne sdílená
- Migrace: `V{číslo}__{popis}.sql` v `db/migrations/`

```bash
# Deploy (migrace + kompilace + kontrola):
cd test-app && bash db/scripts/deploy.sh

# Samotná migrace:
flyway -configFiles=test-app/flyway.conf migrate
```

### Syntaxe ut.run

```sql
-- Spustit všechny testy v aktuálním schématu
EXEC ut.run();

-- Spustit dle suitepath (ne schema!)
EXEC ut.run(':test_app');

-- Spustit konkrétní package
EXEC ut.run('ut_contacts_pkg');

-- Spustit konkrétní test
EXEC ut.run('ut_contacts_pkg.test_add_contact_ok');
```

---

## Testovací aplikace

Adresář `test-app/` obsahuje ukázkovou aplikaci demonstrující celý stack:

### Schéma

- **contacts** – kontakty (jméno, email unikátní, telefon, aktivní Y/N)
- **task_statuses** – číselník stavů (NEW, IN_PROGRESS, DONE, CANCELLED)
- **tasks** – úkoly přiřazené kontaktům, stavový automat
- **audit_log** – automatický audit log INSERT/UPDATE přes trigger

### Packages

**contacts_pkg** – správa kontaktů:
- `add_contact(first, last, email, phone)` → ID
- `update_contact(id, ...)` – nullable parametry pro partial update
- `deactivate_contact(id)` – soft delete
- `get_open_task_count(id)` → NUMBER
- Výjimky: `e_contact_not_found`, `e_duplicate_email`, `e_invalid_email`

**tasks_pkg** – správa úkolů:
- `create_task(contact_id, title, desc, due_date)` → ID
- `start_task(id)` – NEW → IN_PROGRESS
- `complete_task(id)` – NEW/IN_PROGRESS → DONE
- `cancel_task(id)` – NEW/IN_PROGRESS → CANCELLED
- `get_contact_tasks_json(contact_id)` → CLOB (JSON)
- Výjimka: `e_invalid_transition` (pokus o neplatný přechod stavů)

### Testy

```
test_app
  Tasks Package Tests (9 testů)
    ✓ Vytvoření úkolu - OK
    ✓ Vytvoření úkolu pro neexistující kontakt vyvolá výjimku
    ✓ Spuštění úkolu NEW -> IN_PROGRESS
    ✓ Dokončení úkolu IN_PROGRESS -> DONE
    ✓ Dokončení úkolu přímo NEW -> DONE
    ✓ Zrušení úkolu
    ✓ Nelze spustit úkol který není NEW
    ✓ Nelze zrušit již dokončený úkol
    ✓ JSON výpis úkolů kontaktu
  Contacts Package Tests (10 testů)
    ✓ Přidání kontaktu - OK
    ✓ Duplicitní email vyvolá výjimku
    ✓ Neplatný email vyvolá výjimku
    ✓ Email se uloží lowercase
    ✓ Aktualizace kontaktu - OK
    ✓ Aktualizace neexistujícího kontaktu vyvolá výjimku
    ✓ Deaktivace kontaktu
    ✓ Dvojitá deaktivace vyvolá výjimku
    ✓ Počet otevřených úkolů
    ✓ Audit log se zapíše při INSERT

19 tests, 0 failed, 0 errored, 0 disabled, 0 warning(s)
```

---

## Nainstalované verze

| Nástroj | Verze | Umístění |
|---------|-------|----------|
| OpenJDK | 21.0.10 | `/usr/bin/java` |
| SQLcl | 26.1.0.0 | `/opt/sqlcl/bin/sql` |
| Flyway | 9.22.3 | `/opt/flyway-9.22.3/flyway` |
| Docker | 29.4.0 | `/usr/bin/docker` |
| Oracle XE | 21c (slim) | Docker container `oracle-xe` |
| utPLSQL | 3.1.14 | Schema `UT3` v DEVPDB |

---

## Řešení problémů

### ORA-00942: table or view does not exist (při kompilaci packages)

Flyway historická tabulka obsahuje záznam o V1 migrace, která ve skutečnosti neproběhla.

```bash
# Zkontrolovat stav:
sudo docker exec oracle-xe bash -c "echo \"
SELECT table_name FROM user_tables;
\" | sqlplus -S portal/portal123@//localhost:1521/DEVPDB"

# Pokud chybí aplikační tabulky, smazat flyway historii:
sudo docker exec oracle-xe bash -c "echo \"
DROP TABLE \\\"test_app_flyway_history\\\";
COMMIT;
\" | sqlplus -S portal/portal123@//localhost:1521/DEVPDB"

# Znovu spustit deploy
bash test-app/db/scripts/deploy.sh
```

> **Příčina:** `flyway.baselineOnMigrate=true` bez `flyway.baselineVersion=0`
> způsobí, že Flyway označí V1 jako baseline (neaplikuje ji) místo aby ji spustil.
> Konfigurace `baselineVersion=0` je v `test-app/flyway.conf` již nastavena.

### ORA-00904: "UT3"."UT_KEY_VALUE_PAIR": invalid identifier

utPLSQL typy nejsou přístupné vývojovému uživateli.

```bash
sudo docker exec oracle-xe sqlplus -S sys/DevPass123@//localhost:1521/DEVPDB AS sysdba << 'EOF'
BEGIN
  FOR obj IN (
    SELECT object_name FROM all_objects
    WHERE owner='UT3' AND object_type IN ('PACKAGE','TYPE','FUNCTION','PROCEDURE')
  ) LOOP
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON UT3.' || obj.object_name || ' TO PUBLIC';
  END LOOP;
END;
/
EOF
```

### ORA-44001: invalid schema (při ut.run)

Špatná syntaxe volání. `ut.run('test_app')` interpretuje `test_app` jako název schématu.
Správná syntaxe pro suitepath:

```sql
EXEC ut.run(':test_app');   -- suitepath s dvojtečkou
EXEC ut.run();               -- všechny testy v aktuálním schématu
```

### SQLcl ClassNotFoundException / Permission denied

```bash
sudo chmod -R a+rX /opt/sqlcl/
# Pokud chybí lib/modules/:
sudo mkdir -p /opt/sqlcl/lib/modules
for jar in /opt/sqlcl/lib/*.jar; do
  sudo ln -sf "$jar" "/opt/sqlcl/lib/modules/$(basename $jar)"
done
```

### Flyway: "Teams upgrade required: SQL*Plus is not supported"

Používáte Flyway 10+. Přejít na Flyway 9.22.3:

```bash
sudo ln -sf /opt/flyway-9.22.3/flyway /usr/local/bin/flyway
flyway -v  # Musí zobrazit "9.22.3"
```

### Oracle kontejner neběží

```bash
sudo docker ps -a | grep oracle-xe
sudo docker start oracle-xe
sudo docker logs oracle-xe | tail -20
```

### Kontrola volného místa

```bash
df -h /
# Varování: Oracle XE image + data volume ~4-5 GB
# Doporučeno udržovat >10 GB volného místa
```
