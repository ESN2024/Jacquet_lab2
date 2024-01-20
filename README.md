# ESN11 - Rapport Lab2

## Objectifs
Construire et programmer un système de base Nios II sur un FPGA DE10-Lite pour contrôler un ensemble de périphériques présent sur la carte électronique. Nous allons devoir développer un compteur qui s'incrémente chaque seconde sur 3 afficheurs 7 segments. Nous devrons donc pouvoir compter de 0 à 999, et l'afficher en décimale.

## Introduction
Nous allons ainsi voir chaque étape de la réalisation de ce projet, les difficultés, les points clés, les raisons qui nous ont poussés aux différents choix d'implémentation spécifique de notre système.

## Réalisation du système
Nous allons dans un premier construire une représentation du système finale avant de passer à l'étape de la réalisation.

### Schéma bloc fonctionnel

![image](https://github.com/ESN2024/Jacquet_lab2/assets/127327962/b1ade232-76d7-4f5d-ac43-e7931cb02953)

Ce schéma présente l'architecture finale de notre système, la liaison entre notre pc et le système cible, ici la DE10 lite, via un câble USB Blaster. Ici nous visualisons uniquement les périphériques décris dans nos objectifs, évidemment la clock n'apparaît pas, ainsi que le signal de reset présent sur un second bouton poussoire.
L'architecture comporte ainsi différents modules important : 
1. RAM : La mémoire avec une capacité de 40 Mo, amplement suffisant pour cette implémentation.
2. 3 blocs PIO (Parrallel input/output) permettant au FPGA de communiquer avec l'extérieur en lisant des signaux d'entrées et en envoyant des signaux de sortie.
3. Processeur Nios II : Processeur soft-core configurable du FPGA présent sur la DE10 lite. En tant que soft-core, il est implémenté en logique programmable plutôt que fabriqué en tant que puce physique, Ce qui lui donne une nature configurable et nous permet de personnaliser le processeur en fonction de nos besoins spécifiques, réel gain de performances.
4. Un module timer d'intervalle 1 seconde afin de pouvoir incrémenter comme convenu notre compteur.
5. Des blocs VHDL afin de convertir nos données sur l'afficheur 7 segments.

### Création du système sous Platform Designer
Après avoir crée sous Quartus 18.1 notre projet nous allons pouvoir avec l'outil Platform Designer crée notre système en déclarant l'ensemble des modules nécessaires ainsi que leurs configurations respectives.
<img width="404" alt="image" src="https://github.com/ESN2024/Jacquet_lab2/assets/127327962/d132e610-b643-4a31-b0a5-382db7e2d468">

Il faudra relier minutieusement ces différents modules pour les interconnecter de façon intelligente.

Lorsque ces étapes ont été réalisé et que Platform Designer ne renvois aucune erreur nous pouvons généré le VHDL correspondant à ce système en l'exportant (Generate/Generate HDL/Selectionner VHDL).

### Création d'un module VHDL BCD7SEG

Nous allons réaliser la description VHDL d'un composant qui permet d'afficher un mot de 4 bits sur un afficheur 7 segments. Ce composant consiste à transcrire un nombre compris entre 0 et 9 en un mot sur 7 bits correspondant à l'état haut ou bas de nos différents segments.

### Création du Top Level

Ce fichier VHDL consiste à réaliser un liant entre notre Qsys correspondant à nos modules instanciés ainsi que notre composants BCD7SEG, il relie donc ces deux composants à l'aide de signaux sur un Port Map décris en ligne de code.

### Intégration du design généré
Nous allons maintenant revenir sous quartus et réalisé une étape fondamental qui consiste à relié nos broches à nos PIO. Cette étape est réalisé avec l'outil Pin Planner de Quartus (Assignments/Pin Planner). Avant cela il faudra réalisé le check Analysis & Synthesis pour vérifier notre développement jusque là et intégré l'assignation des broches. Une fois cette étape réalisé nous allons pouvoir lancé l'outil Pin Planner et assigné nos broches à nos PIO, attention il faut bien vérifié que le device est le même que le système cible auquel cas nos broches seront différentes (Quartus/Assignments/Device) ici nous développons sur la MAX 10 - 10M50DAF484C7G :

<img width="365" alt="image" src="https://github.com/ESN2024/Jacquet_Lab1/assets/127327962/38226d07-c961-448a-9e1f-cefcc015430f">

Nous retrouvons donc une visualisations de nos broches, avec en dessous nos différents signaux PIO à relier :

<img width="524" alt="image" src="https://github.com/ESN2024/Jacquet_Lab1/assets/127327962/1ed6c888-9472-42e5-a9fa-6643230d793a">

Une fois l'intégralité de nos signaux récupérés, nous pouvons fermé Pin Planner, revenir sur Quartus et lancer le Compile Design afin de compiler l'entiereté de nos système et récupérer les fichiers nécessaires à la suite du développement de notre projet.

### Génération de la BSP
Nous allons maintenant passer à une étape clé, la génération de notre BSP (Board Support Package), facilite la communication entre le logiciel et le matériel, cette étape se réalise sous le terminal Nios II avec la commande : 
<img width="409" alt="image" src="https://github.com/ESN2024/Jacquet_Lab1/assets/127327962/2daa0ab4-defb-4bd4-bf3d-6370fa76a2e8">

Ce qui nous génére un fichier que nous stockerons dans le répertoire /soft, à coté de /app où seront stockés notre code .c et la makefile associé.

### Création du code source

Afin de piloter nos périphériques de façon à créer un chenillard de leds, lancé par un bouton poussoir et à vitesse réglable par des switchs, nous allons écrire un code en C, voici les étapes :

1. Génération des bibliothèques
   #include <stdio.h>: Bibliothèque standard C pour les entrées/sorties, comme printf et scanf.
   #include "system.h": Fichier de configuration spécifique au système Nios II, définit la configuration matérielle.
   #include "sys/alt_sys_init.h": Initialise les composants système d'Altera pour Nios II.
   #include <io.h>: Fournit des fonctions d'entrée/sortie bas niveau, souvent utilisées pour les opérations sur les registres.
   #include <alt_types.h>: Définit des types de données spécifiques à Altera, comme alt_u32 pour les entiers non signés 32 bits.
   #include <sys/alt_irq.h>: Gère les fonctions liées aux interruptions dans les systèmes Nios II d'Altera.
   #include "altera_avalon_pio_regs.h": Fournit des définitions et des fonctions pour manipuler les registres des blocs PIO d'Altera.
   

3. Développement de l'interruption de pilotage de la vitesse
   Nous avons besoin d'une interruption pour les déterminé les états des 4 switchs qui piloteront notre vitesse en renvoyant la valeur sur chaser_speed :
   <img width="389" alt="image" src="https://github.com/ESN2024/Jacquet_Lab1/assets/127327962/83151268-e341-4874-8e40-e6576d1c2726">

   Cette fois ci nous avons bien une fonction de remise à 0 du registre d'interuption : IOWR_ALTERA_AVALON_PIO_EDGE_CAP(PIO_2_BASE, 0x0F), qui nous permet après chaque modification d'état d'un des switchs de renvoyer la valeur correcte de la vitesse du chenillard. Cette vitesse est renvoyé sur chaser_speed avec la fonction de lecture : chaser_speed = IORD_ALTERA_AVALON_PIO_DATA(PIO_2_BASE), qui nous permet de récuperer la valeur des 4 switchs déclaré dans notre PIO jusqu'à une valeur maximale de 15 et de l'afficher à l'aide de notre fonction alt_printf à chaque appel de l'interruption.

4. Fonction principale Main()
   Fonction principale de notre code C, qui sera stoppé à chaque interruption le temps d'exécuter la fonction d'interruption :
   <img width="620" alt="image" src="https://github.com/ESN2024/Jacquet_Lab1/assets/127327962/37c86795-544d-4d45-bb66-4879e5884045">

   Cette fonction commence par une partie d'initialisation des variables et des interruptions, la mise à 1 de la vitesse de notre chenillard par défault ainsi que l'activation des interruptions avec la fonction : IOWR_ALTERA_AVALON_PIO_IRQ_MASK défini à la valeur hexadécimale des périphériques potentiellement déclencheur de cette dernière, ainsi que la fonction IOWR_ALTERA_AVALON_PIO_EDGE_CAP qui permet l'initialisation ou la réinitialisation du registre d'interruptions, ici dans notre main nous l'initialisation une fois, le reste des réinitialisations se passera dans les fonctions d'interruptions. Enfin nous enregistrons les gestionnaires d'interruptions avec la fonction : alt_irq_register. Cette partie d'inititialisation est désormais fini, nous pouvons rentrer dans la boucle while(1) afin d'executer le programme en boucle en attendant uniquement le déclenchement des interruptions.

## Déploiement du projet sur le système cible

Nous revenons à notre terminale Nios II, où nous avons précédemment généré notre BSP, nous allons maintenant généré automatiquement un Makefile avec la commande :
   <img width="295" alt="image" src="https://github.com/ESN2024/Jacquet_Lab1/assets/127327962/09d00f23-ebc5-48b9-9e92-41651effd3f8">

Ce Makefile nous permettra de compiler notre code C ainsi que l'intégralité de notre projet afin de le tester sur notre DE10 lite. une fois généré il nous suffit d'utiliser la commande make à l'endroit où a été généré le Makefile c'est à dire aux cotés du code C. Si aucune erreur n'est remonté, le programme est prêt à être lancé sur la DE10, attention à bien vérifié la connection à la carte avec l'USB Blaster (Tools/Programmer/Start). C'est à l'aide de cette commande : 
<img width="216" alt="image" src="https://github.com/ESN2024/Jacquet_Lab1/assets/127327962/ede777e3-89ba-438c-a72b-e3599f1dcdbb">

que nous allons déployer le programme, et à l'aide de Nios2-terminale.exe suivre les retours renvoyé par nos alt_printf sur notre terminale.

Voici la démonstration finale de notre programme en vidéo : 
[https://github.com/ESN2024/Jacquet_Lab1/assets/127327962/ef314df1-0a86-4096-9aff-18ab99b545d9](https://github.com/ESN2024/Jacquet_Lab1/blob/main/IMG_3171.MOV)

## Conclusion
Ce second projet réalisé sur notre DE10 lite aura été légérement plus compliqué que le premier où la difficulté était dans l'utilisation des interuptions. Ici la difficulté était dans la création des blocs VHDL et leurs liens sous le Top Level. En effet le VHDL est un langage assez à part dans son écriture et il aura fallu se replonger dedans. La seconde difficulté était dans l'insertion d'un timer et son implémentation et utilisation dans notre code source afin d'incrémenter le compteur comme voulu.


