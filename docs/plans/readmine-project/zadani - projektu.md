Zapojení do projektu - SK kompenzace

Situace:

vytvořen projekt v redmine test s jednoduchým workflow a 2-stupňovou hierarchií zde https://redmine.test.ceosdata.com/projects/ai-dev/issues
je to pouze template pro AI vývoj a je několik možností jak postupovat
protože ladíme, zdá se mi jako overkill zakládat projekt pro každý produkt/projekt v rámci drmax
=> navrhuji zatím pracovat v rámci tohoto 1 projektu a zatím neřešit souběh více týmů, podprojektů
později můžeme vytvořit v rámci projektu frontu (tracker) ve kterém budou top-level tickety které zaštiťují právě projekt/produkt
hlavní úkol bude stejně připravit query, které budou moci používat agenti pro odebírání z fronty => reorganizace projektu a úprava podmínek query v budoucnu by neměla agenta výrazně rozbít
zadání je v příloze a skládá se primárně z analytických dokumentů které právě teď vznikají, na požádání lze dodat
původní poptávku klienta
přepis analytických schůzek spojených s poptávkou
Cíl:

Rozject ASAP vývoj
tracking v Redmine
schopnost automatizovaně (ale s možností lidského zásahu) generovat výstupy pro část DEV procesu v Oracle PL/SQL s tím že chceme ukázat tyto oblasti
funkční analýza
technická analýza
plán práce
vývoj PL/SQL
testování
dokumentace
Ukázat zástupci APP týmu čeho je agentický vývoj schopný a "nakoupit" ho pro postupnou adopci
počítat s postupným nasazováním ...
... prvotní ukázka bude určitě podrobena kritice a bude třeba ji přijmout s otevřenou myslí a reagovat kreativně

User avatar
Milan Marťák
Commented about 23 hours ago (edited)
Tak nez jsem to dopsal tak uz to claude pripravil - to je docela obcerstvujici zkusenost, historicky by takovato vec trvala nekolik dni se zapojenim N lidi z infra (tim si nestezuji na Infra, jen konstatuji). Ted to testuji a za mne zatim super, funguje vcetne utPSQL. Vzhledem k usetrenemu casu nechavm doinstalovat plnohodnotny XE s APEX namisto pouheho "slim". Az dojedeme upgrade, dam sem vyslednou dokumentaci.
Tak APEX tam nakonec nebude, a taky mi dosly tokeny takze pridavam orasetup.zip, kde

CLAUDE.md obsahuje instrukce pro PL/SQL vyvoj
SETUP.md jsou instalacni instrukce
@Filip Šabacký - fyi

User avatar
Milan Marťák
Commented 1 day ago
připravuji (tj claude) PL/SQL build stack který bude CC využívat
výstupem bude dokument který bude obsahovat
popis stacku a instalace
testovací aplikaci kterou CC na zaávěr vytvoří pro ověření že vše funguje
základě dokumentu chteme aby CC dokázal instalovat v cílovém prostředí vše potřebné + ověřit funkčnost
