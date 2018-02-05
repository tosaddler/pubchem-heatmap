#pubchem_fingerprint_example.R
#Sample code for working with PubChem fingerprints
library(rcdk)
source('pubchemfunctions.R')

#SMILES descriptors for ethane and ethanol, and for chemicals that have descriptor 
# numbers 879 and 880 to test the alignment of the PubChem 881-bit descriptor string
# in the fingerprint from the web site
smiles1 <- "CC" #ethane
smiles2 <- "CCO" #ethanol
smiles3 <- "BrC1C(Br)CCC1" #This is descriptor 880 from the PubChem list;
#this is also a valid SMILES string for 1,2-dibromopentane
smiles3 <- "ClC1C(Br)CCC1" #This is descriptor 879 from the PubChem list;
#this is also a valid SMILES string for 1-bromo-2-chloro-cyclopentane
smiles4 <- "BrC1C(Br)CCC1" #This is descriptor 880 from the PubChem list;
#this is also a valid SMILES string for 1,2-dibromocyclopentane


#Parse the SMILES strings with the parse.smiles function from rcdk
mol1 <- parse.smiles(smiles1)
mol2 <- parse.smiles(smiles2)
mol3 <- parse.smiles(smiles3)
mol4 <- parse.smiles(smiles4)

#Fingerprints cut and pasted from PubChem
coded1 <-
  'AAADcYBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGAAAAAAAAACAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
coded2 <- 
  'AAADcYBAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGgAACAAAAACggAICAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
coded3 <- 
  'AAADccBgAAAEEAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAAAGAJAAAAByAOAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAiAAAAIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB'
coded4 <- 
  'AAADccBgAAAAGAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAAAGABAAAAByACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'

#Decode the fingerprints using a function from pubchemfunctions.R
#This gives vectors of length 880
decode1 <- pubchemfingerprint_to_vector(coded1)
decode2 <- pubchemfingerprint_to_vector(coded2)
decode3 <- pubchemfingerprint_to_vector(coded3)
decode4 <- pubchemfingerprint_to_vector(coded4)

#Find which PubChem descriptors are in each chemical
#Subtract 1 so the first position in the vector corresponds to number 0 in the list
#of descriptors in the PubChem fingerprint document
pubchem_descriptors1 <- which(decode1==1)-1
pubchem_descriptors2 <- which(decode2==1)-1
pubchem_descriptors3 <- which(decode3==1)-1
pubchem_descriptors4 <- which(decode4==1)-1

#Use a function from pubchemfunctions.R to find which descriptors each chemical has
whichdescs1 <- smiles_to_descriptornumbers(smiles1)
whichdescs2 <- smiles_to_descriptornumbers(smiles2)
whichdescs3 <- smiles_to_descriptornumbers(smiles3)
whichdescs4 <- smiles_to_descriptornumbers(smiles4)

print(whichdescs1)
print(whichdescs2)
print(whichdescs3)
print(whichdescs4)

print(pubchem_descriptors1)
print(pubchem_descriptors2)
print(pubchem_descriptors3)
print(pubchem_descriptors4)

#Compute Tanimoto similarity of ethane and ethanol, and of the other 2
tani12 <- tanimoto_binaryvectors(decode1,decode2)
tani34 <- tanimoto_binaryvectors(decode3,decode4)
