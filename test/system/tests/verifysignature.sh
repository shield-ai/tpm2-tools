#!/bin/bash
#;**********************************************************************;
#
# Copyright (c) 2016, Intel Corporation
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of Intel Corporation nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.
#;**********************************************************************;
file_primary_key_ctx=context.p_B1
file_signing_key_pub=opuB1_B8
file_signing_key_priv=oprB1_B8
file_signing_key_ctx=context_load_out_B1_B8
file_signing_key_name=name.load.B1_B8
file_input_data=secret.data
file_output_data=sig.4
file_verify_tk_data=tickt_verify_sig.4

file_input_data_hash=secret_hash.data
file_input_data_hash_tk=secret_hash_tk.data

handle_signing_key=0x81010005

alg_hash=sha256
alg_primary_key=0x0001
alg_signing_key=0x0001

onerror() {
    echo "$BASH_COMMAND on line ${BASH_LINENO[0]} failed: $?"
    exit 1
}
trap onerror ERR

cleanup() {
    rm -f $file_primary_key_ctx $file_signing_key_pub $file_signing_key_priv \
          $file_signing_key_ctx $file_signing_key_name $file_output_data \
          $file_verify_tk_data $file_input_data_hash $file_input_data_hash_tk \
          $file_input_data
}
trap cleanup EXIT

cleanup

echo "12345678" > $file_input_data

tpm2_clear

tpm2_createprimary -Q -H e -g $alg_hash -G $alg_primary_key -C $file_primary_key_ctx

tpm2_create -Q -g $alg_hash -G $alg_signing_key -u $file_signing_key_pub -r $file_signing_key_priv  -c $file_primary_key_ctx

tpm2_load -Q -c $file_primary_key_ctx  -u $file_signing_key_pub  -r $file_signing_key_priv -n $file_signing_key_name -C $file_signing_key_ctx

tpm2_sign -Q -c $file_signing_key_ctx -g $alg_hash -m $file_input_data -s $file_output_data

tpm2_verifysignature -Q -c $file_signing_key_ctx  -g $alg_hash -m $file_input_data  -s $file_output_data -t $file_verify_tk_data

tpm2_hash -Q -H n -g $alg_hash -o $file_input_data_hash -t $file_input_data_hash_tk $file_input_data

rm -f $file_verify_tk_data
tpm2_verifysignature -Q -c  $file_signing_key_ctx  -D  $file_input_data_hash -s $file_output_data  -t $file_verify_tk_data

rm -f $file_verify_tk_data $file_signing_key_ctx  -rf
tpm2_loadexternal -Q -H n -u $file_signing_key_pub -C  $file_signing_key_ctx

tpm2_verifysignature -Q -c  $file_signing_key_ctx  -g $alg_hash -m $file_input_data  -s $file_output_data -t $file_verify_tk_data

exit 0
