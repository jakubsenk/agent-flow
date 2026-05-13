zde je zadani co jsem dostal, co to musi umet:

:) cilem neni nechat souperit agenty a/nebo prompty ale domluvit se na tom, jak z toho udelat super produkt.
Abych byl konkretni:
- chci zavest neco z toho do App tymu
- nemuzeme cely proces, protoze na to nejsou ready a ani Oracle dev proces pro agenta neni proslapnuty
- pokousel jsem se ten setup namontovat na firemni proces a fail z duvodu ze je to monolit a nelze jednoduse (aspon pro mne) nasadit pouze jednoho agenta, potom dalsiho atd; take workflow/setup v redmine nelze jednoduse namapovat
  => potrebuji se domluvit na  vetsi flexibilite designu, protoze stejne jako u nas, tak ani jinde to nikdo nevezme jako celek a okamzite nasadi
  => bude treba oddelit 3 veci, ktere v soucasne dobe vypadaji jako ze jsou na ruznych mistech dost promichane
1. Agent a jeho obecne schopnosti
2. Technologicke dovednosti
3. Workflow/Proces
   --> to oddeleni a s tim souvisejici kontrakty pro predavani vstupu/vystupu umozni postupne zarazovat dalsi a dalsi casti celeho retezu do existujiciho vyvoje
   Na strane redmine rovnez musi vzniknout novy setup.
   Agenticky vyvoj obecne znamena rozbiti a zjednoduseni komplikovane hierarchie epic--feature-us-task --> v tom se agent ztrati a predavani kontextu bude nocni mura a asi i plytvani tokeny (coz bych rekl mimochodem ze v soucasnch ceos-agents plati take).

Abychom presli od teorie k praxi: budu mit dnes zadani na projekt pro drmaxsk, a jeho cast bych chtel spustit a zapojit nekoho z app tymu. Dale nastavim projekt s 2stupnovym clenenim (epic-task) a jednoduchym workflow v Redmine ktery do toho zkusime napojit. Zacli bychom s nekolika agenty kteri budou delat planovani, vyvoj a test, ale musi byt schopni zaradit se do retezce prace s lidmi.

Cili moje predstava je, ze vyuzijeme role ktere mate predpripravene, ale orchestrace bude muset vzniknout samostatne od agentu a musime byt schopni nasazovat agenty "postupne"

v YT jsem zadal:
https://cmd.youtrack.cloud/projects/ACT/issues/ACT-7/Agent-Flow-aka-ceos-agents-revize
místo pro diskusi vylepšování ceos-agents
https://cmd.youtrack.cloud/projects/ACT/issues/ACT-8/Zapojeni-do-projektu-SK-kompenzace
zde bude zadání pro rozjetí ceos-agents ve slovenském projektu
zatím placeholder, behem den doplním

ad SK projekt viz výše:
doplnil jsem do popisu co máme zip v příloze
chtěl bych ukázat vývoj/test/dokumentaci engine pro výpočet kompenzací (v Oracle PL/SQL)
toto bude vyzadovat aby mel agent k dispozici docker s bezici Oracle DB kde bude moct validovat to co vygeneruje
projekt v redmine je nastavený
background castecne popsany v tom ticketu výse (odkaz do knowledge base)

v projektu v redmine jste jako admin, ale cokoliv tam budete potrebovat, tak dejte vedet a ja nastavim

asi ta nejproblematictejsi vec bude ten Oracle docker a s tim souvisi KDE to vlastne rozject

idealni by bylo na tom novem boxu, ale nevim co by to znamenalo
dalsi varianta je u mne - kvuli Oracle
ale to uz se mi uplne nepodarilo kvuli tem "neflexibilnim workflow atd v Redmine" ...
... proto jsem zakladal ten novy projekt
ale i tak - ta prace s vyvojem PL/SQL Oracle v tech agentech uplne podporovana neni

cili bylo by fajn udelat nejaky minimalni zaklad, na kterem bude mozne to ukazat a nemusi to byt nezbtne cela ta masinka ceos-agents ale klidne jen cast + rucni orchestrace promptovani

jinak instalaci stacku pro Oracle vyvoj uz mi jede, vznikne z toho instalacni prirucka pro claude code kterou vam pak predam
