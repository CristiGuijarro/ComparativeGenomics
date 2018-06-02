# Comparative Genomics README
## -The Basic Package

### Download canonical proteins for whole genomes:

`./getEnsEMBLProt.pl <specieslist.txt>
./getUniProt.pl <missingspecies.txt>`

### Pass in \n (unix newline) separated list of species with 'Genus_species' format. e.g:
Homo_sapiens
Felis_cattus
Canis_lupis
Drosophila_melanogaster

Any species not found in those databases will be output in missingspecies.txt and missingspecies2.txt. It makes sense to pass the first instance of missingspecies.txt into the alternate program. Species not found will need to be downloaded and altered manually with 4 letter codes in file name and header. E.g. header line for Homo sapiens would begin: ">hsap_".

### Run:
`./moveNoDup.pl`
To create Proteomes directory and move all files over for next steps.

### Next:
`./checkProteins.pl`
This is a quick check for fasta header consistency, 4 letter species codes and a protein count.

### Further checks on the genomes:
### Install busco within directory with structure: busco/scripts/run_BUSCO.py
`./buscoGenerator.pl
./buscoParse.pl`

### Write the phylogeny table.
This needs to be done mostly manually. Needs to be a csv format listing:

| Species | Code | Super | Domain | Domain | Subdomain | Group | Kingdom | Ten | Nine | Eight | Seven | Six | Five | Four | Three | Two | One | Class | Order | Family | Genus | NumberOfProteins | Database_Source |
| ------- | ---- | ----- | ------ | ------ | --------- | ----- | ------- | --- | ---- | ----- | ----- | --- | ---- | ---- | ----- | --- | --- | ----- | ----- | ------ | ----- | ---------------- | --------------- |
| Caenorhabditis elegans | cele | Eukaryota | Amorphea | Unikonta | Opisthokonta | Metazoa | Basal2 | Basal3 | Bilateria | Protostomia | Ecdysozoa | Nematoida | Nematoda | Nematoda | Nematoda | Nematoda | Secernentea | Rhabditidae | Rhabditidae | Caenorhabditis | 20362 | EnsEMBL | 
 | Homo sapiens | hsap | Eukaryota | Amorphea | Unikonta | Opisthokonta | Metazoa | Basal2 | Basal3 | Bilateria | Deuterostomia | Chordata | Olfactores | Vertebrata | Tetrapoda | Amniota | Mammalia | Mammalia | Primates | Hominidae | Homo | 23625 | EnsEMBL | 

Save the file as phylogenyTable.csv.

### Concatenate all spec_prot.fasta into a single allProteins.fasta file.
`cat Proteomes_Backup/*_prot.fasta > allProteins.fasta`

### Blast each Proteomes_Backup/spec_prot.fasta against allProteins.fasta.

### Concatenate all the .blast files into an allProteins.blast file.
`cat *_prot.blast > allProteins.blast`

### Run MCL analysis:
`mcxdeblast --m9 --line-mode=abc --out=allProteins.mcl allProteins.blast
mcl <allProteins.mcl> --abc -o finalProteins.mcl`

