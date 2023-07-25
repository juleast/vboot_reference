#!/bin/bash

# Copyright (c) 2010 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to generate padding.c containing PKCS 1.5 padding byte arrays for
# various combinations of RSA key lengths and message digest algorithms. 

Pad_Preamble="0x00,0x01"

SHA1_digestinfo="0x30,0x21,0x30,0x09,0x06,0x05,0x2b,0x0e,0x03,0x02,0x1a,0x05"\
",0x00,0x04,0x14"
SHA256_digestinfo="0x30,0x31,0x30,0x0d,0x06,0x09,0x60,0x86,0x48,0x01,0x65,0x03"\
",0x04,0x02,0x01,0x05,0x00,0x04,0x20"
SHA512_digestinfo="0x30,0x51,0x30,0x0d,0x06,0x09,0x60,0x86,0x48,0x01,0x65,0x03"\
",0x04,0x02,0x03,0x05,0x00,0x04,0x40"

RSA1024_Len=128
RSA2048_Len=256
RSA4096_Len=512
RSA8192_Len=1024

SHA1_T_Len=35
SHA256_T_Len=51
SHA512_T_Len=83

HashAlgos=( SHA1 SHA256 SHA512 )
RSAAlgos=( RSA1024 RSA2048 RSA4096 RSA8192 ) 

function genFFOctets {
  count=$1
  while [ $count -gt 0 ]; do
    echo -n "0xff,"
    let count=count-1
  done
}


cat <<EOF
/*
 * DO NOT MODIFY THIS FILE DIRECTLY.
 *
 * This file is automatically generated by genpadding.sh and contains padding
 * arrays corresponding to various combinations of algorithms for RSA signatures.
 */

EOF


echo '#include "cryptolib.h"'
echo
echo
cat <<EOF 
/*
 * PKCS 1.5 padding (from the RSA PKCS#1 v2.1 standard)
 *
 * Depending on the RSA key size and hash function, the padding is calculated
 * as follows:
 *
 * 0x00 || 0x01 || PS || 0x00 || T
 *
 * T: DER Encoded DigestInfo value which depends on the hash function used.
 *
 * SHA-1:   (0x)30 21 30 09 06 05 2b 0e 03 02 1a 05 00 04 14 || H.
 * SHA-256: (0x)30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20 || H.
 * SHA-512: (0x)30 51 30 0d 06 09 60 86 48 01 65 03 04 02 03 05 00 04 40 || H.
 *
 * Length(T) = 35 octets for SHA-1
 * Length(T) = 51 octets for SHA-256
 * Length(T) = 83 octets for SHA-512
 *
 * PS: octet string consisting of {Length(RSA Key) - Length(T) - 3} 0xFF
 *
 */
EOF
echo
echo


# Generate padding arrays.
algorithmcounter=0

for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo "/* Algorithm Type $algorithmcounter */"
    let algorithmcounter=algorithmcounter+1
    eval rsalen=${rsaalgo}_Len
    eval hashlen=${hashalgo}_T_Len
    let nums=rsalen-hashlen-3 
    echo "const uint8_t padding${rsaalgo}_${hashalgo}[${rsaalgo}NUMBYTES - ${hashalgo}_DIGEST_SIZE] = {"
    echo -n $Pad_Preamble,
    genFFOctets $nums
    echo -n "0x00,"
    eval digestinfo=\$${hashalgo}_digestinfo
    echo $digestinfo
    echo "};"
    echo
  done
done

echo "const int kNumAlgorithms = $algorithmcounter;";
echo "#define NUMALGORITHMS $algorithmcounter"
echo

# Output DigestInfo field lengths.
cat <<EOF
#define SHA1_DIGESTINFO_LEN 15
#define SHA256_DIGESTINFO_LEN 19
#define SHA512_DIGESTINFO_LEN 19
EOF


# Generate DigestInfo arrays.
for hashalgo in ${HashAlgos[@]}
do
  echo "const uint8_t ${hashalgo}_digestinfo[] = {"
  eval digestinfo=\$${hashalgo}_digestinfo
  echo $digestinfo
  echo "};"
  echo
done

# Generate DigestInfo to size map.
echo "const int digestinfo_size_map[] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo ${hashalgo}_DIGESTINFO_LEN,
  done
done
echo "};"
echo

# Generate algorithm signature length map.
echo "const int siglen_map[NUMALGORITHMS] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo ${rsaalgo}NUMBYTES,
  done
done
echo "};"
echo

# Generate algorithm padding array map.
echo "const uint8_t* padding_map[NUMALGORITHMS] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
     echo padding${rsaalgo}_${hashalgo},
  done
done
echo "};"
echo

# Generate algorithm padding size map.
echo "const int padding_size_map[NUMALGORITHMS] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo ${rsaalgo}NUMBYTES - ${hashalgo}_DIGEST_SIZE,
  done
done
echo "};"
echo

# Generate signature algorithm to messge digest algorithm map.
echo "const int hash_type_map[] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo ${hashalgo}_DIGEST_ALGORITHM,
  done
done
echo "};"
echo

# Generate algorithm to message digest's output size map.
echo "const int hash_size_map[NUMALGORITHMS] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo ${hashalgo}_DIGEST_SIZE,
  done
done
echo "};"
echo

# Generate algorithm to message digest's input block size map.
echo "const int hash_blocksize_map[NUMALGORITHMS] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo ${hashalgo}_BLOCK_SIZE,
  done
done
echo "};"
echo

# Generate algorithm to message's digest ASN.1 DigestInfo map.
echo "const uint8_t* hash_digestinfo_map[NUMALGORITHMS] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo ${hashalgo}_digestinfo,
  done
done
echo "};"
echo


# Generate algorithm description strings.
echo "const char* algo_strings[NUMALGORITHMS] = {"
for rsaalgo in ${RSAAlgos[@]}
do
  for hashalgo in ${HashAlgos[@]}
  do
    echo \"${rsaalgo} ${hashalgo}\",
  done
done
echo "};"
echo

#echo "#endif  /* VBOOT_REFERENCE_PADDING_H_ */"
