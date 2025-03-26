#!/bin/bash

rm -f allowed_signers.sig

sleep 1

echo "untrusted comment: verify with factory.pub" > allowed_signers.sig
echo "RWQZW9NItOuQYMZY8ZMX9VX4hfy54df7Pt3Yh1qEWTyRlQKH4PdteqeKUk9jljywlcCl8nzKJAj75F70Y5FTsAK4cw2aV+CZcAA=" >> allowed_signers.sig