### Create ComparativeGenomics Database in mySQL.
`CREATE DATABASE ComparativeGenomics;
USE ComparativeGenomics;
CREATE TABLE `phylogeny` (
  `Species` varchar(60) DEFAULT NULL,
  `SpecCode` varchar(5) DEFAULT NULL,
  `Superdomain` varchar(25) DEFAULT NULL,
  `Domain` varchar(25) DEFAULT NULL,
  `Subdomain` varchar(25) DEFAULT NULL,
  `Group` varchar(25) DEFAULT NULL,
  `Kingdom` varchar(25) DEFAULT NULL,
  `Ten` varchar(25) DEFAULT NULL,
  `Nine` varchar(25) DEFAULT NULL,
  `Eight` varchar(25) DEFAULT NULL,
  `Seven` varchar(25) DEFAULT NULL,
  `Six` varchar(25) DEFAULT NULL,
  `Five` varchar(25) DEFAULT NULL,
  `Four` varchar(25) DEFAULT NULL,
  `Three` varchar(25) DEFAULT NULL,
  `Two` varchar(25) DEFAULT NULL,
  `One` varchar(25) DEFAULT NULL,
  `Class` varchar(25) DEFAULT NULL,
  `Order` varchar(25) DEFAULT NULL,
  `Family` varchar(25) DEFAULT NULL,
  `Genus` varchar(25) DEFAULT NULL,
  `Numberofproteins` int(10) DEFAULT NULL,
  `Databasesource` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE `phylogeny` (
  `Species` varchar(60) DEFAULT NULL,
  `SpecCode` varchar(5) DEFAULT NULL,
  `Superdomain` varchar(25) DEFAULT NULL,
  `Domain` varchar(25) DEFAULT NULL,
  `Subdomain` varchar(25) DEFAULT NULL,
  `Group` varchar(25) DEFAULT NULL,
  `Kingdom` varchar(25) DEFAULT NULL,
  `Ten` varchar(25) DEFAULT NULL,
  `Nine` varchar(25) DEFAULT NULL,
  `Eight` varchar(25) DEFAULT NULL,
  `Seven` varchar(25) DEFAULT NULL,
  `Six` varchar(25) DEFAULT NULL,
  `Five` varchar(25) DEFAULT NULL,
  `Four` varchar(25) DEFAULT NULL,
  `Three` varchar(25) DEFAULT NULL,
  `Two` varchar(25) DEFAULT NULL,
  `One` varchar(25) DEFAULT NULL,
  `Class` varchar(25) DEFAULT NULL,
  `Order` varchar(25) DEFAULT NULL,
  `Family` varchar(25) DEFAULT NULL,
  `Genus` varchar(25) DEFAULT NULL,
  `Numberofproteins` int(10) DEFAULT NULL,
  `Databasesource` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE `sequences` (
  `SpecCode` varchar(5) NOT NULL,
  `Header` varchar(1000) NOT NULL,
  `Sequence` varchar(10000) NOT NULL,
  PRIMARY KEY (`Header`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE `genescollected` (
  `Homology` int(10) NOT NULL,
  `Header` varchar(1000) NOT NULL 
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE `homologycount` (
  `Homology` int(10) NOT NULL,
  `HomologyCount` int(10) NOT NULL,
  PRIMARY KEY (`Homology`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE `specieslisted` (
  `Homology` int(10) NOT NULL,
  `SpecCode` varchar(5) NOT NULL,
  KEY `Homology` (`Homology`),
  CONSTRAINT `specieslisted_ibfk_1` FOREIGN KEY (`Homology`) REFERENCES `genescollected` (`Homology`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE `phylogeny` (
  `Species` varchar(60) DEFAULT NULL,
  `SpecCode` varchar(5) DEFAULT NULL,
  `Superdomain` varchar(25) DEFAULT NULL,
  `Domain` varchar(25) DEFAULT NULL,
  `Subdomain` varchar(25) DEFAULT NULL,
  `Group` varchar(25) DEFAULT NULL,
  `Kingdom` varchar(25) DEFAULT NULL,
  `Ten` varchar(25) DEFAULT NULL,
  `Nine` varchar(25) DEFAULT NULL,
  `Eight` varchar(25) DEFAULT NULL,
  `Seven` varchar(25) DEFAULT NULL,
  `Six` varchar(25) DEFAULT NULL,
  `Five` varchar(25) DEFAULT NULL,
  `Four` varchar(25) DEFAULT NULL,
  `Three` varchar(25) DEFAULT NULL,
  `Two` varchar(25) DEFAULT NULL,
  `One` varchar(25) DEFAULT NULL,
  `Class` varchar(25) DEFAULT NULL,
  `Order` varchar(25) DEFAULT NULL,
  `Family` varchar(25) DEFAULT NULL,
  `Genus` varchar(25) DEFAULT NULL,
  `Numberofproteins` int(10) DEFAULT NULL,
  `Databasesource` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;`

### Upload sequences onto database
`./insertfastamysql <allProteins.fasta>`

### Parse the MCL files to input into database:
Either (quicker):
`./parseMCL.pl --<username> --<password> --finalProteins.mcl > mclinserts.sql
mysql -u<username> -p ComparativeGenomics < mclinserts.sql
Or (significantly slower but more automated):
Uncomment system commands in ./parceMCL.pl then run:
./parseMCL.pl --<username> --<password> --finalProteins.mcl`

### Produce the fullOccupancy.csv table for visualisation and checking.
`./fullOccupancy.pl --username "username" --password "password" > fullOccupancy.csv`
If no password simply press enter when prompted.

### Start collecting some numbers!
`./homologyOccupancy.pl --cladelevel "Kingdom" --cladename "Metazoa" > occupancy.sql`
--cladelevel can be any of the headings in the phylogeny database from Superdomain to Genus. Is case sensitive.
--cladename is any named item within the chosen --cladelevel column.
`mysql -u<username> -p ComparativeGenomics < occupancy.sql`




