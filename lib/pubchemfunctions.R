base64_to_vector <- function(x) {
  #Convert a character string x, a base 64 encoding of the type used in PubChem fingerprints,
  #to a vector of 0s and 1s
  
  charlist <- 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  
  nx <- nchar(x)
  #First convert each character to a number 0-63
  y1 <- numeric(nx)
  for (i in 1:nx) {
    #Find the position of ith character in the list and subtract 1 to convert 
    #range of 1-64 to 0-63
    y1[i] <- as.numeric(regexpr(substr(x,i,i),charlist)) - 1
  }
  
  #Then convert each number 0-63 to 6 binary digits
  y2 <- numeric(6 * nx)
  for (i in 1:nx) {
    integer_i <- y1[i]
    #Convert to a vector of 0s and 1s; intToBits() converts to a 32-element object 
    #with least-significant digit first. Since values only go up to 63 in this case,
    #use the first 6 elements and reverse them
    digits_i <- as.integer(intToBits(integer_i))
    digits_i <- digits_i[c(6,5,4,3,2,1)]
    #Put into big vector y2
    y2[seq(6*(i-1)+1,6*i)] <- digits_i
  }
  return(y2)
}

# Table of encodings used above, from the documentation on base64 encoding
# referenced in PubChems help file on the fingerprint
# Value Encoding  Value Encoding  Value Encoding  Value Encoding
# 0 A             17 R            34 i            51 z
# 1 B             18 S            35 j            52 0
# 2 C             19 T            36 k            53 1
# 3 D             20 U            37 l            54 2
# 4 E             21 V            38 m            55 3
# 5 F             22 W            39 n            56 4
# 6 G             23 X            40 o            57 5
# 7 H             24 Y            41 p            58 6
# 8 I             25 Z            42 q            59 7
# 9 J             26 a            43 r            60 8
# 10 K            27 b            44 s            61 9
# 11 L            28 c            45 t            62 +
# 12 M            29 d            46 u            63 /
# 13 N            30 e            47 v
# 14 O            31 f            48 w         (pad) =
# 15 P            32 g            49 x
# 16 Q            33 h            50 y

pubchemfingerprint_to_vector <- function(x) {
  #Convert a PubChem fingerprint (152-character string) to a length 880 vector
  #of 0s and 1s; position i in the vector = 1 if the chemical has descriptor (i-1);
  #this offset by 1 is needed because the PubChem descriptor numbering as described
  #in ftp://ftp.ncbi.nlm.nih.gov/pubchem/specifications/pubchem_fingerprints.pdf
  #starts at 0
  
  bigvector <- base64_to_vector(x) #vector including padding; length 912
  
  #Drop the padding
  vector880 <- bigvector[33:912]
  return(vector880)
}

smiles_to_descriptornumbers <- function(x) {
  #Given a SMILES string x, return a vector containing the PubChem fingerprint 
  #descriptors found in x
  
  #Uses package rcdk and fingerprint (which gets installed automatically
  #with rcdk)
  
  #Create a molecule object using the SMILES string
  molx <- parse.smiles(x)
  #Add explicit hydrogens so the PubChem fingerprint will include the
  #descriptors that count those
  convert.implicit.to.explicit(molx[[1]])
  fingerprintx <- get.fingerprint(molx[[1]],type='pubchem')
  #fingerprintx is an object; 'bits' list the bits that are turned on;  this in
  #in range 1:881 so subtract 1 to convert to range 0:880 as given in the
  #PubChem documentation
  return(fingerprintx@bits-1)
}

smiles_to_vector880 <- function(x) {
  #Convert a SMILES string to a vector of length 880 corresponding to a PubChem
  #fingerprint
  numbers_for_x <- smiles_to_descriptornumbers(x)
  #Drop descriptor 880 if it's there; for some reason that doesn't seem to actually
  #be in the descriptors on PubChem 
  numbers_for_x <- setdiff(numbers_for_x,880)
  y <- numeric(880)
  y(1 + numbers_for_x) <- 1 #offset by 1 because descriptor numbers start at 0
  return(y)
  
}

tanimoto_binaryvectors <- function(x,y) {
  #Compute Tanimoto similarity using two vectors of 0s and 1s
  number_inboth <- sum(x==1 & y==1)
  number_ineither <- sum(x==1 | y==1)
  return(number_inboth / number_ineither)
}